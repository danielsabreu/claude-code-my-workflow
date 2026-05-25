###############################################################
# 02_factor_estimation.R
# Financial Cycle Replication Package — Abreu & De Lorenzo Buratta
#
# INPUT:  scripts/R/_outputs/df_model.RData
# OUTPUT: scripts/R/_outputs/df_dfm.RData
#         scripts/R/_outputs/df_ic_avar.RData
#         scripts/R/_outputs/df_loadings.RData
#         scripts/R/_outputs/df_dec.RData
#         scripts/R/_outputs/table_r2.xlsx
#         Figures/var_exp.pdf
#         Figures/factor_medians.pdf
#         Figures/ci_medians.pdf
#         Figures/regimes_graph.pdf
#         (Panel figures for Appendices A and C: see 05_panel_figures.R)
#
# Description: Estimates DFM for each country using PCA, QML, and
# two-step estimator. Computes confidence intervals, variance explained,
# loadings, and regime classifications.
###############################################################

library(here)
source(here::here("scripts", "R", "auxiliary", "_paths.R"))
source(file.path(AUX_DIR, "_theme.R"))

library(vars)
library(dfms)
library(seasonal)
library(urca)
library(xts)
library(dplyr)
library(tidyr)
library(zoo)
library(readxl)
library(writexl)
library(mFilter)
library(reshape2)
library(data.table)
library(ggplot2)
library(purrr)
library(scales)

source(file.path(AUX_DIR, "dfm_conf_int.R"))
source(file.path(AUX_DIR, "avar.R"))
source(file.path(AUX_DIR, "normalise.R"))
source(file.path(AUX_DIR, "ICr_c.R"))

###############################################################
# Load data
###############################################################

load(file.path(OUTPUTS_DIR, "df_model.RData"))

###############################################################
# Factor estimation and diagnostics
###############################################################

df_model <- lapply(df_model, function(df) {
  df[df$obstime >= "1990-03-31", ]
})

# Factor model estimation (PCA, QML, two-step)
df_dfm <- df_model %>%
  lapply(., function(df) {
    obstime <- df[, 1]
    dfm <- DFM(df[, 2:ncol(df)], r = 1, p = 4)
    out <- data.frame(
      obstime = as.Date(obstime),
      pca     = as.numeric(dfm$F_pca),
      qml     = as.numeric(dfm$F_qml),
      tstep   = as.numeric(dfm$F_2s)
    )
    return(out)
  })

# IC and asymptotic variance
df_ic_avar <- df_model %>%
  lapply(., function(df) {
    ic      <- ICr_c(df[, 2:ncol(df)])
    var_exp <- ic$eigenvalues[1] / sum(ic$eigenvalues)
    avar    <- avar(df)
    list(ic = ic, avar = avar, loadings = loadings, var_exp = var_exp)
  })

# Align factor sign with DFM PCA reference.
# Bands are centred at zero, so only the factor column needs to be flipped;
# factor.p90/p10 and the regime thresholds are sign-invariant.
df_ic_avar <- map2(df_ic_avar, df_dfm, function(.x, .y) {
  if (cor(.x$avar$factor, .y$pca) < 0) {
    .x$avar$factor <- .x$avar$factor * -1
  }
  list(ic = .x$ic, avar = .x$avar, loadings = .x$loadings, var_exp = .x$var_exp)
})

# Regime classification
df_regimes <- lapply(names(df_ic_avar), function(country) {
  df <- df_ic_avar[[country]]$avar
  df$regime <- ifelse(
    df$factor > max(df$factor.p90.mean, df$factor.p10.mean), "Elevated",
    ifelse(df$factor < min(df$factor.p90.mean, df$factor.p10.mean), "Subdued", "Neutral")
  )
  return(df)
})
names(df_regimes) <- names(df_model)

# Factor loadings
df_loadings <- df_model %>%
  lapply(., function(df) {
    list(loadings = DFM(df[, 2:ncol(df)], r = 1, p = 4)$C)
  })

# Merged dataset for decomposition
df_dec <- lapply(seq_along(df_model), function(i) {
  dt_model <- as.data.table(df_model[[i]])
  dt_dfm   <- as.data.table(df_dfm[[i]])
  dt_model[, obstime := as.Date(obstime)]
  dt_dfm[,   obstime := as.Date(obstime)]
  setDF(merge(dt_model, dt_dfm, by = "obstime", all.x = TRUE))
})
names(df_dec) <- names(df_model)

# R-squared of the factor across variables
df_r2 <- lapply(df_dec, function(df) {
  var_r2 <- data.frame(matrix(NA, nrow = 1, ncol = ncol(df) - 1))
  colnames(var_r2) <- colnames(df)[-1]
  for (i in 2:ncol(df)) {
    model <- lm(pca ~ df[[i]], data = df)
    var_r2[[i - 1]] <- summary(model)$r.squared
  }
  var_r2 <- var_r2[, !(colnames(var_r2) %in% c("pca", "qml", "tstep"))]
  var_r2 <- as.data.frame(var_r2)
  var_r2$mean_r2 <- mean(unlist(var_r2), na.rm = TRUE)
  var_r2$sd_r2   <- sd(unlist(var_r2),   na.rm = TRUE)
  return(var_r2)
})

###############################################################
# Save intermediates
###############################################################

save(df_dec,      file = file.path(OUTPUTS_DIR, "df_dec.RData"))
save(df_ic_avar,  file = file.path(OUTPUTS_DIR, "df_ic_avar.RData"))
save(df_loadings, file = file.path(OUTPUTS_DIR, "df_loadings.RData"))
save(df_dfm,      file = file.path(OUTPUTS_DIR, "df_dfm.RData"))
save(df_regimes,  file = file.path(OUTPUTS_DIR, "df_regimes.RData"))
message("Saved: df_dec, df_ic_avar, df_loadings, df_dfm, df_regimes")

###############################################################
# Figures and tables
###############################################################

# Figure 1: Variance explained
df_var_exp <- data.frame(
  country = names(df_ic_avar),
  var_exp = sapply(df_ic_avar, `[[`, "var_exp"),
  stringsAsFactors = FALSE
)
df_var_exp$country <- factor(df_var_exp$country,
                             levels = sort(unique(df_var_exp$country)))

p_varexp <- ggplot(df_var_exp, aes(x = country, y = var_exp)) +
  geom_col(fill = COLOURS$pca, width = 0.6) +
  geom_text(aes(label = sprintf("%.2f", var_exp)), vjust = -0.4, size = 2.3) +
  geom_hline(yintercept = mean(df_var_exp$var_exp),
             linetype = "dashed", linewidth = 0.5, colour = "grey40") +
  scale_y_continuous(limits = c(0, 1), labels = scales::percent_format(accuracy = 1)) +
  labs(x = "", y = "Share of variance explained") +
  theme_paper()
save_tikz(p_varexp, "var_exp.tikz", width = 6.27, height = 2.8)

# Figure 2: Median financial cycle
df_factor_graph <- bind_rows(df_dfm, .id = "country")
medians          <- aggregate(cbind(pca, qml, tstep) ~ obstime, data = df_factor_graph, FUN = median)
quantiles_by_period <- aggregate(
  cbind(pca, qml, tstep) ~ obstime, data = df_factor_graph,
  FUN = function(x) c(Q1 = quantile(x, 0.25, na.rm = TRUE), Q3 = quantile(x, 0.75, na.rm = TRUE))
)
quantiles_by_period <- do.call(data.frame, quantiles_by_period)
colnames(quantiles_by_period) <- c("obstime", "pca_Q25", "pca_Q75", "qml_Q25", "qml_Q75", "tstep_Q25", "tstep_Q75")
quantiles_combined <- data.frame(
  obstime = quantiles_by_period$obstime,
  Q25 = apply(quantiles_by_period[, c("pca_Q25", "qml_Q25", "tstep_Q25")], 1, min),
  Q75 = apply(quantiles_by_period[, c("pca_Q75", "qml_Q75", "tstep_Q75")], 1, max)
)
medians_long <- reshape2::melt(medians, id.vars = "obstime", variable.name = "variable", value.name = "median_value")

p_medians <- ggplot() +
  geom_ribbon(data = quantiles_combined,
              aes(x = obstime, ymin = Q25, ymax = Q75),
              fill = COLOURS$pca, alpha = 0.15) +
  geom_line(data = medians_long,
            aes(x = obstime, y = median_value, colour = variable,
                linetype = variable), linewidth = 0.7) +
  scale_colour_manual(values = c(pca = COLOURS$pca, qml = COLOURS$qml, tstep = COLOURS$tstep),
                      labels = c(pca = "PCA", qml = "QML", tstep = "Two-step")) +
  scale_linetype_manual(values = c(pca = "solid", qml = "dashed", tstep = "dotted"),
                        labels = c(pca = "PCA", qml = "QML", tstep = "Two-step")) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  scale_x_date(date_labels = "%Y", date_breaks = "4 years") +
  labs(x = "", y = "Standardised units", colour = "", linetype = "") +
  theme_paper()
save_tikz(p_medians, "factor_medians.tikz", width = 6.27, height = 3.0)

# Figure 3: Confidence intervals — median across countries
# Ribbon  : median_factor(t) +/- median_ci_half(t) across countries
# Dashed  : mean over time of the above ribbon bounds
df_ci_all <- bind_rows(lapply(names(df_ic_avar), function(country) {
  df         <- df_ic_avar[[country]]$avar
  df$ci_half <- (df$factor.p90 - df$factor.p10) / 2   # always positive
  df$country <- country
  return(df)
}))

df_ci_median <- aggregate(
  cbind(factor, ci_half) ~ obstime,
  data = df_ci_all,
  FUN  = median,
  na.rm = TRUE
)
names(df_ci_median)[2:3] <- c("factor", "ci_half_med")
med_ci <- mean(df_ci_median$ci_half_med)
# Ribbon and dashed lines are centred at 0 (neutral-zone convention):
df_ci_median$factor.p10      <- -df_ci_median$ci_half_med   # time-varying lower bound
df_ci_median$factor.p90      <-  df_ci_median$ci_half_med   # time-varying upper bound
df_ci_median$factor.p10.mean <- -med_ci                     # constant lower threshold
df_ci_median$factor.p90.mean <-  med_ci                     # constant upper threshold

p_ci <- ggplot(df_ci_median, aes(x = obstime)) +
  geom_ribbon(aes(ymin = factor.p10, ymax = factor.p90),
              fill = COLOURS$ribbon, alpha = 0.6) +
  geom_line(aes(y = factor), colour = COLOURS$pca, linewidth = 0.8) +
  geom_line(aes(y = factor.p10.mean), colour = "grey30",
            linetype = "dashed", linewidth = 0.5) +
  geom_line(aes(y = factor.p90.mean), colour = "grey30",
            linetype = "dashed", linewidth = 0.5) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  scale_x_date(date_labels = "%Y", date_breaks = "4 years") +
  labs(x = "", y = "Standardised units") +
  theme_paper()
save_tikz(p_ci, "ci_medians.tikz", width = 6.27, height = 3.0)

# Figure 4: Regimes across countries (heatmap)
regime_list <- map(df_regimes, ~ .x %>% dplyr::select(obstime, regime))
df_regime   <- bind_rows(regime_list, .id = "country")

p_regimes <- ggplot(df_regime, aes(x = obstime, y = country, fill = regime)) +
  geom_tile(colour = "white", linewidth = 0.25) +
  scale_fill_manual(
    values = c("Elevated" = "#B22222", "Neutral" = "grey75", "Subdued" = "#4472C4"),
    breaks = c("Elevated", "Neutral", "Subdued")
  ) +
  scale_x_date(date_labels = "%Y", date_breaks = "4 years") +
  labs(x = "", y = "", fill = "") +
  theme_paper() +
  theme(panel.grid = element_blank(),
        axis.text.y = element_text(size = 7))
save_tikz(p_regimes, "regimes_graph.tikz", width = 6.27, height = 3.2)

# Table: R-squared
table_r2 <- bind_rows(lapply(names(df_r2), function(country) {
  aux <- as.data.frame(df_r2[[country]])
  aux$Country <- country
  return(aux)
}))
average_row <- table_r2 %>%
  dplyr::select(-Country) %>%
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE))) %>%
  mutate(Country = "Average")
table_r2 <- bind_rows(table_r2, average_row)

write_xlsx(table_r2, file.path(OUTPUTS_DIR, "table_r2.xlsx"))
save(table_r2, file = file.path(OUTPUTS_DIR, "table_r2.RData"))
message("Saved: table_r2.xlsx / .RData")
