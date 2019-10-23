// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for arm, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

TEXT runtime·invallpages(SB), NOSPLIT, $0
	WORD	$0xf57ff06f		// isb sy
	WORD	$0xf57ff04f		// dsb sy

	// Invalidate unified TLB
	MCR	15, 0, R0, C8, C7, 0	// TLBIALL
	RET

TEXT runtime·dmb(SB), NOSPLIT, $0
	WORD	$0xf57ff05e		// DMB ST
	RET

TEXT runtime·set_exc_stack(SB), NOSPLIT, $0-4
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

	// Return to Supervisor mode
	WORD	$0xe321f0d3	// msr CPSR_c, 0xd3

	RET

TEXT runtime·set_vbar(SB), NOSPLIT, $0-4
	MOVW	addr+0(FP), R0
	MCR	15, 0, R0, C12, C0, 0
	RET

TEXT runtime·set_ttbr0(SB), NOSPLIT, $0-4
	MOVW	addr+0(FP), R0

	B runtime·invallpages(SB)

	// Set TTBR0
	MCR	15, 0, R0, C2, C0, 0

	// Use TTBR0 for translation table walks
	MOVW	$0x0, R0
	MCR	15, 0, R0, C2, C0, 2

	// Set Domain Access
	MOVW	$0x3, R0
	MCR	15, 0, R0, C3, C0, 0

	WORD	$0xf57ff06f	// isb sy
	WORD	$0xf57ff04f	// dsb sy

	// Enable MMU
	MRC	15, 0, R0, C1, C0, 0
	ORR	$0x1, R0
	MCR	15, 0, R0, C1, C0, 0

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
	BL	runtime·check(SB)
	BL	runtime·checkgoarm(SB)
	BL	runtime·osinit(SB)
	BL	runtime·vecinit(SB)
	BL	runtime·mmuinit(SB)
	BL	runtime·excstackinit(SB)
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

// exit sequence for `qemu -semihosting`
TEXT runtime·semihostingstop(SB), NOSPLIT, $0
	MOVW	$0x18,    R0
	MOVW	$0x20026, R1
	WORD	$0xef123456	// svc 0x00123456
	RET

TEXT ·publicationBarrier(SB),NOSPLIT|NOFRAME,$0-0
	B	runtime·armPublicationBarrier(SB)
