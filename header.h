typedef enum { VOID_t, INTEGER_t, BOOLEAN_t, PROGRAM_t, FUNCTION_t,VARIABLE_t, PARAMETER_t, CONSTANT_t,ID_LIST, LOOPVAR_t} SEMTYPE ;
typedef enum { False, True } Boolean;
typedef enum { ADD_t, SUB_t, MUL_t, LT_t, EQ_t, AND_t } OPERATOR;

// hash depth limit
#define HASHBUNCH 23

// parameter type
struct PType {
	Boolean isError;
	Boolean hasValue;
	SEMTYPE type;
	union {
		int integerVal;
		Boolean booleanVal;
	} value;
};

// parameter list
struct PTypeList {
	struct PType *value;
	struct PTypeList* next;
};

// parameter lists for function
struct FuncAttr {
	int paramNum;
	struct PTypeList *params;
};

// const attribute
struct ConstAttr {
	SEMTYPE category;
	union {
		int integerVal;
		Boolean booleanVal;
	} value;
   Boolean hasMinus;
};

// symbol table's id node
struct idNode_sem {
	char *value;
	struct idNode_sem *next;
};

// symbol table's parameter node
struct param_sem {
	struct idNode_sem *idlist;
	struct PType *pType;
	struct param_sem *next;
};

// symbol table's expression node
struct expr_sem {
	OPERATOR beginningOp;
	struct PType *pType;
	struct expr_sem *next;
};

/* what is this?
struct typeNode {
	SEMTYPE value;			
   struct typeNode *next;
};
*/

// symbol table attribute
union SymAttr {
	struct ConstAttr *constVal;
	struct FuncAttr *formalParam;
};

// structure for symbol table
struct SymNode {
	char *name;
	int scope;
	SEMTYPE category;		
	struct PType *type;
	union SymAttr *attribute;
	
	struct SymNode *next;
	struct SymNode *prev;
};

// symbol table
struct SymTable {
	struct SymNode *entry[HASHBUNCH];

	int loopVarDepth;
	struct SymNode *loopVar;
};

