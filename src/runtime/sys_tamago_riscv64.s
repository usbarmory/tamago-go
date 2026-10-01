// Copyright 2022 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//
// System calls and other sys.stuff for riscv64, tamago
//

#include "go_asm.h"
#include "go_tls.h"
#include "textflag.h"

TEXT runtime·rt0_riscv64_tamago(SB),NOSPLIT|NOFRAME,$0
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

	CALL	runtime·hwinit0(SB)
	CALL	runtime·check(SB)
	CALL	runtime·osinit(SB)
	CALL	runtime·schedinit(SB)
	CALL	runtime·hwinit1(SB)

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

// sigRelay sets the argument signal as pending (see sigqueue_tamago.go).
//
// The function is meant to be invoked, through os/signal.Relay, within
// interrupt/exception handlers and must therefore not allocate, lock or use
// the runtime.
TEXT runtime·sigRelay(SB),NOSPLIT|NOFRAME,$0-4
	MOVWU	sig+0(FP), T0
	MOV	$(const_numSig), T1
	BGEU	T0, T1, done

	// sigPending[sig/32] |= 1 << (sig%32)
	SRL	$5, T0, T1
	SLL	$2, T1, T1
	MOV	$runtime·sigPending(SB), T2
	ADD	T1, T2, T2
	AND	$31, T0, T0
	MOV	$1, T1
	SLL	T0, T1, T1
	AMOORW	T1, (T2), ZERO
done:
	RET
