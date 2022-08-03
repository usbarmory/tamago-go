// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package runtime

import (
	_ "unsafe"
)

// tamago has no support for threads yet. There is no preemption. (adapted from lock_js.go)

const (
	mutex_unlocked = 0
	mutex_locked   = 1

	note_cleared = 0
	note_woken   = 1
	note_timeout = 2

	active_spin     = 4
	active_spin_cnt = 30
	passive_spin    = 1
)

func lock(l *mutex) {
	lockWithRank(l, getLockRank(l))
}

func lock2(l *mutex) {
	if l.key == mutex_locked {
		// tamago is single-threaded so we should never
		// observe this.
		throw("self deadlock")
	}
	gp := getg()
	if gp.m.locks < 0 {
		throw("lock count")
	}
	gp.m.locks++
	l.key = mutex_locked
}

func unlock(l *mutex) {
	unlockWithRank(l)
}

func unlock2(l *mutex) {
	if l.key == mutex_unlocked {
		throw("unlock of unlocked lock")
	}
	gp := getg()
	gp.m.locks--
	if gp.m.locks < 0 {
		throw("lock count")
	}
	l.key = mutex_unlocked
}

// One-time notifications.

type noteWithTimeout struct {
	gp       *g
	deadline int64
}

var (
	notes            = make(map[*note]*g)
	notesWithTimeout = make(map[*note]noteWithTimeout)
)

func noteclear(n *note) {
	n.key = note_cleared
}

func notewakeup(n *note) {
	// gp := getg()
	if n.key == note_woken {
		throw("notewakeup - double wakeup")
	}
	cleared := n.key == note_cleared
	n.key = note_woken
	if cleared {
		goready(notes[n], 1)
	}
}

func notesleep(n *note) {
	throw("notesleep not supported by tamago")
}

func notetsleep(n *note, ns int64) bool {
	throw("notetsleep not supported by tamago")
	return false
}

// same as runtime·notetsleep, but called on user g (not g0)
func notetsleepg(n *note, ns int64) bool {
	gp := getg()
	if gp == gp.m.g0 {
		throw("notetsleepg on g0")
	}

	if ns >= 0 {
		deadline := nanotime() + ns
		delay := ns/1000000 + 1 // round up
		if delay > 1<<31-1 {
			delay = 1<<31 - 1 // cap to max int32
		}

		mp := acquirem()
		notes[n] = gp
		notesWithTimeout[n] = noteWithTimeout{gp: gp, deadline: deadline}
		releasem(mp)

		gopark(nil, nil, waitReasonSleep, traceEvNone, 1)

		mp = acquirem()
		delete(notes, n)
		delete(notesWithTimeout, n)
		releasem(mp)

		return n.key == note_woken
	}

	for n.key != note_woken {
		mp := acquirem()
		notes[n] = gp
		releasem(mp)

		gopark(nil, nil, waitReasonZero, traceEvNone, 1)

		mp = acquirem()
		delete(notes, n)
		releasem(mp)
	}
	return true
}

// checkTimeouts resumes goroutines that are waiting on a note which has reached its deadline.
// TODO(drchase): need to understand if write barriers are really okay in this context.
//
//go:yeswritebarrierrec
func checkTimeouts() {
	now := nanotime()
	// TODO: map iteration has the write barriers in it; is that okay?
	for n, nt := range notesWithTimeout {
		if n.key == note_cleared && now >= nt.deadline {
			n.key = note_timeout
			goready(nt.gp, 1)
		}
	}
}

// beforeIdle gets called by the scheduler if no goroutine is awake.
// If we are not already handling an event, then we pause for an async event.
// If an event handler returned, we resume it and it will pause the execution.
// beforeIdle either returns the specific goroutine to schedule next or
// indicates with otherReady that some goroutine became ready.
// TODO(drchase): need to understand if write barriers are really okay in this context.
//
//go:yeswritebarrierrec
func beforeIdle(now, pollUntil int64) (gp *g, otherReady bool) {
	return nil, false
}
