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


// sigRelay sets the argument signal as pending (see sigqueue_tamago.go).
//
// The function is meant to be invoked, through os/signal.Relay, within
// interrupt/exception handlers and must therefore not allocate, lock or use
// the runtime.
TEXT runtime·sigRelay(SB),NOSPLIT|NOFRAME,$0-4
	MOVWU	sig+0(FP), R12
	MOVV	$(const_numSig), R13
	BGEU	R12, R13, done

	// sigPending[sig/32] |= 1 << (sig%32)
	SRLV	$5, R12, R13
	SLLV	$2, R13, R13
	MOVV	$runtime·sigPending(SB), R14
	ADDV	R13, R14, R14
	AND	$31, R12, R12
	MOVV	$1, R13
	SLLV	R12, R13, R13
	AMORDBW	R13, (R14), R0
done:
	RET
