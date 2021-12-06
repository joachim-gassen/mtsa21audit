library(tidyverse)
library(ExPanDaR)

# This is the code that we used in the session on data preparation


# --- Audit fee data -----------------------------------------------------------

# Exploring the data organization of the audit fee data

afees_eu <- readRDS("data/generated/afees_eu.rds")

df <- afees_eu %>%
  group_by(entity_map_fkey, audit_fee_fiscal_year_end) %>%
  summarise(nobs = n())

table(df$nobs)

# Multiple observation per client year

df <- afees_eu %>%
  group_by(entity_map_fkey, audit_fee_fiscal_year_end, auditor_fkey) %>%
  summarise(nobs = n())

table(df$nobs)

# Data is organized by client fiscal year and auditor

# Which countries do have many joint audits? Let's check!

audit_ctry <- afees_eu %>%
  group_by(entity_map_fkey, headquarter_country, audit_fee_fiscal_year_end) %>%
  summarise(
    nobs = n()
  ) %>%
  group_by(headquarter_country) %>%
  summarise(
    sh_dual_audits = sum(nobs == 2)/n()
  ) %>%
  arrange(-sh_dual_audits)

head(audit_ctry, 10)

# Many "French" countries. This makes sense. 
# See, e.g.: https://doi.org/10.1080/09638180.2014.998016 

# Now let's have a look at the distribution of audit fees.

ggplot(afees_eu, aes(x = total_fees_eur)) + 
  geom_histogram(bins = 100) + theme_minimal()

# Highly positive/right skewed. This is not surprising as
# audit fees are larger for larger firms and firms become
# large over time as they grow exponentially. Taking
# a log reduces the skewness of the distribution.

ggplot(afees_eu , aes(x = log(total_fees_eur))) + 
  geom_histogram(bins = 100) + theme_minimal()


# An example for a 1:1 left join based on a foreign key
# Let's merge Fama/French industry sectors to the audit
# fee data. This is helpful to compare the data across
# broad industry sectors.

ff12 <- read_csv(
  "data/external/fama_french_12_industries.csv", col_types = cols()
)

df <- left_join(afees_eu, ff12, by = c("sic_code_fkey" = "sic")) %>%
  select(entity_name, sic_code_fkey, ff12_ind) %>%
  distinct()


# --- Financial reporting data -------------------------------------------------

# Size-deflating data can make it more informative
# To see this consider this example that uses financial reporting
# data from a short panel of U.S. Russell 3000 firms.

r3 <- russell_3000 %>%
  mutate(cash = cash_ta * toas)

# The following plot won't tell you much as cash levels reported
# on the balance sheet simply reflect the size of the firms

ggplot(r3, aes(x = cash)) + 
  geom_histogram(bins = 100) + theme_minimal()

# Deflating cash by total assests transforms this measure into
# a meaningful percentage that is nicely bounded to [0,1]

ggplot(r3, aes(x = cash/toas)) + 
  geom_histogram(bins = 100) + theme_minimal()

# But deflating can also be dangerous if you a pick an ill-defined
# deflator. Take book value of equity as an example

ggplot(r3, aes(x = roe, group = equity > 0)) +
  geom_histogram() + theme_minimal()

# Now, this variable is plagued by outliers.
# Let's winsorize the data to the top and bottom percentile.
# If you want to learn more about outliers check:
# https://joachim-gassen.github.io/2021/07/outliers/

r3$roe <- treat_outliers(r3$roe, percentile = 0.01) 
ggplot(r3, aes(x = roe)) +
  geom_histogram() + theme_minimal()

# The distribution of the variable looks better now. But is it informative,
# given that book value of equity is distributed around zero, meaning that
# it can be negative?

ggplot(r3, aes(x = roe, fill = equity > 0)) +
  geom_histogram() + theme_minimal()

# No! Firms having negative book value of equity and reporting a loss are
# characterized as having positive ROE. This is clearly not what you want!
# The morale of the story: Think about the whole distribution of your data
# when defining your variables!

