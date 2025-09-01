// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm64

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
	MOVD	RSP, R20
	MOVD	RSP, R1
	SUB	$16, R1
	BIC	$15, R1	// Align for C code

	MOVW	$CLOCK_REALTIME, R0
	MOVD	$SYS_clock_gettime, R8
	SVC

	MOVD	0(RSP), R3	// sec
	MOVD	8(RSP), R5	// nsec

	MOVD	R20, RSP	// restore SP

	// sec is in R3, nsec in R5
	// return nsec in R3
	MOVD	$1000000000, R4
	MUL	R4, R3
	ADD	R5, R3
	MOVD	R3, ns+0(FP)
	RET

// func sys_exit_group(code int32)
TEXT ·sys_exit_group(SB), $0-4
	MOVW	code+0(FP), R0
	MOVD	$SYS_exit_group, R8
	SVC
	RET

// func sys_write(c *byte)
TEXT ·sys_write(SB),NOSPLIT,$0-8
	MOVW	$1, R0		// fd
	MOVD	c+0(FP), R1	// p
	MOVD	$1, R2		// n
	MOVW	$SYS_write, R8
	SVC
	RET

// func sys_getrandom(b []byte, n int)
TEXT ·sys_getrandom(SB), $0-32
	MOVD	b+0(FP), R0
	MOVD	n+24(FP), R1
	MOVW	$0, R2
	MOVW	$SYS_getrandom, R8
	SVC
	RET

// int32 clone(int32 flags, void *stack, M *mp, G *gp, void (*fn)(void));
// adapted from runtime/sys_linux_arm.s
TEXT ·clone(SB),NOSPLIT,$0
	MOVW	flags+0(FP), R0
	MOVD	stk+8(FP), R1

	// Copy mp, gp, fn off parent stack for use by child.
	MOVD	mp+16(FP), R10
	MOVD	gp+24(FP), R11
	MOVD	fn+32(FP), R12

	MOVD	R10, -8(R1)
	MOVD	R11, -16(R1)
	MOVD	R12, -24(R1)
	MOVD	$1234, R10
	MOVD	R10, -32(R1)

	MOVD	$SYS_clone, R8
	SVC

	// In parent, return.
	CMP	ZR, R0
	BEQ	child
	MOVW	R0, ret+40(FP)
	RET
child:

	// In child, on new stack.
	MOVD	-32(RSP), R10
	MOVD	$1234, R0
	CMP	R0, R10
	BEQ	good
	MOVD	$0, R0
	MOVD	R0, (R0)	// crash

good:
	MOVD	-24(RSP), R12     // fn
	MOVD	-16(RSP), R11     // g
	MOVD	-8(RSP), R10      // m

	CMP	$0, R10
	BEQ	nog
	CMP	$0, R11
	BEQ	nog

	// TODO: setup TLS.

	// In child, set up new stack
	MOVD	R10, 48(R11) // g_m(R11)
	MOVD	R11, g
	//CALL	runtime·stackcheck(SB)

nog:
	// Call fn
	MOVD	R12, R0
	BL	(R0)

	// It shouldn't return.	 If it does, exit that thread.
	MOVW	$111, R0
again:
	MOVD	$SYS_exit, R8
	SVC
	B	again	// keep exiting
