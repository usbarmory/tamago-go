//go:build tamago
package syntax

import (
	"embed"
	"os"
)

//go:embed parser.go
var _src embed.FS

//go:embed testdata/*
var _testdata embed.FS

func init() {
	os.CopyFS(".", _src)
	os.CopyFS(".", _testdata)
}
