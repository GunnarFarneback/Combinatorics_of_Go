all:   	legalg legal legalm tar

legalg:	legal.c states.c states.h Makefile
	cc -Wall -g -o legalg legal.c states.c -lJudy

legal:	legal.c states.c states.h Makefile
	cc -static -O3 -m64 -o legal legal.c states.c -lJudy

legalm:	memlegal.c states.c states.h Makefile
	cc -O3 -m64 -o legalm memlegal.c states.c -lJudy

tar:	memlegal.c legal.c states.c states.h Makefile legals CRT.hs README
	tar -zcf legal.tgz memlegal.c legal.c states.c states.h Makefile legals CRT.hs README
