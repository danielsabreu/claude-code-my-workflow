library(dlm)
library(dplyr)

trend_filterHP <- function(x) {
        
        out_trend <- x[,1]
        out_gap <- x[,1]

        for (i in 2:ncol(x)) {
          
          df <- cbind(x[,1],x[,i])
          df <- df[complete.cases(df[,2]),]
        
          df <- df %>%
                mutate(obstime_year = year(!!sym(names(df)[1])),
                       obstime_month = month(!!sym(names(df)[1])))
          
          ini_year <- df$obstime_year[1]
          ini_month <- df$obstime_month[1]
          
          ts <- ts(df[,2],start = c(ini_year,ini_month),frequency = 4)
          ts_hp <- filterHP(ts,lambda = 400000)
          ts_date <- as.Date(as.yearmon(time(ts_hp)+3/12))-1 
          
          trend <- data.frame(ts_hp[,"trend"])
          trend$obstime <- ts_date
          names(trend) <- c("trend","obstime")
          out_trend <- left_join(out_trend,trend,by="obstime")
          
          gap <- data.frame(ts_hp[,"cycle"])
          gap$obstime <- ts_date
          names(gap) <- c("gap","obstime")
          out_gap <- left_join(out_gap,gap,by="obstime")
          
        }
        
        names(out_trend) <- paste(names(x),"trend",sep=".")
        names(out_gap) <- paste(names(x),"gap",sep=".")
        
        names(out_trend)[1] <- "obstime"
        names(out_gap)[1] <- "obstime"
        
        return(list(out_trend=out_trend,out_gap=out_gap))
        
}

