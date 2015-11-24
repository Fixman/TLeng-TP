%{
#include <stdio.h>
#include "formula.tab.h"
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

[^^_/{}() \t] { return T_ID; }

%%

