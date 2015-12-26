%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>
#include <assert.h>

enum Operation
{
	Literal,
	Concat,
	Caretunder,
	Parentheses,
	Division
};

char *colors[] = {"black", "red", "blue", "green", "purple"};

struct Size
{
	double x;
	double ny, my;
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
extern char* yytext;

#define YYSTYPE_IS_DECLARED
typedef struct Expression *YYSTYPE;

YYSTYPE buildToken(char);
YYSTYPE buildExpression(enum Operation, YYSTYPE, YYSTYPE);
void sizeExpression(YYSTYPE);
void printExpression(YYSTYPE);
void printSVG(YYSTYPE);

void yyerror(const char *);
%}

%token T_DIV
%token T_CARET T_UNDER
%token T_OPENPAREN T_CLOSEPAREN T_OPENBRACKET T_CLOSEBRACKET
%token T_ID
%token T_ENDLINE

%start init

%%

init: e T_ENDLINE { printSVG($$); }

e:	  f T_DIV e { $$ = buildExpression(Division, $1, $3); }
	| f

f:	  g f { $$ = buildExpression(Concat, $1, $2); }
	| g

g:	  h T_CARET h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, $3, NULL)); }
	| h T_UNDER h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, NULL, $3)); }
	| h T_CARET h T_UNDER h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, $3, $5)); }
	| h T_UNDER h T_CARET h { $$ = buildExpression(Concat, $1, buildExpression(Caretunder, $5, $3)); }
	| h

h:	  T_OPENPAREN e T_CLOSEPAREN { $$ = buildExpression(Parentheses, $2, NULL); }
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
		case Literal:
			return (struct Size) {.x = 7, .ny = -6, .my = 0};

		case Concat:
			return (struct Size) {.x = left->d.x + right->d.x, .ny = fmin(left->d.ny, right->d.ny), .my = fmax(left->d.my, right->d.my)};

		case Caretunder:
		{
			struct Size r = {0, 0};
			if (left)
			{
				r.x = fmax(r.x, left->d.x * .75);
				r.ny = left->d.ny * .75 - 6;
			}
			if (right)
			{
				r.x = fmax(r.x, right->d.x * .75);
				r.my = right->d.my * .75 + 5;
			}
			return r;
		}

		case Parentheses:
			return (struct Size) {.x = left->d.x + 9, .ny = left->d.ny - .5, .my = left->d.my + .5};
	}

	fprintf(stderr, "Invalid operation under calculate: %d\n", t);
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

void transformExpression(YYSTYPE q, double dx, double dy, double ds)
{
	if (q == NULL)
		return;

	printf("<g transform=\"translate(%lf %lf) scale(%lf)\">\n", dx, dy, ds);
	printExpression(q);
	printf("</g>\n");
}

void printExpression(YYSTYPE q)
{
	if (q == NULL)
		return;

	switch (q->t)
	{
		case Literal:
			printf("<text>%c</text>\n", q->c);
			break;

		case Concat:
			printExpression(q->left);
			transformExpression(q->right, q->left->d.x, 0, 1);
			break;

		case Caretunder:
			transformExpression(q->left, 0, -6, .75);
			transformExpression(q->right, 0, 5, .75);
			break;

		case Parentheses:
		{
			double height = (q->d.my - q->d.ny) / 6;
			printf("<text transform=\"scale(1 %lf) translate(0 %lf)\">(</text>", height, height / 2);
			transformExpression(q->left, 5, 0, 1);
			printf("<text transform=\"scale(1 %lf) translate(%lf %lf)\">)</text>", height, q->left->d.x + 3, height / 2);

			// printExpression(q->left);
			break;
		}
	}

	if (q->t != Concat)
	{
		printf("<line stroke-width=\".1\" stroke=\"%s\" x1=\"0\" x2=\"%lf\" y1=\"%lf\" y2=\"%lf\" />\n", colors[q->t], q->d.x, q->d.ny, q->d.ny);
		printf("<line stroke-width=\".1\" stroke=\"%s\" x1=\"0\" x2=\"%lf\" y1=\"%lf\" y2=\"%lf\" />\n", colors[q->t], q->d.x, q->d.my, q->d.my);
	}
}

void printSVG(YYSTYPE q)
{
	sizeExpression(q);

	puts("<?xml version=\"1.0\" standalone=\"no\"?>");
	puts("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
	puts("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">");

	puts("<g transform=\"translate(50, 200) scale(8)\" font-family=\"monospace\">");

	printExpression(q);

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
