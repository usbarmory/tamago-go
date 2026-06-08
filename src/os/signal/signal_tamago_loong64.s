// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// func Relay(sig syscall.Signal)
TEXT ·Relay(SB),NOSPLIT|NOFRAME,$0-8
	MOVV	sig+0(FP), R4
	MOVV	R4, ·sig(SB)
	MOVV	·loopG(SB), R12
	JMP	runtime·WakeG(SB)

// func Waiting() bool
TEXT ·Waiting(SB),NOSPLIT,$0-1
	MOVV	·loopG(SB), R12
	JAL	runtime·findTimer(SB)
	XOR	$1, R13, R13
	MOVB	R13, ret+0(FP)
	RET
