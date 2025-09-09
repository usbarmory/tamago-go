// Copyright 2021 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && (amd64 || arm || arm64 || riscv64)

package testing

import (
	"runtime"
	"unsafe"
)

// adapted from runtime/os_linux.go
const (
	_CLONE_VM      = 0x100
	_CLONE_FS      = 0x200
	_CLONE_FILES   = 0x400
	_CLONE_SIGHAND = 0x800
	_CLONE_THREAD  = 0x10000
	_CLONE_SYSVSEM = 0x40000

	cloneFlags = _CLONE_VM | /* share memory */
		_CLONE_FS | /* share cwd, etc */
		_CLONE_FILES | /* share fd table */
		_CLONE_SIGHAND | /* share sig handler table */
		_CLONE_SYSVSEM | /* share SysV semaphore undo lists (see issue #20763) */
		_CLONE_THREAD /* revisit - okay for now */
)

//go:linkname ramStart runtime.ramStart
var ramStart uint64 = 0x80000000

//go:linkname ramSize runtime.ramSize
var ramSize uint64 = 0x20000000 // 512MB

//go:linkname ramStackOffset runtime.ramStackOffset
var ramStackOffset uint64 = 0x100

// defined in testing_tamago_*.s
func sys_exit_group(code int32)
func sys_write(c *byte)
func sys_clock_gettime() (ns int64)
func sys_getrandom(b []byte, n int)

//go:noescape
func clone(flags int32, stk, mp, gp, fn unsafe.Pointer) int32

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

//go:linkname hwinit0 runtime.hwinit0
func hwinit0() {
	runtime.Bloc = uintptr(ramStart)
}

func task(sp, mp, gp, fn unsafe.Pointer) {
	clone(cloneFlags, sp, mp, gp, fn)
}

//go:linkname hwinit1 runtime.hwinit1
func hwinit1() {
	runtime.Exit = sys_exit_group
}

func init() {
	runtime.Task = task
}
