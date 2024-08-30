//go:build tamago
package modindex

import (
	_embed "embed"
	"os"
)

//go:embed testdata/*
var testdata _embed.FS
func init() { os.CopyFS(".", testdata) }
