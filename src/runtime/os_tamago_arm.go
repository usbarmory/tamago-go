// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm

package runtime

// the following variables must be provided externally
var ramStart uint32
var ramSize uint32
var ramStackOffset uint32

// CallOnG0 calls a function (func(off int)) on g0 stack.
//
// The function is meant to be invoked within Go assembly and its arguments
// must be passed through registers rather than on the frame pointer, see
// definition in sys_tamago_arm.s for details.
func CallOnG0()

// GetG returns the pointer to the current G and its P.
func GetG() (gp uint32, pp uint32)

// MemRegion returns the start and end addresses of the physical RAM assigned
// to the Go runtime.
func MemRegion() (start uint32, end uint32) {
	return ramStart, ramStart + ramSize
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

func checkgoarm() {
	if goarm < 5 || goarm > 7 {
		print("runtime: tamago requires ARMv5 through ARMv7. Recompile using GOARM=5, GOARM=6 or GOARM=7.\n")
		exit(1)
	}
}

//go:nosplit
func cputicks() int64 {
	// runtime·nanotime() is a poor approximation of CPU ticks that is enough for the profiler.
	return nanotime()
}
