# --- Header -------------------------------------------------------------------
# Cleans European audit fee data 
#
# See LICENSE file for details 
# ------------------------------------------------------------------------------
library(dplyr)
library(lubridate)
library(readr)
library(writexl)

cblock <- readRDS("data/pulled/audit_analytics_cblock_data.rds")
afee <- readRDS("data/pulled/audit_analytics_afee_data.rds")

afees_eu <- cblock %>%
  select(
    company_fkey, entity_map_fkey, entity_name, name_normalized, short_name, 
    headquarter_city,  headquarter_country, headquarter_country_code, 
    fiscal_year_end, reporting_currency, sic_code_fkey, sic_description,  
    naics_code_fkey, naics_description, isin, ipo_date, is_active, 
    primary_exchange, primary_exchange_id,  primary_exchange_ticker, 
    exchange_submarket_id, submarket_display_name, is_eu_regulated_submarket
  ) %>% 
  left_join(
    afee %>% select(
      entity_map_fkey, auditor_network, audit_fee_fkey, source_filing_type,           
      source_filing_fiscal_year_end, audit_fee_fiscal_year_end, 
      auditor_name, auditor_fkey, auditor_home_office_city,
      auditor_home_office_state, auditor_affiliate_name,
      auditor_affiliate_fkey, auditor_aff_home_office_city,
      auditor_aff_home_office_state, audit_fees_split,               
      audit_fees_eur, audit_related_fees_eur,       
      tax_related_fees_eur, other_fees_eur, total_non_audit_fees_eur,
      total_fees_eur, market_cap_as_of_date, market_cap_eur,
      financials_as_of_date, revenue_eur, assets_eur,
      restated_fee, most_recent_fee
    ),
    by = "entity_map_fkey"
  ) %>% filter(!is.na(total_fees_eur), most_recent_fee == 1) %>%
  select(-most_recent_fee) %>%
  arrange(entity_map_fkey, audit_fee_fiscal_year_end)

dups <- afees_eu %>%
  group_by(entity_map_fkey, audit_fee_fiscal_year_end, auditor_fkey) %>%
  filter(n() > 1)

if (nrow(dups) > 0) stop(paste(
  "Audit Analytics fee data is not organized by firm, fye, and auditor.",
  "Manual data check required."
))

saveRDS(afees_eu, "data/generated/afees_eu.rds")
write_csv(afees_eu, "output/afees_eu.csv")
write_xlsx(afees_eu, "output/afees_eu.xlsx")
