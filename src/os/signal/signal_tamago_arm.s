// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// func Relay(sig syscall.Signal)
TEXT ·Relay(SB),NOSPLIT|NOFRAME,$0-0
	MOVW	sig+0(FP), R0
	MOVW	R0, ·sig(SB)
	MOVW	·loopG(SB), R0
	B	runtime·WakeG(SB)

// func Waiting() bool
TEXT ·Waiting(SB),NOSPLIT,$0-1
	MOVW	·loopG(SB), R0
	CALL	runtime·findTimer(SB)
	EOR	$1, R1
	MOVB	R1, ret+0(FP)
	RET
