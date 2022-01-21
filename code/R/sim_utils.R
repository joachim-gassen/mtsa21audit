# ------------------------------------------------------------------------------
# Some utility functions for our simulations   
# ------------------------------------------------------------------------------


plot_hist <- function(sr) {
  ggplot(sr, aes(x = coef)) + 
    geom_histogram(aes(y  = ..density..), color = NA, fill = my_palette[2]) + 
    geom_function(
      fun = dnorm, color = my_palette[1],
      args = list(mean = mean(sr$coef), sd = sd(sr$coef))
    ) + 
    labs(x = "Coefficient", y = "Density") +
    theme_minimal() + theme(
      text = element_text(family = "serif")
    )      
}


table_sig_runs <- function(sr) {
  df <- sr %>%
    summarise(
      `Significantly positive` = scales::percent(mean(lb > 0 & ub > 0), accuracy = 0.01),
      `Significantly negative` = scales::percent(mean(lb < 0 & ub < 0), accuracy = 0.01)
    )
  
  kbl(t(df), booktabs = T) %>% kable_styling(latex_options = "hold_position")
}


plot_cis <- function(sr, ymin = NA, ymax = NA, teffect = 0) {
  df <- sr %>%
    arrange(coef) %>%
    mutate(run = 1:N_SIM_RUNS) %>%
    pivot_longer(c("coef", "ub", "lb"), names_to = "stat", values_to = "value")
  
  p <- ggplot(df, aes(x = run)) + 
    geom_line(aes(y = value, color = stat, lty = stat)) +
    labs(x = "Simulation run (sorted by coefficient)", y = "Effect confidence interval", color = "") +
    scale_color_manual(values = c(my_palette[2], my_palette[3], my_palette[3])) + 
    scale_linetype_manual(values = c(1, 2, 2)) + 
    geom_hline(yintercept = teffect, lty = 3, color = my_palette[1]) +
    theme_minimal() + theme(
      legend.position = "none",
      text = element_text(family = "serif")
    )
  if (!is.na(ymin) | !is.na(ymax)) p <- p + ylim(ymin, ymax)
  p
}
