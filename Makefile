# latex:  write out \citation in .aux file
# bibtex:  Use .aux and .bib to generate .bbl (included bibliography file)
# latex: write out \bibcite in .aux file based on .bbl
# latex: use \bibcite in .aux file to fill in \cite{...}

FILE=thesis
BIB_FILE=${FILE}.bib
BIB_FILE=
BIB_FILE=${wildcard *.bib}
TEX_FILES=${wildcard *.tex} ${wildcard Chapters/*.tex}
# POSTSCRIPT_FIGURES=*.ps *.eps *.png
FIGURES_EPS  :=$(addsuffix .eps, $(basename $(POSTSCRIPT_FIGURES)))

# .tex -latex-> timestamp.aux -bibtex-> .bbl -latex-> .dvi
# To test:  touch ${FILE}.tex |make |grep '\(bibtex\|latex\|Rerun\)'

default: pdf
dvi: ${FILE}.dvi
catdvi: ${FILE}.dvi
	catdvi $<
eps: ${FIGURES_EPS}

# This reruns latex if 'Rerun to get cross-references right'
${FILE}.dvi: ${FILE}.bbl ${TEX_FILES}
	latex ${FILE}.tex; \
	if ( grep 'Rerun to get cross-references right' \
	     ${FILE}.log > /dev/null ); then latex ${FILE}.tex; else true; fi;

# This timestamp guarantees that latex ran in the presence of ${FILE}.bbl
# It guarantees that bibcite will be found in ${FILE}.aux
${FILE}.bbl: timestamp.aux ${BIB_FILE}
	if test -n "${BIB_FILE}"; then \
	  bibtex ${FILE}; \
	fi
	if test -f ${FILE}.thebib; then \
	  grep -v 'end{thebibliography}' ${FILE}.bbl > tmp.bbl; \
	  grep -v 'begin{thebibliography}' ${FILE}.thebib >> tmp.bbl; \
	  mv -f tmp.bbl ${FILE}.bbl; \
	fi

# This timestamp guarantees there's a .aux file for bibtex
#    with the list of desired citations (the list of bibcite's).
timestamp.aux ${FILE}.aux: ${FILE}.tex
	unset TEXINPUTS; export TEXINPUTS; latex ${FILE}.tex
	echo "" > timestamp.aux

ps.gz: ${FILE}.ps
	gzip $<

# Denali runs dvips v5.86, which does the wrong thing for -R0
# Remove it on Solaris (denali)
# On Ubuntu, use -R0
%.ps: %.dvi
	if [ "$$ARCH" = solaris ]; then \
	  dvips -f -P pdf -G0 -t letter $< > $@ ; \
	else \
	  dvips -f -R0 -P pdf -G0 -t letter $< > $@ ; \
	fi

# Needed to embed Times font used by IEEE class file.
# Use 'pdffonts *.pdf' to check.
%.pdf: %.ps
	ps2pdf14 -dPDFSETTINGS=/prepress $<
	# ps2pdf $< 

renoir: ${FILE}.pdf
	a2ps -Prenoir-duplex -1 -s2 $<

escher: ${FILE}.pdf
	a2ps -Pescher-duplex -1 -s2 ${FILE}.pdf

%.eps: %.svg
	inkscape -D -z --file=$< --export-eps=$@

%.eps: %.fig
	fig2dev -L eps $< > $@

ckptdiagv3.eps: ckptdiagv3.svg
	inkscape -D -z --file=ckptdiagv3.svg --export-eps=ckptdiagv3.eps
# To use this next portion, include in LaTeX source:
# \usepackage{graphicx}
# % png/gif/jpg to eps
# % -blur 1.0   needed if lines not visible; otherwise delete it for higher res
# \DeclareGraphicsRule{.png}{eps}{.bb}{`convert -blur 1.0 #1 'eps:-' }
# \DeclareGraphicsRule{.gif}{eps}{.bb}{`convert -blur 1.0 #1 'eps:-' }
# \DeclareGraphicsRule{.jpg}{eps}{.bb}{`convert -blur 1.0 #1 'eps:-' }
# \DeclareGraphicsExtensions{.png,.gif,.jpg}
# and invoke as:
#   \includegraphics[width=3.0truein]{figures/graphicsFile}
# where one of figures/graphicsFile.{png,gif,jpg} exists.
# Then:  make figures/graphicsFile.bb
# and be sure to send out .ps or .pdf, but NOT .dvi

GIF=${wildcard *.gif}
JPG=${wildcard *.jpg}
PNG=${wildcard *.png}
EPS=${wildcard *.eps}
GRAPHICS=${GIF} ${JPG} ${PNG}
BB=${GIF:.gif=.bb} ${JPG:.jpg=.bb} ${PNG:.png=.bb}
.SUFFIXES: .pdf .eps .gif .jpg .bb .png
.png.bb:
	convert $< 'eps:-' | grep '%%BoundingBox' | head -1 > $@
.gif.bb:
	convert $< 'eps:-' | grep '%%BoundingBox' | head -1 > $@
.jpg.bb:
	convert $< 'eps:-' | grep '%%BoundingBox' | head -1 > $@
# encoding=ascii85:run-length:dc  is also possible
.png.eps:
	bmeps $<.png $<.bb
	bmeps -leps2,encoding=run-length $<.png $<.eps

ps: ${FILE}.ps

pdf: ${FILE}.pdf

${FILE}.pdf: ${FILE}.tex ${FILE}.bbl ${TEX_FILES}
	pdflatex ${FILE}.tex; \
	if ( grep 'Rerun to get cross-references right' \
	     ${FILE}.log > /dev/null ); then pdflatex ${FILE}.tex; fi;

vi: ${FILE}.tex
	vi $<
emacs: ${FILE}.tex
	if test x$$SHLVL = x2; then emacs -nw $<; fi
	if test x$$SHLVL != x2; then emacs $<; fi
xdvi: ${FILE}.dvi
	xdvi $<
gv: ${FILE}.ps
	gv $<
ghostview: ${FILE}.ps
	ghostview $<
acroread: ${FILE}.pdf
	acroread $<
xpdf: ${FILE}.pdf
	xpdf $<
kpdf: ${FILE}.pdf
	kpdf $<
evince: ${FILE}.pdf
	evince $<
okular: ${FILE}.pdf
	okular $<
touch: ${FILE}.tex
	touch $<
spell: ${FILE}.tex
	sed -f detex.sed ${FILE}.tex | spell | sort | uniq | less
detex: ${FILE}.tex
	sed -f detex.sed ${FILE}.tex | less

A: ${FILE}.pdf
M: ${FILE}.pdf
monitor:
	 fileschanged -x make pdf -f $(TEX_FILES) $(POSTSCRIPT_FIGURES)
	
#	  | sed -e 's/\\ref{[^}]*}//g' \
#	  | sed -e 's/\\cite{[^}]*}//g' \
#	  | sed -e 's/\\label{[^}]*}//g' \
#	  | sed -e 's/\\[a-zA-Z]*//g' \

# Don't clean *.ps or *.eps;  That can include some figures.
clean:
	rm -f core a.out *.o *~ .*.swp *.dvi ${FILE}.ps ${FILE}.ps.gz \
	  ${FILE}.pdf *.log *.blg *.dgz \
	  ${FILE}-summary.pdf ${FILE}-body.pdf ${FILE}-references.pdf

distclean: clean
	rm -f *.brf *.idx *.lof *.lot *.toc *.out *.bbl
	rm -f *.aux
	rm -f Chapters/*.aux

dist: clean
	( dir=`basename $$PWD`; cd ..; tar cvf $$dir.tar ./$$dir; \
	  gzip $$dir.tar; cd $$dir; ls -l ../$$dir.tar.gz )

dist-core: clean
	( dir=`basename $$PWD`; cd ..; \
	  if test -d ./$$dir/figures; then files=./$$dir/* ./$$dir/figures/*; \
	  			      else files=./$$dir/*; fi; \
	  tar --no-recursion -cvf $$dir.tar $$files; \
	  gzip $$dir.tar; cd $$dir; ls -l ../$$dir.tar.gz )

# Creating:  ${FILE}-body.pdf instead of $PFILE}-body.dgz
#    Fastlane won't handle .png files contained in .dgz files.
dist-nsf: ${FILE}-summary.dvi ${FILE}-body.pdf ${FILE}-references.dvi
	rm -f ${FILE}-body.dgz
	@ echo
	@ echo CREATED:  ${FILE}-summary.dvi ${FILE}-body.pdf \
		${FILE}-references.dvi
	@ echo

# dist-nsf-alt: ${FILE}-summary.pdf ${FILE}-body.pdf ${FILE}-references.pdf
# 	@ echo
# 	@ echo CREATED:  ${FILE}-summary.pdf ${FILE}-body.pdf \
# 		${FILE}-references.pdf
# 	@ echo

# This assumes a title page (page 1), project summary (page 2), body (3 - 17),
#   and all succeeding pages (18 - ).  Change numbers below if it's different
#   for you.
${FILE}-summary.dvi ${FILE}-body.dvi ${FILE}-body.dgz ${FILE}-references.dvi: \
					${FILE}.dvi ${POSTSCRIPT_FIGURES}
	dviselect =2:2 ${FILE}.dvi ${FILE}-summary.dvi
	dviselect =3:17 ${FILE}.dvi ${FILE}-body.dvi
	tar cvf - ${FILE}-body.dvi ${POSTSCRIPT_FIGURES} | gzip \
	    > ${FILE}-body.dgz
	dviselect =18: ${FILE}.dvi ${FILE}-references.dvi
