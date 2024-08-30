//go:build tamago
package dwarf

import (
	"embed"
	"os"
)

//go:embed dwarf.go putvarabbrevgen.go
var testdata embed.FS
func init() { os.CopyFS(".", testdata) }
