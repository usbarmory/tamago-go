// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

// Signal delivery for GOOS=tamago.
//
// Signals are raised through os/signal.Relay, which is suitable for
// invocation from bare metal interrupt/exception handlers. Relay (see
// sigRelay in sys_tamago_$GOARCH.s) only sets the signal bit in sigPending
// with an atomic operation, without allocation, locking or runtime use.
//
// The os/signal loop receives signals through signal_recv, which parks its
// goroutine whenever no signal is pending. The scheduler (see sigReady)
// makes it runnable again once a signal becomes pending.
//
// As signals are held in sigPending, a signal raised at any time, and in
// particular while the receiver is not parked, is never lost.

package runtime

import (
	"internal/runtime/atomic"
	"internal/runtime/sys"
	"unsafe"
)

const numSig = 256

var (
	// sigPending holds pending signals
	sigPending [numSig / 32]uint32

	// sigWaiter holds the *g parked in signal_recv
	sigWaiter atomic.Uintptr

	// sigRecv holds signals taken by signal_recv but not yet returned
	sigRecv [numSig / 32]uint32
)

// sigRelay sets signal in sigPending, defined in sys_tamago_$GOARCH.s
func sigRelay(sig uint32)

//go:nosplit
func sigAnyPending() bool {
	for i := range sigPending {
		if atomic.Load(&sigPending[i]) != 0 {
			return true
		}
	}

	return false
}

// signal_recv returns the next pending signal, blocking until one is
// available.
//
//go:linkname signal_recv os/signal.signal_recv
func signal_recv() uint32 {
	for {
		for i := range sigRecv {
			if v := sigRecv[i]; v != 0 {
				n := uint32(sys.TrailingZeros32(v))
				sigRecv[i] &^= 1 << n
				return uint32(i)*32 + n
			}
		}

		received := false

		for i := range sigPending {
			if v := atomic.Xchg(&sigPending[i], 0); v != 0 {
				sigRecv[i] |= v
				received = true
			}
		}

		if !received {
			gopark(sigParkCommit, nil, waitReasonIOWait, traceBlockGeneric, 1)
		}
	}
}

func sigParkCommit(gp *g, _ unsafe.Pointer) bool {
	p := uintptr(unsafe.Pointer(gp))
	sigWaiter.Store(p)

	if sigAnyPending() {
		// A signal was raised while parking, abort unless sigReady
		// already took gp (in which case it is being made runnable).
		return !sigWaiter.CompareAndSwap(p, 0)
	}

	return true
}

// sigReady returns the parked signal receiver, in _Gwaiting state, if any
// signal is pending, the caller must make it runnable.
//
//go:nosplit
func sigReady() *g {
	if !sigAnyPending() {
		return nil
	}

	return (*g)(unsafe.Pointer(sigWaiter.Swap(0)))
}

// signalWaitUntilIdle waits until the signal delivery mechanism is idle.
// This is used to ensure that we do not drop a signal notification due
// to a race between disabling a signal and receiving a signal.
// This assumes that signal delivery has already been disabled for
// the signal(s) in question, and here we are just waiting to make sure
// that all the signals have been delivered to the user channels
// by the os/signal package.
//
//go:linkname signalWaitUntilIdle os/signal.signalWaitUntilIdle
func signalWaitUntilIdle() {
	for sigAnyPending() || sigWaiter.Load() == 0 {
		Gosched()
	}
}
