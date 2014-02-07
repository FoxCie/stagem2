SRC=rapport.tex
BIB=bibliographie.tex
BIBDEP=rapport.aux
OUTPUT=rapport.pdf
AUXFILES= 	rapport.aux \
			rapport.bbl \
			rapport.log \
			rapport.blg \

all: bib
	pdflatex $(SRC)
	pdflatex $(SRC)

bib: $(BIBDEP)
	bibtex $^

$(BIBDEP): $(SRC)
	pdflatex $(SRC)

clean:
	-rm $(AUX_FILES)

mrproper:
	-rm $(AUX_FILES) $(OUTPUT)

