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

// WakeG modifies a goroutine cached timer for time.Sleep (g.timer) to fire as
// soon as possible.
//
// The function arguments must be passed through the following registers
// (rather than on the frame pointer):
//
//   * R0: G pointer
TEXT runtime·WakeG(SB),NOSPLIT|NOFRAME,$0-0
	MOVW	(g_timer)(T0), T0
	BEQ	T0, ZERO, done

	// g->timer.nextwhen = 1
	MOV	$(1 << 32), T1
	MOV	T1, (timer_nextwhen)(T0)

	// g->timer.status = timerModifiedEarlier
	MOV	$const_timerModifiedEarlier, T1
	MOV	T1, (timer_status+0)(T0)

	// g->m->p.timerModifiedEarliest = 1
	MOV	$1, T1
	MOV	runtime·allp(SB), T0
	MOV	(T0), T0
	MOV	T1, (p_timerModifiedEarliest)(T0)
done:
	RET

