// Copyright 2021 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && (amd64 || arm || arm64 || riscv64)

// Package goos provides support for using `GOOS=tamago` in Linux user
// space.
package goos

import (
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

var (
	RamStart       uint = 0x80000000
	RamSize        uint = 0x20000000 // 512MB
	RamStackOffset uint = 0x100

	Bloc   = uintptr(RamStart)
	Exit   = sys_exit_group
	Idle   func(until int64)
	ProcID func() uint64

	Hwinit0  = func() {}
	InitRNG  = func() {}
	Nanotime = sys_clock_gettime
	Hwinit1  = func() {}
)

// defined in linux_user*.s
func CPUInit()
func sys_exit_group(code int32)
func sys_write(c *byte)
func sys_clock_gettime() (ns int64)
func sys_getrandom(b []byte, n int)

//go:noescape
func clone(flags int32, stk, mp, gp, fn unsafe.Pointer) int32

func GetRandomData(b []byte) {
	sys_getrandom(b, len(b))
}

// preallocated memory to avoid malloc during panic
var a [1]byte

func Printk(c byte) {
	a[0] = c
	sys_write(&a[0])
}

var Task = func(sp, mp, gp, fn unsafe.Pointer) {
	clone(cloneFlags, sp, mp, gp, fn)
}
