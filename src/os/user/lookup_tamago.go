// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package user

import (
	"errors"
)

func init() {
	groupImplemented = false
}

func lookupUser(username string) (*User, error) {
	return nil, errors.New("unsupported")
}

func lookupUserId(uid string) (*User, error) {
	return nil, errors.New("unsupported")
}

func lookupGroup(groupname string) (*Group, error) {
	return nil, errors.New("unsupported")
}

func lookupGroupId(string) (*Group, error) {
	return nil, errors.New("unsupported")
}

func listGroups(*User) ([]string, error) {
	return nil, errors.New("unsupported")
}
