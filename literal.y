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

init: e T_ENDLINE { printf("%s\n", $1); exit(0); }
;

e:    f { printf("Entro a e[0] con \"%s\" {1: \"%s\"}\n", $$, $1); }
	| f T_SUM e { printf("Entro a e[1] con \"%s\" {1: \"%s\", 2: \"%s\", 3: \"%s\"}\n", $$, $1, $2, $3); sprintf($$, "%s+%s", $1, $3); }
;

f: id
;

id: T_ID { $$ = strdup(yytext); }
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
