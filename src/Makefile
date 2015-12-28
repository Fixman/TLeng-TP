all: formula

formula.tab.c formula.tab.h: formula.y
	bison --verbose -d formula.y

lex.yy.c: formula.tab.h formula.l
	flex formula.l

formula: lex.yy.c formula.tab.c formula.tab.h
	gcc -std=gnu11 -o formula lex.yy.c formula.tab.c -lfl -lm -g

clean:
	rm -f formula.output formula.tab.h formula.tab.c lex.yy.c formula
