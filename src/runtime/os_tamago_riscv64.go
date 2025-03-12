// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && riscv64

package runtime

// the following variables must be provided externally
var ramStart uint64
var ramSize uint64
var ramStackOffset uint64

// defined in asm_riscv64.s
func cputicks() int64

// GetG returns the pointer to the current G and its P.
func GetG() (gp uint64, pp uint64)

// MemRegion returns the start and end addresses of the physical RAM assigned
// to the Go runtime.
func MemRegion() (start uint64, end uint64) {
	return ramStart, ramStart + ramSize
}

// TextRegion returns the start and end addresses of the physical RAM
// containing the Go runtime executable instructions.
func TextRegion() (start uint64, end uint64) {
	return uint64(firstmoduledata.text), uint64(firstmoduledata.etext)
}

// DataRegion returns the start and end addresses of the physical RAM
// containing the Go runtime global symbols.
func DataRegion() (start uint64, end uint64) {
	return uint64(firstmoduledata.data), uint64(firstmoduledata.enoptrbss)
}
