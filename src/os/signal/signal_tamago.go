// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package signal

import (
	"os"
	"syscall"
	"time"
	_ "unsafe"
)

var (
	loopG uintptr
	sig   syscall.Signal
)

// Defined by the runtime package.
func getgp() uintptr

func loop() {
	loopG = getgp()

	for {
		// Sleep indefinitely until woken up by [Relay] through
		// runtime.wakeg.
		time.Sleep(1<<63 - 1) // math.MaxInt64
		process(sig)
		sig = -1
	}
}

func init() {
	watchSignalLoop = loop
}

const numSig = 256

func signum(sig os.Signal) int {
	switch sig := sig.(type) {
	case syscall.Signal:
		i := int(sig)
		if i < 0 || i >= numSig {
			return -1
		}
		return i
	default:
		return -1
	}
}

func enableSignal(sig int)  {}
func disableSignal(sig int) {}
func ignoreSignal(sig int)  {}

func signalIgnored(sig int) bool {
	return false
}

//go:linkname waitUntilIdle os/signal.signalWaitUntilIdle
func waitUntilIdle() {
	for !Waiting() {
	}
}

// Relay sends a signal to the [Notify] channel.
//
// To make it suitable for invocation in bare metal interrupt/exception
// handlers, the function is implemented in assembly avoiding allocation and
// runtime use.
//
//go:nosplit
func Relay(sig syscall.Signal)

// Waiting returns whether package signal is blocked waiting an incoming signal
// to [Notify].
//
//go:nosplit
func Waiting() bool
