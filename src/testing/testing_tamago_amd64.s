// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && amd64

#include "go_asm.h"
#include "textflag.h"

#define SYS_write		1
#define SYS_exit		60
#define SYS_clock_gettime	228
#define SYS_getrandom		318

// func sys_clock_gettime() int64
TEXT ·sys_clock_gettime(SB),NOSPLIT,$40-8
	MOVQ	$SYS_clock_gettime, AX
	SYSCALL

	MOVQ	0(SP), AX	// sec
	MOVQ	8(SP), DX	// nsec
	MOVQ	R12, SP		// Restore real SP
	// sec is in AX, nsec in DX
	// return nsec in AX
	IMULQ	$1000000000, AX
	ADDQ	DX, AX
	MOVQ	AX, ret+0(FP)
	RET

// func sys_exit(code int32)
TEXT ·sys_exit(SB), $0-4
	MOVL	code+0(FP), DI
	MOV	$SYS_exit, AX
	SYSCALL
	RET

// func sys_write(c *byte)
TEXT ·sys_write(SB),NOSPLIT,$0-8
	MOV	$1, DI		// fd
	MOV	c+0(FP), SI	// p
	MOV	$1, DX		// n
	MOV	$SYS_write, AX
	SYSCALL
	RET

// func sys_getrandom(b []byte, n int)
TEXT ·sys_getrandom(SB), $0-32
	MOV	b+0(FP), DI
	MOV	n+24(FP), SI
	MOV	$0, DX
	MOV	$SYS_getrandom, AX
	SYSCALL
	RET
