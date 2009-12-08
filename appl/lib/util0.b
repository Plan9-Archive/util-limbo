implement Util0;

include "sys.m";
	sys: Sys;
	sprint: import sys;
include "string.m";
	str: String;
include "util0.m";

init()
{
	sys = load Sys Sys->PATH;
	str = load String String->PATH;
}

progctl(pid: int, s: string)
{
	f := sprint("/prog/%d/ctl", pid);
	fd := sys->open(f, Sys->OWRITE);
	sys->fprint(fd, "%s", s);
}

kill(pid: int)
{
	progctl(pid, "kill");
}

killgrp(pid: int)
{
	progctl(pid, "killgrp");
}

pid(): int
{
	return sys->pctl(0, nil);
}

warn(s: string)
{
	sys->fprint(sys->fildes(2), "%s\n", s);
}

fail(s: string)
{
	warn(s);
	raise "fail:"+s;
}

hex(d: array of byte): string
{
	s: string;
	n := len d;
	for(i := 0; i < n; i++)
		s += sprint("%02x", int d[i]);
	return s;
}

unhexc(c: int): int
{
	if(c >= '0' && c <= '9') return c-'0';
	if(c >= 'a' && c <= 'f') return c-'a'+10;
	if(c >= 'A' && c <= 'F') return c-'A'+10;
	return -1;
}

unhex(s: string): array of byte
{
	if(len s % 2 != 0) {
		sys->werrstr("bad hex, odd length");
		return nil;
	}
	d := array[len s/2] of byte;
	o := 0;
	for(i := 0; i < len s; i += 2) {
		hi := unhexc(s[i]);
		lo := unhexc(s[i+1]);
		if(hi < 0 || lo < 0) {
			sys->werrstr(sprint("bad hex %#q", s[i:i+2]));
			return nil;
		}
		d[o++] = byte ((hi<<4) | lo);
	}
	return d;
}

min(a, b: int): int
{
	if(a < b)
		return a;
	return b;
}

max(a, b: int): int
{
	if(a > b)
		return a;
	return b;
}

abs(a: int): int
{
	if(a < 0)
		a = -a;
	return a;
}

eq(a, b: array of byte): int
{
	if(len a != len b)
		return 0;
	n := len a;
	for(i := 0; i < n; i++)
		if(a[i] != b[i])
			return 0;
	return 1;
}


preadn(fd: ref Sys->FD, buf: array of byte, n: int, o: big): int
{
	h := 0;
	while(h < n) {
		nn := sys->pread(fd, buf[h:], n-h, o+big h);
		if(nn < 0)
			return nn;
		if(nn == 0)
			break;
		h += nn;
	}
	return h;
}

readfile(f: string, max: int): array of byte
{
	fd := sys->open(f, Sys->OREAD);
	if(fd == nil) {
		sys->werrstr(sprint("open %q: %r", f));
		return nil;
	}
	return readfd(fd, max);
}

readfd(fd: ref Sys->FD, max: int): array of byte
{
	buf := array[0] of byte;
	d := array[Sys->ATOMICIO] of byte;
	for(;;) {
		n := sys->read(fd, d, len d);
		if(n < 0) {
			sys->werrstr(sprint("read: %r"));
			return nil;
		}
		if(n == 0)
			break;
		if(max >= 0 && len buf+n > max) {
			sys->werrstr(sprint("file too big"));
			return nil;
		}
		nbuf := array[len buf+n] of byte;
		nbuf[:] = buf;
		nbuf[len buf:] = d[:n];
		buf = nbuf;
	}
	return buf;
}

writefile(f: string, create: int, buf: array of byte): string
{
	fd: ref Sys->FD;
	if(create){
		fd = sys->create(f, Sys->OWRITE|Sys->OTRUNC, 8r666);
		if(fd == nil)
			return sprint("create %q: %r", f);
	} else {
		fd = sys->open(f, Sys->OWRITE|Sys->OTRUNC);
		if(fd == nil)
			return sprint("open %q: %r", f);
	}
	return writefd(fd, buf);
}

writefd(fd: ref Sys->FD, buf: array of byte): string
{
	if(sys->write(fd, buf, len buf) != len buf)
		return sprint("write: %r");
	return nil;
}

workdir(): string
{
	return sys->fd2path(sys->open(".", Sys->OREAD));
}

exists(f: string): int
{
	return sys->stat(f).t0 == 0;
}

isdir(f: string): int
{
	(ok, dir) := sys->stat(f);
	return ok == 0 && (dir.mode & Sys->DMDIR);
}


rev[T](l: list of T): list of T
{
	r: list of T;
	for(; l != nil; l = tl l)
		r = hd l::r;
	return r;
}

revint(l: list of int): list of int
{
	r: list of int;
	for(; l != nil; l = tl l)
		r = hd l::r;
	return r;
}

revbig(l: list of big): list of big
{
	r: list of big;
	for(; l != nil; l = tl l)
		r = hd l::r;
	return r;
}

l2a[T](l: list of T): array of T
{
	a := array[len l] of T;
	i := 0;
	for(; l != nil; l = tl l)
		a[i++] = hd l;
	return a;
}

a2l[T](a: array of T): list of T
{
	l: list of T;
	for(i := len a-1; i >= 0; i--)
		l = a[i]::l;
	return l;
}

inssort[T](a: array of T, ge: ref fn(a, b: T): int)
{
	for(i := 1; i < len a; i++) {
		tmp := a[i];
		for(j := i; j > 0 && ge(a[j-1], tmp); j--)
			a[j] = a[j-1];
		a[j] = tmp;
	}
}

# xxx it isn't qsort!
qsort[T](a: array of T, ge: ref fn(a, b: T): int)
{
	for(i := 1; i < len a; i++) {
		tmp := a[i];
		for(j := i; j > 0 && ge(a[j-1], tmp); j--)
			a[j] = a[j-1];
		a[j] = tmp;
	}
}


prefix(pre, s: string): int
{
	return len pre <= len s && pre == s[:len pre];
}

suffix(suf, s: string): int
{
	return len suf <= len s && suf == s[len s-len suf:];
}

index(sub, s: string): int
{
	nsub := len sub;
	n := len s-nsub+1;
next:
	for(i := 0; i < n; i++) {
		o := i;
		for(j := 0; j < nsub; j++)
			if(s[o++] != sub[j])
				continue next;
		return i;
	}
	return -1;
}

strip(s, cl: string): string
{
	return str->drop(droptl(s, cl), cl);
}

droptl(s, cl: string): string
{
	for(i := len s-1; i >= 0; i--)
		if(!str->in(s[i], cl))
			break;
	return s[:i+1];
}

taketl(s, cl: string): string
{
	for(i := len s-1; i >= 0; i--)
		if(!str->in(s[i], cl))
			break;
	return s[i+1:];
}

stripws(s: string): string
{
	return strip(s, " \t\r\n");
}

join(l: list of string, sep: string): string
{
	s := "";
	for(; l != nil; l = tl l)
		s += sep+hd l;
	if(s != nil)
		s = s[len sep:];
	return s;
}

hasstr(l: list of string, s: string): int
{
	for(; l != nil; l = tl l)
		if(hd l == s)
			return 1;
	return 0;
}

sizefmts := array[] of {'b', 'k', 'm', 'g', 't', 'p', 'e', 'z'};
sizefmt(v: big): string
{
	i := 0;
	while(v > big 9999 && i < len sizefmts-1) {
		v /= big 1024;
		i++;
	}
	s := sprint("%bd", v);
	if(i != 0)
		s[len s] = sizefmts[i];
	return s;
}

sizeparse(s: string): big
{
	(v, rem) := str->tobig(s, 10);
	if(rem == nil)
		return v;
	if(len rem != 1) {
		sys->werrstr(sprint("bad size %#q", s));
		return big -1;
	}
	c := rem[0];
	for(i := 0; i < len sizefmts; i++)
		if(sizefmts[i] == c)
			return v;
		else
			v *= big 1024;
	sys->werrstr(sprint("bad size %#q", s));
	return big -1;
}

gbb(d: array of byte, o, n: int): (big, int)
{
	d = d[o:];
	v := big 0;
	for(i := 0; i < n; i++)
		v = (v<<8)|big d[i];
	return (v, o+n);
}

gbl(d: array of byte, o, n: int): (big, int)
{
	d = d[o:];
	v := big 0;
	for(i := n-1; i >= 0; i--)
		v = (v<<8)|big d[i];
	return (v, o+n);
}

gib(d: array of byte, o, n: int): (int, int)
{
	d = d[o:];
	v := 0;
	for(i := 0; i < n; i++)
		v = (v<<8)|int d[i];
	return (v, o+n);
}

gil(d: array of byte, o, n: int): (int, int)
{
	d = d[o:];
	v := 0;
	for(i := n-1; i >= 0; i--)
		v = (v<<8)|int d[i];
	return (v, o+n);
}

pbb(d: array of byte, o: int, v: big, n: int): int
{
	if(d == nil)
		return o+n;
	d = d[o:];
	for(i := n-1; i >= 0; i--) {
		d[i] = byte v;
		v >>= 8;
	}
	return o+n;
}

pbl(d: array of byte, o: int, v: big, n: int): int
{
	if(d == nil)
		return o+n;
	d = d[o:];
	for(i := 0; i < n; i++) {
		d[i] = byte v;
		v >>= 8;
	}
	return o+n;
}

pib(d: array of byte, o: int, v: int, n: int): int
{
	if(d == nil)
		return o+n;
	d = d[o:];
	for(i := n-1; i >= 0; i--) {
		d[i] = byte v;
		v >>= 8;
	}
	return o+n;
}

pil(d: array of byte, o: int, v: int, n: int): int
{
	if(d == nil)
		return o+n;
	d = d[o:];
	for(i := 0; i < n; i++) {
		d[i] = byte v;
		v >>= 8;
	}
	return o+n;
}


g64(d: array of byte, o: int): (big, int)
{
	return gbb(d, o, 8);
}

g64l(d: array of byte, o: int): (big, int)
{
	return gbl(d, o, 8);
}

g32(d: array of byte, o: int): (big, int)
{
	return gbb(d, o, 4);
}

g32l(d: array of byte, o: int): (big, int)
{
	return gbl(d, o, 4);
}

g32i(d: array of byte, o: int): (int, int)
{
	return gib(d, o, 4);
}

g32il(d: array of byte, o: int): (int, int)
{
	return gil(d, o, 4);
}

g16(d: array of byte, o: int): (int, int)
{
	return gib(d, o, 2);
}

g16l(d: array of byte, o: int): (int, int)
{
	return gil(d, o, 2);
}

g8(d: array of byte, o: int): (int, int)
{
	return gib(d, o, 1);
}

gbuf(d: array of byte, o, n: int): (array of byte, int)
{
	r := array[n] of byte;
	r[:] = d[o:o+n];
	return (r, o+n);
}


p64(d: array of byte, o: int, v: big): int
{
	return pbb(d, o, v, 8);
}

p64l(d: array of byte, o: int, v: big): int
{
	return pbl(d, o, v, 8);
}

p32(d: array of byte, o: int, v: big): int
{
	return pbb(d, o, v, 4);
}

p32l(d: array of byte, o: int, v: big): int
{
	return pbl(d, o, v, 4);
}

p32i(d: array of byte, o: int, v: int): int
{
	return pib(d, o, v, 4);
}

p32il(d: array of byte, o: int, v: int): int
{
	return pil(d, o, v, 4);
}

p16(d: array of byte, o: int, v: int): int
{
	return pib(d, o, v, 2);
}

p16l(d: array of byte, o: int, v: int): int
{
	return pil(d, o, v, 2);
}
