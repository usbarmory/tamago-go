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

// sigRelay sets the argument signal as pending (see sigqueue_tamago.go).
//
// The function is meant to be invoked, through os/signal.Relay, within
// interrupt/exception handlers and must therefore not allocate, lock or use
// the runtime.
TEXT runtime·sigRelay(SB),NOSPLIT|NOFRAME,$0-4
	MOVWU	sig+0(FP), R0
	CMP	$(const_numSig), R0
	BHS	done

	// sigPending[sig/32] |= 1 << (sig%32)
	LSR	$5, R0, R1
	AND	$31, R0, R0
	MOVD	$1, R2
	LSLW	R0, R2, R2
	MOVD	$runtime·sigPending(SB), R3
	ADD	R1<<2, R3, R3
loop:
	LDAXRW	(R3), R1
	ORRW	R2, R1, R1
	STLXRW	R1, (R3), R0
	CBNZ	R0, loop
done:
	RET

// never called (cgo not supported)
TEXT runtime·read_tls_fallback(SB),NOSPLIT|NOFRAME,$0
	MOVD	$0, R0
	MOVD	R0, (R0)
	RET
