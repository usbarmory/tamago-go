// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && riscv64

#include "go_asm.h"
#include "textflag.h"

#define CLOCK_REALTIME 0

#define SYS_write		64
#define SYS_exit		93
#define SYS_exit_group		94
#define SYS_clock_gettime	113
#define SYS_clone		220
#define SYS_getrandom		278

TEXT cpuinit(SB),NOSPLIT|NOFRAME,$0

// func sys_clock_gettime() int64
TEXT ·sys_clock_gettime(SB),NOSPLIT,$40-8
	MOV	$CLOCK_REALTIME, A0
	MOV	$8(X2), A1
	MOV	$SYS_clock_gettime, A7
	ECALL
	MOV	8(X2), T0	// sec
	MOV	16(X2), T1	// nsec
	MOV	$1000000000, T2
	MUL	T2, T0
	ADD	T1, T0
	MOV	T0, ns+0(FP)
	RET

// func sys_exit_group(code int32)
TEXT ·sys_exit_group(SB), $0-4
	MOVW	code+0(FP), A0
	MOV	$SYS_exit_group, A7
	ECALL
	RET

// func sys_write(c *byte)
TEXT ·sys_write(SB),NOSPLIT,$0-8
	MOV	$1, A0		// fd
	MOV	c+0(FP), A1	// p
	MOV	$1, A2		// n
	MOV	$SYS_write, A7
	ECALL
	RET

// func sys_getrandom(b []byte, n int)
TEXT ·sys_getrandom(SB), $0-32
	MOV	b+0(FP), A0
	MOV	n+24(FP), A1
	MOV	$0, A2
	MOV	$SYS_getrandom, A7
	ECALL
	RET

// func clone(flags int32, stk, mp, gp, fn unsafe.Pointer) int32
// adapted from runtime/sys_linux_riscv64.s
TEXT ·clone(SB),NOSPLIT|NOFRAME,$0
	MOVW	flags+0(FP), A0
	MOV	stk+8(FP), A1

	// Copy mp, gp, fn off parent stack for use by child.
	MOV	mp+16(FP), T0
	MOV	gp+24(FP), T1
	MOV	fn+32(FP), T2

	MOV	T0, -8(A1)
	MOV	T1, -16(A1)
	MOV	T2, -24(A1)
	MOV	$1234, T0
	MOV	T0, -32(A1)

	MOV	$SYS_clone, A7
	ECALL

	// In parent, return.
	BEQ	ZERO, A0, child
	MOVW	ZERO, ret+40(FP)
	RET

child:
	// In child, on new stack.
	MOV	-32(X2), T0
	MOV	$1234, A0
	BEQ	A0, T0, good
	WORD	$0	// crash

good:
	MOV	-24(X2), T2	// fn
	MOV	-16(X2), T1	// g
	MOV	-8(X2), T0	// m

	BEQ	ZERO, T0, nog
	BEQ	ZERO, T1, nog

	// In child, set up new stack
	MOV	T0, 48(T1) // g_m(T1)
	MOV	T1, g

nog:
	// Call fn
	JALR	RA, T2

	// It shouldn't return.  If it does, exit this thread.
	MOV	$111, A0
	MOV	$SYS_exit, A7
	ECALL
	JMP	-3(PC)	// keep exiting
