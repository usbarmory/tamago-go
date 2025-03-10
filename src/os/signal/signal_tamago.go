// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package signal

import (
	"os"
)

const numSig = 0

func signum(sig os.Signal) int {
	return -1
}

func enableSignal(sig int)  {}
func disableSignal(sig int) {}
func ignoreSignal(sig int)  {}

func signalIgnored(sig int) bool {
	return false
}
