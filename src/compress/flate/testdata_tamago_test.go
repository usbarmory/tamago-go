//go:build tamago
package flate

import (
	compress_testdata "compress/testdata"
	"embed"
	"os"
	"syscall"
	"testdata"
)

//go:embed testdata/*
var flate_testdata embed.FS

func init() {
	os.CopyFS("testdata", testdata.FS)

	// tests look for path ../../testdata
	syscall.Mkdir("./1", 0777)
	syscall.Chdir("./1")
	os.CopyFS("testdata", compress_testdata.FS)

	// tests look for path ../testdata
	syscall.Mkdir("./2", 0777)
	syscall.Chdir("./2")

	// tests look for path ./testdata
	os.CopyFS(".", flate_testdata)
}
