// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm

package runtime

import "runtime/goos"

// MemRegion returns the start and end addresses of the physical RAM assigned
// to the Go runtime.
func MemRegion() (start uint32, end uint32) {
	return uint32(goos.RamStart), uint32(goos.RamStart + goos.RamSize)
}

// TextRegion returns the start and end addresses of the physical RAM
// containing the Go runtime executable instructions.
func TextRegion() (start uint32, end uint32) {
	return uint32(firstmoduledata.text), uint32(firstmoduledata.etext)
}

// DataRegion returns the start and end addresses of the physical RAM
// containing the Go runtime global symbols.
func DataRegion() (start uint32, end uint32) {
	return uint32(firstmoduledata.data), uint32(firstmoduledata.enoptrbss)
}
