library(tidyverse)
set.seed(142)
library(modelsummary)

source("code/R/sim_utils.R")

N_SUBJECTS <- 1000
N_SIM_RUNS <- 1000

my_palette <- RColorBrewer::brewer.pal(8, "Set1")
options(
  ggplot2.discrete.colour = my_palette, 
  ggplot2.discrete.fill = my_palette
)

subject_pool <- tibble(
  subject_id = replicate(N_SUBJECTS, paste0(sample(LETTERS, 12, replace = T), collapse = "")),
  male = sample(c(T,F), N_SUBJECTS, replace = T),
  age = round(truncnorm::rtruncnorm(N_SUBJECTS, 18, 65, 30, 10))
)

ggplot(subject_pool) +
  geom_density((aes(x = age, group = male, color = male))) + theme_classic()

create_random_treatment <- function(df, n = 100) {
  df <- sample_n(df, n)
  df$sample_id <- paste0(sample(letters, 12, replace = T), collapse = "") 
  df$treated <- sample(c(T,F), n, replace = T)
  return(df)
}

plot_samples <- function(df) {
  ggplot(df) +
    geom_density((aes(x = age, color = male, linetype = treated))) +
    facet_wrap(vars(sample_id), ) +
    theme_classic() +
    theme(
      strip.background = element_blank(),
      strip.text.x = element_blank()
    )
}

stat_samples <- function(df) {
  df %>%
    mutate(sample_id = as.numeric(as.factor(sample_id))) %>%
    group_by(sample_id, treated) %>%
    summarise(
      n = n(),
      pct_male = sum(male)/n(),
      mean_age = mean(age),
      sd_age = sd(age),
      .groups = "drop"
    )
}

random_treated_samples <- bind_rows(
  replicate(9, create_random_treatment(subject_pool, 100),simplify = F)
)

plot_samples(random_treated_samples)
stat_samples(random_treated_samples)

create_stratified_treatment <- function(df, n = 100) {
  df <- sample_n(df, n)
  df %>%
    mutate(
      sample_id = paste0(sample(letters, 12, replace = T), collapse = ""),
      age_bin = ntile(age, round(n/10))
    ) %>%
    group_by(male, age_bin) %>%
    slice_sample(prop = 1) %>%
    ungroup() %>%
    select(-age_bin) %>%
    mutate(
      treated = rep(sample(c(T, F)), ceiling(n/2))[1:n]
    ) %>%
    slice_sample(prop = 1)
}


stratified_treated_samples <- bind_rows(
  replicate(9, create_stratified_treatment(subject_pool, 100),simplify = F)
)

plot_samples(stratified_treated_samples)
stat_samples(stratified_treated_samples)

seed_treatment_effect <- function(df, esize = 0.1) {
  df %>%
    mutate(y = rnorm(n()) + treated*esize)
}

est_teffect <- function(
  esize = 0.1, n = 100, controls = FALSE, confound = FALSE,
  sp = subject_pool, 
  sample_func = create_stratified_treatment
) {
  if (confound) {
    df <- sample_func(sp, n) %>%
      mutate(
        confound_effect = rnorm(n()) + male + ((age - 18)/47),
        y = rnorm(n()) + confound_effect + treated*esize
      )
    
  } else {
    df <- sample_func(sp, n) %>%
      mutate(y = rnorm(n()) + treated*esize)
  }

  if (controls) mod <- fixest::feols(y ~ treated + male + age, data = df)
  else mod <- fixest::feols(y ~ treated, data = df)
  broom::tidy(mod, conf.int = T) %>%
    filter(term == "treatedTRUE") %>%
    select(
      coef =estimate,
      lb = conf.low,
      ub = conf.high
    )
}

# power_sim <- bind_rows(replicate(N_SIM_RUNS, est_teffect(), simplify = F))

# plot_hist(power_sim)
# plot_cis(power_sim, teffect = 0.1) 


est_power <- function(
  teffect, n, controls = FALSE, confound = FALSE, 
  tassignment = "stratified"
) {
  sample_func <- ifelse(
    tassignment == "stratified", 
    create_stratified_treatment, create_random_treatment
  )
  bind_rows(
    replicate(
      N_SIM_RUNS, 
      est_teffect(teffect, n, controls, confound, sample_func = sample_func), 
      simplify = F)
    ) %>%
    summarise(
      mean_coef = mean(coef),
      sd_coef = sd(coef),
      rmse = sqrt(mean((coef - teffect)^2)),
      power = mean(lb > 0)
    )
}

pa_fname <- "data/generated/exp_power_analysis_full.rds"

if (!file.exists(pa_fname)) {
  power_analysis <- expand_grid(
    teffect = c(0.3, 0.5, 1),
    n = c(30, 50, 100, 300, 500),
    controls = c(TRUE, FALSE),
    confound = c(TRUE, FALSE),
    tassignment = c("stratified", "random"),
  ) %>%
    rowwise() %>%
    mutate(
      est_power = est_power(teffect, n, controls, confound, tassignment)
    ) %>%
    unnest(est_power)
  
  saveRDS(power_analysis, pa_fname)
} else power_analysis <- readRDS(pa_fname)

ggplot(
  power_analysis, 
  aes(
    x = n, y = power, color = as.factor(teffect), linetype = tassignment, 
    shape = confound, group = interaction(teffect, tassignment, confound)
  )
) +
  geom_point() +
  geom_line() +
  scale_y_continuous(labels = scales::label_percent()) +
  labs (
    x = "Sample size", y = "Power", linetype = "Assignment", 
    color = "Effect size", shape = "Confounder present?"
  ) +
  theme_classic() +
  theme(legend.position = "bottom")

