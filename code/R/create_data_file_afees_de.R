library(dplyr)
library(readr)
library(ExPanDaR)

afees <- readRDS("data/generated/afees_eu_clean.rds")
afees_de <- afees %>% filter(hq_iso2c == "DE") 

# ExPanD(afees_de, cs_id = c("entity_map_fkey", "isin", "entity_name"), ts_id = "year")

cbook <- read_csv(
  "data/external/codebook_audit_fees_clean.csv", show_col_types = FALSE
)

writexl::write_xlsx(
  list(Data = afees_de, Codebook = cbook), "output/afees_de.xlsx"
)

