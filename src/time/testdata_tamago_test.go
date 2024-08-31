//go:build tamago
package time_test

import (
	"embed"
	"os"
)

//go:embed testdata/*
var testdata embed.FS

//go:embed testdata/2020b_Europe_Berlin
var zoneinfo []byte

func init() {
	os.CopyFS(".", testdata)
	// tests look for gorootSource/Europe/Berlin
	os.MkdirAll("zoneinfo/Europe", 0700)
	os.WriteFile("zoneinfo/Europe/Berlin", zoneinfo, 0600)
}
