Util0: module
{
	PATH:	con "/dis/lib/util0.dis";

	init:	fn();

	kill:		fn(pid: int);
	killgrp:	fn(pid: int);
	pid:		fn(): int;
	warn:		fn(s: string);
	fail:		fn(s: string);
	hex:		fn(d: array of byte): string;
	unhex:		fn(s: string): array of byte;
	min,
	max:		fn(a, b: int): int;
	abs:		fn(a: int): int;
	eq:		fn(a, b: array of byte): int;

	preadn:		fn(fd: ref Sys->FD, buf: array of byte, n: int, o: big): int;
	readfile:	fn(f: string, max: int): array of byte;  # max -1 means no limit
	readfd:		fn(fd: ref Sys->FD, max: int): array of byte;
	writefile:	fn(f: string, create: int, buf: array of byte): string;
	writefd:	fn(fd: ref Sys->FD, buf: array of byte): string;
	workdir:	fn(): string;
	exists:		fn(f: string): int;
	isdir:		fn(f: string): int;

	rev:		fn[T](l: list of T): list of T;
	revint:		fn(l: list of int): list of int;
	revbig:		fn(l: list of big): list of big;
	l2a:		fn[T](l: list of T): array of T;
	a2l:		fn[T](l: array of T): list of T;
	inssort,
	qsort:		fn[T](a: array of T, ge: ref fn(a, b: T): int);

	prefix,
	suffix,
	index:		fn(sub, s: string): int;
	strip,		
	droptl,		
	taketl:		fn(s, cl: string): string;
	stripws:	fn(s: string): string;
	join:		fn(l: list of string, sep: string): string;
	hasstr:		fn(l: list of string, s: string): int;

	sizefmt:	fn(v: big): string;
	sizeparse:	fn(s: string): big;

	g64, g64l:	fn(d: array of byte, o: int): (big, int);
	g32, g32l:	fn(d: array of byte, o: int): (big, int);
	g32i, g32il,
	g16, g16l,
	g8:		fn(d: array of byte, o: int): (int, int);
	gbuf:		fn(d: array of byte, o, n: int): (array of byte, int);

	p64, p64l:	fn(d: array of byte, o: int, v: big): int;
	p32, p32l:	fn(d: array of byte, o: int, v: big): int;
	p32i, p32il,
	p16, p16l:	fn(d: array of byte, o: int, v: int): int;
};
