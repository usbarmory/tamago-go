// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && loong64

#include "go_asm.h"
#include "textflag.h"

#define SYS_write		64
#define SYS_exit		93
#define SYS_exit_group		94
#define SYS_clock_gettime	113
#define SYS_clone		220
#define SYS_mmap		222
#define SYS_getrandom		278

#define CLOCK_REALTIME 0

TEXT ·CPUInit(SB),NOSPLIT|NOFRAME,$0
	MOVV	·RamStart(SB), R4
	MOVV	·RamSize(SB), R5
	MOVV	$0x3, R6	// PROT_READ | PROT_WRITE
	MOVV	$0x22, R7	// MAP_PRIVATE | MAP_ANONYMOUS
	MOVV	$0xffffffff, R8
	MOVV	$0, R9
	MOVV	$SYS_mmap, R11
	SYSCALL

	// set stack pointer
	MOVV	·RamStart(SB), R3
	MOVV	·RamSize(SB), R13
	MOVV	·RamStackOffset(SB), R14
	ADDV	R13, R3
	SUBV	R14, R3

	JMP	runtime·rt0_loong64_tamago(SB)

// func sys_clock_gettime() int64
TEXT ·sys_clock_gettime(SB),NOSPLIT,$40-8
	MOVV	$CLOCK_REALTIME, R4
	MOVV	$8(R3), R5
	MOVV	$SYS_clock_gettime, R11
	SYSCALL
	MOVV	8(R3), R12	// sec
	MOVV	16(R3), R13	// nsec
	MOVV	$1000000000, R14
	MULVU	R14, R12, R12
	ADDV	R13, R12, R12
	MOVV	R12, ns+0(FP)
	RET

// func sys_exit_group(code int32)
TEXT ·sys_exit_group(SB), $0-4
	MOVW	code+0(FP), R4
	MOVV	$SYS_exit_group, R11
	SYSCALL
	RET

// func sys_write(c *byte)
TEXT ·sys_write(SB),NOSPLIT,$0-8
	MOVV	$1, R4		// fd
	MOVV	c+0(FP), R5	// p
	MOVV	$1, R6		// n
	MOVV	$SYS_write, R11
	SYSCALL
	RET

// func sys_getrandom(b []byte, n int)
TEXT ·sys_getrandom(SB), $0-32
	MOVV	b+0(FP), R4
	MOVV	n+24(FP), R5
	MOVV	$0, R6
	MOVV	$SYS_getrandom, R11
	SYSCALL
	RET

// func clone(flags int32, stk, mp, gp, fn unsafe.Pointer) int32
// adapted from runtime/sys_linux_loong64.s
TEXT ·clone(SB),NOSPLIT|NOFRAME,$0
	MOVW	flags+0(FP), R4
	MOVV	stk+8(FP), R5

	// Copy mp, gp, fn off parent stack for use by child.
	MOVV	mp+16(FP), R12
	MOVV	gp+24(FP), R13
	MOVV	fn+32(FP), R14

	MOVV	R12, -8(R5)
	MOVV	R13, -16(R5)
	MOVV	R14, -24(R5)
	MOVV	$1234, R12
	MOVV	R12, -32(R5)

	MOVV	$SYS_clone, R11
	SYSCALL

	// In parent, return.
	BEQ	R4, R0, child
	MOVW	R0, ret+40(FP)
	RET

child:
	// In child, on new stack.
	MOVV	-32(R3), R12
	MOVV	$1234, R4
	BEQ	R4, R12, good
	WORD	$0	// crash

good:
	MOVV	-24(R3), R14	// fn
	MOVV	-16(R3), R13	// g
	MOVV	-8(R3), R12	// m

	BEQ	R12, R0, nog
	BEQ	R13, R0, nog

	// In child, set up new stack
	MOVV	R12, 48(R13)	// g_m(R13)
	MOVV	R13, g

nog:
	// Call fn
	JAL	(R14)

	// It shouldn't return.  If it does, exit this thread.
	MOVV	$111, R4
	MOVV	$SYS_exit, R11
	SYSCALL
	JMP	-3(PC)	// keep exiting
