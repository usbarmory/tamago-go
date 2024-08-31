//go:build tamago
package os_test

import (
	"embed"
	"os"
	"syscall"
)

//go:embed *.go exec/*
var src embed.FS

//go:embed testdata/*
var testdata embed.FS

func init() {
	// cwd in TestDirFSRootDir must not be empty
	os.MkdirAll("./1", 0777)
	syscall.Chdir("./1")

	os.CopyFS(".", src)
	os.CopyFS(".", testdata)
}
