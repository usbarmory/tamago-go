// Copyright 2011 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package time

import (
	"errors"
)

// for testing: whatever interrupts a sleep
func interrupt() {
	// cannot predict pid, don't want to kill group
}

func open(name string) (p uintptr, err error) {
	return 0, errors.New("not implemented")
}

func read(fd uintptr, buf []byte) (int, error) {
	return -1, errors.New("not implemented")
}

func closefd(fd uintptr) { }

func preadn(fd uintptr, buf []byte, off int) error {
	return errors.New("not implemented")
}
