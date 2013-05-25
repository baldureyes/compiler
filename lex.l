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
\n          { linenum++; }

"class"     { return CLASS; }
"extends"   { return EXTENDS; }
"public"    { return PUBLIC; }
"static"    { return STATIC; }
"void"      { return VOID; }
"main"      { return MAIN; }
"length"    { return LENGTH; }
"{"         { return LLBR; }
"}"         { return RLBR; }
"["         { return LMBR; }
"]"         { return RMBR; }
"("         { return LSBR; }
")"         { return RSBR; }
","         { return COMMA; }
";"         { return SEMI; }
"."         { return PERIOD; }
"String"    { return STRING; }
"int"       { return INT; }
"boolean"   { return BOOLEAN; }
"new"       { return NEW; }
"!"         { return EXCLA; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"true"      { return TRUE; }
"false"     { return FALSE; }
"this"      { return THIS; }
"return"    { return RETURN; }
"="         { return EQ; }
"&&"        { return AND; }
"<"         { return LESS; }
"+"         { return ADD; }
"-"         { return MINUS; }
"*"         { return STAR; }
{integer}   { yylval.intVal = atoi(yytext); return INT_LIT; }
{identifier} { yylval.text = yytext; return IDENTIFIER; }
"System.out.println" { return SYSPRINT; }



%%

