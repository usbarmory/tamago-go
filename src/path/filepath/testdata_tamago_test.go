// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package filepath

import (
	"embed"
	"os"
	"syscall"
)

//go:embed match.go
var src embed.FS

func init() {
	// tests look for path ../filepath/match.go
	os.MkdirAll("./1/filepath", 0777)
	syscall.Chdir("./1/filepath")
	os.CopyFS(".", src)
}
