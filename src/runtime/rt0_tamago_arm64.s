// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !user_linux

#include "textflag.h"

TEXT _rt0_arm64_tamago(SB),NOSPLIT|NOFRAME,$0
	// cpuinit must be provided externally by the linked application for
	// CPU initialization, it must call _rt0_tamago_start at completion
	B	cpuinit(SB)

TEXT _rt0_tamago_start(SB),NOSPLIT|NOFRAME,$0
	MOVD	runtime·ramStart(SB), R1
	MOVD	R1, RSP
	MOVD	runtime·ramSize(SB), R1
	MOVD	runtime·ramStackOffset(SB), R2
	ADD	R1, RSP
	SUB	R2, RSP
	B	runtime·rt0_arm64_tamago(SB)
