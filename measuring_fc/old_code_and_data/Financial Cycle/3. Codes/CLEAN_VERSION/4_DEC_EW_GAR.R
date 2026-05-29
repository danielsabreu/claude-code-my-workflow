###############################################
# Preamble
###############################################

library(xts)
library(tidyverse)
library(readxl)
library(reshape2)
library(pROC)
library(lubridate)
library(ggthemes)
library(BISdata)
library(mFilter)

source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/main_with_pass.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/trend_filterHP.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/filterhp.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/normalise.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/urtests.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getseas.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/ICr_c.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/boundaryFstats.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getauroc.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/FC_decomposition.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/getfilter.R")
source("G:/6.APM/Financial Cycle/3. Codes/Auxiliary/transform_2yoy.R")


load("G:/6.APM/Financial Cycle/2. Data/df_dec.RData")

###############################################
# Decomposition
###############################################

# Country specific decomposition
dec <- lapply(df_dec, FC_decomposition)
dec_graph <- dec[["PT"]]$graph
dec[["PT"]]$dec
png("dec_graph.png", width = 868, height = 422)
dec_graph
dev.off()
write_xlsx(dec[["PT"]]$dec,"G:/6.APM/Financial Cycle/2. Data/dec_graph.xlsx")

# Median financial cycle
dec_df <- bind_rows(lapply(dec, function(sublist) {sublist$dec}), .id ="country")
country_selection <- c("SE", "IT", "FR", "DE", "BE", "NL", "FI", "GB", "PT", "NO", "DK", "ES")
dec_median <- dec_df %>% 
              filter(country %in% country_selection) %>% 
              filter(obstime >= as.Date("2001-12-31")) %>% 
              group_by(obstime) %>% 
              summarise(pca = median(pca), 
                        cred.hh.roc.2yoy = median(cred.hh.roc.2yoy),
                        cred.nfc.roc.2yoy = median(cred.nfc.roc.2yoy),
                        rhp.roc.2yoy = median(rhp.roc.2yoy),
                        sp.roc.2yoy = median(sp.roc.2yoy),
                        dsr.roc.2yoy = median(dsr.roc.2yoy),
                        cred.2gdp.roc.2yoy = median(cred.2gdp.roc.2yoy),
                        sprd.bond.diff.2y = median(sprd.bond.diff.2y))


dec_median_graph <- FC_decomposition(dec_median)

png("dec_graph.png", width = 868, height = 422)
dec_median_graph$graph
dev.off()

###############################################
# Crisis indicators
###############################################

# Lo Duca crisis

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
                    
# Prepare file for early warning analysis

df_ew <- lapply(df_dec, function(df) {df %>% mutate(crisis_systemic = 0, crisis_residual = 0)})
countries <- intersect(names(df_ew), unique(df_esrb_systemic$Country))
df_ew <- df_dec[countries]

df_ew <- lapply(names(df_ew), function(country) {
          df_ew[[country]] %>%
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
            crisis_total = crisis_systemic+ crisis_residual,
            crisis_total.5.12 = crisis_systemic.5.12+ crisis_residual.5.12,
            crisis_total.5.16 = crisis_systemic.5.16+ crisis_residual.5.16) %>%
            ungroup()
})
            
names(df_ew) <- countries

############################################
## In-sample EW analysis - Logit estimation
############################################

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

indicators <- c("pca", "qml", "tstep", "cred.nfc.roc.2yoy", "cred.hh.roc.2yoy", "rhp.roc.2yoy", "sp.roc.2yoy", "dsr.roc.2yoy", "cred.2gdp.roc.2yoy", "sprd.bond.diff.2y", "basel.gap")
crisis_def <- "crisis_systemic.5.12"

# Compute AUROC
df_auroc <- data.frame(matrix(NA, nrow = length(countries), ncol = length(indicators)))
colnames(df_auroc) <- indicators
rownames(df_auroc) <- countries

for(i in 1:length(countries)){
  df <- na.omit(as.data.frame(df_ew_bis[[i]]))
  for(j in 1:length(indicators)) {
    df_auroc[i,j] <- getauroc(df[df$crisis_systemic != 1, ],crisis_def,indicators[j]) 
  }
}

df_auroc <- rbind(df_auroc,colMeans(df_auroc))
row.names(df_auroc)[nrow(df_auroc)] <- "Avg"
df_auroc$country <- row.names(df_auroc)
write_xlsx(df_auroc, path = "G:/6.APM/Financial Cycle/2. Data/df_auroc.xlsx")

# Compute coords
df_coords <- data.frame(matrix(NA, nrow = length(countries), ncol = length(indicators)))
colnames(df_coords) <- indicators
rownames(df_coords) <- countries

theta <- 0.5
crisis_def <- "crisis_systemic.5.12"
for(i in 1:length(countries)){
  df <- na.omit(as.data.frame(df_ew_bis[[i]]))
  for(j in 1:length(indicators)) {
    df_coords[i,j] <- get_coords(df[df$crisis_systemic != 1, ],crisis_def,indicators[j], theta)$optimal_threshold$usefulness
  }
}

df_coords <- rbind(df_coords,colMeans(df_coords))
row.names(df_coords)[nrow(df_coords)] <- "Avg"
df_coords$country <- row.names(df_coords)
write_xlsx(df_coords, path = "G:/6.APM/Financial Cycle/2. Data/df_coords.xlsx")

# Optimal threshold graph
coord_graphs <- list()
graph_ind <- "pca"
for(i in 1:length(countries)){
  
  df <- na.omit(as.data.frame(df_ew_bis[[i]]))
    
  coord_results <- get_coords(df[df$crisis_systemic != 1, ], crisis_def, graph_ind, theta)
  coord <- coord_results$all_thresholds  # Access all thresholds data
  
  intersection <- coord %>%
    mutate(diff = abs(specificity - sensitivity)) %>%
    filter(diff == min(diff)) %>%
    slice(1) %>%
    pull(threshold)
  
  coord_long <- tidyr::pivot_longer(
    coord,
    cols = c(specificity, sensitivity),
    names_to = "Metric",
    values_to = "Value"
  )
  
  p <- ggplot(coord_long, aes(x = threshold, y = Value, color = Metric)) +
    geom_line(size = 1) +
    geom_vline(xintercept = intersection, linetype = "dashed", color = "red", size = 1) +
    scale_color_manual(values = c("specificity" = "blue", "sensitivity" = "orange")) +
    labs(
      title = paste("", countries[i]),
      x = "",
      y = "",
      color = "Metric"
    ) +
    annotate(
      "text", x = intersection, y = 0.5,
      label = paste("Threshold =", round(intersection, 2)),
      angle = 90, vjust = -1, color = "red"
    ) +
    theme_base()
  
  coord_graphs[[paste0(countries[i], "_", indicators[j])]] <- p

}