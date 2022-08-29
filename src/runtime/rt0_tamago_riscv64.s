// Copyright 2022 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "go_asm.h"
#include "go_tls.h"
#include "funcdata.h"
#include "textflag.h"

#define t0 5

#define sie     0x104
#define mstatus 0x300
#define mie     0x304

#define CSRC(RS,CSR) WORD $(0x3073 + RS<<15 + CSR<<20)
#define CSRS(RS,CSR) WORD $(0x2073 + RS<<15 + CSR<<20)
#define CSRW(RS,CSR) WORD $(0x1073 + RS<<15 + CSR<<20)

// entry point for M privilege level instances
TEXT _rt0_riscv64_tamago(SB),NOSPLIT|NOFRAME,$0
	// Disable interrupts
	MOV	$0, T0
	CSRW	(t0, sie)
	CSRW	(t0, mie)
	MOV	$0x7FFF, T0
	CSRC	(t0, mstatus)

	// Enable FPU
	MOV	$(1<<13), T0
	CSRS	(t0, mstatus)

	JMP	_rt0_riscv64_tamago_start(SB)

// entry point for S/U privilege level instances
TEXT _rt0_riscv64_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOV	runtime·ramStart(SB), X2
	MOV	runtime·ramSize(SB), T1
	MOV	runtime·ramStackOffset(SB), T2
	ADD	T1, X2
	SUB	T2, X2
	JMP	runtime·rt0_riscv64_tamago(SB)
