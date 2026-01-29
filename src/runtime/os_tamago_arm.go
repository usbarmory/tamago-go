// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm

package runtime

// CallOnG0 calls a function (func(off int)) on g0 stack.
//
// The function is meant to be invoked within Go assembly and its arguments
// must be passed through registers rather than on the frame pointer, see
// definition in sys_tamago_arm.s for details.
func CallOnG0()

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
