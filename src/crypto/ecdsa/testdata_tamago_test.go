//go:build tamago
package ecdsa

import (
	"embed"
	"os"
)

//go:embed testdata/*
var testdata embed.FS
func init() { os.CopyFS(".", testdata) }
