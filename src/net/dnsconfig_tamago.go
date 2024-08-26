// Copyright 2022 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package net

// SetDefaultNS sets the default name servers to use in the absence of DNS
// configuration.
func SetDefaultNS(servers []string) {
	defaultNS = servers
}
