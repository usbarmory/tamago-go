//go:build tamago
package os

import (
	"embed"
)

//go:embed testdata/*
var testdata embed.FS
func init() { CopyFS(".", testdata) }
