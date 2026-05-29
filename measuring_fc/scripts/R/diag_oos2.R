# Test: run OOS with OLD logic (no guard) vs NEW (with guard)
# Focus on 2007 Q1 (peak quarter) to measure IT's old prediction

library(here); source(here::here("scripts","R","auxiliary","_paths.R"))
source(file.path(here::here("scripts","R","auxiliary"),"_theme.R"))
library(vars); library(dfms); library(seasonal); library(urca); library(xts)
library(tidyverse); library(zoo); library(readxl); library(writexl); library(mFilter)
library(reshape2); library(data.table); library(lubridate)
source(file.path(AUX_DIR,"trend_filterHP.R")); source(file.path(AUX_DIR,"filterhp.R"))
source(file.path(AUX_DIR,"normalise.R")); source(file.path(AUX_DIR,"getseas_v2.R"))
source(file.path(AUX_DIR,"getfilter.R")); source(file.path(AUX_DIR,"transform_2yoy.R"))

load(file.path(RAW_DIR,"df_country.RData"))
load(file.path(RAW_DIR,"basel_gap.RData"))
esrb_path <- file.path(RAW_DIR,"esrb.fcdb20220120.en.xlsx")

parse_esrb_dates <- function(df) {
  df %>% mutate(
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

df_crisis <- lapply(df_country_filtered, function(df) df["obstime"]) %>%
  lapply(., function(df) df %>% mutate(crisis_systemic=0L,crisis_residual=0L))
df_crisis <- lapply(names(df_crisis), function(country) {
  df_crisis[[country]] %>% rowwise() %>%
    mutate(
      crisis_systemic.5.12 = as.integer(any(obstime >= df_esrb_systemic[df_esrb_systemic$Country==country,"start.date.12",drop=TRUE] & obstime <= df_esrb_systemic[df_esrb_systemic$Country==country,"start.date.5",drop=TRUE])),
      crisis_residual.5.12 = as.integer(any(obstime >= df_esrb_residual[df_esrb_residual$Country==country,"start.date.12",drop=TRUE] & obstime <= df_esrb_residual[df_esrb_residual$Country==country,"start.date.5",drop=TRUE])),
      crisis_total = crisis_systemic.5.12 + crisis_residual.5.12,
      crisis_total.5.12 = crisis_total
    ) %>% ungroup()
}) %>% setNames(names(df_country_filtered))

quarter <- as.Date("2007-03-31")
message("Running OOS for 2007 Q1 (peak quarter)...")
df_subset <- lapply(df_country_filtered, function(df) filter(df, obstime <= quarter))
df_country_trans <- df_subset %>%
  lapply(.,transform_2yoy) %>% lapply(.,getseas, trans=FALSE) %>%
  lapply(.,function(df) {
    obstime <- as.Date(df[nrow(df),1]) %m+% months(3)
    df[,1] <- as.Date(df[,1])
    df_bw <- rbind(df, cbind(obstime, df[nrow(df),2:ncol(df)]))
    df_cycle <- getfilter(df_bw,filter="BW",freq=25,nfix=2,drift=FALSE)$cycle
    df_cycle <- getfilter(df_cycle,filter="BW",freq=4,nfix=4,drift=FALSE)$trend
    df_cycle[-nrow(df_cycle),]
  })
for(i in seq_along(df_country_trans)) {
  aux1 <- c(rep(NA,8), diff(df_subset[[i]]$sprd.bond, lag=8))
  df_country_trans[[i]]$sprd.bond.roc.2yoy <- aux1
  colnames(df_country_trans[[i]])[ncol(df_country_trans[[i]])] <- "sprd.bond.diff.2y"
}
df_model_oos <- df_country_trans %>%
  lapply(., function(df_input) {
    norm_data <- normalise(df_input[,2:ncol(df_input)])
    out <- cbind(as.Date(df_input[,1]), norm_data); names(out)[1] <- "obstime"; out
  }) %>% lapply(.,na.omit)
df_dfm_oos <- df_model_oos %>% lapply(., function(df) {
  obstime <- df[,1]; dfm <- DFM(df[,2:ncol(df)],r=1,p=4)
  data.frame(obstime=as.Date(obstime), pca=as.numeric(dfm$F_pca), qml=as.numeric(dfm$F_qml), tstep=as.numeric(dfm$F_2s))
})
df_dec_oos <- lapply(seq_along(df_model_oos), function(i) {
  dt_m <- as.data.table(df_model_oos[[i]]); dt_d <- as.data.table(df_dfm_oos[[i]])
  dt_m[,obstime:=as.Date(obstime)]; dt_d[,obstime:=as.Date(obstime)]
  setDF(merge(dt_m,dt_d,by="obstime",all.x=TRUE))
}) %>% setNames(names(df_dfm_oos))
df_ew_q <- lapply(names(df_dec_oos), function(country) {
  left_join(df_dec_oos[[country]], df_crisis[[country]], by="obstime")
}) %>% setNames(names(df_dec_oos))
df_ew_bis_q <- lapply(names(df_ew_q), function(cc) {
  cd <- bis_cred2gdp_gap %>% filter(country==cc) %>% dplyr::select(obstime,basel.gap)
  left_join(df_ew_q[[cc]], cd, by="obstime")
}) %>% setNames(names(df_ew_q))

# Run logits with OLD logic (no guard) and NEW logic (guard) for each country
indicators <- c("pca","qml","tstep","cred.nfc.roc.2yoy","cred.hh.roc.2yoy","rhp.roc.2yoy","sp.roc.2yoy","dsr.roc.2yoy","cred.2gdp.roc.2yoy","sprd.bond.diff.2y","basel.gap")
results <- lapply(names(df_ew_bis_q), function(country) {
  test_data <- df_ew_bis_q[[country]]
  target_data <- df_crisis[[country]]
  oos_row <- test_data[test_data$obstime == quarter,]
  oos_row$crisis_total.5.12 <- target_data[target_data$obstime == (quarter %m+% years(1)),"crisis_total",drop=TRUE]
  
  pred_old <- NA; pred_new <- NA
  # OLD logic: no guard
  tryCatch({
    mdl <- glm(crisis_total.5.12 ~ pca, family=binomial(link="logit"), data=test_data)
    pred_old <- predict(mdl, newdata=oos_row, type="response") * 100
  }, error=function(e) NULL)
  # NEW logic: with guard
  resp_vals <- na.omit(test_data[["crisis_total.5.12"]])
  ind_vals  <- na.omit(test_data[["pca"]])
  if(length(unique(resp_vals)) >= 2 && length(ind_vals) > 0) {
    tryCatch({
      mdl <- glm(crisis_total.5.12 ~ pca, family=binomial(link="logit"), data=test_data)
      pred_new <- predict(mdl, newdata=oos_row, type="response") * 100
    }, error=function(e) NULL)
  }
  n1 <- sum(test_data$crisis_total.5.12, na.rm=TRUE)
  n0 <- sum(test_data$crisis_total.5.12==0, na.rm=TRUE)
  data.frame(country=country, n1=n1, n0=n0, pred_old=round(pred_old,2), pred_new=round(pred_new,2))
}) %>% bind_rows()
cat("\n=== 2007 Q1 predictions: OLD (no guard) vs NEW (with guard) ===\n")
print(results)
cat("\nMedian OLD:", round(median(results$pred_old, na.rm=TRUE),1), "%\n")
cat("Median NEW:", round(median(results$pred_new, na.rm=TRUE),1), "%\n")
