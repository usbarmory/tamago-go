// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package runtime

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

type mWaitList struct{}

func lockVerifyMSize() {}

func mutexContended(l *mutex) bool {
	return false
}

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

// Linked list of notes with a deadline.
var allDeadlineNotes *note

func noteclear(n *note) {
	n.status = note_cleared
}

func notewakeup(n *note) {
	if n.status == note_woken {
		throw("notewakeup - double wakeup")
	}
	cleared := n.status == note_cleared
	n.status = note_woken
	if cleared {
		goready(n.gp, 1)
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

		n.gp = gp
		n.deadline = deadline
		if allDeadlineNotes != nil {
			allDeadlineNotes.allprev = n
		}
		n.allnext = allDeadlineNotes
		allDeadlineNotes = n

		gopark(nil, nil, waitReasonSleep, traceBlockSleep, 1)

		n.gp = nil
		n.deadline = 0
		if n.allprev != nil {
			n.allprev.allnext = n.allnext
		}
		if allDeadlineNotes == n {
			allDeadlineNotes = n.allnext
		}
		n.allprev = nil
		n.allnext = nil

		return n.status == note_woken
	}

	for n.status != note_woken {
		n.gp = gp

		gopark(nil, nil, waitReasonZero, traceBlockGeneric, 1)

		n.gp = nil
	}
	return true
}

// checkTimeouts resumes goroutines that are waiting on a note which has reached its deadline.
func checkTimeouts() {
	now := nanotime()
	for n := allDeadlineNotes; n != nil; n = n.allnext {
		if n.status == note_cleared && n.deadline != 0 && now >= n.deadline {
			n.status = note_timeout
			goready(n.gp, 1)
		}
	}
}

// beforeIdle gets called by the scheduler if no goroutine is awake.
//
//go:yeswritebarrierrec
func beforeIdle(now, pollUntil int64) (gp *g, otherReady bool) {
	// we have nothing to do forever
	if pollUntil == 1<<63 - 1 {
		// halt until an interrupt is received
		Halt()
	}

	return nil, false
}
