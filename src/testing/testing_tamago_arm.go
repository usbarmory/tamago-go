// Copyright 2021 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && arm

package testing

import (
	"runtime"
	_ "unsafe"
)

//go:linkname ramStart runtime.ramStart
var ramStart uint32 = 0x80000000

//go:linkname ramSize runtime.ramSize
var ramSize uint32 = 0x20000000 // 512MB

//go:linkname ramStackOffset runtime.ramStackOffset
var ramStackOffset uint32 = 0x100

// defined in testing_tamago_arm.s
func sys_exit(code int32)
func sys_write(c *byte)
func sys_clock_gettime() (ns int64)
func sys_getrandom(b []byte, n int)

//go:linkname nanotime1 runtime.nanotime1
func nanotime1() int64 {
	return sys_clock_gettime()
}

//go:linkname initRNG runtime.initRNG
func initRNG() {}

//go:linkname getRandomData runtime.getRandomData
func getRandomData(b []byte) {
	sys_getrandom(b, len(b))
}

// preallocated memory to avoid malloc during panic
var a [1]byte

//go:linkname printk runtime.printk
func printk(c byte) {
	a[0] = c
	sys_write(&a[0])
}

//go:linkname hwinit runtime.hwinit
func hwinit() {
	runtime.Bloc = uintptr(ramStart)
	runtime.Exit = sys_exit
}
