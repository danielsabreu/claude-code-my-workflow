###############################################################
# 01_data_processing.R
# Financial Cycle Replication Package — Abreu & De Lorenzo Buratta
#
# INPUT:  data/raw/df_country.RData
# OUTPUT: scripts/R/_outputs/df_model.RData
#         scripts/R/_outputs/summary_stats.RData
#         scripts/R/_outputs/summary_stats.xlsx
#
# Description: Applies 2-year growth rate transformations, removes
# low-frequency components via Butterworth filter, standardises all
# variables, and filters countries by minimum sample length.
###############################################################

library(here)
source(here::here("scripts", "R", "auxiliary", "_paths.R"))

library(vars)
library(dfms)
library(seasonal)
library(urca)
library(xts)
library(tidyverse)
library(zoo)
library(readxl)
library(writexl)
library(mFilter)
library(reshape2)
library(lubridate)

source(file.path(AUX_DIR, "trend_filterHP.R"))
source(file.path(AUX_DIR, "filterhp.R"))
source(file.path(AUX_DIR, "normalise.R"))
source(file.path(AUX_DIR, "getseas_v2.R"))
source(file.path(AUX_DIR, "getfilter.R"))
source(file.path(AUX_DIR, "transform_2yoy.R"))

###############################################################
# Load data
###############################################################

load(file.path(RAW_DIR, "df_country.RData"))

###############################################################
# Transformations: 2-year growth rates + Butterworth filter + normalisation
###############################################################

df_country$MX <- NULL  # Exclude: missing observations in sprd.bond

df_country_trans <- df_country %>%
  lapply(., transform_2yoy) %>%
  lapply(., getseas, trans = FALSE) %>%
  lapply(., function(df) {
    obstime <- as.Date(df[nrow(df), 1]) %m+% months(3)
    df[, 1] <- as.Date(df[, 1])
    df_bw <- rbind(df, cbind(obstime, df[nrow(df), 2:ncol(df)]))
    df_bw_cycle <- getfilter(df_bw, filter = "BW", freq = 25, nfix = 2, drift = FALSE)$cycle
    df_bw_cycle <- getfilter(df_bw_cycle, filter = "BW", freq = 4,  nfix = 4, drift = FALSE)$trend
    df_bw_cycle <- df_bw_cycle[-nrow(df_bw_cycle), ]
    return(df_bw_cycle)
  })

# Bond spread: 2-year difference (not growth rate)
# Use name-based access to avoid index-order fragility
for (cc in names(df_country_trans)) {
  aux1 <- c(rep(NA, 8), diff(df_country[[cc]]$sprd.bond, lag = 8))
  df_country_trans[[cc]]$sprd.bond.roc.2yoy <- aux1
  colnames(df_country_trans[[cc]])[ncol(df_country_trans[[cc]])] <- "sprd.bond.diff.2y"
}

# Standardise
df_country_trans <- df_country_trans %>%
  lapply(., function(df_input) {
    normalized_data <- normalise(df_input[, 2:ncol(df_input)])
    df <- cbind(df_input[, 1], normalized_data)
    df[, 1] <- as.Date(df_input[, 1])
    names(df)[1] <- "obstime"
    return(df)
  }) %>%
  lapply(., na.omit)

# Filter by minimum number of rows (PT sets the minimum)
min_rows <- 88
filtered_list <- lapply(df_country_trans, function(df) {
  if (nrow(df) >= min_rows) return(df) else return(NULL)
})
# Paper sample: 10 European countries (explicit list to prevent new countries
# entering the analysis when the dataset is extended to future vintages)
PAPER_COUNTRIES <- c("BE", "DE", "ES", "FI", "FR", "GB", "IT", "NL", "PT", "SE")

all_pass <- filtered_list[!sapply(filtered_list, is.null)]
df_model <- all_pass[intersect(names(all_pass), PAPER_COUNTRIES)]

###############################################################
# Save
###############################################################

save(df_model, file = file.path(OUTPUTS_DIR, "df_model.RData"))
message("Saved: df_model.RData")

###############################################################
# Descriptive statistics
###############################################################

df_smst <- df_country %>% lapply(., transform_2yoy)

for (i in seq_along(df_smst)) {
  aux1 <- c(rep(NA, 8), diff(df_country[[i]]$sprd.bond, lag = 8))
  df_smst[[i]]$sprd.bond.roc.2yoy <- aux1
  colnames(df_smst[[i]])[ncol(df_smst[[i]])] <- "sprd.bond.diff.2y"
}

df_smst <- lapply(df_smst, na.omit)
df_smst <- bind_rows(df_smst, .id = "country")

summary_stats <- df_smst %>%
  group_by(country) %>%
  summarize(
    nobs                     = n(),
    mean_cred_nfc            = mean(cred.nfc.roc.2yoy, na.rm = TRUE),
    sd_cred_nfc              = sd(cred.nfc.roc.2yoy,   na.rm = TRUE),
    mean_cred_hh             = mean(cred.hh.roc.2yoy,  na.rm = TRUE),
    sd_cred_hh               = sd(cred.hh.roc.2yoy,    na.rm = TRUE),
    mean_rhp                 = mean(rhp.roc.2yoy,       na.rm = TRUE),
    sd_rhp                   = sd(rhp.roc.2yoy,         na.rm = TRUE),
    mean_sp                  = mean(sp.roc.2yoy,        na.rm = TRUE),
    sd_sp                    = sd(sp.roc.2yoy,          na.rm = TRUE),
    mean_dsr                 = mean(dsr.roc.2yoy,       na.rm = TRUE),
    sd_dsr                   = sd(dsr.roc.2yoy,         na.rm = TRUE),
    mean_cred2gdp            = mean(cred.2gdp.roc.2yoy, na.rm = TRUE),
    sd_cred2gdp              = sd(cred.2gdp.roc.2yoy,   na.rm = TRUE),
    mean_sprd_bond           = mean(sprd.bond.diff.2y,  na.rm = TRUE),
    sd_sprd_bond             = sd(sprd.bond.diff.2y,    na.rm = TRUE)
  ) %>%
  ungroup()

save(summary_stats,   file = file.path(OUTPUTS_DIR, "summary_stats.RData"))
write_xlsx(summary_stats, file.path(OUTPUTS_DIR, "summary_stats.xlsx"))
message("Saved: summary_stats.RData / .xlsx")
