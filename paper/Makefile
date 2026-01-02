# Paper build automation

PAPER := mhx_ternary_whitepaper
LATEX := pdflatex
BIBTEX := bibtex

.PHONY: all pdf clean watch

all: pdf

pdf: $(PAPER).pdf

$(PAPER).pdf: $(PAPER).tex
	$(LATEX) $(PAPER)
	$(BIBTEX) $(PAPER) || true
	$(LATEX) $(PAPER)
	$(LATEX) $(PAPER)

clean:
	rm -f *.aux *.bbl *.blg *.log *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz
	rm -f $(PAPER).pdf

watch:
	@echo "Watching for changes..."
	@while true; do \
		inotifywait -q -e modify $(PAPER).tex; \
		make pdf; \
	done

# Quick preview without full rebuild
quick:
	$(LATEX) $(PAPER)

# Full rebuild from scratch
rebuild: clean pdf
