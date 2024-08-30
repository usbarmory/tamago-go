//go:build tamago
package metrics

import (
	"embed"
	"os"
)

//go:embed doc.go
var src embed.FS
func init() { os.CopyFS(".", src) }
