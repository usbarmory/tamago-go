// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package goos implements support for the GOOSPKG build setting (see Go
// proposal #73608).
//
// The GOOSPKG build setting controls which copy of the runtime/goos source
// code to use. The default is obviously GOROOT/src/runtime/goos, but a
// different implementation can be substituted into the build instead.
//
// This package provides the logic needed by the rest of the go command
// to implement the overlay.
//
// When GOOSPKG is empty GOROOT/src/runtime/goos is imported as expected to
// resolve [runtime/goos].
//
// When GOOSPKG is set it defines a module repository root path to be used as
// alias for [runtime/goos], the implementation must live under module
// subdirectory "goos".
//
// ResolveImport is called to resolve the [runtime/goos] import, in a manner
// similar to fips140 snapshot logic (see GOROOT/src/cmd/go/internal/fips140).
package goos

import (
	"context"
	"os"
	"path/filepath"

	"cmd/go/internal/base"
	"cmd/go/internal/cfg"
	"cmd/go/internal/modload"
	"cmd/go/internal/str"
)

const goos = "runtime/goos"

// ResolveImport resolves the import path imp.
func ResolveImport(loaderstate *modload.State, imp string) (newPath, dir string, ok bool) {
	if !str.HasPathPrefix(imp, goos) || cfg.Goos != "tamago" {
		return "", "", false
	}

	if cfg.GOOSPKG != "" {
		r, err := modload.ListModules(loaderstate, context.Background(), []string{cfg.GOOSPKG}, 0, "")

		if err != nil {
			base.Fatalf("go: GOOSPKG=%q not found in module list: %v", cfg.GOOSPKG, err)
		}

		if len(r) > 0 && r[0].Error == nil {
			dir = r[0].Dir
		}

		if len(dir) == 0 {
			base.Fatalf("go: GOOSPKG=%q not found in module list", cfg.GOOSPKG)
		}

		dir = filepath.Join(dir, "goos")
	} else {
		// fallback to Linux userspace goos defined in GOROOT/src/runtime/goos
		if os.Getenv("GOHOSTOS") == "linux" && (cfg.Goarch == "amd64" || cfg.Goarch == "arm" || cfg.Goarch == "arm64" || cfg.Goarch == "riscv64") {
			dir = filepath.Join(cfg.GOROOT, "src/runtime/goos")
		} else {
			base.Fatalf("go: GOOS %s unsupported without external GOOSPKG on %s/%s", cfg.Goos, os.Getenv("GOHOSTOS"), cfg.Goarch)
		}
	}

	return goos, dir, true
}
