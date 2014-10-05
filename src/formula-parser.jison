/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex
%%

\s+                              /* skip whitespace */
[0-9]+("."[0-9]+)?\b             return 'NUMBER'
[A-Za-z]\d{1,2}                  return 'CELL'
[A-Za-z]+                        return 'WORD'
"*"                              return '*'
"/"                              return '/'
"-"                              return '-'
"+"                              return '+'
"^"                              return '^'
"("                              return '('
")"                              return ')'
">"                              return '>'
">="                             return '>='
"=="                             return '=='
"<="                             return '<='
"<"                              return '<'
"!"                              return 'NOT'
":"                              return ':'
";"                              return ';'
","                              return ';'
"\""                             return '"'
<<EOF>>                          return 'EOF'
.+                               return 'ANYTHING'

/lex

/* operator associations and precedence */

%left '('
%left 'NOT'
%left '+' '-'
%left '*' '/'
%left '^'
%left UMINUS
%left '<' '<=' '==' '>' '>='

%right ')'

%start expressions

%% /* language grammar */

expressions
    : e EOF
        {return $1;}
    ;

e
    : 'NOT' e
        {$$ = !$2;}
    | e '+' e
        {$$ = $1+$3;}
    | e '-' e
        {$$ = $1-$3;}
    | e '*' e
        {$$ = $1*$3;}
    | e '/' e
        {$$ = $1/$3;}
    | e '^' e
        {$$ = Math.pow($1, $3);}
    | '-' e %prec UMINUS
        {$$ = -$2;}
    | e '<' e
        {$$ = ($1 < $3);}
    | e '<=' e
        {$$ = ($1 <= $3);}
    | e '==' e
        {$$ = ($1 == $3);}
    | e '>=' e
        {$$ = ($1 >= $3);}
    | e '>' e
        {$$ = ($1 > $3);}
    | '(' e ')'
        {$$ = $2;}
    | CELL ':' CELL
        {$$ = getMatrixValues($1, $3);}
    | CELL
        {$$ = getCalcResultAt($1);}
    | WORD '(' args ')'
        {$$ = require('formulajs')[$1.toUpperCase()].apply(this, $3); if ($$.message) { $$ = $$.message }}
    | NUMBER
        {$$ = Number(yytext);}
    | E
        {$$ = Math.E;}
    | PI
        {$$ = Math.PI;}
    | '"' ANYTHING '"'
        {$$ = $2}
    | '"' WORD '"'
        {$$ = $2}
    ;

args
    : e ';' args
        {$$ = [$e]; $$ = $$.concat($args) }
    | e
        {$$ = [$1] }
    ;

