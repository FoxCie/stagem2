%{
#include "y.tab.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum BaseType {LONG_T, INT_T, WORD_T, CHAR_T, FLOAT_T};

struct Var
{
	char *name;
	enum {TAB, PTR, BASE} gentype;
	union
	{
		struct Var *element;
		struct Var *pointed;
		enum BaseType type;
	} type;
	union
	{
		int n;
		float f;
	} value;
}

struct Reg
{
	

extern int lineno, column;
int instnumber;

%}

%union {struct Var *var; int n;}

%token REG8 REG16 REG32 REG64 LOC_REG INS_N CONST

%type <n> REG8 REG16 REG32 REG64 LOC_REG INS_N
%type <n> regs topstmt

%%

program:      topstmts
;

topstmts:
|             topstmts topstmt {printf("%d:%d: Found register of %d bits\n", lineno, column, $2);}
;

topstmt:      INS_N regs   {instnumber = $1; $$ = $2;}
;

regs:         REG8         {$$ = 8;}
|             REG16        {$$ = 16;}
|             REG32        {$$ = 32;}
|             REG64        {$$ = 64;}
|             LOC_REG      {$$ = 42;}
;

%%


int main(int argc, char *argv[])
{
	printf("Analyzing...\n\n");

	yyparse();

	printf("\n\nDone.\n");

	return EXIT_SUCCESS;
}

