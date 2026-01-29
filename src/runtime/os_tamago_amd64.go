// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago && amd64

package runtime

import (
	"internal/cpu"
)

// defined in asm_amd64.s
func cputicks() int64

// CPU returns the CPU name given by the vendor.
// If the CPU name can not be determined an
// empty string is returned.
func CPU() string {
	return cpu.Name()
}

// Asleep returns whether the goroutine holds a cached timer for time.Sleep
// (g.timer) and is therefore suitable as [Wake] or [WakeG] target.
func Asleep(gp uint) bool
