// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package dwarf

import (
	"embed"
	"os"
)

//go:embed dwarf.go putvarabbrevgen.go
var testdata embed.FS
func init() { os.CopyFS(".", testdata) }
