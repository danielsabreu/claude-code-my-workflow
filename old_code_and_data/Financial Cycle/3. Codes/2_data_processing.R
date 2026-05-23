###############################################
# Preamble
###############################################

rm(list=ls())

setwd("G:/6.APM/Financial Cycle")

lct <- Sys.getlocale("LC_TIME"); Sys.setlocale("LC_TIME", "C")

library(vars)
library(nowcasting)
library(dfms)
library(seasonal)
library(urca)
library(xts)
library(ecb)
library(tidyverse)
library(zoo)
library(readxl)
library(writexl)
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
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getfilter.R")

###############################################
# Computation of indicators - Longer TSs
###############################################

load("G:/6.APM/Financial Cycle/2. Data/sdw_q_join.RData")

# Include share prices from excel file SOURCE OF SHARES PRICES IS OECD!
sp <- read_xlsx("G:/6.APM/Financial Cycle/3. Codes/presentation/the_data_dec2023_obstime_BIS_credit.xlsx")
sp <- sp[,c("obstime","SHPRICE","bond spread","spread_nfc","spread_hh_h","spread_hh_c","VOL_PSI20")] %>% 
      mutate(obstime = as.Date(paste(substr(obstime,1,4),substr(obstime,6,7),"01",sep="-"),format = "%Y-%m-%d")) %>%
      mutate(obstime = ceiling_date(obstime,"month") %m-% days(1))
sdw_q_join <- left_join(sdw_q_join,sp,by="obstime")

# Renaming
sdw_q_join <- sdw_q_join %>%
                 rename(cred.nfc.2gdp = `Q:PT:N:A:M:770:A`,  # Portugal - Credit to Non-financial corporations from All sectors at Market value - Percentage of GDP - Adjusted for breaks
                        cred.nfc = `Q:PT:N:A:M:XDC:A`,       # Portugal - Credit to Non-financial corporations from All sectors at Market value - Domestic currency - Adjusted for breaks
                        cred.hh.2gdp = `Q:PT:H:A:M:770:A`,   # Portugal - Credit to Households and NPISHs from All sectors at Market value - Percentage of GDP - Adjusted for breaks
                        cred.hh = `Q:PT:H:A:M:XDC:A`,        # Portugal - Credit to Households and NPISHs from All sectors at Market value - Domestic currency - Adjusted for breaks
                        cred.nfs.2gdp = `Q:PT:C:A:M:770:A`,  # Portugal - Credit to Non financial sector from All sectors at Market value - Percentage of GDP - Adjusted for breaks
                        cred.nfs = `Q:PT:C:A:M:XDC:A`,       # Portugal - Credit to Non financial sector from All sectors at Market value - Domestic currency - Adjusted for breaks
                        cred.gov.2gdp = `Q:PT:G:A:M:770:A`,  # Portugal - Credit to General government from All sectors at Market value - Percentage of GDP - Adjusted for breaks
                        cred.gov = `Q:PT:G:A:M:XDC:A`,       # Portugal - Credit to General government from All sectors at Market value - Domestic currency - Adjusted for breaks
                        cred.pnfs.2gdp = `Q:PT:P:A:M:770:A`, # Portugal - Credit to Private non-financial sector from All sectors at Market value - Percentage of GDP - Adjusted for breaks
                        cred.pnfs = `Q:PT:P:A:M:XDC:A`,      # Portugal - Credit to Private non-financial sector from All sectors at Market value - Domestic currency - Adjusted for breaks
                        cred.tot.2gdp = `Q:PT:P:A:A`,        # Credit-to-GDP ratios (actual data)
                        cred.tot.trend = `Q:PT:P:A:B`,       # Credit-to-GDP trend (HP filter) 
                        cred.tot.gap = `Q:PT:P:A:C`,         # Credit-to-GDP gaps (actual-trend)
                        dsr.hh = `Q:PT:H`,                   # DSR - Portugal - Households and NPISHs
                        dsr.nfc = `Q:PT:N`,                  # DSR - Portugal - Non-financial corporations
                        dsr.pnfs = `Q:PT:P`,                 # DSR - Portugal - Private non-financial sector
                        #cpi = `M:PT:628`,                   # Index, 2010 = 100
                        #cpi.yoy = `M:PT:771`,               # Year-on-year changes, in per cent
                        rhp.2rent = `HPI_RPI`,               # Price to rent ratio
                        rhp.2inc = `HPI_YDH`,                # Price to income
                        nhp = `HPI`,                         # Nominal house prices
                        rhp = `RHP`,                         # Real house prices
                        sp = `SHPRICE`,                        # Share prices
                        sprd.bond = `bond spread`,           # Spread between 10y PT gov and 10y DE bonds  
                        sprd.hh = spread_hh_h,               # Interest rate spread - loans for house purchase
                        sprd.c = spread_hh_c,                # Interest rate spread - loans for consumption
                        sprd.nfc = spread_nfc,               # Interest rate spread - loans to NFCs
                        sp.vol = VOL_PSI20,                  # PSI20 volatility - mean of standard deviation of intra-quarter observations
                        ir.lt = IRLT,                        # long-run interest rate - yields gov bonds 10y
                        ir.st = IR3TIB,                      # short-run interest rate - yields gov bonds 3m
                        ir.ib = IRSTCI,                      # immediate interest rate - interbank rates
                        ir.sr = `shadow rate`                # shadow rate
                        ) %>% 
                     mutate(inc = rhp/rhp.2inc,               # Households disposable income per capita
                           cred.hh.2inc = cred.hh/(nhp/rhp.2inc), # Household Debt to income)
                        )

# compute relevant indicators
df_ind <- sdw_q_join %>%
          mutate(cred.pnfs.2yoy = cred.pnfs/lag(cred.pnfs,8)-1,
                 cred.gov.2yoy = cred.gov/lag(cred.gov,8)-1,
                 cred.nfc.2yoy = cred.nfc/lag(cred.nfc,8)-1,
                 cred.hh.2yoy = cred.hh/lag(cred.hh,8)-1,
                 rhp.2yoy = rhp/lag(rhp,8)-1,
                 rhp.2inc.2yoy = rhp.2inc/lag(rhp.2inc,8)-1,
                 sp.2yoy = sp/lag(sp,8)-1,
                 cred.hh.2inc.2yoy  = cred.hh.2inc/lag(cred.hh.2inc,8)-1,
                 dsr.pnfs.2yoy = dsr.pnfs/lag(dsr.pnfs,8)-1,
                 dsr.new.2yoy = dsr.new/lag(dsr.new,8)-1,
                 cred.tot.2gdp.2yoy = cred.tot.2gdp/lag(cred.tot.2gdp,8)-1,
                 rhp.2rent.2yoy = rhp.2rent/lag(rhp.2rent,8)-1,
                 ir.st.2yoy = ir.st/lag(ir.st,8)-1,
                 ir.lt.2yoy = ir.lt/lag(ir.lt,8)-1,
                 ir.ib.2yoy = ir.ib/lag(ir.ib,8)-1,
                 ir.sr.2yoy = ir.sr/lag(ir.sr,8)-1,
                 sprd.bond.2yoy = sprd.bond/lag(sprd.bond,8)-1,
                 sprd.nfc.2yoy = sprd.nfc/lag(sprd.nfc,8)-1,
                 sprd.hh.2yoy = sprd.hh/lag(sprd.hh,8)-1,
                 sprd.c.2yoy = sprd.c/lag(sprd.c,8)-1,
                 
                 cred.pnfs.yoy = cred.pnfs/lag(cred.pnfs,4)-1,
                 cred.nfc.yoy = cred.nfc/lag(cred.nfc,4)-1,
                 cred.hh.yoy = cred.hh/lag(cred.hh,4)-1,
                 rhp.yoy = rhp/lag(rhp,4)-1,
                 sp.yoy = sp/lag(sp,4)-1,
                 dsr.pnfs.yoy = dsr.pnfs/lag(dsr.pnfs,4)-1,
                 cred.tot.2gdp.yoy = cred.tot.2gdp/lag(cred.tot.2gdp,4)-1,
                 rhp.2rent.yoy = rhp.2rent/lag(rhp.2rent,4)-1,
                 ir.st.yoy = ir.st/lag(ir.st,4)-1,
                 ir.lt.yoy = ir.lt/lag(ir.lt,4)-1,
                 ir.ib.yoy = ir.ib/lag(ir.ib,4)-1,
                 ir.sr.yoy = ir.sr/lag(ir.sr,4)-1,
                 sprd.bond.yoy = sprd.bond/lag(sprd.bond,4)-1,
                 sprd.nfc.yoy = sprd.nfc/lag(sprd.nfc,4)-1,
                 sprd.hh.yoy = sprd.hh/lag(sprd.hh,4)-1,
                 sprd.c.yoy = sprd.c/lag(sprd.c,4)-1,
                 
                 rhp.qoq = rhp/lag(rhp,1)-1,
                 cred.pnfs.qoq = cred.pnfs/lag(cred.pnfs,1)-1,
                 cred.nfc.qoq = cred.nfc/lag(cred.nfc,1)-1,
                 cred.hh.qoq = cred.hh/lag(cred.hh,1)-1,
                 rhp.qoq = rhp/lag(rhp,1)-1,
                 sp.qoq = sp/lag(sp,1)-1,
                 dsr.pnfs.qoq = dsr.pnfs/lag(dsr.pnfs,1)-1,
                 cred.tot.2gdp.qoq = cred.tot.2gdp/lag(cred.tot.2gdp,1)-1,
                 rhp.2rent.qoq = rhp.2rent/lag(rhp.2rent,1)-1) %>%
          select(obstime,cred.gov.2yoy,cred.nfc.2yoy,cred.hh.2yoy,rhp.2yoy,rhp.2inc.2yoy,sp.2yoy,cred.hh.2inc.2yoy,dsr.pnfs.2yoy,dsr.new.2yoy,cred.tot.2gdp.2yoy,ir.st.2yoy,ir.lt.2yoy,ir.ib.2yoy,ir.sr.2yoy,sprd.bond.2yoy,sprd.nfc.2yoy,sprd.hh.2yoy,sprd.c.2yoy,sprd.nfc,sprd.hh,sprd.c,sprd.bond,sp.vol,ir.lt,ir.st,ir.ib,ir.sr)

###############################################
# data processing - 2yoy
###############################################

df_ind <- df_ind[df_ind$obstime<="2023-03-31",] 

# seas adj
df_seas <- getseas(df_ind,trans=F)

plot(df_ind$cred.nfc.2yoy,type="l")
lines(df_ind$cred.nfc.2yoy,type="l",col="red")

# ur test
urtests(as.matrix(df_seas[,2:ncol(df_seas)]))

# applying CF filter
pl_cf <- 6
pu_cf <- 16

df_cf_cycle <- getfilter(df_seas,filter="CF",drift=FALSE,pl=pl_cf,pu=pu_cf)$cycle # avg narrow cycle from schuler, hiebert and peltonen (min = 5 years and max = 40 years -> pl=20,pu=160). Business cycle frequency: 1.5-8 years (pl = 1.5*4; pu = 8*4)
df_cf_trend <- getfilter(df_seas,filter="CF",drift=FALSE,pl=pl_cf,pu=pu_cf)$trend

# applying Butterworth filter (2-step computation of the cyclical component in order to remove both high and low frequencies)
bw_freq <- 12 # interpretation: the CYCLE obtained by applying the filter is cleansed from cycles associated with frequencies ABOVE 12 years. 
bw_nfix <- 2

# add a new observation (t+1) which is equal to last observation -> needed because BW filter (for some reason) forces the cyclical component of the last observation to be zero.
obstime <-  as.Date(df_seas[nrow(df_seas),1]) %m+% months(3)
df_seas[,1] <- as.Date(df_seas[,1]) 
df_seas_bw <- rbind(df_seas,cbind(obstime,df_seas[nrow(df_seas),2:ncol(df_seas)]))

df_bw_cycle <- getfilter(df_seas_bw,filter="BW",freq=bw_freq,nfix = bw_nfix,drift=FALSE)$cycle
df_bw_cycle <- getfilter(df_bw_cycle,filter="BW",freq=bw_freq/2,nfix = bw_nfix+2,drift=FALSE)$trend # we consider freq = 8 so that the TREND obtained by applying the filter is cleansed from cycles associated with frequencies BELOW 8 years! 
df_bw_trend <- getfilter(df_seas_bw,filter="BW",freq=bw_freq,nfix = bw_nfix,drift=FALSE)$trend # This is the way to get the trend. Computing the dif between the time series and the cycle (after the 2-step procedure) IMPLIES THAT WE ARE NOT EXCLUDING THE HIGH-FREQUENCY MOVEMENTS!
df_test <- na.omit(df_seas$cred.hh.yoy)-na.omit(df_bw_cycle$cred.hh.yoy)

df_bw_cycle <- df_bw_cycle[-nrow(df_bw_cycle),]
df_bw_trend <- df_bw_trend[-nrow(df_bw_trend),]


# Combine indicators filtered (BW) indicators and non filtered indicators (interest rates)

df_combined <- df_bw_cycle %>% 
               select(obstime,cred.gov.2yoy,cred.nfc.2yoy,cred.hh.2yoy,rhp.2yoy,rhp.2inc.2yoy,sp.2yoy,cred.hh.2inc.2yoy,dsr.pnfs.2yoy,dsr.new.2yoy,cred.tot.2gdp.2yoy,ir.st.2yoy,ir.lt.2yoy,ir.ib.2yoy,ir.sr.2yoy,sprd.bond.2yoy,sprd.nfc.2yoy,sprd.hh.2yoy,sprd.c.2yoy) %>% 
               merge(.,df_seas[,c("obstime","sprd.nfc","sprd.hh","sprd.c","sprd.bond","sp.vol","ir.lt","ir.st","ir.ib","ir.sr")], by = "obstime")

# normalise data
#df_combined <- df_seas
df <- cbind(df_combined[,1],normalise(df_combined[,2:ncol(df_combined)]))
df[,1] <- as.Date(df[,1])
names(df)[1] <- "obstime"


###############################################
# Generate files
###############################################

# Add the market indicators (sprd.nfc, sprd.hh, sprd.c, sprd.bond and sp.vol) to the data

# df_mkt_ind <- sdw_q_join[,c("obstime","sprd.nfc","sprd.hh","sprd.c","sprd.bond","sp.vol")]
# df <- merge(df,df_mkt_ind,by="obstime",all.x=TRUE)

save(df, file = "2. Data/df.RData")
write_xlsx(df,"2. Data/df.xlsx")


###############################################
# data processing - yoy
###############################################

# compute relevant indicators
df_ind <- sdw_q_join %>%
  mutate(cred.pnfs.2yoy = cred.pnfs/lag(cred.pnfs,8)-1,
         cred.gov.2yoy = cred.gov/lag(cred.gov,8)-1,
         cred.nfc.2yoy = cred.nfc/lag(cred.nfc,8)-1,
         cred.hh.2yoy = cred.hh/lag(cred.hh,8)-1,
         rhp.2yoy = rhp/lag(rhp,8)-1,
         rhp.2inc.2yoy = rhp.2inc/lag(rhp.2inc,8)-1,
         sp.2yoy = sp/lag(sp,8)-1,
         cred.hh.2inc.2yoy  = cred.hh.2inc/lag(cred.hh.2inc,8)-1,
         dsr.pnfs.2yoy = dsr.pnfs/lag(dsr.pnfs,8)-1,
         dsr.new.2yoy = dsr.new/lag(dsr.new,8)-1,
         cred.tot.2gdp.2yoy = cred.tot.2gdp/lag(cred.tot.2gdp,8)-1,
         rhp.2rent.2yoy = rhp.2rent/lag(rhp.2rent,8)-1,
         ir.st.2yoy = ir.st/lag(ir.st,8)-1,
         ir.lt.2yoy = ir.lt/lag(ir.lt,8)-1,
         ir.ib.2yoy = ir.ib/lag(ir.ib,8)-1,
         ir.sr.2yoy = ir.sr/lag(ir.sr,8)-1,
         sprd.bond.2yoy = sprd.bond/lag(sprd.bond,8)-1,
         sprd.nfc.2yoy = sprd.nfc/lag(sprd.nfc,8)-1,
         sprd.hh.2yoy = sprd.hh/lag(sprd.hh,8)-1,
         sprd.c.2yoy = sprd.c/lag(sprd.c,8)-1,
         
         cred.pnfs.yoy = cred.pnfs/lag(cred.pnfs,4)-1,
         cred.gov.yoy = cred.gov/lag(cred.gov,4)-1,
         cred.nfc.yoy = cred.nfc/lag(cred.nfc,4)-1,
         cred.hh.yoy = cred.hh/lag(cred.hh,4)-1,
         rhp.yoy = rhp/lag(rhp,4)-1,
         rhp.2inc.yoy = rhp.2inc/lag(rhp.2inc,4)-1,
         sp.yoy = sp/lag(sp,4)-1,
         cred.hh.2inc.yoy  = cred.hh.2inc/lag(cred.hh.2inc,4)-1,
         dsr.pnfs.yoy = dsr.pnfs/lag(dsr.pnfs,4)-1,
         dsr.new.yoy = dsr.new/lag(dsr.new,4)-1,
         cred.tot.2gdp.yoy = cred.tot.2gdp/lag(cred.tot.2gdp,4)-1,
         rhp.2rent.yoy = rhp.2rent/lag(rhp.2rent,4)-1,
         ir.st.yoy = ir.st/lag(ir.st,4)-1,
         ir.lt.yoy = ir.lt/lag(ir.lt,4)-1,
         ir.ib.yoy = ir.ib/lag(ir.ib,4)-1,
         ir.sr.yoy = ir.sr/lag(ir.sr,4)-1,
         sprd.bond.yoy = sprd.bond/lag(sprd.bond,4)-1,
         sprd.nfc.yoy = sprd.nfc/lag(sprd.nfc,4)-1,
         sprd.hh.yoy = sprd.hh/lag(sprd.hh,4)-1,
         sprd.c.yoy = sprd.c/lag(sprd.c,4)-1,
         
         rhp.qoq = rhp/lag(rhp,1)-1,
         cred.pnfs.qoq = cred.pnfs/lag(cred.pnfs,1)-1,
         cred.nfc.qoq = cred.nfc/lag(cred.nfc,1)-1,
         cred.hh.qoq = cred.hh/lag(cred.hh,1)-1,
         rhp.qoq = rhp/lag(rhp,1)-1,
         sp.qoq = sp/lag(sp,1)-1,
         dsr.pnfs.qoq = dsr.pnfs/lag(dsr.pnfs,1)-1,
         cred.tot.2gdp.qoq = cred.tot.2gdp/lag(cred.tot.2gdp,1)-1,
         rhp.2rent.qoq = rhp.2rent/lag(rhp.2rent,1)-1) %>%
  select(obstime,cred.gov.yoy,cred.nfc.yoy,cred.hh.yoy,rhp.yoy,rhp.2inc.yoy,sp.yoy,cred.hh.2inc.yoy,dsr.pnfs.yoy,dsr.new.yoy,cred.tot.2gdp.yoy,ir.st.yoy,ir.lt.yoy,ir.ib.yoy,ir.sr.yoy,sprd.bond.yoy,sprd.nfc.yoy,sprd.hh.yoy,sprd.c.yoy,sprd.nfc,sprd.hh,sprd.c,sprd.bond,sp.vol,ir.lt,ir.st,ir.ib,ir.sr)


df_ind <- df_ind[df_ind$obstime<="2023-03-31",] 

# seas adj
df_seas <- getseas(df_ind,trans=F)

plot(df_ind$cred.nfc.yoy,type="l")
lines(df_ind$cred.nfc.yoy,type="l",col="red")

# ur test
urtests(as.matrix(df_seas[,2:ncol(df_seas)]))

# applying CF filter
pl_cf <- 6
pu_cf <- 16

df_cf_cycle <- getfilter(df_seas,filter="CF",drift=FALSE,pl=pl_cf,pu=pu_cf)$cycle # avg narrow cycle from schuler, hiebert and peltonen (min = 5 years and max = 40 years -> pl=20,pu=160). Business cycle frequency: 1.5-8 years (pl = 1.5*4; pu = 8*4)
df_cf_trend <- getfilter(df_seas,filter="CF",drift=FALSE,pl=pl_cf,pu=pu_cf)$trend

# applying Butterworth filter (2-step computation of the cyclical component in order to remove both high and low frequencies)
bw_freq <- 12 # interpretation: the CYCLE obtained by applying the filter is cleansed from cycles associated with frequencies ABOVE 12 years. 
bw_nfix <- 2

# add a new observation (t+1) which is equal to last observation -> needed because BW filter (for some reason) forces the cyclical component of the last observation to be zero.
obstime <-  as.Date(df_seas[nrow(df_seas),1]) %m+% months(3)
df_seas[,1] <- as.Date(df_seas[,1]) 
df_seas_bw <- rbind(df_seas,cbind(obstime,df_seas[nrow(df_seas),2:ncol(df_seas)]))

df_bw_cycle <- getfilter(df_seas_bw,filter="BW",freq=bw_freq,nfix = bw_nfix,drift=FALSE)$cycle
df_bw_cycle <- getfilter(df_bw_cycle,filter="BW",freq=bw_freq/2,nfix = bw_nfix+2,drift=FALSE)$trend # we consider freq = 8 so that the TREND obtained by applying the filter is cleansed from cycles associated with frequencies BELOW 8 years! 
df_bw_trend <- getfilter(df_seas_bw,filter="BW",freq=bw_freq,nfix = bw_nfix,drift=FALSE)$trend # This is the way to get the trend. Computing the dif between the time series and the cycle (after the 2-step procedure) IMPLIES THAT WE ARE NOT EXCLUDING THE HIGH-FREQUENCY MOVEMENTS!

df_bw_cycle <- df_bw_cycle[-nrow(df_bw_cycle),]
df_bw_trend <- df_bw_trend[-nrow(df_bw_trend),]


# Combine indicators filtered (BW) indicators and non filtered indicators (interest rates)

df_combined <- df_bw_cycle %>% 
  select(obstime,cred.gov.yoy,cred.nfc.yoy,cred.hh.yoy,rhp.yoy,rhp.2inc.yoy,sp.yoy,cred.hh.2inc.yoy,dsr.pnfs.yoy,dsr.new.yoy,cred.tot.2gdp.yoy,ir.st.yoy,ir.lt.yoy,ir.ib.yoy,ir.sr.yoy,sprd.bond.yoy,sprd.nfc.yoy,sprd.hh.yoy,sprd.c.yoy) %>% 
  merge(.,df_seas[,c("obstime","sprd.nfc","sprd.hh","sprd.c","sprd.bond","sp.vol","ir.lt","ir.st","ir.ib","ir.sr")], by = "obstime")

# normalise data
df <- cbind(df_combined[,1],normalise(df_combined[,2:ncol(df_combined)]))
df[,1] <- as.Date(df[,1])
names(df)[1] <- "obstime"


###############################################
# Generate files
###############################################
save(df, file = "2. Data/df_yoy.RData")


###############################################
# Graphs
###############################################

pat <- ".2yoy"
plot.ts(na.omit(df[,grepl(pat,names(df),fixed=TRUE)]))

# spectral analysis to illustrate the effects of filtering
var <- "cred.hh.2yoy"

plot(na.omit(df_seas[,var]),type="l")
spec <- spec.pgram(na.omit(df_seas[,var]),log="yes",detrend=FALSE,demean = TRUE)$spec
freq <- spec.pgram(na.omit(df_seas[,var]),log="yes",detrend=FALSE,demean = TRUE,plot=FALSE)$freq

df_spec <- getfilter(df_seas_bw,filter="BW",freq=bw_freq,nfix = bw_nfix,drift=FALSE)$cycle
spec_1 <- spec.pgram(na.omit(df_spec[,var]),log="yes",detrend=FALSE,demean = TRUE)$spec

df_spec_2 <- getfilter(df_spec,filter="BW",freq=bw_freq/2,nfix = bw_nfix+2,drift=FALSE)$trend
spec_2 <- spec.pgram(na.omit(df_spec_2[,var]),log="yes",detrend=FALSE,demean = TRUE)$spec

plot(log(spec)~freq,type="l")
abline(v=1/12, col="blue")
lines(log(spec_1)~freq,type="l",col="red")
abline(v=1/6, col="blue")
lines(log(spec_2)~freq,type="l",col="green")

plot(na.omit(df_seas[,var]),type="l")
lines(na.omit(df_spec_2[,var]),type="l",col="red")

# Transformed variables
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy") # ,"sp.2yoy"
g1 <- df_seas[,c("obstime",selection)] %>%
  na.omit() %>% 
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g1

selection <- c("ir.lt","ir.st","ir.ib","ir.sr")
g2 <- df_seas[,c("obstime",selection)] %>%
  na.omit() %>% 
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g2

# selection <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy") #,"sp.yoy"
# g2 <- df_seas[,c("obstime",selection)] %>% 
#   na.omit() %>% 
#   pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
#   ggplot(., aes(x = obstime, y = value, color = variable)) +
#   geom_line() +
#   theme_classic() +
#   theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
# g2
# 
# selection <- c("cred.nfc.qoq","cred.hh.qoq","rhp.qoq") #,"sp.qoq"
# g3 <- df_seas[,c("obstime",selection)] %>%
#   na.omit() %>% 
#   pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
#   ggplot(., aes(x = obstime, y = value, color = variable)) +
#   geom_line() +
#   theme_classic() +
#   theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
# g3

# Filtered variables

  #BW
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy") # ,"sp.2yoy"
g4 <- df_bw_cycle[,c("obstime",selection)] %>%
  na.omit() %>% 
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g4

# selection <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy") # ,"sp.yoy" 
# g5 <- df_bw_cycle[,c("obstime",selection)] %>%
#   na.omit() %>% 
#   pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
#   ggplot(., aes(x = obstime, y = value, color = variable)) +
#   geom_line() +
#   theme_classic() +
#   theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
# g5
# 
# selection <- c("cred.nfc.qoq","cred.hh.qoq","rhp.qoq") #,"sp.qoq" 
# g6 <- df_bw_cycle[,c("obstime",selection)] %>%
#   na.omit() %>% 
#   pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
#   ggplot(., aes(x = obstime, y = value, color = variable)) +
#   geom_line() +
#   theme_classic() +
#   theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
# g6

  #CF
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy") # ,"sp.2yoy"
g5 <- df_cf_cycle[,c("obstime",selection)] %>%
  na.omit() %>% 
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g5

# selection <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy") # ,"sp.yoy" 
# g6 <- df_cf_cycle[,c("obstime",selection)] %>%
#   na.omit() %>% 
#   pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
#   ggplot(., aes(x = obstime, y = value, color = variable)) +
#   geom_line() +
#   theme_classic() +
#   theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
# g6
# 
# selection <- c("cred.nfc.qoq","cred.hh.qoq","rhp.qoq") #,"sp.qoq" 
# g7 <- df_cf_cycle[,c("obstime",selection)] %>%
#   na.omit() %>% 
#   pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
#   ggplot(., aes(x = obstime, y = value, color = variable)) +
#   geom_line() +
#   theme_classic() +
#   theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
# g7

# Interest rates
sdw_q_join$ir.wx <- sdw_q_join$ir.sr
sdw_q_join[sdw_q_join$obstime<="2004-06-30","ir.wx"] <- NA
selection <- c("ir.wx","ir.ib","ir.st") 
g8 <- sdw_q_join[,c("obstime", selection)] %>%
  filter(!is.na(ir.st)) %>%  # Filter out rows where dsr.new is NA
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank())
print(g8)
write_xlsx(g8, "g8.xlsx")

# DSTIs
selection <- c("dsr.new","dsr.pnfs")
g9 <- sdw_q_join[,c("obstime", selection)] %>%
  filter(!is.na(dsr.new)) %>%  # Filter out rows where dsr.new is NA
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank())
print(g9)
write_xlsx(g9, "g9.xlsx")
# Transformed variables vs Trend 
  # hh credit
plot(na.omit(df_seas$cred.hh.2yoy),type="l")
lines(na.omit(df_bw_trend$cred.hh.2yoy),type="l",col="blue")
lines(na.omit(df_cf_trend$cred.hh.2yoy),type="l",col="red")

# plot(na.omit(df_seas$cred.hh.yoy),type="l")
# lines(na.omit(df_bw_trend$cred.hh.yoy),type="l",col="blue")
# lines(na.omit(df_cf_trend$cred.hh.yoy),type="l",col="red")
# lines(na.omit(df_test),type="l",col="green")
# plot(na.omit(df_bw_cycle$rhp.yoy),type="l")

# plot(na.omit(df_seas$cred.hh.qoq),type="l")
# lines(na.omit(df_bw_trend$cred.hh.qoq),type="l",col="blue")
# lines(na.omit(df_cf_trend$cred.hh.qoq),type="l",col="red")

  # house prices
plot(na.omit(df_seas$rhp.2yoy),type="l")
lines(na.omit(df_bw_trend$rhp.2yoy),type="l",col="blue")
lines(na.omit(df_cf_trend$rhp.2yoy),type="l",col="red")

# plot(na.omit(df_seas$rhp.yoy),type="l")
# lines(na.omit(df_bw_trend$rhp.yoy),type="l",col="blue")
# lines(na.omit(df_cf_trend$rhp.yoy),type="l",col="red")
# 
# plot(na.omit(df_seas$rhp.qoq),type="l")
# lines(na.omit(df_bw_trend$rhp.qoq),type="l",col="blue")
# lines(na.omit(df_cf_trend$rhp.qoq),type="l",col="red")

#   # house prices to income
# plot(na.omit(df_seas$rhp.2rent.2yoy),type="l")
# lines(na.omit(df_bw_trend$rhp.2rent.2yoy),type="l",col="blue")
# lines(na.omit(df_cf_trend$rhp.2rent.2yoy),type="l",col="red")
# 
# plot(na.omit(df_seas$rhp.2rent.yoy),type="l")
# lines(na.omit(df_bw_trend$rhp.2rent.yoy),type="l",col="blue")
# lines(na.omit(df_cf_trend$rhp.2rent.yoy),type="l",col="red")
# 
# plot(na.omit(df_seas$rhp.2rent.qoq),type="l")
# lines(na.omit(df_bw_trend$rhp.2rent.qoq),type="l",col="blue")
# lines(na.omit(df_cf_trend$rhp.2rent.qoq),type="l",col="red")

 # credit to gdp
plot(na.omit(df_seas$cred.tot.2gdp.2yoy),type="l")
lines(na.omit(df_bw_trend$cred.tot.2gdp.2yoy),type="l",col="blue")
lines(na.omit(df_cf_trend$cred.tot.2gdp.2yoy),type="l",col="red")

# plot(na.omit(df_seas$cred.tot.2gdp.yoy),type="l")
# lines(na.omit(df_bw_trend$cred.tot.2gdp.yoy),type="l",col="blue")
# lines(na.omit(df_cf_trend$cred.tot.2gdp.yoy),type="l",col="red")
# 
# plot(na.omit(df_seas$cred.tot.2gdp.qoq),type="l")
# lines(na.omit(df_bw_trend$cred.tot.2gdp.qoq),type="l",col="blue")
# lines(na.omit(df_cf_trend$cred.tot.2gdp.qoq),type="l",col="red")