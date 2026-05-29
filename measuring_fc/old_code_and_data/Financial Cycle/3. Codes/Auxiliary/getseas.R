getseas <- function(x,trans) {
  
  start.date <- x[[1,1]]
  start.y <- year(start.date)
  start.m <- substr(start.date,6,7)
  start.q <- if(start.m %in% c("01","02","03")) "01" else if(start.m %in% c("04","05","06")) "02" else if(start.m %in% c("07","08","09")) "03" else "04" 
  
  end.date <- x[[nrow(x),1]]
  end.y <- substr(end.date,1,4)
  end.m <- substr(end.date,6,7)
  end.q <- if(end.m %in% c("01","02","03")) "01" else if(end.m %in% c("04","05","06")) "02" else if(end.m %in% c("07","08","09")) "03" else "04" 
  
  x.ts <- ts(x[,2:ncol(x)],start = c(start.y,start.q), end = c(end.y,end.q),frequency = 4)
  out <- matrix(NA,nrow(x),ncol(x))

  if(trans == F) {
    
    for(i in 1:ncol(x.ts)) {
      
      y <- x.ts[,i]
      y.seas <- as.matrix(y)
      if(nrow(y.seas)!=nrow(x)) {
        out[,i+1] <- rbind(as.matrix(rep(NA,nrow(x)-nrow(y.seas))),y.seas)
      } else {
        out[,i+1] <- as.matrix(y.seas)  
      }
    }
    
  } else {
    
    for(i in 1:ncol(x.ts)) {
      
      y <- x.ts[,i]
      y.seas <- seas(y, regression.aictest = NULL)
      y.seas <- as.matrix(y.seas[["data"]][1:nrow(y.seas[["data"]]),3])
      if(nrow(y.seas)!=nrow(x)) {
        out[,i+1] <- rbind(as.matrix(rep(NA,nrow(x)-nrow(y.seas))),y.seas)
      } else {
        out[,i+1] <- as.matrix(y.seas)  
      }
    }
    
  }
  
  out <- as.data.frame(out)
  out[,1] <- as.matrix(x[,1])
  colnames(out) <- colnames(x)
  return(out)
}