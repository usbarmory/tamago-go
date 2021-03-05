// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build tamago,arm

package runtime

import (
	"unsafe"
)

const tamagoDebug = true

const _PAGESIZE uintptr = 0x1000

// ARM processor modes
// Table B1-1 ARM Architecture Reference Manual ARMv7-A and ARMv7-R edition
const (
	USR_MODE = 0b10000
	FIQ_MODE = 0b10001
	IRQ_MODE = 0b10010
	SVC_MODE = 0b10011
	MON_MODE = 0b10110
	ABT_MODE = 0b10111
	HYP_MODE = 0b11010
	UND_MODE = 0b11011
	SYS_MODE = 0b11111
)

// Memory region attributes
// Table B3-10 ARM Architecture Reference Manual ARMv7-A and ARMv7-R edition
const (
	TTE_SECTION_1MB   uint32 = 0x2
	TTE_SECTION_16MB  uint32 = 0x40002
	TTE_EXECUTE_NEVER uint32 = 0x10
	TTE_CACHEABLE     uint32 = 0x8
	TTE_BUFFERABLE    uint32 = 0x4
)

// MMU access permissions
// Table B3-8 ARM Architecture Reference Manual ARMv7-A and ARMv7-R edition
const (
	// PL1: no access   PL0: no access
	TTE_AP_000 uint32 = 0b000000 << 10
	// PL1: read/write  PL0: no access
	TTE_AP_001 uint32 = 0b000001 << 10
	// PL1: read/write  PL0: read only
	TTE_AP_010 uint32 = 0b000010 << 10
	// PL1: read/write  PL0: read/write
	TTE_AP_011 uint32 = 0b000011 << 10
	// Reserved
	TTE_AP_100 uint32 = 0b100000 << 10
	// PL1: read only   PL0: no access
	TTE_AP_101 uint32 = 0b100001 << 10
	// PL1: read only   PL0: read only
	TTE_AP_110 uint32 = 0b100010 << 10
	// PL1: read only   PL0: read only
	TTE_AP_111 uint32 = 0b100011 << 10
)

// the following variables must be provided externally
var ramStart uint32
var ramStackOffset uint32

// the following variables must be provided externally
// (but are already stubbed somewhere else in the runtime)
// var ramSize uint32

// the following functions must be provided externally
func hwinit()
func printk(byte)
func exceptionHandler()
func getRandomData([]byte)
func initRNG()

// the following functions must be provided externally
// (but are already stubbed somewhere else in the runtime)
//func nanotime1() int64

// the following functions are defined in sys_tamago_arm.s
func set_vbar(addr unsafe.Pointer)
func set_ttbr0(addr unsafe.Pointer)
func set_exc_stack(addr unsafe.Pointer)
func processor_mode() uint32

//go:nosplit
func dmb()

// stubs for unused/unimplemented functionality
type mOS struct{}
type sigset struct{}
type gsignalStack struct{}

func goenvs()                                             {}
func sigsave(p *sigset)                                   {}
func msigrestore(sigmask sigset)                          {}
func clearSignalHandlers()                                {}
func sigblock(exiting bool)                               {}
func minit()                                              {}
func unminit()                                            {}
func mdestroy(mp *m)                                      {}
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

// the following functions are defined in sys_tamago_arm.s
func resetHandler()
func undefinedHandler()
func svcHandler()
func prefetchAbortHandler()
func dataAbortHandler()
func irqHandler()
func fiqHandler()

func fnAddress(fn func()) uint32 {
	return **((**uint32)(unsafe.Pointer(&fn)))
}

//go:nosplit
func vecinit() {
	if processor_mode() != SYS_MODE {
		return
	}

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

	vt.reset_addr = fnAddress(resetHandler)
	vt.undefined_addr = fnAddress(undefinedHandler)
	vt.svc_addr = fnAddress(svcHandler)
	vt.prefetch_abort_addr = fnAddress(prefetchAbortHandler)
	vt.data_abort_addr = fnAddress(dataAbortHandler)
	vt.irq_addr = fnAddress(irqHandler)
	vt.fiq_addr = fnAddress(fiqHandler)

	set_vbar(unsafe.Pointer(vt))

	// Allocate stack pointer for exception modes to provide a stack to the
	// g0 goroutine when summoned by exception vectors.
	excStackStart := ramStart + excStackOffset
	memclrNoHeapPointers(unsafe.Pointer(uintptr(excStackStart)), uintptr(excStackSize))
	dmb()

	set_exc_stack(unsafe.Pointer(uintptr(excStackStart + excStackSize)))

	if !tamagoDebug {
		return
	}

	print("vecTableStart    ", hex(vecTableStart), "\n")
	print("vecTableSize     ", hex(vecTableSize), "\n")
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
	totalSize := vecTableSize + l1pageTableSize + excStackSize + imageSize + heapSize + stackSize + unusedSize

	print("-- Memory section sizes ---------------------\n")
	print("vector table:    ", vecTableSize, " (", vecTableSize/1024, " kB)\n")
	print("L1 page table:   ", l1pageTableSize, " (", l1pageTableSize/1024, " kB)\n")
	print("exception stack: ", excStackSize, " (", excStackSize/1024, " kB)\n")
	print("program image:   ", imageSize, " (", imageSize/1024, " kB)\n")
	print("heap:            ", heapSize, " (", heapSize/1024, " kB)\n")
	print("g0 stack:        ", stackSize, " (", stackSize/1024, " kB)\n")
	print("total unused:    ", unusedSize, " (", unusedSize/1024, " kB)\n")
	print("total:           ", totalSize, " (", totalSize/1024, " kB)\n")
	print("---------------------------------------------\n")
}

//go:nosplit
func mmuinit() {
	// Initialize page tables and map regions in privileged system area.
	//
	// MMU initialization is required to take advantage of data cache.
	//
	// Define a flat L1 page table, the MMU is enabled only for caching to work.
	// The L1 page table is located 16KB after ramStart.

	if processor_mode() != SYS_MODE {
		return
	}

	l1pageTableStart := ramStart + l1pageTableOffset
	memclrNoHeapPointers(unsafe.Pointer(uintptr(l1pageTableStart)), uintptr(l1pageTableSize))

	memAttr := uint32(TTE_AP_011 | TTE_CACHEABLE | TTE_BUFFERABLE | TTE_SECTION_1MB)
	devAttr := uint32(TTE_AP_011 | TTE_SECTION_1MB)

	// skip page zero to trap null pointers
	for i := uint32(1); i < l1pageTableSize/4; i++ {
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
func walltime1() (sec int64, nsec int32) {
	// TODO: probably better implement this in sys_tamago_arm.s for better
	// performance
	nano := nanotime()
	sec = nano / 1000000000
	nsec = int32(nano - (sec * 1000000000))
	return
}

//go:nosplit
func usleep(us uint32) {
	wake := nanotime() + int64(us)*1000
	for nanotime() < wake {
	}
}

func exit(code int32) {
	print("exit with code ", code, " halting\n")
	for {
		// hang forever
	}
}

func exitThread(wait *uint32) {
	// We should never reach exitThread
	throw("exitThread: not implemented")
}

const preemptMSupported = false

func preemptM(mp *m) {
	// Not currently supported.
	//
	// TODO: Use a note like we use signals on POSIX OSes
}
