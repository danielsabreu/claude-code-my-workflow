###############################################################
# 00_refresh_data.R
# Financial Cycle — Incremental Data Refresh
#
# PURPOSE: Extend data/raw/df_country.RData with observations
# after the current vintage and create/update basel_gap.RData.
# Run before each new estimation round or submission.
#
# NOT part of the replication package.
# After running, commit updated data/raw/ files.
#
# REQUIREMENTS: Internet access; BISdata, countrycode, httr
###############################################################

library(here)
source(here::here("scripts", "R", "auxiliary", "_paths.R"))

library(tidyverse)
library(lubridate)
library(zoo)
library(readxl)
library(writexl)
library(BISdata)
library(countrycode)
library(xts)

# httr for direct OECD SDMX API calls
if (!requireNamespace("httr",     quietly = TRUE)) install.packages("httr")
if (!requireNamespace("quantmod", quietly = TRUE)) install.packages("quantmod")
library(httr)
library(quantmod)

Sys.setlocale("LC_TIME", "C")

COUNTRIES <- c("BE", "DE", "ES", "FI", "FR", "GB", "IT", "NL", "PT", "SE")
COL_ORDER <- c("obstime", "cred.nfc", "cred.hh", "rhp", "sp", "dsr", "cred.2gdp", "sprd.bond")

###############################################################
# STEP 0: Load existing dataset and find cutoff date
###############################################################

load(file.path(RAW_DIR, "df_country.RData"))

max_dates <- sapply(df_country, function(df) max(df$obstime))
cutoff    <- as.Date(min(max_dates))
message("Current vintage: ", cutoff, " — fetching data after this date")

###############################################################
# Helper: parse BIS quarter strings
###############################################################

parse_bis_quarter <- function(x) {
  as.Date(as.yearqtr(paste(substr(x, 1, 4), substr(x, 7, 8), sep = "-")), frac = 1)
}

###############################################################
# STEP 1: BIS data (full bulk download, filter new obs)
###############################################################

message("Fetching BIS credit data...")
bis_cred_raw <- fetch_dataset(
  dest.dir = tempdir(), bis.url = "https://data.bis.org/static/bulk/", "WS_TC_csv_col.zip"
)
bis_cred <- bis_cred_raw %>%
  mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>%
  filter(ts_id %in% c("N:A:M:XDC:A", "H:A:M:XDC:A")) %>%
  select(which(names(.) == "Series"):(ncol(.) - 1)) %>%
  pivot_longer(cols = !Series, names_to = "variable", values_to = "value") %>%
  mutate(
    obstime = parse_bis_quarter(variable),
    country = substr(sub("^[^:]*:", "", Series), 1, 2),
    ts_id   = recode(sub("^[^:]*:[^:]*:", "", Series),
                     "N:A:M:XDC:A" = "cred.nfc",
                     "H:A:M:XDC:A" = "cred.hh")
  ) %>%
  select(country, obstime, ts_id, value) %>%
  filter(obstime > cutoff, country %in% COUNTRIES, !is.na(value))

message("Fetching BIS credit-to-GDP and Basel gap...")
bis_gap_raw <- fetch_dataset(
  dest.dir = tempdir(), bis.url = "https://data.bis.org/static/bulk/", "WS_CREDIT_GAP_csv_col.zip"
)

bis_cred2gdp <- bis_gap_raw %>%
  mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>%
  filter(ts_id == "P:A:A") %>%
  select(which(names(.) == "Series"):(ncol(.) - 1)) %>%
  pivot_longer(cols = !Series, names_to = "variable", values_to = "value") %>%
  mutate(
    obstime = parse_bis_quarter(variable),
    country = substr(sub("^[^:]*:", "", Series), 1, 2),
    ts_id   = "cred.2gdp"
  ) %>%
  select(country, obstime, ts_id, value) %>%
  filter(obstime > cutoff, country %in% COUNTRIES, !is.na(value))

# Basel gap — always rebuild full series
message("Building Basel gap series...")
bis_cred2gdp_gap <- bis_gap_raw %>%
  mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>%
  filter(ts_id == "P:A:B") %>%
  select(which(names(.) == "Series"):(ncol(.) - 1)) %>%
  pivot_longer(cols = !Series, names_to = "variable", values_to = "value") %>%
  mutate(
    obstime   = parse_bis_quarter(variable),
    country   = substr(sub("^[^:]*:", "", Series), 1, 2),
    basel.gap = as.numeric(value)
  ) %>%
  select(country, obstime, basel.gap) %>%
  filter(country %in% COUNTRIES, !is.na(basel.gap))

save(bis_cred2gdp_gap, file = file.path(RAW_DIR, "basel_gap.RData"))
message("Saved: data/raw/basel_gap.RData (", nrow(bis_cred2gdp_gap), " rows)")

message("Fetching BIS DSR data...")
bis_dsr_raw <- fetch_dataset(
  dest.dir = tempdir(), bis.url = "https://data.bis.org/static/bulk/", "WS_DSR_csv_col.zip"
)
bis_dsr <- bis_dsr_raw %>%
  mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>%
  filter(ts_id == "P") %>%
  select(which(names(.) == "Series"):(ncol(.) - 1)) %>%
  pivot_longer(cols = !Series, names_to = "variable", values_to = "value") %>%
  mutate(
    obstime = parse_bis_quarter(variable),
    country = substr(sub("^[^:]*:", "", Series), 1, 2),
    ts_id   = "dsr"
  ) %>%
  select(country, obstime, ts_id, value) %>%
  filter(obstime > cutoff, country %in% COUNTRIES, !is.na(value))

bis_new <- bind_rows(bis_cred, bis_cred2gdp, bis_dsr)
message("BIS new obs: ", nrow(bis_new), " rows after ", cutoff)

###############################################################
# STEP 2: OECD via new SDMX REST API
# New endpoint: https://sdmx.oecd.org/public/rest/data/
###############################################################

fetch_oecd_sdmx <- function(dataflow, key, start_period, description) {
  url <- paste0(
    "https://sdmx.oecd.org/public/rest/data/",
    dataflow, "/", key,
    "?startPeriod=", start_period,
    "&format=csvfilewithlabels"
  )
  message("Fetching OECD: ", description, " ...")
  resp <- tryCatch(GET(url, timeout(120)), error = function(e) {
    message("  Request failed: ", conditionMessage(e)); NULL
  })
  if (is.null(resp) || status_code(resp) != 200) {
    message("  OECD ", description, " returned status ",
            if (!is.null(resp)) status_code(resp) else "NA", " — skipping")
    return(NULL)
  }
  content(resp, as = "text", encoding = "UTF-8") %>%
    read_csv(show_col_types = FALSE)
}

# Start period strings
oecd_q_start <- paste0(format(cutoff, "%Y"), "-Q",
                        as.integer(format(cutoff, "%m")) %/% 3 + 1)
oecd_m_start <- format(cutoff %m+% months(1), "%Y-%m")

# House prices (quarterly, real, seasonally adjusted)
raw_rhp <- fetch_oecd_sdmx(
  dataflow    = "OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,1.0",
  key         = ".Q.RHP.IX",
  start_period = oecd_q_start,
  description = "house prices"
)

oecd_rre <- if (!is.null(raw_rhp)) {
  raw_rhp %>%
    select(any_of(c("REF_AREA", "TIME_PERIOD", "OBS_VALUE"))) %>%
    rename_with(~ c("ref_area", "TIME_PERIOD", "value")[seq_along(.)]) %>%
    mutate(
      obstime = as.Date(as.yearqtr(gsub("-Q", " Q", TIME_PERIOD)), frac = 1),
      value   = as.numeric(value),
      country = countrycode(ref_area, "iso3c", "iso2c"),
      country = if_else(is.na(country), ref_area, country),
      ts_id   = "rhp"
    ) %>%
    select(country, obstime, ts_id, value) %>%
    filter(country %in% COUNTRIES, !is.na(value))
} else {
  tibble(country=character(), obstime=as.Date(character()), ts_id=character(), value=numeric())
}

# Share prices (monthly → quarterly)
# Try KEI dataset first (also contains SHARE), then FINMARK with version 2.0
raw_sp <- fetch_oecd_sdmx(
  dataflow    = "OECD.SDD.STES,DSD_KEI@DF_KEI,4.0",
  key         = ".M.SHARE.IX.....",
  start_period = oecd_m_start,
  description = "share prices (via KEI)"
)
if (is.null(raw_sp)) {
  raw_sp <- fetch_oecd_sdmx(
    dataflow    = "OECD.SDD.STES,DSD_STES@DF_FINMARK,2.0",
    key         = ".M.SHARE.IX.....",
    start_period = oecd_m_start,
    description = "share prices (FINMARK v2.0)"
  )
}

oecd_sp <- if (!is.null(raw_sp)) {
  raw_sp %>%
    select(any_of(c("REF_AREA", "TIME_PERIOD", "OBS_VALUE"))) %>%
    rename_with(~ c("ref_area", "TIME_PERIOD", "value")[seq_along(.)]) %>%
    mutate(
      date_m  = as.Date(paste0(TIME_PERIOD, "-01"), format = "%Y-%m-%d"),
      obstime = ceiling_date(date_m, "month") %m-% days(1),
      value   = as.numeric(value),
      country = countrycode(ref_area, "iso3c", "iso2c"),
      country = if_else(is.na(country), ref_area, country),
      ts_id   = "sp"
    ) %>%
    filter(format(obstime, "%m") %in% c("03", "06", "09", "12")) %>%
    select(country, obstime, ts_id, value) %>%
    filter(country %in% COUNTRIES, !is.na(value))
} else {
  # Fallback: Yahoo Finance equity indices (monthly close, end-of-quarter)
  message("OECD share prices unavailable — using Yahoo Finance equity indices as fallback")
  sp_symbols <- c(
    BE = "^BFX",  DE = "^GDAXI", ES = "^IBEX",  FI = "^OMXH25",
    FR = "^FCHI", GB = "^FTSE",  IT = "FTSEMIB.MI", NL = "^AEX",
    PT = "PSI20.LS", SE = "^OMX"
  )
  sp_start <- format(cutoff %m+% months(1), "%Y-%m-%d")

  sp_list <- lapply(names(sp_symbols), function(ctry) {
    sym <- sp_symbols[ctry]
    tryCatch({
      getSymbols(sym, src = "yahoo", from = sp_start, auto.assign = FALSE,
                 warnings = FALSE) %>%
        Cl() %>%
        as.data.frame() %>%
        rownames_to_column("date") %>%
        mutate(
          obstime = as.Date(date),
          country = ctry,
          ts_id   = "sp",
          value   = as.numeric(.[[2]])
        ) %>%
        select(country, obstime, ts_id, value) %>%
        filter(format(obstime, "%m") %in% c("03", "06", "09", "12")) %>%
        group_by(country, obstime = floor_date(obstime, "month")) %>%
        slice_tail(n = 1) %>%
        ungroup() %>%
        mutate(obstime = ceiling_date(obstime, "month") %m-% days(1))
    }, error = function(e) {
      message("  Yahoo Finance failed for ", ctry, " (", sym, "): ", conditionMessage(e))
      NULL
    })
  })

  bind_rows(sp_list) %>%
    filter(!is.na(value))
}

# Bond yields (monthly → quarterly, spread vs Germany)
raw_irlt <- fetch_oecd_sdmx(
  dataflow    = "OECD.SDD.STES,DSD_KEI@DF_KEI,4.0",
  key         = ".M.IRLT.PA.....",
  start_period = oecd_m_start,
  description = "bond yields"
)

oecd_irlt <- if (!is.null(raw_irlt)) {
  raw_irlt %>%
    select(any_of(c("REF_AREA", "TIME_PERIOD", "OBS_VALUE"))) %>%
    rename_with(~ c("ref_area", "TIME_PERIOD", "value")[seq_along(.)]) %>%
    mutate(
      date_m  = as.Date(paste0(TIME_PERIOD, "-01"), format = "%Y-%m-%d"),
      obstime = ceiling_date(date_m, "month") %m-% days(1),
      value   = as.numeric(value),
      country = countrycode(ref_area, "iso3c", "iso2c"),
      country = if_else(is.na(country), ref_area, country)
    ) %>%
    filter(format(obstime, "%m") %in% c("03", "06", "09", "12")) %>%
    select(country, obstime, value) %>%
    pivot_wider(names_from = country, values_from = value) %>%
    { if ("DE" %in% names(.))
        mutate(., across(-c(obstime, DE), ~ . - DE))
      else . } %>%
    pivot_longer(cols = -obstime, names_to = "country", values_to = "value") %>%
    mutate(ts_id = "sprd.bond") %>%
    select(country, obstime, ts_id, value) %>%
    filter(country %in% COUNTRIES, !is.na(value))
} else {
  tibble(country=character(), obstime=as.Date(character()), ts_id=character(), value=numeric())
}

oecd_new <- bind_rows(oecd_rre, oecd_sp, oecd_irlt)
oecd_vars_found <- unique(oecd_new$ts_id)
message("OECD new obs: ", nrow(oecd_new), " rows — variables: ",
        if (length(oecd_vars_found) > 0) paste(oecd_vars_found, collapse=", ") else "none")

###############################################################
# STEP 3: Combine new observations and bind to existing data
###############################################################

new_long <- bind_rows(bis_new, oecd_new) %>%
  arrange(country, obstime) %>%
  mutate(value = as.numeric(value))

new_quarters <- sort(unique(new_long$obstime))
message("Candidate new quarters: ", paste(format(new_quarters), collapse = ", "))

if (length(new_quarters) == 0) {
  message("No new observations. Dataset is already up to date.")
} else {
  new_wide <- new_long %>%
    pivot_wider(names_from = ts_id, values_from = value) %>%
    mutate(across(-c(country, obstime), as.numeric))

  required_vars <- setdiff(COL_ORDER, "obstime")

  for (ctry in COUNTRIES) {
    new_ctry <- new_wide %>%
      filter(country == ctry) %>%
      select(-country) %>%
      arrange(obstime)

    if (nrow(new_ctry) == 0) {
      message("  ", ctry, ": no new data"); next
    }

    # Only keep quarters where ALL required variables are present
    present_vars <- intersect(required_vars, names(new_ctry))
    missing_vars <- setdiff(required_vars, names(new_ctry))
    if (length(missing_vars) > 0) {
      message("  ", ctry, ": missing variables (", paste(missing_vars, collapse=", "),
              ") — these quarters will be skipped")
      next
    }

    new_ctry_clean <- new_ctry %>%
      filter(if_all(all_of(required_vars), ~ !is.na(.))) %>%
      select(all_of(COL_ORDER))

    if (nrow(new_ctry_clean) == 0) {
      message("  ", ctry, ": no complete quarters (NAs in required variables)"); next
    }

    df_country[[ctry]] <- bind_rows(df_country[[ctry]], new_ctry_clean) %>%
      distinct(obstime, .keep_all = TRUE) %>%
      arrange(obstime)

    new_end <- max(df_country[[ctry]]$obstime)
    message("  ", ctry, ": added ", nrow(new_ctry_clean), " quarter(s) → now through ", new_end)
  }
}

###############################################################
# STEP 4: Save
###############################################################

save(df_country, file = file.path(RAW_DIR, "df_country.RData"))
message("Saved: data/raw/df_country.RData")

new_max  <- as.Date(max(sapply(df_country, function(df) max(df$obstime))))
n_ctries <- length(df_country)

vintage_text <- paste0(
  "Vintage:       ", Sys.Date(), "\n",
  "Previous end:  ", cutoff, "\n",
  "New end date:  ", new_max, "\n",
  "Countries (", n_ctries, "): ", paste(names(df_country), collapse = ", "), "\n"
)
writeLines(vintage_text, file.path(RAW_DIR, "vintage.txt"))
message("\nRefresh complete.\n", vintage_text)
