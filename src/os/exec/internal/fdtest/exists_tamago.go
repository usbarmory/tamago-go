// Copyright 2021 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package fdtest

// Exists is not implemented on tamago and panics.
func Exists(fd uintptr) bool {
	panic("unimplemented")
}
