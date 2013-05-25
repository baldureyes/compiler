%{
/**
 * Introduction to Compiler Design by Prof. Yi Ping You, spring 2012
 * Project 3 YACC sample
 * Last Modification : 2012/06/14 12:18
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "header.h"
#include "symtab.h"
#include "semcheck.h"

//#include "test.h"
int scopevars[128];
int yydebug;
int varnum=0;
extern int linenum;		/* declared in lex.l */
extern FILE *yyin;		/* declared by lex */
extern FILE *outFile;
extern char *yytext;		/* declared by lex */
extern char buf[256];		/* declared in lex.l */
extern char output[128];
int scope = 0;
int mode=1;
int Opt_D = 1;			/* symbol table dump option */
char fileName[256];
int read=0;
char writebuffer[128];
char branchbuffer[32];
int branchstack[32];
int branchptr=0;
int branchcount=0;
int param=0;
int typeflag=(-1);
int declareflag=0;
int whileflag=0;
int ifflag=0;
int functionflag=0;
int singleblock=0;
struct SymTable *symbolTable;	// main symbol table

__BOOLEAN paramError;			// indicate is parameter have any error?

struct PType *funcReturn;		// record function's return type, used at 'return statement' production rule

%}

%union {
	int intVal;
	float realVal;
	//__BOOLEAN booleanVal;
	char *lexeme;
	struct idNode_sem *id;
	//SEMTYPE type;
	struct ConstAttr *constVal;
	struct PType *ptype;
	struct param_sem *par;
	struct expr_sem *exprs;
	/*struct var_ref_sem *varRef; */
	struct expr_sem_node *exprNode;
};

/* tokens */
%token ARRAY BEG BOOLEAN DEF DO ELSE END FALSE FOR INTEGER IF OF PRINT READ REAL RETURN STRING THEN TO TRUE VAR WHILE
%token OP_ADD OP_SUB OP_MUL OP_DIV OP_MOD OP_ASSIGN OP_EQ OP_NE OP_GT OP_LT OP_GE OP_LE OP_AND OP_OR OP_NOT
%token MK_COMMA MK_COLON MK_SEMICOLON MK_LPAREN MK_RPAREN MK_LB MK_RB

%token <lexeme>ID
%token <intVal>INT_CONST 
%token <realVal>FLOAT_CONST
%token <realVal>SCIENTIFIC
%token <lexeme>STR_CONST

%type<id> id_list
%type<constVal> literal_const
%type<ptype> type scalar_type array_type ret_type
%type<par> param param_list opt_param_list
%type<exprs> var_ref boolean_expr boolean_term boolean_factor relop_expr expr term factor boolean_expr_list opt_boolean_expr_list
%type<intVal> dim mul_op add_op rel_op array_index loop_param

/* start symbol */
%start program
%%

program			: ID
			{
			  writebuffer[0]='\0';
			  struct PType *pType = createPType( VOID_t );
			  struct SymNode *newNode = createProgramNode( $1, scope, pType );
			  insertTab( symbolTable, newNode );
			  scopevars[scope]=0;
			  if( strcmp(fileName,$1) ) {
				fprintf( stdout, "<Error> found in Line %d: program beginning ID inconsist with file name  \n", linenum );
			  }
			}
			  MK_SEMICOLON
			{
			fputs(".class public ",outFile);
			fputs(fileName,outFile);
			fputs("\n.super java/lang/Object\n",outFile);
			fprintf(outFile,".field public static _sc Ljava/util/Scanner;\n");
			declareflag=1;
			}
			  program_body
			  END ID
			{
			  fputs("\treturn\n.end method\n",outFile);
			  if( strcmp($1, $7) ) { fprintf( stdout, "<Error> found in Line %d: %s", linenum,"Program end ID inconsist with the beginning ID  \n"); }
			  if( strcmp(fileName,$7) ) {
				 fprintf( stdout, "<Error> found in Line %d: program end ID inconsist with file name  \n", linenum );
			  }
			  // dump symbol table
				printSymTable( symbolTable, scope );
			}
			;

program_body		: opt_decl_list {declareflag=0;} opt_func_decl_list
			{
			fputs(".method public static main([Ljava/lang/String;)V\n",outFile);
			fputs(".limit stack 15\n",outFile);
			varnum+=1;
			}
			  compound_stmt
			;

opt_decl_list		: decl_list
			| /* epsilon */
			;

decl_list		: decl_list decl
			| decl
			;

decl			: VAR id_list MK_COLON scalar_type MK_SEMICOLON       /* scalar type declaration */
			{
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createVarNode( ptr->value, scope, $4 );
					if(scope==0)
						{
						fputs(".field public static ",outFile);
						fputs(ptr->value,outFile);
						fputs(" ",outFile);
						if($4->type==1)
							{
							fputs("I",outFile);
							}
						else if($4->type==2)
							{
							fputs("Z",outFile);
							}
						else if($4->type==4)
							{
							fputs("F",outFile);
							}
						fputs("\n",outFile);
						}
					else
						{
						//fputs(ptr->value,outFile);
						//fputs(" = ",outFile);
						//fprintf(outFile,"%d",varnum);
						varnum+=1;
						//fputs(", next number ",outFile);
						//fprintf(outFile,"%d",varnum);
						//fputs("\n",outFile);
						}
					insertTab( symbolTable, newNode );
				}
			  }
			  typeflag=(-1);
			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON array_type MK_SEMICOLON        /* array type declaration */
			{
			  verifyArrayType( $2, $4 );
			  // insert into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( $4->isError == __TRUE ) { }
				else if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createVarNode( ptr->value, scope, $4 );
					insertTab( symbolTable, newNode );
				}
			  }
			  
			  deleteIdList( $2 );
			}
			| VAR id_list MK_COLON literal_const MK_SEMICOLON     /* const declaration */
			{
			  struct PType *pType = createPType( $4->category );
			  // insert constants into symbol table
			  struct idNode_sem *ptr;
			  struct SymNode *newNode;
			  for( ptr=$2 ; ptr!=0 ; ptr=(ptr->next) ) {
			  	if( verifyRedeclaration( symbolTable, ptr->value, scope ) ==__FALSE ) { }
				else {
					newNode = createConstNode( ptr->value, scope, pType, $4 );
					if(scope==0)
						{
						fputs(".field public static ",outFile);
						fputs(ptr->value,outFile);
						fputs(" ",outFile);
						if($4->category==1)
							{
							fputs("I",outFile);
							}
						else if($4->category==2)
							{
							fputs("Z",outFile);
							}
						else if($4->category==4)
							{
							fputs("F",outFile);
							}
						fputs("\n",outFile);
						}
					else
						{
						//fputs(ptr->value,outFile);
						//fputs(" = ",outFile);
						//fprintf(outFile,"%d",varnum);
						varnum+=1;
						//fputs(", next number ",outFile);
						//fprintf(outFile,"%d",varnum);
						//fputs("\n",outFile);
						}
					insertTab( symbolTable, newNode );
				}
			  }
			  typeflag=(-1);
			  deleteIdList( $2 );
			}
			;

literal_const		: INT_CONST
			{
			  int tmp = $1;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			  if(declareflag==0)
				{
				fprintf(outFile,"sipush %d\n",$1);
				if(typeflag==1)
					{
					fprintf(outFile,"i2f\n");
					}
				else
					{
					typeflag=0;
					}
				}
			}
			| OP_SUB INT_CONST
			{
			  int tmp = -$2;
			  $$ = createConstAttr( INTEGER_t, &tmp );
			  if(declareflag==0)
				{
				fprintf(outFile,"sipush %d\n",-$2);
				if(typeflag==1)
					{
					fprintf(outFile,"i2f\n");
					}
				else
					{
					typeflag=0;
					}
				}
			}
			| FLOAT_CONST
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			  if(declareflag==0)
				{
				fprintf(outFile,"ldc %f\n",$1);
				if(typeflag==0)
					{
					fprintf(outFile,"i2f\n");
					}
				typeflag=1;
				}
			}
			| OP_SUB FLOAT_CONST
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			  if(declareflag==0)
				{
				fprintf(outFile,"ldc %f\n",-$2);
				if(typeflag==0)
					{
					fprintf(outFile,"i2f\n");
					}
				typeflag=1;
				}
			}
			| SCIENTIFIC 
			{
			  float tmp = $1;
			  $$ = createConstAttr( REAL_t, &tmp );
			  if(declareflag==0)
				{
				fprintf(outFile,"ldc %f\n",$1);
				if(typeflag==0)
					{
					fprintf(outFile,"i2f\n");
					}
				typeflag=1;
				}
			}
			| OP_SUB SCIENTIFIC
			{
			  float tmp = -$2;
			  $$ = createConstAttr( REAL_t, &tmp );
			  if(declareflag==0)
				{
				fprintf(outFile,"ldc %f\n",-$2);
				if(typeflag==0)
					{
					fprintf(outFile,"i2f\n");
					}
				typeflag=1;
				}
			}
			| STR_CONST
			{
			  $$ = createConstAttr( STRING_t, $1 );
			  if(declareflag==0)
			  fprintf(outFile,"ldc \"%s\"\n",$1);
			}
			| TRUE
			{
			  SEMTYPE tmp = __TRUE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
			  if(declareflag==0)
					{
					fprintf(outFile,"iconst_1\n");
					if(typeflag==1)
						{
						fprintf(outFile,"i2f\n");
						}
					else
						{
						typeflag=0;
						}
					}
			}
			| FALSE
			{
			  SEMTYPE tmp = __FALSE;
			  $$ = createConstAttr( BOOLEAN_t, &tmp );
			  if(declareflag==0)
				{
				fprintf(outFile,"iconst_0\n");
				if(typeflag==1)
					{
					fprintf(outFile,"i2f\n");
					}
				else
					{
					typeflag=0;
					}
				}
			}
			;

opt_func_decl_list	: func_decl_list
			| /* epsilon */
			;

func_decl_list		: func_decl_list func_decl
			| func_decl
			;

func_decl		: ID {writebuffer[0]='\0';param=0;} MK_LPAREN opt_param_list
			{
			  // check and insert parameters into symbol table
			  paramError = insertParamIntoSymTable( symbolTable, $4, scope+1 );
			}
			  MK_RPAREN ret_type 
			{
			  // check and insert function into symbol table
			  fprintf(outFile,".method public static %s(%s)",$1,writebuffer);
			  if($7->type==0)
			  fprintf(outFile,"V\n");
			  else if($7->type==1)
			  fprintf(outFile,"I\n");
			  else if($7->type==2)
			  fprintf(outFile,"Z\n");
			  else if($7->type==3)
			  fprintf(outFile,"S\n");
			  else if($7->type==4)
			  fprintf(outFile,"F\n");
			  writebuffer[0]='\0';
			  fprintf(outFile,".limit stack 10\n");
			  if( paramError == __TRUE ) {
			  	printf("--- param(s) with several fault!! ---\n");
			  } else {
				insertFuncIntoSymTable( symbolTable, $1, $4, $7, scope );
			  }
			  funcReturn = $7;
			}
			  MK_SEMICOLON
			  compound_stmt
			  END ID
			{
			  fprintf(outFile,"return\n");
			  fprintf(outFile,".end method\n");
			  if( strcmp($1,$12) ) {
				fprintf( stdout, "<Error> found in Line %d: the end of the functionName mismatch  \n", linenum );
			  }
			  funcReturn = 0;
			  param=0;
			}
			;

opt_param_list		: param_list { $$ = $1; }
			| /* epsilon */ { $$ = 0; }
			;

param_list		: param_list MK_SEMICOLON param
			{
			  
			  param_sem_addParam( $1, $3 );
			  $$ = $1;
			}
			| param { $$ = $1; }
			;

param			: id_list MK_COLON type 
			{
			int t=varnum;
			$$ = createParam( $1, $3 );
			struct idNode_sem *ptr;
			 for( ptr=$1 ; ptr!=0 ; ptr=(ptr->next) )
			 {
			  if($3->type==1)
			  strcat(writebuffer,"I");
			  else if($3->type==2)
			  strcat(writebuffer,"Z");
			  else if($3->type==3)
			  strcat(writebuffer,"S");
			  else if($3->type==4)
			  strcat(writebuffer,"F");
			  //fputs(ptr->value,outFile);
			  //fputs(" = ",outFile);
			  //fprintf(outFile,"%d",t);
			  t+=1;
			  param+=1;
			  //fputs(", next number ",outFile);
			  //fprintf(outFile,"%d",t);
			  //fputs("\n",outFile);
			  }
			}
			;

id_list			: id_list MK_COMMA ID
			{
			  idlist_addNode( $1, $3 );
			  $$ = $1;
			}
			| ID { $$ = createIdList($1); }
			;

ret_type		: MK_COLON scalar_type { $$ = $2; }
			| /* epsilon */ { $$ = createPType( VOID_t ); }

type			: scalar_type { $$ = $1; }
			| array_type { $$ = $1; }
			;

scalar_type		: INTEGER { $$ = createPType( INTEGER_t ); }
			| REAL { $$ = createPType( REAL_t ); }
			| BOOLEAN { $$ = createPType( BOOLEAN_t ); }
			| STRING { $$ = createPType( STRING_t ); }
			;

array_type		: ARRAY array_index TO array_index OF type
			{
				verifyArrayDim( $6, $2, $4 );
				increaseArrayDim( $6, $2, $4 );
				$$ = $6;
			}
			;

array_index		: INT_CONST { $$ = $1; }
			| OP_SUB INT_CONST { $$ = -$2; }
			;

stmt			: compound_stmt
			| simple_stmt
			| cond_stmt
			| while_stmt
			| for_stmt
			| return_stmt
			| proc_call_stmt
			;

compound_stmt		: 
			{ 
			  typeflag=(-1);
			  scope++;
			  scopevars[scope]=varnum-param;
			  param=0;
			  //fputs("entering block, next number ",outFile);
			  //fprintf(outFile,"%d",varnum);
			  //fputs("\n",outFile);
			}
			  BEG
			  opt_decl_list
			{
			fprintf(outFile,".limit locals %d\n",varnum-scopevars[scope]+2);
			fprintf(outFile,"new java/util/Scanner\ndup\ngetstatic java/lang/System/in Ljava/io/InputStream;\ninvokespecial java/util/Scanner/<init>(Ljava/io/InputStream;)V\nputstatic %s/_sc Ljava/util/Scanner;\n",fileName);
			}
			  opt_stmt_list
			  END 
			{ 
			  // print contents of current scope
			  //fputs("leaving block, symbol table entries:\n",outFile);
			  printSymTable( symbolTable, scope );
			  varnum=scopevars[scope-1];
			  deleteScope( symbolTable, scope );	// leave this scope, delete...
			  scope--;
			  typeflag=(-1);
			}
			;

opt_stmt_list		: stmt_list
			| /* epsilon */
			;

stmt_list		: stmt_list stmt
			| stmt
			;

simple_stmt		:  var_ref {mode=0;} OP_ASSIGN boolean_expr MK_SEMICOLON
			{
			  typeflag=(-1);
			  mode=1;
			  fprintf(outFile,writebuffer);
			  writebuffer[0]='\0';
			  // check if LHS exists
			  __BOOLEAN flagLHS = verifyExistence( symbolTable, $1, scope, __TRUE );
			  // id RHS is not dereferenced, check and deference
			  __BOOLEAN flagRHS = __TRUE;
			  if( $4->isDeref == __FALSE ) {
				//flagRHS = verifyExistence( symbolTable, $3, scope, __FALSE );
				flagRHS = verifyAndDerefenced( symbolTable, $4, scope, __FALSE );
			  }

			  // if both LHS and RHS are exists, verify their type
			  if( flagLHS==__TRUE && flagRHS==__TRUE )
				verifyAssignmentTypeMatch( $1, $4 );
			}
			| PRINT 
			  {
			  typeflag=(-1);
			  mode=0;
			  fprintf(outFile,"getstatic java/lang/System/out Ljava/io/PrintStream;\n");
			  }
			  boolean_expr MK_SEMICOLON
			  {
			  if($3->pType->type==3)
			  fprintf(outFile,"invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
			  else if($3->pType->type==4||typeflag==1)
			  fprintf(outFile,"invokevirtual java/io/PrintStream/print(F)V\n");
			  else if($3->pType->type==1)
			  fprintf(outFile,"invokevirtual java/io/PrintStream/print(I)V\n");
			  else if($3->pType->type==2)
			  fprintf(outFile,"invokevirtual java/io/PrintStream/print(I)V\n");
			  mode=1;
			  verifyScalarExpr( $3, "print" );
			  typeflag=(-1);
			  }
 			| READ
			  {
			  read=1;
			  fprintf(outFile,"getstatic %s/_sc Ljava/util/Scanner;\n",fileName);
			  }
			  boolean_expr MK_SEMICOLON
			  {
			  fprintf(outFile,writebuffer);
			  read=0;
			  verifyScalarExpr( $3, "read" );
			  typeflag=(-1);
			  }
			;

proc_call_stmt		: ID {mode=0;functionflag=1;} MK_LPAREN opt_boolean_expr_list MK_RPAREN MK_SEMICOLON
			{
			  struct expr_sem *ptr;
			  functionflag=0;
			  if($4!=NULL)
			  {
			  for( ptr=$4 ; ptr!=0 ; ptr=(ptr->next) )
				{
				if(ptr->pType->type==1)
					{
					fprintf(outFile,"invokestatic %s/%s(",fileName,$1);
					fprintf(outFile,"I");
					if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==0)
					fprintf(outFile,")V\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
					fprintf(outFile,")I\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
					fprintf(outFile,")Z\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==3)
					fprintf(outFile,")S\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
					fprintf(outFile,")F\n");
					if(typeflag==1)
						{
						fprintf(outFile,"i2f\n");
						}
					else
						{
						typeflag=0;
						}
					}
				else if(ptr->pType->type==2)
					{
					fprintf(outFile,"invokestatic %s/%s(",fileName,$1);
					fprintf(outFile,"Z");
					if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==0)
					fprintf(outFile,")V\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
					fprintf(outFile,")I\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
					fprintf(outFile,")Z\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==3)
					fprintf(outFile,")S\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
					fprintf(outFile,")F\n");
					if(typeflag==1)
						{
						fprintf(outFile,"b2f\n");
						}
					else
						{
						typeflag=0;
						}
					}
				else if(ptr->pType->type==3)
					{
					fprintf(outFile,"invokestatic %s/%s(",fileName,$1);
					fprintf(outFile,"S");
					if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==0)
					fprintf(outFile,")V\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
					fprintf(outFile,")I\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
					fprintf(outFile,")Z\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==3)
					fprintf(outFile,")S\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
					fprintf(outFile,")F\n");
					}
				else if(ptr->pType->type==4)
					{
					if(typeflag==0)
						{
						fprintf(outFile,"i2f\n");
						}
					fprintf(outFile,"invokestatic %s/%s(",fileName,$1);
					fprintf(outFile,"F");
					if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==0)
					fprintf(outFile,")V\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
					fprintf(outFile,")I\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
					fprintf(outFile,")Z\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==3)
					fprintf(outFile,")S\n");
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
					fprintf(outFile,")F\n");
					typeflag=1;
					}
				}
			  }
			  mode=1;
			  verifyFuncInvoke( $1, $4, symbolTable, scope );
			}
			;

cond_stmt		: IF 
			  {
			  strcpy(branchbuffer,"ifeq");
			  mode=0;
			  typeflag=(-1);
			  branchstack[branchptr]=branchcount;
			  ifflag=1;
			  singleblock=0;
			  }
			  condition 
			  {
			  ifflag=0;
			  typeflag=(-1);
			  branchcount+=3;
			  mode=1;
			  fprintf(outFile,"goto L%d\n",branchstack[branchptr]+1);
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]);
			  branchptr+=1;
			  }
			  THEN
			  opt_stmt_list
			  {
			  branchptr-=1;
			  fprintf(outFile,"goto L%d\n",branchstack[branchptr]+2);
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]+1);
			  typeflag=(-1);
			  branchptr+=1;
			  }
			  else
			  {
			  branchptr-=1;
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]+2);
			  typeflag=(-1);
			  }
			  END IF
			;
else              : ELSE opt_stmt_list {typeflag=0;}
					|
					;
condition		: boolean_expr { verifyBooleanExpr( $1, "if" ); } 
			;

while_stmt		: WHILE
			  {
			  typeflag=(-1);
			  strcpy(branchbuffer,"ifeq");
			  branchstack[branchptr]=branchcount;
			  mode=0;
			  whileflag=1;
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]+2);
			  singleblock=0;
			  }
			  condition_while
			  {
			  fprintf(outFile,"goto L%d\n",branchstack[branchptr]+1);
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]);
			  whileflag=0;
			  typeflag=(-1);
			  mode=1;
			  branchptr+=1;
			  branchcount+=3;
			  }
			  DO
			  opt_stmt_list
			  {
			  branchptr-=1;
			  typeflag=(-1);
			  fprintf(outFile,"goto L%d\n",branchstack[branchptr]+2);
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]+1);
			  }
			  END DO
			;

condition_while		: boolean_expr { verifyBooleanExpr( $1, "while" ); } 
			;

for_stmt		: FOR ID 
			{ 
			typeflag=(-1);
			  insertLoopVarIntoTable( symbolTable, $2 );
			}
			  OP_ASSIGN loop_param TO loop_param
			{
			  verifyLoopParam( $5, $7 );
			  branchstack[branchptr]=branchcount;
			  fprintf(outFile,"sipush %d\n",$5);
			  fprintf(outFile,"istore %d\n",lookupLoopVar(symbolTable,$2)->javanum);
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]+1);
			  fprintf(outFile,"iload %d\n",lookupLoopVar(symbolTable,$2)->javanum);
			  fprintf(outFile,"sipush %d\n",$7);
			  fprintf(outFile,"isub\n");
			  fprintf(outFile,"ifgt L%d\n",branchstack[branchptr]);
			  typeflag=(-1);
			  branchcount+=2;
			  branchptr+=1;
			}
			  DO
			  opt_stmt_list
			  END DO
			{
			  branchptr-=1;
			  fprintf(outFile,"iload %d\n",lookupLoopVar(symbolTable,$2)->javanum);
			  fprintf(outFile,"sipush 1\n");
			  fprintf(outFile,"iadd\n");
			  fprintf(outFile,"istore %d\n",lookupLoopVar(symbolTable,$2)->javanum);
			  fprintf(outFile,"goto L%d\n",branchstack[branchptr]+1);
			  fprintf(outFile,"L%d:\n",branchstack[branchptr]);
			  popLoopVar( symbolTable );
			  typeflag=(-1);
			}
			;

loop_param		: INT_CONST { $$ = $1; }
			;

return_stmt		: RETURN {mode=0;typeflag=(-1);} boolean_expr MK_SEMICOLON
			{
			  typeflag=(-1);
			  mode=1;
			  if($3->pType->type==4||typeflag==1)
				{
				fprintf(outFile,"freturn\n");
				}
			  else if($3->pType->type==1||$3->pType->type==2)
				{
				fprintf(outFile,"ireturn\n");
				}
			  verifyReturnStatement( $3, funcReturn );
			}
			;

opt_boolean_expr_list	: boolean_expr_list { $$ = $1; }
			| /* epsilon */ { $$ = 0; }	// null
			;

boolean_expr_list	: boolean_expr_list MK_COMMA boolean_expr
			{
			  struct expr_sem *exprPtr;
			  for( exprPtr=$1 ; (exprPtr->next)!=0 ; exprPtr=(exprPtr->next) );
			  exprPtr->next = $3;
			  $$ = $1;
			}
			| boolean_expr
			{
			typeflag=(-1);
			  $$ = $1;
			}
			;

boolean_expr		: boolean_expr OP_OR boolean_term
			{
			  verifyAndOrOp( $1, OR_t, $3);
			  $$ = $1;
			  if(mode==0&&!(ifflag==1&&functionflag==0))
					{
					fprintf(outFile,"ior\n");
					}
			}
			| boolean_term
				{
				$$ = $1;
				}
			;

boolean_term		: boolean_term OP_AND boolean_factor
			{
			  verifyAndOrOp( $1, AND_t, $3 );
			  $$ = $1;
			  if(mode==0&&!(whileflag==1&&functionflag==0))
					{
					fprintf(outFile,"iand\n");
					}
			}
			| boolean_factor 
				{
				$$ = $1;

				}
			;

boolean_factor		: OP_NOT boolean_factor 
			{
			  verifyUnaryNOT( $2 );
			  $$ = $2;
			  
			  if(mode==0)
					{
					fprintf(outFile,"ldc -1\n");
					fprintf(outFile,"ixor\n");
					}
			}
			| relop_expr
				{
				$$ = $1;
				}
			;

relop_expr		: expr rel_op expr
			{
			  verifyRelOp( $1, $2, $3 );
			  $$ = $1;
			   if($1->pType->type==4||typeflag==1)
			   fprintf(outFile,"fcmpl\n");
			   else if($1->pType->type==1||$1->pType->type==2)
			   fprintf(outFile,"isub\n");
			   if((ifflag==1||whileflag==1)&&functionflag==0)
					{
					fprintf(outFile,"%s L%d\n",branchbuffer,branchstack[branchptr]);
					}
			   typeflag=0;
			   singleblock=1;
			}
			| expr 
				{
				$$ = $1;
				typeflag=0;
				if(singleblock==0)
					{
					if((ifflag==1||whileflag==1)&&functionflag==0)
						{
						if($1->pType->type==4||typeflag==1)
							{
							fprintf(outFile,"ldc 0.0\n");
							fprintf(outFile,"fcmpl\n");
							fprintf(outFile,"%s L%d\n",branchbuffer,branchstack[branchptr]);
							}
						else if($1->pType->type==1||$1->pType->type==2)
							{
							fprintf(outFile,"ldc 0\n");
							fprintf(outFile,"isub\n");
							fprintf(outFile,"%s L%d\n",branchbuffer,branchstack[branchptr]);
							}
						}
					}
				else
					{
					singleblock=0;
					}
				}
			;

rel_op			: OP_LT { $$ = LT_t;strcpy(branchbuffer,"iflt");}
			| OP_LE { $$ = LE_t; strcpy(branchbuffer,"ifle");}
			| OP_EQ { $$ = EQ_t; strcpy(branchbuffer,"ifeq");}
			| OP_GE { $$ = GE_t; strcpy(branchbuffer,"ifge");}
			| OP_GT { $$ = GT_t; strcpy(branchbuffer,"ifgt");}
			| OP_NE { $$ = NE_t; strcpy(branchbuffer,"ifne");}
			;

expr			: expr add_op term
			{
			  verifyArithmeticOp( $1, $2, $3 );
			  $$ = $1;
			  if($2==ADD_t)
				{
				if(mode==0)
					{
					if($3->pType->type==4||typeflag==1)
					fprintf(outFile,"fadd\n");
					else if($3->pType->type==1)
					fprintf(outFile,"iadd\n");
					else if($3->pType->type==2)
					fprintf(outFile,"iadd\n");
					}
				}
			  else if($2==SUB_t)
				{
				if(mode==0)
					{
					if($3->pType->type==4||typeflag==1)
					fprintf(outFile,"fsub\n");
					else if($3->pType->type==1)
					fprintf(outFile,"isub\n");
					else if($3->pType->type==2)
					fprintf(outFile,"isub\n");
					}
				}
			}
			| term { $$ = $1; }
			;

add_op			: OP_ADD { $$ = ADD_t; }
			| OP_SUB { $$ = SUB_t; }
			;

term			: term mul_op factor
			{
			  if( $2 == MOD_t ) {
				verifyModOp( $1, $3 );
			  }
			  else {
				verifyArithmeticOp( $1, $2, $3 );
			  }
			  $$ = $1;
			 if($2==MUL_t)
				{
				if(mode==0)
					{
					if($3->pType->type==4||typeflag==1)
					fprintf(outFile,"fmul\n");
					else if($3->pType->type==1)
					fprintf(outFile,"imul\n");
					else if($3->pType->type==2)
					fprintf(outFile,"imul\n");
					}
				}
			  else if($2==DIV_t)
				{
				if(mode==0)
					{
					if($3->pType->type==4||typeflag==1)
					fprintf(outFile,"fdiv\n");
					else if($3->pType->type==1)
					fprintf(outFile,"idiv\n");
					else if($3->pType->type==2)
					fprintf(outFile,"idiv\n");
					}
				}
			  else if($2==MOD_t)
				{
				if(mode==0)
					{
					if($3->pType->type==1)
					fprintf(outFile,"irem\n");
					else if($3->pType->type==2)
					fprintf(outFile,"irem\n");
					}
				}
			}
			| factor { $$ = $1; }
			;

mul_op			: OP_MUL { $$ = MUL_t; }
			| OP_DIV { $$ = DIV_t; }
			| OP_MOD { $$ = MOD_t; }
			;

factor			: var_ref
			{
			  verifyExistence( symbolTable, $1, scope, __FALSE );
			  $$ = $1;
			  $$->beginningOp = NONE_t;
			}
			| OP_SUB var_ref
			{
			  if( verifyExistence( symbolTable, $2, scope, __FALSE ) == __TRUE )
				verifyUnaryMinus( $2 );
			  $$ = $2;
			  $$->beginningOp = SUB_t;
			  if(mode==0)
					{
					if($2->pType->type==4||typeflag==1)
						fprintf(outFile,"fneg\n");
					else if($2->pType->type==1)
						fprintf(outFile,"ineg\n");
					else if($2->pType->type==2)
						fprintf(outFile,"ineg\n");
					}
			}
			| MK_LPAREN boolean_expr MK_RPAREN 
			{
			  $2->beginningOp = NONE_t;
			  $$ = $2; 
			}
			| OP_SUB MK_LPAREN boolean_expr MK_RPAREN
			{
			  verifyUnaryMinus( $3 );
			  $$ = $3;
			  $$->beginningOp = SUB_t;
			  if(mode==0)
				{
				if($3->pType->type==4||typeflag==1)
					fprintf(outFile,"fneg\n");
				else if($3->pType->type==1)
					fprintf(outFile,"ineg\n");
				else if($3->pType->type==2)
					fprintf(outFile,"ineg\n");
				}
			}
			| ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  $$ = verifyFuncInvoke( $1, $3, symbolTable, scope );
			  $$->beginningOp = NONE_t;
			  struct expr_sem *ptr;
			  fprintf(outFile,"invokestatic %s/%s(",fileName,$1);
			  if($3!=NULL)
			  {
			  for( ptr=$3 ; ptr!=0 ; ptr=(ptr->next) )
				{
				if(ptr->pType->type==1)
				fprintf(outFile,"I");
				else if(ptr->pType->type==2)
				fprintf(outFile,"Z");
				else if(ptr->pType->type==3)
				fprintf(outFile,"S");
				else if(ptr->pType->type==4)
				fprintf(outFile,"F");
				}
			  }
			  if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==0)
			  fprintf(outFile,")V\n");
			  else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
				{
				fprintf(outFile,")I\n");
				if(typeflag==1)
					{
					fprintf(outFile,"i2f\n");
					}
				else
					{
					typeflag=0;
					}
				}
			  else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
				{
				fprintf(outFile,")Z\n");
				if(typeflag==1)
					{
					fprintf(outFile,"b2f\n");
					}
				else
					{
					typeflag=0;
					}
				}
			  else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==3)
				{
				fprintf(outFile,")S\n");
				}
			  else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
				{
				fprintf(outFile,")F\n");
				typeflag=1;
				}
			}
			| OP_SUB ID MK_LPAREN opt_boolean_expr_list MK_RPAREN
			{
			  $$ = verifyFuncInvoke( $2, $4, symbolTable, scope );
			  $$->beginningOp = SUB_t;
			  struct expr_sem *ptr;
			  fprintf(outFile,"invokestatic %s/%s(",fileName,$2);
			  if($4!=NULL)
			  {
			  for( ptr=$4 ; ptr!=0 ; ptr=(ptr->next) )
				{
				if(ptr->pType->type==1)
				fprintf(outFile,"I");
				else if(ptr->pType->type==2)
				fprintf(outFile,"Z");
				else if(ptr->pType->type==3)
				fprintf(outFile,"S");
				else if(ptr->pType->type==4)
				fprintf(outFile,"F");
				}
			  }
			  if(lookupSymbol(symbolTable,$2,scope,__FALSE)->type->type==0)
			  fprintf(outFile,")\n");
			  else if(lookupSymbol(symbolTable,$2,scope,__FALSE)->type->type==0)
				{
				fprintf(outFile,")I\n");
				if(typeflag==1)
					{
					fprintf(outFile,"i2f\n");
					}
				else
					{
					typeflag=0;
					}
				}
			  else if(lookupSymbol(symbolTable,$2,scope,__FALSE)->type->type==0)
				{
				fprintf(outFile,")Z\n");
				if(typeflag==1)
					{
					fprintf(outFile,"b2f\n");
					}
				else
					{
					typeflag=0;
					}
				}
			  else if(lookupSymbol(symbolTable,$2,scope,__FALSE)->type->type==0)
				{
				fprintf(outFile,")S\n");
				}
			  else if(lookupSymbol(symbolTable,$2,scope,__FALSE)->type->type==0)
				{
				fprintf(outFile,")F\n");
				typeflag=1;
				}
			  if(mode==0)
				{
				if($4->pType->type==4||typeflag==1)
					fprintf(outFile,"fneg\n");
				else if($4->pType->type==1)
					fprintf(outFile,"ineg\n");
				else if($4->pType->type==2)
					fprintf(outFile,"ineg\n");
				}
			}
			| literal_const
			{
			  $$ = (struct expr_sem *)malloc(sizeof(struct expr_sem));
			  $$->isDeref = __TRUE;
			  $$->varRef = 0;
			  
			  if( ($1->category == INTEGER_t) || ($1->category == BOOLEAN_t) || ($1->category == REAL_t))
			  	$$->pType = createPTypeWithValue($1->category, &($1->value));
			  else
			  	$$->pType = createPType( $1->category );
			  $$->next = 0;
			  if( $1->hasMinus == __TRUE ) {
			  	$$->beginningOp = SUB_t;
			  }
			  else {
				$$->beginningOp = NONE_t;
			  }
			}
			;

var_ref			: ID
			{
			  $$ = createExprSem( $1 );
			  if(mode==0)
				{
				if(lookupSymbol(symbolTable,$1,scope,__FALSE)==NULL)
					{
					fprintf(outFile,"iload %d\n",lookupLoopVar(symbolTable,$1)->javanum);
					}
				else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->category==10)
					{
					if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
						{
						fprintf(outFile,"ldc %d\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->attribute->constVal->value.integerVal);
						if(typeflag==1)
							{
							fprintf(outFile,"i2f\n");
							}
						else
							{
							typeflag=0;
							}
						}
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
						{
						if(lookupSymbol(symbolTable,$1,scope,__FALSE)->attribute->constVal->value.booleanVal==1)
						fprintf(outFile,"iconst_1\n");
						else
						fprintf(outFile,"iconst_0\n");
						if(typeflag==1)
							{
							fprintf(outFile,"i2f\n");
							}
						else
							{
							typeflag=0;
							}
						}
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==3)
						fprintf(outFile,"ldc \"%s\"\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->attribute->constVal->value.stringVal);
					else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
						{
						fprintf(outFile,"ldc %f\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->attribute->constVal->value.realVal);
						if(typeflag==0)
							{
							fprintf(outFile,"i2f\n");
							}
						typeflag=1;
						}
					}
				else
					{
			  		if(lookupSymbol(symbolTable,$1,scope,__FALSE)->scope==0)
			  			{
			  			if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
							{
			  				fprintf(outFile,"getstatic %s/%s I\n",fileName,$1);
							if(typeflag==1)
								{
								fprintf(outFile,"i2f\n");
								}
							else
								{
								typeflag=0;
								}
							}
			  			else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
							{
			  				fprintf(outFile,"getstatic %s/%s I\n",fileName,$1);
							if(typeflag==1)
								{
								fprintf(outFile,"i2f\n");
								}
							else
								{
								typeflag=0;
								}
							}
			  			else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
							{
							if(typeflag==0)
								{
								fprintf(outFile,"i2f\n");
								}
			  				fprintf(outFile,"getstatic %s/%s F\n",fileName,$1);
							typeflag=1;
							}
					  	}
					else
				  		{
						if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
							{
							fprintf(outFile,"iload %d\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->javanum);
							if(typeflag==1)
								{
								fprintf(outFile,"i2f\n");
								}
							else
								{
								typeflag=0;
								}
							}
						else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
							{
							fprintf(outFile,"iload %d\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->javanum);
							if(typeflag==1)
								{
								fprintf(outFile,"i2f\n");
								}
							else
								{
								typeflag=0;
								}
							}
						else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
							{
							if(typeflag==0)
								{
								fprintf(outFile,"i2f\n");
								}
							fprintf(outFile,"fload %d\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->javanum);
							typeflag=1;
							}
						}
					}
				}
				else
					{
					writebuffer[0]='\0';
					 if(lookupSymbol(symbolTable,$1,scope,__FALSE)->scope!=0)
						{
						if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
							{
							if(read==1)
							fprintf(outFile,"invokevirtual java/util/Scanner/nextInt()I\n");
							sprintf(writebuffer,"istore %d\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->javanum);
							}
						else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
							{
							if(read==1)
							fprintf(outFile,"invokevirtual java/util/Scanner/nextBoolean()Z\n");
							sprintf(writebuffer,"istore %d\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->javanum);
							}
						else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
							{
							if(typeflag==0)
								{
								fprintf(outFile,"i2f\n");
								}
							if(read==1)
							fprintf(outFile,"invokevirtual java/util/Scanner/nextFloat()F\n");
							sprintf(writebuffer,"fstore %d\n",lookupSymbol(symbolTable,$1,scope,__FALSE)->javanum);
							typeflag=1;
							}
						}
					else
						{
						if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==1)
							{
							if(read==1)
							fprintf(outFile,"invokevirtual java/util/Scanner/nextInt()I\n");
							sprintf(writebuffer,"putstatic %s/%s I\n",fileName,$1);
							}
						else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==2)
							{
							if(read==1)
							fprintf(outFile,"invokevirtual java/util/Scanner/nextBoolean()Z\n");
							sprintf(writebuffer,"putstatic %s/%s I\n",fileName,$1);
							}
						else if(lookupSymbol(symbolTable,$1,scope,__FALSE)->type->type==4)
							{
							if(typeflag==0)
								{
								fprintf(outFile,"i2f\n");
								}
							if(read==1)
							fprintf(outFile,"invokevirtual java/util/Scanner/nextFloat()F\n");
							sprintf(writebuffer,"putstatic %s/%s F\n",fileName,$1);
							typeflag=1;
							}
						}
					}
			}
			| var_ref dim
			{
			  increaseDim( $1, $2 );
			  $$ = $1;
			}
			;

dim			: MK_LB boolean_expr MK_RB
			{
			  $$ = verifyArrayIndex( $2 );
			}
			;

%%

int yyerror( char *msg )
{
	fprintf( stderr, "\n|--------------------------------------------------------------------------\n" );
	fprintf( stderr, "| Error found in Line #%d: %s\n", linenum, buf );
	fprintf( stderr, "|\n" );
	fprintf( stderr, "| Unmatched token: %s\n", yytext );
	fprintf( stderr, "|--------------------------------------------------------------------------\n" );
	exit(-1);
}

