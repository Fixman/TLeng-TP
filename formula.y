%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>
#include <assert.h>

enum Operation
{
	Concat,
	Caretunder,
	Parentheses,
	Division,
	Literal
};

struct Size
{
	double x, y;
};

struct Expression
{
	struct Expression *left, *right;
	char c;

	enum Operation t;
	struct Size d;
};

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern char* yytext;

#define YYSTYPE_IS_DECLARED
typedef struct Expression *YYSTYPE;

YYSTYPE buildToken(char);
YYSTYPE buildExpression(enum Operation, YYSTYPE, YYSTYPE);
void printSVG(YYSTYPE);

void sizeExpression(YYSTYPE);

void yyerror(const char *);
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
	printSVG($$);
	exit(0);
}

e:	  f T_DIV e { $$ = buildExpression(Division, $1, $3); }
	| f

f:	  g f { $$ = buildExpression(Concat, $1, $2); }
	| g

g:	  h T_CARET h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, $3, NULL)); }
	| h T_UNDER h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, NULL, $3)); }
	| h T_CARET h T_UNDER h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, $3, $5)); }
	| h T_UNDER h T_CARET h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, $5, $3)); }
	| h

h:	  T_OPENPAREN e T_CLOSEPAREN { $$ = buildExpression(Parentheses, $1, $3); }
	| T_OPENBRACKET e T_CLOSEBRACKET { $$ = $2; }
	| T_ID { $$ = buildToken(yytext[0]); }

%%

YYSTYPE buildToken(char c)
{
	YYSTYPE r = malloc(sizeof (struct Expression));
	r->c = c;
	r->t = Literal;
	r->left = r->right = NULL;

	return r;
}

YYSTYPE buildExpression(enum Operation op, YYSTYPE left, YYSTYPE right)
{
	YYSTYPE r = malloc(sizeof (struct Expression));
	r->c = '\0';
	r->t = op;
	r->left = left;
	r->right = right;

	return r;
}

struct Size getSizes(enum Operation t, YYSTYPE left, YYSTYPE right)
{
	switch (t)
	{
		case Concat:
			return (struct Size) {.x = left->d.x + right->d.x, .y = left->d.y + right->d.y};

		case Caretunder:
		{
			struct Size r = {0, 0};
			if (left)
			{
				r.x += left->d.x / 2. + 1;
				r.y += left->d.y / 2. + 1;
			}
			if (right)
			{
				r.x += right->d.x / 2. + 1;
				r.y += right->d.y / 2. + 1;
			}
			return r;
		}

		case Literal:
			return (struct Size) {.x = 1, .y = 1};
	}

	fprintf(stderr, "Invalid operation: %d\n", t);
	abort();
}

void sizeExpression(YYSTYPE q)
{
	if (q == NULL)
		return;
	
	sizeExpression(q->left);
	sizeExpression(q->right);

	q->d = getSizes(q->t, q->left, q->right);
}

void printSVG(YYSTYPE q)
{
	sizeExpression(q);

	puts("<?xml version=\"1.0\" standalone=\"no\"?>");
	puts("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
	puts("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">");

	puts("<g transform=\"translate(50, 200) scale(8)\" font-family=\"monospace\">");

	// double x = 0, y = 0, s = 1;
	// printExpression(q, &x, &y, &s, true);

	puts("</g>");
	puts("</svg>");
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
