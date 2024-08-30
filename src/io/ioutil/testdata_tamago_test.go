//go:build tamago
package ioutil

import (
	"embed"
	"os"
)

//go:embed ioutil_test.go
var src embed.FS

//go:embed testdata/*
var testdata embed.FS

func init() {
	os.CopyFS(".", src)
	os.CopyFS(".", testdata)
}
