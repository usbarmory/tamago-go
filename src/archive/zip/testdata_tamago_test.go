//go:build tamago
package zip

import (
	"embed"
	"os"
)

//go:embed testdata/*
var testdata embed.FS
func init() { os.CopyFS(".", testdata) }
