%{
   // C declaration
   #include <stdio.h>
   #include <stdlib.h>
   #include <string.h>
   #include "header.h"
   extern int linenum;
   extern FILE *yyin;
   extern char *yytext;
   FILE *mipsFile;
   int iniExp;  
   int idLoc;
   struct expAttr *retExpAttr;
   struct ptypeAttr *retPtype;
%}


%union {
   int intVal;
   struct expAttr *expattr;
   char* text;
   struct ptypeAttr *ptypeattr;
}

%left CLASS EXTENDS PUBLIC STATIC VOID MAIN LENGTH
%left LLBR RLBR LMBR RMBR LSBR RSBR COMMA SEMI PERIOD
%left STRING INT BOOLEAN NEW EXCLA 
%left IF ELSE WHILE TRUE FALSE THIS RETURN SYSPRINT
%left EQ AND LESS ADD MINUS STAR

%token<intVal>    INT_LIT
%token<text>      IDENTIFIER
%type<expattr>    Expression IdentifierAssign
%type<ptypeattr>  Type
%start Goal
%%

Goal: MainClass ClassDecs
    ;

MainClass: 
         CLASS {
            mipsFile = fopen("project2.asm","w");
            fprintf(mipsFile,".data\n");
            fprintf(mipsFile,"   .text\n");
            fprintf(mipsFile,"   .global main\n");
            iniExp = 0;
         }
         IDENTIFIER LLBR PUBLIC STATIC VOID 
         MAIN {
            fprintf(mipsFile,"main:\n");
         } 
         LSBR STRING LMBR RMBR IDENTIFIER RSBR LLBR Statement RLBR 
         RLBR {
            fprintf(mipsFile,"   .data\n");
            fprintf(mipsFile,"   .text\n");
         }
         ;

ClassDecs: ClassDec ClassDecs
         | ClassDec
         |
         ;

ClassDec: 
        CLASS {
           //fprintf(mipsFile,"CS_test:\n");
        }
        IDENTIFIER ExtendId LLBR VarDecs MethodDecs RLBR
        ;

ExtendId: EXTENDS IDENTIFIER
        |
        ;

VarDecs: VarDecs VarDec
       |
       ;

VarDec: Type IDENTIFIER {
      /*
           myTable[tableDep].expType = $1->type;
           strcpy(myTable[tableDep].name, $2);
           myTable[tableDep].contain = tableDep*4;
           fprintf(mipsFile,"   # init param dec\n");
           fprintf(mipsFile,"   li $t0,0\n");
           fprintf(mipsFile,"   sw $t0,%d($sp)\n",tableDep*4);
           tableDep++;
           */
        }
        SEMI
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
    | INT { 
    /*
         retPtype->type = const_t;
         $$ = retPtype;
         */
      }
    | IDENTIFIER {
    /*
         retPtype->type = param_t;
         $$ = retPtype;
         */
      }
    ;

IdentifierAssign: LMBR Expression RMBR EQ Expression SEMI
                | EQ Expression SEMI {
                /*
                    $$=$2;
                    iniExp = 0;
                    */
                  }
                ;

Statement: LLBR Statements RLBR
         | IF LSBR Expression RSBR Statement ELSE Statement
         | WHILE LSBR Expression RSBR Statement
         | SYSPRINT LSBR Expression RSBR SEMI {
         /*
             // get expression
             if($3->expType == const_t ){
               fprintf(mipsFile,"   li $a0,%d\n",$3->contain);
             }else{
               fprintf(mipsFile,"   lw $a0,%d($sp)\n",$3->contain*4);
             }
             // print
             fprintf(mipsFile,"   li $v0,1\n");
             fprintf(mipsFile,"   syscall\n");
             */
           }

         | IDENTIFIER IdentifierAssign {
         /*
              idLoc = searchParam ($1);
              if(idLoc == -1) {
                 printf("exp use undefined id: %s\n", $1);
              }else {
                 if($2->expType == const_t){
                    fprintf(mipsFile,"   li $t0,%d\n",$2->contain);
                    fprintf(mipsFile,"   sw $t0,%d($sp)\n",$2->contain);
                 }else{
                    idLoc = searchParam ($2->name);
                    if(idLoc == -1) printf("exp use undefined id: %s\n", $2->name);
                    fprintf(mipsFile,"   lw $t0,%d($sp)\n",myTable[idLoc].contain);
                    fprintf(mipsFile,"   sw $t0,%d($sp)\n",$2->contain);
                 }
              }
              */
           }
         ;

Operator: ADD Expression {
            /*
            if(isInt==0){
               fprintf(mipsFile, "   lw $t2,0($sp)\n");
               fprintf(mipsFile, "   add $t1,$t2\n");
            }else{
               fprintf(mipsFile, "   addi $t1,%d\n",$2);
            }
            */
          }
        | LESS Expression
        | AND Expression
        | MINUS Expression{
            /*
            if(isInt==0){
               fprintf(mipsFile, "   lw $t2,0($sp)\n");
               fprintf(mipsFile, "   sub $t1,$t2\n");
            }else{
               fprintf(mipsFile, "   li $t2,%d\n",$2);
               fprintf(mipsFile, "   sub $t1,$t2\n");
            }
            */
          }
        | STAR Expression
        ;

Expressions: Expression Expression0
           |
           ;

Expression0: Expression1 Expression0
           |
           ;

Expression1: COMMA Expression
           ;

Expression: Expression {
          /*
               if(iniExp==0){
                  if($1->expType == param_t){
                     fprintf(mipsFile, "   lw $t1,%d($sp)\n",$1->contain);
                  }else{
                     fprintf(mipsFile, "   li $t1,%d\n",$1->contain);
                  }
                  iniExp=1;
               }
               */
            } 
            Operator 
          | Expression LMBR Expression RMBR
          | Expression PERIOD LENGTH
          | Expression PERIOD IDENTIFIER LSBR Expressions RSBR
          | INT_LIT {
          /*
               retExpAttr->expType = const_t;
               retExpAttr->contain = $1;
               $$ = retExpAttr;
               */
            }
          | TRUE
          | FALSE
          | IDENTIFIER {
          /*
               idLoc = searchParam ($1);
               if(idLoc != -1) {
                  strcpy(retExpAttr->name,myTable[idLoc].name);
                  retExpAttr->expType = param_t;
                  retExpAttr->contain = myTable[idLoc].contain;
                  $$ = retExpAttr;
               }else {
                  printf("exp use undefined id: %s\n", $1);
               }
               */
            }
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

