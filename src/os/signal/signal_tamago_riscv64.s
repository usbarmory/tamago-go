// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// func Relay(sig syscall.Signal)
TEXT ·Relay(SB),NOSPLIT,$0-8
	MOV	sig+0(FP), A0
	MOV	A0, ·sig(SB)
	MOV	·loopG(SB), T0
	JMP	runtime·WakeG(SB)

// func Waiting() bool
TEXT ·Waiting(SB),NOSPLIT,$0-1
	MOV	·loopG(SB), T0
	CALL	runtime·findTimer(SB)
	XOR	$1, T1
	MOV	T1, ret+0(FP)
	RET
