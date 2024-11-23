// Copyright 2022 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

#define SYS_mmap 222

// entry point for M privilege level instances
TEXT _rt0_riscv64_tamago(SB),NOSPLIT|NOFRAME,$0
	MOV	runtime·testBinary(SB), T0
	BGT	T0, ZERO, testing

	// cpuinit must be provided externally by the linked application for
	// CPU initialization, it must call _rt0_tamago_start at completion
	JMP	cpuinit(SB)

testing:
	// when testing bare metal memory is mapped as OS virtual memory
	MOV	runtime·ramStart(SB), A0
	MOV	runtime·ramSize(SB), A1
	MOV	$0x3, A2	// PROT_READ | PROT_WRITE
	MOV	$0x22, A3	// MAP_PRIVATE | MAP_ANONYMOUS
	MOV	$0xffffffff, A4
	MOV	$0, A5
	MOV	$SYS_mmap, A7
	ECALL

	JMP	_rt0_tamago_start(SB)

// entry point for S/U privilege level instances
TEXT _rt0_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOV	runtime·ramStart(SB), X2
	MOV	runtime·ramSize(SB), T1
	MOV	runtime·ramStackOffset(SB), T2
	ADD	T1, X2
	SUB	T2, X2
	JMP	runtime·rt0_riscv64_tamago(SB)
