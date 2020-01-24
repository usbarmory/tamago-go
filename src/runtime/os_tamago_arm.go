// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build tamago,arm

package runtime

import (
	"unsafe"
)

const tamagoDebug = true

// FIXME: for mem_tamago.go copied from mem_plan9.go
const _PAGESIZE uintptr = 0x1000

// Memory region attributes
// Table B3-10 ARM Architecture Reference Manual ARMv7-A and ARMv7-R edition
const TTE_SECTION_1MB uint32 = 0x2
const TTE_SECTION_16MB uint32 = 0x40002
const TTE_EXECUTE_NEVER uint32 = 0x10
const TTE_CACHEABLE uint32 = 0x8
const TTE_BUFFERABLE uint32 = 0x4

// MMU access permissions
// Table B3-8 ARM Architecture Reference Manual ARMv7-A and ARMv7-R edition
const TTE_AP_000 uint32 = 0b000000 << 10 // PL1: no access   PL0: no access
const TTE_AP_001 uint32 = 0b000001 << 10 // PL1: read/write  PL0: no access
const TTE_AP_010 uint32 = 0b000010 << 10 // PL1: read/write  PL0: read only
const TTE_AP_011 uint32 = 0b000011 << 10 // PL1: read/write  PL0: read/write
const TTE_AP_100 uint32 = 0b100000 << 10 // Reserved
const TTE_AP_101 uint32 = 0b100001 << 10 // PL1: read only   PL0: no access
const TTE_AP_110 uint32 = 0b100010 << 10 // PL1: read only   PL0: read only
const TTE_AP_111 uint32 = 0b100011 << 10 // PL1: read only   PL0: read only

// the following variables must be provided externally
var ramStart uint32
var ramStackOffset uint32

// the following variables must be provided externally
// (but are already stubbed somewhere else in the runtime)
// var ramSize uint32

// the following functions must be provided externally
func hwinit()
func printk(byte)
func getRandomData([]byte)
func initRNG()

// the following functions must be provided externally
// (but are already stubbed somewhere else in the runtime)
//func initRNG()
//func nanotime() int64

// the following functions are defined in sys_tamago_arm.s
func set_vbar(addr unsafe.Pointer)
func set_ttbr0(addr unsafe.Pointer)
func set_exc_stack(addr unsafe.Pointer)

//go:nosplit
func dmb()
func semihostingstop()

// stubs for unused/unimplemented functionality
type mOS struct{}
type sigset struct{}
type gsignalStack struct{}

func goenvs()                                             {}
func msigsave(mp *m)                                      {}
func msigrestore(sigmask sigset)                          {}
func clearSignalHandlers()                                {}
func sigblock()                                           {}
func minit()                                              {}
func unminit()                                            {}
func madvise(addr unsafe.Pointer, n uintptr, flags int32) {}
func munmap(addr unsafe.Pointer, n uintptr)               {}
func setProcessCPUProfiler(hz int32)                      {}
func setThreadCPUProfiler(hz int32)                       {}
func initsig(preinit bool)                                {}
func sigdisable(uint32)                                   {}
func sigenable(uint32)                                    {}
func sigignore(uint32)                                    {}
func closeonexec(int32)                                   {}
func osyield()                                            {}

type ExceptionHandler func()

// global variables
var vt *vector_table

var vecTableOffset uint32 = 0
var vecTableSize uint32 = 0x4000 // 16 kB

var l1pageTableOffset uint32 = 0x4000 // 16 kB
var l1pageTableSize uint32 = 0x4000   // 16 kB

var excStackOffset uint32 = 0x8000 // 32 kB
var excStackSize uint32 = 0x4000   // 16 kB

// the following variables are set in sys_tamago_arm.s
var stackBottom uint32

var defaultHandler ExceptionHandler = func() {
	// TODO: implement stack dump
	throw("unhandled exception! (defaultHandler)\n")
}

var simpleHandler ExceptionHandler = func() {
	// TODO: implement stack dump
	print("unhandled exception! (simpleHandler)\n")
	for {
	} // freeze
}

// Table 11-1 ARM® Cortex™ -A Series Programmer’s Guide
type vector_table struct {
	// jump entries
	reset          uint32
	undefined      uint32
	svc            uint32
	prefetch_abort uint32
	data_abort     uint32
	_unused        uint32
	irq            uint32
	fiq            uint32
	// call pointers
	reset_addr          uint32
	undefined_addr      uint32
	svc_addr            uint32
	prefetch_abort_addr uint32
	data_abort_addr     uint32
	_unused_addr        uint32
	irq_addr            uint32
	fiq_addr            uint32
}

// May run with m.p==nil, so write barriers are not allowed.
//go:nowritebarrier
func newosproc(mp *m) {
	panic("newosproc: not implemented")
}

func Setncpu(n int32) {
	if n > 1 {
		throw("unsupported: ncpu >= 2")
	}
	ncpu = n
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
	// the kernel uses Setncpu() to update ncpu to the number of
	// booted CPUs on startup
	ncpu = 1
	physPageSize = 4096
	initBloc()
}

func signame(sig uint32) string {
	if sig >= uint32(len(sigtable)) {
		return ""
	}
	return sigtable[sig].name
}

func checkgoarm() {
	// tamago/ARM only supports ARMv7
	if goarm != 7 {
		print("runtime: tamago requires ARMv7. Recompile using GOARM=7.\n")
		exit(1)
	}
}

//go:nosplit
func cputicks() int64 {
	// Currently cputicks() is used in blocking profiler and to seed runtime·fastrand().
	// runtime·nanotime() is a poor approximation of CPU ticks that is enough for the profiler.
	// TODO: need more entropy to better seed fastrand.
	return nanotime()
}

//go:nosplit
func roundup(val, upto uint32) uint32 {
	return ((val + (upto - 1)) & ^(upto - 1))
}

//go:linkname os_sigpipe os.sigpipe
func os_sigpipe() {
	throw("too many writes on closed pipe")
}

//go:nosplit
func crash() {
	*(*int32)(nil) = 0
}

func GetRandomData(r []byte) {
	getRandomData(r)
}

//go:nosplit
func vecinit() {
	// Allocate the vector table
	vecTableStart := ramStart + vecTableOffset
	memclrNoHeapPointers(unsafe.Pointer(uintptr(vecTableStart)), uintptr(vecTableSize))
	dmb()

	// ldr pc, [pc, #24]
	resetVectorWord := uint32(0xe59ff018)

	vt = (*vector_table)(unsafe.Pointer(uintptr(vecTableStart)))
	vt.reset = resetVectorWord
	vt.undefined = resetVectorWord
	vt.svc = resetVectorWord
	vt.prefetch_abort = resetVectorWord
	vt.data_abort = resetVectorWord
	vt._unused = resetVectorWord
	vt.irq = resetVectorWord
	vt.fiq = resetVectorWord

	defaultHandlerAddr := **((**uint32)(unsafe.Pointer(&defaultHandler)))
	simpleHandlerAddr := **((**uint32)(unsafe.Pointer(&simpleHandler)))

	// We don't handle IRQ or exceptions yet.
	vt.reset_addr = defaultHandlerAddr
	vt.undefined_addr = defaultHandlerAddr
	vt.prefetch_abort_addr = defaultHandlerAddr
	vt.data_abort_addr = defaultHandlerAddr
	vt.irq_addr = defaultHandlerAddr
	vt.fiq_addr = defaultHandlerAddr

	// SWI calls are also triggered by throw, but we cannot panic in panic
	// therefore this handler needs not to throw.
	vt.svc_addr = simpleHandlerAddr

	if tamagoDebug {
		print("vecTableStart    ", hex(vecTableStart), "\n")
		print("vecTableSize     ", hex(vecTableSize), "\n")
	}

	set_vbar(unsafe.Pointer(vt))
}

//go:nosplit
func excstackinit() {
	// Allocate stack pointer for exception modes to provide a stack to the
	// g0 goroutine when summoned by exception vectors.

	excStackStart := ramStart + excStackOffset
	memclrNoHeapPointers(unsafe.Pointer(uintptr(excStackStart)), uintptr(excStackSize))
	dmb()

	if tamagoDebug {
		print("excStackStart    ", hex(excStackStart), "\n")
		print("excStackSize     ", hex(excStackSize), "\n")
		print("stackBottom      ", hex(stackBottom), "\n")
		print("g0.stackguard0   ", hex(g0.stackguard0), "\n")
		print("g0.stackguard1   ", hex(g0.stackguard1), "\n")
		print("g0.stack.lo      ", hex(g0.stack.lo), "\n")
		print("g0.stack.hi      ", hex(g0.stack.hi), "\n")
		print("-- ELF image layout (firstmoduledata dump) --\n")
		print(".text            ", hex(firstmoduledata.text), " - ", hex(firstmoduledata.etext), "\n")
		print(".noptrdata       ", hex(firstmoduledata.noptrdata), " - ", hex(firstmoduledata.enoptrdata), "\n")
		print(".data            ", hex(firstmoduledata.data), " - ", hex(firstmoduledata.edata), "\n")
		print(".bss             ", hex(firstmoduledata.bss), " - ", hex(firstmoduledata.ebss), "\n")
		print(".noptrbss        ", hex(firstmoduledata.noptrbss), " - ", hex(firstmoduledata.enoptrbss), "\n")
		print(".end             ", hex(firstmoduledata.end), "\n")

		imageSize := uint32(firstmoduledata.end - firstmoduledata.text)
		heapSize := uint32(g0.stack.lo - firstmoduledata.end)
		stackSize := uint32(g0.stack.hi - g0.stack.lo)
		unusedSize := uint32(firstmoduledata.text) - (excStackStart + excStackSize) + ramStackOffset

		print("-- Memory section sizes ---------------------\n")
		print("vector table:    ", vecTableSize, " (", vecTableSize/1024, " kB)\n")
		print("L1 page table:   ", l1pageTableSize, " (", l1pageTableSize/1024, " kB)\n")
		print("exception stack: ", excStackSize, " (", excStackSize/1024, " kB)\n")
		print("program image:   ", imageSize, " (", imageSize/1024, " kB)\n")
		print("heap:            ", heapSize, " (", heapSize/1024, " kB)\n")
		print("g0 stack:        ", stackSize, " (", stackSize/1024, " kB)\n")
		print("total unused:    ", unusedSize, " (", unusedSize/1024, " kB)\n")

		totalSize := vecTableSize + l1pageTableSize + excStackSize + imageSize + heapSize + stackSize + unusedSize
		print("total:           ", totalSize, " (", totalSize/1024, " kB)\n")
		print("---------------------------------------------\n")
	}

	set_exc_stack(unsafe.Pointer(uintptr(excStackStart + excStackSize)))
}

//go:nosplit
func mmuinit() {
	// Initialize page tables and map regions in privileged system area.
	//
	// MMU initialization is required to take advantage of data cache.
	// http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.faqs/ka13835.html

	// Define a flat L1 page table, the MMU is enabled only for caching to work.
	// The L1 page table is located 16KB after ramStart.

	l1pageTableStart := ramStart + l1pageTableOffset
	memclrNoHeapPointers(unsafe.Pointer(uintptr(l1pageTableStart)), uintptr(l1pageTableSize))

	var i uint32

	memAttr := uint32(TTE_AP_011 | TTE_CACHEABLE | TTE_BUFFERABLE | TTE_SECTION_1MB)
	devAttr := uint32(TTE_AP_011 | TTE_SECTION_1MB)

	for i = 0; i < l1pageTableSize/4; i++ {
		if i >= (ramStart>>20) && i < ((ramStart+ramSize)>>20) {
			*(*uint32)(unsafe.Pointer(uintptr(l1pageTableStart + 4*i))) = (i << 20) | memAttr
		} else {
			*(*uint32)(unsafe.Pointer(uintptr(l1pageTableStart + 4*i))) = (i << 20) | devAttr
		}
	}

	dmb()

	if tamagoDebug {
		print("l1pageTableStart ", hex(l1pageTableStart), "\n")
		print("l1pageTableSize  ", hex(l1pageTableSize), "\n")
	}

	set_ttbr0(unsafe.Pointer(uintptr(l1pageTableStart)))
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
func write(fd uintptr, buf unsafe.Pointer, count int32) int32 {
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
	nsec = int32(nano - (sec * 1000000000))
	return
}

//go:nosplit
func usleep(us uint32) {
	// TODO: Understand how much this is used and if blocking operation is
	// an acceptable strategy.
	if tamagoDebug {
		print("usleep for ", us, "us\n")
	}
	wake := nanotime() + int64(us)*1000
	for nanotime() < wake {
	}
}

func exit(code int32) {
	print("exit with code ", code, " halting\n")
	// TODO: valid only within `qemu -semihosting`, support native hardware
	semihostingstop()
}

func exitThread(wait *uint32) {
	// We should never reach exitThread
	throw("exitThread: not implemented")
}
