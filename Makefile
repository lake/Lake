default:	.make.paper
view:		${OUTPUT}
	$(VIEWER) $(OUTPUT)

images:		.make.images
.make.images:	${DIAGRAMS}
    ifneq  (${DIAGRAMS},)
		dia -t ${IMAGE_TYPE} ${DIAGRAMS}
    endif
	touch .make.images

.make.paper: $(FILES) .make.images
	$(LATEX) ${PAPER}
	$(LATEX) ${PAPER}
	touch .make.paper

clean:
	rm -f *.bak *.aux *.out *.log *.toc *.pdf *.ps *.png .make.* diagrams/*.png

todo:
	grep "TODO"  -R *.tex
