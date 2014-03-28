%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "y.tab.h"
	#include <string.h>

/* Pour représenter une variable */
enum {STRING_T, FLOAT_T, INT_T, BOOL_T, CLASS_T, INST_T, ENDARG_T,
		FUNCTION_T, NEW_T, ERR_T = -1, UNKNOWN_T = -2};
struct Var
{
	int type;
	union
	{
		int n;
		double f;
		char *s;
		void *c;
	} val;
	int reg;
};

/* Pour représenter un element d'une table des symboles */
struct Element
{
	char *id;
	struct Var var;
};

struct Lhs
{
	char *id;
	struct Var *var;
};

/* Gestion des tables des symboles */
	int allocSize = 10;
	struct Table
	{
		int size;
		int nElmts;
		struct Element *tab;
		struct Table *next;
		struct Table *previous;
	};

	struct Liste
	{
		struct Table *head;
		struct Table *tail;
		struct Liste *parent;
	};

	struct Liste *creerListe(struct Liste *);
	void viderListe(struct Liste *);
	struct Table *creerTable();
	struct Var *ajouterVal(struct Liste *, char *, struct Var *);
	struct Var *chercherVal(struct Liste *, char *);
	struct Var *chercherFun(struct Liste *, char *, struct Liste *);
	struct Var *ajouterFun(struct Liste *, char *, struct Liste *);
	struct Var *ajouterString(struct Liste *, struct Var *);
	char *hashParams(struct Liste *);
	void writeParams(struct Liste *);
	void typerParams(struct Liste *, struct Liste *);
	void initializeParams(struct Liste *);
	void writeType(int);
	void writeGlobals(struct Liste *l);
	int compterCars(char *);
	void afficherVarList(char *, struct Liste *, char *);
	void afficherVar(char *);
	void afficherListe(struct Liste *);
	
	struct Liste *globalList;
	struct Liste *currentList;
	struct Liste *precList;
	struct Liste *tempList;
	struct Liste *argList;
	struct Classe *currentClass;
	struct Fonction *currentFun;
	char *lastID;
	char *funName;
	char *className;
	char *lastClassName = NULL;

	int compteur = 0;
	int cptStr = 0;
	int nbPassages = 0;
	int canWrite = 0;
	int cptIf = 0;
	enum {WRITE_FUNS, WRITE_MAIN, WAIT, TRY} status = WAIT, oldStatus = WAIT;
	

/* Structure pour les fonctions */
struct Fonction
{
	int retType;
	struct Liste *args;
	char *id;
	enum {READY, NOT_READY, NO_WRITE}  status;
};

/* Pour les classes */
struct Classe
{
	struct Liste *funs;
	char *id;
};

%}
%union {struct Var *var; struct Lhs *l; int n; double f; char *id;}

%token AND OR CLASS IF THEN ELSE END WHILE DO DEF LEQ GEQ 
%token STRING FLOAT INT ID FOR TO RETURN IN NEQ PRINT
%left '*' 
%left '/'
%left '+' '-'
%left '<' '>' LEQ GEQ EQ
%left AND OR

%type <var> primary expr comp_expr additive_expr
%type <var> multiplicative_expr stmt params deffun
%type <l> lhs
%type <id> debug
%type <id> ID STRING exprs opt_params
%type <n> INT
%type <f> FLOAT
%%
program		:  topstmts opt_terms
;
topstmts        :      
| topstmt
| topstmts terms topstmt
;
topstmt	        : defclass term stmts terms END 
					{
						currentList = globalList;
						currentClass = NULL;
						className = NULL;
					}
                | stmt
;

defclass 		: CLASS ID
		   			{
						struct Classe *c;
						if (nbPassages == 0)
						{
							c = malloc(sizeof *c);
							struct Var var;
		
							c->id = $2;

							if (c == NULL)
							{
								fprintf(stderr, "Erreur : malloc impossible\n");
								exit(EXIT_FAILURE);
							}
			
							c->funs = creerListe(currentList);

							var.type = CLASS_T;
							var.val.c = c;

							ajouterVal(currentList, $2, &var);
						}
						else
						{
							struct Var *var = chercherVal(currentList, $2);
			
							if (var == NULL || var->type != CLASS_T)
							{
								fprintf(stderr, "ERREUR : pas de classe %s definie dans ce contexte\n", $2);
								exit(EXIT_FAILURE);
							}
			
							c = var->val.c;
						}

						currentList = c->funs;
						currentClass = c;
						className = $2;
					}
		   		| CLASS ID '<' ID

stmts	        : /* none */
                | stmt {lastClassName = NULL;}
                | stmts terms stmt {lastClassName = NULL;}
                ;

stmt		: debutif THEN stmts terms END
	  				{
						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							printf("br i1 1, label %%labelIfEnd%i, label %%labelIfEnd%i\n", cptIf, cptIf);
							printf("labelIfFalse%i:\n", cptIf);
							printf("br i1 1, label %%labelIfEnd%i, label %%labelIfEnd%i\n", cptIf, cptIf);
							printf("labelIfEnd%i:\n", cptIf++);
						}
					}
                | debutif THEN stmts terms ELSE stmts terms END
					{
						
					}
                | FOR ID IN expr TO expr term stmts terms END
					{
						$$ = $4;
					}
                | WHILE expr DO term stmts terms END
					{
						$$ = $2;
					}
                | ID '=' expr
					{
						struct Var *var;
						if ((var = chercherVal(currentList, $1)) == NULL)
							ajouterVal(currentList, $1, $3);
						else if ($3->type == INT_T || $3->type == FLOAT_T)
						{
							if (status == WRITE_FUNS || status == WRITE_MAIN)
							{
								printf("store ");
								writeType(var->type);
								printf("%%x%i, ", $3->reg);
								writeType(var->type);
								printf(" *%%x%i\n", var->reg);
							}
						}
								
						viderListe(tempList);
					}
                | RETURN expr
					{
						$$ = $2;
						if (currentFun == NULL)
						{
							fprintf(stderr, "ERREUR : instruction return en dehors d'une fonction");
							exit(EXIT_FAILURE);
						}
						if (currentFun->retType == UNKNOWN_T)
							currentFun->retType = $2->type;
						else if (currentFun->retType != $2->type)
						{
							fprintf(stderr, "ERREUR : conflit de type pour la fonction %s\n", currentFun->id);
							fprintf(stderr, "new type is %i, foster type is %i\n", $2->type, currentFun->retType);
							exit(EXIT_FAILURE);
						}
						if (status == WRITE_FUNS)
						{
							printf("\tret ");
							if (currentFun->retType == INT_T)
								printf("i32 ");
							else if (currentFun->retType == FLOAT_T)
								printf("double ");
							printf("%%x%i\n", $2->reg);
						}
						if (currentFun->retType == UNKNOWN_T)
							status = WAIT;
					}
                | deffun opt_params term stmts terms END
					{
						char *nom;

						if (status == WRITE_FUNS && currentFun->status == READY)
						{
							printf("}\n\n");
							currentFun->status = NO_WRITE;
						}
						if (currentList->parent == NULL)
						{
							fprintf(stderr, "ERREUR : pas de liste parent");
							exit(EXIT_FAILURE);
						}

						currentList = currentList->parent;

						if (currentFun->status == READY && status == WRITE_FUNS)
							currentFun->status = NO_WRITE;
						currentFun = NULL;
						funName = NULL;
						
					}
				| debug ';'
					{
						if (currentList->parent != NULL)
						{
							struct Var *var = chercherVal(currentList->parent, $1);
							if (var == NULL)
								afficherVarList($1, currentList, "");
							else if  (var->type == CLASS_T || var->type == FUNCTION_T)
								afficherVarList($1, currentList->parent, "");
							else
								afficherVarList($1, currentList, "");
						}
						else
							afficherVarList($1, currentList, "");
						currentList = precList;
					}
				| PRINT expr
					{
						if ((status == WRITE_FUNS && currentFun != NULL) || status == WRITE_MAIN)
						{
							if ($2->type == INT_T)
								printf("call i32 (i32)* @print_int(i32 %%x%i)\n", $2->reg);
							if ($2->type == FLOAT_T)
								printf("call i32 (double)* @print_double(double %%x%i)\n", $2->reg);
							if ($2->type == STRING_T)
							{
								printf("call i32 (i8 *, ...)* @printf(i8* getelementptr(");
								printf("[%i x i8] * @x%i, i32 0, i32 0))\n", compterCars($2->val.c), $2->reg);
							}
							if ($2->type == BOOL_T)
								printf("call i32 (i1) *@print_bool(i1 %%x%i)\n", $2->reg);
						}
; 					}

debutif			: IF expr
					{
						int cpt = cptIf;
						if ($2->type != BOOL_T)
						{
							fprintf(stderr, "ERREUR : condition non booleenne\n");
							exit(EXIT_FAILURE);
						}

						if (status == WRITE_MAIN || status == WRITE_FUNS)
						{
							printf("br i1 %%x%i, label %%labelIfTrue%i, label %%labelIfFalse%i\n", $2->reg, cpt, cpt);
							printf("labelIfTrue%i:\n", cpt);
						}
					}
;

deffun			: DEF ID
					{
						struct Fonction *fun;

						if (chercherVal(currentList, $2) == NULL)
						{
							struct Var var;

							fun = malloc(sizeof *fun);

							fun->args = creerListe(currentList);
							fun->retType = UNKNOWN_T;
							fun->id = $2;
							fun->status = NO_WRITE;

							var.type = FUNCTION_T;
							var.val.c = fun;
							$$ = ajouterVal(currentList, $2, &var);
						}
						else
						{
							char *params = hashParams(argList);
							char *name = malloc(strlen($2) + strlen(params) + 1);
							struct Var *var;

							if (nbPassages <= 1)
							{
								nbPassages++;
								status = WAIT;
							}

							strcpy(name, $2);
							strcat(name, params);

							var = chercherFun(currentList, name, argList);

							if (var == NULL)
							{
								fprintf(stderr, "ERREUR : %s jamais definie (params : %s)\n", name, params);
								exit(EXIT_FAILURE);
							}
							else if (var->type != FUNCTION_T)
							{
								fprintf(stderr, "ERREUR : %s n'est pas une fonction\n", $2);
								exit(EXIT_FAILURE);
							}

							fun = var->val.c;

							free(params);
							free(name);
						}

						currentList = fun->args;
						currentFun = fun;
						funName = $2;

						if (status == WRITE_FUNS && fun->status == READY)
						{
							printf("define ");
							if (fun->retType == INT_T)
								printf("i32 ");
							else if (fun->retType == FLOAT_T)
								printf("double ");
							printf("@");
							if (className != NULL)
								printf("%s$", className);
							printf("%s", $2);
						}
					}
;
opt_params      : /* none */
					{
						struct Var var;
						var.type = ENDARG_T;

						if (nbPassages > 1)
						{
							ajouterVal(currentList, "", &var);
						}
						$$ = NULL;
		
						if (status == WRITE_FUNS && currentFun->status == READY)
							printf("()\n{\n");
					}
						
                | '(' ')'
					{
						struct Var var;
						var.type = ENDARG_T;
						ajouterVal(currentList, "", &var);
						$$ = NULL;
					
						if (status == WRITE_FUNS)
							printf("()\n{\n");
					}
                | '(' params ')'
					{
						struct Var var;
						struct Table *t;
						int i;

						var.type = ENDARG_T;

						ajouterVal(currentList, "", &var);

						typerParams(currentList, argList);

						if (status == WRITE_FUNS && currentFun->status == READY)
						{
							char *name = hashParams(argList);

							printf("%s(", name);
							writeParams(currentList);
							printf(")\n{\n");
							initializeParams(currentList);

							free(name);
						}
					}
;
params          : params ',' ID
					{
						struct Var var;

						var.type = UNKNOWN_T;

						$$ = ajouterVal(currentList, $3, &var);
					}
                | ID
					{
						struct Var var;

						var.type = UNKNOWN_T;
						$$ = ajouterVal(currentList, $1, &var);
					}
; 
debug			: ID
					{
						struct Var *var;
						precList = currentList;

						var = chercherVal(currentList, $1);

						if (var == NULL)
							$$ = $1;
						else if (var->type == CLASS_T)
						{
							struct Classe *c = var->val.c;
							currentList = c->funs;
							$$ = $1;
						}
						else
							$$ = $1;
					}

                | debug '.' ID
					{
						struct Var *var = chercherVal(currentList, $3);
						if (var == NULL)
							$$ = $3;
						else if (var->type == CLASS_T)
						{
							struct Classe *c = var->val.c;
							currentList = c->funs;
							$$ = $3;
						}
						else
							$$ = $3;
					}
/*                | ID '(' exprs ')'*/
;
lhs				: ID
					{
						struct Var *var;
						$$ = malloc(sizeof *$$);
						precList = currentList;
						var = chercherVal(currentList, $1);
						$$->id = $1;
						if (var == NULL && !(funName != NULL && status == WRITE_MAIN))
						{
							fprintf(stderr, "ERREUR : %s non defini dans ce contexte\n", $1);
							exit(EXIT_FAILURE);
						}
						if (var->type == UNKNOWN_T)
							status = WAIT;
						lastID = $1;
						$$->var = var;

						if (var->type == INT_T || var->type == FLOAT_T)
						{
							struct Var v;
							v.type = var->type;
							v.reg = compteur++;
							if (status == WRITE_MAIN || status == WRITE_FUNS)
							{
								printf("%%x%i = load ", v.reg);
								writeType(var->type);
								printf(" *%%x%i\n", var->reg);
								$$->var = ajouterVal(tempList, "", &v);
							}
						}
								

					}
				| lhs '.' ID
					{
						if ($1->var->type == CLASS_T)
						{
							if (strncmp($3, "new", 4) == 0)
							{
								struct Var var;
								var.type = NEW_T;
								var.val.c = $1->var->val.c;
								$$->var = ajouterVal(tempList, "", &var);
							}
							else
							{
								fprintf(stderr, "ERREUR : new() attendu au lieu de %s\n", $3);
								exit(EXIT_FAILURE);
							}
						}
						else if ($1->var->type == INST_T)
						{
							struct Classe *c = $1->var->val.c;
							$$ = malloc(sizeof *$$);
							$$->var = chercherVal(c->funs, $3);
							$$->id = $3;
							if ($$->var == NULL)
							{
								fprintf(stderr, "ERREUR : %s non defini dans ce contexte\n", $3);
								exit(EXIT_FAILURE);
							}

							if ($$->var->type == UNKNOWN_T)
								status = WAIT;
							lastID = $3;
							lastClassName = c->id;
						}
						else
						{
							fprintf(stderr, "ERREUR : type classe ou objet attendu avant '.'\n");
							exit(EXIT_FAILURE);
						}
					}
				| lhs '(' exprs ')'
					{
						if ($1->var->type == FUNCTION_T)
						{
							struct Fonction *f = $1->var->val.c, *g;
							struct Var *var = NULL;
							struct Var v;
							struct Table *t;
							int i;
							char *nom = malloc(strlen($3) + strlen($1->id) + 2);

							$$ = malloc(sizeof *$$);

							v.type = ENDARG_T;
							//ajouterVal(argList, "", &v);

							nom[0] = '\0';
							strcat(nom, $1->id);
							strcat(nom, "$");
							strcat(nom, $3);

							var = chercherFun(f->args->parent, nom, argList);
							if (var == NULL)
							{
								int j = 0, add = 1;
								int old = status;
								char *filename;
								struct Table *t;
								struct Liste *temp = creerListe(NULL);
								struct Liste *oldList = currentList;
								struct Liste *l;
								FILE *fichier;

								if (lastClassName != NULL)
								{
									struct Var *v = chercherVal(globalList, lastClassName);

									if (v->type == CLASS_T)
									{
										struct Classe *c = v->val.c;
										l = c->funs;
										className = c->id;
										currentClass = c;
									}
									else
									{
										fprintf(stderr, "%s n'est pas une classe\n", lastClassName);
										exit(EXIT_FAILURE);
									}
									filename = malloc(strlen(lastClassName) + strlen($1->id) + 6);
									strcpy(filename, lastClassName);
									strcat(filename, "$");
									strcat(filename, $1->id);
								}
								else
								{
									filename = malloc(strlen(lastID) + 5);
									strcpy(filename, $1->id);
									l = currentList;
								}

								strcat(filename, ".fun");
								status = WAIT;
								var = ajouterFun(f->args->parent, nom, argList);
								currentList = l;
								if (var == NULL && add)
								{
									fprintf(stderr, "ERREUR : pas de fonction %s definie dans ce contexte\n", lastID);
									exit(EXIT_FAILURE);
								}
								for (t = argList->tail ; t != NULL ; t = t->previous)
								{
									for (i = 0 ; i < t->nElmts ; i++)
									{
										if (t->tab[i].var.type == UNKNOWN_T)
										{
											add = 0;
											fprintf(stderr, "Parametre inconnu pour %s\n", f->id);
										}
										ajouterVal(temp, t->tab[i].id, &(t->tab[i].var));
									}
								}

								fichier = fopen(filename, "r");
								if (fichier == NULL)
								{
									fprintf(stderr, "ERREUR : impossible d'ouvrir le fichier %s\n", filename);
									exit(EXIT_FAILURE);
								}
								while (status == WAIT)
								{
									viderListe(argList);
									for (t = temp->tail ; t != NULL ; t = t->previous)
									{
										for (i = 0 ; i < t->nElmts ; i++)
											ajouterVal(argList, t->tab[i].id, &(t->tab[i].var));
									}
									fseek(fichier, 0, SEEK_SET);
									status = TRY;
									pushFile(fichier);
									yyparse();
									popFile();
								}

								g = var->val.c;

								viderListe(argList);
								for (t = temp->tail ; t != NULL ; t = t->previous)
								{
									for (i = 0 ; i < t->nElmts ; i++)
										ajouterVal(argList, t->tab[i].id, &(t->tab[i].var));
								}
								status = WRITE_FUNS;
								g->status = READY;
								fseek(fichier, 0, SEEK_SET);
								pushFile(fichier);
								yyparse();
								popFile();
								status = old;
								fclose(fichier);
								currentList = oldList;
							
								g->status = NO_WRITE;
									viderListe(argList);
									for (t = temp->tail ; t != NULL ; t = t->previous)
									{
										for (i = 0 ; i < t->nElmts ; i++)
											ajouterVal(argList, t->tab[i].id, &(t->tab[i].var));
									}
							}

							v.type = ENDARG_T;
							ajouterVal(argList, "", &v);
							$$->var = ajouterVal(tempList, "", var);
							g = var->val.c;
							$$->var->type = g->retType;
							if (status == WRITE_MAIN || status == WRITE_FUNS)
							{
								$$->var->reg = compteur++;
	
								printf("%%x%i = call ", $$->var->reg);
								if (g->retType == INT_T)
									printf("i32 ");
								else if (g->retType == FLOAT_T)
									printf("double ");
								printf("(");
								for (t = argList->tail ; t != NULL ; )
								{
									for (i = 0 ; i < t->nElmts ; i++)
									{
										if (t->tab[i].var.type == ENDARG_T)
										{
											t = NULL;
											break;
										}
										if (!(t == argList->tail && i == 0))
											printf(", ");
										writeType(t->tab[i].var.type);
									}
								}
	
								printf(")* @");
								if (g->args->parent != NULL)
								{
									if (lastClassName != NULL)
										printf("%s$", lastClassName);
									lastClassName = NULL;
								}
								printf("%s(", g->id);
	
								for (t = argList->tail ; t != NULL ; )
								{
									for (i = 0 ; i < t->nElmts ; i++)
									{
										if (t->tab[i].var.type == ENDARG_T)
										{
											t = NULL;
											break;
										}
										if (!(t == argList->tail && i == 0))
											printf(", ");
										writeType(t->tab[i].var.type);
										printf("%%x%i", t->tab[i].var.reg);
									}
								}

								printf(")\n");
							}
						}
						else if ($1->var->type == NEW_T)
						{
							struct Var var;
							var.type = INST_T;
							var.val.c = $1->var->val.c;
							$$->var = ajouterVal(tempList, "", &var);
						}
						else
						{
							fprintf(stderr, "ERREUR : fonction ou methode attendue avant '('\n");
							exit(EXIT_FAILURE);
						}
						viderListe(argList);
						$$->id = $1->id;
					}
;
exprs           :	{
						$$ = malloc(1);
						$$[0] = '\0';
					} 
				| exprs ',' expr
					{
						ajouterVal(argList, "", $3);
						if ($3->type >= 0 && $3->type <= 9)
							$$ = malloc(strlen($1) + 3);
						else
							$$ = malloc(strlen($1) + 4);
						sprintf($$, "%s$%i", $1, $3->type);
						free($1);
						if ($3->type == UNKNOWN_T)
							status = WAIT;
					}
                | expr
					{
						ajouterVal(argList, "", $1);
						if ($1->type >= 0 && $1->type <= 9)
							$$ = malloc(2);
						else
							$$ = malloc(3);
						sprintf($$, "%i", $1->type);
						if ($1->type == UNKNOWN_T)
							status = WAIT;
					}
;
primary         : lhs
					{
						$$ = $1->var;
					}

                | STRING
					{
						struct Var var;
						int size;

						var.type = STRING_T;
						var.val.c = $1;
					
						$$ = ajouterString(globalList, &var);
					}
                | FLOAT
					{
						struct Var var;
	
						var.type = FLOAT_T;
						var.val.f = $1;

						$$ = ajouterVal(tempList, "", &var);
						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							$$->reg = compteur++;
							printf("%%x%i = fadd double %g, 0.0\n", $$->reg, $1);
						}
					}
                | INT
					{
						struct Var var;
	
						var.type = INT_T;
						var.val.n = $1;

						$$ = ajouterVal(tempList, "", &var);
						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							$$->reg = compteur++;
							printf("%%x%i = add i32 %i, 0\n", $$->reg, $1);
						}
					}
                | '(' expr ')'
					{
						$$ = $2;
					}
;
expr            : expr AND comp_expr
					{
						struct Var var;
						var.type = BOOL_T;
						
						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != BOOL_T || $3->type != BOOL_T)
						{
							fprintf(stderr, "ERREUR : expression booleenne attendue\n");
							exit(EXIT_FAILURE);
						}
	
						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							var.reg = compteur++;
							printf("%%x%i = and i1 %%x%i, %%x%i\n", var.reg, $1->reg, $3->reg);
						}

						ajouterVal(tempList, "", &var);
					}
                | expr OR comp_expr
					{
						struct Var var;
						var.type = BOOL_T;
						
						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != BOOL_T || $3->type != BOOL_T)
						{
							fprintf(stderr, "ERREUR : expression booleenne attendue\n");
							exit(EXIT_FAILURE);
						}
	
						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							var.reg = compteur++;
							printf("%%x%i = and i1 %%x%i, %%x%i\n", var.reg, $1->reg, $3->reg);
						}

						ajouterVal(tempList, "", &var);
					}
                | comp_expr
					{
						$$ = $1;
					}
;
comp_expr       : additive_expr '<' additive_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						var.type = BOOL_T;
						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
								if ($1->type == INT_T)
								{
									reg1 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
								}
								if ($3->type == INT_T)
								{
									reg2 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
								}
								var.reg = compteur++;
								printf("%%x%i = fcmp olt double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
							else
							{
								var.reg = compteur++;
								printf("%%x%i = icmp slt i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						$$ = ajouterVal(tempList, "", &var);
					}
                | additive_expr '>' additive_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
								if ($1->type == INT_T)
								{
									reg1 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
								}
								if ($3->type == INT_T)
								{
									reg2 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
								}
								var.reg = compteur++;
								printf("%%x%i = fcmp ogt double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
							else
							{
								var.reg = compteur++;
								printf("%%x%i = icmp sgt i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						var.type = BOOL_T;
						$$ = ajouterVal(tempList, "", &var);
					}
                | additive_expr LEQ additive_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
								if ($1->type == INT_T)
								{
									reg1 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
								}
								if ($3->type == INT_T)
								{
									reg2 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
								}
								var.reg = compteur++;
								printf("%%x%i = fcmp ole double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
							else
							{
								var.reg = compteur++;
								printf("%%x%i = icmp sle i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						var.type = BOOL_T;
						$$ = ajouterVal(tempList, "", &var);
					}
                | additive_expr GEQ additive_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
								if ($1->type == INT_T)
								{
									reg1 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
								}
								if ($3->type == INT_T)
								{
									reg2 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
								}
								var.reg = compteur++;
								printf("%%x%i = fcmp oge double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
							else
							{
								var.reg = compteur++;
								printf("%%x%i = icmp sge i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						var.type = BOOL_T;
						$$ = ajouterVal(tempList, "", &var);
					}
                | additive_expr EQ additive_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
								if ($1->type == INT_T)
								{
									reg1 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
								}
								if ($3->type == INT_T)
								{
									reg2 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
								}
								var.reg = compteur++;
								printf("%%x%i = fcmp oeq double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
							else
							{
								var.reg = compteur++;
								printf("%%x%i = icmp eq i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						var.type = BOOL_T;
						$$ = ajouterVal(tempList, "", &var);
					}
                | additive_expr NEQ additive_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						if (status == WRITE_FUNS || status == WRITE_MAIN)
						{
							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
									if ($1->type == INT_T)
									{
										reg1 = compteur++;
										printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
									}
									if ($3->type == INT_T)
									{
										reg2 = compteur++;
										printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
									}
									var.reg = compteur++;
									printf("%%x%i = fcmp one double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
							else
							{
								var.reg = compteur++;
								printf("%%x%i = icmp neq i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						var.type = BOOL_T;
						$$ = ajouterVal(tempList, "", &var);
					}
                | additive_expr
					{
						$$ = $1;
					}
;
additive_expr   : multiplicative_expr
					{
						$$ = $1;
					}
                | additive_expr '+' multiplicative_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						else if ($1->type == FLOAT_T || $3->type == FLOAT_T)
						{
							var.type = FLOAT_T;
							if (status == WRITE_FUNS || status == WRITE_MAIN)
							{
								if ($1->type == INT_T)
								{
									reg1 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
								}
								if ($3->type == INT_T)
								{
									reg2 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
								}
								var.reg = compteur++;
								printf("%%x%i = fadd double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						else
						{
							var.type = INT_T;
							if (status == WRITE_FUNS || status == WRITE_MAIN)
							{
								var.reg = compteur++;
								printf("%%x%i = add i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						$$ = ajouterVal(tempList, "", &var);
					}
                | additive_expr '-' multiplicative_expr
					{
						struct Var var;
						int reg1 = $1->reg, reg2 = $3->reg;

						if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
						{
							if (currentFun != NULL)
								currentFun->status = NOT_READY;
							else
								canWrite = 0;

							var.type = UNKNOWN_T;
						}
						else if ($1->type != FLOAT_T && $1->type != INT_T
							&& $3->type != FLOAT_T && $3->type != INT_T)
						{
							fprintf(stderr, "ERREUR : expression numerique attendue\n");
							exit(EXIT_FAILURE);
						}

						if ($1->type == FLOAT_T || $3->type == FLOAT_T)
						{
							var.type = FLOAT_T;
							if (status == WRITE_FUNS || status == WRITE_MAIN)
							{
								if ($1->type == INT_T)
								{
									reg1 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
								}
								if ($3->type == INT_T)
								{
									reg2 = compteur++;
									printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
								}
								var.reg = compteur++;
								printf("%%x%i = fsub double %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						else
						{
							var.type = INT_T;
							if (status == WRITE_FUNS || status == WRITE_MAIN)
							{
								var.reg = compteur++;
								printf("%%x%i = sub i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
							}
						}
						$$ = ajouterVal(tempList, "", &var);
					}
;
multiplicative_expr : multiplicative_expr '*' primary
						{
							struct Var var;
							int reg1 = $1->reg, reg2 = $3->reg;

							if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
							{
								if (currentFun != NULL)
									currentFun->status = NOT_READY;
								else
									canWrite = 0;

								var.type = UNKNOWN_T;
							}
							else if ($1->type != FLOAT_T && $1->type != INT_T
								&& $3->type != FLOAT_T && $3->type != INT_T)
							{
								fprintf(stderr, "ERREUR : expression numerique attendue\n");
								exit(EXIT_FAILURE);
							}

							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
								var.type = FLOAT_T;
								if (status == WRITE_FUNS || status == WRITE_MAIN)
								{
									if ($1->type == INT_T)
									{
										reg1 = compteur++;
										printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
									}
									if ($3->type == INT_T)
									{
										reg2 = compteur++;
										printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
									}
									var.reg = compteur++;
									printf("%%x%i = fmul double %%x%i, %%x%i\n", var.reg, reg1, reg2);
								}
							}
							else
							{
								var.type = INT_T;
								if (status == WRITE_FUNS || status == WRITE_MAIN)
								{
									var.reg = compteur++;
									printf("%%x%i = mul i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
								}
							}
							$$ = ajouterVal(tempList, "", &var);
						}
					| multiplicative_expr '/' primary
						{
							struct Var var;
							int reg1 = $1->reg, reg2 = $3->reg;

							if ($1->type == UNKNOWN_T || $3->type == UNKNOWN_T)
							{
								if (currentFun != NULL)
									currentFun->status = NOT_READY;
								else
									canWrite = 0;

								var.type = UNKNOWN_T;
							}
							else if ($1->type != FLOAT_T && $1->type != INT_T
								&& $3->type != FLOAT_T && $3->type != INT_T)
							{
								fprintf(stderr, "ERREUR : expression numerique attendue\n");
								exit(EXIT_FAILURE);
							}

							if ($1->type == FLOAT_T || $3->type == FLOAT_T)
							{
								var.type = FLOAT_T;
								if (status == WRITE_FUNS || status == WRITE_MAIN)
								{
									if ($1->type == INT_T)
									{
										reg1 = compteur++;
										printf("%%x%i = sitofp i32 %%x%i to double\n", reg1, $1->reg);
									}
									if ($3->type == INT_T)
									{
										reg2 = compteur++;
										printf("%%x%i = sitofp i32 %%x%i to double\n", reg2, $3->reg);
									}
									var.reg = compteur++;
									printf("%%x%i = fdiv double %%x%i, %%x%i\n", var.reg, reg1, reg2);
								}
							}
							else
							{
								var.type = INT_T;
								if (status == WRITE_FUNS || status == WRITE_MAIN)
								{
									var.reg = compteur++;
									printf("%%x%i = sdiv i32 %%x%i, %%x%i\n", var.reg, reg1, reg2);
								}
							}
							$$ = ajouterVal(tempList, "", &var);
						}
                    | primary
						{
							$$ = $1;
						}
;
opt_terms	: /* none */
		| terms
		;

terms		: terms ';'
                | terms '\n'
		| ';'
                | '\n'
		;
term            : ';'
                | '\n'
;
%%

struct Table *creerTable()
{
	struct Table *table = malloc(sizeof *table);
	
	table->size = allocSize;
	table->nElmts = 0;
	table->tab = malloc(table->size * sizeof(struct Element));
	table->next = NULL;
	table->previous = NULL;

	return table;
}

struct Liste *creerListe(struct Liste *parent)
{
	struct Liste *ret = malloc(sizeof *ret);

	ret->head = creerTable();
	ret->tail = ret->head;
	ret->parent = parent;

	return ret;
}

void viderListe(struct Liste *l)
{
	struct Table *t;

	if (l == NULL || l->head == NULL)
		return;

	for (t = l->head ; t != NULL ; t = t->next)
		t->nElmts = 0;
}

struct Var *ajouterVal(struct Liste *l, char *id, struct Var *var)
{
	struct Table *t;
	struct Var *v;

	if (l == NULL || l->head == NULL)
		return NULL;

	if (id[0] != '\0' && (v = chercherVal(l, id)) != NULL)
	{
		*v = *var;
		return v;
	}


	if (id[0] == '$')
		l = globalList;
	else if (id[0] == '@')
	{
		if (currentClass == NULL)
		{
			fprintf(stderr, "ERREUR : definition de la variable d'instance %s en dehors d'une classe", id);
			exit(EXIT_FAILURE);
		}
		l = currentClass->funs;
	}

	t = l->head;

	if (t->nElmts == t->size)
	{
		struct Table *new = creerTable();
		new->next = t;
		t->previous = new;
		l->head = new;
		t = new;
	}
	
	t->tab[t->nElmts].id = strdup(id);
	t->tab[t->nElmts].var = *var;

	return &(t->tab[t->nElmts++].var);
}

struct Var *chercherVal(struct Liste *l, char *id)
{
	struct Table *t;
	int i;

	if (l == NULL || l->head == NULL)
		return NULL;

	if (id[0] == '$')
		l = globalList;
	else if (id[0] == '@')
	{
		if (currentClass == NULL)
		{
			fprintf(stderr, "ERREUR : utilisation de la variable d'instance %s en dehors de toute classe\n", id);
			exit(EXIT_FAILURE);
		}
		l = currentClass->funs;
	}

	for (t = l->head ; t != NULL ; t = t->next)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (strcmp(t->tab[i].id, id) == 0)
				return &(t->tab[i].var);
		}
	}

	return NULL;
}

void afficherStructVar(struct Var *var)
{
	switch (var->type)
	{
		case INT_T :
		fprintf(stderr, "INT : %i", var->val.n);
		break;

		case FLOAT_T :
		fprintf(stderr, "FLOAT : %g", var->val.f);
		break;

		case STRING_T :
		fprintf(stderr, "STRING : %s", var->val.s);
		break;
	
		case FUNCTION_T :
		fprintf(stderr, "FUNCTION : %i", ((struct Fonction *)var->val.c)->status);
		break;

		default :
		fprintf(stderr, "COMPLEX : %i", var->type);
	}
}

void afficherVarList(char *id, struct Liste *l, char *nom)
{
	struct Table *t;
	int i;

	if (l == NULL || l->head == NULL)
		return;

	for (t = l->head ; t != NULL ; t = t->next)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (strcmp(t->tab[i].id, id) == 0)
			{
				if (nom[0] != '\0')
					fprintf(stderr, "%s.", nom);
				fprintf(stderr, "%s : ", id);
				afficherStructVar(&(t->tab[i].var));
				fprintf(stderr, "\n");
			}

			if (t->tab[i].var.type == CLASS_T)
			{
				char *s;
				struct Classe *c = t->tab[i].var.val.c;
				struct Liste *m;

				if (c == NULL)
				{
					fprintf(stderr, "ERREUR : classe nulle\n");
					break;
				}

				m = c->funs;

				s = malloc(strlen(nom) + strlen(t->tab[i].id) + 2);
				s[0] = '\0';
				if (nom[0] != '\0')
				{
					strcat(s, nom);
					strcat(s, ".");
				}
				strcat(s, t->tab[i].id);

				afficherVarList(id, m, s);

				free(s);
			}
			else if (t->tab[i].var.type == FUNCTION_T)
			{
				char *s;
				struct Fonction *f = t->tab[i].var.val.c;
				struct Liste *m;

				if (f == NULL)
				{
					fprintf(stderr, "ERREUR : Fonction nulle\n");
					break;
				}

				m = f->args;


				s = malloc(strlen(nom) + strlen(t->tab[i].id) + 2);
				s[0] = '\0';
				if (nom[0] != '\0')
				{
					strcat(s, nom);
					strcat(s, ".");
				}
				strcat(s, t->tab[i].id);
				
				afficherVarList(id, m, s);

				free(s);
			}
		}
	}
}
			
void afficherVar(char *id)
{
	char nom[256] = "";

	afficherVarList(id, globalList, nom);
}

struct Var *chercherFun(struct Liste *l, char *id, struct Liste *args)
{
	struct Table *t, *u;
	int i, j;

	if (l == NULL || l->head == NULL)
		return NULL;

	for (t = l->head ; t != NULL ; t = t->next)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (strcmp(t->tab[i].id, id) == 0)
			{
				if (t->tab[i].var.type == FUNCTION_T)
					return &(t->tab[i].var);
				else
				{
					fprintf(stderr, "ERREUR : pas de fonction %s definie\n", id);
					exit(EXIT_FAILURE);
				}
			}
		}
	}

	return chercherFun(l->parent, id, args);
}

struct Var *ajouterFun(struct Liste *l, char *id, struct Liste *args)
{
	struct Fonction *f = malloc(sizeof *f);
	struct Table *t;
	int i;
	struct Var var;

	if (l == NULL || l->head == NULL)
		return NULL;

	f->args = creerListe(l);
	f->id = strdup(id);
	f->status = NOT_READY;
	f->retType = UNKNOWN_T;

	var.type = FUNCTION_T;
	var.val.c = f;
		
	return ajouterVal(l, id, &var);
}

struct Var *ajouterString(struct Liste *l, struct Var *var)
{
	struct Table *t;
	int i;
	char *s = var->val.c;

	l = globalList;

	if (l == NULL || l->tail == NULL)
		return NULL;

	for (t = l->tail ; t != NULL ; t = t->previous)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (t->tab[i].var.type == STRING_T)
			{
				if (strcmp(s, t->tab[i].var.val.c) == 0)
					return &(t->tab[i].var);
			}
		}
	}

	var->reg = compteur++;
	printf("@x%i = constant [%i x i8] c\"%s\"\n", var->reg, compterCars(var->val.c), var->val.c);

	return ajouterVal(l, "", var);
}

char *hashParams(struct Liste *l)
{
	int size = 1, i;
	struct Table *t;
	char *ret = malloc(1);

	ret[0] = '\0';

	if (l == NULL || l->head == NULL)
		return ret;

	for (t = l->tail ; t != NULL ; t = t->previous)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (t->tab[i].var.type >= 0 && t->tab[i].var.type <= 9)
				size += 2;
			else
				size += 3;
			if (i == t->nElmts - 1 && t->previous == NULL)
			{
				free(ret);
				ret = malloc(size);
				for (t = l->tail ; t != NULL ; t = t->previous)
				{
					for (i = 0 ; i < t->nElmts ; i++)
					{
						sprintf(ret, "%s$%i", ret, t->tab[i].var.type);
						if (i == t->nElmts - 1 && t->previous == NULL)
							return ret;
					}
				}
			}
		}
	}
	
	return ret;
}

void typerParams(struct Liste *l, struct Liste *args)
{
	struct Table *t, *u;
	int i, j = 0;

	if (l == NULL || l->tail == NULL || args == NULL || args->tail == NULL)
		return;

	u = args->tail;

	for (t = l->tail ; t != NULL ; )
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (j == u->nElmts)
			{
				j = 0;
				u = u->previous;
			}

			if (u == NULL && t->tab[i].var.type != ENDARG_T)
			{
				fprintf(stderr, "ERREUR : arguments manquants pour %s : attendu : %i\n", funName, t->tab[i].var.type);
				exit(EXIT_FAILURE);
			}

			else if (t->tab[i].var.type == ENDARG_T && u != NULL)
			{
				fprintf(stderr, "ERREUR : trop d'arguments pour %s : attendus : %i\n", funName, i);
				exit(EXIT_FAILURE);
			}

			if (u == NULL)
			{
				t = NULL;
				break;
			}

			t->tab[i].var.type = u->tab[j].var.type;
			j++;
		}
		if (t != NULL)
			t = t->previous;
	}
}

void writeParams(struct Liste *l)
{
	struct Table *t;
	int i, reg;

	if (l == NULL || l->tail == NULL)
		return;

	for (t = l->tail ; t != NULL ; t = t->previous)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (t->tab[i].var.type == ENDARG_T)
				return;
			if (!(t == l->tail && i == 0))
				printf(", ");
			writeType(t->tab[i].var.type);
			printf("%%arg%s", t->tab[i].id);

			
		}
	}
}

int compterCars(char *s)
{
	int i = 0, size = 0;

	while (s[i] != '\0')
	{
		if (s[i++] == '\\')
		{
			size++;
			i++;
			i++;
		}
		else
			size++;
	}

	return size;
}

void writeGlobals(struct Liste *l)
{
	struct Table *t;
	int i, j = 0, k;

	if (l == NULL || l->tail == NULL)
		return;

	for (t = l->tail ; t != NULL ; t = t->next)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (t->tab[i].var.type == STRING_T)
				printf("@x%i = constant [%i x i8] c\"%s\"\n", t->tab[i].var.reg, compterCars(t->tab[i].var.val.c), t->tab[i].var.val.c);
		}
	}
}

void initializeParams(struct Liste *l)
{
	struct Table *t;
	int i, reg, arg = 1;

	if (l == NULL || l->tail == NULL)
		return;

	for (t = l->tail ; t != NULL ; t = t->previous)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (t->tab[i].var.type == ENDARG_T)
				arg = 0;
			if (t->tab[i].var.type == INT_T || t->tab[i].var.type == FLOAT_T)
			{
				reg = compteur++;
				t->tab[i].var.reg = reg;
				printf("%%x%i = ", reg);
				if (t->tab[i].var.type == INT_T)
				{
					printf("alloca i32\n");
					if (arg)
					{
						printf("store i32 ");
						printf("%%arg%s, i32 *%%x%i\n", t->tab[i].id, reg);
					}
				}
				else if (t->tab[i].var.type == FLOAT_T)
				{
					printf("alloca double\n");
					if (arg)
					{
						printf("store double ");
						printf("%%arg%s, double *%%x%i\n", t->tab[i].id, reg);
					}
				}
			}
		}
	}
}

void initializeMain(struct Liste *l)
{
	struct Table *t;
	int i;

	for (t = l->tail ; t != NULL ; t = t->previous)
	{
		for (i = 0 ; i < t->nElmts ; i++)
		{
			if (t->tab[i].var.type == INT_T || t->tab[i].var.type == FLOAT_T)
			{
				int reg = compteur++;
				t->tab[i].var.reg = reg;
				printf("%%x%i = alloca ", reg);
				writeType(t->tab[i].var.type);
				printf("\n");
			}
		}
	}
}

void writeType(int type)
{
	switch (type)
	{
		case INT_T :
		printf("i32 ");
		break;
	
		case FLOAT_T :
		printf("double ");
		break;

		default :
		break;
	}
}
				
							
void afficherListe(struct Liste *l)
{
	struct Table *t;
	int i;

	printf("Affichage de %x\n", l);

	if (l == NULL || l->head == NULL)
		return;

	for (t = l->head ; t != NULL ; t = t->next)
		for (i = 0 ; i < t->nElmts ; i++)
			printf("%s : %i\n", t->tab[i].id, t->tab[i].var.type);
}

int main() {
	int i = 0;
	globalList = creerListe(NULL);
	currentList = globalList;
	tempList = creerListe(NULL);
	argList = creerListe(NULL);

	printf("declare i32 @printf(i8 *, ...)\n\n");

	printf("@str_int = constant [4 x i8] c\"%%d\\0A\\00\"\n");
	printf("@str_double = constant [4 x i8] c\"%%g\\0A\\00\"\n");
	printf("\n");
	printf("define i32 @print_double(double %%argf)\n{\n");
	printf("\t%%retVal = call i32 (i8 *, ...)* @printf(");
	printf("i8 * getelementptr([4 x i8]* @str_double, i32 0, i32 0), double %%argf)\n");
	printf("ret i32 %%retVal\n");
	printf("}\n\n");
	printf("define i32 @print_int(i32 %%argi)\n{\n");
	printf("\t%%retVal = call i32 (i8 *, ...)* @printf(");
	printf("i8 * getelementptr([4 x i8]* @str_int, i32 0, i32 0), i32 %%argi)\n");
	printf("ret i32 %%retVal\n");
	printf("}\n\n");
	printf("define i32 @print_str(i8 * %%argstr)\n{\n");
	printf("\t%%retVal = call i32 (i8 *, ...)* @printf(i8 * %%argstr)");
	printf("ret i32 %%retVal\n");
	printf("}\n\n");
	printf("define i32 @print_bool(i1 %%argb)\n{\n");
	printf("\t%%intVal = zext i1 %%argb to i32\n");
	printf("\t%%retVal = call i32 (i8 *, ...)* @printf(");
	printf("i8 * getelementptr([4 x i8]* @str_int, i32 0, i32 0), i32 %%intVal)\n");
	printf("ret i32 %%retVal\n");
	printf("}\n\n");

	copierEntree();	

  yyparse(); 
	creerMain();
	nbPassages++;
	reinitialiserEntree();
	currentList = globalList;
	lastClassName = NULL;
	yyparse();
	status = WRITE_FUNS;

	printf("define i32 @main()\n");
	printf("{\n");
	reinitialiserEntree();
	currentList = globalList;
	lastClassName = NULL;
	status = WRITE_MAIN;
	initializeMain(globalList);
	yyparse();
	printf("ret i32 0\n");
	printf("}\n");

  return 0;
}

