getfilter <- function(x,filter,...) {
  
  start.date <- x[[1,1]]
  start.y <- year(start.date)
  start.m <- substr(start.date,6,7)
  start.q <- if(start.m %in% c("01","02","03")) "01" else if(start.m %in% c("04","05","06")) "02" else if(start.m %in% c("07","08","09")) "03" else "04" 
  
  end.date <- x[[nrow(x),1]]
  end.y <- substr(end.date,1,4)
  end.m <- substr(end.date,6,7)
  end.q <- if(end.m %in% c("01","02","03")) "01" else if(end.m %in% c("04","05","06")) "02" else if(end.m %in% c("07","08","09")) "03" else "04" 
  
  x.ts <- ts(x[,2:ncol(x)],start = c(start.y,start.q), end = c(end.y,end.q),frequency = 4)
  out_cycle <- matrix(NA,nrow(x),ncol(x))
  out_trend <- matrix(NA,nrow(x),ncol(x))
  
  for(i in 1:ncol(x.ts)) {

    y <- x.ts[,i]
    # Linearly interpolate internal NAs (publication-lag gaps) before filtering.
    # na.omit on a ts object only strips leading/trailing NAs and errors on internal ones.
    if (any(is.na(y))) {
      y <- zoo::na.approx(y, na.rm = FALSE)  # fill internal NAs
      y <- stats::na.omit(y)                  # strip any remaining leading/trailing
    }
    y.filter <- mFilter(y,filter,...)
    y.cycle <- as.matrix(y.filter$cycle)
    y.trend <- as.matrix(y.filter$trend) 
    
    if(nrow(x) != length(y)) {
      
      y.cycle <- rbind(as.matrix(rep(NA,nrow(x)-length(y))),y.cycle)
      y.trend <- rbind(as.matrix(rep(NA,nrow(x)-length(y))),y.trend)
    }
    
    out_cycle[,i+1] <- y.cycle
    out_trend[,i+1] <- y.trend
  }
  
  out_cycle <- as.data.frame(out_cycle)
  out_cycle[,1] <- as.matrix(x[,1])
  out_cycle[,1] <- as.Date(out_cycle[,1])
  colnames(out_cycle) <- colnames(x)
  
  out_trend <- as.data.frame(out_trend)
  out_trend[,1] <- as.matrix(x[,1])
  out_trend[,1] <- as.Date(out_trend[,1])
  colnames(out_trend) <- colnames(x)
  
  out = list(cycle=out_cycle,trend=out_trend,x.ts=x.ts)
  return(out)
}