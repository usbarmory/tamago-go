// Copyright 2018 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package net

import (
	"context"
	"errors"
	"internal/poll"
	"io"
	"os"
	"syscall"
	"time"
)

// SocketFunc must be set externally by the application on GOOS=tamago to
// provide the network socket implementation. The returned interface must match
// the requested socket and be either net.Conn, net.PacketConn or net.Listen.
var SocketFunc func(ctx context.Context, net string, family, sotype int, laddr, raddr Addr) (interface{}, error)

// Network file descriptor.
type netFD struct {
	c interface{}

	// immutable until Close
	listener bool
	family   int
	sotype   int
	net      string
	laddr    Addr
	raddr    Addr

	// unused
	pfd         poll.FD
	isConnected bool // handshake completed or use of association with peer
}

type deadline interface {
	SetDeadline(t time.Time) error
	SetReadDeadline(t time.Time) error
	SetWriteDeadline(t time.Time) error
}

// socket returns a network file descriptor that uses SocketFunc, if set, as
// underlying implementation.
func socket(ctx context.Context, net string, family, sotype, proto int, _ bool, laddr, raddr sockaddr, ctrlCtxFn func(context.Context, string, string, syscall.RawConn) error) (fd *netFD, err error) {
	fd = &netFD{family: family, sotype: sotype, net: net, laddr: laddr, raddr: raddr}

	if laddr != nil && raddr == nil {
		fd.listener = true
	}

	if laddr != nil && laddr.String() == "<nil>" {
		fd.laddr = &TCPAddr{}
		laddr = nil
	}

	if raddr != nil && raddr.String() == "<nil>" {
		fd.raddr = &TCPAddr{}
		raddr = nil
	}

	if SocketFunc == nil {
		return nil, errors.New("net.SocketFunc is nil")
	}

	if fd.c, err = SocketFunc(ctx, net, family, sotype, laddr, raddr); err != nil {
		return
	}

	switch fd.c.(type) {
	case Listener, PacketConn, Conn:
	default:
		return nil, syscall.EINVAL
	}

	return
}

func (fd *netFD) Read(p []byte) (n int, err error) {
	return fd.c.(Conn).Read(p)
}

func (fd *netFD) Write(p []byte) (nn int, err error) {
	return fd.c.(Conn).Write(p)
}

func (fd *netFD) Close() error {
	return fd.c.(io.Closer).Close()
}

func (fd *netFD) closeRead() error {
	return syscall.ENOSYS
}

func (fd *netFD) closeWrite() error {
	return syscall.ENOSYS
}

func (fd *netFD) accept() (f *netFD, err error) {
	if fd.c, err = fd.c.(Listener).Accept(); err != nil {
		return nil, err
	}

	return fd, nil
}

func (fd *netFD) SetDeadline(t time.Time) error {
	return fd.c.(deadline).SetDeadline(t)
}

func (fd *netFD) SetReadDeadline(t time.Time) error {
	return fd.c.(deadline).SetReadDeadline(t)
}

func (fd *netFD) SetWriteDeadline(t time.Time) error {
	return fd.c.(deadline).SetWriteDeadline(t)
}

func sysSocket(family, sotype, proto int) (int, error) {
	return 0, syscall.ENOSYS
}

func (fd *netFD) readFrom(p []byte) (n int, sa syscall.Sockaddr, err error) {
	n, a, err := fd.c.(PacketConn).ReadFrom(p)

	if err != nil {
		return
	}

	addr := a.(*UDPAddr)
	sa, err = ipToSockaddr(fd.family, addr.IP, addr.Port, addr.Zone)

	return
}

func (fd *netFD) readFromInet4(p []byte, sa *syscall.SockaddrInet4) (n int, err error) {
	n, a, err := fd.c.(PacketConn).ReadFrom(p)

	if err != nil {
		return
	}

	addr := a.(*UDPAddr)
	*sa, err = ipToSockaddrInet4(addr.IP, addr.Port)

	return
}

func (fd *netFD) readFromInet6(p []byte, sa *syscall.SockaddrInet6) (n int, err error) {
	n, a, err := fd.c.(PacketConn).ReadFrom(p)

	if err != nil {
		return
	}

	addr := a.(*UDPAddr)
	*sa, err = ipToSockaddrInet6(addr.IP, addr.Port, addr.Zone)

	return
}

func (fd *netFD) readMsg(p []byte, oob []byte, flags int) (n, oobn, retflags int, sa syscall.Sockaddr, err error) {
	return 0, 0, 0, nil, syscall.ENOSYS
}

func (fd *netFD) readMsgInet4(p []byte, oob []byte, flags int, sa *syscall.SockaddrInet4) (n, oobn, retflags int, err error) {
	return 0, 0, 0, syscall.ENOSYS
}

func (fd *netFD) readMsgInet6(p []byte, oob []byte, flags int, sa *syscall.SockaddrInet6) (n, oobn, retflags int, err error) {
	return 0, 0, 0, syscall.ENOSYS
}

func (fd *netFD) writeMsgInet4(p []byte, oob []byte, sa *syscall.SockaddrInet4) (n int, oobn int, err error) {
	return 0, 0, syscall.ENOSYS
}

func (fd *netFD) writeMsgInet6(p []byte, oob []byte, sa *syscall.SockaddrInet6) (n int, oobn int, err error) {
	return 0, 0, syscall.ENOSYS
}

func (fd *netFD) writeTo(p []byte, sa syscall.Sockaddr) (n int, err error) {
	addr := sockaddrToUDP(sa)
	return fd.c.(PacketConn).WriteTo(p, addr)
}

func (fd *netFD) writeToInet4(p []byte, sa *syscall.SockaddrInet4) (n int, err error) {
	addr := &UDPAddr{IP: sa.Addr[0:], Port: sa.Port}
	return fd.c.(PacketConn).WriteTo(p, addr)
}

func (fd *netFD) writeToInet6(p []byte, sa *syscall.SockaddrInet6) (n int, err error) {
	addr := &UDPAddr{IP: sa.Addr[0:], Port: sa.Port, Zone: zoneCache.name(int(sa.ZoneId))}
	return fd.c.(PacketConn).WriteTo(p, addr)
}

func (fd *netFD) writeMsg(p []byte, oob []byte, sa syscall.Sockaddr) (n int, oobn int, err error) {
	return 0, 0, syscall.ENOSYS
}

func (fd *netFD) dup() (f *os.File, err error) {
	return nil, syscall.ENOSYS
}
