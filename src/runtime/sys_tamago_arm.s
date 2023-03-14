// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for arm, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

TEXT runtime·rt0_arm_tamago(SB),NOSPLIT|NOFRAME,$0
	MOVW	$0xcafebabe, R12

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
	BL	runtime·schedinit(SB)

	// create a new goroutine to start program
	SUB	$8, R13
	MOVW	$runtime·mainPC(SB), R0
	MOVW	R0, 4(R13)	// arg 1: fn
	MOVW	$0, R0
	MOVW	R0, 0(R13)	// dummy LR
	BL	runtime·newproc(SB)
	MOVW	$12(R13), R13	// pop args and LR

	// start this M
	BL	runtime·mstart(SB)

	MOVW	$1234, R0
	MOVW	$1000, R1
	MOVW	R0, (R1)	// fail hard

TEXT runtime·publicationBarrier(SB),NOSPLIT|NOFRAME,$0-0
	B	runtime·armPublicationBarrier(SB)

// CallOnG0 calls a function (func(off int)) on g0 stack.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * R0: fn argument (vector table offset)
//   * R1: fn pointer
//   * R2: caller program counter
TEXT runtime·CallOnG0(SB),NOSPLIT|NOFRAME,$0-0
	MOVW	$runtime·g0(SB), R5
	CMP	g, R5
	B.EQ	noswitch

	// save LR as Thread ID (TPIDRURW)
	MCR	15, 0, R14, C13, C0, 2

	// save our state in g->sched
	MOVW	R13, (g_sched+gobuf_sp)(g)
	MOVW	R2, (g_sched+gobuf_pc)(g)
	MOVW	R2, (g_sched+gobuf_lr)(g)
	MOVW	g, (g_sched+gobuf_g)(g)

	// switch to g0
	MOVW	g_m(g), R6
	MOVW	m_g0(R6), R2
	MOVW	R2, g
	MOVW	(g_sched+gobuf_sp)(R2), R3

	// make it look like mstart called systemstack on g0, to stop traceback
	SUB	$4, R3, R3
	MOVW	$runtime·mstart(SB), R4
	MOVW	R4, 0(R3)
	MOVW	R3, R13

	// call target function
	MOVW	R0, off+0(FP)
	BL	(R1)

	// switch back to g
	MOVW	g_m(g), R1
	MOVW	m_curg(R1), R0
	MOVW	R0, g
	MOVW	$0, R3
	MOVW	R3, (g_sched+gobuf_sp)(g)

	// restore PC from Thread ID (TPIDRURW)
	MRC	15, 0, R5, C13, C0, 2
	MOVW	R5, R15

noswitch:
	// call target function
	MOVW	R0, off+0(FP)
	B	(R1)

// never called (cgo not supported)
TEXT runtime·read_tls_fallback(SB),NOSPLIT|NOFRAME,$0
	MOVW	$0, R0
	MOVW	R0, (R0)
	RET
