// Copyright 2019 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build tamago

package time

import "errors"

func LoadLocationFromTZData(name string, data []byte) (*Location, error) {
	return nil, errors.New("not implemented")
}

func loadTzinfoFromDirOrZip(dir, name string) ([]byte, error) {
	return nil, errors.New("not implemented")
}

func loadLocation(name string, sources []string) (z *Location, firstErr error) {
	return nil, errors.New("not implemented")
}
