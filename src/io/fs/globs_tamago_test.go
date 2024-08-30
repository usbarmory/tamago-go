// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package fs_test

import (
	. "io/fs"
	"os"
)

func init() {
	globTests = []struct {
		fs              FS
		pattern, result string
	}{
		{os.DirFS("./dev"), "zero", "zero"},
		{os.DirFS("./dev"), "ze?o", "zero"},
		{os.DirFS("./dev"), `ze\ro`, "zero"},
		{os.DirFS("./dev"), "*", "zero"},
		{os.DirFS("."), "*/zero", "dev/zero"},
	}
}
