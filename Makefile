FILES = ${shell ls *.tex 2> /dev/null}
DIAGRAMS = ${shell ls diagrams/*.dia 2> /dev/null}
TEMPLATE = default
OUTPUT = ${TEMPLATE}.pdf
LATEX = pdflatex
VIEWER = kpdf
IMAGE_TYPE = png

LATEX_DIR=latex


include local-options



default:	${OUTPUT}
view:		${OUTPUT}
	$(VIEWER) $(OUTPUT)

images:		.make.images
.make.images:	${DIAGRAMS}
    ifneq  (${DIAGRAMS},)
		dia -t ${IMAGE_TYPE} ${DIAGRAMS}
    endif
	touch .make.images

${OUTPUT}: $(FILES) .make.images
	$(LATEX) latex/${TEMPLATE}
	$(LATEX) latex/${TEMPLATE}
    ifneq  (${TEMPLATE}.pdf, ${OUTPUT})
		mv ${TEMPLATE}.pdf ${OUTPUT}
    endif

clean:
	rm -f *.bak *.aux *.out *.log *.toc *.pdf *.ps *.png .make.* diagrams/*.png

todo:
	grep "TODO"  -R *.tex
