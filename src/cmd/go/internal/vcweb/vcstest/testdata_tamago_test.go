//go:build tamago
package vcstest

import (
	"os"
	"syscall"
	"cmd/go/testdata/vcstest"
)

func init() {
	os.CopyFS("testdata/vcstest", testdata.FS)
	os.Remove("testdata/vcstest/embed_tamago.go")

	// tests look for path ../../../testdata/vcstest
	syscall.Mkdir("./1/2/3", 0777)
	syscall.Chdir("./1/2/3")
}
