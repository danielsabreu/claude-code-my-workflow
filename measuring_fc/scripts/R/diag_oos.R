# Diagnostic: compare old vs new OOS logic at 2006 Q1
# Goal: find which countries/quarters explain 28% -> 20% change

library(here)
source(here::here("scripts", "R", "auxiliary", "_paths.R"))
library(vars); library(dfms); library(seasonal); library(urca)
library(xts); library(tidyverse); library(zoo); library(readxl)
library(mFilter); library(reshape2); library(data.table); library(lubridate)

source(file.path(AUX_DIR, "trend_filterHP.R"))
source(file.path(AUX_DIR, "filterhp.R"))
source(file.path(AUX_DIR, "normalise.R"))
source(file.path(AUX_DIR, "getseas_v2.R"))
source(file.path(AUX_DIR, "getfilter.R"))
source(file.path(AUX_DIR, "transform_2yoy.R"))

load(file.path(RAW_DIR, "df_country.RData"))
load(file.path(RAW_DIR, "basel_gap.RData"))
esrb_path <- file.path(RAW_DIR, "esrb.fcdb20220120.en.xlsx")

# --- ESRB dates (same as 04_oos.R) ---
parse_esrb_dates <- function(df) {
  df %>%
    mutate(
      start.date = as.Date(paste(substr(`Start date`,1,4),substr(`Start date`,6,8),"01",sep="-"),format="%Y-%m-%d"),
      start.date = ceiling_date(start.date,"month") %m-% days(1),
      end.date   = as.Date(paste(substr(`End of crisis management date`,1,4),substr(`End of crisis management date`,6,8),"01",sep="-"),format="%Y-%m-%d"),
      end.date   = ceiling_date(end.date,"month") %m-% days(1),
      start.date.5  = start.date %m-% months(15),
      start.date.12 = start.date %m-% months(36),
      start.date.16 = start.date %m-% months(48),
      Country = ifelse(Country=="UK*","GB",Country)
    ) %>% dplyr::select(Country,start.date,end.date,start.date.5,start.date.12,start.date.16)
}

df_esrb_systemic <- read_xlsx(esrb_path,sheet="Systemic crises") %>%
  slice(-c(1,79:nrow(.))) %>% filter(Banking==1,`Macropru relevant`==1) %>% parse_esrb_dates()

df_esrb_residual <- read_xlsx(esrb_path,sheet="Residual events") %>%
  slice(-1) %>% filter(Banking==1,`Macropru relevant`==1) %>% parse_esrb_dates() %>%
  add_row(Country="PT",start.date=as.Date("1999-03-31"),end.date=as.Date("2000-03-31"),
          start.date.5=as.Date("1997-12-31"),start.date.12=as.Date("1996-03-31"),start.date.16=as.Date("1995-03-31")) %>%
  add_row(Country="NL",start.date=as.Date("2002-03-31"),end.date=as.Date("2003-12-31"),
          start.date.5=as.Date("2000-12-31"),start.date.12=as.Date("1999-03-31"),start.date.16=as.Date("1998-03-31"))

countries <- intersect(names(df_country), unique(df_esrb_systemic$Country))
min_rows  <- 88
df_country_filtered <- df_country[countries] %>%
  lapply(., function(df) if(nrow(df)>=min_rows) df else NULL)
for(exc in c("MX","PL","HU","CZ","NO")) df_country_filtered[[exc]] <- NULL
df_country_filtered <- df_country_filtered[!sapply(df_country_filtered,is.null)]

cat("Countries in OOS:", paste(sort(names(df_country_filtered)), collapse=", "), "\n")

# --- Crisis indicators ---
df_crisis <- lapply(df_country_filtered, function(df) df["obstime"]) %>%
  lapply(., function(df) df %>% mutate(crisis_systemic=0L,crisis_residual=0L))

df_crisis <- lapply(names(df_crisis), function(country) {
  df_crisis[[country]] %>% rowwise() %>%
    mutate(
      crisis_systemic.5.12 = as.integer(any(
        obstime >= df_esrb_systemic[df_esrb_systemic$Country==country,"start.date.12",drop=TRUE] &
        obstime <= df_esrb_systemic[df_esrb_systemic$Country==country,"start.date.5",drop=TRUE])),
      crisis_residual.5.12 = as.integer(any(
        obstime >= df_esrb_residual[df_esrb_residual$Country==country,"start.date.12",drop=TRUE] &
        obstime <= df_esrb_residual[df_esrb_residual$Country==country,"start.date.5",drop=TRUE])),
      crisis_total.5.12 = crisis_systemic.5.12 + crisis_residual.5.12
    ) %>% ungroup()
}) %>% setNames(names(df_country_filtered))

# --- Check variation in crisis_total.5.12 for each country at 2006 Q1 ---
quarter <- as.Date("2006-03-31")
cat("\n=== Crisis variation check at 2006 Q1 ===\n")
for(ctry in names(df_crisis)) {
  td <- df_crisis[[ctry]] %>% filter(obstime <= quarter)
  n1 <- sum(td$crisis_total.5.12, na.rm=TRUE)
  n0 <- sum(td$crisis_total.5.12==0, na.rm=TRUE)
  cat(ctry, ": n_obs=", nrow(td), " | crisis_total.5.12: n1=", n1, " n0=", n0, "\n")
}
