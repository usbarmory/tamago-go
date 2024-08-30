//go:build tamago
package jpeg

import (
	"image/testdata"
	"os"
	"syscall"
)

func init() {
	os.CopyFS("testdata", testdata.FS)
	// tests look for path ../testdata
	syscall.Mkdir("./1", 0777)
	syscall.Chdir("./1")
}
