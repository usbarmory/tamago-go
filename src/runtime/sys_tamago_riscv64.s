// Copyright 2022 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for riscv64, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

TEXT runtime·rt0_riscv64_tamago(SB),NOSPLIT|TOPFRAME,$0
	// create istack out of the bootstack
	MOV	$runtime·g0(SB), g
	MOV	$(-64*1024), T0
	ADD	T0, X2, T1
	MOV	T1, g_stackguard0(g)
	MOV	T1, g_stackguard1(g)
	MOV	T1, (g_stack+stack_lo)(g)
	MOV	X2, (g_stack+stack_hi)(g)

	// set the per-goroutine and per-mach "registers"
	MOV	$runtime·m0(SB), T0

	// save m->g0 = g0
	MOV	g, m_g0(T0)
	// save m0 to g0->m
	MOV	T0, g_m(g)

	CALL	runtime·hwinit(SB)
	CALL	runtime·check(SB)

	// args are already prepared
	CALL	runtime·args(SB)
	CALL	runtime·osinit(SB)
	CALL	runtime·schedinit(SB)

	// create a new goroutine to start program
	MOV	$runtime·mainPC(SB), T0		// entry
	ADD	$-16, X2
	MOV	T0, 8(X2)
	MOV	ZERO, 0(X2)
	CALL	runtime·newproc(SB)
	ADD	$16, X2

	// start this M
	CALL	runtime·mstart(SB)

	WORD $0 // crash if reached
	RET

// GetG returns the pointer to the current G and its P.
TEXT runtime·GetG(SB),NOSPLIT,$0-16
	MOV	g, gp+0(FP)

	MOV	(g_m)(g), T0
	MOV	(m_p)(T0), T0
	MOV	T0, pp+8(FP)

	RET

// WakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * T0: G pointer
TEXT runtime·WakeG(SB),NOSPLIT|NOFRAME,$0-0
	MOV	(g_timer)(T0), T0
	BEQ	T0, ZERO, done

	// g->timer.when = 1
	MOV	$(1 << 32), T1
	MOV	T1, (timer_when)(T0)

	// g->timer.astate &= timerModified
	// g->timer.state  &= timerModified
	MOV	(timer_astate)(T0), T2
	OR	$const_timerModified<<8|const_timerModified, T2, T2
	MOV	T2, (timer_astate)(T0)

	MOV	(timer_ts)(T0), T0
	BEQ	T0, ZERO, done

	// g->timer.ts.minWhenModified = 1
	MOV	$(1 << 32), T1
	MOV	T1, (timers_minWhenModified)(T0)

	// len(g->timer.ts.heap)
	MOV	(timers_heap+8)(T0), T2
	BEQ	T2, ZERO, done

	// offset to last element
	SUB	$1, T2, T2
	MOV	$(timerWhen__size), T3
	MUL	T3, T2, T2

	MOV	(timers_heap)(T0), T0
	BEQ	T0, ZERO, done

	// g->timer.ts.heap[len-1]
	ADD	T2, T0, T0
	JMP	check

prev:
	SUB	$(timerWhen__size), T0
	BEQ	T0, ZERO, done

check:
	// find longest timer as *timers.adjust() might be pending
	MOV	(timerWhen_when)(T0), T1
	MOV	$((1 << 63) - 1), T2 // math.MaxInt64
	BNE	T2, T1, prev

	// g->timer.ts.heap[off] = 1
	MOV	$(1 << 32), T1
	MOV	T1, (timerWhen_when)(T0)

done:
	RET
