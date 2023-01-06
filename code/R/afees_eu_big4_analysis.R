# ------------------------------------------------------------------------------
# Master Seminar Accounting WiSe 2022/23
#
# Example code for an analysis which accesses the big 4 audit fee premium
# for a sample of European publicly listed firms
#
# (C) Joachim Gassen - See LICENSE file for detail
# ------------------------------------------------------------------------------

# If you are new to R the below might be a good start:
# https://r4ds.had.co.nz.

# Some additional info on installing R (including videos) is also available here
# https://joachim-gassen.github.io/2021/03/get-a-treat/

library(tidyverse)
library(readxl)

# For a dive into the literarture on the determinants, the below can be 
# considered a seminal study and

# Simunic, D. (1980): The pricing of audit services: theory and evidence. 
# Journal of Accounting Research 18(1): 161–190, https://doi.org/10.2307/2490397

# And this is a recent meta study:

# Widmann, M., F. Follert and M. Wolz (2021): What is it going to cost? 
# Empirical evidence from a systematic literature review of audit fee 
# determinants. Management Review Quarterly 71, 455–489. 
# https://doi.org/10.1007/s11301-020-00190-w

# The below is not meant to be a thorough assessment of the big 4 audit 
# fee premium (no additional covariates etc.). Instead, it is designed
# as a didactical blue print for how to design inferential analyses.

# --- Read data and provided some descriptives on audit fees ------------

# You might need to adjust the path below if you are using this code
# outside of the repository.

afees_eu <- readRDS("data/generated/afees_eu_clean.rds")

# Remember - prior to running an inferential analysis, you should always
# conduct a careful exploratory analysis of the data (EDA).

# You can use ExPanD for this.

if (FALSE) {
  install.packages("ExPanDaR")
  library(ExPanDaR)
  ExPanD(
    afees_eu, 
    cs_id = c("entity_map_fkey", "isin", "entity_name"), 
    ts_id = "year",
    export_nb_option = TRUE
  )
}

# You can also use it online:
# https://jgassen.shinyapps.io/expand/ or
# https://trr266.wiwi.hu-berlin.de/shiny/expand/

# Now, we will turn to the inferential analysis
# Let us first look at some moments of our
# dependent variable audit fees (measured in million €)

mean(afees_eu$audit_fees)
median(afees_eu$audit_fees)
hist(afees_eu$audit_fees)


# Break it up by the two levels of our independent variables

afees_eu_big4 <- afees_eu %>% filter(big4)

mean(afees_eu_big4$audit_fees)
median(afees_eu_big4$audit_fees)
hist(afees_eu_big4$audit_fees)

afees_eu_non_big4 <- afees_eu %>% filter(!big4)

mean(afees_eu_non_big4$audit_fees)
median(afees_eu_non_big4$audit_fees)
hist(afees_eu_non_big4$audit_fees)


# Let's do a parametric and unparametric univariate test

t.test(afees_eu_big4$audit_fees, afees_eu_non_big4$audit_fees, var.equal = T)
wilcox.test(afees_eu_big4$audit_fees, afees_eu_non_big4$audit_fees)


# Audit fees, as many size driven firm data, are extremly right-skewed.
# Large firms have high audit fees. We will use log audit fees from now on 
# to address the effect of exponential growth

hist(afees_eu_big4$laudit_fees)
hist(afees_eu_non_big4$laudit_fees)

t.test(afees_eu_big4$laudit_fees, afees_eu_non_big4$laudit_fees, var.equal = T)
wilcox.test(afees_eu_big4$laudit_fees, afees_eu_non_big4$laudit_fees)


# --- Univariate Regression ----------------------------------------------------

mod_ols_plain <- lm(audit_fees ~ big4, data = afees_eu)
summary(mod_ols_plain)

mean(afees_eu_big4$audit_fees) - mean(afees_eu_non_big4$audit_fees)

ggplot(afees_eu, aes(x = as.numeric(big4), y = audit_fees)) + 
  geom_point() +
  geom_smooth(method = "lm") +
  theme_classic()

# Log model 

mod_ols_log <- lm(laudit_fees ~ big4, data = afees_eu)
summary(mod_ols_log)

ggplot(afees_eu, aes(x = as.numeric(big4), y = laudit_fees)) + 
  geom_point() +
  geom_smooth(method = "lm") +
  theme_classic()

# To interpret our coefficient as a percentage we take the exponential
# For further info (incl. videos):
# https://sites.google.com/site/curtiskephart/ta/econ113/interpreting-beta

mod_ols_log$coefficients
exp(mod_ols_log$coefficients[2]) - 1

# 892 % as an audit fee premium seems pretty big doesn't it`?


# --- OLS with log(assets) as control ------------------------------------------

mod_ols_log_size <- lm(laudit_fees ~ big4 + lassets, data = afees_eu)

ggplot(afees_eu_change, aes(x = lassets, y = laudit_fees, color = big4, group = big4)) + 
  geom_point(alpha = 0.1) +
  geom_smooth(method = "lm") +
  theme_classic()

summary(mod_ols_log_size)
exp(mod_ols_log_size$coefficients[2]) - 1

# 81 % - that sounds a little bit more realistic but still too large


# --- Fixed effect estimate ----------------------------------------------------

library(fixest)

mod_fe_log_size <- feols(laudit_fees ~ big4 + lassets | isin, data = afees_eu)
summary(mod_fe_log_size)

exp(mod_fe_log_size$coefficients[1]) - 1

# 23 % - this is driven by only those firms that change their auditor
# from big 4 to non-big 4

# How many firms do change their auditor type?

afees_eu_change <- afees_eu %>% group_by(isin) %>% filter(sd(big4) > 0)

n_distinct(afees_eu_change$isin)

# 733 

mod_fe_log_size_change <- feols(
  laudit_fees ~ big4 + lassets | isin, data = afees_eu_change
)
summary(mod_fe_log_size_change)

exp(mod_fe_log_size_change$coefficients[1]) - 1

# As you see: Results for this sub-sample are very similar to the much
# larger sub-sample

# --- Estimate for a sample containing only matched observations ---------------

library(MatchIt)

afees_eu$year <- as.factor(afees_eu$year)

afees_eu$pm <- unname(
  matchit(
    big4 ~ lassets, 
    exact = c("hq_iso2c", "ff12_ind", "year"), 
    data = afees_eu, caliper = 0.1
  )$weights
)

ggplot(afees_eu, aes(x = lassets, y = laudit_fees, color = as.factor(pm))) + 
  geom_point(alpha = 0.1) +
  theme_classic()

afees_eu_pm <- afees_eu %>% filter(pm == 1)

table(afees_eu_pm$year, afees_eu_pm$big4)
table(afees_eu_pm$hq_iso2c, afees_eu_pm$big4)

ggplot(afees_eu_pm, aes(x = lassets, y = laudit_fees, color = big4, group = big4)) + 
  geom_point(alpha = 0.1) +
  geom_smooth(method = "lm") +
  theme_classic()

mod_pmfe_log_size <- feols(laudit_fees ~ big4 + lassets | isin, data = afees_eu_pm)
summary(mod_pmfe_log_size)

confint(mod_pmfe_log_size)
cis <- .Last.value

exp(mod_pmfe_log_size$coefficients[1]) - 1
exp(cis[1,]) - 1

# The big 4 audit fee premium for European publicly listed firms, as assessed
# for a country, sector and sized matched sample of firms from the period 
# 2009-2020, is estimated to be within the confidence interval of 13 % and 26 % 
# (point estimate is 19 %).


# --- Yearly analysis ----------------------------------------------------------

mod_pmfe_log_size_by_year <- feols(
  laudit_fees ~ big4*year + lassets | isin, data = afees_eu_pm
)
summary(mod_pmfe_log_size_by_year)

# The big 4 audit premium seems to be relatively stable over time


# --- By country analysis ------------------------------------------------------

# Limit sample to countries with at least 100 firms

afees_eu_pm_lc <- afees_eu_pm %>% 
  group_by(hq_iso2c) %>% 
  filter(n_distinct(isin) >= 100)

mod_pmfe_log_size_by_iso2c <- feols(
  laudit_fees ~ i(hq_iso2c, big4) + lassets | isin + year, data = afees_eu_pm_lc
)
summary(mod_pmfe_log_size_by_iso2c)

# There seems to be some cross-country variation (Italy and Sweden have no
# significant discount - but small samples)
