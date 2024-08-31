//go:build tamago
package sync_test

import (
	"embed"
	"os"
)

//go:embed example_test.go
var src embed.FS
func init() { os.CopyFS(".", src) }
