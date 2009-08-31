implement Testutil0;

include "sys.m";
	sys: Sys;
	sprint: import sys;
include "draw.m";
include "util0.m";
	util: Util0;
	kill, killgrp, pid, warn, fail, hex, unhex, min, max, abs, eq: import util;
	preadn, readfile, readfd, writefile, workdir, exists, isdir: import util;
	rev, revint, revbig, l2a, a2l, inssort, qsort: import util;
	prefix, suffix, index, strip, droptl, taketl, stripws, join, hasstr, sizefmt, sizeparse: import util;
	g64, g64l, g32, g32l, g32i, g32il, g16, g16l, g8, gbuf: import util;
	p64, p64l, p32, p32l, p32i, p32il, p16, p16l: import util;

Testutil0: module {
	init:	fn(nil: ref Draw->Context, nil: list of string);
};

init(nil: ref Draw->Context, nil: list of string)
{
	sys = load Sys Sys->PATH;
	util = load Util0 Util0->PATH;
	util->init();

	warn("testing warn...");
	test("hex(0x00 0x0a 0x40 0x80 0xff) == 000a4080ff", hex(array[] of {byte 0, byte 16r0a, byte 16r40, byte 16r80, byte 16rff}) == "000a4080ff");
	test("len unhex(000a4080ff) == 4", len unhex("000a4080ff") == 5);
	test("hex(unhex(000a4080ff)) == 000a4080ff", hex(unhex("000a4080ff")) == "000a4080ff");
	test("unhex(0) is nil", unhex("0") == nil);
	test("unhex(zz) is nil", unhex("zz") == nil);

	test("exists(/dev/null)", exists("/dev/null"));
	test("isdir(/dev)", isdir("/dev"));
	test("workdir() != nil", workdir() != nil);
	
	test("prefix(abc, abcd)", prefix("abc", "abcd"));
	test("!prefix(bcd, abcd)", !prefix("bcd", "abcd"));
	test("!suffix(abc, abcd)", !suffix("abc", "abcd"));
	test("suffix(bcd, abcd)", suffix("bcd", "abcd"));
	test("index(abc, abcd) == 0", index("abc", "abcd") == 0);
	test("index(bcd, abcd) == 1", index("bcd", "abcd") == 1);
	test("index(cde, abcd) < 0", index("cde", "abcd") < 0);
	test("index(longer, short) < 0", index("longer", "short") < 0);

	test("droptl(test023123, 0-9) == test", droptl("test023123", "0-9") == "test");
	test("taketl(test023123, 0-9) == 023123", taketl("test023123", "0-9") == "023123");
	test("strip(ADSFtest9231, A-Z0-9) == test", strip("ADSFtest9231", "A-Z0-9") == "test");
	test("stripws( \tblah\n ) == blah", stripws(" \tblah\n ") == "blah");

	test("join(nil, x) == nil)", join(nil, "x") == nil);
	test("join(list of {a, b, c, d, e}, ,) == a,b,c,d,e", join(list of {"a", "b", "c", "d", "e"}, ",") == "a,b,c,d,e");
	test("hasstr(list of {a, b, c, d, e}, e)", hasstr(list of {"a", "b", "c", "d", "e"}, "e"));
	test("!hasstr(list of {a, b, c, d, e}, f)", !hasstr(list of {"a", "b", "c", "d", "e"}, "f"));
	test("!hasstr(list of {a, b, c, d, e}, nil)", !hasstr(list of {"a", "b", "c", "d", "e"}, nil));
	test("!hasstr(nil, nil)", !hasstr(nil, nil));

	test("sizefmt(0) == 0", sizefmt(big 0) == "0");
	test("sizefmt(256*1024) == 256k", sizefmt(big (256*1024)) == "256k");
	test("sizefmt(256*1024*1024) == 256m", sizefmt(big (256*1024*1024)) == "256m");
	test("sizefmt(4*1024**6) == 4096p", sizefmt(big 4*big 1024**6) == "4096p");
	test("sizefmt(9999*1024) == 9999k", sizefmt(big (9999*1024)) == "9999k");
	test("sizefmt(10*1024*1024) == 10m", sizefmt(big (10*1024*1024)) == "10m");

	test("sizeparse(10m) == 10*1024*1024", sizeparse("10m") == big (10*1024*1024));
	test("sizeparse(bogus) < 0", sizeparse("bogus") < big 0);
	testsizeparsefmt("0");
	testsizeparsefmt("256k");
	testsizeparsefmt("10k");
	testsizeparsefmt("30t");
	testsizeparsefmt("4096p");


	test("g64(ff0102030405060708, 1).t0 == 0102030405060708", g64(unhex("ff0102030405060708"), 1).t0 == big 16r0102030405060708);
	test("g64l(ff0807060504030201, 1).t0 == 0102030405060708", g64l(unhex("ff0807060504030201"), 1).t0 == big 16r0102030405060708);
	test("g16(ff0102, 1).t0 == 0102", g16(unhex("ff0102"), 1).t0 == 16r0102);
	test("g16l(ff0102, 1).t0 == 0201", g16l(unhex("ff0102"), 1).t0 == 16r0201);

	testputbig(p64, 16r0102030405060708, "0102030405060708");
	testputbig(p64l, 16r0102030405060708, "0807060504030201");
	testputint(p32i, 16r01020304, "01020304");
	testputint(p32il, 16r01020304, "04030201");
}

test(s: string, v: int)
{
	if(!v)
		fail(s);
}

testsizeparsefmt(s: string)
{
	test(sprint("sizefmt(sizeparse(%s)) == %s", s, s), sizefmt(sizeparse(s)) == s);
}

testputbig(put: ref fn(d: array of byte, o: int, v: big): int, v: big, s: string)
{
	d := array[1+8] of byte;
	test("put(d, 1, v) == 1+8", put(d, 1, v) == 1+8);
	test(sprint("hex(d[1:1+8] == %s", s), hex(d[1:1+8]) == s);
}

testputint(put: ref fn(d: array of byte, o: int, v: int): int, v: int, s: string)
{
	d := array[1+4] of byte;
	test("put(d, 1, v) == 1+4", put(d, 1, v) == 1+4);
	test(sprint("hex(d[1:1+4] == %s", s), hex(d[1:1+4]) == s);
}
