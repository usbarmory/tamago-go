// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

TEXT _rt0_arm_tamago(SB),NOSPLIT,$0
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
