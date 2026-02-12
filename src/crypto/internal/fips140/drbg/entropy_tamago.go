// Copyright 2024 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package drbg

import (
	entropy "crypto/internal/entropy/v1.0.0"
	"sync"
)

// memory is a scratch buffer that is accessed between samples by the entropy
// source to expose it to memory access timings.
//
// We reuse it and share it between Seed calls to avoid the significant (~500µs)
// cost of zeroing a new allocation every time. The entropy source accesses it
// using atomics (and doesn't care about its contents).
//
// In GOOS=tamago it is dynamically allocated at first use to prevent
// allocation in the .noptrbss section, which would cause overhead on ELF to
// binary conversions.
var getMemory = sync.OnceValue(func() *entropy.ScratchBuffer {
	return new(entropy.ScratchBuffer)
})

func getEntropy() *[SeedSize]byte {
	memory := getMemory()

	var retries int
	seed, err := entropy.Seed(memory)
	for err != nil {
		// The CPU jitter-based SP 800-90B entropy source has a non-negligible
		// chance of failing the startup health tests.
		//
		// Each time it does, it enters a permanent failure state, and we
		// restart it anew. This is not expected to happen more than a few times
		// in a row.
		if retries++; retries > 100 {
			panic("fips140/drbg: failed to obtain initial entropy")
		}
		seed, err = entropy.Seed(memory)
	}
	return &seed
}
