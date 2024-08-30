//go:build tamago
package tar

import (
	"embed"
	"os"
)

//go:embed testdata/*
var testdata embed.FS
func init() { os.CopyFS(".", testdata) }
