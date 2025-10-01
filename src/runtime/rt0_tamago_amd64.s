// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !user_linux

#include "textflag.h"

TEXT _rt0_amd64_tamago(SB),NOSPLIT|NOFRAME,$0
	// cpuinit must be provided externally by the linked application for
	// CPU initialization, it must call _rt0_tamago_start at completion
	JMP	cpuinit(SB)

TEXT _rt0_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOVQ	runtime·ramStart(SB), SP
	MOVQ	runtime·ramSize(SB), AX
	MOVQ	runtime·ramStackOffset(SB), BX
	ADDQ	AX, SP
	SUBQ	BX, SP
	JMP	runtime·rt0_amd64_tamago(SB)
