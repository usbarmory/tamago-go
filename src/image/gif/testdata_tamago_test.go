// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package gif

import (
	"image/testdata"
	"os"
	"syscall"
)

func init() {
	os.CopyFS("testdata", testdata.FS)
	// tests look for path ../testdata
	syscall.Mkdir("./1", 0777)
	syscall.Chdir("./1")
}
