// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// This file implements runtime support for signal handling.

package runtime

import (
	_ "unsafe"
)

//go:linkname signalWaitUntilIdle os/signal.signalWaitUntilIdle
func signalWaitUntilIdle() {
	throw("signalWaitUntilIdle: not implemented")
}
