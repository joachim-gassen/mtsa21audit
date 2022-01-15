# If you are new to Makefiles: https://makefiletutorial.com

RAW_DATA := output/afees_eu.xlsx output/afees_eu.csv 
DOCS := output/afees_eu_eda.pdf output/afees_eu_teffect.pdf

TARGETS :=  $(RAW_DATA) $(DOCS)

EXTERNAL_DATA := data/external/fama_french_12_industries.csv \
	data/external/fama_french_48_industries.csv

WRDS_DATA := data/pulled/audit_analytics_afee_data.rds \
	data/pulled/audit_analytics_cblock_data.rds

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

$(RAW_DATA): $(WRDS_DATA) code/R/prepare_data.R
	$(RSCRIPT) code/R/prepare_data.R

data/generated/afees_eu_clean.rds: $(EXTERNAL_DATA) \
	data/generated/afees_eu.rds code/R/clean_data.R 
	$(RSCRIPT) code/R/clean_data.R

output/afees_eu_eda.pdf: doc/afees_eu_eda.Rmd data/generated/afees_eu_clean.rds 
	$(RSCRIPT) -e 'library(rmarkdown); render("doc/afees_eu_eda.Rmd", quiet = TRUE)'
	mv doc/afees_eu_eda.pdf output
	cp output/afees_eu_eda.pdf afees_eu_eda.pdf
	rm -f doc/afees_eu_eda.ttt doc/afees_eu_eda.fff doc/afees_eu_eda.log
	
output/afees_eu_teffect.pdf: doc/afees_eu_teffect.Rmd data/generated/afees_eu_clean.rds 
	$(RSCRIPT) -e 'library(rmarkdown); render("doc/afees_eu_teffect.Rmd", quiet = TRUE)'
	mv doc/afees_eu_teffect.pdf output
	cp output/afees_eu_teffect.pdf afees_eu_teffect.pdf
	rm -f doc/afees_eu_teffect.ttt doc/afees_eu_teffect.fff doc/afees_eu_teffect.log
