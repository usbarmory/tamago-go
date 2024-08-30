//go:build tamago
package zlib

import (
	"compress/testdata"
	"os"
	"syscall"
)

func init() {
	os.CopyFS("testdata", testdata.FS)
	// tests look for path ../testdata
	syscall.Mkdir("./1", 0777)
	syscall.Chdir("./1")
}
