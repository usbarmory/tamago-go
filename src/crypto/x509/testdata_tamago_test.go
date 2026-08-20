// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package x509

import (
	"embed"
	"os"
)

//go:embed testdata/*
var testdata embed.FS

//go:embed test-file.crt
var testfile []byte

func init() {
	os.CopyFS(".", testdata)
	os.WriteFile("test-file.crt", testfile, 0600)
}
