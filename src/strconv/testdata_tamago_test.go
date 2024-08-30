//go:build tamago
package strconv

import (
	"embed"
	"os"
)

//go:embed testdata/*
var testdata embed.FS
func init() { os.CopyFS(".", testdata) }
