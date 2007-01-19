FILES = ${shell ls *.tex}
DIAGRAMS = ${shell ls *.dia}
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
	dia -t ${IMAGE_TYPE} ${DIAGRAMS}
	touch .make.images

${OUTPUT}: $(FILES) images
	$(LATEX) latex/${TEMPLATE}
	$(LATEX) latex/${TEMPLATE}
    ifneq  (${TEMPLATE}.pdf, ${OUTPUT})
		mv ${TEMPLATE}.pdf ${OUTPUT}
    endif

clean:
	rm -f *.bak *.aux *.out *.log *.toc *.pdf *.ps *.png .make.*

spellcheck:
	for f in `ls *.tex`; do aspell -t -c $$f; done


