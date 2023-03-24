// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm

package runtime

import (
	"runtime/internal/atomic"
	"unsafe"
)

const _PAGESIZE uintptr = 0x1000

// the following variables must be provided externally
var ramStart uint32
var ramSize uint32
var ramStackOffset uint32

// the following functions must be provided externally
func hwinit()
func printk(byte)
func getRandomData([]byte)
func initRNG()

// the following functions must be provided externally
// (but are already stubbed somewhere else in the runtime)
//func nanotime1() int64

// GetRandomData generates len(r) random bytes from the random source provided
// externally by the linked application.
func GetRandomData(r []byte) {
	getRandomData(r)
}

// CallOnG0 calls a function (func(off int)) on g0 stack.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * R0: fn argument (vector table offset)
//   * R1: fn pointer
//   * R2: size of stack area reserved for caller registers
//   * R3: caller program counter
func CallOnG0()

// GetG returns the pointer to the current G and its P.
func GetG() (g uint32, p uint32)

// WakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * R0: G pointer
//   * R1: P pointer
func WakeG()

// MemRegion returns the start and end addresses of the physical RAM assigned
// to the Go runtime.
func MemRegion() (start uint32, end uint32) {
	return ramStart, ramStart + ramSize
}

// stubs for unused/unimplemented functionality
type mOS struct{}
type sigset struct{}
type gsignalStack struct{}

func goenvs()                        {}
func sigsave(p *sigset)              {}
func msigrestore(sigmask sigset)     {}
func clearSignalHandlers()           {}
func sigblock(exiting bool)          {}
func minit()                         {}
func unminit()                       {}
func mdestroy(mp *m)                 {}
func setProcessCPUProfiler(hz int32) {}
func setThreadCPUProfiler(hz int32)  {}
func initsig(preinit bool)           {}
func osyield()                       {}
func osyield_no_g()                  {}

// May run with m.p==nil, so write barriers are not allowed.
//
//go:nowritebarrier
func newosproc(mp *m) {
	throw("newosproc: not implemented")
}

// Called to do synchronous initialization of Go code built with
// -buildmode=c-archive or -buildmode=c-shared.
// None of the Go runtime is initialized.
//go:nosplit
//go:nowritebarrierrec
func libpreinit() {
	initsig(true)
}

// Called to initialize a new m (including the bootstrap m).
// Called on the parent thread (main thread in case of bootstrap), can allocate memory.
func mpreinit(mp *m) {
	mp.gsignal = malg(32 * 1024)
	mp.gsignal.m = mp
}

func osinit() {
	ncpu = 1
	physPageSize = 4096
	initBloc()
}

func signame(sig uint32) string {
	return ""
}

func checkgoarm() {
	if goarm < 5 || goarm > 7 {
		print("runtime: tamago requires ARMv5 through ARMv7. Recompile using GOARM=5, GOARM=6 or GOARM=7.\n")
		exit(1)
	}
}

//go:nosplit
func cputicks() int64 {
	// Currently cputicks() is used in blocking profiler and to seed runtime·fastrand().
	// runtime·nanotime() is a poor approximation of CPU ticks that is enough for the profiler.
	return nanotime()
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
	// TODO: probably better implement this in sys_tamago_arm.s for better
	// performance
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
	print("exit with code ", code, " halting\n")
	for {
		// hang forever
	}
}

func exitThread(wait *atomic.Uint32) {
	// We should never reach exitThread
	throw("exitThread: not implemented")
}

const preemptMSupported = false

func preemptM(mp *m) {
	// No threads, so nothing to do.
}
