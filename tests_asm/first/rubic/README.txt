Matthieu Renard
Damien Clergeaud
Johann Seiller

Pour compiler notre compilateur, nous avons fait un Makefile.

Nous utilisons bison au lieu de yacc. Donc si vous utilisez yacc. Il suffit de changer la commande dans le Makefile.

Un executable rubic est créé.

Pour l'exécuter, il faut rediriger le fichier d'entree sur l'entree standard. Et le code intermédiaire est retournée sur la sortie standard. Il suffit de rediriger la sortie dans un fichier pour le sauver.

À l'éxecution, le compilateur génère plusieurs fichiers (input.tmp, main.fun ...) qui pourront être effacés par la suite.
Nous n'avons pas eu le temps de faire l'effacement automatique, mais tous les
fichiers ont l'extension .fun, excepté input.tmp. Un simple :
rm *.fun input.tmp 
devrait nettoyer le répertoire (si les fichiers existaient, ils seront remplacés, il faut donc veiller à les renommer avant
si nécessaire). 

Le fichier d'entrée doit finir par une ligne vide.

