// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package rand

import (
	"runtime"
	"sync"
)

func init() {
	Reader = &reader{}
}

type reader struct {
	mu sync.Mutex
}

func (r *reader) Read(b []byte) (int, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	runtime.GetRandomData(b)

	return len(b), nil
}
