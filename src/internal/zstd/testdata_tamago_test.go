//go:build tamago
package zstd

import (
	"os"
	"syscall"
	"testdata"
)

func init() {
	os.CopyFS("testdata", testdata.FS)
	// tests look for path ../../testdata
	syscall.Mkdir("./1/2", 0777)
	syscall.Chdir("./1/2")
}
