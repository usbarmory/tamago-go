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

func (r *Resolver) lookupIP(ctx context.Context, network, name string) (addrs []IPAddr, err error) {
	ips, _, err := r.goLookupIPCNAME(ctx, network, name, getSystemDNSConfig())
	return ips, err
}

func (*Resolver) lookupPort(ctx context.Context, network, service string) (port int, err error) {
	return goLookupPort(network, service)
}

func (r *Resolver) lookupCNAME(ctx context.Context, name string) (string, error) {
	_, cname, err := r.goLookupIPCNAME(ctx, "CNAME", name, getSystemDNSConfig())
	return cname.String(), err
}

func (r *Resolver) lookupSRV(ctx context.Context, service, proto, name string) (cname string, srvs []*SRV, err error) {
	return r.goLookupSRV(ctx, service, proto, name)
}

func (r *Resolver) lookupMX(ctx context.Context, name string) (mxs []*MX, err error) {
	return r.goLookupMX(ctx, name)
}

func (r *Resolver) lookupNS(ctx context.Context, name string) (nss []*NS, err error) {
	return r.goLookupNS(ctx, name)
}

func (r *Resolver) lookupTXT(ctx context.Context, name string) (txts []string, err error) {
	return r.goLookupTXT(ctx, name)
}

func (r *Resolver) lookupAddr(ctx context.Context, addr string) (ptrs []string, err error) {
	return r.goLookupPTR(ctx, addr, getSystemDNSConfig())
}

// concurrentThreadsLimit returns the number of threads we permit to
// run concurrently doing DNS lookups.
func concurrentThreadsLimit() int {
	return 500
}
