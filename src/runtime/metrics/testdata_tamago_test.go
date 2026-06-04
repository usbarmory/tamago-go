// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package metrics

import (
	"embed"
	"os"
)

//go:embed doc.go
var src embed.FS
func init() { os.CopyFS(".", src) }
