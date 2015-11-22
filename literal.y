%{

#include <stdio.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;

void yyerror(const char *s);
%}

%token T_DIV
%token T_CARET T_UNDER
%token T_OPENPAREN T_CLOSEPAREN T_OPENBRACKET T_CLOSEBRACKET
%token T_ID

%start E

%%

E:    F T_DIV E { printf("(frac $1 $3)"); }
	| F
;

F:    T_OPENPAREN E T_CLOSEPAREN { printf("($2)"); }
	| T_ID
;
