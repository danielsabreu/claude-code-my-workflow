###############################################
# Preamble: Setup and Libraries
###############################################

# Clean environment
rm(list=ls())

# Set working directory
setwd("G:/6.APM/Financial Cycle")

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

# Source auxiliary functions
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/trend_filterHP.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/filterhp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/normalise.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getseas_v2.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getfilter.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/transform_2yoy.R")
#source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/BW_filter.R")

###############################################
# Load and Merge Data
###############################################

# Load the main dataset
load("G:/6.APM/Financial Cycle/2. Data/df_country.RData")

#############################################################################
# Transformations (cut.off, 2-Year Growth Rates, filtering, normalisation)
#############################################################################

df_country$MX <- NULL # Exclude MX because of missing observations in sprd.bond
# df_country <- lapply(df_country, function(df) {
#                 df <- df[df$obstime <= "2024-09-30", ]
#                 return(df)
#               })

# Use this block for "indicator without filter"
# df_country_trans <- df_country %>%
#   lapply(.,transform_2yoy) %>%
#   lapply(.,getseas, trans = F)

# Use this block for "indicator with filter" 
df_country_trans <- df_country %>%
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
  aux1 <- c(rep(NA, 8), diff(df_country[[i]]$sprd.bond, lag = 8)) # Add NA to align length
  df_country_trans[[i]]$sprd.bond.roc.2yoy <- aux1
  colnames(df_country_trans[[i]])[ncol(df_country_trans[[i]])] <- "sprd.bond.diff.2y"
}

df_country_trans <- df_country_trans %>%
                    lapply(.,function(df_input) {
                        normalized_data <- normalise(df_input[, 2:ncol(df_input)])
                        df <- cbind(df_input[, 1], normalized_data)
                        df[, 1] <- as.Date(df_input[, 1])
                        names(df)[1] <- "obstime"
                        return(df)
                    }) %>%
                    lapply(.,na.omit)

# Filter for countries with a minimum number of rows
min_rows <- 88  # nrow of the PT df
filtered_list <- lapply(df_country_trans, function(df) {
  if (nrow(df) >= min_rows) return(df) else return(NULL)
})

df_model <- filtered_list[!sapply(filtered_list, is.null)]

# Save files
save(df_model, file = "2. Data/df_model.RData")


###########################
# Descriptive statistics
###########################

df_smst <- df_country %>% lapply(.,transform_2yoy)

for (i in 1:length(df_smst)) {
  aux1 <- c(rep(NA, 8), diff(df_country[[i]]$sprd.bond, lag = 8)) # Add NA to align length
  df_smst[[i]]$sprd.bond.roc.2yoy <- aux1
  colnames(df_smst[[i]])[ncol(df_smst[[i]])] <- "sprd.bond.diff.2y"
}

df_smst <- lapply(df_smst,na.omit) 
df_smst <- bind_rows(df_smst, .id = "country")

summary_stats <- df_smst %>%
                 group_by(country) %>%
                 summarize(nobs = n(),
                           
                           sd_cred_nfc = sd(cred.nfc.roc.2yoy, na.rm = TRUE),
                           mean_cred_nfc = mean(cred.nfc.roc.2yoy),
                           
                           sd_cred_hh = sd(cred.hh.roc.2yoy),
                           mean_cred_hh = mean(cred.hh.roc.2yoy),
                           
                           sd_rhp.roc.2yoy = sd(rhp.roc.2yoy),
                           mean_rhp.roc.2yoy = mean(rhp.roc.2yoy),
                           
                           sd_sp.roc.2yoy = sd(sp.roc.2yoy),
                           mean_sp.roc.2yoy = mean(sp.roc.2yoy),
                           
                           sd_dsr.roc.2yoy = sd(dsr.roc.2yoy),
                           mean_dsr.roc.2yoy = mean(dsr.roc.2yoy),
                           
                           sd_cred.2gdp.roc.2yoy = sd(cred.2gdp.roc.2yoy),
                           mean_cred.2gdp.roc.2yoy = mean(cred.2gdp.roc.2yoy),
                           
                           sd_sprd.bond.diff.2y = sd(sprd.bond.diff.2y),
                           mean_sprd.bond.diff.2y = mean(sprd.bond.diff.2y),
                           

                  ) %>%
                  ungroup()

write_xlsx(summary_stats, "G:/6.APM/Financial Cycle/2. Data/summary_stats.xlsx")
save(summary_stats, file = "G:/6.APM/Financial Cycle/2. Data/summary_stats.RData")