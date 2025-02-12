// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package asm

import (
	"embed"
	"os"
	"syscall"
)

//go:embed testdata/*
var testdata embed.FS

var textflag = `
#define NOPROF	1
#define DUPOK	2
#define NOSPLIT	4
#define RODATA	8
#define NOPTR	16
#define WRAPPER 32
#define NEEDCTXT 64
#define TLSBSS	256
#define NOFRAME 512
#define REFLECTMETHOD 1024
#define TOPFRAME 2048
#define ABIWRAPPER 4096
`

func init() {
	// tests look for path ../../../../runtime/textflag.h
	os.MkdirAll("runtime", 0777)
	os.WriteFile("runtime/textflag.h", []byte(textflag), 0600)
	os.MkdirAll("./1/2/3/4", 0777)
	syscall.Chdir("./1/2/3/4")
	os.CopyFS(".", testdata)
}
