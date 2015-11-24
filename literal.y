%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

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
Operation divide = {(struct Transform) {.dx = 0, .dy = -5, .ds = .8}, (struct Transform) {.dx = 0, .dy = 5, .ds = .8}};
Operation concat = {idTransform, (struct Transform) {.dx = 8, .dy = 0, .ds = 1}};
Operation caret = {idTransform, (struct Transform) {.dx = 6, .dy = -10, .ds = .5}};
Operation under = {idTransform, (struct Transform) {.dx = 6, .dy = 8, .ds = .5}};

YYSTYPE buildToken(char c);
YYSTYPE buildExpression(Operation op, YYSTYPE a, YYSTYPE b);
void printExpression(YYSTYPE q, double *x, double *y, double *s, double dx, int tab);
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

e:	  f T_DIV e { $$ = buildExpression(divide, $1, $3); }
	| f

f:	  g f { $$ = buildExpression(concat, $1, $2); }
	| g

g:	  h T_CARET h { $$ = buildExpression(caret, $1, $3); }
	| h T_UNDER h { $$ = buildExpression(under, $1, $3); }
	| h

h:	  T_OPENPAREN e T_CLOSEPAREN
	| T_OPENBRACKET e T_CLOSEBRACKET { $$ = $2; }
	| T_ID { $$ = buildToken(yytext[0]); }

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

void printBlock(struct Transform t, YYSTYPE e, double *x, double *y, double *s, int tab)
{
	static double ls = 1;

	*y += t.dy * *s;
	*x += t.dx * *s;
	*s *= t.ds;

	printExpression(e, x, y, s, t.dx, tab + 1);

	*s /= t.ds;
	*y -= t.dy * *s;
}

void printExpression(YYSTYPE q, double *x, double *y, double *s, double dx, int tab)
{
	if (q->c != '\0')
	{
		assert(q->left == NULL && q->right == NULL);

		printTabs(tab);
		printf("<text transform=\"translate(%.2f, %.2f) scale(%.2f)\">%c</text>\n", *x, *y, *s, q->c);
		//*x += *s * 8;
	}
	else
	{
		assert(q->left != NULL && q->right != NULL);

		printBlock(q->tl, q->left, x, y, s, tab);
		printBlock(q->tr, q->right, x, y, s, tab);
	}
}

void printSVG(YYSTYPE q)
{
	puts("<?xml version=\"1.0\" standalone=\"no\"?>");
	puts("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
	puts("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">");
	puts("<g transform=\"translate(0, 200) scale(10)\" font-family=\"Courier\">");

	double x = 0, y = 0, s = 1;
	printExpression(q, &x, &y, &s, 0, 0);

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
