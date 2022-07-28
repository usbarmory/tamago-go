// Copyright 2022 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "go_asm.h"
#include "go_tls.h"
#include "funcdata.h"
#include "textflag.h"

#define s0 8
#define uie     0x004
#define sie     0x104
#define hie     0x204
#define mstatus 0x300
#define mie     0x304

#define CSRC(RS,CSR) WORD $(0x3073 + RS<<15 + CSR<<20)
#define CSRS(RS,CSR) WORD $(0x2073 + RS<<15 + CSR<<20)
#define CSRW(RS,CSR) WORD $(0x1073 + RS<<15 + CSR<<20)

TEXT _rt0_riscv64_tamago(SB),NOSPLIT|NOFRAME,$0
	// Disable interrupts
	MOV	$0, S0
	CSRW	(s0, sie)
	CSRW	(s0, mie)
	MOV	$0x7FFF, S0
	CSRC	(s0, mstatus)

	// Enable FPU
	MOV	$(1<<13), S0
	CSRS	(s0, mstatus)

runtime_start:
	MOV	runtime·ramStart(SB), X2
	MOV	runtime·ramSize(SB), T1
	MOV	runtime·ramStackOffset(SB), T2
	ADD	T1, X2
	SUB	T2, X2
	JMP	runtime·rt0_riscv64_tamago(SB)
