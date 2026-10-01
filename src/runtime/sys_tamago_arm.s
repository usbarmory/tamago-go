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

// sigRelay sets the argument signal as pending (see sigqueue_tamago.go).
//
// The function is meant to be invoked, through os/signal.Relay, within
// interrupt/exception handlers and must therefore not allocate, lock or use
// the runtime.
TEXT runtime·sigRelay(SB),NOSPLIT|NOFRAME,$0-4
	MOVW	sig+0(FP), R0
	CMP	$(const_numSig), R0
	B.HS	done

	// sigPending[sig/32] |= 1 << (sig%32)
	MOVW	R0>>5, R1
	AND	$31, R0, R0
	MOVW	$1, R2
	MOVW	R2<<R0, R2
	MOVW	$runtime·sigPending(SB), R3
	ADD	R1<<2, R3, R3
#ifndef GOARM_6
	// ARMv5 (uniprocessor): mask interrupts as done by runtime atomics
	// (see internal/runtime/atomic·armcas).
	WORD	$0xe10f4000	// MRS R4, CPSR (save)
	ORR	$0xc0, R4, R5	// mask IRQ+FIQ
	WORD	$0xe121f005	// MSR CPSR_c, R5
	MOVW	(R3), R1
	ORR	R2, R1, R1
	MOVW	R1, (R3)
	WORD	$0xe121f004	// MSR CPSR_c, R4 (restore)
#else
loop:
	LDREX	(R3), R1
	ORR	R2, R1, R1
	STREX	R1, (R3), R0
	CMP	$0, R0
	B.NE	loop
#ifdef GOARM_7
	DMB	MB_ISH
#endif
#endif
done:
	RET

// never called (cgo not supported)
TEXT runtime·read_tls_fallback(SB),NOSPLIT|NOFRAME,$0
	MOVW	$0, R0
	MOVW	R0, (R0)
	RET
