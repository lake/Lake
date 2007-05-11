# Makefiles that import this makefile
# must define
# 	CURRENT = the stem of the master latex file to be built
# and optionally define 
# 	LOCAL_TEXINPUTS = the location of local macros, style files, etc.
# 	LOCAL_BIBINPUTS = the location of bibtex databases.
# 	LOCAL_BSTINPUTS = the location of bibtex style files.

PAPER=$(CURRENT:=.pdf)
ifdef LOCAL_TEXINPUTS
	ifdef TEXINPUTS
		export TEXINPUTS := $(LOCAL_TEXINPUTS):$(TEXINPUTS)
	else
		#the null entry `::' denotes the default system directories.
		#above we assume that, if TEXINPUTS is defined, the builder
		#correctly set TEXINPUTS. However, here we must append `::'
		#or the Tex system files will not be found.
		export TEXINPUTS := $(LOCAL_TEXINPUTS)::
	endif
endif
ifdef LOCAL_BIBINPUTS
	ifdef BIBINPUTS
		export BIBINPUTS := $(LOCAL_BIBINPUTS):$(BIBINPUTS)
	else
		# see above for the explanation for appending `::'
		export BIBINPUTS := $(LOCAL_BIBINPUTS)::
	endif
endif
ifdef LOCAL_BSTINPUTS
	ifdef BSTINPUTS
		export BSTINPUTS := $(LOCAL_BSTINPUTS):$(BSTINPUTS):
	else
		# see above for the explanation for appending `::'
		export BSTINPUTS := $(LOCAL_BSTINPUTS)::
	endif
endif
TEX_INCLUDES = $(wildcard latex/*.tex)
TEX_SRC = $(wildcard *.tex)
BIB_FILES = $(wildcard *.bib) $(wildcard Bib/*.bib)

XFIG_FILES = $(wildcard Figures/*.fig)
#XFIG_FILES = $(shell find ./Figures -name \*.fig)  If I want to use subdirs.
XFIG_PDFTEX_T = $(XFIG_FILES:fig=pdftex_t)
XFIG_TEMPS = $(wildcard Figures/*.bak) $(XFIG_FILES:fig=pdf) $(XFIG_PDFTEX_T)

DOT=$(wildcard Figures/*.dot)
#DOTEPS=$(DOT:dot=eps)
DOTPDF=$(DOT:dot=pdf)

NEATO=$(wildcard Figures/*.neato)
#NEATOEPS=$(NEATO:neato=eps)
NEATOPDF=$(NEATO:neato=pdf)

GNUPLOT_SRC = $(wildcard Figures/*.gnuplot)
GNUPLOT_TEX = $(GNUPLOT_SRC:gnuplot=tex)
#GNUPLOT_FIG = $(GNUPLOT_SRC:gnuplot=fig)
#GNUPLOTEPS=$(GNUPLOT:gnuplot=eps)
#GNUPLOTPDF=$(GNUPLOT:gnuplot=pdf)
GNUPLOT_OUTPUT = $(GNUPLOT_TEX) #$(GNUPLOT_FIG)

DIA_SRC = $(wildcard Figures/*.dia)
DIA_OUTPUT = $(DIA_SRC:dia=$(IMAGE_TYPE))

FIGURES = $(XFIG_PDFTEX_T) $(DOTPDF) $(NEATOPDF) $(GNUPLOT_OUTPUT) $(DIA_OUTPUT)

export latex_count=3

#.PHONY: debug
#debug: 
#	@echo $(PDF_VIEWER)

.PHONY: all
ifneq ($(notdir $(PDF_VIEWER)),xpdf)
all: $(PAPER)
else
all: $(PAPER) .xpdf-reload
endif

.PHONY: view
view: ${PAPER}
	${PDF_VIEWER} ${PAPER}

.xpdf-reload: $(PAPER)
	@touch $@
	@xpdf -remote $(PAPER) -raise $(PAPER) &

%.pdf: %.aux %.bbl
	@if [ ! -e $(PAPER) ] ; then\
	    pdflatex $(basename $<) ;\
	fi
	@while egrep -s 'Rerun (LaTeX|to get cross-references right)' $(<:aux=log) && [ $$latex_count -gt 0 ] ;\
	    do \
		echo "Rerunning pdflatex...." ;\
		pdflatex $(basename $<) > /dev/null;\
		latex_count=`expr $$latex_count - 1` ;\
	    done

.PRECIOUS: %.aux
%.aux: %.tex $(TEX_SRC) $(TEX_INCLUDES) $(BIB_FILES) $(FIGURES) 
	#TODO use basename? as in pdflatex $(basename $<)
	pdflatex $< #> /dev/null

.PRECIOUS: %.$(IMAGE_TYPE)
%.$(IMAGE_TYPE): %.dia
	dia -t $(IMAGE_TYPE) $<

.PRECIOUS: %.pdf
%.pdf: %.eps
	epstopdf $<

%.eps: %.dot
	dot $< -Tps > $@

%.eps: %.neato
	neato -Gepsilon=.000000001 $< -Tps > $@

.PRECIOUS: %.bbl
%.bbl: %.tex %.aux $(BIB_FILES)
ifneq ($(strip $(BIB_FILES)),)
	bibtex -min-crossrefs=100 $(basename $<)
endif
	@echo "" # manual NOP

.PRECIOUS: %.tex
%.tex: %.gnuplot
	gnuplot $< > $(<:gnuplot=tex)

#Without -p, graphics are not output, only text.
.PRECIOUS: %.pdftex_t
%.pdftex_t: %.fig
	fig2dev -Lpdftex -p0 $< > $(<:fig=pdf)
	fig2dev -Lpdftex_t -p$(<:fig=pdf) $< > $(<:fig=pdftex_t)

.PHONY: clean
clean:
	rm -f $(CURRENT).bbl $(CURRENT).blg $(CURRENT).log *.aux *.bak
	rm -f .xpdf-reload

.PHONY: cleaner
cleaner: clean
	rm -f $(CURRENT).pdf

.PHONY: cleanest
cleanest: cleaner
	rm -f *~ $(FIGURES)

todo:
	grep "TODO" -R *.tex
