// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

TEXT _rt0_arm_tamago(SB),NOSPLIT,$0
	// Detect HYP mode and switch to SVC if necessary
	WORD	$0xe10f0000	// mrs r0, CPSR
	AND	$0x1f, R0, R0	// get processor mode

	CMP	$0x10, R0	// USR mode
	B.EQ	runtime_start	// Skip initialization if USER mode

	CMP	$0x1a, R0	// HYP mode
	B.NE	after_eret	// Skip ERET if not HYP mode

	BIC	$0x1f, R0
	ORR	$0x1d3, R0	// AIF masked, SVC mode
	MOVW	$12(R15), R14	// add lr, pc, #12 (after_eret)
	WORD	$0xe16ff000	// msr SPSR_fsxc, r0
	WORD	$0xe12ef30e	// msr ELR_hyp, lr
	WORD	$0xe160006e	// eret

after_eret:
	// Enter System Mode
	WORD	$0xe321f0df	// msr CPSR_c, 0xdf

runtime_start:
	MOVW	runtime·ramStart(SB), R13
	MOVW	runtime·ramSize(SB), R1
	MOVW	runtime·ramStackOffset(SB), R2
	ADD	R1, R13
	SUB	R2, R13
	B	runtime·rt0_arm_tamago(SB)
