//go:build tamago
package errors

import (
	"embed"
	"os"
)

//go:embed codes.go
var src embed.FS
func init() { os.CopyFS(".", src) }
