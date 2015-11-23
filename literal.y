%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Expression
{
	char c;
	int x, y;
	int size;
};

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern char* yytext;

void yyerror(const char *s);
void print(char s);

struct Expression tokens[1000];

int x, y, size;
int id;
%}

%token T_SUM
%token T_DIV
%token T_CARET T_UNDER
%token T_OPENPAREN T_CLOSEPAREN T_OPENBRACKET T_CLOSEBRACKET
%token T_ID
%token T_ENDLINE

%start init

%%

init: e T_ENDLINE
{
	int i;
	for (i = 0; i < id; i++)
		printf("\"%c\", x = %d, y = %d, size = %d\n", tokens[i].c, tokens[i].x, tokens[i].y, tokens[i].size);

	exit(0);
}
;

e:    f
	| f T_SUM e
;

f: id
;

id: T_ID
{
	tokens[id++] = (struct Expression) {.c = yytext[0], .x = x, .y = y, .size = size};
	x += size;
}
;

%%

void print(char s)
{
	printf("Caracter \"%c\" (%d)\n", s, (int) s);
}

void yyerror(const char* s)
{
	fprintf(stderr, "Parse error: %s\n", s);
	exit(1);
}

int main()
{
	x = 0;
	y = 0;
	size = 1;

	yyparse();

	printf("asdf\n");
}
