// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm

#include "go_asm.h"
#include "textflag.h"

#define CLOCK_REALTIME 0

// for EABI, as we don't support OABI
#define SYS_BASE 0x0

#define SYS_exit		(SYS_BASE + 1)
#define SYS_write		(SYS_BASE + 4)
#define SYS_clone		(SYS_BASE + 120)
#define SYS_exit_group		(SYS_BASE + 248)
#define SYS_clock_gettime	(SYS_BASE + 263)
#define SYS_getrandom		(SYS_BASE + 384)

TEXT cpuinit(SB),NOSPLIT|NOFRAME,$0

// func sys_clock_gettime() int64
TEXT ·sys_clock_gettime(SB),NOSPLIT,$12-8
	MOVW	$CLOCK_REALTIME, R0
	MOVW	$spec-12(SP), R1	// timespec

	MOVW	$SYS_clock_gettime, R7
	SWI	$0

	MOVW	sec-12(SP), R0	// sec
	MOVW	nsec-8(SP), R2	// nsec

	MOVW	$1000000000, R3
	MULLU	R0, R3, (R1, R0)
	ADD.S	R2, R0
	ADC	$0, R1	// Add carry bit to upper half.

	MOVW	R0, ns_lo+0(FP)
	MOVW	R1, ns_hi+4(FP)

	RET

// func sys_exit_group(code int32)
TEXT ·sys_exit_group(SB), $0-4
	MOVW	code+0(FP), R0
	MOVW	$SYS_exit_group, R7
	SWI	$0
	RET

// func sys_write(c *byte)
TEXT ·sys_write(SB),NOSPLIT,$0-4
	MOVW	$1, R0		// fd
	MOVW	c+0(FP), R1	// p
	MOVW	$1, R2		// n
	MOVW	$SYS_write, R7
	SWI	$0
	RET

// func sys_getrandom(b []byte, n int)
TEXT ·sys_getrandom(SB), $0-16
	MOVW	b+0(FP), R0
	MOVW	n+12(FP), R1
	MOVW	$0, R2
	MOVW	$SYS_getrandom, R7
	SWI	$0
	RET

// int32 clone(int32 flags, void *stack, M *mp, G *gp, void (*fn)(void));
// adapted from runtime/sys_linux_arm.s
TEXT ·clone(SB),NOSPLIT,$0
	MOVW	flags+0(FP), R0
	MOVW	stk+4(FP), R1
	MOVW	$0, R2	// parent tid ptr
	MOVW	$0, R3	// tls_val
	MOVW	$0, R4	// child tid ptr
	MOVW	$0, R5

	// Copy mp, gp, fn off parent stack for use by child.
	MOVW	$-16(R1), R1
	MOVW	mp+8(FP), R6
	MOVW	R6, 0(R1)
	MOVW	gp+12(FP), R6
	MOVW	R6, 4(R1)
	MOVW	fn+16(FP), R6
	MOVW	R6, 8(R1)
	MOVW	$1234, R6
	MOVW	R6, 12(R1)

	MOVW	$SYS_clone, R7
	SWI	$0

	// In parent, return.
	CMP	$0, R0
	BEQ	3(PC)
	MOVW	R0, ret+20(FP)
	RET

	// Paranoia: check that SP is as we expect. Use R13 to avoid linker 'fixup'
	NOP	R13	// tell vet SP/R13 changed - stop checking offsets
	MOVW	12(R13), R0
	MOVW	$1234, R1
	CMP	R0, R1
	BEQ	2(PC)
	BL	runtime·abort(SB)

	MOVW	0(R13), R8    // m
	MOVW	4(R13), R0    // g

	CMP	$0, R8
	BEQ	nog
	CMP	$0, R0
	BEQ	nog

	MOVW	R0, g
	MOVW	R8, (24)(g) // g_m(g)

	// paranoia; check they are not nil
	MOVW	0(R8), R0
	MOVW	0(g), R0

	BL	runtime·emptyfunc(SB)	// fault if stack check is wrong

nog:
	// Call fn
	MOVW	8(R13), R0
	MOVW	$16(R13), R13
	BL	(R0)

	// It shouldn't return. If it does, exit that thread.
	SUB	$16, R13 // restore the stack pointer to avoid memory corruption
	MOVW	$0, R0
	MOVW	R0, 4(R13)

	MOVW	$SYS_exit, R7
	SWI	$0
	MOVW	$1234, R0
	MOVW	$1005, R1
	MOVW	R0, (R1)
