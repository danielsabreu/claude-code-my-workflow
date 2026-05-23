###############################################
# Preamble
###############################################

rm(list=ls())

setwd("G:/6.APM/Financial Cycle")

lct <- Sys.getlocale("LC_TIME"); Sys.setlocale("LC_TIME", "C")

Sys.setenv(http_proxy = "proxy.bportugal.pt:8080")
Sys.setenv(https_proxy = "proxy.bportugal.pt:8080")

iam_user <- "PTBPU313718"
iam_pass <- "4TmkhwXsGB_iam2024S2"

library(vars)
library(nowcasting)
library(dfms)
library(seasonal)
library(urca)
library(xts)
library(ecb)
library(tidyverse)
library(dplyr)
library(zoo)
library(lubridate)
library(readxl)
library(writexl)
library(ggplot2)
#devtools::install_github("expersso/BIS")
#devtools::install_github("nmecsys/nowcasting")
#remotes::install_github("https://github.com/expersso/OECD") ##  There is a bug in the version of the OECD package on CRAN
library(mFilter)
library(OECD)
library(BISdata)
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/main_with_pass.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/trend_filterHP.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/filterhp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/normalise.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/urtests.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getseas.R")

###############################################
# Variable keys
###############################################

key_sdw_q <- list("CBD2.Q..W0.67._Z._Z.A.F.A1135._X.ALL.CA._Z.LE._T.EUR", # Loans and advances - of which lending for house purchase
                  "CBD2.Q..W0.67._Z._Z.A.A.A0000._X.ALL.CA._Z.LE._T.EUR", # Total assets
                  "CBD2.Q..W0.67._Z._Z.A.F.A1100._X.ALL.CA._Z.LE._T.EUR", # Loans and advances - all exposures
                  "CBD2.Q..W2.67.S1M._Z.A.C.OR203._Z._Z._Z._Z._Z._Z.PC", # Defaulted residential mortgage loans granted to domestic households (non-SME retail) (% of total residential mortgage loans granted to domestic households)
                  "CBD2.Q..W2.67.S1M._Z.A.A.OR208._Z._Z._Z._Z._Z._Z.PC", # Average risk weight (RW) of domestic mortgage loans granted to households (non-SME retail) falling under IRB Pillar I capital requirement
                  "CBD2.Q..W2.67.S1M._Z.A.A.OR209._Z._Z._Z._Z._Z._Z.PC", # Average loss given default (LGD) of domestic mortgage loans granted to households (non-SME retail) falling under IRB Pillar I capital requirement
                  "CBD2.Q..W2.67.S1M._Z.A.A.OR210._Z._Z._Z._Z._Z._Z.PC", # Average probability of default (PD) of domestic mortgage loans granted to households (non-SME retail) falling under IRB Pillar I capital requirement
                  "CBD2.Q..W2.67.S1M._Z.A.C.OR204._Z._Z._Z._Z._Z._Z.PC", # Coverage ratio for defaulted domestic mortgage loans (non-SME retail)"
                  "CBD2.Q..W2.67.S1M._Z.A.C.OR206._Z._Z._Z._Z._Z._Z.PC", # Share of domestic mortgage loans granted to households (non-SME retail) falling under IRB capital requirement
                  
                  "BSI.Q..N.A.A30.A.1.U6.2240.Z01.E", # Debt securities of NFC
                  "BSI.Q..N.A.A30.A.1.U6.2250.Z01.E", # Debt securities of HHs
                  
                  "RESR.Q.._T.N._TR.TVLD.4D0.TB.N.IX", # Residential property prices
                  "RESV.Q.._T.N._TR.RVMB.4F0._Z._Z.PT", # Model-based valuation measures (residual - Bayesian static equation)
                  "RESV.Q.._T.N._TR.RVPI.4F0._Z._Z.RO", # Estimates of the over/undervaluation of residential property prices - House price to income ratio (deviation from its average since January 1996)
                  
                  "RPP.Q.PT.N.TD.00.4.00", # Transaction value - Index; Residential property, All dwelling types, new and existing
                  
                  "QSA.Q.N..W0.S1M.S1.N.L.LE.F4.T._Z.XDC._T.S.V.N._T",    # Loans granted to households
                  "QSA.Q.N..W0.S1M.S1._Z.B.B6G._Z._Z._Z.XDC._T.S.V.N._T", # Gross disposable income of households
                  "QSA.Q.N..W0.S1M.S1.N.L.LE.F3.T._Z.XDC._T.S.V.N._T",    # QSA debt sec issued by HHs, NSA mil. local currency
                  "QSA.Q.N..W0.S11.S1.N.L.LE.F4.T._Z.XDC._T.S.V.N._T",    # Total loans to NFCs, NSA mil. local currency
                  "QSA.Q.N..W0.S11.S1.N.L.LE.F3.T._Z.XDC._T.S.V.N._T",  # Total debt securities issued by NFCs, NSA mil. local currency
                  "QSA.Q.N..W0.S11.S1.N.L.LE.F81.T._Z.XDC._T.S.V.N._T", # Total trade credit granted to NFCs, NSA mil. local currency"
                  
                  "MNA.Q.N..W2.S1.S1.D.D1._Z._T._Z.XDC.V.N", # Compensation of employees
                  "MNA.Q.Y..W2.S1.S1.B.B1GQ._Z._Z._Z.EUR.V.N", # Gross domestic product at market prices
                  
                  "BP6.Q.N..W1.S1.S1.T.B.CA._Z._Z._Z.EUR._T._X.N", # Current account 
                  
                  "FM.Q.PT.EUR.RT.BB.PT10YT_TWEB.YLDA" # Portugal 10 Years Government Benchmark Bond - TradeWeb data - Yield, average of observations through period
                  
)


key_sdw_m <- list("ICP.M..N.041000.4.INX", # HICP - Actual rentals for housing
                  "ICP.M..Y.000000.3.INX", # HICP - Overall index
                  
                  "IRS.M..L.L40.CI.0000.EUR.N.Z", # Long-term interest rate for convergence purposes - 10 years maturity, denominated in Euro
                  
                  "MIR.M..B.A22.A.R.A.2250.EUR.O", # Bank interest rates - loans to households for house purchase (outstanding amounts). Annualised agreed rate (AAR)
                  "MIR.M..B.A2C.A.C.A.2250.EUR.N", # Bank interest rates - loans to households for house purchase APRC (new business) - euro area
                  
                  "RAI.M..LMGBLNFCH.EUR.MIR.Z", # Spreads new lending private non-financial sector
                  "RAI.M..SVLHPHH.EUR.MIR.Z", # share of variable rate loans in total loans for house purchase (new business; Euro denominated loans; floating rate or initial rate fixed for a period of up to 1 year)
                  
                  "BSI.M..N.A.A21.A.1.U2.2250.Z01.E", # Credit for consumption vis-a-vis euro area households reported by MFI excluding ESCB (stock)
                  "BSI.M..N.A.A20T.A.1.U6.2240.Z01.E", # Loans to NFCs - adjusted by securitization
                  "BSI.M..N.A.A20T.A.1.U6.2250.Z01.E", # Loans to HHs - adjusted by securitization
                  "BSI.M..N.A.A22.A.1.U2.2250.Z01.E", # Lending for house purchase vis-a-vis euro area households reported by MFI excluding ESCB (stock)
                  "BSI.M..N.A.A20.F.1.U6.2250.Z01.E", # Outstanding amounts at the end of the period (stocks), MFIs excluding ESCB reporting sector - Loans, Up to 1 year maturity
                  "BSI.M..N.A.A20.I.1.U6.2250.Z01.E", # Outstanding amounts at the end of the period (stocks), MFIs excluding ESCB reporting sector - Loans, Over 1 and up to 5 years maturity
                  "BSI.M..N.A.A20.J.1.U6.2250.Z01.E", # Outstanding amounts at the end of the period (stocks), MFIs excluding ESCB reporting sector - Loans, Over 5 years maturity
                  "BSI.M..N.A.A20.A.1.U6.2250.Z01.E", # Loans vis-a-vis domestic households reported by MFI excluding ESCB (stock)
                  
                  "MIR.M..B.A2B.A.C.A.2250.EUR.N" # Bank interest rates - loans to households for consumption APRC (new business)
)

###############################################
# Extract data
###############################################

# BIS data
bis_cred <- fetch_dataset(dest.dir = tempdir(),bis.url ="https://data.bis.org/static/bulk/", "WS_TC_csv_col.zip")
bis_vars <- c("Q:PT:N:A:M:770:A", # Portugal - Credit to Non-financial corporations from All sectors at Market value - Percentage of GDP - Adjusted for breaks
              "Q:PT:N:A:M:XDC:A", # Portugal - Credit to Non-financial corporations from All sectors at Market value - Domestic currency - Adjusted for breaks
              "Q:PT:H:A:M:770:A", # Portugal - Credit to Households and NPISHs from All sectors at Market value - Percentage of GDP - Adjusted for breaks
              "Q:PT:H:A:M:XDC:A", # Portugal - Credit to Households and NPISHs from All sectors at Market value - Domestic currency - Adjusted for breaks
              "Q:PT:C:A:M:770:A", # Portugal - Credit to Non financial sector from All sectors at Market value - Percentage of GDP - Adjusted for breaks
              "Q:PT:C:A:M:XDC:A", # Portugal - Credit to Non financial sector from All sectors at Market value - Domestic currency - Adjusted for breaks
              "Q:PT:G:A:M:770:A", # Portugal - Credit to General government from All sectors at Market value - Percentage of GDP - Adjusted for breaks
              "Q:PT:G:A:M:XDC:A", # Portugal - Credit to General government from All sectors at Market value - Domestic currency - Adjusted for breaks
              "Q:PT:P:A:M:770:A", # Portugal - Credit to Private non-financial sector from All sectors at Market value - Percentage of GDP - Adjusted for breaks
              "Q:PT:P:A:M:XDC:A") # Portugal - Credit to Private non-financial sector from All sectors at Market value - Domestic currency - Adjusted for breaks
bis_selection <- as.matrix(colnames(bis_cred)) 
bis_selection <- bis_selection[which(bis_selection=="Series"):nrow(bis_selection),]
bis_cred <- bis_cred %>% 
  filter(`Borrowers' country`=="Portugal", Series %in% bis_vars) %>%
  select(bis_selection) %>%
  pivot_longer(cols = !Series, names_to ="variable",values_to="value")  %>%
  pivot_wider(names_from = Series,values_from = "value") %>% 
  rename(obstime=variable) %>%
  mutate(obstime=as.Date(as.yearqtr(paste(substr(obstime,1,4),substr(obstime,7,8),sep="-")),frac = 1))


bis_cred2gdpgap <- fetch_dataset(dest.dir = tempdir(),bis.url ="https://data.bis.org/static/bulk/", "WS_CREDIT_GAP_csv_col.zip")
bis_vars <- c("Q:PT:P:A:A", # Credit-to-GDP ratios (actual data)
              "Q:PT:P:A:B", # Credit-to-GDP trend (HP filter) 
              "Q:PT:P:A:C") # Credit-to-GDP gaps (actual-trend)
bis_selection <- as.matrix(colnames(bis_cred2gdpgap)) 
bis_selection <- bis_selection[which(bis_selection=="Series"):nrow(bis_selection),]
bis_cred2gdpgap <- bis_cred2gdpgap %>% 
  filter(`Borrowers' country`=="Portugal", Series %in% bis_vars) %>%
  select(all_of(bis_selection)) %>%
  pivot_longer(cols = !Series, names_to ="variable",values_to="value")  %>%
  pivot_wider(names_from = Series,values_from = "value") %>%
  rename(obstime=variable) %>%
  mutate(obstime=as.Date(as.yearqtr(paste(substr(obstime,1,4),substr(obstime,7,8),sep="-")),frac = 1))


bis_dsr <- fetch_dataset(dest.dir = tempdir(),bis.url ="https://data.bis.org/static/bulk/", "WS_DSR_csv_col.zip")
bis_vars <- c("Q:PT:H", # DSR - Portugal - Households and NPISHs
              "Q:PT:N", # DSR - Portugal - Non-financial corporations
              "Q:PT:P") # DSR - Portugal - Private non-financial sector
bis_selection <- as.matrix(colnames(bis_dsr)) 
bis_selection <- bis_selection[which(bis_selection=="Series"):nrow(bis_selection),]
bis_dsr <- bis_dsr %>% 
  filter(`Borrowers' country`=="Portugal", Series %in% bis_vars) %>%
  select(all_of(bis_selection)) %>%
  pivot_longer(cols = !Series, names_to ="variable",values_to="value")  %>%
  pivot_wider(names_from = Series,values_from = "value") %>% 
  rename(obstime=variable) %>%
  mutate(obstime=as.Date(as.yearqtr(paste(substr(obstime,1,4),substr(obstime,7,8),sep="-")),frac = 1))

bis_data <- left_join(bis_cred,bis_dsr,by='obstime')
bis_data <- left_join(bis_data,bis_cred2gdpgap,by="obstime")


# OECD

# House prices indicators database
oecd_labels <- get_data_structure("OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,1.0")$CL_MEASURE_HOU
oecd_rre <- get_dataset(dataset = "OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,1.0") %>% 
            filter(FREQ == "Q", REF_AREA == "PRT", MEASURE %in% c("RHP", # Real house price indices, s.a.
                                                                  "HPI", # Nominal house price indices, s.a.
                                                                  "RPI", # Rent prices, s.a.
                                                                  "HPI_RPI", # Price to rent ratio
                                                                  "HPI_RPI_AVG", # Standardised price-rent ratio    
                                                                  "HPI_YDH", # Price to income ratio
                                                                  "HPI_YDH_AVG" # Standardised price-income ratio
            )) %>%
            select(MEASURE, ObsValue,TIME_PERIOD) %>% 
            pivot_wider(names_from = "MEASURE",
                        values_from = "ObsValue",
                        values_fill = NA) %>%
            mutate(TIME_PERIOD = as.yearqtr(TIME_PERIOD, format = "%Y-Q%q")) %>%
            mutate(TIME_PERIOD = as.Date(as.yearqtr(paste(substr(TIME_PERIOD,1,4),substr(TIME_PERIOD,7,8),sep="-")),frac = 1)) %>%
            filter(is.na(TIME_PERIOD) == FALSE) %>%
            rename(obstime=TIME_PERIOD) %>% 
            arrange(obstime) %>% 
            mutate(across(where(is.character), as.numeric))

# Key economic indicators database
oecd_labels <- get_data_structure("OECD.SDD.STES,DSD_KEI@DF_KEI,4.0")
oecd_kei <- get_dataset(dataset = "OECD.SDD.STES,DSD_KEI@DF_KEI,4.0", "PRT.Q.IRSTCI+IR3TIB+IRLT....") %>% 
            select(MEASURE, ObsValue,TIME_PERIOD) %>% 
            pivot_wider(names_from = "MEASURE",
                        values_from = "ObsValue",
                        values_fill = NA) %>%
            mutate(TIME_PERIOD = as.yearqtr(TIME_PERIOD, format = "%Y-Q%q")) %>%
            mutate(TIME_PERIOD = as.Date(as.yearqtr(paste(substr(TIME_PERIOD,1,4),substr(TIME_PERIOD,7,8),sep="-")),frac = 1)) %>%
            filter(is.na(TIME_PERIOD) == FALSE) %>%
            rename(obstime=TIME_PERIOD) %>% 
            arrange(obstime) %>% 
            mutate(across(where(is.character), as.numeric))

# include a line in the dataframe for the date "1987-09-30" (is missing from the oecd data) that equals the values of the last observation "1987-06-30".
new_row <- oecd_kei[which(oecd_kei$obstime == as.Date("1987-06-30")),]
new_row$obstime <- as.Date("1987-09-30")
oecd_kei <- rbind(oecd_kei[which(oecd_kei$obstime <= as.Date("1987-06-30")),],new_row,oecd_kei[which(oecd_kei$obstime > as.Date("1987-06-30")),])

# SDW - Quarterly data

sdw_get_data_q <- lapply(key_sdw_q,get_data_with_password,iam_user=iam_user,iam_pass=iam_pass)
names(sdw_get_data_q) <- key_sdw_q
sdw_get_data_q <- Map(cbind,sdw_get_data_q,var_name=names(sdw_get_data_q))

sdw_q <- bind_rows(sdw_get_data_q) %>%
  filter(ref_area %in% c("PT")) %>%       
  select(obstime,obsvalue,var_name) %>%
  pivot_wider(names_from = "var_name",
              values_from = "obsvalue",
              values_fill = NA) %>%
  mutate(obstime=as.Date(as.yearqtr(paste(substr(obstime,1,4),substr(obstime,7,8),sep="-")),frac = 1))

# SDW - Monthly data

sdw_get_data_m <- lapply(key_sdw_m,get_data_with_password,iam_user=iam_user,iam_pass=iam_pass)
names(sdw_get_data_m) <- key_sdw_m
sdw_get_data_m <- Map(cbind,sdw_get_data_m,var_name=names(sdw_get_data_m))

sdw_m <- bind_rows(sdw_get_data_m) %>%
  filter(ref_area %in% c("PT")) %>%
  select(obstime,obsvalue,var_name) %>%
  pivot_wider(names_from = "var_name",
              values_from = "obsvalue",
              values_fill = NA) %>%
  mutate(obstime=as.Date(paste(substr(obstime,1,4),substr(obstime,6,8),"01",sep="-"),format = "%Y-%m-%d"))

sdw_m <- sdw_m %>%
  mutate(obstime = ceiling_date(obstime,"month") %m-% days(1))
  sdw_m[,c(3:ncol(sdw_m))] <- lapply(sdw_m[,c(3:ncol(sdw_m))],as.numeric)
  sdw_m <- sdw_m %>% # Compute avg interest rate in the last 3 months
  mutate(MIR.M..B.A2B.A.C.A.2250.EUR.N = (MIR.M..B.A2B.A.C.A.2250.EUR.N+lag(MIR.M..B.A2B.A.C.A.2250.EUR.N,1)+lag(MIR.M..B.A2B.A.C.A.2250.EUR.N,2))/3,
         MIR.M..B.A22.A.R.A.2250.EUR.O = (MIR.M..B.A22.A.R.A.2250.EUR.O+lag(MIR.M..B.A22.A.R.A.2250.EUR.O,1)+lag(MIR.M..B.A22.A.R.A.2250.EUR.O,2))/3
  )

    
# shadow rates
shadow_rates <- read_excel("2. Data/shadow_rates.xlsx",sheet = "final series")  


# CCyB task force DSR
SRIs_20180530_including_readme <- read_excel("G:\\6.APM\\Financial Cycle\\2. Data\\SRIs_20180530_including_readme.xlsx", sheet = "Data")

dsr_tf_level <- SRIs_20180530_including_readme %>% 
  select(.,country,obstime,DSR) %>% 
  pivot_wider(names_from = country, values_from = DSR) %>% 
  select(obstime,PT) %>% 
  rename(dsr.tf = PT) %>% 
  mutate(dsr.tf.roc.1q = dsr.tf/lag(dsr.tf)-1) %>% 
  left_join(.,bis_dsr,by="obstime") %>%
  mutate(dsr.new = `Q:PT:P`)

# Compute "new" dsr indicator dsr_t1 = dsr_t0*(1+r_t1) -> dsr_to = dsr_t1 / (1+r_t1) -> r_t1 = dsr_t1/dsr_t0 - 1
for(i in nrow(dsr_tf_level):1) {
  
  if(is.na(dsr_tf_level[i,"dsr.new"])==TRUE & is.na(dsr_tf_level[i+1,"dsr.tf.roc.1q"])==FALSE) {
    
    dsr_tf_level[i,"dsr.new"] = dsr_tf_level[i+1,"dsr.new"] / (1+dsr_tf_level[i+1,"dsr.tf.roc.1q"])
    
  } 
}

# Join data
bis_oecd_data <- left_join(bis_data,oecd_rre, by="obstime")
bis_oecd_data <- left_join(bis_oecd_data,oecd_kei, by="obstime")
sdw_q_join <- left_join(bis_oecd_data,sdw_q,by="obstime")
sdw_q_join <- left_join(sdw_q_join,sdw_m,by="obstime")
sdw_q_join <- left_join(sdw_q_join,shadow_rates,by="obstime")
sdw_q_join <- left_join(sdw_q_join,dsr_tf_level[,c("obstime","dsr.new")],by="obstime")

bis_oecd_data[,c(2:ncol(bis_oecd_data))] <- lapply(bis_oecd_data[,c(2:ncol(bis_oecd_data))],as.numeric)
sdw_q_join[,c(2:ncol(sdw_q_join))] <- lapply(sdw_q_join[,c(2:ncol(sdw_q_join))],as.numeric)

# Export data
save(sdw_q_join, file = "2. Data/sdw_q_join.RData")
write_xlsx(sdw_q_join,"2. Data/sdw_q_join.xlsx")