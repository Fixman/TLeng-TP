%{

#include <stdio.h>

#define YY_DECL int yylex()

#include "literal.tab.h"

%}

%%

"("	{ return T_OPENPAREN; }
")" { return T_CLOSEPAREN; }
"/" { return T_DIV; }
"[a-zA-Z0-9]" { return T_ID; }

%%

