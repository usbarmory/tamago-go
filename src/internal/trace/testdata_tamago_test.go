//go:build tamago
package trace

import (
	"embed"
	"os"
)

//go:embed order.go internal/oldtrace/*
var src embed.FS

//go:embed testdata/*
var testdata embed.FS

func init() {
	os.CopyFS(".", src)
	os.CopyFS(".", testdata)
}
