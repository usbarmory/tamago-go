//go:build tamago
package buildid

import (
	"embed"
	"os"
)

//go:embed testdata/*
var testdata embed.FS
func init() { os.CopyFS(".", testdata) }
