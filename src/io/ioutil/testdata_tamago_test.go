// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package ioutil

import (
	"embed"
	"os"
	"syscall"
)

//go:embed ioutil_test.go
var src embed.FS

//go:embed testdata/*
var testdata embed.FS

func init() {
	// tests look for path ../io_test.go
	os.WriteFile("io_test.go", []byte{}, 0600)
	os.MkdirAll("./ioutil", 0777)
	syscall.Chdir("./ioutil")
	os.CopyFS(".", src)
	os.CopyFS(".", testdata)
}
