all: literal

literal.tab.c literal.tab.h: literal.y
	bison --verbose -d literal.y

lex.yy.c: literal.tab.h literal.l
	flex literal.l

literal: lex.yy.c literal.tab.c literal.tab.h
	gcc -std=gnu11 -o literal lex.yy.c literal.tab.c -lfl -lm

clean:
	rm -f literal.output literal.tab.h literal.tab.c lex.yy.c literal
