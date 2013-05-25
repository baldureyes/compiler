typedef enum { param_t, const_t } ptype;
int tableDep=0;

struct expAttr {
   ptype expType;
   char name[10];
   int contain; // stack pos or const value
};

struct expAttr myTable[10];

struct ptypeAttr {
   ptype type;
};

// return param table location
int searchParam ( char* name ) {
   int i = tableDep;
   for (i = 0; i < tableDep; i++) {
      if (!strcmp(name,myTable[i].name)) {
         return i;
      }
   }
   return  -1;
}
