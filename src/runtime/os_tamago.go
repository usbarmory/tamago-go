// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package runtime

import (
	"internal/abi"
	"internal/runtime/atomic"
	"unsafe"
)

type mOS struct {
	waitsemacount uint32
}

// see testing.testBinary
var testBinary string

// the following functions must be provided externally
func hwinit0()
func hwinit1()
func printk(byte)
func getRandomData([]byte)
func initRNG()

// the following functions must be provided externally
// (but are already stubbed somewhere else in the runtime)
//func nanotime1() int64

// the following functions can be provided externally
var (
	// Bloc allows to override the heap memory start address
	Bloc uintptr

	// Exit can be set externally to provide an implementation for runtime
	// termination (see runtime.exit).
	Exit func(int32)

	// Idle can be set externally to provide an implementation for CPU idle time
	// management (see runtime.beforeIdle).
	Idle func(until int64)

	// ProcID can be set externally to provide the process identifier.
	ProcID func() uint64

	// Task can be set externally to provide an implementation for HW/OS threading.
	//
	// The call takes effect only when [runtime.NumCPU] is greater than 1 (see
	// [runtime.SetNumCPU]).
	Task func(sp, mp, gp, fn unsafe.Pointer)
)

// GetRandomData generates len(r) random bytes from the random source provided
// externally by the linked application.
func GetRandomData(r []byte) {
	getRandomData(r)
}

// WakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
//
// The function is meant to be invoked within Go assembly and its arguments
// must be passed through registers rather than on the frame pointer, see
// definition in sys_tamago_$GOARCH.s for details.
func WakeG()

// Wake modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible, reporting whether the modification is successful.
func Wake(gp uint) bool

// stubs for unused/unimplemented functionality
type sigset struct{}
type gsignalStack struct{}

func goenvs()                        {}
func sigsave(p *sigset)              {}
func msigrestore(sigmask sigset)     {}
func clearSignalHandlers()           {}
func sigblock(exiting bool)          {}
func unminit()                       {}
func mdestroy(mp *m)                 {}
func setProcessCPUProfiler(hz int32) {}
func setThreadCPUProfiler(hz int32)  {}
func initsig(preinit bool)           {}
func osyield()                       {}
func osyield_no_g()                  {}

const stacksize = 8192 * 1024 // 8192KB

// May run with m.p==nil, so write barriers are not allowed.
//
//go:nowritebarrier
func newosproc(mp *m) {
	if Task == nil {
		throw("newosproc: not implemented")
	}

	stack := sysAlloc(stacksize, &memstats.stacks_sys, "HW thread stack")
	if stack == nil {
		writeErrStr(failallocatestack)
		exit(1)
	}

	Task(unsafe.Pointer(uintptr(stack)+stacksize), unsafe.Pointer(mp), unsafe.Pointer(mp.g0), unsafe.Pointer(abi.FuncPCABI0(mstart)))
}

// Called to initialize a new m (including the bootstrap m).
// Called on the parent thread (main thread in case of bootstrap), can allocate memory.
func mpreinit(mp *m) {
	mp.gsignal = malg(32 * 1024)
	mp.gsignal.m = mp
}

func getCPUCount() int32 {
	return numCPUStartup
}

func osinit() {
	physPageSize = 4096
	numCPUStartup = 1

	if Bloc != 0 {
		bloc = Bloc
		blocMax = bloc
	} else {
		initBloc()
	}
}

func readRandom(r []byte) int {
	initRNG()
	getRandomData(r)
	return len(r)
}

func signame(sig uint32) string {
	return ""
}

//go:linkname os_sigpipe os.sigpipe
func os_sigpipe() {
	throw("too many writes on closed pipe")
}

//go:nosplit
func crash() {
	*(*int32)(nil) = 0
}

//go:linkname syscall
func syscall(number, a1, a2, a3 uintptr) (r1, r2, err uintptr) {
	switch number {
	// SYS_WRITE
	case 1:
		r1 := write(a1, unsafe.Pointer(a2), int32(a3))
		return uintptr(r1), 0, 0
	default:
		throw("unexpected syscall")
	}

	return
}

//go:nosplit
func write1(fd uintptr, buf unsafe.Pointer, count int32) int32 {
	if fd != 1 && fd != 2 {
		throw("unexpected fd, only stdout/stderr are supported")
	}

	c := uintptr(count)

	for i := uintptr(0); i < c; i++ {
		p := (*byte)(unsafe.Pointer(uintptr(buf) + i))
		printk(*p)
	}

	return int32(c)
}

//go:linkname syscall_now syscall.now
func syscall_now() (sec int64, nsec int32) {
	sec, nsec, _ = time_now()
	return
}

//go:nosplit
func walltime() (sec int64, nsec int32) {
	nano := nanotime()
	sec = nano / 1000000000
	nsec = int32(nano % 1000000000)
	return
}

//go:nosplit
func usleep(us uint32) {
	wake := nanotime() + int64(us)*1000
	for nanotime() < wake {
	}
}

//go:nosplit
func usleep_no_g(usec uint32) {
	usleep(usec)
}

func exit(code int32) {
	if Exit != nil {
		Exit(code)
	}

	print("exit with code ", code, " halting\n")

	for {
		// hang forever
	}
}

func exitThread(wait *atomic.Uint32) {
	return
}

//go:nosplit
func semacreate(mp *m) {
}

//go:nosplit
func semasleep(ns int64) int {
	gp := getg()
	addr := &gp.m.waitsemacount

	v := uint32(0)

	if ns >= 0 {
		deadline := nanotime() + ns

		for {
			if deadline-nanotime() <= 0 {
				return -1 // timeout or interrupted
			}
			if v = atomic.Load(addr); v <= 0 {
				continue
			}
			if atomic.Cas(addr, v, v-1) {
				return 0
			}
		}
	}

	for {
		if v = atomic.Load(addr); v <= 0 {
			// interrupted; try again (c.f. lock_sema.go)
			continue
		}
		if atomic.Cas(addr, v, v-1) {
			return 0
		}
	}
}

//go:nosplit
func semawakeup(mp *m) {
	atomic.Xadd(&mp.waitsemacount, 1)
}

const preemptMSupported = false

func preemptM(mp *m) {}

func minit() {
	if ProcID == nil {
		return
	}

	gp := getg()
	gp.m.procid = ProcID()
}

// Stubs so tests can link correctly. These should never be called.
func open(name *byte, mode, perm int32) int32        { panic("not implemented") }
func closefd(fd int32) int32                         { panic("not implemented") }
func read(fd int32, p unsafe.Pointer, n int32) int32 { panic("not implemented") }
