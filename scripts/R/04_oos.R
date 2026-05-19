###############################################################
# 04_oos.R
# Financial Cycle Replication Package — Abreu & De Lorenzo Buratta
#
# INPUT:  data/raw/df_country.RData
#         data/raw/esrb.fcdb20220120.en.xlsx
#         data/raw/basel_gap.RData   ← created by 00_refresh_data.R
#
# OUTPUT: Figures/oos_graph.pdf
#         scripts/R/_outputs/df_oos.RData / .xlsx
#
# Description: Simulated out-of-sample early-warning exercise focusing
# on the GFC (2006 Q1 – 2009 Q1). Re-estimates the DFM and logit model
# at each quarter using only data available at that point in time.
###############################################################

library(here)
source(here::here("scripts", "R", "auxiliary", "_paths.R"))
source(file.path(here::here("scripts", "R", "auxiliary"), "_theme.R"))

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
library(data.table)
library(scales)
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

# Basel gap — fixed file (no live API call)
basel_path <- file.path(RAW_DIR, "basel_gap.RData")
if (!file.exists(basel_path)) {
  stop("basel_gap.RData not found in data/raw/. Run scripts/R/00_refresh_data.R first.")
}
load(basel_path)  # loads: bis_cred2gdp_gap (country, obstime, basel.gap)

esrb_path <- file.path(RAW_DIR, "esrb.fcdb20220120.en.xlsx")

###############################################################
# ESRB crisis dates
###############################################################

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
  parse_esrb_dates() %>%
  add_row(Country = "PT", start.date = as.Date("1999-03-31"), end.date = as.Date("2000-03-31"),
          start.date.5 = as.Date("1997-12-31"), start.date.12 = as.Date("1996-03-31"),
          start.date.16 = as.Date("1995-03-31")) %>%
  add_row(Country = "NL", start.date = as.Date("2002-03-31"), end.date = as.Date("2003-12-31"),
          start.date.5 = as.Date("2000-12-31"), start.date.12 = as.Date("1999-03-31"),
          start.date.16 = as.Date("1998-03-31"))

###############################################################
# Country sample for OOS exercise
###############################################################

countries <- intersect(names(df_country), unique(df_esrb_systemic$Country))
min_rows  <- 88
df_country_filtered <- df_country[countries] %>%
  lapply(., function(df) if (nrow(df) >= min_rows) df else NULL)

# Exclude countries with structural data issues
for (exc in c("MX", "PL", "HU", "CZ", "NO")) {
  df_country_filtered[[exc]] <- NULL
}
df_country_filtered <- df_country_filtered[!sapply(df_country_filtered, is.null)]

###############################################################
# Crisis indicators
###############################################################

df_crisis <- lapply(df_country_filtered, function(df) df["obstime"]) %>%
  lapply(., function(df) df %>% mutate(crisis_systemic = 0L, crisis_residual = 0L))

df_crisis <- lapply(names(df_crisis), function(country) {
  df_crisis[[country]] %>%
    rowwise() %>%
    mutate(
      crisis_systemic = as.integer(any(
        obstime >= df_esrb_systemic[df_esrb_systemic$Country == country, "start.date", drop = TRUE] &
          obstime <= df_esrb_systemic[df_esrb_systemic$Country == country, "end.date",   drop = TRUE])),
      crisis_systemic.5.12 = as.integer(any(
        obstime >= df_esrb_systemic[df_esrb_systemic$Country == country, "start.date.12", drop = TRUE] &
          obstime <= df_esrb_systemic[df_esrb_systemic$Country == country, "start.date.5",  drop = TRUE])),
      crisis_systemic.5.16 = as.integer(any(
        obstime >= df_esrb_systemic[df_esrb_systemic$Country == country, "start.date.16", drop = TRUE] &
          obstime <= df_esrb_systemic[df_esrb_systemic$Country == country, "start.date.5",  drop = TRUE])),
      crisis_residual = as.integer(any(
        obstime >= df_esrb_residual[df_esrb_residual$Country == country, "start.date", drop = TRUE] &
          obstime <= df_esrb_residual[df_esrb_residual$Country == country, "end.date",   drop = TRUE])),
      crisis_residual.5.12 = as.integer(any(
        obstime >= df_esrb_residual[df_esrb_residual$Country == country, "start.date.12", drop = TRUE] &
          obstime <= df_esrb_residual[df_esrb_residual$Country == country, "start.date.5",  drop = TRUE])),
      crisis_residual.5.16 = as.integer(any(
        obstime >= df_esrb_residual[df_esrb_residual$Country == country, "start.date.16", drop = TRUE] &
          obstime <= df_esrb_residual[df_esrb_residual$Country == country, "start.date.5",  drop = TRUE])),
      crisis_total      = crisis_systemic    + crisis_residual,
      crisis_total.5.12 = crisis_systemic.5.12 + crisis_residual.5.12,
      crisis_total.5.16 = crisis_systemic.5.16 + crisis_residual.5.16
    ) %>%
    ungroup()
}) %>%
  setNames(names(df_country_filtered))

###############################################################
# Out-of-sample loop: 2006 Q1 – 2009 Q1
###############################################################

start_date <- as.Date("2006-03-31")
end_date   <- as.Date("2009-03-31")
oos_dates  <- df_crisis[[1]]$obstime[df_crisis[[1]]$obstime >= start_date &
                                       df_crisis[[1]]$obstime <= end_date]

indicators <- c("pca", "qml", "tstep", "cred.nfc.roc.2yoy", "cred.hh.roc.2yoy",
                "rhp.roc.2yoy", "sp.roc.2yoy", "dsr.roc.2yoy",
                "cred.2gdp.roc.2yoy", "sprd.bond.diff.2y", "basel.gap")

df_oos <- vector("list", length(oos_dates))

for (q_idx in seq_along(oos_dates)) {
  quarter <- oos_dates[q_idx]
  message("OOS quarter: ", as.Date(quarter))

  df_subset <- lapply(df_country_filtered, function(df) filter(df, obstime <= quarter))

  df_country_trans <- df_subset %>%
    lapply(., transform_2yoy) %>%
    lapply(., getseas, trans = FALSE) %>%
    lapply(., function(df) {
      obstime  <- as.Date(df[nrow(df), 1]) %m+% months(3)
      df[, 1]  <- as.Date(df[, 1])
      df_bw    <- rbind(df, cbind(obstime, df[nrow(df), 2:ncol(df)]))
      df_cycle <- getfilter(df_bw, filter = "BW", freq = 25, nfix = 2, drift = FALSE)$cycle
      df_cycle <- getfilter(df_cycle, filter = "BW", freq = 4,  nfix = 4, drift = FALSE)$trend
      df_cycle[-nrow(df_cycle), ]
    })

  for (i in seq_along(df_country_trans)) {
    aux1 <- c(rep(NA, 8), diff(df_subset[[i]]$sprd.bond, lag = 8))
    df_country_trans[[i]]$sprd.bond.roc.2yoy <- aux1
    colnames(df_country_trans[[i]])[ncol(df_country_trans[[i]])] <- "sprd.bond.diff.2y"
  }

  df_model_oos <- df_country_trans %>%
    lapply(., function(df_input) {
      norm_data <- normalise(df_input[, 2:ncol(df_input)])
      out       <- cbind(as.Date(df_input[, 1]), norm_data)
      names(out)[1] <- "obstime"
      return(out)
    }) %>%
    lapply(., na.omit)

  df_dfm_oos <- df_model_oos %>%
    lapply(., function(df) {
      obstime <- df[, 1]
      dfm     <- DFM(df[, 2:ncol(df)], r = 1, p = 4)
      data.frame(obstime = as.Date(obstime),
                 pca = as.numeric(dfm$F_pca),
                 qml = as.numeric(dfm$F_qml),
                 tstep = as.numeric(dfm$F_2s))
    })

  df_dec_oos <- lapply(seq_along(df_model_oos), function(i) {
    dt_m <- as.data.table(df_model_oos[[i]])
    dt_d <- as.data.table(df_dfm_oos[[i]])
    dt_m[, obstime := as.Date(obstime)]
    dt_d[, obstime := as.Date(obstime)]
    setDF(merge(dt_m, dt_d, by = "obstime", all.x = TRUE))
  }) %>%
    setNames(names(df_dfm_oos))

  df_ew_q <- lapply(names(df_dec_oos), function(country) {
    left_join(df_dec_oos[[country]], df_crisis[[country]], by = "obstime")
  }) %>%
    setNames(names(df_dec_oos))

  df_ew_bis_q <- lapply(names(df_ew_q), function(country_code) {
    country_data <- bis_cred2gdp_gap %>%
      filter(country == country_code) %>%
      dplyr::select(obstime, basel.gap)
    left_join(df_ew_q[[country_code]], country_data, by = "obstime")
  }) %>%
    setNames(names(df_ew_q))

  oos_results <- lapply(names(df_ew_bis_q), function(country) {
    test_data   <- df_ew_bis_q[[country]]
    target_data <- df_crisis[[country]]
    oos_row     <- test_data[test_data$obstime == as.Date(quarter), ]
    oos_row$crisis_total.5.12 <- target_data[
      target_data$obstime == (as.Date(quarter) %m+% years(1)), "crisis_total", drop = TRUE]

    oos_pred <- data.frame(matrix(ncol = length(indicators), nrow = 1))
    colnames(oos_pred) <- indicators
    for (j in seq_along(indicators)) {
      formula   <- as.formula(paste("crisis_total.5.12 ~", indicators[j]))
      # Skip if response has no variation (all zeros or all ones) or indicator is all NA
      resp_vals <- na.omit(test_data[["crisis_total.5.12"]])
      ind_vals  <- na.omit(test_data[[indicators[j]]])
      if (length(unique(resp_vals)) < 2 || length(ind_vals) == 0) {
        oos_pred[, j] <- NA
        next
      }
      glm_model <- tryCatch(
        glm(formula, family = binomial(link = "logit"), data = test_data),
        error = function(e) NULL
      )
      oos_pred[, j] <- if (!is.null(glm_model))
        predict(glm_model, newdata = oos_row, type = "response") * 100
      else NA
    }
    return(oos_pred)
  }) %>%
    setNames(names(df_ew_bis_q))

  out          <- bind_rows(oos_results, .id = "country")
  out$quarter  <- as.Date(quarter)
  df_oos[[q_idx]] <- out
}

df_oos         <- bind_rows(df_oos)
df_oos$quarter <- as.Date(df_oos$quarter)

###############################################################
# OOS figure: median predicted probability of crisis (PCA only)
###############################################################

oos_graph <- df_oos %>%
  group_by(quarter) %>%
  summarise(
    pca_median = median(pca, na.rm = TRUE),
    pca_q25    = quantile(pca, 0.25, na.rm = TRUE),
    pca_q75    = quantile(pca, 0.75, na.rm = TRUE)
  )

p_oos <- ggplot(oos_graph, aes(x = quarter)) +
  geom_ribbon(aes(ymin = pca_q25, ymax = pca_q75),
              fill = COLOURS$ribbon, alpha = 0.6) +
  geom_line(aes(y = pca_median), colour = COLOURS$pca, linewidth = 0.8) +
  geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.3) +
  scale_x_date(
    breaks = as.Date(c("2006-03-31","2007-03-31","2008-03-31","2009-03-31")),
    labels = c("2006 Q1","2007 Q1","2008 Q1","2009 Q1")
  ) +
  scale_y_continuous(breaks = seq(0, 30, by = 5)) +
  labs(x = "", y = "Predicted probability (%)") +
  theme_paper()
save_tikz(p_oos, "oos_graph.tikz", width = 6.27, height = 3.0)

###############################################################
# Save
###############################################################

save(df_oos,    file = file.path(OUTPUTS_DIR, "df_oos.RData"))
write_xlsx(df_oos, file.path(OUTPUTS_DIR, "df_oos.xlsx"))
message("Saved: df_oos.RData / .xlsx")
