// Copyright 2024 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for amd64, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

#define IA32_MSR_FS_BASE 0xc0000100

#define SYS_arch_prctl 158

TEXT runtime·rt0_amd64_tamago(SB),NOSPLIT|NOFRAME|TOPFRAME,$0
	// create istack out of the bootstack
	MOVQ	$runtime·g0(SB), DI
	LEAQ	(-64*1024)(SP), AX
	MOVQ	AX, g_stackguard0(DI)
	MOVQ	AX, g_stackguard1(DI)
	MOVQ	AX, (g_stack+stack_lo)(DI)
	MOVQ	SP, (g_stack+stack_hi)(DI)

	// find out information about the processor we're on
	MOVL	$0, AX
	CPUID
	CMPL	AX, $0
	JE	nocpuinfo

	CMPL	BX, $0x756E6547  // "Genu"
	JNE	notintel
	CMPL	DX, $0x49656E69  // "ineI"
	JNE	notintel
	CMPL	CX, $0x6C65746E  // "ntel"
	JNE	notintel
	MOVB	$1, runtime·isIntel(SB)

notintel:
	// Load EAX=1 cpuid flags
	MOVL	$1, AX
	CPUID
	MOVL	AX, runtime·processorVersionInfo(SB)

nocpuinfo:
	LEAQ	runtime·m0+m_tls(SB), DI
	CALL	runtime·settls(SB)

	// store through it, to make sure it works
	get_tls(BX)
	MOVQ	$0x123, g(BX)
	MOVQ	runtime·m0+m_tls(SB), AX
	CMPQ	AX, $0x123
	JEQ 2(PC)
	CALL	runtime·abort(SB)
ok:
	// set the per-goroutine and per-mach "registers"
	get_tls(BX)
	LEAQ	runtime·g0(SB), CX
	MOVQ	CX, g(BX)
	LEAQ	runtime·m0(SB), AX

	// save m->g0 = g0
	MOVQ	CX, m_g0(AX)
	// save m0 to g0->m
	MOVQ	AX, g_m(CX)

	CLD				// convention is D is always left cleared

	// Check GOAMD64 requirements
	// We need to do this after setting up TLS, so that
	// we can report an error if there is a failure. See issue 49586.
#ifdef NEED_FEATURES_CX
	MOVL	$0, AX
	CPUID
	CMPL	AX, $0
	JE	bad_cpu
	MOVL	$1, AX
	CPUID
	ANDL	$NEED_FEATURES_CX, CX
	CMPL	CX, $NEED_FEATURES_CX
	JNE	bad_cpu
#endif

#ifdef NEED_MAX_CPUID
	MOVL	$0x80000000, AX
	CPUID
	CMPL	AX, $NEED_MAX_CPUID
	JL	bad_cpu
#endif

#ifdef NEED_EXT_FEATURES_BX
	MOVL	$7, AX
	MOVL	$0, CX
	CPUID
	ANDL	$NEED_EXT_FEATURES_BX, BX
	CMPL	BX, $NEED_EXT_FEATURES_BX
	JNE	bad_cpu
#endif

#ifdef NEED_EXT_FEATURES_CX
	MOVL	$0x80000001, AX
	CPUID
	ANDL	$NEED_EXT_FEATURES_CX, CX
	CMPL	CX, $NEED_EXT_FEATURES_CX
	JNE	bad_cpu
#endif

#ifdef NEED_OS_SUPPORT_AX
	XORL    CX, CX
	XGETBV
	ANDL	$NEED_OS_SUPPORT_AX, AX
	CMPL	AX, $NEED_OS_SUPPORT_AX
	JNE	bad_cpu
#endif

	CALL	runtime·check(SB)

	MOVL	24(SP), AX		// copy argc
	MOVL	AX, 0(SP)
	MOVQ	32(SP), AX		// copy argv
	MOVQ	AX, 8(SP)
	CALL	runtime·hwinit0(SB)
	CALL	runtime·osinit(SB)
	CALL	runtime·schedinit(SB)
	CALL	runtime·hwinit1(SB)

	// create a new goroutine to start program
	MOVQ	$runtime·mainPC(SB), AX		// entry
	PUSHQ	AX
	CALL	runtime·newproc(SB)
	POPQ	AX

	// start this M
	CALL	runtime·mstart(SB)

	CALL	runtime·abort(SB)	// mstart should never return
	RET

bad_cpu:
	CALL	runtime·exit(SB)
	CALL	runtime·abort(SB)
	RET

// GetG returns the pointer to the current G and its P.
TEXT runtime·GetG(SB),NOSPLIT,$0-16
	get_tls(CX)
	MOVQ	g(CX), AX
	MOVQ	AX, gp+0(FP)

	MOVQ	(g_m)(AX), AX
	MOVQ	(m_p)(AX), AX
	MOVQ	AX, pp+8(FP)

	RET

// This is needed by asm_amd64.s
TEXT runtime·settls(SB),NOSPLIT,$32
	MOVW	runtime·testBinary(SB), AX
	CMPW	AX, $0
	JA	testing

	ADDQ	$8, DI	// ELF wants to use -8(FS)
	MOVQ	DI, AX
	MOVQ	$IA32_MSR_FS_BASE, CX
	MOVQ	$0x0, DX
	WRMSR
	RET

testing:
	ADDQ	$8, DI	// ELF wants to use -8(FS)
	MOVQ	DI, SI
	MOVQ	$0x1002, DI	// ARCH_SET_FS
	MOVQ	$SYS_arch_prctl, AX
	SYSCALL
	CMPQ	AX, $0xfffffffffffff001
	JLS	2(PC)
	MOVL	$0xf1, 0xf1  // crash
	RET

// WakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * AX: G pointer
TEXT runtime·WakeG(SB),NOSPLIT|NOFRAME,$0-0
	MOVQ	(g_timer)(AX), DX
	CMPQ	DX, $0
	JE	done

	// g->timer.when = 1
	MOVQ	$(1 << 32), BX
	MOVQ	BX, (timer_when)(DX)

	// g->timer.astate &= timerModified
	// g->timer.state  &= timerModified
	MOVQ	(timer_astate)(DX), CX
	ORQ	$const_timerModified<<8|const_timerModified, CX
	MOVQ	CX, (timer_astate)(DX)

	MOVQ	(timer_ts)(DX), AX
	CMPQ	AX, $0
	JE	done

	// g->timer.ts.minWhenModified = 1
	MOVQ	$(1 << 32), BX
	MOVQ	BX, (timers_minWhenModified)(AX)

	// len(g->timer.ts.heap)
	MOVQ	(timers_heap+8)(AX), CX
	CMPQ	CX, $0
	JE	done

	// offset to last element
	SUBQ	$1, CX
	MOVQ	$(timerWhen__size), BX
	IMULQ	BX, CX

	MOVQ	(timers_heap)(AX), AX
	CMPQ	AX, $0
	JE	done

	// g->timer.ts.heap[len-1]
	ADDQ	CX, AX
	JMP	check

prev:
	SUBQ	$(timerWhen__size), AX
	CMPQ	AX, $0
	JE	done

check:
	// find heap entry matching g.timer
	MOVQ	(timerWhen_timer)(AX), BX
	CMPQ	BX, DX
	JNE	prev

	// g->timer.ts.heap[off].when = 1
	MOVQ	$(1 << 32), BX
	MOVQ	BX, (timerWhen_when)(AX)

done:
	RET

// Wake modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
TEXT runtime·Wake(SB),$0-8
	MOVQ	gp+0(FP), AX
	JMP	runtime·WakeG(SB)
