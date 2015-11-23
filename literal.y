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
Operation caret = {idTransform, (struct Transform) {.dx = 6, .dy = -10, .ds = .6}};
Operation concat = {idTransform, (struct Transform) {.dx = 8, .dy = 0, .ds = 1}};

YYSTYPE buildToken(char c);
YYSTYPE buildExpression(Operation op, YYSTYPE a, YYSTYPE b);
void printExpression(YYSTYPE q, int tab);
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

e:    f e { $$ = buildExpression(concat, $1, $2); }
	| f

f:    g T_CARET g { $$ = buildExpression(caret, $1, $3); }
	| g

g:    id

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

void printBlock(struct Transform t, struct Expression *e, int tab)
{
	printTabs(tab); printf("<g transform=\"translate(%.2f, %.2f) scale(%.2f)\">\n", t.dx, t.dy, t.ds);
	printExpression(e, tab + 1);
	printTabs(tab); printf("</g>");
}

void printExpression(YYSTYPE q, int tab)
{
	if (q->c != '\0')
	{
		assert(q->left == NULL && q->right == NULL);

		printTabs(tab);
		printf("<text>%c</text>\n", q->c);
	}
	else
	{
		assert(q->left != NULL && q->right != NULL);

		printBlock(q->tl, q->left, tab);
		printBlock(q->tr, q->right, tab);
	}
}

void printSVG(YYSTYPE q)
{
	puts("<?xml version=\"1.0\" standalone=\"no\"?>");
	puts("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
	puts("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">");
	puts("<g transform=\"translate(0, 200) scale(10)\" font-family=\"Courier\">");

	printExpression(q, 0);

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
