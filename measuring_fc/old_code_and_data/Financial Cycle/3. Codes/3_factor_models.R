###############################################
# Preamble
###############################################

rm(list=ls())

setwd("G:/6.APM/Financial Cycle")

library(ggthemes)
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
library(mFilter)
library(OECD)
library(BISdata)
library(PANICr)
library(strucchange)
library(reshape2)
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/main_with_pass.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/trend_filterHP.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/filterhp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/normalise.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/urtests.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getseas.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/ICr_c.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/boundaryFstats.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/dfm_str_break.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/test_str_brk.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/factor_est_cp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/create_grid.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/dfm_conf_int.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/avar.R")

load("G:/6.APM/Financial Cycle/2. Data/df.RData")

###############################################
# Indicator with different transformations
###############################################

pat <- ".2yoy"
plot.ts(na.omit(df[,grepl(pat,names(df),fixed=TRUE)]))
df_2yoy <- df[,grepl(pat,names(df),fixed=TRUE)]
df_2yoy <- cbind(df[,1],df_2yoy)
colnames(df_2yoy)[1] <- "obstime"
df_2yoy <- na.omit(df_2yoy)
dfm_2yoy <- DFM(df_2yoy[2:ncol(df_2yoy)], r = 1, p = 1) 
df_2yoy <- cbind(df_2yoy,dfm_2yoy$F_pca)
colnames(df_2yoy)[ncol(df_2yoy)] <- "factor.2yoy"
plot(dfm_2yoy)

###############################################
# Number of factors
###############################################

# Number of autoregressive terms
VARselect(df_2yoy[,2:ncol(df_2yoy)])

# Number of factors
# Bai and Ng (2002) criteria
r_df_2yoy <- ICr(df_2yoy)
r_df_2yoy

ICfactors(df_2yoy[,2:ncol(df_2yoy)], type = 2)

# Screeplot
screeplot(r_df_2yoy)

# Number of factors - modified Bai and Ng (2002) criteria according to Halli and Liska (2007)
int <- seq(0,15,0.5)
rc_df_2yoy <- ICr_c(df_2yoy[,2:ncol(df_2yoy)])
xx <- matrix(NA,length(int),4)
logV <- rc_df_2yoy[["logV"]]
cvec <- rc_df_2yoy[["cvec"]]
results <- rc_df_2yoy[["IC"]]
for (i in 1:length(int)) {
  c <- int[i]
  ic_c <- logV+cvec*c
  r.star <- t(as.matrix(apply(ic_c, 2, FUN = which.min)))
  xx[i,] <- cbind(c,r.star)
}
xx <- cbind(xx,apply(xx[,2:ncol(xx)],1,mean))
plot(xx[,1],xx[,ncol(xx)],type="l",ylab = "Number of factors", xlab ="c")


###############################################
# Factors with different sets of variables
###############################################

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy")
plot.ts(na.omit(df[,selection]))
df_cred <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_cred)[1] <- "obstime"
dfm_cred <- DFM(df_cred[,2:ncol(df_cred)], r = 1, p = 1) 
df_cred <- cbind(df_cred,dfm_cred$F_pca)
colnames(df_cred)[ncol(df_cred)] <- "factor.narrow"
plot(dfm_cred)

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy")
plot.ts(na.omit(df[,selection]))
df_assets <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_assets)[1] <- "obstime"
dfm_assets <- DFM(df_assets[,2:ncol(df_assets)], r = 1, p = 1) 
df_assets <- cbind(df_assets,dfm_assets$F_pca)
colnames(df_assets)[ncol(df_assets)] <- "factor.baseline"
plot(dfm_assets)

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy", "dsr.pnfs.2yoy","cred.tot.2gdp.2yoy")
plot.ts(na.omit(df[,selection]))
df_all <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_all)[1] <- "obstime"
dfm_all <- DFM(df_all[,2:ncol(df_all)], r = 1, p = 1) 
df_all <- cbind(df_all,dfm_all$F_pca)
colnames(df_all)[ncol(df_all)] <- "factor.broad"
plot(dfm_all)

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.pnfs.2yoy","cred.tot.2gdp.2yoy","sprd.nfc","sprd.hh","sprd.c","sprd.bond","sp.vol")
plot.ts(na.omit(df[,selection]))
df_mkt <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_mkt)[1] <- "obstime"
dfm_mkt <- DFM(df_mkt[,2:ncol(df_mkt)], r = 1, p = 1) 
df_mkt <- cbind(df_mkt,dfm_mkt$F_pca)
colnames(df_mkt)[ncol(df_mkt)] <- "factor.mkt"
plot(dfm_mkt)

# Merge in a single df
dfm_vars <- df_cred[,c("obstime","factor.narrow")] %>% 
             merge(df_assets[,c("obstime","factor.baseline")],by = "obstime", all = T) %>% 
             merge(df_all[,c("obstime","factor.broad")],by = "obstime", all = T) %>% 
             merge(df_mkt[,c("obstime","factor.mkt")],by = "obstime", all = T) 

df_vars <- merge(df,dfm_vars,all = T)

###############################################
# Stability of the factors
###############################################

break.date <- '2000-03-31'
break.i <- which(df_assets$obstime == as.Date(break.date))

df_assets_pre <- df_assets[df_assets$obstime<break.date,]
df_assets_post <- df_assets[df_assets$obstime>=break.date,]

# screeplot

df_assets_ic <- ICr(df_assets[,2:(ncol(df_assets)-1)], max.r = 4)
df_assets_pre_ic <- ICr(df_assets_pre[,2:(ncol(df_assets_pre)-1)], max.r = 4)
df_assets_post_ic <- ICr(df_assets_post[,2:(ncol(df_assets_post)-1)], max.r = 4)

eigen_assets <- c(100*df_assets_ic$eigenvalues[1]/sum(df_assets_ic$eigenvalues),
                  100*df_assets_ic$eigenvalues[2]/sum(df_assets_ic$eigenvalues),
                  100*df_assets_ic$eigenvalues[3]/sum(df_assets_ic$eigenvalues),
                  100*df_assets_ic$eigenvalues[4]/sum(df_assets_ic$eigenvalues))
            
eigen_assets_pre <-c(100*df_assets_pre_ic$eigenvalues[1]/sum(df_assets_pre_ic$eigenvalues),
                     100*df_assets_pre_ic$eigenvalues[2]/sum(df_assets_pre_ic$eigenvalues),
                     100*df_assets_pre_ic$eigenvalues[3]/sum(df_assets_pre_ic$eigenvalues),
                     100*df_assets_pre_ic$eigenvalues[4]/sum(df_assets_pre_ic$eigenvalues))


eigen_assets_post <-c(100*df_assets_post_ic$eigenvalues[1]/sum(df_assets_post_ic$eigenvalues),
                      100*df_assets_post_ic$eigenvalues[2]/sum(df_assets_post_ic$eigenvalues),
                      100*df_assets_post_ic$eigenvalues[3]/sum(df_assets_post_ic$eigenvalues),
                      100*df_assets_post_ic$eigenvalues[4]/sum(df_assets_post_ic$eigenvalues))

eigen_assets_graph <- rbind(eigen_assets,eigen_assets_pre,eigen_assets_post)
rownames(eigen_assets_graph) <- c("full sample","pre 2000","post 2000")
colnames(eigen_assets_graph) <- c("1st factor","2nd factor","3rd factor","4th factor")
barplot(t(eigen_assets_graph),
        beside=TRUE,
        ylab="% of variance explained",
        legend.text = colnames(eigen_assets_graph),
        args.legend = list(x = "topleft", bty = "n"),
        main = "Baseline")



# factor estimation

  # sub samples

dfm_assets_pre <- as.data.frame(cbind(df_assets_pre$obstime,DFM(df_assets_pre[,2:(ncol(df_assets_pre)-1)], r = 1, p = 1)$F_pca)) 
dfm_assets_pre[,1] <- as.Date(dfm_assets_pre[,1])
names(dfm_assets_pre) <- c("obstime","factor.baseline.pre")

dfm_assets_post <- as.data.frame(cbind(df_assets_post$obstime,DFM(df_assets_post[,2:(ncol(df_assets_post)-1)], r = 1, p = 1)$F_pca)) 
dfm_assets_post[,1] <- as.Date(dfm_assets_post[,1])
names(dfm_assets_post) <- c("obstime","factor.baseline.post")

dfm_assets_full <- df_assets[,c("obstime","factor.baseline")]

factor_subsample_graph <- full_join(dfm_assets_pre,dfm_assets_post,by="obstime")
factor_subsample_graph <- as.data.frame(cbind(factor_subsample_graph,df_assets[,"factor.baseline"]))
names(factor_subsample_graph) <- c("obstime","factor.baseline.pre","factor.baseline.post","factor.baseline")

plot(factor_subsample_graph$obstime,factor_subsample_graph$factor.baseline,type="l",ylim=c(-2.5,4),ylab="",xlab="")
lines(factor_subsample_graph$obstime,factor_subsample_graph$factor.baseline.pre,type="l",col="red")
lines(factor_subsample_graph$obstime,factor_subsample_graph$factor.baseline.post,type="l",col="blue")
legend("topright",legend=c("pre 2000","post 2000","full sample"),col=c("red","blue","green"),lty=1)

  # Rolling and expanding window

i.end <- nrow(df_assets)
i.window <- which(df_assets$obstime == as.Date(break.date)) # round(nrow(df_assets)/2,0) #   
factor_window <- matrix(NA,nrow=i.end,ncol=2)

factor_window[1:i.window,1] <-DFM(df_assets[1:i.window,2:(ncol(df_assets)-1)], r = 1, p = 1)$F_pca
factor_window[1:i.window,2] <-DFM(df_assets[1:i.window,2:(ncol(df_assets)-1)], r = 1, p = 1)$F_pca

for (i in 1:(i.end-i.window+1)) {
  aux <- DFM(df_assets[i:(i.window+i-1),2:(ncol(df_assets)-1)], r = 1, p = 1)$F_pca
  aux2 <- DFM(df_assets[1:(i.window+i-1),2:(ncol(df_assets)-1)], r = 1, p = 1)$F_pca
  factor_window[i.window+i-1,] <- c(aux[length(aux)],aux2[length(aux2)])  
}

factor_window_graph <- cbind(dfm_assets_full,factor_window)
names(factor_window_graph)[3:4] <- c("factor.rolling","factor.expanding")

plot(factor_window_graph$obstime,factor_window_graph$factor.baseline,type="l", ylab="", xlab="")
lines(factor_window_graph$obstime,factor_window_graph$factor.rolling,type="l",col="red",lty=2)
lines(factor_window_graph$obstime,factor_window_graph$factor.expanding,type="l",col="blue",lty=2)
abline(v=factor_window_graph[i.window,"obstime"],lty=2)
legend("topright",legend=c("full sample","rolling window","expanding window"),col=c("black","red"),lty=c(1,2,2))


  # Stability tests (QLR test)

trim <- 0.2

df_assets[round(trim*nrow(df_assets)), "obstime"]
df_assets[(round((1-trim)*nrow(df_assets))+1),"obstime"]
df_assets[round((1-trim*2)*nrow(df_assets))+1, "obstime"]

qlr_out <- matrix(NA,nrow = round((1-trim*2)*nrow(df_assets))+1, ncol = ncol(df_assets)-2)
qlr_out <- as.data.frame(qlr_out)
colnames(qlr_out) <- colnames(df_assets)[2:(ncol(df_assets)-1)]

qlr <- Fstats(df_assets$cred.nfc.2yoy ~ df_assets$factor.baseline + lag(df_assets$factor.baseline), from = trim)
bound <- boundary.Fstats(qlr)

for (i in 2:(ncol(df_assets)-1)) {
  qlr_out[,i-1] <- Fstats(df_assets[,i] ~ df_assets$factor.baseline + lag(df_assets$factor.baseline), from = trim)$Fstats
}

qlr_out <- cbind(qlr_out,bound)
qlr_out$obstime <- df_assets[round(trim*nrow(df_assets)):(round((1-trim)*nrow(df_assets))+1),"obstime"]

plot(qlr_out$obstime,qlr_out$cred.hh.2yoy,type="l",ylab="",xlab="")
lines(qlr_out$obstime,qlr_out$cred.nfc.2yoy,type="l",col="2")       
lines(qlr_out$obstime,qlr_out$rhp.2yoy,type="l",col="3")       
lines(qlr_out$obstime,qlr_out$sp.2yoy,type="l",col="4")  
lines(qlr_out$obstime,qlr_out$bound,col=1,lty=2)
legend("topright",
       legend=c("Household credit","Non-financial corporations credit","Real house prices","Share prices","5% Critical Value (Andrews, 1993)"),
       col=c(1,2,3,4,1),
       lty=c(1,1,1,1,2))

######################################################
# Factors with different sets of variables - post 2000

# WARNING: 
# The dataframes created in this section have the same name 
# as the ones created in the section that includes data prior to 2000. 

######################################################

bd <- '2001-03-31'

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy")
plot.ts(na.omit(df[,selection]))
df_cred <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_cred)[1] <- "obstime"
df_cred <- df_cred[df_cred$obstime>=bd,]
dfm_cred <- DFM(df_cred[,2:ncol(df_cred)], r = 1, p = 1) 
df_cred <- cbind(df_cred,dfm_cred$F_pca)
colnames(df_cred)[ncol(df_cred)] <- "factor.narrow"
plot(dfm_cred)

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy")
plot.ts(na.omit(df[,selection]))
df_assets <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_assets)[1] <- "obstime"
df_assets <- df_assets[df_assets$obstime>=bd,]
dfm_assets <- DFM(df_assets[,2:ncol(df_assets)], r = 1, p = 1) 
df_assets <- cbind(df_assets,dfm_assets$F_pca)
colnames(df_assets)[ncol(df_assets)] <- "factor.baseline"
plot(dfm_assets)

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy", "dsr.pnfs.2yoy","cred.tot.2gdp.2yoy")
plot.ts(na.omit(df[,selection]))
df_all <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_all)[1] <- "obstime"
df_all <- df_all[df_all$obstime>=bd,]
df_avar <- avar(as.matrix(df_all[,-1])) %>% cbind(df_all[,1],.)
colnames(df_avar)[1] <- "obstime"
dfm_all <- DFM(df_all[,2:ncol(df_all)], r = 1, p = 1) 
df_all <- cbind(df_all,dfm_all$F_pca)
colnames(df_all)[ncol(df_all)] <- "factor.broad"

plot(dfm_all)

selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.pnfs.2yoy","cred.tot.2gdp.2yoy","sprd.nfc","sprd.hh","sprd.c","sprd.bond","sp.vol")
plot.ts(na.omit(df[,selection]))
df_mkt <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_mkt)[1] <- "obstime"
df_mkt <- df_mkt[df_mkt$obstime>=bd,]
dfm_mkt <- DFM(df_mkt[,2:ncol(df_mkt)], r = 1, p = 1) 
df_mkt <- cbind(df_mkt,dfm_mkt$F_pca)
colnames(df_mkt)[ncol(df_mkt)] <- "factor.mkt"
plot(dfm_mkt)

# Merge in a single df
dfm_vars <- df_cred[,c("obstime","factor.narrow")] %>% 
  merge(df_assets[,c("obstime","factor.baseline")],by = "obstime", all = T) %>% 
  merge(df_all[,c("obstime","factor.broad")],by = "obstime", all = T) %>% 
  merge(df_mkt[,c("obstime","factor.mkt")],by = "obstime", all = T) 

df_vars <- merge(df,dfm_vars,all = T)

# Aditional exercises substituting dsr.pnfs.2yoy by different interest rates (shadow rate, interbank rate, long-run (10y) gov yields and short-run (3m) gov yields)

# ir.sr
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","ir.sr","cred.tot.2gdp.2yoy")
plot.ts(na.omit(df[,selection]))
df_ir_sr <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_ir_sr)[1] <- "obstime"
df_ir_sr <- df_ir_sr[df_ir_sr$obstime>=bd,]
dfm_ir_sr <- DFM(df_ir_sr[,2:ncol(df_ir_sr)], r = 1, p = 1) 
df_ir_sr <- cbind(df_ir_sr,dfm_ir_sr$F_pca)
colnames(df_ir_sr)[ncol(df_ir_sr)] <- "factor.ir_sr"
plot(dfm_ir_sr)

# ir.ib
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","ir.ib","cred.tot.2gdp.2yoy")
plot.ts(na.omit(df[,selection]))
df_ir_ib <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_ir_ib)[1] <- "obstime"
df_ir_ib <- df_ir_ib[df_ir_ib$obstime>=bd,]
dfm_ir_ib <- DFM(df_ir_ib[,2:ncol(df_ir_ib)], r = 1, p = 1) 
df_ir_ib <- cbind(df_ir_ib,dfm_ir_ib$F_pca)
colnames(df_ir_ib)[ncol(df_ir_ib)] <- "factor.ir_ib"
plot(dfm_ir_ib)

# ir.lr
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","ir.lt","cred.tot.2gdp.2yoy")
plot.ts(na.omit(df[,selection]))
df_ir_lt <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_ir_lt)[1] <- "obstime"
df_ir_lt <- df_ir_lt[df_ir_lt$obstime>=bd,]
dfm_ir_lt <- DFM(df_ir_lt[,2:ncol(df_ir_lt)], r = 1, p = 1) 
df_ir_lt <- cbind(df_ir_lt,dfm_ir_lt$F_pca)
colnames(df_ir_lt)[ncol(df_ir_lt)] <- "factor.ir_lt"
plot(dfm_ir_lt)

# ir.st
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","ir.st","cred.tot.2gdp.2yoy")
plot.ts(na.omit(df[,selection]))
df_ir_st <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_ir_st)[1] <- "obstime"
df_ir_st <- df_ir_st[df_ir_st$obstime>=bd,]
dfm_ir_st <- DFM(df_ir_st[,2:ncol(df_ir_st)], r = 1, p = 1) 
df_ir_st <- cbind(df_ir_st,dfm_ir_st$F_pca)
colnames(df_ir_st)[ncol(df_ir_st)] <- "factor.ir_st"
plot(dfm_ir_st)

# adding shadow rate and keeping the dsr in the model
selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.pnfs.2yoy","ir.sr","cred.tot.2gdp.2yoy")
plot.ts(na.omit(df[,selection]))
df_ir_sr2 <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_ir_sr2)[1] <- "obstime"
df_ir_sr2 <- df_ir_sr2[df_ir_sr2$obstime>=bd,]
dfm_ir_sr2 <- DFM(df_ir_sr2[,2:ncol(df_ir_sr2)], r = 1, p = 4) 
df_ir_sr2 <- cbind(df_ir_sr2,dfm_ir_sr2$F_pca)
colnames(df_ir_sr2)[ncol(df_ir_sr2)] <- "factor.ir_sr2"
plot(dfm_ir_sr2)
plot(dfm_ir_sr2, method = "all", type = "individual") 
plot(dfm_ir_sr2, type = "residual")
summary(dfm_ir_sr2)
plot(predict(dfm_ir_sr2), xlim = c(80, 100))

# Merge in a single df
dfm_ir <- df_ir_sr[,c("obstime","factor.ir_sr")] %>% 
  merge(df_ir_ib[,c("obstime","factor.ir_ib")],by = "obstime") %>% 
  merge(df_ir_lt[,c("obstime","factor.ir_lt")],by = "obstime") %>% 
  merge(df_ir_st[,c("obstime","factor.ir_st")],by = "obstime") %>% 
  merge(df_all[,c("obstime","factor.broad")],by = "obstime") %>% 
  merge(df_ir_sr2[,c("obstime","factor.ir_sr2")],by = "obstime")

######################################################

# Factor model with change point estimation

######################################################

#selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy")
#selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy")
#selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy", "dsr.pnfs.2yoy","cred.tot.2gdp.2yoy")
#selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy", "ir.lt","cred.tot.2gdp.2yoy")
#selection <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","sprd.nfc.2yoy")

var_list <- list(#narrow = c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy"),
                 baseline = c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy"),
                 broad = c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy", "dsr.new.2yoy","cred.tot.2gdp.2yoy"),
                 new1 = c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","sprd.bond"),
                 new2 = c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","ir.sr")
                 )

trim = 0.15
df_cp <- as.data.frame(df[,"obstime"])
colnames(df_cp) <- "obstime"
set.seed(123)

cp_est <- list()
cp_test <- list()
cp_inf <- list() 
list_avar <- list()


for (i in 1:length(var_list)) {
  
  selection <- var_list[[i]]  
  plot.ts(na.omit(df[,selection]))
  df_est <- na.omit(cbind(df[,1],df[,selection])) # df for estimation
  colnames(df_est)[1] <- "obstime"
  df_test <- df_est # df for the stability test
  
  # DFM ("linear")
  dfm_lin <- DFM(df_est[,2:ncol(df_est)], r = 1, p = 1) #factor_est_cp(df_est[,2:ncol(df_est)], r = 1) 
  #plot(dfm_lin)
  df_aux <- cbind(df_est,dfm_lin$F_pca) #cbind(df_est,dfm_lin$factor) 
  colnames(df_aux)[ncol(df_aux)] <- paste0(names(var_list)[i],".lin")
  
  # AVAR estimation
  df_avar <- avar(as.matrix(df_est[,-1])) %>% cbind(df_est[,1],.)
  list_avar[[i]] <- df_avar
  names(list_avar)[i] <- names(var_list)[i]
  
  # DFM with change point
  grid <- create_grid(df_est$obstime, trim)
  dfm_cp <- dfm_str_brk(df_est,grid,r=1)
  cp_est[[i]] <- dfm_cp
  names(cp_est)[i] <- names(var_list)[i]

  df_aux <- cbind(df_aux,dfm_cp$factor)
  colnames(df_aux)[ncol(df_aux)] <- paste0(names(var_list)[i],".cp")
  print(dfm_cp$break.date)
  df_aux <- cbind(df_aux,1*(df_aux$obstime>=dfm_cp$break.date))
  colnames(df_aux)[ncol(df_aux)] <- paste0(names(var_list)[i],".brk")
  df_aux <- df_aux[,c("obstime",paste0(names(var_list)[i],".lin"),paste0(names(var_list)[i],".cp"),paste0(names(var_list)[i],".brk"))]

  # # Conf interval for the change point estimate
  # conf_int <- dfm_conf_int(df_est,dfm_cp,grid,n_boot=250,trim=0.15,p=0.95)
  # break.date.p10 <- df_est[conf_int[["conf_int"]][["5%"]],"obstime"]
  # break.date.p90 <- df_est[conf_int[["conf_int"]][["95%"]],"obstime"]
  # df_aux <- cbind(df_aux,1*(df_aux$obstime==rep(break.date.p10,nrow(df_aux))))
  # colnames(df_aux)[ncol(df_aux)] <- paste0(names(var_list)[i],".p10")
  # df_aux <- cbind(df_aux,1*(df_aux$obstime==rep(break.date.p90,nrow(df_aux))))
  # colnames(df_aux)[ncol(df_aux)] <- paste0(names(var_list)[i],".p90")
  # cp_inf[[i]] <- conf_int
  # names(cp_inf)[i] <- names(var_list)[i]

  # Merge data
  df_cp <- merge(df_cp,df_aux,by="obstime",all.x = TRUE)

  # # Stability test
  # test_cp <- test_str_brk(df_test,grid,r=1)
  # cp_test[[i]] <- test_cp
  # names(cp_test)[i] <- names(var_list)[i]
  
}

df_vars <- merge(df_vars,df_cp[,c("obstime","baseline.lin","broad.lin","new1.lin","new2.lin")],by="obstime",all = TRUE)
#df_vars <- merge(df_vars,df_cp[,c("obstime","baseline.lin","baseline.cp","broad.lin","broad.cp","new1.lin","new1.cp","new2.cp")],by="obstime",all = TRUE)

# DFM with new1 
selection <- var_list[["new1"]]  
plot.ts(na.omit(df[,selection]))
df_est <- na.omit(cbind(df[,1],df[,selection])) # df for estimation
colnames(df_est)[1] <- "obstime"
dfm_lin <- DFM(df_est[,2:ncol(df_est)], r = 1, p = 1) #factor_est_cp(df_est[,2:ncol(df_est)], r = 1) 
plot(dfm_lin)
df_aux <- cbind(df_est,dfm_lin$F_pca)
colnames(df_aux)[ncol(df_aux)] <- paste0("new1",".lin")
plot(df_aux$obstime,df_aux$new1.lin,type="l")
df_avar <- avar(df_est[-1])
# Number of factors
# Bai and Ng (2002) criteria
r_df <- ICr(df_aux[-1])
screeplot(r_df)


###############################################
# Save files
###############################################

save(df_vars, file = "2. Data/df_vars.RData")
write_xlsx(df_vars,"2. Data/df_vars.xlsx")

###############################################
# Excel files for graphs
###############################################

# Excel function to convert dates to right format: =IF(MONTH(A2)=3; YEAR(A2); YEAR(A2) + IF(MONTH(A2)=6; 0.25; IF(MONTH(A2)=9; 0.5; IF(MONTH(A2)=12; 0.75))))

write_xlsx(qlr_out,"G:/6.APM/Financial Cycle/2. Data/figures/df_qlr_out.xlsx")

###############################################
# Graphs
###############################################

plot(dfm_vars$factor.narrow,type="l",ylim=c(-5,5))
lines(dfm_vars$factor.baseline,type="l",col="blue")
lines(dfm_vars$factor.broad,type="l",col="red")

selection <- c("factor.narrow","factor.baseline","factor.broad")
g2 <- na.omit(df_vars[,c("obstime",selection)]) %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g2

selection <- c("factor.baseline")
g3 <- na.omit(df_vars[,c("obstime",selection)]) %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g3

selection <- c("factor.narrow")
g4 <- na.omit(df_vars[,c("obstime",selection)]) %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g4

selection <- c("factor.broad")
g5 <- na.omit(df_vars[,c("obstime",selection)]) %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g5

plot(df_avar$obstime,df_avar$factor*(-1),type="l")
lines(df_avar$obstime,df_avar$factor.p5*(-1),col="red")
lines(df_avar$obstime,df_avar$factor.p95*(-1),col="red")


selection <- c("factor.ir_sr","factor.ir_ib","factor.ir_st","factor.ir_lt","factor.broad","factor.ir_sr2")
g6 <- na.omit(dfm_ir[,c("obstime",selection)]) %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g6

selection <- c("factor.ir_sr","factor.broad","factor.ir_sr2")
g7 <- na.omit(dfm_ir[,c("obstime",selection)]) %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g7

selection <- c("factor.ir_sr","factor.ir_ib","factor.ir_st","factor.ir_lt")
g8 <- na.omit(dfm_ir[,c("obstime",selection)]) %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(., aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  theme_classic() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank()) 
g8

# change point graphs

# Narrow
selection <- c("narrow.lin","narrow.cp")
break_time <- df_cp %>% filter(narrow.brk == 1) %>% slice(1) %>% pull(obstime)
fig <- df_cp %>%
  select(obstime, all_of(selection)) %>%
  na.omit() %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  geom_vline(xintercept = break_time, linetype = "dashed", color = "red") +  # Add vertical line
  theme_classic() +
  theme(legend.position = "bottom", 
        strip.background = element_blank(), 
        strip.text = element_blank())
fig

# Baseline
selection <- c("baseline.lin","baseline.cp")
break_time <- df_cp %>% filter(baseline.brk == 1) %>% slice(1) %>% pull(obstime)
fig <- df_cp %>%
  select(obstime, all_of(selection)) %>%
  na.omit() %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  geom_vline(xintercept = break_time, linetype = "dashed", color = "red") +  # Add vertical line
  theme_classic() +
  theme(legend.position = "bottom", 
        strip.background = element_blank(), 
        strip.text = element_blank())
print(fig)


# Broad
selection <- c("broad.lin","broad.cp")
break_time <- df_cp %>% filter(broad.brk == 1) %>% slice(1) %>% pull(obstime)
fig <- df_cp %>%
  select(obstime, all_of(selection)) %>%
  na.omit() %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  geom_vline(xintercept = break_time, linetype = "dashed", color = "red") +  # Add vertical line
  theme_classic() +
  theme(legend.position = "bottom", 
        strip.background = element_blank(), 
        strip.text = element_blank())
fig
write_xlsx(fig,"fig2.xlsx")

# New1
selection <- c("new1.lin","new1.cp")
break_time <- df_cp %>% filter(new1.brk == 1) %>% slice(1) %>% pull(obstime)
fig <- df_cp %>%
  select(obstime, all_of(selection)) %>%
  na.omit() %>%
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  geom_vline(xintercept = break_time, linetype = "dashed", color = "red") +  # Add vertical line
  theme_classic() +
  theme(legend.position = "bottom", 
        strip.background = element_blank(), 
        strip.text = element_blank())
fig

# New2
selection <- c("new2.lin","new2.cp")
break_time <- df_cp %>% filter(new2.brk == 1) %>% slice(1) %>% pull(obstime)
fig <- df_cp %>%
  select(obstime, all_of(selection)) %>%
  na.omit() %>%
  mutate(new2.cp = new2.cp*-1) %>% 
  pivot_longer(cols = all_of(selection), names_to = "variable", values_to = "value") %>%
  ggplot(aes(x = obstime, y = value, color = variable)) +
  geom_line() +
  geom_vline(xintercept = break_time, linetype = "dashed", color = "red") +  # Add vertical line
  theme_classic() +
  theme(legend.position = "bottom", 
        strip.background = element_blank(), 
        strip.text = element_blank())
fig

#############################################
# Stability tests
w <- cp_test$new1$lm_results
plot(w$obstime,w$rhp.2yoy,type="l",ylab="",xlab="",ylim=c(0,50))
lines(w$obstime,w$cred.nfc.2yoy,type="l",col="2")
lines(w$obstime,w$cred.hh.2yoy,type="l",col="3")       
lines(w$obstime,w$sp.2yoy,type="l",col="4")
lines(w$obstime,w$dsr.new.2yoy,type="l",col="5")
lines(w$obstime,w$cred.tot.2gdp.2yoy,type="l",col="6")
lines(w$obstime,w$ir.sr,type="l",col="7")
lines(qlr_out$obstime,qlr_out$bound,col=1,lty=2)

legend("topright",
       legend=c("Household credit","Non-financial corporations credit","Real house prices","Share prices","5% Critical Value (Andrews, 1993)"),
       col=c(1,2,3,4,1),
       lty=c(1,1,1,1,2))


# Stability tests
w <- cp_test$new1$lm_results
plot(w$obstime,w$rhp.2yoy,type="l",ylab="",xlab="",ylim=c(0,50))
lines(w$obstime,w$cred.nfc.2yoy,type="l",col="2")
lines(w$obstime,w$cred.hh.2yoy,type="l",col="3")       
lines(w$obstime,w$sp.2yoy,type="l",col="4")
lines(w$obstime,w$dsr.new.2yoy,type="l",col="5")
lines(w$obstime,w$cred.tot.2gdp.2yoy,type="l",col="6")
lines(w$obstime,w$ir.sr,type="l",col="7")
lines(qlr_out$obstime,qlr_out$bound,col=1,lty=2)

legend("topright",
       legend=c("Household credit","Non-financial corporations credit","Real house prices","Share prices","5% Critical Value (Andrews, 1993)"),
       col=c(1,2,3,4,1),
       lty=c(1,1,1,1,2))
#############################################
### Confidence intervals for the break date
ci_aux <- cp_est$new1$grid_results
plot(ci_aux$break.date,ci_aux$ssr,type="l")
write_xlsx(ci_aux,"ci_aux2.xlsx")
head(ci_aux)

df_boot <- as.data.frame(cp_inf$new1$df_boot)
head(df_boot)
p5 <- quantile(df_boot[,"break.date.i"],prob=0.05)
p95 <- quantile(df_boot[,"break.date.i"],prob=0.95)

ci_aux <- na.omit(df_cp[,c("obstime","new1.cp")])
ci_aux[p5,"obstime"]
ci_aux[p95,"obstime"]
##########################################

### P-value tables
stat_table <- cp_test$new1$sup_stat
df_lm <- cp_inf$new1$df_lm
j <- 2
for (j in 2:(nrow(stat_table))) {
  
  result <- sum(test_df[,j]>stat_table[3,j])
  
}

cv_table <- rbind(apply(cp_inf$new1$df_lm, 2, function(x) quantile(x, probs = 0.95)),
                  apply(cp_inf$new1$df_w, 2, function(x) quantile(x, probs = 0.95)),
                  apply(cp_inf$new1$df_lr, 2, function(x) quantile(x, probs = 0.95))) %>% cbind(c("lm","w","lr"),.)
print(cv_table)

cv_table_block <- rbind(apply(cp_inf$new1$df_lm_block, 2, function(x) quantile(x, probs = 0.95)),
                  apply(cp_inf$new1$df_w_block, 2, function(x) quantile(x, probs = 0.95)),
                  apply(cp_inf$new1$df_lr_block, 2, function(x) quantile(x, probs = 0.95))) %>% cbind(c("lm","w","lr"),.)
print(cv_table_block)


new1_inf <- cp_inf$new1
df_w_q <- apply(new1_inf$df_lm, 2, function(x) quantile(x, probs = 0.95))
print(df_w_q)

print(cp_test$broad$sup_stat)
print(cp_test$new2$sup_stat)
print(cp_test$new1$sup_stat)
###
print(rbind(new1_inf$lr_cv,new1_inf$w_cv,new1_inf$lm_cv)) # Bootstrap
print(rbind(new1_inf$lr_cv_block,new1_inf$w_cv_block,new1_inf$lm_cv_block)) # Block Bootstrap

pat <- "cred.hh.2yoy"
plot(density(new1_inf$df_lm[,pat]))
lines(density(new1_inf$df_w[,pat]))
lines(density(new1_inf$df_lr[,pat]))

plot(density(new1_inf$df_lm_block))
lines(density(new1_inf$df_w_block))
lines(density(new1_inf$df_lr_block))

# Bai and Ng (2002) criteria
r_df_2yoy <- ICr(df_est[,-1])
r_df_2yoy

x <- df_est
model_results <- dfm_cp 
grid <- grid
n_boot=250;trim=0.15;p=0.9
i <- 1
j <- 1

tbl <- test_cp$sup_stat
tbl

conf_int$lr_cv

obstime <- df_est$obstime
teste_w <- conf_int$df_w_block
teste_lr <- conf_int$df_lr_block
teste_lm <- conf_int$df_lm_block
plot(density(teste_lm))
lines(density(teste_lr),col="blue")
lines(density(teste_w),col="red")
teste_w <- conf_int$df_w
teste_lr <- conf_int$df_lr
teste_lm <- conf_int$df_lm
plot(density(teste_lm))
lines(density(teste_lr),col="blue")
lines(density(teste_w),col="red")

a <- test_cp$lr_results

plot(a$obstime,a$cred.hh.2yoy,type="l",ylim=c(0,50))
lines(a$obstime,a$cred.nfc.2yoy,col="red")
lines(a$obstime,a$rhp.2yoy,col="blue")
lines(a$obstime,a$dsr.new.2yoy,col="pink")
lines(a$obstime,a$sp.2yoy,col="green")
lines(a$obstime,a$cred.tot.2gdp.2yoy,col="grey")

b <- dfm_cp$grid_results
plot(b$break.date,b$ssr,type="l")
df_est[conf_int$conf_int[1],"obstime"]
df_est[conf_int$conf_int[2],"obstime"]
break.date.p10
break.date.p90


rbind(test_cp$sup_lr,test_cp$sup_w,test_cp$sup_lm)


#############################################
# Factors yoy
#############################################
load("G:/6.APM/Financial Cycle/2. Data/df_yoy.Rdata")

###############################################
# Factors with different sets of variables
###############################################

# selection <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy")
# plot.ts(na.omit(df[,selection]))
# df_cred <- na.omit(cbind(df[,1],df[,selection]))
# colnames(df_cred)[1] <- "obstime"
# dfm_cred <- DFM(df_cred[,2:ncol(df_cred)], r = 1, p = 1) 
# df_cred <- cbind(df_cred,dfm_cred$F_pca)
# colnames(df_cred)[ncol(df_cred)] <- "factor.narrow.yoy"
# plot(dfm_cred)
# 
# selection <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy","sp.yoy")
# plot.ts(na.omit(df[,selection]))
# df_assets <- na.omit(cbind(df[,1],df[,selection]))
# colnames(df_assets)[1] <- "obstime"
# dfm_assets <- DFM(df_assets[,2:ncol(df_assets)], r = 1, p = 1) 
# df_assets <- cbind(df_assets,dfm_assets$F_pca)
# colnames(df_assets)[ncol(df_assets)] <- "factor.baseline.yoy"
# plot(dfm_assets)

selection <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy","sp.yoy", "dsr.new.yoy","cred.tot.2gdp.yoy")
plot.ts(na.omit(df[,selection]))
df_all_yoy <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_all_yoy)[1] <- "obstime"
dfm_all_yoy <- DFM(df_all_yoy[,2:ncol(df_all_yoy)], r = 1, p = 1)
df_all_yoy <- cbind(df_all_yoy,dfm_all_yoy$F_pca)
colnames(df_all_yoy)[ncol(df_all_yoy)] <- "factor.broad.yoy"
plot(dfm_all_yoy)

selection <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy","sp.yoy","dsr.new.yoy","cred.tot.2gdp.yoy","sprd.bond")
plot.ts(na.omit(df[,selection]))
df_new1_yoy <- na.omit(cbind(df[,1],df[,selection]))
colnames(df_new1_yoy)[1] <- "obstime"
dfm_new1_yoy <- DFM(df_new1_yoy[,2:ncol(df_new1_yoy)], r = 1, p = 1) 
df_new1_yoy <- cbind(df_new1_yoy,dfm_new1_yoy$F_pca)
colnames(df_new1_yoy)[ncol(df_new1_yoy)] <- "factor.new1.yoy"
plot(dfm_new1_yoy)

# Merge in a single df
dfm_vars_yoy <- df_all_yoy[,c("obstime","factor.broad.yoy")] %>% 
  merge(df_new1_yoy[,c("obstime","factor.new1.yoy")],by = "obstime", all = T) 

df_vars_yoy <- merge(df,dfm_vars_yoy,all = T)
save(df_vars_yoy, file = "2. Data/df_vars_yoy.RData")

#############################################