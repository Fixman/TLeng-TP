all: literal

literal.tab.c literal.tab.h: literal.y
	bison -d literal.y

lex.yy.c: literal.tab.h literal.l
	flex literal.l

literal: lex.yy.c literal.tab.c literal.tab.h
	gcc -o literal lex.yy.c literal.tab.c -lfl

clean:
	rm -f literal.tab.h literal.tab.c lex.yy.c literal
