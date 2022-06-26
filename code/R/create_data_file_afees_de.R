suppressMessages({
  library(dplyr)
  library(readr)
})

message("Preparing BaSem data... ", appendLF = FALSE)

afees <- readRDS("data/generated/afees_eu_clean.rds")
afees_de <- afees %>% filter(hq_iso2c == "DE") 

cbook <- read_csv(
  "data/external/codebook_audit_fees_clean.csv", show_col_types = FALSE
)

writexl::write_xlsx(
  list(Data = afees_de, Codebook = cbook), "output/afees_de.xlsx"
)

message("done!")
