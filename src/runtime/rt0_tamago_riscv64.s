// Copyright 2022 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !user_linux

#include "textflag.h"

// entry point for M privilege level instances
TEXT _rt0_riscv64_tamago(SB),NOSPLIT|NOFRAME,$0
	// cpuinit must be provided externally by the linked application for
	// CPU initialization, it must call _rt0_tamago_start at completion
	JMP	cpuinit(SB)

// entry point for S/U privilege level instances
TEXT _rt0_tamago_start(SB),NOSPLIT|NOFRAME,$0
	JMP	runtime·rt0_riscv64_tamago(SB)
