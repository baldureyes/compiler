%{
   // C declaration
   // register: $t0: math result, $t1: condi left result, $t2: cal tmp, $t3: condi right result
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
   int condiFlag;
   int ifNum;
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
            fprintf(mipsFile,"   .globl main\n");
            ifNum = 0;
            iniExp = 0;
            condiFlag = 0;
            retExpAttr = (struct expAttr*) malloc(sizeof(struct expAttr));
            retPtype = (struct ptypeAttr*) malloc(sizeof(struct ptypeAttr));
         }
         IDENTIFIER LLBR PUBLIC STATIC VOID 
         MAIN {
            fprintf(mipsFile,"main:\n");
         } 
         LSBR STRING LMBR RMBR IDENTIFIER RSBR LLBR Statement RLBR 
         RLBR {
            fprintf(mipsFile,"   # exit program\n");
            fprintf(mipsFile,"   jr $ra\n\n");
            fprintf(mipsFile,"   .data\n");
            fprintf(mipsFile,"   .text\n");
         }
         ;

ClassDecs: ClassDec ClassDecs
         | ClassDec
         |
         ;

ClassDec: 
        CLASS IDENTIFIER {
           fprintf(mipsFile,"%s:\n",$2);
        } ExtendId LLBR VarDecs MethodDecs RLBR
        ;

ExtendId: EXTENDS IDENTIFIER
        |
        ;

VarDecs: VarDecs VarDec
       |
       ;

VarDec: Type IDENTIFIER {
           myTable[tableDep].expType = $1->type;
           strcpy(myTable[tableDep].name, $2);
           myTable[tableDep].contain = tableDep*4;
           fprintf(mipsFile,"   # dec param \"%s\" at stack loc %d \n",$2,tableDep*4);
           fprintf(mipsFile,"   li $t0,0\n");
           fprintf(mipsFile,"   sw $t0,%d($sp)\n",tableDep*4);
           tableDep++;
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
         retPtype->type = const_t;
         $$ = retPtype;
      }
    | IDENTIFIER {
         retPtype->type = param_t;
         $$ = retPtype;
      }
    ;

IdentifierAssign: LMBR Expression RMBR EQ Expression SEMI
                | EQ Expression SEMI {
                    $$=$2;
                    iniExp = 0;
                  }
                ;

Statement: LLBR Statements RLBR
         | IF {
              condiFlag = 1;
              ifNum++;
           }
           LSBR Expression {
              condiFlag = 0;
              iniExp = 0;
              fprintf(mipsFile,"   slt $t1,$t0,$t3\n");
              fprintf(mipsFile,"   li $t2,0\n");
              fprintf(mipsFile,"   beq $t1,$t2,Else%d\n",ifNum);
              fprintf(mipsFile,"   # start if_%d statement\n",ifNum);
           }
           RSBR Statement ELSE {
              iniExp = 0;
              fprintf(mipsFile,"   j Endif%d\n",ifNum);
              fprintf(mipsFile,"Else%d:\n",ifNum);
           }
           Statement {
              fprintf(mipsFile,"Endif%d:\n",ifNum);
           }
         | WHILE LSBR Expression RSBR Statement
         | SYSPRINT LSBR Expression RSBR SEMI {
             int tmp = $3->contain;
             // get expression
             if($3->expType == const_t ){
               fprintf(mipsFile,"   # print\n");
               fprintf(mipsFile,"   move $a0,$t0\n");
             }else{
               idLoc = searchParam($3->name);
               fprintf(mipsFile,"   # print param \"%s\"\n",myTable[idLoc].name);
               fprintf(mipsFile,"   lw $a0,%d($sp)\n",myTable[idLoc].contain);
             }
             // print
             fprintf(mipsFile,"   li $v0,1\n");
             fprintf(mipsFile,"   syscall\n");
           }

         | IDENTIFIER IdentifierAssign {
              idLoc = searchParam($1);
              if(idLoc == -1) {
                 printf("undefined param: %s\n", $1);
              }else {
                 if($2->expType == const_t){
                    fprintf(mipsFile,"   # assign %d to \"%s\"\n",$2->contain,$1);
                    fprintf(mipsFile,"   li $t0,%d\n",$2->contain);
                    fprintf(mipsFile,"   sw $t0,%d($sp)\n",myTable[idLoc].contain);
                 }else{
                    idLoc = searchParam ($2->name);
                    if(idLoc == -1) printf("exp use undefined id: %s\n", $2->name);
                    fprintf(mipsFile,"   # assign %s to \"%s\"\n",myTable[idLoc].name,$1);
                    fprintf(mipsFile,"   lw $t0,%d($sp)\n",myTable[idLoc].contain);
                    idLoc = searchParam($1);
                    fprintf(mipsFile,"   sw $t0,%d($sp)\n",myTable[idLoc].contain);
                 }
              }
           }
         ;

Operator: ADD Expression {
            if( $2->expType == param_t){
               idLoc = searchParam($2->name);
               if(condiFlag == 1){
                  fprintf(mipsFile, "   lw $t2,%d($sp)\n",myTable[idLoc].contain);
                  fprintf(mipsFile, "   add $t3,$t2\n");
               }else{
                  fprintf(mipsFile, "   lw $t2,%d($sp)\n",myTable[idLoc].contain);
                  fprintf(mipsFile, "   add $t0,$t2\n");
               }
            }else{
               if(condiFlag == 1){
                  fprintf(mipsFile, "   addi $t3,%d\n",$2->contain);
               }else{
                  fprintf(mipsFile, "   addi $t0,%d\n",$2->contain);
               }
            }
          }
        | LESS Expression {
            fprintf(mipsFile, "   # less than\n");
            if( $2->expType == param_t){
               idLoc = searchParam($2->name);
               fprintf(mipsFile, "   lw $t3,%d($sp)\n",myTable[idLoc].contain);
            }else{
               fprintf(mipsFile, "   li $t3,%d\n",$2->contain);
            }
          }
        | AND Expression
        | MINUS Expression{
            if( $2->expType == param_t){
               idLoc = searchParam($2->name);
               if(condiFlag == 1){
                  fprintf(mipsFile, "   lw $t2,%d($sp)\n",myTable[idLoc].contain);
                  fprintf(mipsFile, "   sub $t3,$t3,$t2\n");
               }else{
                  fprintf(mipsFile, "   lw $t2,%d($sp)\n",myTable[idLoc].contain);
                  fprintf(mipsFile, "   sub $t0,$t0,$t2\n");
               }
            }else{
               if(condiFlag == 1){
                  fprintf(mipsFile, "   li $t2,%d\n",$2->contain);
                  fprintf(mipsFile, "   sub $t3,$t3,$t2\n");
               }else{
                  fprintf(mipsFile, "   li $t2,%d\n",$2->contain);
                  fprintf(mipsFile, "   sub $t0,$t0,$t2\n");
               }
            }
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
               if(iniExp==0){
                  if($1->expType == param_t){
                     if(condiFlag == 1){
                        fprintf(mipsFile, "   lw $t3,%d($sp)\n",$1->contain);
                     }else{
                        fprintf(mipsFile, "   lw $t0,%d($sp)\n",$1->contain);
                     }
                  }else{
                     fprintf(mipsFile, "   li $t0,%d\n",$1->contain);
                  }
                  iniExp=1;
               }
            } 
            Operator 
          | Expression LMBR Expression RMBR
          | Expression PERIOD LENGTH
          | Expression PERIOD IDENTIFIER LSBR Expressions RSBR
          | INT_LIT {
               if(iniExp==0){
                  fprintf(mipsFile, "   li $t0,%d\n",$1);
                  iniExp=1;
               }
               retExpAttr->expType = const_t;
               retExpAttr->contain = $1;
               $$ = retExpAttr;
            }
          | TRUE {
               if(iniExp==0){
                  fprintf(mipsFile, "   li $t0,%d\n",1);
                  if(condiFlag==1){
                     fprintf(mipsFile, "   li $t3,%d\n",1);
                     fprintf(mipsFile, "   li $t0,%d\n",0);
                  }
                  iniExp=1;
               }
               retExpAttr->expType = const_t;
               retExpAttr->contain = 1;
               $$ = retExpAttr;
            }
          | FALSE {
               if(iniExp==0){
                  fprintf(mipsFile, "   li $t0,%d\n",0);
                  if(condiFlag==1){
                     fprintf(mipsFile, "   li $t3,%d\n",0);
                     fprintf(mipsFile, "   li $t0,%d\n",1);
                  }
                  iniExp=1;
               }
               retExpAttr->expType = const_t;
               retExpAttr->contain = 0;
               $$ = retExpAttr;
            }
          | IDENTIFIER {
               idLoc = searchParam ($1);
               if(idLoc != -1) {
                  strcpy(retExpAttr->name,myTable[idLoc].name);
                  retExpAttr->expType = param_t;
                  retExpAttr->contain = myTable[idLoc].contain;
                  $$ = retExpAttr;
               }else {
                  printf("undefined id: %s\n", $1);
               }
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

