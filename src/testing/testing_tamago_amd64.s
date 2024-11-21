// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && amd64

#include "go_asm.h"
#include "textflag.h"

#define CLOCK_REALTIME 0

#define SYS_write		1
#define SYS_exit		60
#define SYS_clock_gettime	228
#define SYS_getrandom		318

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

// func sys_exit(code int32)
TEXT ·sys_exit(SB), $0-4
	MOVL	code+0(FP), DI
	MOVL	$SYS_exit, AX
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
