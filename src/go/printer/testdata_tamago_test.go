//go:build tamago
package printer

import (
	"embed"
	"os"
)

//go:embed example_test.go printer.go
var src embed.FS

//go:embed testdata/*
var testdata embed.FS

func init() {
	os.CopyFS(".", src)
	os.CopyFS(".", testdata)
}
