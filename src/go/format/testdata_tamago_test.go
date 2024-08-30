//go:build tamago
package format

import (
	"embed"
	"os"
)

//go:embed format_test.go
var src embed.FS
func init() { os.CopyFS(".", src) }
