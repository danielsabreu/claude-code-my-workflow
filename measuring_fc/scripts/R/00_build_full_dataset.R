###############################################################
# 00_build_full_dataset.R
# Financial Cycle — Full Dataset Build from Public APIs
#
# PURPOSE: Build data/raw/df_country.RData from scratch using
# BIS and OECD public data APIs. Run this instead of
# 00_refresh_data.R when a complete re-extraction is needed.
#
# NOT part of the replication package.
# After running, commit updated data/raw/ files.
#
# REQUIREMENTS: Internet access; BISdata, httr, quantmod
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
library(httr)
library(quantmod)

Sys.setlocale("LC_TIME", "C")

COUNTRIES  <- c("BE", "DE", "ES", "FI", "FR", "GB", "IT", "NL", "PT", "SE")
COL_ORDER  <- c("obstime", "cred.nfc", "cred.hh", "rhp", "sp", "dsr", "cred.2gdp", "sprd.bond")
FULL_START <- as.Date("1980-01-01")

###############################################################
# Helper
###############################################################

parse_bis_quarter <- function(x) {
  as.Date(as.yearqtr(paste(substr(x, 1, 4), substr(x, 7, 8), sep = "-")), frac = 1)
}

fetch_oecd_sdmx <- function(dataflow, key, start_period, description) {
  url <- paste0(
    "https://sdmx.oecd.org/public/rest/data/",
    dataflow, "/", key,
    "?startPeriod=", start_period,
    "&format=csvfilewithlabels"
  )
  message("Fetching OECD: ", description, " ...")
  resp <- tryCatch(GET(url, timeout(180)), error = function(e) {
    message("  Request failed: ", conditionMessage(e)); NULL
  })
  if (is.null(resp) || status_code(resp) != 200) {
    message("  OECD ", description, " status ",
            if (!is.null(resp)) status_code(resp) else "NA", " — skipping")
    return(NULL)
  }
  content(resp, as = "text", encoding = "UTF-8") %>%
    read_csv(show_col_types = FALSE)
}

###############################################################
# STEP 1: BIS — full bulk downloads
###############################################################

message("=== BIS credit (NFC + HH) ===")
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
  filter(obstime >= FULL_START, country %in% COUNTRIES, !is.na(value))
message("  BIS credit rows: ", nrow(bis_cred))

message("=== BIS credit-to-GDP + Basel gap ===")
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
  filter(obstime >= FULL_START, country %in% COUNTRIES, !is.na(value))

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
message("  Saved: basel_gap.RData (", nrow(bis_cred2gdp_gap), " rows)")

message("=== BIS DSR ===")
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
  filter(obstime >= FULL_START, country %in% COUNTRIES, !is.na(value))
message("  BIS DSR rows: ", nrow(bis_dsr))

bis_all <- bind_rows(bis_cred, bis_cred2gdp, bis_dsr)

###############################################################
# STEP 2: OECD — full history
###############################################################

message("=== OECD house prices (full history) ===")
raw_rhp <- fetch_oecd_sdmx(
  "OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,1.0",
  ".Q.RHP.IX", "1970-Q1", "house prices"
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
message("  House price rows: ", nrow(oecd_rre))

message("=== OECD share prices (full history) ===")
raw_sp <- fetch_oecd_sdmx(
  "OECD.SDD.STES,DSD_KEI@DF_KEI,4.0",
  ".M.SHARE.IX.....", "1970-01", "share prices (KEI)"
)
if (is.null(raw_sp)) {
  raw_sp <- fetch_oecd_sdmx(
    "OECD.SDD.STES,DSD_STES@DF_FINMARK,2.0",
    ".M.SHARE.IX.....", "1970-01", "share prices (FINMARK v2.0)"
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
  message("  OECD share prices unavailable — using Yahoo Finance (full history)")
  sp_symbols <- c(BE="^BFX", DE="^GDAXI", ES="^IBEX", FI="^OMXH25",
                  FR="^FCHI", GB="^FTSE",  IT="FTSEMIB.MI", NL="^AEX",
                  PT="PSI20.LS", SE="^OMX")
  sp_list <- lapply(names(sp_symbols), function(ctry) {
    tryCatch({
      getSymbols(sp_symbols[ctry], src="yahoo", from=format(FULL_START, "%Y-%m-%d"),
                 auto.assign=FALSE, warnings=FALSE) %>%
        Cl() %>% as.data.frame() %>% rownames_to_column("date") %>%
        mutate(obstime=as.Date(date), country=ctry, ts_id="sp",
               value=as.numeric(.[[2]])) %>%
        select(country, obstime, ts_id, value) %>%
        filter(format(obstime, "%m") %in% c("03","06","09","12")) %>%
        group_by(country, obstime=floor_date(obstime,"month")) %>%
        slice_tail(n=1) %>% ungroup() %>%
        mutate(obstime=ceiling_date(obstime,"month") %m-% days(1))
    }, error=function(e) { message("  Yahoo Finance failed for ", ctry); NULL })
  })
  bind_rows(sp_list) %>% filter(!is.na(value))
}
message("  Share price rows: ", nrow(oecd_sp))

message("=== OECD bond yields (full history) ===")
raw_irlt <- fetch_oecd_sdmx(
  "OECD.SDD.STES,DSD_KEI@DF_KEI,4.0",
  ".M.IRLT.PA.....", "1970-01", "bond yields"
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
message("  Bond yield spread rows: ", nrow(oecd_irlt))

oecd_all <- bind_rows(oecd_rre, oecd_sp, oecd_irlt)

###############################################################
# STEP 3: Assemble df_country
###############################################################

message("=== Assembling df_country ===")
all_long <- bind_rows(bis_all, oecd_all) %>%
  arrange(country, obstime) %>%
  mutate(value = as.numeric(value))

all_wide <- all_long %>%
  pivot_wider(names_from = ts_id, values_from = value) %>%
  mutate(across(-c(country, obstime), as.numeric))

required_vars <- setdiff(COL_ORDER, "obstime")

df_country <- lapply(COUNTRIES, function(ctry) {
  d <- all_wide %>%
    filter(country == ctry) %>%
    select(-country) %>%
    arrange(obstime)

  missing_vars <- setdiff(required_vars, names(d))
  if (length(missing_vars) > 0) {
    message("  ", ctry, ": missing — ", paste(missing_vars, collapse = ", "))
    return(NULL)
  }

  d_clean <- d %>%
    filter(if_all(all_of(required_vars), ~ !is.na(.))) %>%
    select(all_of(COL_ORDER))

  if (nrow(d_clean) == 0) { message("  ", ctry, ": no complete quarters"); return(NULL) }

  message("  ", ctry, ": ", nrow(d_clean), " quarters (",
          format(min(d_clean$obstime)), " – ", format(max(d_clean$obstime)), ")")
  d_clean
}) %>% setNames(COUNTRIES)

df_country <- df_country[!sapply(df_country, is.null)]

###############################################################
# STEP 4: Save
###############################################################

save(df_country, file = file.path(RAW_DIR, "df_country.RData"))
message("Saved: data/raw/df_country.RData (", length(df_country), " countries)")

new_max <- as.Date(max(sapply(df_country, function(df) max(df$obstime))))
new_min <- as.Date(min(sapply(df_country, function(df) min(df$obstime))))

vintage_text <- paste0(
  "Vintage:    ", Sys.Date(), "\n",
  "Build:      FULL rebuild from public APIs (BIS + OECD)\n",
  "Range:      ", new_min, " to ", new_max, "\n",
  "Countries (", length(df_country), "): ", paste(names(df_country), collapse = ", "), "\n"
)
writeLines(vintage_text, file.path(RAW_DIR, "vintage.txt"))
message("\nFull build complete.\n", vintage_text)
