// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

TEXT _rt0_amd64_tamago(SB),NOSPLIT,$-8
	JMP	_rt0_amd64(SB)
