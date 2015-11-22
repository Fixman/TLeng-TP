%{

#include <stdio.h>

#define YY_DECL int yylex()

#include "literal.tab.h"

%}

%%

"\n" { return T_ENDLINE; }

"("	{ return T_OPENPAREN; }
")" { return T_CLOSEPAREN; }
"/" { return T_DIV; }
"+" { return T_SUM; }

[a-zA-Z0-9] { return T_ID; }

%%

