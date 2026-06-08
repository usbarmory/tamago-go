// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for loong64, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

TEXT runtime·rt0_loong64_tamago(SB),NOSPLIT|NOFRAME,$0
	// create istack out of the bootstack
	MOVV	$runtime·g0(SB), g
	MOVV	$(-64*1024), R12
	ADDV	R12, R3, R13
	MOVV	R13, g_stackguard0(g)
	MOVV	R13, g_stackguard1(g)
	MOVV	R13, (g_stack+stack_lo)(g)
	MOVV	R3, (g_stack+stack_hi)(g)

	// set the per-goroutine and per-mach "registers"
	MOVV	$runtime·m0(SB), R12

	// save m->g0 = g0
	MOVV	g, m_g0(R12)
	// save m0 to g0->m
	MOVV	R12, g_m(g)

	JAL	runtime·hwinit0(SB)
	JAL	runtime·check(SB)
	JAL	runtime·osinit(SB)
	JAL	runtime·schedinit(SB)
	JAL	runtime·hwinit1(SB)

	// create a new goroutine to start program
	MOVV	$runtime·mainPC(SB), R12	// entry
	ADDV	$-16, R3
	MOVV	R12, 8(R3)
	MOVV	R0, 0(R3)
	JAL	runtime·newproc(SB)
	ADDV	$16, R3

	// start this M
	JAL	runtime·mstart(SB)

	WORD	$0 // crash if reached
	RET

// func GetG() (gp uint, pp uint)
TEXT runtime·GetG(SB),NOSPLIT,$0-16
	MOVV	g, gp+0(FP)

	MOVV	(g_m)(g), R12
	MOVV	(m_p)(R12), R12
	MOVV	R12, pp+8(FP)

	RET

TEXT runtime·findTimer(SB),NOSPLIT|NOFRAME,$0-0
	BEQ	R12, R0, fail

	MOVV	(g_timer)(R12), R15
	BEQ	R15, R0, fail

	MOVV	(timer_ts)(R15), R12
	BEQ	R12, R0, fail

	// len(g->timer.ts.heap)
	MOVV	(timers_heap+8)(R12), R14
	BEQ	R14, R0, fail

	// offset to last element
	SUBV	$1, R14, R14
	MOVV	$(timerWhen__size), R13
	MULVU	R13, R14, R14

	MOVV	(timers_heap)(R12), R12
	BEQ	R12, R0, fail

	// g->timer.ts.heap[len-1]
	ADDV	R14, R12, R12
	JMP	check
prev:
	SUBV	$(timerWhen__size), R12
	BEQ	R12, R0, fail
check:
	// find heap entry matching g.timer
	MOVV	(timerWhen_timer)(R12), R13
	BNE	R15, R13, prev

	MOVV	$0, R13
	RET
fail:
	MOVV	$1, R13
	RET

// WakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * R12: G pointer
//
// The function return values are passed through the following registers:
// (rather than on the frame pointer):
//
//   * R12: success (0), failure (1)
TEXT runtime·WakeG(SB),NOSPLIT,$0-0
	JAL	runtime·findTimer(SB)

	BNE	R13, R0, fail

	// g->timer.ts.heap[off] = 1
	MOVV	$1, R13
	MOVV	R13, (timerWhen_when)(R12)

	// g->timer.when = 1
	MOVV	$1, R13
	MOVV	R13, (timer_when)(R15)

	// g->timer.astate &= timerModified
	// g->timer.state  &= timerModified
	MOVV	(timer_astate)(R15), R14
	OR	$const_timerModified<<8|const_timerModified, R14, R14
	MOVV	R14, (timer_astate)(R15)

	// g->timer.ts.minWhenModified = 1
	MOVV	(timer_ts)(R15), R12
	MOVV	$1, R13
	MOVV	R13, (timers_minWhenModified)(R12)

	MOVV	$0, R12
	RET
fail:
	MOVV	$1, R12
	RET

// func Wake(gp uint) bool
TEXT runtime·Wake(SB),$0-9
	MOVV	gp+0(FP), R12
	JAL	runtime·WakeG(SB)
	XOR	$1, R12, R12
	MOVB	R12, ret+8(FP)
	RET
