// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package entropy

import (
	"unsafe"
	"sync/atomic"
)

// ScratchBuffer is a large buffer that will be written to using atomics, to
// generate noise from memory access timings. Its contents do not matter.
type ScratchBuffer *[1 << 25]byte

// touchMemory performs a write to memory at the given index.
//
// The memory slice is passed in and may be shared across sources e.g. to avoid
// the significant (~500µs) cost of zeroing a new allocation on every [Seed] call.
func touchMemory(memory *ScratchBuffer, idx uint32) {
	if *memory == nil {
		*memory = new([1<<25]byte)
	}

	idx = idx / 4 * 4 // align to 32 bits
	u32 := (*uint32)(unsafe.Pointer(&(*memory)[idx]))
	last := atomic.LoadUint32(u32)
	atomic.SwapUint32(u32, last+13)
}
