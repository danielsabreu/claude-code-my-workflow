###############################################
# Preamble
###############################################

rm(list=ls())

lct <- Sys.getlocale("LC_TIME"); Sys.setlocale("LC_TIME", "C")

#devtools::install_github("expersso/BIS")
#remotes::install_github("https://github.com/expersso/OECD") ##  There is a bug in the version of the OECD package on CRAN

library(xts)
library(tidyverse)
library(zoo)
library(lubridate)
library(readxl)
library(writexl)
library(OECD)
library(BISdata)
library(countrycode)
library(dplyr)

###############################################
# BIS
###############################################

# Credit 
bis_vars <- c("N:A:M:XDC:A", # Credit to Non-financial corporations from All sectors at Market value - Domestic currency - Adjusted for breaks
              "H:A:M:XDC:A")  # Credit to Households and NPISHs from All sectors at Market value - Domestic currency - Adjusted for breaks
               
bis_cred <- fetch_dataset(dest.dir = tempdir(),bis.url ="https://data.bis.org/static/bulk/", "WS_TC_csv_col.zip") %>% 
            mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>% 
            filter(ts_id %in% bis_vars) %>% 
            select(which(names(.) == "Series"):(ncol(.)-1)) %>% 
            pivot_longer(cols = !Series, names_to ="variable",values_to="value") 

# Credit2gdp
bis_vars <- c("P:A:A")  # Credit-to-GDP ratios (actual data)
bis_cred2gdp <- fetch_dataset(dest.dir = tempdir(),bis.url ="https://data.bis.org/static/bulk/", "WS_CREDIT_GAP_csv_col.zip") %>% 
                   mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>% 
                   filter(ts_id %in% bis_vars) %>% 
                   select(which(names(.) == "Series"):(ncol(.)-1)) %>% 
                   pivot_longer(cols = !Series, names_to ="variable",values_to="value")

# DSR
bis_vars <- c("P") # DSR - Portugal - Private non-financial sector
bis_dsr <- fetch_dataset(dest.dir = tempdir(),bis.url ="https://data.bis.org/static/bulk/", "WS_DSR_csv_col.zip") %>% 
           mutate(ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>% 
           filter(ts_id %in% bis_vars) %>% 
           select(which(names(.) == "Series"):(ncol(.)-1)) %>% 
           pivot_longer(cols = !Series, names_to ="variable",values_to="value")

# Merge BIS data
bis_data <- rbind(bis_cred,bis_dsr,bis_cred2gdp) %>% 
            rename(obstime = variable) %>%
            mutate(obstime = as.Date(as.yearqtr(paste(substr(obstime,1,4),substr(obstime,7,8),sep="-")),frac = 1),
                   country = substr(sub("^[^:]*:", "", Series), 1, 2),
                   ts_id = sub("^[^:]*:[^:]*:", "", Series)) %>%
            select(-Series) %>% 
            select(country,obstime,ts_id,value)

# Backcast DSR using CCyB taskforce 
SRIs_20180530_including_readme <- read_excel("G:\\6.APM\\Financial Cycle\\2. Data\\SRIs_20180530_including_readme.xlsx", sheet = "Data")

dsr_tf <- SRIs_20180530_including_readme %>% 
          select(.,country,obstime,DSR) %>% 
          group_by(country) %>% 
          rename(dsr.tf = DSR) %>% 
          mutate(dsr.tf.roc.1q = dsr.tf/lag(dsr.tf)-1)

dsr_new <- bis_data %>% 
           pivot_wider(names_from = ts_id, values_from = value) %>% 
           select(country,obstime,P) %>% 
           rename(dsr.bis = P) %>% 
           full_join(.,dsr_tf, by = c("country","obstime")) %>% 
           group_by(country) %>% 
           mutate(value = dsr.bis) %>% 
           mutate(value = {
             for (i in length(country):1) {
               if (is.na(value[i])==TRUE && is.na(dsr.tf.roc.1q[i+1])==FALSE) {
                 value[i] <- value[i+1] / (1 + dsr.tf.roc.1q[i+1])

               }
             }
             value
           }) %>% 
           mutate(ts_id = "dsr") %>% 
           select(country,obstime,ts_id,value) 

# Final BIS data
bis_data <- rbind(bis_data,dsr_new) %>% filter(ts_id!="P") %>% na.omit(.)      

###############################################
# OECD
###############################################

# Real house price indices, s.a.
oecd_rre <- get_dataset("OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,", ".Q.RHP.IX") %>% 
            select(REF_AREA,MEASURE, ObsValue,TIME_PERIOD) %>% 
            mutate(TIME_PERIOD = as.yearqtr(TIME_PERIOD, format = "%Y-Q%q")) %>%
            mutate(TIME_PERIOD = as.Date(as.yearqtr(paste(substr(TIME_PERIOD,1,4),substr(TIME_PERIOD,7,8),sep="-")),frac = 1))

# Share prices (month-on-month roc)
oecd_sp <- get_dataset(dataset = "OECD.SDD.STES,DSD_STES@DF_FINMARK,", ".M.SHARE.IX.....") %>% 
           select(REF_AREA,MEASURE, ObsValue,TIME_PERIOD) %>% 
           mutate(TIME_PERIOD=as.Date(paste(substr(TIME_PERIOD,1,4),substr(TIME_PERIOD,6,8),"01",sep="-"),format = "%Y-%m-%d")) %>%
           mutate(TIME_PERIOD = ceiling_date(TIME_PERIOD,"month") %m-% days(1))

# 10Y Bond yields and spreads
oecd_irlt <- get_dataset(dataset = "OECD.SDD.STES,DSD_KEI@DF_KEI,4.0", ".M.IRLT.PA.....") %>% 
             select(REF_AREA,MEASURE, ObsValue,TIME_PERIOD) %>% 
             mutate(TIME_PERIOD=as.Date(paste(substr(TIME_PERIOD,1,4),substr(TIME_PERIOD,6,8),"01",sep="-"),format = "%Y-%m-%d")) %>%
             mutate(TIME_PERIOD = ceiling_date(TIME_PERIOD,"month") %m-% days(1)) %>% 
             pivot_wider(., names_from = REF_AREA, values_from = ObsValue) %>% 
             mutate(across(-c(TIME_PERIOD, MEASURE), as.numeric)) %>% 
             mutate(across(-c(MEASURE,TIME_PERIOD,DEU), ~ . - DEU)) %>% 
             pivot_longer(cols = -c(MEASURE,TIME_PERIOD), names_to = "REF_AREA", values_to = "ObsValue")

oecd_data <- rbind(oecd_rre,oecd_sp,oecd_irlt) %>% 
             rename(obstime = TIME_PERIOD, ts_id=MEASURE, ref_area = REF_AREA, value = ObsValue) %>% 
             filter(format(obstime, "%m") %in% c("03", "06", "09", "12")) %>% # keep only end of quarter observations
             mutate(country = countrycode(ref_area, "iso3c", "iso2c")) %>%
             mutate(country = if_else(is.na(country), ref_area, country)) %>% 
             select(country,obstime,ts_id,value) %>% 
             na.omit(.) 


###############################################
# Join data per country
###############################################

df_long <- rbind(oecd_data,bis_data) %>% 
           arrange(obstime) %>%
           na.omit() %>% 
           mutate(ts_id = recode(ts_id,
                                 "RHP" = "rhp" ,
                                 "SHARE" = "sp",
                                 "IRLT" = "sprd.bond",
                                 "N:A:M:XDC:A" = "cred.nfc",
                                 "H:A:M:XDC:A" = "cred.hh",
                                 "P:A:A" = "cred.2gdp"))


col_order <- c("obstime", "cred.nfc", "cred.hh", "rhp", "sp", "dsr", "cred.2gdp", "sprd.bond")
df_country <- df_long %>%  
  group_by(country) %>%  
  nest() %>%  # Nest data by country  
  mutate(wide_data = map(data, ~ pivot_wider(.x, names_from = ts_id, values_from = value))) %>%  
  filter(map_int(wide_data, ~ ncol(.))==8) %>%   # filter for countries with all indicators available          
  mutate(wide_data = map(wide_data, ~ .x %>% select(all_of(col_order)))) %>%
  select(country, wide_data) %>%
  deframe()

df_country <- lapply(df_country, function(df) {
              mutate(df, across(-c(obstime), as.numeric))
})

###############################################
# Export data
###############################################

save(df_country, file = "2. Data/df_country.RData")