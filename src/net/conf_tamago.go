// Copyright 2011 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package net

import (
	"io/fs"
	"time"
)

var (
	DefaultNS         = []string{"8.8.8.8:53"}
	DefaultDNSTimeout = time.Duration(5) * time.Second
	UseTCP            = false
)

func getSystemDNSConfig() *dnsConfig {
	return &dnsConfig{
		servers:  DefaultNS,
		ndots:    1,
		timeout:  DefaultDNSTimeout,
		attempts: 2,
		err:      fs.ErrNotExist,
		useTCP:   UseTCP,
	}
}
