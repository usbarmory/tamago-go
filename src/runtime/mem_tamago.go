// Copyright 2010 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package runtime

import "unsafe"

func sbrk(n uintptr) unsafe.Pointer {
	// Plan 9 sbrk from /sys/src/libc/9sys/sbrk.c
	bl := bloc
	n = memRound(n)
	if bl+n > blocMax {
		// Stop at stack top address
		if bl+n > uintptr(g0.stack.lo) {
			return nil
		} else {
			memclrNoHeapPointers(unsafe.Pointer(bl), n)
		}
		blocMax = bl + n
	}
	bloc += n
	return unsafe.Pointer(bl)
}
