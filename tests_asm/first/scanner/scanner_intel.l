%{
#include "y.tab.h"

#include <stdio.h>
#include <string.h>

int column = 1, lineno = 1;

/* Function that counts the current column */
void count()
{
	int i;
	for (i = 0; yytext[i] != '\0'; i++)
	{
		if (yytext[i] == '\n')
			column = 1;
		else if (yytext[i] == '\t')
			column += 8 - (column % 8);
		else
			column++;
	}
}

void yyerror(char *s)
{
	fprintf(stderr, "%s line %d col %d\n", s, lineno, column);
}
%}

LOC_REG       ([re]+(bp|sp))
REG8          ([abcd][hl]|r([89]|1[0-5])b)
REG16         ([abcd]x|[cdefgs]s|flags|ip|[sd]i|r([89]|1[0-5])w)
REG32         (e([abcd]x|[sd]i|ip)|r([89]|1[0-5])d|eflags)
REG64         (r([abcd]x|[sd]i|ip|[89]|1[0-5]|flags))
INS_N         ([0-9]+:)
CONST         (0x[0-9]+)
%%
{LOC_REG}	  {count(); return LOC_REG;}
{REG8}        {count(); return REG8;}
{REG16}       {count(); return REG16;}
{REG32}       {count(); return REG32;}
{REG64}       {count(); return REG64;}
{INS_N}       {count(); return INS_N;}
{CONST}       {count(); return CONST;}
"{"           {count(); return '{';}
"}"           {count(); return '}';}
","           {count(); return ',';}
"\n"          {count(); lineno++;}
[ \t\v\f]     {count();}
.             ;
%%

