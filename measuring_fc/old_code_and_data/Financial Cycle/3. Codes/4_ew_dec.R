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
library(pROC)
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/main_with_pass.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/trend_filterHP.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/filterhp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/normalise.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/urtests.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getseas.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/ICr_c.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/boundaryFstats.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getauroc.R")

load("G:/6.APM/Financial Cycle/2. Data/df_vars.RData")

###############################################
# Decomposition of factors
###############################################

# factor.narrow (narrow)

tail(df_vars)

reg <- lm(df_vars$factor.narrow ~ 0 + #without intercept
            df_vars$cred.nfc.2yoy +
            df_vars$cred.hh.2yoy +
            df_vars$rhp.2yoy
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 


for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"factor.narrow"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}

names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","factor.narrow")],df_aux3))
df_dec_narrow <- df_aux3

  # reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))

  # create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "factor.narrow", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "factor.narrow", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255)#,
                               #"sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255)#,
                               #"dsr.pnfs.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                               #"cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255)
  )) +
  scale_color_manual(values = c("factor.narrow" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())



# factor.baseline (baseline)

tail(df_vars)

reg <- lm(df_vars$factor.baseline ~ 0 + #without intercept
            df_vars$cred.nfc.2yoy +
            df_vars$cred.hh.2yoy +
            df_vars$rhp.2yoy +
            df_vars$sp.2yoy
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 


for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

tail(df_aux2)


row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"factor.baseline"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}


names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","factor.baseline")],df_aux3))

#   # correct very extreme value by turning it equal to the previous observation
# df_aux3[df_aux3$obstime=="2015-12-31",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2015-09-30",2:ncol(df_aux3)]
# df_dec_baseline <- df_aux3

  # reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))
df_dec_baseline <- df_graph

  # create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "factor.baseline", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "factor.baseline", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                               "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255)#,
                               #"dsr.pnfs.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                               #"cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255)
  )) +
  scale_color_manual(values = c("factor.baseline" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())



# factor.broad (broad)

tail(df_vars)

reg <- lm(df_vars$factor.broad~ 0 + #without intercept
                df_vars$cred.nfc.2yoy +
                df_vars$cred.hh.2yoy +
                df_vars$rhp.2yoy +
                df_vars$sp.2yoy +
                df_vars$dsr.pnfs.2yoy + 
                df_vars$cred.tot.2gdp.2yoy,
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.pnfs.2yoy","cred.tot.2gdp.2yoy")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 

for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"factor.broad"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}

names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.pnfs.2yoy","cred.tot.2gdp.2yoy")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","factor.broad")],df_aux3))
df_dec_broad <- df_aux3

  # reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))

  # create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "factor.broad", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "factor.broad", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                               "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                               "dsr.pnfs.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                               "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255))) +
  scale_color_manual(values = c("factor.broad" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())


# factor.mkt (broad + market indicators)

tail(df_vars)

reg <- lm(df_vars$factor.mkt~ 0 + #without intercept
            df_vars$cred.nfc.2yoy +
            df_vars$cred.hh.2yoy +
            df_vars$rhp.2yoy +
            df_vars$sp.2yoy +
            df_vars$dsr.pnfs.2yoy + 
            df_vars$cred.tot.2gdp.2yoy + 
            df_vars$sprd.nfc +
            df_vars$sprd.hh + 
            df_vars$sprd.c +
            df_vars$sprd.bond +
            df_vars$sp.vol,
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.pnfs.2yoy","cred.tot.2gdp.2yoy","sprd.nfc","sprd.hh","sprd.c","sprd.bond","sp.vol")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 

for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"factor.mkt"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}

names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.pnfs.2yoy","cred.tot.2gdp.2yoy","sprd.nfc","sprd.hh","sprd.c","sprd.bond","sp.vol")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","factor.mkt")],df_aux3))

  # correct very extreme value by turning it equal to the previous observation
df_aux3[df_aux3$obstime=="2013-09-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2013-06-30",2:ncol(df_aux3)]
df_aux3[df_aux3$obstime=="2007-09-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2007-06-30",2:ncol(df_aux3)]
df_aux3[df_aux3$obstime=="2022-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2022-03-31",2:ncol(df_aux3)]
df_dec_mkt <- df_aux3

# reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))

  # create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "factor.mkt", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "factor.mkt", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                               "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                               "dsr.pnfs.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                               "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255),
                               "sprd.nfc" = rgb(160, 210, 45, maxColorValue = 255),
                               "sprd.hh"=rgb(165, 25, 140, maxColorValue = 255),
                               "sprd.c"=rgb(90, 40, 160, maxColorValue = 255),
                               "sprd.bond"=rgb(20, 170, 160, maxColorValue = 255),
                               "sp.vol"=rgb(73, 134, 191, maxColorValue = 255))) +
  scale_color_manual(values = c("factor.mkt" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())

# Broad - Linear (with new dsti)

tail(df_vars)

reg <- lm(df_vars$broad.lin ~ 0 + #without intercept
            df_vars$cred.nfc.2yoy +
            df_vars$cred.hh.2yoy +
            df_vars$rhp.2yoy +
            df_vars$sp.2yoy +
            df_vars$dsr.new.2yoy +
            df_vars$cred.tot.2gdp.2yoy
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 

for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"broad.lin"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}

names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","broad.lin")],df_aux3))

# correct very extreme value by turning it equal to the previous observation
#df_aux3[df_aux3$obstime=="2019-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2019-03-31",2:ncol(df_aux3)]

# reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))

# create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "broad.lin", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "broad.lin", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                               "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                               "dsr.new.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                               "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255)
  )) +
  scale_color_manual(values = c("broad.lin" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())


# New1 - Linear

tail(df_vars)

reg <- lm(df_vars$new1.lin ~ 0 + #without intercept
            df_vars$cred.nfc.2yoy +
            df_vars$cred.hh.2yoy +
            df_vars$rhp.2yoy +
            df_vars$sp.2yoy +
            df_vars$dsr.new.2yoy +
            df_vars$cred.tot.2gdp.2yoy +
            df_vars$sprd.bond
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","sprd.bond")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 

for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"new1.lin"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}

names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","sprd.bond")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","new1.lin")],df_aux3))
write_xlsx(df_aux3,"df_aux3.xlsx")
# correct very extreme value by turning it equal to the previous observation
df_aux3[df_aux3$obstime=="2019-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2019-03-31",2:ncol(df_aux3)]

# reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))

# create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "new1.lin", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "new1.lin", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                               "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                               "dsr.new.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                               "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255),
                               "sprd.bond" = rgb(160, 210, 45, maxColorValue = 255)
  )) +
  scale_color_manual(values = c("new1.lin" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())

# Baseline - lin

tail(df_vars)

reg <- lm(df_vars$baseline.lin ~ 0 + #without intercept
            df_vars$cred.nfc.2yoy +
            df_vars$cred.hh.2yoy +
            df_vars$rhp.2yoy +
            df_vars$sp.2yoy 
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 

for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"baseline.lin"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}

names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","baseline.lin")],df_aux3))

# # correct very extreme value by turning it equal to the previous observation
# df_aux3[df_aux3$obstime=="1992-09-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1991-06-30",2:ncol(df_aux3)]
# df_aux3[df_aux3$obstime=="1996-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1996-03-31",2:ncol(df_aux3)]
# #write_xlsx(df_aux3,"df_new2.xlsx")

# reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))
#write_xlsx(df_aux3,"dec_baseline_extended.xlsx")

# create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "baseline.lin", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "baseline.lin", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                               "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255)
  )) +
  scale_color_manual(values = c("baseline.lin" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())


  # Broad - lin

tail(df_vars)

reg <- lm(df_vars$broad.lin ~ 0 + #without intercept
            df_vars$cred.nfc.2yoy +
            df_vars$cred.hh.2yoy +
            df_vars$rhp.2yoy +
            df_vars$sp.2yoy +
            df_vars$dsr.new.2yoy +
            df_vars$cred.tot.2gdp.2yoy
)

summary(reg)
coef <- reg$coefficients
df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy")]
df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 

for (i in 1:ncol(df_aux2)) {
  
  df_aux2[,i] <- df_aux[,i]*coef[i]
  
}

row.sum <- rowSums(df_aux2)
df_aux2 <- df_aux2/row.sum

df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"broad.cp"]))

for (i in 1:ncol(df_aux3)) {
  
  df_aux3[,i] <- df_aux2[,i]*df_f[,i]
  
}

names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy")
df_aux3 <- na.omit(cbind(df_vars[,c("obstime","broad.cp")],df_aux3))

# correct very extreme value by turning it equal to the previous observation
df_aux3[df_aux3$obstime=="1999-12-31",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1999-06-30",2:ncol(df_aux3)]
df_aux3[df_aux3$obstime=="1996-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1996-03-31",2:ncol(df_aux3)]
#write_xlsx(df_aux3,"df_new2.xlsx")

# reshape the data for ggplot's geom_bar
df_graph <- melt(df_aux3, id.vars = c("obstime"))

# create a plot
ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
  geom_bar(data = df_graph[df_graph$variable != "broad.cp", ], stat = "identity") +
  geom_line(data = df_graph[df_graph$variable == "broad.cp", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
  labs(#title = "Financial cylce decomposition",
    x = "",
    y = "",
    fill = "Variables",
    color = "Variables") +
  scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                               "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                               "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                               "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                               "dsr.new.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                               "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255)
  )) +
  scale_color_manual(values = c("broad.cp" = "black")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())


# Change Point


  # New1
  
  tail(df_vars)
  
  reg <- lm(df_vars$new1.cp ~ 0 + #without intercept
              df_vars$cred.nfc.2yoy +
              df_vars$cred.hh.2yoy +
              df_vars$rhp.2yoy +
              df_vars$sp.2yoy +
              df_vars$dsr.new.2yoy +
              df_vars$cred.tot.2gdp.2yoy +
              df_vars$sprd.bond
  )
  
  summary(reg)
  coef <- reg$coefficients
  df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","sprd.bond")]
  df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 
  
  for (i in 1:ncol(df_aux2)) {
    
    df_aux2[,i] <- df_aux[,i]*coef[i]
    
  }
  
  row.sum <- rowSums(df_aux2)
  df_aux2 <- df_aux2/row.sum
  
  df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
  df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"new1.cp"]))
  
  for (i in 1:ncol(df_aux3)) {
    
    df_aux3[,i] <- df_aux2[,i]*df_f[,i]
    
  }
  
  names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","sprd.bond")
  df_aux3 <- na.omit(cbind(df_vars[,c("obstime","new1.cp")],df_aux3))

  # correct very extreme value by turning it equal to the previous observation
  df_aux3[df_aux3$obstime=="1995-12-31",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1995-09-30",2:ncol(df_aux3)]
  
  # reshape the data for ggplot's geom_bar
  df_graph <- melt(df_aux3, id.vars = c("obstime"))
  
  # create a plot
  ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
    geom_bar(data = df_graph[df_graph$variable != "new1.cp", ], stat = "identity") +
    geom_line(data = df_graph[df_graph$variable == "new1.cp", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
    geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
    labs(#title = "Financial cylce decomposition",
      x = "",
      y = "",
      fill = "Variables",
      color = "Variables") +
    scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                                 "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                                 "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                                 "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                                 "dsr.new.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                                 "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255),
                                 "sprd.bond" = rgb(160, 210, 45, maxColorValue = 255)
                                 )) +
    scale_color_manual(values = c("new1.cp" = "black")) +
    theme_base() +
    theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())

  # New2
  
  tail(df_vars)
  
  reg <- lm(df_vars$new2.cp ~ 0 + #without intercept
              df_vars$cred.nfc.2yoy +
              df_vars$cred.hh.2yoy +
              df_vars$rhp.2yoy +
              df_vars$sp.2yoy +
              df_vars$dsr.new.2yoy +
              df_vars$cred.tot.2gdp.2yoy +
              df_vars$ir.sr
  )
  
  summary(reg)
  coef <- reg$coefficients
  df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","ir.sr")]
  df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 
  
  for (i in 1:ncol(df_aux2)) {
    
    df_aux2[,i] <- df_aux[,i]*coef[i]
    
  }
  
  row.sum <- rowSums(df_aux2)
  df_aux2 <- df_aux2/row.sum
  
  df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
  df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"new2.cp"]))
  
  for (i in 1:ncol(df_aux3)) {
    
    df_aux3[,i] <- df_aux2[,i]*df_f[,i]
    
  }
  
  names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy","ir.sr")
  df_aux3 <- na.omit(cbind(df_vars[,c("obstime","new2.cp")],df_aux3))
  
  # correct very extreme value by turning it equal to the previous observation
  df_aux3[df_aux3$obstime=="1996-03-31",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1995-12-31",2:ncol(df_aux3)]
  df_aux3[df_aux3$obstime=="1996-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1995-12-31",2:ncol(df_aux3)]  
  df_aux3[df_aux3$obstime=="1996-09-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1995-12-31",2:ncol(df_aux3)]  
  df_aux3[df_aux3$obstime=="2015-09-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2015-06-30",2:ncol(df_aux3)]  
  write_xlsx(df_aux3,"df_new2.xlsx")
  
  # reshape the data for ggplot's geom_bar
  df_graph <- melt(df_aux3, id.vars = c("obstime"))
  
  # create a plot
  ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
    geom_bar(data = df_graph[df_graph$variable != "new2.cp", ], stat = "identity") +
    geom_line(data = df_graph[df_graph$variable == "new2.cp", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
    geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
    labs(#title = "Financial cylce decomposition",
      x = "",
      y = "",
      fill = "Variables",
      color = "Variables") +
    scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                                 "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                                 "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                                 "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                                 "dsr.new.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                                 "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255),
                                 "ir.sr" = rgb(160, 210, 45, maxColorValue = 255)
                                  )) +
    scale_color_manual(values = c("new2.cp" = "black")) +
    theme_base() +
    theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())

  
  # Broad
  
  tail(df_vars)
  
  reg <- lm(df_vars$broad.cp ~ 0 + #without intercept
              df_vars$cred.nfc.2yoy +
              df_vars$cred.hh.2yoy +
              df_vars$rhp.2yoy +
              df_vars$sp.2yoy +
              df_vars$dsr.new.2yoy +
              df_vars$cred.tot.2gdp.2yoy
  )
  
  summary(reg)
  coef <- reg$coefficients
  df_aux <- df_vars[,c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy")]
  df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 
  
  for (i in 1:ncol(df_aux2)) {
    
    df_aux2[,i] <- df_aux[,i]*coef[i]
    
  }
  
  row.sum <- rowSums(df_aux2)
  df_aux2 <- df_aux2/row.sum
  
  df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
  df_f <- as.matrix(replicate(ncol(df_aux3),df_vars[,"broad.cp"]))
  
  for (i in 1:ncol(df_aux3)) {
    
    df_aux3[,i] <- df_aux2[,i]*df_f[,i]
    
  }
  
  names(df_aux3) <- c("cred.nfc.2yoy","cred.hh.2yoy","rhp.2yoy","sp.2yoy","dsr.new.2yoy","cred.tot.2gdp.2yoy")
  df_aux3 <- na.omit(cbind(df_vars[,c("obstime","broad.cp")],df_aux3))
  
  # correct very extreme value by turning it equal to the previous observation
  df_aux3[df_aux3$obstime=="1999-12-31",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1999-06-30",2:ncol(df_aux3)]
  df_aux3[df_aux3$obstime=="1996-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="1996-03-31",2:ncol(df_aux3)]
  #write_xlsx(df_aux3,"df_new2.xlsx")
  
  # reshape the data for ggplot's geom_bar
  df_graph <- melt(df_aux3, id.vars = c("obstime"))
  
  # create a plot
  ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
    geom_bar(data = df_graph[df_graph$variable != "broad.cp", ], stat = "identity") +
    geom_line(data = df_graph[df_graph$variable == "broad.cp", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
    geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
    labs(#title = "Financial cylce decomposition",
      x = "",
      y = "",
      fill = "Variables",
      color = "Variables") +
    scale_fill_manual(values = c("cred.nfc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                                 "cred.hh.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                                 "rhp.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                                 "sp.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                                 "dsr.new.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                                 "cred.tot.2gdp.2yoy" = rgb(111, 111, 111, maxColorValue = 255)
    )) +
    scale_color_manual(values = c("broad.cp" = "black")) +
    theme_base() +
    theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())

  
###############################################
# Decomposition yoy data
###############################################  
load("G:/6.APM/Financial Cycle/2. Data/df_vars_yoy.RData")

  # New1 - Linear
  
  tail(df_vars_yoy)
  
  reg <- lm(df_vars_yoy$factor.new1.yoy ~ 0 + #without intercept
              df_vars_yoy$cred.nfc.yoy +
              df_vars_yoy$cred.hh.yoy +
              df_vars_yoy$rhp.yoy +
              df_vars_yoy$sp.yoy +
              df_vars_yoy$dsr.new.yoy +
              df_vars_yoy$cred.tot.2gdp.yoy +
              df_vars_yoy$sprd.bond
  )
  
  summary(reg)
  coef <- reg$coefficients
  df_aux <- df_vars_yoy[,c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy","sp.yoy","dsr.new.yoy","cred.tot.2gdp.yoy","sprd.bond")]
  df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 
  
  for (i in 1:ncol(df_aux2)) {
    
    df_aux2[,i] <- df_aux[,i]*coef[i]
    
  }
  
  row.sum <- rowSums(df_aux2)
  df_aux2 <- df_aux2/row.sum
  
  df_aux3 <- data.frame(matrix(NA,nrow=nrow(df_aux2),ncol=ncol(df_aux2)))
  df_f <- as.matrix(replicate(ncol(df_aux3),df_vars_yoy[,"factor.new1.yoy"]))
  
  for (i in 1:ncol(df_aux3)) {
    
    df_aux3[,i] <- df_aux2[,i]*df_f[,i]
    
  }
  
  names(df_aux3) <- c("cred.nfc.yoy","cred.hh.yoy","rhp.yoy","sp.yoy","dsr.new.yoy","cred.tot.2gdp.yoy","sprd.bond")
  df_aux3 <- na.omit(cbind(df_vars_yoy[,c("obstime","factor.new1.yoy")],df_aux3))
  write_xlsx(df_aux3,"df_new1_yoy.xlsx")
  # correct very extreme value by turning it equal to the previous observation
  #df_aux3[df_aux3$obstime=="2019-06-30",2:ncol(df_aux3)] <- df_aux3[df_aux3$obstime=="2019-03-31",2:ncol(df_aux3)]
  
  # reshape the data for ggplot's geom_bar
  df_graph <- melt(df_aux3, id.vars = c("obstime"))
  
  # create a plot
  ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
    geom_bar(data = df_graph[df_graph$variable != "factor.new1.yoy", ], stat = "identity") +
    geom_line(data = df_graph[df_graph$variable == "factor.new1.yoy", ], aes(x = obstime, y = value, color = variable), size = 1.25) +
    geom_hline(yintercept = 0, color = "black", size = 0.5) +  # Horizontal line at y = 0
    labs(#title = "Financial cylce decomposition",
      x = "",
      y = "",
      fill = "Variables",
      color = "Variables") +
    scale_fill_manual(values = c("cred.nfc.yoy" = rgb(0, 70, 122, maxColorValue = 255),
                                 "cred.hh.yoy" = rgb(242, 200, 81, maxColorValue = 255),
                                 "rhp.yoy" = rgb(237, 26, 59, maxColorValue = 255),
                                 "sp.yoy" = rgb(50, 104, 49, maxColorValue = 255),
                                 "dsr.new.yoy" = rgb(245, 130, 50, maxColorValue = 255),
                                 "cred.tot.2gdp.yoy" = rgb(111, 111, 111, maxColorValue = 255),
                                 "sprd.bond" = rgb(160, 210, 45, maxColorValue = 255)
    )) +
    scale_color_manual(values = c("factor.new1.yoy" = "black")) +
    theme_base() +
    theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())
  
      
###############################################
# Early warning properties
###############################################


# create a sequence of dates with the last day of each quarter
start_date <- as.Date("1980-03-31")
end_date <- as.Date("2023-12-31") # add one more quarter to the date you really want

quarterly_dates <- seq.Date(from = start_date, to = end_date, by = "quarter")-days(1)
quarterly_dates[month(quarterly_dates) %in% c(03, 12)] <- ceiling_date(quarterly_dates[month(quarterly_dates) %in% c(3, 12)], "month") - days(1) # Adjust dates to ensure they end on the 31st day for March and December
df_crisis <- data.frame(obstime = quarterly_dates)

df_crisis$crisis <- ifelse(
  (df_crisis$obstime >= as.Date("1983-02-01") & df_crisis$obstime <= as.Date("1985-03-31")) |
    (df_crisis$obstime >= as.Date("2008-10-01") & df_crisis$obstime <= as.Date("2015-12-31")) |
    (df_crisis$obstime >= as.Date("1992-03-31") & df_crisis$obstime <= as.Date("1995-03-31")),
  1, 0
)

# lagged crisis indicator with NA values during crises

# original crisis start dates
crisis_dates <- as.Date(c('1983-02-01', '2008-10-01', '1992-03-31'))

# subtracting 5, 12 and 16 quarters (assuming 30 days per month for simplicity)
crisis_dates_5 <- crisis_dates %m-% months(15)
crisis_dates_12 <- crisis_dates %m-% months(36)
crisis_dates_16 <- crisis_dates %m-% months(48)

df_crisis$crisis.12.5 <- ifelse((df_crisis$obstime >= crisis_dates_12[1] & df_crisis$obstime <= crisis_dates_5[1]) |
                                  (df_crisis$obstime >= crisis_dates_12[2] & df_crisis$obstime <= crisis_dates_5[2]) |
                                  (df_crisis$obstime >= crisis_dates_12[3] & df_crisis$obstime <= crisis_dates_5[3]),
                                1,
                                ifelse(df_crisis$crisis == 1,
                                       NA,
                                       0)
)

df_crisis$crisis.16.5 <- ifelse((df_crisis$obstime >= crisis_dates_16[1] & df_crisis$obstime <= crisis_dates_5[1]) |
                                  (df_crisis$obstime >= crisis_dates_16[2] & df_crisis$obstime <= crisis_dates_5[2]) |
                                  (df_crisis$obstime >= crisis_dates_16[3] & df_crisis$obstime <= crisis_dates_5[3]),
                                1,
                                ifelse(df_crisis$crisis == 1,
                                       NA,
                                       0)
)

# ------------ OLD
# 
# # create a sequence of dates with the last day of each quarter
# start_date <- as.Date("1980-03-31")
# end_date <- as.Date("2023-09-30")
# 
# quarterly_dates <- seq.Date(from = start_date, to = end_date, by = "quarter")-days(1)
# quarterly_dates[month(quarterly_dates) %in% c(03, 12)] <- ceiling_date(quarterly_dates[month(quarterly_dates) %in% c(3, 12)], "month") - days(1) # Adjust dates to ensure they end on the 31st day for March and December
# df_date <- data.frame(obstime = quarterly_dates)
# 
# df_date$crisis <- ifelse(
#   (df_date$obstime >= as.Date("1983-02-01") & df_date$obstime <= as.Date("1985-03-31")) |
#   (df_date$obstime >= as.Date("2008-10-01") & df_date$obstime <= as.Date("2015-12-31")) |
#   (df_date$obstime >= as.Date("1992-03-31") & df_date$obstime <= as.Date("1995-03-31")),
#   1, 0
# )
# 
# # lagged crisis indicator with NA values during crises
# 
#   # original crisis start dates
# crisis_dates <- as.Date(c('1983-02-01', '2008-10-01', '1992-03-31'))
# 
#   # subtracting 5, 12 and 16 quarters (assuming 30 days per month for simplicity)
# crisis_dates_5 <- crisis_dates %m-% months(15)
# crisis_dates_12 <- crisis_dates %m-% months(36)
# crisis_dates_16 <- crisis_dates %m-% months(48)
# 
# df_date$crisis.12.5 <- ifelse((df_date$obstime >= crisis_dates_12[1] & df_date$obstime <= crisis_dates_5[1]) |
#                               (df_date$obstime >= crisis_dates_12[2] & df_date$obstime <= crisis_dates_5[2]) |
#                               (df_date$obstime >= crisis_dates_12[3] & df_date$obstime <= crisis_dates_5[3]),
#                               1,
#                               ifelse(df_date$crisis == 1,
#                                      NA,
#                                      0)
#                               )
# 
# df_date$crisis.16.5 <- ifelse((df_date$obstime >= crisis_dates_16[1] & df_date$obstime <= crisis_dates_5[1]) |
#                               (df_date$obstime >= crisis_dates_16[2] & df_date$obstime <= crisis_dates_5[2]) |
#                               (df_date$obstime >= crisis_dates_16[3] & df_date$obstime <= crisis_dates_5[3]),
#                               1,
#                               ifelse(df_date$crisis == 1,
#                                      NA,
#                                      0)
#   )
# df_crisis <- df_date


# estimate the probit models and respective auroc associated with alternative indicators

df_ew <- merge(df_vars[,c("obstime","new1.lin")],df_crisis,by ="obstime", all.x = TRUE) %>% na.omit()
#df_ew <- merge(df_vars[,c("obstime","factor.narrow","factor.baseline","factor.broad","factor.mkt")],df_crisis,by ="obstime", all.x = TRUE) %>% na.omit()

df_auroc <- data.frame(matrix(NA,nrow = 1 ,ncol=2))
vars <- c("new1.lin")
#vars <- c("factor.narrow","factor.baseline","factor.broad","factor.mkt")
crisis <- c("crisis.12.5","crisis.16.5")
colnames(df_auroc) <- crisis
rownames(df_auroc) <- vars

for(i in 1:length(vars)) {
  
  for (j in 1:length(crisis)) {
    
    df_auroc[i,j] <- getauroc(df_ew,crisis[j],vars[i])
  }
}

# estimate the probit models and respective auroc associated with alternative indicators
df_other_ind <- read_xlsx("G:/6.APM/Financial Cycle/2. Data/Indicators used in other works/Financial cycle indicators.xlsx")
df_other_ind$obstime <- as.Date(df_other_ind$obstime)
df_other_ind_ew <- merge(df_other_ind,df_crisis, by="obstime",all.x = TRUE) %>% na.omit()

df_auroc_2 <- data.frame(matrix(NA,nrow = 3 ,ncol=2))
vars <- c("sri","shp","bg")
crisis <- c("crisis.12.5","crisis.16.5")
colnames(df_auroc_2) <- crisis
rownames(df_auroc_2) <- vars

for(i in 1:length(vars)) {
  
  for (j in 1:length(crisis)) {
    
    df_auroc_2[i,j] <- getauroc(df_other_ind_ew,crisis[j],vars[i])
  }
}

order <- c("new1.lin")
#order <- c("factor.narrow","factor.baseline","factor.broad","factor.mkt")
df_auroc <- data.frame(rbind(df_auroc,df_auroc_2))
df_auroc$var <- rownames(df_auroc)
df_auroc_long <- gather(df_auroc, key = "crisis_type", value = "auroc", crisis.12.5, crisis.16.5) %>%
                 arrange(factor(match(var, order))) %>%
                 mutate(var = str_replace(var, "new1.lin", "Factor model"),
                        var = str_replace(var, "bg", "Basel gap"),
                        var = str_replace(var, "shp", "SHP (2020)"),
                        var = str_replace(var, "sri", "SRI"))


# Plotting grouped bar graphs with adjusted width, dodge position, custom order, and custom labels


ggplot(df_auroc_long, aes(x = reorder(var, -auroc), y = auroc, fill = crisis_type)) +
     geom_bar(stat = "identity", position = position_dodge2(width = 0.9, preserve = "single"), alpha = 0.7) +
     geom_text(aes(label = round(auroc, 2)), position = position_dodge2(width = 0.9, preserve = "single"), vjust = -0.5) +
     labs(title = "", x = "", y = "") +
     scale_fill_manual(values = c("crisis.12.5" = rgb(0, 70, 122, maxColorValue = 255),
                               "crisis.16.5" = rgb(242, 200, 81, maxColorValue = 255)),
                       labels = c("crisis.12.5" = "crisis 12-5", "crisis.16.5" = "crisis 16-5")) +
     theme_base() +
     theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(), legend.title = element_blank())


# Change point analysis

df_ew_cp <- merge(df_vars[,c("obstime","narrow.lin","baseline.lin","broad.lin","new1.lin","new2.lin","narrow.cp","baseline.cp","broad.cp","new1.cp","new2.cp")],df_crisis,by ="obstime", all.x = TRUE) %>% na.omit()

vars <- c("narrow.lin","baseline.lin","broad.lin","new1.lin","new2.lin","narrow.cp","baseline.cp","broad.cp","new1.cp","new2.cp")
crisis <- c("crisis.12.5","crisis.16.5")
df_auroc_cp <- data.frame(matrix(NA,nrow = length(vars) ,ncol=2))
colnames(df_auroc_cp) <- crisis
rownames(df_auroc_cp) <- vars

for(i in 1:length(vars)) {
  
  for (j in 1:length(crisis)) {
    
    df_auroc_cp[i,j] <- getauroc(df_ew_cp,crisis[j],vars[i])
  }
}

order <- c("narrow.lin","baseline.lin","broad.lin","new1.lin","new1.lin","narrow.cp","baseline.cp","broad.cp","new1.cp","new1.cp")
df_auroc_cp$var <- rownames(df_auroc_cp)
df_auroc_cp_long <- gather(df_auroc_cp, key = "crisis_type", value = "auroc", crisis.12.5, crisis.16.5) %>%
                    arrange(factor(match(var, order)))

# %>%
#   mutate(var = str_replace(var, "factor.narrow", "Narrow"),
#          var = str_replace(var, "factor.baseline", "Baseline"),
#          var = str_replace(var, "factor.broad", "Broad"),
#          var = str_replace(var, "factor.mkt", "Market"),
#          var = str_replace(var, "bg", "Basel gap"),
#          var = str_replace(var, "shp", "SHP (2020)"),
#          var = str_replace(var, "sri", "SRI"))


# Plotting grouped bar graphs with adjusted width, dodge position, custom order, and custom labels


ggplot(df_auroc_cp_long, aes(x = reorder(var, -auroc), y = auroc, fill = crisis_type)) +
  geom_bar(stat = "identity", position = position_dodge2(width = 0.9, preserve = "single"), alpha = 0.7) +
  geom_text(aes(label = round(auroc, 2)), position = position_dodge2(width = 0.9, preserve = "single"), vjust = -0.5) +
  labs(title = "", x = "", y = "") +
  scale_fill_manual(values = c("crisis.12.5" = rgb(0, 70, 122, maxColorValue = 255),
                               "crisis.16.5" = rgb(242, 200, 81, maxColorValue = 255)),
                    labels = c("crisis.12.5" = "crisis 12-5", "crisis.16.5" = "crisis 16-5")) +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(), legend.title = element_blank())


###############################################
# Impact on growth-at-risk
###############################################

df_gdp <- read_xlsx("G:/6.APM/Financial Cycle/2. Data/other sources/INE_gdp.xlsx")
df_gdp$obstime <- as.Date(df_gdp$obstime)
df_gdp$gdp.qoq.lag <- lag(df_gdp$gdp.qoq,5)
df_gdp <- na.omit(merge(df_vars,df_gdp,by = "obstime", all.x = TRUE))
df_gdp$factor.baseline.ind <- ifelse(df_gdp$factor.baseline>quantile(df_gdp$factor.baseline, 0.75),"1",0)

# Plotting pdf
g1 <- ggplot(df_gdp, aes(x = gdp.qoq.lag, color = as.factor(factor.baseline.ind))) +
      geom_density() +
      labs(title = "",
           x = "",
           y = "") +
      scale_color_manual(values = c("blue", "red"), name = "", labels = c("FC (baseline) <= p75", "FC (baseline) > p75")) +
      theme_base() +
      theme(legend.position = "bottom")

density <- ggplot_build(g1)
df_gdp_density <- density$data

# Plotting cdf
ggplot(df_gdp, aes(x = gdp.qoq.lag, color = as.factor(factor.baseline.ind))) +
  stat_ecdf() +
  labs(title = "",
       x = "",
       y = "") +
  scale_color_manual(values = c("blue", "red"), name = "", labels = c("FC (baseline) > p75", "FC (baseline) <= p75")) +
  theme_base() +
  theme(legend.position = "bottom")


###############################################
# Excel files for graphs
###############################################

# Excel function to convert dates to right format: =IF(MONTH(A2)=3; YEAR(A2); YEAR(A2) + IF(MONTH(A2)=6; 0.25; IF(MONTH(A2)=9; 0.5; IF(MONTH(A2)=12; 0.75))))

write_xlsx(df_auroc,"G:/6.APM/Financial Cycle/2. Data/figures/df_auroc.xlsx")
write_xlsx(df_gdp_density,"G:/6.APM/Financial Cycle/2. Data/figures/df_gdp_density.xlsx")
write_xlsx(df_dec_narrow,"G:/6.APM/Financial Cycle/2. Data/figures/df_dec_narrow.xlsx")
write_xlsx(df_dec_baseline,"G:/6.APM/Financial Cycle/2. Data/figures/df_dec_baseline.xlsx")
write_xlsx(df_dec_broad,"G:/6.APM/Financial Cycle/2. Data/figures/df_dec_broad.xlsx")
write_xlsx(df_dec_mkt,"G:/6.APM/Financial Cycle/2. Data/figures/df_dec_mkt.xlsx")