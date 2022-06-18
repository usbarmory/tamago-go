// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// This file contains tamaga-defined interfaces that could run in non-Tamago contexts.
// For example, on the t9 unikernel, some drivers can run in the host as well as
// on tamago, and they must implement the DevFile interface.

package syscall

// DevFile is the implementation required of device files
// like /dev/null or /dev/random.
type DevFile interface {
	Pread([]byte, int64) (int, error)
	Pwrite([]byte, int64) (int, error)
}
