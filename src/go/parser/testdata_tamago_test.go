// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package parser

import (
	"embed"
	"os"
)

//go:embed *.go
var _src embed.FS

//go:embed testdata/*
var _testdata embed.FS

func init() {
	os.CopyFS(".", _src)
	os.CopyFS(".", _testdata)

	src, _ = os.ReadFile("parser.go")
}
