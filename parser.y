%{
   // C declaration
   #include <stdio.h>
   #include <stdlib.h>
   extern int linenum;
   extern FILE *yyin;
   extern char *yytext;
%}

%left CLASS EXTENDS PUBLIC STATIC VOID MAIN LENGTH
%left LLBR RLBR LMBR RMBR LSBR RSBR COMMA SEMI PERIOD
%left STRING INT BOOLEAN INT_LIT NEW EXCLA IDENTIFIER
%left IF ELSE WHILE TRUE FALSE THIS RETURN SYSPRINT
%left EQ AND LESS ADD MINUS STAR

%union {
   int ivalue;
   char* text;
   double dbvalue;
}

%%

Goal: MainClass ClassDecs
    ;

MainClass: CLASS IDENTIFIER LLBR PUBLIC STATIC VOID MAIN LSBR STRING LMBR RMBR IDENTIFIER RSBR LLBR Statement RLBR RLBR
         ;

ClassDecs: ClassDec ClassDecs
         | ClassDec
         |
         ;

ClassDec: CLASS IDENTIFIER ExtendId LLBR VarDecs MethodDecs RLBR
        ;

ExtendId: EXTENDS IDENTIFIER
        |
        ;

VarDecs: VarDecs VarDec
       |
       ;

VarDec: Type IDENTIFIER SEMI
      ;

TypeIds: Type IDENTIFIER TypeIds0
       |
       ;

TypeIds0: TypeIds1 TypeIds1
        |
        ;

TypeIds1: COMMA Type IDENTIFIER
        |
        ;

Statements: Statement Statements
          |
          ;

MethodDecs: MethodDec MethodDecs
          |
          ;

MethodDec: PUBLIC Type IDENTIFIER LSBR TypeIds RSBR LLBR VarDecs Statements RETURN Expression SEMI RLBR
         ;

Type: INT LMBR RMBR
    | BOOLEAN
    | INT
    | IDENTIFIER
    ;

IDENTIFIERX: LMBR Expression RMBR EQ Expression SEMI
           | EQ Expression SEMI
           ;

Statement: LLBR Statements RLBR
         | IF LSBR Expression RSBR Statement ELSE Statement
         | WHILE LSBR Expression RSBR Statement
         | SYSPRINT LSBR Expression RSBR SEMI
         | IDENTIFIER IDENTIFIERX
         ;

Operator: AND
        | LESS
        | ADD
        | MINUS
        | STAR
        ;

Expressions: Expression Expression0
           |
           ;

Expression0: Expression1 Expression0
           |
           ;

Expression1: COMMA Expression
           ;

Expression: Expression Operator Expression
          | Expression LMBR Expression RMBR
          | Expression PERIOD LENGTH
          | Expression PERIOD IDENTIFIER LSBR Expressions RSBR
          | INT_LIT
          | TRUE
          | FALSE
          | IDENTIFIER
          | THIS
          | NEW INT LMBR Expression RMBR
          | NEW IDENTIFIER LSBR RSBR
          | EXCLA Expression
          | LSBR Expression RSBR
          ;


%%

int yyerror( char *msg ){
   fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
   fprintf( stderr, "| Error found in Line #%d\n", linenum);
   fprintf( stderr, "|\n" );
    fprintf( stderr, "| Unmatched token: %s\n", yytext );
   fprintf( stderr, "|--------------------------------------------------------------------------\n" );
   exit(-1);
}

int  main( int argc, char **argv ){
   
   if( argc != 2 ) {
      fprintf(  stdout,  "Usage:  ./parser  [filename]\n"  );
      exit(0);
   }
   FILE *fp = fopen( argv[1], "r" );

   if( fp == NULL )  {
      fprintf( stdout, "Open  file  error\n" );
      exit(-1);
   }

   yyin = fp;
   yyparse();

   fprintf( stdout, "\n" );
   fprintf( stdout, "|--------------------------------|\n" );
   fprintf( stdout, "|  There is no syntactic error!  |\n" );
   fprintf( stdout, "|--------------------------------|\n" );
   exit(0);
}

