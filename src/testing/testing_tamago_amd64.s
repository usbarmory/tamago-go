// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && amd64 && user_linux

#include "go_asm.h"
#include "textflag.h"

#define SYS_write		1
#define SYS_mmap		9
#define SYS_clone		56
#define SYS_exit		60
#define SYS_clock_gettime	228
#define SYS_exit_group		231
#define SYS_getrandom		318

#define CLOCK_REALTIME 0

TEXT _rt0_amd64_tamago(SB),NOSPLIT|NOFRAME,$0
	MOVQ	runtime·ramStart(SB), DI
	MOVQ	runtime·ramSize(SB), SI
	MOVL	$0x3, DX	// PROT_READ | PROT_WRITE
	MOVL	$0x22, R10	// MAP_PRIVATE | MAP_ANONYMOUS
	MOVL	$0xffffffff, R8
	MOVL	$0, R9
	MOVL	$SYS_mmap, AX
	SYSCALL

	MOVQ	runtime·ramStart(SB), SP
	MOVQ	runtime·ramSize(SB), AX
	MOVQ	runtime·ramStackOffset(SB), BX
	ADDQ	AX, SP
	SUBQ	BX, SP
	JMP	runtime·rt0_amd64_tamago(SB)

// func sys_clock_gettime() int64
TEXT ·sys_clock_gettime(SB),NOSPLIT,$40-8
	SUBQ	$16, SP		// Space for results

	MOVL	$CLOCK_REALTIME, DI
	LEAQ	0(SP), SI
	MOVQ	$SYS_clock_gettime, AX
	SYSCALL

	MOVQ	0(SP), AX	// sec
	MOVQ	8(SP), DX	// nsec
	ADDQ	$16, SP

	IMULQ	$1000000000, AX
	ADDQ	DX, AX
	MOVQ	AX, ns+0(FP)

	RET

// func sys_exit_group(code int32)
TEXT ·sys_exit_group(SB), $0-4
	MOVL	code+0(FP), DI
	MOVL	$SYS_exit_group, AX
	SYSCALL
	RET

// func sys_write(c *byte)
TEXT ·sys_write(SB),NOSPLIT,$0-8
	MOVQ	$1, DI		// fd
	MOVQ	c+0(FP), SI	// p
	MOVL	$1, DX		// n
	MOVL	$SYS_write, AX
	SYSCALL
	RET

// func sys_getrandom(b []byte, n int)
TEXT ·sys_getrandom(SB), $0-32
	MOVQ	b+0(FP), DI
	MOVQ	n+24(FP), SI
	MOVL	$0, DX
	MOVL	$SYS_getrandom, AX
	SYSCALL
	RET

// int32 clone(int32 flags, void *stk, M *mp, G *gp, void (*fn)(void));
// adapted from runtime/sys_linux_amd64.s
TEXT ·clone(SB),NOSPLIT|NOFRAME,$0
	MOVL	flags+0(FP), DI
	MOVQ	stk+8(FP), SI
	MOVQ	$0, DX
	MOVQ	$0, R10
	MOVQ    $0, R8
	// Copy mp, gp, fn off parent stack for use by child.
	// Careful: Linux system call clobbers CX and R11.
	MOVQ	mp+16(FP), R13
	MOVQ	gp+24(FP), R9
	MOVQ	fn+32(FP), R12
	CMPQ	R13, $0    // m
	JEQ	nog1
	CMPQ	R9, $0    // g
	JEQ	nog1
	LEAQ	88(R13), R8 // m_tls(R13)
	ADDQ	$8, R8	// ELF wants to use -8(FS)
	ORQ 	$0x00080000, DI //add flag CLONE_SETTLS(0x00080000) to call clone
nog1:
	MOVL	$SYS_clone, AX
	SYSCALL

	// In parent, return.
	CMPQ	AX, $0
	JEQ	3(PC)
	MOVL	AX, ret+40(FP)
	RET

	// In child, on new stack.
	MOVQ	SI, SP

	// If g or m are nil, skip Go-related setup.
	CMPQ	R13, $0    // m
	JEQ	nog2
	CMPQ	R9, $0    // g
	JEQ	nog2

	// In child, set up new stack
	MOVQ	R9, g
	MOVQ	g, DI
	CALL	runtime·settls(SB)
	MOVQ	g, (TLS)

	MOVQ	TLS, CX
	MOVQ	R13, 48(R9) // g_m(R9)
	MOVQ	R9, 0(CX)(TLS*1)
	MOVQ	R9, R14 // set g register

nog2:
	// Call fn. This is the PC of an ABI0 function.
	CALL	R12

	// It shouldn't return. If it does, exit that thread.
	MOVL	$111, DI
	MOVL	$SYS_exit, AX
	SYSCALL
	JMP	-3(PC)	// keep exiting
