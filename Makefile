# If you are new to Makefiles: https://makefiletutorial.com

DATA := output/afees_eu.xlsx output/afees_eu.csv

TARGETS :=  $(DATA)

EXTERNAL_DATA := data/external/fama_french_12_industries.csv \
	data/external/fama_french_48_industries.csv

WRDS_DATA := data/pulled/audit_analytics_afee_data.rds \
	data/pulled/audit_analytics_cblock_data.rds

GENERATED_DATA := data/generated/afees_eu.rds

RSCRIPT := Rscript --encoding=UTF-8

.phony: all clean very-clean dist-clean

all: $(TARGETS)

clean:
	rm -f $(TARGETS)
	rm -f $(GENERATED_DATA)
	
very-clean: clean
	rm -f $(WRDS_DATA)

dist-clean: very-clean
	rm config.csv
	
config.csv:
	@echo "To start, you need to copy _config.csv to config.csv and edit it"
	@false
	
$(WRDS_DATA): code/R/pull_wrds_data.R code/R/read_config.R config.csv
	$(RSCRIPT) code/R/pull_wrds_data.R

$(GENERATED_DATA): $(WRDS_DATA) $(EXTERNAL_DATA) code/R/prepare_data.R
	$(RSCRIPT) code/R/prepare_data.R

$(RESULTS):	$(GENERATED_DATA) code/R/do_analysis.R
	$(RSCRIPT) code/R/do_analysis.R

$(DATA): $(GENERATED_DATA)

$(PAPER): doc/paper.Rmd doc/references.bib $(RESULTS) 
	$(RSCRIPT) -e 'library(rmarkdown); render("doc/paper.Rmd")'
	mv doc/paper.pdf output
	rm -f doc/paper.ttt doc/paper.fff
	
$(PRESENTATION): doc/presentation.Rmd $(RESULTS) doc/beamer_theme_trr266.sty
	$(RSCRIPT) -e 'library(rmarkdown); render("doc/presentation.Rmd")'
	mv doc/presentation.pdf output
