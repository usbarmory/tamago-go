// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

#define SYS_mmap 222

TEXT _rt0_arm64_tamago(SB),NOSPLIT|NOFRAME,$0
	MOVD	runtime·testBinary(SB), R0
	CMP	$0, R0
	BGT	testing

	// cpuinit must be provided externally by the linked application for
	// CPU initialization, it must call _rt0_tamago_start at completion
	B	cpuinit(SB)

testing:
	// when testing bare metal memory is mapped as OS virtual memory
	MOVD	runtime·ramStart(SB), R0
	MOVD	runtime·ramSize(SB), R1
	MOVW	$0x3, R2	// PROT_READ | PROT_WRITE
	MOVW	$0x22, R3	// MAP_PRIVATE | MAP_ANONYMOUS
	MOVW	$0xffffffff, R4
	MOVW	$0, R5
	MOVW	$SYS_mmap, R8
	SVC

	B	_rt0_tamago_start(SB)

TEXT _rt0_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOVD	runtime·ramStart(SB), R1
	MOVD	R1, RSP
	MOVD	runtime·ramSize(SB), R1
	MOVD	runtime·ramStackOffset(SB), R2
	ADD	R1, RSP
	SUB	R2, RSP
	B	runtime·rt0_arm64_tamago(SB)
