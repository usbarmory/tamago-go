// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm64

package runtime

// the following variables must be provided externally
var ramStart uint64
var ramSize uint64
var ramStackOffset uint64

// CallOnG0 calls a function (func(off int)) on g0 stack.
//
// The function is meant to be invoked within Go assembly and its arguments
// must be passed through registers rather than on the frame pointer, see
// definition in sys_tamago_arm.s for details.
func CallOnG0()

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

//go:nosplit
func cputicks() int64 {
	// runtime·nanotime() is a poor approximation of CPU ticks that is enough for the profiler.
	return nanotime()
}
