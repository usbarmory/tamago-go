// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

TEXT _rt0_arm_tamago(SB),NOSPLIT,$0
	// Raspberry Pi firmware sets CPU to HYP mode.
	// Detect if in HYP mode and switch out of HYP mode
	// to SVC mode (borrow technique from Linux kernel).
	WORD	$0xe10f0000 	// mrs	r0, CPSR
	WORD	$0xe220001a 	// eor	r0, r0, #26
	WORD	$0xe310001f 	// tst	r0, #31
	WORD	$0xe3c0001f 	// bic	r0, r0, #31
	WORD	$0xe38000d3 	// orr	r0, r0, #211	; 0xd3
	WORD	$0x1a000004 	// bne	#0x18 (past eret)
	WORD	$0xe3800c01 	// orr	r0, r0, #256	; 0x100
	WORD	$0xe28fe00c 	// add	lr, pc, #12
	WORD	$0xe16ff000 	// msr	SPSR_fsxc, r0
	WORD	$0xe12ef30e 	// msr	ELR_hyp, lr
	WORD	$0xe160006e 	// eret

	// Disable MMU as soon as possible. Will be re-enabled in mmuinit().
	MRC	15, 0, R0, C1, C0, 0
	BIC	$0x1, R0
	MCR	15, 0, R0, C1, C0, 0

	// Enter System Mode
	WORD	$0xe321f0df	// msr CPSR_c, 0xdf

	MOVW	runtime·ramStart(SB), R13
	MOVW	runtime·ramSize(SB), R1
	MOVW	runtime·ramStackOffset(SB), R2
	ADD	R1, R13
	SUB	R2, R13
	B	runtime·rt0_arm_tamago(SB)
