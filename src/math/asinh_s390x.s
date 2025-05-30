// Copyright 2017 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// Minimax polynomial coefficients and other constants
DATA ·asinhrodataL18<> + 0(SB)/8, $0.749999999977387502E-01
DATA ·asinhrodataL18<> + 8(SB)/8, $-.166666666666657082E+00
DATA ·asinhrodataL18<> + 16(SB)/8, $0.303819368237360639E-01
DATA ·asinhrodataL18<> + 24(SB)/8, $-.446428569571752982E-01
DATA ·asinhrodataL18<> + 32(SB)/8, $0.173500047922695924E-01
DATA ·asinhrodataL18<> + 40(SB)/8, $-.223719767210027185E-01
DATA ·asinhrodataL18<> + 48(SB)/8, $0.113655037946822130E-01
DATA ·asinhrodataL18<> + 56(SB)/8, $0.579747490622448943E-02
DATA ·asinhrodataL18<> + 64(SB)/8, $-.139372433914359122E-01
DATA ·asinhrodataL18<> + 72(SB)/8, $-.218674325255800840E-02
DATA ·asinhrodataL18<> + 80(SB)/8, $-.891074277756961157E-02
DATA ·asinhrodataL18<> + 88(SB)/8, $.41375273347623353626
DATA ·asinhrodataL18<> + 96(SB)/8, $.51487302528619766235E+04
DATA ·asinhrodataL18<> + 104(SB)/8, $-1.67526912689208984375
DATA ·asinhrodataL18<> + 112(SB)/8, $0.181818181818181826E+00
DATA ·asinhrodataL18<> + 120(SB)/8, $-.165289256198351540E-01
DATA ·asinhrodataL18<> + 128(SB)/8, $0.200350613573012186E-02
DATA ·asinhrodataL18<> + 136(SB)/8, $-.273205381970859341E-03
DATA ·asinhrodataL18<> + 144(SB)/8, $0.397389654305194527E-04
DATA ·asinhrodataL18<> + 152(SB)/8, $0.938370938292558173E-06
DATA ·asinhrodataL18<> + 160(SB)/8, $0.212881813645679599E-07
DATA ·asinhrodataL18<> + 168(SB)/8, $-.602107458843052029E-05
DATA ·asinhrodataL18<> + 176(SB)/8, $-.148682720127920854E-06
DATA ·asinhrodataL18<> + 184(SB)/8, $-5.5
DATA ·asinhrodataL18<> + 192(SB)/8, $1.0
DATA ·asinhrodataL18<> + 200(SB)/8, $1.0E-20
GLOBL ·asinhrodataL18<> + 0(SB), RODATA, $208

// Table of log correction terms
DATA ·asinhtab2080<> + 0(SB)/8, $0.585235384085551248E-01
DATA ·asinhtab2080<> + 8(SB)/8, $0.412206153771168640E-01
DATA ·asinhtab2080<> + 16(SB)/8, $0.273839003221648339E-01
DATA ·asinhtab2080<> + 24(SB)/8, $0.166383778368856480E-01
DATA ·asinhtab2080<> + 32(SB)/8, $0.866678223433169637E-02
DATA ·asinhtab2080<> + 40(SB)/8, $0.319831684989627514E-02
DATA ·asinhtab2080<> + 48(SB)/8, $0.0
DATA ·asinhtab2080<> + 56(SB)/8, $-.113006378583725549E-02
DATA ·asinhtab2080<> + 64(SB)/8, $-.367979419636602491E-03
DATA ·asinhtab2080<> + 72(SB)/8, $0.213172484510484979E-02
DATA ·asinhtab2080<> + 80(SB)/8, $0.623271047682013536E-02
DATA ·asinhtab2080<> + 88(SB)/8, $0.118140812789696885E-01
DATA ·asinhtab2080<> + 96(SB)/8, $0.187681358930914206E-01
DATA ·asinhtab2080<> + 104(SB)/8, $0.269985148668178992E-01
DATA ·asinhtab2080<> + 112(SB)/8, $0.364186619761331328E-01
DATA ·asinhtab2080<> + 120(SB)/8, $0.469505379381388441E-01
GLOBL ·asinhtab2080<> + 0(SB), RODATA, $128

// Asinh returns the inverse hyperbolic sine of the argument.
//
// Special cases are:
//      Asinh(±0) = ±0
//      Asinh(±Inf) = ±Inf
//      Asinh(NaN) = NaN
// The algorithm used is minimax polynomial approximation
// with coefficients determined with a Remez exchange algorithm.

TEXT	·asinhAsm(SB), NOSPLIT, $0-16
	FMOVD	x+0(FP), F0
	MOVD	$·asinhrodataL18<>+0(SB), R9
	LGDR	F0, R12
	WORD	$0xC0293FDF	//iilf	%r2,1071644671
	BYTE	$0xFF
	BYTE	$0xFF
	SRAD	$32, R12
	WORD	$0xB917001C	//llgtr	%r1,%r12
	MOVW	R1, R6
	MOVW	R2, R7
	CMPBLE	R6, R7, L2
	WORD	$0xC0295FEF	//iilf	%r2,1609564159
	BYTE	$0xFF
	BYTE	$0xFF
	MOVW	R2, R7
	CMPBLE	R6, R7, L14
L3:
	WORD	$0xC0297FEF	//iilf	%r2,2146435071
	BYTE	$0xFF
	BYTE	$0xFF
	CMPW	R1, R2
	BGT	L1
	LTDBR	F0, F0
	FMOVD	F0, F10
	BLTU	L15
L9:
	FMOVD	$0, F0
	WFADB	V0, V10, V0
	WORD	$0xC0398006	//iilf	%r3,2147909631
	BYTE	$0x7F
	BYTE	$0xFF
	LGDR	F0, R5
	SRAD	$32, R5
	MOVH	$0x0, R2
	SUBW	R5, R3
	FMOVD	$0, F8
	RISBGZ	$32, $47, $0, R3, R4
	BYTE	$0x18	//lr	%r1,%r4
	BYTE	$0x14
	RISBGN	$0, $31, $32, R4, R2
	SUBW	$0x100000, R1
	SRAW	$8, R1, R1
	ORW	$0x45000000, R1
	BR	L6
L2:
	MOVD	$0x30000000, R2
	CMPW	R1, R2
	BGT	L16
	FMOVD	200(R9), F2
	FMADD	F2, F0, F0
L1:
	FMOVD	F0, ret+8(FP)
	RET
L14:
	LTDBR	F0, F0
	BLTU	L17
	FMOVD	F0, F10
L4:
	FMOVD	192(R9), F2
	WFMADB	V0, V0, V2, V0
	LTDBR	F0, F0
	FSQRT	F0, F8
L5:
	WFADB	V8, V10, V0
	WORD	$0xC0398006	//iilf	%r3,2147909631
	BYTE	$0x7F
	BYTE	$0xFF
	LGDR	F0, R5
	SRAD	$32, R5
	MOVH	$0x0, R2
	SUBW	R5, R3
	RISBGZ	$32, $47, $0, R3, R4
	SRAW	$8, R4, R1
	RISBGN	$0, $31, $32, R4, R2
	ORW	$0x45000000, R1
L6:
	LDGR	R2, F2
	FMOVD	184(R9), F0
	WFMADB	V8, V2, V0, V8
	FMOVD	176(R9), F4
	WFMADB	V10, V2, V8, V2
	FMOVD	168(R9), F0
	FMOVD	160(R9), F6
	FMOVD	152(R9), F1
	WFMADB	V2, V6, V4, V6
	WFMADB	V2, V1, V0, V1
	WFMDB	V2, V2, V4
	FMOVD	144(R9), F0
	WFMADB	V6, V4, V1, V6
	FMOVD	136(R9), F1
	RISBGZ	$57, $60, $51, R3, R3
	WFMADB	V2, V0, V1, V0
	FMOVD	128(R9), F1
	WFMADB	V4, V6, V0, V6
	FMOVD	120(R9), F0
	WFMADB	V2, V1, V0, V1
	VLVGF	$0, R1, V0
	WFMADB	V4, V6, V1, V4
	LDEBR	F0, F0
	FMOVD	112(R9), F6
	WFMADB	V2, V4, V6, V4
	MOVD	$·asinhtab2080<>+0(SB), R1
	FMOVD	104(R9), F1
	WORD	$0x68331000	//ld	%f3,0(%r3,%r1)
	FMOVD	96(R9), F6
	WFMADB	V2, V4, V3, V2
	WFMADB	V0, V1, V6, V0
	FMOVD	88(R9), F4
	WFMADB	V0, V4, V2, V0
	MOVD	R12, R6
	CMPBGT	R6, $0, L1

	LCDBR	F0, F0
	FMOVD	F0, ret+8(FP)
	RET
L16:
	WFMDB	V0, V0, V1
	FMOVD	80(R9), F6
	WFMDB	V1, V1, V4
	FMOVD	72(R9), F2
	WFMADB	V4, V2, V6, V2
	FMOVD	64(R9), F3
	FMOVD	56(R9), F6
	WFMADB	V4, V2, V3, V2
	FMOVD	48(R9), F3
	WFMADB	V4, V6, V3, V6
	FMOVD	40(R9), F5
	FMOVD	32(R9), F3
	WFMADB	V4, V2, V5, V2
	WFMADB	V4, V6, V3, V6
	FMOVD	24(R9), F5
	FMOVD	16(R9), F3
	WFMADB	V4, V2, V5, V2
	WFMADB	V4, V6, V3, V6
	FMOVD	8(R9), F5
	FMOVD	0(R9), F3
	WFMADB	V4, V2, V5, V2
	WFMADB	V4, V6, V3, V4
	WFMDB	V0, V1, V6
	WFMADB	V1, V4, V2, V4
	FMADD	F4, F6, F0
	FMOVD	F0, ret+8(FP)
	RET
L17:
	LCDBR	F0, F10
	BR	L4
L15:
	LCDBR	F0, F10
	BR	L9
