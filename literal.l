%{

#include <stdio.h>

#define YY_DECL int yylex()

#include "literal.tab.h"

%}

%%

[ \t] ;

"\n" { return T_ENDLINE; }

"(" { return T_OPENPAREN; }
")" { return T_CLOSEPAREN; }
"{" { return T_OPENBRACKET; }
"}" { return T_CLOSEBRACKET; }
"/" { return T_DIV; }
"^" { return T_CARET; }
"_" { return T_UNDER; }

[^^_/{}()] { return T_ID; }

%%

