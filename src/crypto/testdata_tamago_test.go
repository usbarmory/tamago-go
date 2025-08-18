// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago
package crypto_test

import (
	"embed"
	"os"
	"runtime"
)

//go:embed *
var src embed.FS

func init() {
	os.Mkdir(runtime.GOROOT() + "/src/crypto", 0750)
	os.CopyFS(runtime.GOROOT() + "/src/crypto", src)
}
