# --- Header -------------------------------------------------------------------
# Cleans European audit fee data 
#
# See LICENSE file for details 
# ------------------------------------------------------------------------------
library(dplyr)
library(readr)
library(lubridate)
library(ExPanDaR)

afees_eu <- readRDS("data/generated/afees_eu.rds")
ff12 <- read_csv(
  "data/external/fama_french_12_industries.csv", col_types = cols()
)

afees_eu_desc <- afees_eu %>%
  group_by(entity_map_fkey, isin, entity_name, audit_fee_fiscal_year_end) %>%
  arrange(entity_map_fkey, isin, entity_name, audit_fee_fiscal_year_end) %>%
  summarise(
    year = unique(year(audit_fee_fiscal_year_end)),
    sic = unique(sic_code_fkey),
    hq_iso2c = unique(headquarter_country_code), 
    big4 = any(1:4 %in% auditor_fkey),
    audit_fees_eur = sum(audit_fees_eur),
    total_non_audit_fees_eur = sum(total_non_audit_fees_eur), 
    total_fees_eur = sum(total_fees_eur), 
    market_cap_eur = mean(market_cap_eur, na.rm = TRUE), 
    revenues_eur = mean(revenue_eur, na.rm = TRUE),
    assets_eur = mean(assets_eur, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  group_by(entity_map_fkey) %>%
  filter(
    is.na(lag(audit_fee_fiscal_year_end)) | 
      ((month(audit_fee_fiscal_year_end) == 
        month(lag(audit_fee_fiscal_year_end))) &
          (day(audit_fee_fiscal_year_end) == 
             day(lag(audit_fee_fiscal_year_end))))
  ) %>%
  select(-audit_fee_fiscal_year_end) 

dups <- afees_eu_desc %>%
  group_by(entity_map_fkey, year) %>%
  filter(n() > 1)

if (nrow(dups) > 0) stop(
  "Audit fee descriptive data has duplicates. This should not happen"
)

afees_eu_clean <- afees_eu_desc %>%
  ungroup() %>%
  filter(year > 2008, year < 2021) %>%
  mutate(
    ltotal_fees = log((1 + total_fees_eur)),
    laudit_fees = log((1 + audit_fees_eur)),
    lnaudit_fees = log((1 + total_non_audit_fees_eur)),
    lassets = log(assets_eur),
    lrevenues = log(revenues_eur),
    lmarket_cap = log(market_cap_eur),
    tfees_ta = total_fees_eur/assets_eur
  ) %>%
  left_join(ff12, by = "sic") %>%
  filter(
    assets_eur > 0, revenues_eur > 0, market_cap_eur > 0,
    total_fees_eur > 0, audit_fees_eur > 0, !is.na(ff12_ind)
  )  %>%
  select(
    entity_map_fkey, isin, entity_name, hq_iso2c, ff12_ind, year, lassets, lrevenues, 
    lmarket_cap, big4, laudit_fees, lnaudit_fees, ltotal_fees
  ) %>% group_by(hq_iso2c) %>% filter(n() >= 1000) %>% ungroup()

if (FALSE) {
  ExPanD(
    afees_eu_clean, cs_id = c("entity_map_fkey", "isin", "entity_name"), ts_id = "year"
  )
  
  cfg_list <- readRDS("data/external/expand_afee_eda.rds")
  
  ExPanD(
    afees_eu_clean, 
    cs_id = c("entity_map_fkey", "isin", "entity_name"), ts_id = "year",
    config_list = cfg_list, export_nb_option = TRUE
  )
}


