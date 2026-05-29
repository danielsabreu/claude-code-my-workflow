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
library(dplyr)
library(tidyr)
library(zoo)
library(readxl)
library(writexl)
library(mFilter)
library(reshape2)
library(data.table)
library(ggthemes)
library(ggplot2)
library(purrr)

source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/dfm_conf_int.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/avar.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/normalise.R")
#source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/dfm_str_break.R")
#source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/create_grid.R")
#source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/factor_est_cp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/ICr_c.R")

###############################################
# Load and Merge Data
###############################################

# Load the main dataset
load("G:/6.APM/Financial Cycle/2. Data/df_model.RData")

###############################################
# Compute factors, ic, and avar
###############################################

df_model <- lapply(df_model, function(df) {
                df <- df[df$obstime >= "1990-03-31", ]
                return(df)
              })

# factor model estimation
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

# IC and avar estimation
df_ic_avar <- df_model %>% 
  lapply(., function(df) {
    ic <-  ICr_c(df[,2:ncol(df)])
    var_exp <- ic$eigenvalues[1]/sum(ic$eigenvalues)
    avar <- avar(df)
    out <- list(ic=ic, avar=avar, loadings=loadings, var_exp = var_exp)
    return(out)
  }
  )

df_ic_avar <- map2(df_ic_avar,df_dfm, function(.x,.y) {
  if(cor(.x$avar$factor,.y$pca)<0) {.x$avar$factor = .x$avar$factor*-1
                                    .x$avar$factor.p10 = .x$avar$factor.p10*-1
                                    .x$avar$factor.p90 = .x$avar$factor.p90*-1
                                    .x$avar$factor.p90.mean = .x$avar$factor.p90.mean*-1
                                    .x$avar$factor.p10.mean = .x$avar$factor.p10.mean*-1}
  out <- list(.x$ic,.x$avar,.x$loadings, .x$var_exp)
  names(out) <- c("ic","avar","loadings", "var_exp")
  return(out)
})

# Regime identification
df_regimes <- lapply(names(df_ic_avar), function(country) {
  
  df <- df_ic_avar[[country]]$avar
  
  df$regime <- ifelse(df$factor > max(df$factor.p90.mean, df$factor.p10.mean), "Elevated",
                                            ifelse(df$factor < min(df$factor.p90.mean, df$factor.p10.mean),"Subdued", "Neutral"))

  return(df)
  
})
names(df_regimes) <- names(df_model)

# Loadings
df_loadings <- df_model %>% 
  lapply(., function(df) {
    loadings <- DFM(df[,2:ncol(df)], r = 1, p = 4)$C
    out <- list(loadings=loadings)
    return(out)
  }
  )

# Data frame to feed the decomposition 
df_dec <- lapply(seq_along(df_model), function(i) {
  dt_model <- as.data.table(df_model[[i]])  
  dt_dfm <- as.data.table(df_dfm[[i]])      
  dt_model[, obstime := as.Date(obstime)]
  dt_dfm[, obstime := as.Date(obstime)]
  df_result <- merge(dt_model, dt_dfm, by = "obstime", all.x = TRUE)
  setDF(df_result)  
  df_result
})
names(df_dec) <- names(df_model)

# R2
df_r2 <- lapply(df_dec, function(df) {
  var_r2 <- data.frame(matrix(NA, nrow = 1, ncol = ncol(df) - 1))
  colnames(var_r2) <- colnames(df)[-1]
  
  for (i in 2:ncol(df)) {
    var <- df[[i]]
    model <- lm(pca ~ var, data = df)
    var_r2[[i - 1]] <- summary(model)$r.squared
  }
  
  var_r2 <- var_r2[, !(colnames(var_r2) %in% c("pca", "qml", "tstep"))]
  var_r2 <- as.data.frame(var_r2)
  var_r2$mean_r2 <- mean(unlist(var_r2), na.rm = TRUE)
  var_r2$sd_r2 <- sd(unlist(var_r2), na.rm = TRUE)
  
  return(var_r2)
})

###############################################
# Save
###############################################

save(df_dec, file = "2. Data/df_dec.RData")
save(df_ic_avar, file = "2. Data/df_ic_avar.RData")
save(df_loadings, file = "2. Data/df_loadings.RData")
save(df_dfm, file = "2. Data/df_dfm.RData")

###############################################
# Graphs
###############################################

country <- "PT"

png("factor.png", width = 868, height = 422)
plot.ts(na.omit(df_model[[country]]))
plot(df_dfm[[country]]$obstime,df_dfm[[country]]$pca,type="l")
lines(df_dfm[[country]]$obstime,df_dfm[[country]]$qml,col="red")
lines(df_dfm[[country]]$obstime,df_dfm[[country]]$tstep,col="blue")
dev.off()

png("pca_conf.png", width = 868, height = 422)
plot(df_dfm[[country]]$obstime,df_dfm[[country]]$pca,type="l")
lines(df_ic_avar[[country]]$avar$obstime,df_ic_avar[[country]]$avar$factor.p5,col="red", lty = 2)
lines(df_ic_avar[[country]]$avar$obstime,df_ic_avar[[country]]$avar$factor.p95,col="red", lty = 2)
conf_int_graph <- data.frame(obstime = as.Date(df_dfm[[country]]$obstime), pca = df_dfm[[country]]$pca, p5 = df_ic_avar[[country]]$avar$factor.p5, p95 = df_ic_avar[[country]]$avar$factor.p95)
write_xlsx(conf_int_graph, path = "G:/6.APM/Financial Cycle/conf_int_graph.xlsx")
dev.off()

# Variance explained graph
df_var_exp <- data.frame(country = character(), var_exp = numeric(), stringsAsFactors = FALSE)
for (i in 1:length(df_ic_avar)) {
    new_row <- data.frame(country = names(df_ic_avar)[i], var_exp = df_ic_avar[[i]]$var_exp, stringsAsFactors = FALSE)
    df_var_exp <- rbind(df_var_exp, new_row)
}

df_var_exp$country <- factor(df_var_exp$country)

png("var_exp.png", width = 868, height = 422)
ggplot(df_var_exp, aes(x = country, y = var_exp)) +
  geom_bar(stat = "identity", position = position_dodge2(width = 0.9, preserve = "single"), fill = rgb(0, 70, 122, maxColorValue = 255)) +
  geom_text(aes(label = round(var_exp, 2)), position = position_dodge2(width = 0.9, preserve = "single"), vjust = -0.5) +
  geom_hline(yintercept = mean(df_var_exp$var_exp), linetype = "dashed", size = 0.8) +
  labs(title = "", x = "", y = "") +
  theme_base() +
  theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(), legend.title = element_blank(), axis.text.x = element_text(angle = 45, hjust = 1))
dev.off()


# Median of the financial cycle
df_factor_graph <- bind_rows(df_dfm, .id = "country")

medians <- aggregate(cbind(pca, qml, tstep) ~ obstime, data = df_factor_graph, FUN = median)
quantiles_by_period <- aggregate(cbind(pca, qml, tstep) ~ obstime, 
                                 data = df_factor_graph, 
                                 FUN = function(x) c(Q1 = quantile(x, 0.25, na.rm = TRUE),
                                                     Q3 = quantile(x, 0.75, na.rm = TRUE)))

quantiles_by_period <- do.call(data.frame, quantiles_by_period)
colnames(quantiles_by_period) <- c("obstime", "pca_Q25", "pca_Q75", "qml_Q25", "qml_Q75", "tstep_Q25", "tstep_Q75")

quantiles_combined <- data.frame(obstime = quantiles_by_period$obstime,
                                 Q25 = apply(quantiles_by_period[, c("pca_Q25", "qml_Q25", "tstep_Q25")], 1, min),
                                 Q75 = apply(quantiles_by_period[, c("pca_Q75", "qml_Q75", "tstep_Q75")], 1, max)
                                 )

medians_long <- reshape2::melt(medians, 
                     id.vars = "obstime", 
                     variable.name = "variable", 
                     value.name = "median_value")


png("factor_medians.png", width = 868, height = 422)
ggplot() +
  geom_ribbon(data = quantiles_combined, 
              aes(x = obstime, ymin = Q25, ymax = Q75), 
              fill = rgb(0, 70, 122, maxColorValue = 255), alpha = 0.3) +
  geom_line(data = medians_long, aes(x = obstime, y = median_value, color = variable), size = 1.2) +
  labs(title = "", x = "", y = "", color = "") +   
  theme_base()
dev.off()


# R2 Table
table_r2 <- bind_rows(lapply(names(df_r2), function(country) {
  aux <- df_r2[[country]]
  aux <- as.data.frame(aux)
  aux$Country <- country
  return(aux)
}))

average_row <- table_r2 %>%
  dplyr::select(-Country) %>% 
  summarise(across(everything(), ~ mean(.x, na.rm = TRUE))) %>%
  mutate(Country = "Average")  
table_r2 <- bind_rows(table_r2, average_row)

write_xlsx(table_r2, "G:/6.APM/Financial Cycle/2. Data/table_r2.xlsx")


# Financial cycle confidence bands
conf_graph <- lapply(names(df_ic_avar), function(country) {
  
  df <- df_ic_avar[[country]]$avar
  
  ggplot(df, aes(x = obstime)) +
    geom_ribbon(aes(ymin = factor.p10, ymax = factor.p90), fill = "gray80", alpha = 0.5) +
    geom_line(aes(y = factor), color = "blue", linewidth = 1) +
    geom_line(aes(y = factor.p10.mean), color = "black", linetype = "dashed", linewidth = 1) +
    geom_line(aes(y = factor.p90.mean), color = "black", linetype = "dashed", linewidth = 1) +
    labs(
      title = "",
      x = "",
      y = ""
    ) +
    scale_x_date(date_labels = "%Y", date_breaks = "4 year") + 
    theme_base()
  
})
names(conf_graph) <- names(df_ic_avar)

png("conf_graph.png", width = 868, height = 422)
conf_graph[["PT"]]
dev.off()

conf_graph$PT

# Regimes over time
regime_list <- map(df_regimes, ~ .x %>% dplyr::select(obstime, regime))
df_regime <- bind_rows(regime_list, .id = "country")

# Create the heatmap
regimes <- ggplot(df_regime, aes(x = obstime, y = country, fill = regime)) +
                  geom_tile(color = "white") +  # Tile for each combination
                  scale_fill_manual(
                    values = c(
                      "Subdued" = "blue",
                      "Neutral" = "gray",
                      "Elevated" = "red"
                    ),
                    name = ""
                  ) +
                  labs(
                    x = "",
                    y = "",
                    title = ""
                  ) +
                  theme_base() +
                  theme(
                    axis.text.x = element_text(angle = 0, hjust = 1),
                    axis.text.y = element_text(size = 10),
                    panel.grid = element_blank(),
                    legend.position = "bottom"
                  )

png("regimes_graph.png", width = 868, height = 422)
regimes
dev.off()

