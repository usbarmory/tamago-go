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
	BL	runtime·hwinit0(SB)
	BL	runtime·check(SB)
	BL	runtime·checkgoarm(SB)
	BL	runtime·osinit(SB)
	BL	runtime·schedinit(SB)
	BL	runtime·hwinit1(SB)

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

// func CallOnG0(func())
TEXT runtime·CallOnG0(SB),NOSPLIT,$0
	JMP	runtime·systemstack(SB)
	RET

TEXT runtime·findTimer(SB),NOSPLIT|NOFRAME,$0-0
	CMP	$0, R0
	B.EQ	fail

	MOVW	(g_timer)(R0), R3
	CMP	$0, R3
	B.EQ	fail

	MOVW	(timer_ts)(R3), R0
	CMP	$0, R0
	B.EQ	fail

	// len(g->timer.ts.heap)
	MOVW	(timers_heap+4)(R0), R2
	CMP	$0, R2
	B.EQ	fail

	// offset to last element
	SUB	$1, R2, R2
	MOVW	$(timerWhen__size), R1
	MUL	R1, R2, R2

	MOVW	(timers_heap)(R0), R0
	CMP	$0, R0
	B.EQ	fail

	// g->timer.ts.heap[len-1]
	ADD	R2, R0, R0
	B	check
prev:
	SUB	$(timerWhen__size), R0
	CMP	$0, R0
	B.EQ	fail
check:
	// find heap entry matching g.timer
	MOVW	(timerWhen_timer)(R0), R1
	CMP	R3, R1
	B.NE	prev

	MOVW	$0, R1
	RET
fail:
	MOVW	$1, R1
	RET

// wakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * R0: G pointer
//
// The function return values are passed through the following registers:
// (rather than on the frame pointer):
//
//   * R0: success (0), failure (1)
TEXT runtime·wakeG(SB),NOSPLIT,$0-0
	CALL	runtime·findTimer(SB)

	CMP	$0, R1
	B.NE	fail

	// g->timer.ts.heap[off] = 1
	MOVW	$1, R1
	MOVW	R1, (timerWhen_when+0)(R0)
	MOVW	$0, R1
	MOVW	R1, (timerWhen_when+4)(R0)

	// g->timer.when = 1
	MOVW	$1, R1
	MOVW	R1, (timer_when+0)(R3)
	MOVW	$0, R1
	MOVW	R1, (timer_when+4)(R3)

	// g->timer.astate &= timerModified
	// g->timer.state  &= timerModified
	MOVW	(timer_astate)(R3), R2
	ORR	$const_timerModified<<8|const_timerModified, R2, R2
	MOVW	R2, (timer_astate)(R3)

	// g->timer.ts.minWhenModified = 1
	MOVW	(timer_ts)(R3), R0
	MOVW	$1, R1
	MOVW	R1, (timers_minWhenModified+0)(R0)
	MOVW	$0, R1
	MOVW	R1, (timers_minWhenModified+4)(R0)

	MOVW	$0, R0
	RET
fail:
	MOVW	$1, R0
	RET

// never called (cgo not supported)
TEXT runtime·read_tls_fallback(SB),NOSPLIT|NOFRAME,$0
	MOVW	$0, R0
	MOVW	R0, (R0)
	RET
