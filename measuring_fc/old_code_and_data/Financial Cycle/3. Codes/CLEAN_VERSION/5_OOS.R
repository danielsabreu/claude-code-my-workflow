
rm(list=ls())

setwd("G:/6.APM/Financial Cycle")

###############################################
# Preamble
###############################################

# Load necessary libraries
library(vars)
library(nowcasting)
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
library(rmsumst)
library(data.table)
library(ggthemes)

# Source auxiliary functions
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/trend_filterHP.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/filterhp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/normalise.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getseas_v2.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getfilter.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/transform_2yoy.R")
#source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/BW_filter.R")


################################################
## Out-of-sample EW analysis - Logit estimation
################################################

load("G:/6.APM/Financial Cycle/2. Data/df_country.RData")

# Credit2gdp
bis_vars <- c("P:A:B") # Credit-to-GDP trend (HP filter)
bis_cred2gdp <- fetch_dataset(dest.dir = tempdir(),bis.url ="https://data.bis.org/static/bulk/", "WS_CREDIT_GAP_csv_col.zip") %>% 
  mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>% 
  filter(ts_id %in% bis_vars) %>% 
  dplyr::select(which(names(.) == "Series"):(ncol(.)-1)) %>% 
  pivot_longer(cols = !Series, names_to ="variable",values_to="value") %>% 
  mutate(country = substr(Series,3,4)) %>%  
  rename(obstime = variable, ts_id = Series) %>% 
  dplyr::select(country, obstime, ts_id, value) %>% 
  mutate(obstime=as.Date(as.yearqtr(paste(substr(obstime,1,4),substr(obstime,7,8),sep="-")),frac = 1)) %>% 
  mutate(ts_id = sub("^[^:]*:[^:]*:", "", ts_id))

df_esrb_systemic <- read_xlsx("G:/6.APM/Financial Cycle/2. Data/esrb.fcdb20220120.en.xlsx", sheet = "Systemic crises") %>%
  slice(-c(1,79:nrow(.))) %>% 
  filter(Banking == 1, `Macropru relevant` == 1) %>% 
  mutate(start.date = as.Date(paste(substr(`Start date`,1,4),substr(`Start date`,6,8),"01",sep="-"),format = "%Y-%m-%d")) %>% 
  mutate(start.date = ceiling_date(start.date,"month") %m-% days(1)) %>%                   
  mutate(end.date = as.Date(paste(substr(`End of crisis management date`,1,4),substr(`End of crisis management date`,6,8),"01",sep="-"),format = "%Y-%m-%d")) %>% 
  mutate(end.date = ceiling_date(end.date,"month") %m-% days(1)) %>% 
  dplyr::select(Country, start.date, end.date) %>% 
  mutate(start.date.5 = start.date %m-% months(15), start.date.12 = start.date %m-% months(36), start.date.16 = start.date %m-% months(48)) %>% 
  mutate(Country = ifelse(Country == "UK*","GB",Country))

df_esrb_residual <- read_xlsx("G:/6.APM/Financial Cycle/2. Data/esrb.fcdb20220120.en.xlsx", sheet = "Residual events") %>%
  slice(-1) %>% 
  filter(Banking == 1, `Macropru relevant` == 1) %>% 
  mutate(start.date = as.Date(paste(substr(`Start date`,1,4),substr(`Start date`,6,8),"01",sep="-"),format = "%Y-%m-%d")) %>% 
  mutate(start.date = ceiling_date(start.date,"month") %m-% days(1)) %>%                   
  mutate(end.date = as.Date(paste(substr(`End of crisis management date`,1,4),substr(`End of crisis management date`,6,8),"01",sep="-"),format = "%Y-%m-%d")) %>% 
  mutate(end.date = ceiling_date(end.date,"month") %m-% days(1)) %>% 
  dplyr::select(Country, start.date, end.date) %>% 
  mutate(start.date.5 = start.date %m-% months(15), start.date.12 = start.date %m-% months(36), start.date.16 = start.date %m-% months(48)) %>% 
  mutate(Country = ifelse(Country == "UK*","GB",Country)) %>% 
  add_row(Country = "PT", start.date = as.Date("1999-03-31"), end.date = as.Date("2000-03-31"), start.date.5 = as.Date("1997-12-31"), start.date.12 = as.Date("1996-03-31"), start.date.16 = as.Date("1995-03-31")) %>% 
  add_row(Country = "NL", start.date = as.Date("2002-03-31"), end.date = as.Date("2003-12-31"), start.date.5 = as.Date("2000-12-31"), start.date.12 = as.Date("1999-03-31"), start.date.16 = as.Date("1998-03-31")) 


# Prepare file for early warning analysis
countries <- intersect(names(df_country), unique(df_esrb_systemic$Country))
min_rows <- 88  # nrow of the PT df
df_country_filtered <- df_country[countries] %>% 
  lapply(., function(df) {if (nrow(df) >= min_rows) return(df) else return (NULL)})

df_country_filtered$MX <- NULL # Exclude because of missing observations in sprd.bond
df_country_filtered$PL <- NULL # Exclude because of missing observations in rhp
df_country_filtered$HU <- NULL # Exclude because of missing observations in rhp
df_country_filtered$CZ <- NULL # Exclude because of missing observations in rhp
df_country_filtered$NO <- NULL # Exclude because of missing very small sample due to short dsr

df_crisis <- lapply(df_country_filtered, function(df) {df <- df["obstime"]}) %>% 
  lapply(., function(df) {df %>% mutate(crisis_systemic = 0, crisis_residual = 0)})

df_crisis <- lapply(names(df_crisis), function(country) {
  df_crisis[[country]] %>%
    rowwise() %>%
    mutate(
      crisis_systemic = ifelse(
        any(obstime >= df_esrb_systemic %>%
              filter(Country == country) %>%
              pull(start.date) &
              obstime <= df_esrb_systemic %>%
              filter(Country == country) %>%
              pull(end.date)),
        1, 0),
      crisis_systemic.5.12 = ifelse(
        any(obstime >= df_esrb_systemic %>%
              filter(Country == country) %>%
              pull(start.date.12) &
              obstime <= df_esrb_systemic %>%
              filter(Country == country) %>%
              pull(start.date.5)),
        1, 0),
      crisis_systemic.5.16 = ifelse(
        any(obstime >= df_esrb_systemic %>%
              filter(Country == country) %>%
              pull(start.date.16) &
              obstime <= df_esrb_systemic %>%
              filter(Country == country) %>%
              pull(start.date.5)),
        1, 0),
      crisis_residual = ifelse(
        any(obstime >= df_esrb_residual %>%
              filter(Country == country) %>%
              pull(start.date) &
              obstime <= df_esrb_residual %>%
              filter(Country == country) %>%
              pull(end.date)),
        1, 0),
      crisis_residual.5.12 = ifelse(
        any(obstime >= df_esrb_residual %>%
              filter(Country == country) %>%
              pull(start.date.12) &
              obstime <= df_esrb_residual %>%  
              filter(Country == country) %>%
              pull(start.date.5)),
        1, 0),
      crisis_residual.5.16 = ifelse(
        any(obstime >= df_esrb_residual %>%
              filter(Country == country) %>%
              pull(start.date.16) &
              obstime <= df_esrb_residual %>%  
              filter(Country == country) %>%
              pull(start.date.5)),
        1, 0),
      crisis_total = crisis_systemic + crisis_residual,
      crisis_total.5.12 = crisis_systemic.5.12+ crisis_residual.5.12,
      crisis_total.5.16 = crisis_systemic.5.16+ crisis_residual.5.16) %>%
    ungroup()
})

names(df_crisis) <- names(df_country_filtered)

start_date<- as.Date("2006-03-31")
end_date <- as.Date("2009-03-31")
oos_dates <- df_crisis$SE$obstime[df_crisis$SE$obstime >= start_date & df_crisis$SE$obstime <= end_date]


indicators <- c("pca", "qml", "tstep", "cred.nfc.roc.2yoy", "cred.hh.roc.2yoy","rhp.roc.2yoy", "sp.roc.2yoy", "dsr.roc.2yoy","cred.2gdp.roc.2yoy", "sprd.bond.diff.2y", "basel.gap")
df_oos <- data.frame(matrix(nrow = 1, ncol = 13))
colnames(df_oos) <- c("quarter","country", indicators)

for (quarter in oos_dates) {
  print(as.Date(quarter))
  df_subset <- lapply(df_country_filtered, function(df){ filter(df, obstime <= quarter) })
  
  df_country_trans <- df_subset %>%
    lapply(.,transform_2yoy) %>%
    lapply(.,getseas, trans = F) %>%
    lapply(.,function(df) {
      obstime <-  as.Date(df[nrow(df),1]) %m+% months(3)
      df[,1] <- as.Date(df[,1])
      df_bw <- rbind(df,cbind(obstime,df[nrow(df),2:ncol(df)]))
      df_bw_cycle <- getfilter(df_bw,filter="BW",freq=25,nfix = 2,drift=FALSE)$cycle
      df_bw_cycle <- getfilter(df_bw_cycle,filter="BW",freq = 4 ,nfix = 4,drift=FALSE)$trend
      df_bw_cycle <- df_bw_cycle[-nrow(df_bw_cycle),]
      return(df_bw_cycle)
    })
  
  for (i in 1:length(df_country_trans)) {
    aux1 <- c(rep(NA, 8), diff(df_subset[[i]]$sprd.bond, lag = 8)) # Add NA to align length
    df_country_trans[[i]]$sprd.bond.roc.2yoy <- aux1
    colnames(df_country_trans[[i]])[ncol(df_country_trans[[i]])] <- "sprd.bond.diff.2y"
  }
  
  df_model <- df_country_trans %>%
    lapply(.,function(df_input) {
      normalized_data <- normalise(df_input[, 2:ncol(df_input)])
      df <- cbind(df_input[, 1], normalized_data)
      df[, 1] <- as.Date(df_input[, 1])
      names(df)[1] <- "obstime"
      return(df)
    }) %>%
    lapply(.,na.omit)  
  
  df_dfm <- df_model %>% 
    lapply(., function(df) {
      obstime <- df[,1]
      dfm <- DFM(df[,2:ncol(df)], r = 1, p = 4)
      pca <- dfm$F_pca
      qml <- dfm$F_qml
      tstep <- dfm$F_2s
      dfm <- data.frame(obstime=obstime,pca,qml,tstep)
      colnames(dfm) <- c("obstime","pca","qml","tstep")
      dfm[,1] <- as.Date(dfm[,1])
      return(dfm)
    }
    )
  
  df_dec <- lapply(seq_along(df_model), function(i) {
    dt_model <- as.data.table(df_model[[i]])  
    dt_dfm <- as.data.table(df_dfm[[i]])      
    dt_model[, obstime := as.Date(obstime)]
    dt_dfm[, obstime := as.Date(obstime)]
    df_result <- merge(dt_model, dt_dfm, by = "obstime", all.x = TRUE)
    setDF(df_result)  
    df_result
  })
  
  names(df_dec) <- names(df_dfm)
  
  df_ew <- lapply(names(df_dec), function(country) {aux1 <- df_dec[[country]] 
  aux2 <- df_crisis[[country]]
  out <- left_join(aux1, aux2, by = "obstime")
  return(out)})
  names(df_ew) <- names(df_dec)
  
  # Join bis data with the crisis indicators
  df_ew_bis <- lapply(names(df_ew), function(country_code) {
    
    country_data <- bis_cred2gdp %>%
      filter(country == country_code) %>%
      mutate(ts_id = recode(ts_id, `P:A:B` = "basel.gap")) %>% 
      pivot_wider(names_from = ts_id, values_from = value) %>% 
      dplyr::select(obstime,basel.gap)
    
    merged_df <- left_join(df_ew[[country_code]], country_data, by = c("obstime" = "obstime"))
    return(merged_df)
  })
  
  names(df_ew_bis) <- names(df_ew)
  
  oos_results <- lapply(names(df_ew_bis), function(country) {
    
    test_data <- df_ew_bis[[country]]
    target_data <- df_crisis[[country]]
    
    oos_data <- test_data[test_data$obstime == as.Date(quarter), ]
    # IMPORTANT NOTE: IN THE OOS DATA WE DEFINE CRISIS.TOTAL AS THE TARGET VARIABLES. WE SUBSTITUTE IT INTO CRISIS.TOTAL.5.12 TO FACILITATE THE GLM COMMANDS BELOW  
    oos_data$crisis_total.5.12 <- target_data[target_data$obstime == (as.Date(quarter) %m+% years(1)), "crisis_total", drop = TRUE]
    
    indicators <- c("pca", "qml", "tstep", "cred.nfc.roc.2yoy", "cred.hh.roc.2yoy","rhp.roc.2yoy", "sp.roc.2yoy", "dsr.roc.2yoy","cred.2gdp.roc.2yoy", "sprd.bond.diff.2y", "basel.gap")
    oos_pred <- data.frame(matrix(ncol = length(indicators), nrow = 1))
    colnames(oos_pred) <- indicators
    
    for (j in 1:length(indicators)) {
      formula <- as.formula(paste("crisis_total.5.12 ~", indicators[j]))
      glm_model <- glm(formula, family = binomial(link = "logit"), data = test_data)
      glm_pred <- predict(glm_model, newdata = oos_data, type = "response")
      oos_pred[,j] <- glm_pred*100
    }           
    
    return(oos_pred)
    
  })
  
  names(oos_results) <- names(df_ew_bis)
  out <- bind_rows(oos_results, .id = "country")
  out <- cbind(quarter, out)
  
  df_oos <- rbind(df_oos, out)
  
}

df_oos <- df_oos[-1,] 
df_oos$quarter <- as.Date(df_oos$quarter)

oos_graph <- df_oos %>% 
             group_by(quarter) %>% 
             summarise(pca_median = median(pca),
                       basel_gap_median = median(basel.gap),
                       pca_q25 = quantile(pca, 0.25),
                       pca_q75 = quantile(pca, 0.75),
                       basel_gap_q25 = quantile(basel.gap, 0.25),
                       basel_gap_q75 = quantile(basel.gap, 0.75)
                       )

oos_graph_index <- oos_graph %>% 
                   mutate(pca_median = pca_median/ pca_median[1],
                          pca_q25 = pca_q25/ pca_q25[1],
                          pca_q75 = pca_q75/pca_q75[1])

# Probability of crisis
png("oos_graph.png", width = 868, height = 422)
ggplot(oos_graph, aes(x = quarter)) +
  geom_line(aes(y = pca_median), color = "blue", size = 1) +
  geom_line(aes(y = pca_q75), linetype = "dashed", color = "black") +
  geom_line(aes(y = pca_q25), linetype = "dashed", color = "black") +
  scale_x_date(
    breaks = as.Date(c("2006-03-31", "2007-03-31", "2008-03-31", "2009-03-31")),  # Specify the exact years
    labels = c("2006", "2007", "2008", "2009")  # Labels for the ticks
  ) +
  scale_y_continuous(breaks = seq(0, 30, by = 5)) +  # Adjust y-axis ticks as needed
  labs(
    title = "",
    x = "",
    y = ""
  ) +
  theme_base()
dev.off()

# index
ggplot(oos_graph_index, aes(x = quarter)) +
  geom_line(aes(y = pca_median), color = "blue", size = 1) +
  labs(title = "",
       x = "",
       y = "") +
  theme_base()

