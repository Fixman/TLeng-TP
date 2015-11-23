%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Transform
{
	double dx, dy;
	double ds;
};

struct Expression
{
	char c;
	struct Expression *left, *right;
	struct Transform tl, tr;
};


extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern char* yytext;

#define YYSTYPE_IS_DECLARED
typedef struct Expression *YYSTYPE;
typedef struct Transform Operation[2];

//const struct Transform idTransform = {.dx = 0, .dy = 0, .ds = 1};
#define idTransform ((struct Transform) {.dx = 0, .dy = 0, .ds = 1})
Operation caret = {idTransform, (struct Transform) {.dx = 1, .dy = 1, .ds = .75}};

YYSTYPE buildToken(char c);
YYSTYPE buildExpression(Operation op, YYSTYPE a, YYSTYPE b);
void printExpression(YYSTYPE e);

void yyerror(const char *s);
%}

%token T_DIV
%token T_CARET T_UNDER
%token T_OPENPAREN T_CLOSEPAREN T_OPENBRACKET T_CLOSEBRACKET
%token T_ID
%token T_ENDLINE

%start init

%%

init: e T_ENDLINE
{
	printExpression($$);
	exit(0);
}

e:	  f T_CARET e { $$ = buildExpression(caret, $1, $3); }
	| f

f:	  id

id:   T_ID { $$ = buildToken(yytext[0]); }

%%

YYSTYPE buildToken(char c)
{
	YYSTYPE r = malloc(sizeof (struct Expression));
	r->c = c;
	r->left = r->right = NULL;

	return r;
}

YYSTYPE buildExpression(Operation op, YYSTYPE a, YYSTYPE b)
{
	YYSTYPE r = malloc(sizeof (struct Expression));
	r->c = '\0';
	r->left = a;
	r->right = b;

	r->tl = op[0];
	r->tr = op[1];

	return r;
}

void printTabs(int tab)
{
	while (tab--)
		printf("\t");
}

void printExpression(YYSTYPE q)
{
	static int tab = 0;
	
	if (q->c != '\0')
	{
		printTabs(tab);
		printf("Text: %c\n", q->c);
	}
	else
	{
		printTabs(tab);
		printf("Transform: dx = %lf, dy = %lf, ds = %lf\n", q->tl.dx, q->tl.dy, q->tl.ds);

		tab++;
		printExpression(q->left);
		tab--;

		printTabs(tab);
		printf("Transform: dx = %lf, dy = %lf, ds = %lf\n", q->tr.dx, q->tr.dy, q->tr.ds);
		
		tab++;
		printExpression(q->right);
		tab--;
	}
}

void yyerror(const char* s)
{
	fprintf(stderr, "Parse error: %s\n", s);
	exit(1);
}

int main()
{
	yyparse();
}
