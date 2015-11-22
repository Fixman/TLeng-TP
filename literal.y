%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define YYSTYPE char *

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern char* yytext;

void yyerror(const char *s);
void print(char s);

int x;
%}

%token T_SUM
%token T_DIV
%token T_CARET T_UNDER
%token T_OPENPAREN T_CLOSEPAREN T_OPENBRACKET T_CLOSEBRACKET
%token T_ID
%token T_ENDLINE

%start init

%%

init: e T_ENDLINE { exit(0); }
;

e:	id e { printf("(%s)", $1); }
	|
;

id: T_ID	{ $$ = strdup(yytext); }
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
	yyparse();
}
