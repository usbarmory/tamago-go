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

	// cpuinit must be provided externally by the linked application for
	// CPU initialization, it must call _rt0_tamago_start at completion
	BL.EQ	cpuinit(SB)

	// when testing bare metal memory is mapped as OS virtual memory
	MOVW	runtime·ramStart(SB), R0
	MOVW	runtime·ramSize(SB), R1
	MOVW	$0x3, R2	// PROT_READ | PROT_WRITE
	MOVW	$0x22, R3	// MAP_PRIVATE | MAP_ANONYMOUS
	MOVW	$0xffffffff, R4
	MOVW	$0, R5
	MOVW	$SYS_mmap2, R7
	SWI	$0

	B	_rt0_tamago_start(SB)

TEXT _rt0_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOVW	runtime·ramStart(SB), R13
	MOVW	runtime·ramSize(SB), R1
	MOVW	runtime·ramStackOffset(SB), R2
	ADD	R1, R13
	SUB	R2, R13
	B	runtime·rt0_arm_tamago(SB)
