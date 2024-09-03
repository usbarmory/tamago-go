// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build arm

#include "go_asm.h"
#include "textflag.h"

#define CLOCK_REALTIME	0

// for EABI, as we don't support OABI
#define SYS_BASE 0x0

#define SYS_exit (SYS_BASE + 1)
#define SYS_write (SYS_BASE + 4)
#define SYS_clock_gettime (SYS_BASE + 263)
#define SYS_getrandom (SYS_BASE + 384)

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

	MOVW	R0, ret_lo+0(FP)
	MOVW	R1, ret_hi+4(FP)

	RET

// func sys_exit(code int32)
TEXT ·sys_exit(SB), $0-4
	MOVW	code+0(FP), R0
	MOVW	$SYS_exit, R7
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
