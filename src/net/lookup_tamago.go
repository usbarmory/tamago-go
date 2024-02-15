// Copyright 2011 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package net

import (
	"context"
)

func lookupProtocol(ctx context.Context, name string) (proto int, err error) {
	return lookupProtocolMap(name)
}

func (r *Resolver) lookupHost(ctx context.Context, host string) (addrs []string, err error) {
	ips, _, err := r.goLookupIPCNAME(ctx, "ip", host, getSystemDNSConfig())
	if err != nil {
		return
	}
	addrs = make([]string, 0, len(ips))
	for _, ip := range ips {
		addrs = append(addrs, ip.String())
	}
	return
}

func (r *Resolver) lookupIP(ctx context.Context, network, host string) (addrs []IPAddr, err error) {
	ips, _, err := r.goLookupIPCNAME(ctx, network, host, getSystemDNSConfig())
	return ips, err
}

func (r *Resolver) lookupPort(ctx context.Context, network, service string) (int, error) {
	return goLookupPort(network, service)
}

func (r *Resolver) lookupCNAME(ctx context.Context, name string) (string, error) {
	return r.goLookupCNAME(ctx,  name, getSystemDNSConfig())
}

func (r *Resolver) lookupSRV(ctx context.Context, service, proto, name string) (string, []*SRV, error) {
	return r.goLookupSRV(ctx, service, proto, name)
}

func (r *Resolver) lookupMX(ctx context.Context, name string) ([]*MX, error) {
	return r.goLookupMX(ctx, name)
}

func (r *Resolver) lookupNS(ctx context.Context, name string) ([]*NS, error) {
	return r.goLookupNS(ctx, name)
}

func (r *Resolver) lookupTXT(ctx context.Context, name string) ([]string, error) {
	return r.goLookupTXT(ctx, name)
}

func (r *Resolver) lookupAddr(ctx context.Context, addr string) ([]string, error) {
	return r.goLookupPTR(ctx, addr, getSystemDNSConfig())
}

// concurrentThreadsLimit returns the number of threads we permit to
// run concurrently doing DNS lookups.
func concurrentThreadsLimit() int {
	return 500
}
