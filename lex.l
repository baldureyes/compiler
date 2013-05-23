%{
#include <stdio.h>
#include <string.h>
#include "parser.tab.h"

int linenum = 1;

%}



letter [A-Za-z]
digit [0-9]
integer [0-9]+
identifier ({letter})({letter}|{digit})*

%%

[ \t]+
\n    { linenum++; }

"class" { yylval.text=yytext; return CLASS; }
"extends" { yylval.text=yytext; return EXTENDS; }
"public" { yylval.text=yytext; return PUBLIC; }
"static" { yylval.text=yytext; return STATIC; }
"void" { yylval.text=yytext; return VOID; }
"main" { yylval.text=yytext; return MAIN; }
"length" { yylval.text=yytext; return LENGTH; }
"{" { yylval.text=yytext; return LLBR; }
"}" { yylval.text=yytext; return RLBR; }
"[" { yylval.text=yytext; return LMBR; }
"]" { yylval.text=yytext; return RMBR; }
"(" { yylval.text=yytext; return LSBR; }
")" { yylval.text=yytext; return RSBR; }
"," { yylval.text=yytext; return COMMA; }
";" { yylval.text=yytext; return SEMI; }
"." { yylval.text=yytext; return PERIOD; }
"String" { yylval.text=yytext; return STRING; }
"int" { yylval.text=yytext; return INT; }
"boolean" { yylval.text=yytext; return BOOLEAN; }
"new" { yylval.text=yytext; return NEW; }
"!" { yylval.text=yytext; return EXCLA; }
"if" { yylval.text=yytext; return IF; }
"else" { yylval.text=yytext; return ELSE; }
"while" { yylval.text=yytext; return WHILE; }
"true" { yylval.text=yytext; return TRUE; }
"false" { yylval.text=yytext; return FALSE; }
"this" { yylval.text=yytext; return THIS; }
"return" { yylval.text=yytext; return RETURN; }
"System.out.println" { yylval.text=yytext; return SYSPRINT; }
"=" { yylval.text=yytext; return EQ; }
"&&" { yylval.text=yytext; return AND; }
"<" { yylval.text=yytext; return LESS; }
"+" { yylval.text=yytext; return ADD; }
"-" { yylval.text=yytext; return MINUS; }
"*" { yylval.text=yytext; return STAR; }

{integer} { yylval.text=yytext; return INT_LIT; }
{identifier} { yylval.text=yytext; return IDENTIFIER; }



%%

