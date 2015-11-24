%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>
#include <assert.h>

struct Transform
{
	double dx, dy;
	double ds;
};

struct Expression
{
	char c;
	struct Expression *left, *center, *right;
	struct Transform t0, t1;
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
Operation divide = {idTransform, (struct Transform) {.dx = 0, .dy = -5, .ds = .8}};

Operation concat = {idTransform, (struct Transform) {.dx = 9, .dy = 0, .ds = 1}};
Operation caret = {idTransform, (struct Transform) {.dx = 6, .dy = -10, .ds = .5}};
Operation under = {idTransform, (struct Transform) {.dx = 6, .dy = 5, .ds = .5}};

YYSTYPE buildToken(char c);
YYSTYPE buildExpression(Operation op, YYSTYPE a, YYSTYPE b, YYSTYPE c);
bool printExpression(YYSTYPE q, double *x, double *y, double *s);
void printSVG(YYSTYPE e);

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
	printSVG($$);
	exit(0);
}

e:	  f T_DIV e { $$ = buildExpression(divide, $1, NULL, $3); }
	| f

f:	  g f { $$ = buildExpression(concat, $1, NULL, $2); }
	| g

g:	  h T_CARET h { $$ = buildExpression(caret, $1, NULL, $3); }
	| h T_UNDER h { $$ = buimaxldExpression(under, $1, NULL, $3); }
	| h

h:	  T_OPENPAREN e T_CLOSEPAREN
	| T_OPENBRACKET e T_CLOSEBRACKET { $$ = $2; }
	| T_ID { $$ = buildToken(yytext[0]); }

%%

YYSTYPE buildToken(char c)
{
	YYSTYPE r = malloc(sizeof (struct Expression));
	r->c = c;
	r->left = r->center = r->right = NULL;

	return r;
}

YYSTYPE buildExpression(Operation op, YYSTYPE a, YYSTYPE b, YYSTYPE c)
{
	YYSTYPE r = malloc(sizeof (struct Expression));
	r->c = '\0';
	r->left = a;
	r->center = b;
	r->right = c;

	r->t0 = op[0];
	r->t1 = op[1];

	return r;
}

struct Transform invert(struct Transform n)
{
	return (struct Transform) {.dx = n.dx, .dy = -1 * (1 / n.ds) * n.dy, .ds = 1 / n.ds};
}

bool printBlock(struct Transform t, YYSTYPE e, double *x, double *y, double *s, bool ax)
{
	if (e == NULL)
		return false;

	if (ax)
		*x += *s * t.dx;
	
	*y += *s * t.dy;
	*s *= t.ds;

	if (ax = printExpression(e, x, y, s))
		*x += *s * t.dx;
	
	*s /= t.ds;
	*y -= *s * t.dy;

	return ax;
}

bool printExpression(YYSTYPE q, double *x, double *y, double *s)
{
	if (q->c != '\0')
	{
		assert(q->left == NULL && q->right == NULL);
		printf("<text transform=\"translate(%.2f, %.2f) scale(%.2f)\">%c</text>\n", *x, *y, *s, q->c);

		return true;
	}
	else
	{
		assert(q->left != NULL && q->right != NULL);

		bool ax = printBlock(idTransform, q->left, x, y, s, false);

		double x0 = *x;
		printBlock(q->t0, q->center, &x0, y, s, ax);

		double x1 = *x;
		printBlock(q->t1, q->right, &x1, y, s, ax);

		*x = fmax(x0, x1);

		return false;
	}
}

void printSVG(YYSTYPE q)
{
	puts("<?xml version=\"1.0\" standalone=\"no\"?>");
	puts("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
	puts("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">");
	puts("<g transform=\"translate(0, 200) scale(10)\" font-family=\"Courier\">");

	double x = 0, y = 0, s = 1;
	printExpression(q, &x, &y, &s);

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
