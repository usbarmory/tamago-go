// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for arm, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

TEXT runtime·rt0_arm64_tamago(SB),NOSPLIT|NOFRAME,$0
	// set up g register
	// g is R10
	MOVD	$runtime·g0(SB), g
	MOVD	$runtime·m0(SB), R0

	// save m->g0 = g0
	MOVD	g, m_g0(R0)
	// save g->m = m0
	MOVD	R0, g_m(g)

	// create 64kB istack out of the bootstack
	MOVD	RSP, R7
	MOVD	$(-64*1024)(R7), R0
	MOVD	R0, g_stackguard0(g)
	MOVD	R0, g_stackguard1(g)
	MOVD	R0, (g_stack+stack_lo)(g)
	MOVD	R7, (g_stack+stack_hi)(g)

	BL	runtime·hwinit0(SB)
	BL	runtime·check(SB)
	BL	runtime·osinit(SB)
	BL	runtime·schedinit(SB)
	BL	runtime·hwinit1(SB)

	// create a new goroutine to start program
	MOVD	$runtime·mainPC(SB), R0		// entry
	SUB	$16, RSP
	MOVD	R0, 8(RSP) // arg
	MOVD	$0, 0(RSP) // dummy LR
	BL	runtime·newproc(SB)
	ADD	$16, RSP

	// start this M
	BL	runtime·mstart(SB)
	UNDEF

// GetG returns the pointer to the current G and its P.
TEXT runtime·GetG(SB),NOSPLIT,$0-16
	MOVD	g, gp+0(FP)

	MOVD	(g_m)(g), R0
	MOVD	(m_p)(R0), R0
	MOVD	R0, pp+8(FP)

	RET

// WakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
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
TEXT runtime·WakeG(SB),NOSPLIT|NOFRAME,$0-0
	MOVD	(g_timer)(R0), R3
	CMP	$0, R3
	BEQ	fail

	MOVD	(timer_ts)(R3), R0
	CMP	$0, R0
	BEQ	fail

	// len(g->timer.ts.heap)
	MOVD	(timers_heap+8)(R0), R2
	CMP	$0, R2
	BEQ	fail

	// offset to last element
	SUB	$1, R2, R2
	MOVD	$(timerWhen__size), R1
	MUL	R1, R2, R2

	MOVD	(timers_heap)(R0), R0
	CMP	$0, R0
	BEQ	fail

	// g->timer.ts.heap[len-1]
	ADD	R2, R0, R0
	B	check
prev:
	SUB	$(timerWhen__size), R0
	CMP	$0, R0
	BEQ	fail
check:
	// find heap entry matching g.timer
	MOVD	(timerWhen_timer)(R0), R1
	CMP	R3, R1
	BNE	prev

	// g->timer.ts.heap[off] = 1
	MOVD	$(1 << 32), R1
	MOVD	R1, (timerWhen_when)(R0)

	// g->timer.when = 1
	MOVD	$(1 << 32), R1
	MOVD	R1, (timer_when)(R3)

	// g->timer.astate &= timerModified
	// g->timer.state  &= timerModified
	MOVD	(timer_astate)(R3), R2
	ORR	$const_timerModified<<8|const_timerModified, R2, R2
	MOVD	R2, (timer_astate)(R3)

	// g->timer.ts.minWhenModified = 1
	MOVD	(timer_ts)(R3), R0
	MOVD	$(1 << 32), R1
	MOVD	R1, (timers_minWhenModified)(R0)

	MOVD	$0, R0
	RET
fail:
	MOVD	$1, R0
	RET

// Wake modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
TEXT runtime·Wake(SB),$0-9
	MOVD	gp+0(FP), R0
	CALL	runtime·WakeG(SB)
	EOR	$1, R0
	MOVB	R0, ret+8(FP)
	RET

// never called (cgo not supported)
TEXT runtime·read_tls_fallback(SB),NOSPLIT|NOFRAME,$0
	MOVD	$0, R0
	MOVD	R0, (R0)
	RET
