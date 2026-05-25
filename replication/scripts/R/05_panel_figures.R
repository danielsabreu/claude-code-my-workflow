###############################################################
# 05_panel_figures.R
# Financial Cycle Replication Package — Abreu & De Lorenzo Buratta
#
# INPUT:  scripts/R/_outputs/df_dfm.RData
#         scripts/R/_outputs/df_ic_avar.RData
#         scripts/R/_outputs/df_dec.RData
#
# OUTPUT: Figures/panel_fc_{1_2 … 9_10}.pdf      — Appendix A
#         Figures/final_panel_with_legend_{1_2 … 9_10}.pdf — Appendix B
#         Figures/panel_ci_{1_2 … 9_10}.pdf      — Appendix C
#
# Description: Generates all individual-country panel figures for the
# three appendices. Countries are shown alphabetically in pairs of two,
# stacked vertically within each panel.
###############################################################

library(here)
source(here::here("scripts", "R", "auxiliary", "_paths.R"))
source(file.path(AUX_DIR, "_theme.R"))
source(file.path(AUX_DIR, "FC_decomposition.R"))
source(file.path(AUX_DIR, "normalise.R"))

library(ggplot2)
library(patchwork)
library(reshape2)
library(dplyr)
library(lubridate)

load(file.path(OUTPUTS_DIR, "df_dfm.RData"))
load(file.path(OUTPUTS_DIR, "df_ic_avar.RData"))
load(file.path(OUTPUTS_DIR, "df_dec.RData"))

###############################################################
# Country layout
###############################################################

PAPER_COUNTRIES <- c("BE", "DE", "ES", "FI", "FR", "GB", "IT", "NL", "PT", "SE")
PAIRS <- list(
  list(idx = "1_2",  countries = c("BE", "DE")),
  list(idx = "3_4",  countries = c("ES", "FI")),
  list(idx = "5_6",  countries = c("FR", "GB")),
  list(idx = "7_8",  countries = c("IT", "NL")),
  list(idx = "9_10", countries = c("PT", "SE"))
)

###############################################################
# Helper: single-country financial cycle plot (Appendix A)
###############################################################

plot_fc_country <- function(ctry) {
  dfm <- df_dfm[[ctry]]

  df_long <- melt(dfm[, c("obstime", "pca", "qml", "tstep")],
                  id.vars = "obstime", variable.name = "estimator",
                  value.name = "value")

  ggplot(df_long, aes(x = obstime, y = value,
                      colour = estimator, linetype = estimator)) +
    geom_line(linewidth = 0.55) +
    scale_colour_manual(
      values  = c(pca = COLOURS$pca, qml = COLOURS$qml, tstep = COLOURS$tstep),
      labels  = c(pca = "PCA", qml = "QML", tstep = "Two-step")) +
    scale_linetype_manual(
      values  = c(pca = "solid", qml = "dashed", tstep = "dotted"),
      labels  = c(pca = "PCA", qml = "QML", tstep = "Two-step")) +
    geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
    scale_x_date(date_labels = "%Y", date_breaks = "4 years") +
    labs(title  = COUNTRY_NAMES[ctry],
         x = "", y = "Standardised units",
         colour = "", linetype = "") +
    theme_paper()
}

###############################################################
# Helper: single-country confidence interval plot (Appendix C)
###############################################################

plot_ci_country <- function(ctry) {
  avar <- df_ic_avar[[ctry]]$avar
  # factor.p90 = +ci_half, factor.p10 = -ci_half (centred at 0)
  # ribbon wraps around the factor estimate: [factor - ci_half, factor + ci_half]
  avar$ci_lo <- avar$factor + avar$factor.p10   # factor - ci_half
  avar$ci_hi <- avar$factor + avar$factor.p90   # factor + ci_half

  ggplot(avar, aes(x = obstime)) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi),
                fill = COLOURS$ribbon, alpha = 0.6) +
    geom_line(aes(y = factor), colour = COLOURS$pca, linewidth = 0.65) +
    geom_line(aes(y = factor.p10.mean), colour = "grey30",
              linetype = "dashed", linewidth = 0.45) +
    geom_line(aes(y = factor.p90.mean), colour = "grey30",
              linetype = "dashed", linewidth = 0.45) +
    geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
    scale_x_date(date_labels = "%Y", date_breaks = "4 years") +
    labs(title = COUNTRY_NAMES[ctry],
         x = "", y = "Standardised units") +
    theme_paper()
}

###############################################################
# Helper: single-country decomposition plot (Appendix B)
###############################################################

plot_dec_country <- function(ctry) {
  df_in <- df_dec[[ctry]]
  if (is.null(df_in)) {
    message("  Skipping ", ctry, " — not in df_dec")
    return(NULL)
  }

  # Decomposition returns graph already; rebuild for consistent theme
  dec_result <- FC_decomposition(df_in)
  dec_graph  <- dec_result$dec  # obstime, pca, and variable columns

  var_names <- c("cred.nfc.roc.2yoy","cred.hh.roc.2yoy","rhp.roc.2yoy",
                 "sp.roc.2yoy","dsr.roc.2yoy","cred.2gdp.roc.2yoy","sprd.bond.diff.2y")

  df_long <- melt(dec_graph, id.vars = c("obstime"),
                  measure.vars = var_names,
                  variable.name = "variable", value.name = "contribution")
  df_long$variable <- factor(df_long$variable,
                              levels = names(VAR_LABELS),
                              labels = VAR_LABELS)

  ggplot() +
    geom_col(data = df_long,
             aes(x = obstime, y = contribution, fill = variable),
             position = "stack", width = 70) +
    geom_line(data = dec_graph,
              aes(x = obstime, y = pca), colour = "black", linewidth = 0.65) +
    geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
    scale_fill_manual(values = DEC_COLOURS) +
    scale_x_date(date_labels = "%Y", date_breaks = "4 years") +
    labs(title = COUNTRY_NAMES[ctry],
         x = "", y = "Standardised units", fill = "") +
    theme_paper() +
    theme(legend.position = "bottom",
          legend.text     = element_text(size = 5.5),
          legend.key.size = unit(0.28, "cm"),
          legend.spacing.x = unit(0.15, "cm"))
}

###############################################################
# Generate panels
###############################################################

for (pair in PAIRS) {
  idx  <- pair$idx
  ctrs <- pair$countries

  # ---- Appendix A: factor estimates ----
  plots_fc <- lapply(ctrs, plot_fc_country)
  combined_fc <- plots_fc[[1]] / plots_fc[[2]] +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")
  save_tikz(combined_fc,
            paste0("panel_fc_", idx, ".tikz"),
            width = 6.27, height = 5.6)

  # ---- Appendix B: decomposition ----
  plots_dec <- lapply(ctrs, plot_dec_country)
  if (!any(sapply(plots_dec, is.null))) {
    combined_dec <- plots_dec[[1]] / plots_dec[[2]] +
      plot_layout(guides = "collect") &
      theme(legend.position = "bottom")
    save_tikz(combined_dec,
              paste0("final_panel_with_legend_", idx, ".tikz"),
              width = 6.27, height = 5.6)
  }

  # ---- Appendix C: confidence intervals ----
  plots_ci <- lapply(ctrs, plot_ci_country)
  combined_ci <- plots_ci[[1]] / plots_ci[[2]]
  save_tikz(combined_ci,
            paste0("panel_ci_", idx, ".tikz"),
            width = 6.27, height = 5.6)
}

message("All panel figures saved.")
