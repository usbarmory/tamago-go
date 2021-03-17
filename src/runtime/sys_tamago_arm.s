// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for arm, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

TEXT runtime·invallpages(SB),NOSPLIT,$0
	// Invalidate Instruction Cache + DSB
	MOVW	$0, R1
	MCR	15, 0, R1, C7, C5, 0
	MCR	15, 0, R1, C7, C10, 4

	// Invalidate unified TLB
	MCR	15, 0, R0, C8, C7, 0	// TLBIALL
	RET

TEXT runtime·dmb(SB),NOSPLIT,$0
	// Data Memory Barrier
	MOVW	$0, R0
	MCR	15, 0, R0, C7, C10, 5
	RET

TEXT runtime·set_exc_stack(SB),NOSPLIT,$0-4
	MOVW addr+0(FP), R0

	// Set IRQ mode SP
	WORD	$0xe321f0d2	// msr CPSR_c, 0xd2
	MOVW R0, R13

	// Set Abort mode SP
	WORD	$0xe321f0d7	// msr CPSR_c, 0xd7
	MOVW R0, R13

	// Set Undefined mode SP
	WORD	$0xe321f0db	// msr CPSR_c, 0xdb
	MOVW R0, R13

	// Set Supervisor mode SP
	WORD	$0xe321f0d3	// msr CPSR_c, 0xd3
	MOVW R0, R13

	// Return to System mode
	WORD	$0xe321f0df	// msr CPSR_c, 0xdf

	RET

TEXT runtime·set_vbar(SB),NOSPLIT,$0-4
	MOVW	addr+0(FP), R0
	MCR	15, 0, R0, C12, C0, 0
	RET

TEXT runtime·set_ttbr0(SB),NOSPLIT,$0-4
	MOVW	addr+0(FP), R0

	BL runtime·invallpages(SB)

	// Set TTBR0
	MCR	15, 0, R0, C2, C0, 0

	// Use TTBR0 for translation table walks
	MOVW	$0x0, R0
	MCR	15, 0, R0, C2, C0, 2

	// Set Domain Access
	MOVW	$0x3, R0
	MCR	15, 0, R0, C3, C0, 0

	// Invalidate Instruction Cache + DSB
	MOVW	$0, R0
	MCR	15, 0, R0, C7, C5, 0
	MCR	15, 0, R0, C7, C10, 4

	// Enable MMU
	MRC	15, 0, R0, C1, C0, 0
	ORR	$0x1, R0
	MCR	15, 0, R0, C1, C0, 0

	RET

TEXT runtime·processor_mode(SB),NOSPLIT,$0-4
	WORD	$0xe10f0000	// mrs r0, CPSR
	AND	$0x1f, R0, R0	// get processor mode
	MOVW	R0, ret+0(FP)

	RET

TEXT runtime·rt0_arm_tamago(SB),NOSPLIT|NOFRAME,$0
	MOVW	$0xcafebabe, R12

	MOVW R13, runtime·stackBottom(SB)

	// set up g register
	// g is R10
	MOVW	$runtime·g0(SB), g
	MOVW	$runtime·m0(SB), R8

	// save m->g0 = g0
	MOVW	g, m_g0(R8)
	// save g->m = m0
	MOVW	R8, g_m(g)

	// create 64kB istack out of the bootstack
	MOVW	$(-64*1024)(R13), R0
	MOVW	R0, g_stackguard0(g)
	MOVW	R0, g_stackguard1(g)
	MOVW	R0, (g_stack+stack_lo)(g)
	MOVW	R13, (g_stack+stack_hi)(g)

	BL	runtime·emptyfunc(SB)	// fault if stack check is wrong
	BL	runtime·hwinit(SB)
	BL	runtime·mmuinit(SB)
	BL	runtime·check(SB)
	BL	runtime·checkgoarm(SB)
	BL	runtime·osinit(SB)
	BL	runtime·vecinit(SB)
	BL	runtime·schedinit(SB)

	// create a new goroutine to start program
	MOVW	$runtime·mainPC(SB), R0
	MOVW.W	R0, -4(R13)
	MOVW	$8, R0
	MOVW.W	R0, -4(R13)
	MOVW	$0, R0
	MOVW.W	R0, -4(R13)	// push $0 as guard
	BL	runtime·newproc(SB)
	MOVW	$12(R13), R13	// pop args and LR

	// start this M
	BL	runtime·mstart(SB)

	MOVW	$1234, R0
	MOVW	$1000, R1
	MOVW	R0, (R1)	// fail hard

TEXT runtime·publicationBarrier(SB),NOSPLIT|NOFRAME,$0-0
	B	runtime·armPublicationBarrier(SB)

#define CALLFN_FROM_G0(FN, NAME)					\
	/* restore SP */						\
	MOVW	R13, (g_sched+gobuf_sp)(g)				\
									\
	/* restore PC from LR */					\
	MOVW	R14, (g_sched+gobuf_pc)(g)				\
									\
	/* restore g */							\
	MOVW	R14, (g_sched+gobuf_lr)(g)				\
	MOVW	g, (g_sched+gobuf_g)(g)					\
									\
	/* switch to g0 */						\
	MOVW	g_m(g), R1						\
	MOVW	m_g0(R1), R2						\
	MOVW	R2, g							\
	MOVW	(g_sched+gobuf_sp)(R2), R3				\
									\
	/* make it look like mstart called systemstack on g0 */		\
	/* to stop traceback (see runtime·systemstack)       */		\
	SUB	$4, R3, R3						\
	MOVW	$runtime·mstart(SB), R4					\
	MOVW	R4, 0(R3)						\
	MOVW	R3, R13							\
									\
	/* call handler function */					\
	MOVW	$NAME(SB), R0						\
	MOVW	$FN, R1							\
	MOVW	R1, off+0(FP)						\
	BL	(R0)							\
									\
	/* switch back to g */						\
	MOVW	g_m(g), R1						\
	MOVW	m_curg(R1), R0						\
	MOVW	R0, g							\
									\
	/* restore stack pointer */					\
	MOVW	(g_sched+gobuf_sp)(g), R13				\
	MOVW	$0, R3							\
	MOVW	R3, (g_sched+gobuf_sp)(g)				\

#define CALLFN_FROM_EXCEPTION(VECTOR, NAME, OFFSET, RN, SAVE_SIZE)	\
	/* restore stack pointer */					\
	WORD	$0xe105d200			/* mrs sp, SP_usr */	\
									\
	/* remove exception specific LR offset */			\
	SUB	$OFFSET, R14, R14					\
									\
	/* save caller registers */					\
	MOVM.DB		[R0-RN, R14], (R13)	/* push {r0-rN, r14} */	\
									\
	/* call exception handler from g0 */				\
	CALLFN_FROM_G0(VECTOR, NAME)					\
									\
	/* restore registers */						\
	SUB $SAVE_SIZE, R13, R13					\
	MOVM.IA.W	(R13), [R0-RN, R14]	/* pop {r0-rN, r14} */	\
									\
	/* restore PC from LR and mode */				\
	ADD	$OFFSET, R14, R14					\
	MOVW.S	R14, R15

TEXT runtime·resetHandler(SB),NOSPLIT|NOFRAME,$0
	CALLFN_FROM_EXCEPTION(0x0, ·exceptionHandler, 0, R12, 56)

TEXT runtime·undefinedHandler(SB),NOSPLIT|NOFRAME,$0
	CALLFN_FROM_EXCEPTION(0x4, ·exceptionHandler, 4, R12, 56)

TEXT runtime·svcHandler(SB),NOSPLIT|NOFRAME,$0
	CALLFN_FROM_EXCEPTION(0x8, ·exceptionHandler, 0, R12, 56)

TEXT runtime·prefetchAbortHandler(SB),NOSPLIT|NOFRAME,$0
	CALLFN_FROM_EXCEPTION(0xc, ·exceptionHandler, 4, R12, 56)

TEXT runtime·dataAbortHandler(SB),NOSPLIT|NOFRAME,$0
	CALLFN_FROM_EXCEPTION(0x10, ·exceptionHandler, 8, R12, 56)

TEXT runtime·irqHandler(SB),NOSPLIT|NOFRAME,$0
	CALLFN_FROM_EXCEPTION(0x18, ·exceptionHandler, 4, R12, 56)

TEXT runtime·fiqHandler(SB),NOSPLIT|NOFRAME,$0
	CALLFN_FROM_EXCEPTION(0x1c, ·exceptionHandler, 4, R7, 36)

// never called (cgo not supported)
TEXT runtime·read_tls_fallback(SB),NOSPLIT|NOFRAME,$0
	MOVW	$0, R0
	MOVW	R0, (R0)
	RET
