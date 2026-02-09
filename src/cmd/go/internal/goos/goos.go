// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package goos implements support for the GOOSPKG build setting (see Go
// proposal #73608).
//
// The GOOSPKG build setting controls which copy of the runtime/goos source
// code to use. The default is obviously GOROOT/src/runtime/goos, but different
// implementations can be substituted into the build instead.
//
// This package provides the logic needed by the rest of the go command
// to implement the overlay.
//
// [Init] must be called to initialize the GOOSPKG logic. It may fail and call
// base.Fatalf.
//
// When GOOSPKG is empty GOROOT/src/runtime/goos is imported as expected to
// resolve [runtime/goos].
//
// When GOOSPKG is set it defines a module, or filesystem path, as source
// location for [runtime/goos].
//
// ResolveImport is called to resolve the [runtime/goos] import, in a manner
// similar to fips140 snapshot logic (see GOROOT/src/cmd/go/internal/fips140).
package goos

import (
	"context"
	"os"
	"path"
	"path/filepath"
	"strings"

	"cmd/go/internal/base"
	"cmd/go/internal/cfg"
	"cmd/go/internal/modfetch"
	"cmd/go/internal/str"

	"golang.org/x/mod/module"
)

// Init initializes the GOOS=tamago settings.
// It must be called before using any other functions in this package.
// If initialization fails, Init calls base.Fatalf.
func Init() {
	if initDone {
		return
	}
	initDone = true
	initVersion()
	initDir()

	if cfg.Goos != "tamago" || cfg.GOOSPKG != "" {
		return
	}

	// fallback to Linux userspace goos defined in GOROOT/src/runtime/goos
	if os.Getenv("GOHOSTOS") == "linux" && (cfg.Goarch == "amd64" || cfg.Goarch == "arm" || cfg.Goarch == "arm64" || cfg.Goarch == "riscv64") {
		return
	}

	base.Fatalf("go: cannot use GOOS %s with empty GOOSPKG on %s/%s", cfg.Goos, os.Getenv("GOHOSTOS"), cfg.Goarch)
}

var initDone bool

// checkInit panics if Init has not been called.
func checkInit() {
	if !initDone {
		panic("goos: not initialized")
	}
}

var name string
var version string

func initVersion() {
	if cfg.GOOSPKG == "" {
		return
	}

	n, v, found := strings.Cut(cfg.GOOSPKG, "@")

	if found {
		name = n
		version = v
		return
	}

	if _, err := os.Stat(cfg.GOOSPKG); err != nil {
		base.Fatalf("go: unknown GOOSPKG %q, %v", cfg.GOOSPKG, err)
	}

	dir = filepath.Join(cfg.GOOSPKG, "goos")

	return
}

// Dir reports the directory containing the runtime/goos source code.
// If GOOSPKG is empty, Dir returns GOROOT/src/runtime/goos.
// Otherwise Dir ensures that the snapshot has been unpacked into the
// module cache and then returns the directory in the module cache
// corresponding to the runtime/goos directory.
func Dir() string {
	checkInit()
	return dir
}

var dir string

func initDir() {
	if dir != "" {
		return
	}

	if version == "" {
		dir = filepath.Join(cfg.GOROOT, "src/runtime/goos")
		return
	}

	mod := module.Version{Path: name, Version: version}
	mdir, err := modfetch.NewFetcher().Download(context.Background(), mod)
	if err != nil {
		base.Fatalf("go: downloading GOOSPKG=%q: %v", cfg.GOOSPKG, err)
	}
	dir = filepath.Join(mdir, "goos")
}

// ResolveImport resolves the import path imp.
func ResolveImport(imp string) (newPath, dir string, ok bool) {
	checkInit()
	const goos = "runtime/goos"
	if !str.HasPathPrefix(imp, goos) {
		return "", "", false
	}
	goosv := path.Join(goos, version)
	var sub string
	if str.HasPathPrefix(imp, goosv) {
		sub = "." + imp[len(goosv):]
	} else {
		sub = "." + imp[len(goos):]
	}
	newPath = path.Join(goos, sub)
	dir = filepath.Join(Dir(), sub)
	return newPath, dir, true
}
