###############################################################
# 03_dec_ew_gar.R
# Financial Cycle Replication Package — Abreu & De Lorenzo Buratta
#
# INPUT:  scripts/R/_outputs/df_dec.RData
#         data/raw/esrb.fcdb20220120.en.xlsx
#         data/raw/basel_gap.RData   ← created by 00_refresh_data.R
#
# OUTPUT: Figures/dec_graph.pdf
#         (Decomposition panels for Appendix B: see 05_panel_figures.R)
#         scripts/R/_outputs/df_auroc.RData / .xlsx
#         scripts/R/_outputs/df_coords.RData / .xlsx
#
# Description: Computes financial cycle decomposition, in-sample
# early-warning analysis (AUROC + usefulness index), and identifies
# financial cycle regimes.
###############################################################

library(here)
source(here::here("scripts", "R", "auxiliary", "_paths.R"))
source(file.path(AUX_DIR, "_theme.R"))

library(xts)
library(tidyverse)
library(readxl)
library(writexl)
library(reshape2)
library(pROC)
library(lubridate)
library(mFilter)

source(file.path(AUX_DIR, "main_with_pass.R"))
source(file.path(AUX_DIR, "trend_filterHP.R"))
source(file.path(AUX_DIR, "filterhp.R"))
source(file.path(AUX_DIR, "normalise.R"))
source(file.path(AUX_DIR, "urtests.R"))
source(file.path(AUX_DIR, "getseas.R"))
source(file.path(AUX_DIR, "ICr_c.R"))
source(file.path(AUX_DIR, "boundaryFstats.R"))
source(file.path(AUX_DIR, "getauroc.R"))
source(file.path(AUX_DIR, "get_coords.R"))
source(file.path(AUX_DIR, "FC_decomposition.R"))
source(file.path(AUX_DIR, "getfilter.R"))
source(file.path(AUX_DIR, "transform_2yoy.R"))

load(file.path(OUTPUTS_DIR, "df_dec.RData"))

###############################################################
# Decomposition
###############################################################

# Country-specific decomposition
dec <- lapply(df_dec, FC_decomposition)

# Median decomposition across selected countries
country_selection <- c("SE", "IT", "FR", "DE", "BE", "NL", "FI", "GB", "PT", "ES")
dec_df <- bind_rows(lapply(dec, function(sublist) sublist$dec), .id = "country")

dec_median <- dec_df %>%
  filter(country %in% country_selection, obstime >= as.Date("2001-12-31")) %>%
  group_by(obstime) %>%
  summarise(
    pca                  = median(pca,                  na.rm = TRUE),
    cred.hh.roc.2yoy     = median(cred.hh.roc.2yoy,    na.rm = TRUE),
    cred.nfc.roc.2yoy    = median(cred.nfc.roc.2yoy,   na.rm = TRUE),
    rhp.roc.2yoy         = median(rhp.roc.2yoy,        na.rm = TRUE),
    sp.roc.2yoy          = median(sp.roc.2yoy,         na.rm = TRUE),
    dsr.roc.2yoy         = median(dsr.roc.2yoy,        na.rm = TRUE),
    cred.2gdp.roc.2yoy   = median(cred.2gdp.roc.2yoy,  na.rm = TRUE),
    sprd.bond.diff.2y    = median(sprd.bond.diff.2y,   na.rm = TRUE)
  )

dec_median_graph <- FC_decomposition(dec_median)

save_tikz(dec_median_graph$graph + theme_paper() +
            theme(legend.position = "bottom",
                  legend.text = element_text(size = 6.5)),
          "dec_graph.tikz", width = 6.27, height = 3.2)

###############################################################
# Crisis indicators (ESRB financial crises database)
###############################################################

esrb_path <- file.path(RAW_DIR, "esrb.fcdb20220120.en.xlsx")

parse_esrb_dates <- function(df) {
  df %>%
    mutate(
      start.date = as.Date(paste(substr(`Start date`, 1, 4), substr(`Start date`, 6, 8), "01", sep = "-"),
                           format = "%Y-%m-%d"),
      start.date = ceiling_date(start.date, "month") %m-% days(1),
      end.date   = as.Date(paste(substr(`End of crisis management date`, 1, 4),
                                 substr(`End of crisis management date`, 6, 8), "01", sep = "-"),
                           format = "%Y-%m-%d"),
      end.date   = ceiling_date(end.date, "month") %m-% days(1),
      start.date.5  = start.date %m-% months(15),
      start.date.12 = start.date %m-% months(36),
      start.date.16 = start.date %m-% months(48),
      Country = ifelse(Country == "UK*", "GB", Country)
    ) %>%
    dplyr::select(Country, start.date, end.date, start.date.5, start.date.12, start.date.16)
}

df_esrb_systemic <- read_xlsx(esrb_path, sheet = "Systemic crises") %>%
  slice(-c(1, 79:nrow(.))) %>%
  filter(Banking == 1, `Macropru relevant` == 1) %>%
  parse_esrb_dates()

df_esrb_residual <- read_xlsx(esrb_path, sheet = "Residual events") %>%
  slice(-1) %>%
  filter(Banking == 1, `Macropru relevant` == 1) %>%
  parse_esrb_dates()

###############################################################
# Prepare early-warning dataset
###############################################################

tag_crisis <- function(df_ew_list, df_systemic, df_residual) {
  lapply(names(df_ew_list), function(country) {
    df_ew_list[[country]] %>%
      rowwise() %>%
      mutate(
        crisis_systemic = as.integer(any(
          obstime >= df_systemic[df_systemic$Country == country, "start.date", drop = TRUE] &
            obstime <= df_systemic[df_systemic$Country == country, "end.date",   drop = TRUE])),
        crisis_systemic.5.12 = as.integer(any(
          obstime >= df_systemic[df_systemic$Country == country, "start.date.12", drop = TRUE] &
            obstime <= df_systemic[df_systemic$Country == country, "start.date.5",  drop = TRUE])),
        crisis_systemic.5.16 = as.integer(any(
          obstime >= df_systemic[df_systemic$Country == country, "start.date.16", drop = TRUE] &
            obstime <= df_systemic[df_systemic$Country == country, "start.date.5",  drop = TRUE])),
        crisis_residual = as.integer(any(
          obstime >= df_residual[df_residual$Country == country, "start.date", drop = TRUE] &
            obstime <= df_residual[df_residual$Country == country, "end.date",   drop = TRUE])),
        crisis_residual.5.12 = as.integer(any(
          obstime >= df_residual[df_residual$Country == country, "start.date.12", drop = TRUE] &
            obstime <= df_residual[df_residual$Country == country, "start.date.5",  drop = TRUE])),
        crisis_residual.5.16 = as.integer(any(
          obstime >= df_residual[df_residual$Country == country, "start.date.16", drop = TRUE] &
            obstime <= df_residual[df_residual$Country == country, "start.date.5",  drop = TRUE])),
        crisis_total      = crisis_systemic    + crisis_residual,
        crisis_total.5.12 = crisis_systemic.5.12 + crisis_residual.5.12,
        crisis_total.5.16 = crisis_systemic.5.16 + crisis_residual.5.16
      ) %>%
      ungroup()
  }) %>%
    setNames(names(df_ew_list))
}

countries_ew <- intersect(names(df_dec), unique(df_esrb_systemic$Country))
df_ew_base   <- lapply(df_dec[countries_ew], function(df) df %>% mutate(crisis_systemic = 0L, crisis_residual = 0L))
df_ew        <- tag_crisis(df_ew_base, df_esrb_systemic, df_esrb_residual)

###############################################################
# Basel gap — load from fixed file (created by 00_refresh_data.R)
###############################################################

basel_path <- file.path(RAW_DIR, "basel_gap.RData")
if (!file.exists(basel_path)) {
  stop("basel_gap.RData not found in data/raw/. Run scripts/R/00_refresh_data.R first.")
}
load(basel_path)  # loads object: bis_cred2gdp_gap (data.frame with country, obstime, basel.gap)

df_ew_bis <- lapply(names(df_ew), function(country_code) {
  country_data <- bis_cred2gdp_gap %>%
    filter(country == country_code) %>%
    dplyr::select(obstime, basel.gap)
  left_join(df_ew[[country_code]], country_data, by = "obstime")
}) %>%
  setNames(names(df_ew))

###############################################################
# In-sample early-warning: AUROC and usefulness index
###############################################################

indicators  <- c("pca", "qml", "tstep", "cred.nfc.roc.2yoy", "cred.hh.roc.2yoy",
                 "rhp.roc.2yoy", "sp.roc.2yoy", "dsr.roc.2yoy",
                 "cred.2gdp.roc.2yoy", "sprd.bond.diff.2y", "basel.gap")
crisis_def  <- "crisis_systemic.5.12"
theta       <- 0.5    # balanced preferences
theta_alt   <- 0.7    # crisis-averse: 70% weight on missed crises (T1), 30% on false alarms (T2)

countries_ew <- names(df_ew_bis)

df_auroc      <- data.frame(matrix(NA, nrow = length(countries_ew), ncol = length(indicators)),
                            row.names = countries_ew)
colnames(df_auroc) <- indicators
df_coords     <- df_auroc
df_coords_alt <- df_auroc   # usefulness at theta_alt

for (i in seq_along(countries_ew)) {
  df <- na.omit(as.data.frame(df_ew_bis[[i]]))
  df_train <- df[df$crisis_systemic != 1, ]
  for (j in seq_along(indicators)) {
    df_auroc[i, j]      <- getauroc(df_train, crisis_def, indicators[j])
    df_coords[i, j]     <- get_coords(df_train, crisis_def, indicators[j], theta)$optimal_threshold$usefulness
    df_coords_alt[i, j] <- get_coords(df_train, crisis_def, indicators[j], theta_alt)$optimal_threshold$usefulness
  }
}

# Add average row
df_auroc      <- rbind(df_auroc,      colMeans(df_auroc,      na.rm = TRUE))
df_coords     <- rbind(df_coords,     colMeans(df_coords,     na.rm = TRUE))
df_coords_alt <- rbind(df_coords_alt, colMeans(df_coords_alt, na.rm = TRUE))
rownames(df_auroc)[nrow(df_auroc)]           <- "Avg"
rownames(df_coords)[nrow(df_coords)]         <- "Avg"
rownames(df_coords_alt)[nrow(df_coords_alt)] <- "Avg"

df_auroc$country      <- rownames(df_auroc)
df_coords$country     <- rownames(df_coords)
df_coords_alt$country <- rownames(df_coords_alt)

write_xlsx(df_auroc,      file.path(OUTPUTS_DIR, "df_auroc.xlsx"))
write_xlsx(df_coords,     file.path(OUTPUTS_DIR, "df_coords.xlsx"))
write_xlsx(df_coords_alt, file.path(OUTPUTS_DIR, "df_coords_alt.xlsx"))
save(df_auroc,      file = file.path(OUTPUTS_DIR, "df_auroc.RData"))
save(df_coords,     file = file.path(OUTPUTS_DIR, "df_coords.RData"))
save(df_coords_alt, file = file.path(OUTPUTS_DIR, "df_coords_alt.RData"))
message("Saved: df_auroc, df_coords, df_coords_alt (.xlsx + .RData)")
