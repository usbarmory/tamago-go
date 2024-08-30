//go:build tamago
package main

import (
	"embed"
	"os"
	"runtime"
)

//go:embed *.go
var src embed.FS

//go:embed testdata/*
var testdata embed.FS

func init() {
	os.CopyFS(".", src)
	os.CopyFS(".", testdata)

	os.Mkdir(runtime.GOROOT(), 0750)
	os.CopyFS(runtime.GOROOT(), src)
}
