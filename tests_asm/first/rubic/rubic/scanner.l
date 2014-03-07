%{
#include <stdio.h>
#include "y.tab.h"
#include <string.h>

int column=0; int lineno=0;
extern char *className;
int defFun = 0;
extern int nbPassages;
const char *mainInput = "input.tmp";
const char *mainFun = "main.fun";
FILE *mainInputFile = NULL;
FILE *mainFile = NULL;
YY_BUFFER_STATE buf;
YY_BUFFER_STATE mainBuf;

/* Function that counts the current column */
void count() {
  int i;
  for (i = 0; yytext[i] != '\0'; i++) {
    if (yytext[i] == '\n')
      column = 0;
    else if (yytext[i] == '\t')
      column += 8 - (column % 8);
    else
      column++;
  }
}
/* Function called in case of error during parsing */
void yyerror(char *s) {
  fprintf(stderr, "%s line %d col %d\n", s, lineno, column);
}

void reinitialiserEntree()
{
	if (mainFile == NULL)
		mainFile = fopen(mainFun, "r");

	if (mainFile == NULL)
	{
		fprintf(stderr, "ERREUR : impossible de lire %s\n", mainFun);
		exit(EXIT_FAILURE);
	}

	fseek(mainFile, 0, SEEK_SET);

	while (YY_CURRENT_BUFFER)
		yypop_buffer_state();

	mainBuf = yy_create_buffer(mainFile, YY_BUF_SIZE);
	yypush_buffer_state(mainBuf);
}

void initCopie();
void copierInput();
void pushFile(FILE *);
void popFile();
%}
F ([0-9]+\.[0-9]*)
I ([0-9]+)
S (\"[^\n\"]*\")
ID ([$@]?[a-zA-Z_][a-zA-Z_0-9]*)
%%
{F}      { count(); yylval.f = atof(yytext); return(FLOAT); }
{I}      { count(); yylval.n = atoi(yytext); return(INT); }
{S}      { 
			int size = 0, i = 1, j = 0;
			char *s;
			char c;

			while (yytext[i++] != '"')
				size++;

			s = malloc(size + 3);
				
			i = 1;
			while (yytext[i] != '"')
			{
				s[j++] = yytext[i++];
			}
			s[j] = '\0';
			strcat(s, "\\00");
			count();
			yylval.id = s; return(STRING); 
		 }
"for"    { count(); return(FOR); }
"while"  { count(); return(WHILE);}
"if"     { count(); return(IF); }
"then"   { return(THEN); }
"else"   { count(); return(ELSE); }
"return" { count(); return(RETURN); }
"class"  { count(); return(CLASS); }
"def"    { count(); if (nbPassages == 0) defFun = 1; return(DEF); }
"in"     { count(); return(IN); }
"end"    { count(); return(END); }
"do"	 { count(); return DO;}
"PRINT"	 { count(); return PRINT; }
".."	 { count(); return(TO); }
"<="	 { count(); return(LEQ); }
">="     { count(); return(GEQ); }
"=="	 { count(); return(EQ); }
"!="	 { count(); return(NEQ); }
"&&"     { count(); return(AND); }
"||"     { count(); return(OR); }
";"	 { count(); return(';'); }
","	 { count(); return(','); }
"."	 { count(); return('.'); }
"="      { count(); return('='); }
"("	 { count(); return('('); }
")"	 { count(); return(')'); }
"-"	 { count(); return('-'); }
"+"	 { count(); return('+'); }
"*"	 { count(); return('*'); }
"/"	 { count(); return('/'); }
"<"	 { count(); return('<'); }
">"	 { count(); return('>'); }
{ID}     { 
			count(); 
			yylval.id = strdup(yytext); 
			if (defFun)
			{
				char *filename;
				char token[5] = {'\0'};
				FILE *fichier;
				char c;
				int i, j = 0, nbEnds = 1;

				if (className != NULL)
					filename = malloc(strlen(className) + yyleng + 5);
				else
					filename = malloc(yyleng + 6);
				filename[0] = '\0';
				if (className != NULL)
				{
					strcat(filename, className);
					strcat(filename, "$");
				}
				strcat(filename, yytext);
				strcat(filename, ".fun");
				
				fichier = fopen(filename, "w");
				if (fichier == NULL)
				{
					fprintf(stderr, "ERREUR : impossible de creer un fichier.\n");
					exit(EXIT_FAILURE);
				}

				fprintf(fichier, "def %s", yytext);

				while (nbEnds > 0 && (c = input()) != EOF)
				{
					column++;
					if (c == '\n')
					{
						column = 0;
						lineno++;
					}
					fputc(c, fichier);
					if (c == ' ' || c == '\t' || c == '\n')
					{
						token[j] = '\0';
						if (strncmp(token, "end", j+1) == 0)
							nbEnds--;
						else if (strncmp(token, "if", j+1) == 0)
							nbEnds++;
						j = 0;
					}
					else if (j < 4)
						token[j++] = c;
				}
				unput('\n');
				unput('d');
				unput('n');
				unput('e');
				unput('\n');
				unput('\n');
				lineno -= 3;
				column = 0;

				fclose(fichier);
				defFun = 0;
			}

			return(ID);
		}
"\n"     { count(); lineno++; return('\n'); }
[ \t\v\f]  { count(); }
.        ;
%%
void initCopie()
{
}

void pushFile(FILE *f)
{
	YY_BUFFER_STATE temp = yy_create_buffer(f, YY_BUF_SIZE);
	yypush_buffer_state(temp);
}

void popFile()
{
	yypop_buffer_state();
}

void copierEntree()
{
	char c;

	mainInputFile = fopen(mainInput, "w");

	if (mainInputFile == NULL)
	{
		fprintf(stderr, "ERREUR : impossible de creer le fichier %s\n", mainInput);
		exit(EXIT_FAILURE);
	}

	while ((c = getchar()) != EOF)
		fputc(c, mainInputFile);

	fclose(mainInputFile);

	mainInputFile = fopen(mainInput, "r");

	if (mainInputFile == NULL)
	{
		fprintf(stderr, "ERREUR : impossible de lire le fichier %s\n", mainInput);
		exit(EXIT_FAILURE);
	}

	yy_delete_buffer(mainBuf);
	mainBuf = yy_create_buffer(mainInputFile, YY_BUF_SIZE);
	yypush_buffer_state(mainBuf);
}

void creerMain()
{
	FILE *fichier = fopen(mainInput, "r");
	char c;
	char token[10] = "";
	int i = 0, nbEnds = 0, nbIfs = 0;


	mainFile = fopen(mainFun, "w");

	if (mainFile == NULL)
	{
		fprintf(stderr, "ERREUR : impossible de creer un fichier\n");
		exit(EXIT_FAILURE);
	}
	if (fichier == NULL)
	{
		fprintf(stderr, "ERREUR : impossible de creer un fichier\n");
		exit(EXIT_FAILURE);
	}

	while ((c = fgetc(fichier)) != EOF)
	{
		if (c == '\n' || c == '\t' || c == ' ' || c == '\v' || c == '\f' || i >= 9)
		{
			token[i] = '\0';
			if (i < 9)
			{
				if (strcmp(token, "def") == 0
					|| strcmp(token, "class") == 0)
					nbEnds++;
				else if (strcmp(token, "end") == 0)
				{
					if (nbIfs > 0)
					{
						if (nbEnds == 0)
							fprintf(mainFile, "%s\n", token);
						nbIfs--;
					}
					if (nbEnds > 0)
						nbEnds--;
				}
				else if (strcmp(token, "if") == 0)
				{
					if (nbEnds > 0)
						nbEnds++;
					else
						fprintf(mainFile, "%s ", token);
					nbIfs++;
				}
				else if (nbEnds == 0)
				{
					fprintf(mainFile, "%s", token);
					fputc(c, mainFile);
				}
			}
			else if (nbEnds == 0)
			{
				fputc(c, mainFile);
				while ((c = fgetc(fichier)) != '\n' && c!= '\t' && c != ' ' && c != '\v' && c != '\f')
					fputc(c, mainFile);
			}
			i = 0;
			token[0] = '\0';
		}
		else if (c == '"' && nbEnds == 0)
		{
			fputc(c, mainFile);
			while ((c = fgetc(fichier)) != '"')
			{
				fputc(c, mainFile);
			}
			fputc(c, mainFile);
		}
		else
			token[i++] = c;
	}

	fclose(mainFile);
	mainFile = NULL;

	reinitialiserEntree();
}

void changerEntree(FILE *f)
{
	buf = yy_create_buffer(f, YY_BUF_SIZE);
	yy_switch_to_buffer(buf);
}

void supprimerEntree()
{
	yy_delete_buffer(buf);
}

