// Copyright 2021 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// This file implements runtime support for signal handling.

package runtime

// sigRecvPrepareForFixup is a no-op on tamago. (This would only be
// called while GC is disabled.)
//
//go:nosplit
func sigRecvPrepareForFixup() {
}
