// Copyright 2023 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package net

import (
	"context"
)

func installTestHooks() {
	SocketFunc = func(context.Context, string, int, int, Addr, Addr) (i interface{}, err error) {
		return nil, nil
	}
}

func uninstallTestHooks() {}

// forceCloseSockets must be called only from TestMain.
func forceCloseSockets() {}

func enableSocketConnect() {}

func disableSocketConnect(network string) {}

func isDeadlineExceeded(err error) bool { return false }
