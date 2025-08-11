// Copyright 2025 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package runtime

// beforeIdle gets called by the scheduler if no goroutine is awake.
//
//go:yeswritebarrierrec
func beforeIdle(now, pollUntil int64) (gp *g, otherReady bool) {
	idleStart := nanotime()

	if Idle != nil {
		Idle(pollUntil)
	}

	sched.idleTime.Add(nanotime() - idleStart)

	// always return otherReady to ensure that no M is ever dropped
	return nil, true
}

func checkTimeouts() {}
