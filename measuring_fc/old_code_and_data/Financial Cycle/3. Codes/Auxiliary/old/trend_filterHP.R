library(dlm)

trend_filterHP <- function(df) {
        
        df <- df %>%
                mutate(obstime_year = year(!!sym(names(df)[1])),
                       obstime_month = month(!!sym(names(df)[1])))
        
        ini_year <- df$obstime_year[1]
        ini_month <- df$obstime_month[1]
        
        ts <- ts(df[,2],start = c(ini_year,ini_month),frequency = 4)
        ts_hp <- filterHP(ts,lambda = 400000)
        ts_date <- as.Date(as.yearmon(time(ts_hp)+3/12))-1 
        
        out <- data.frame(ts_hp[,"trend"])
        out$obstime <- ts_date
        names(out) <- c("trend","obstime")
        out
        
}