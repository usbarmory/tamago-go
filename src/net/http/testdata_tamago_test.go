//go:build tamago
package http

import (
	"embed"
	"os"
)

//go:embed *.go
var src embed.FS

//go:embed testdata/*
var testdata embed.FS

func init() {
	os.CopyFS(".", src)
	os.CopyFS(".", testdata)
}
