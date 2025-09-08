// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

#define SYS_mmap 9

TEXT _rt0_amd64_tamago(SB),NOSPLIT|NOFRAME,$0
	MOVL	runtime·testBinary(SB), AX
	CMPL	AX, $0
	JA	testing

	// cpuinit must be provided externally by the linked application for
	// CPU initialization, it must call _rt0_tamago_start at completion
	JMP	cpuinit(SB)

testing:
	// when testing bare metal memory is mapped as OS virtual memory
	MOVQ	runtime·ramStart(SB), DI
	MOVQ	runtime·ramSize(SB), SI
	MOVL	$0x3, DX	// PROT_READ | PROT_WRITE
	MOVL	$0x22, R10	// MAP_PRIVATE | MAP_ANONYMOUS
	MOVL	$0xffffffff, R8
	MOVL	$0, R9
	MOVL	$SYS_mmap, AX
	SYSCALL

	JMP	_rt0_tamago_start(SB)

TEXT _rt0_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOVQ	runtime·ramStart(SB), SP
	MOVQ	runtime·ramSize(SB), AX
	MOVQ	runtime·ramStackOffset(SB), BX
	ADDQ	AX, SP
	SUBQ	BX, SP
	JMP	runtime·rt0_amd64_tamago(SB)
