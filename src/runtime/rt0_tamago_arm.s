// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// for EABI, as we don't support OABI
#define SYS_BASE 0x0

#define SYS_mmap2 (SYS_BASE + 192)

TEXT _rt0_arm_tamago(SB),NOSPLIT|NOFRAME,$0
	MOVW	runtime·testBinary(SB), R0
	CMP	$0, R0
	B.EQ	start

	// when testing bare metal memory is mapped as OS virtual memory
	MOVW	runtime·ramStart(SB), R0
	MOVW	runtime·ramSize(SB), R1
	MOVW	$0x3, R2	// PROT_READ | PROT_WRITE
	MOVW	$0x22, R3	// MAP_PRIVATE | MAP_ANONYMOUS
	MOVW	$0xffffffff, R4
	MOVW	$0, R5
	MOVW	$SYS_mmap2, R7
	SWI	$0

	B	_rt0_arm_tamago_start(SB)

start:
	// Detect HYP mode and switch to SVC if necessary
	WORD	$0xe10f0000	// mrs r0, CPSR
	AND	$0x1f, R0, R0	// get processor mode

	CMP	$0x10, R0	// USR mode
	BL.EQ	_rt0_arm_tamago_start(SB)

	CMP	$0x1a, R0	// HYP mode
	B.NE	after_eret

	BIC	$0x1f, R0
	ORR	$0x1d3, R0	// AIF masked, SVC mode
	MOVW	$12(R15), R14	// add lr, pc, #12 (after_eret)
	WORD	$0xe16ff000	// msr SPSR_fsxc, r0
	WORD	$0xe12ef30e	// msr ELR_hyp, lr
	WORD	$0xe160006e	// eret

after_eret:
	// Enter System Mode
	WORD	$0xe321f0df	// msr CPSR_c, 0xdf

	B	_rt0_arm_tamago_start(SB)

TEXT _rt0_arm_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOVW	runtime·ramStart(SB), R13
	MOVW	runtime·ramSize(SB), R1
	MOVW	runtime·ramStackOffset(SB), R2
	ADD	R1, R13
	SUB	R2, R13
	B	runtime·rt0_arm_tamago(SB)
