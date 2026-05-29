# Function to compute asymptotic covariance matrix of the factors
avar <- function(x,conf=0.20) {
  
  obstime <- x[,1]
  x <- as.matrix(normalise(x[,2:ncol(x)]))
  t <- nrow(x)
  n <- ncol(x)
  alpha <- qnorm(1-conf/2)
  gamma <- matrix(NA, nrow=t,ncol=1) 
  out <- as.data.frame(matrix(NA,t,3))
  colnames(out) <- c("factor","factor.p10","factor.p90")
  
  # Estimate factor, loadings and residuals
  eigen <- eigen(cov(x), symmetric = TRUE) ## cov(x) = (t(x) %*% x)/(nrow(x)-1)
  loadings <- as.matrix(eigen$vectors[,1:1])
  factor <- as.matrix(x %*% loadings)
  out[,"factor"] <- factor
  e <- x - factor %*% t(loadings)
  v <- eigen(cov(loadings)^(1/2) %*% cov(factor) %*% cov(loadings)^(1/2))$values[1:1]
  
  for (i in 1:t) {
    
    gamma[i] <- solve(v)%*%(crossprod(e[i,])/n * t(loadings) %*% loadings)*solve(v) 
    out[i,"factor.p90"] <- alpha*gamma[i]^(1/2)*n^(-1/2)
    out[i,"factor.p10"] <- -alpha*gamma[i]^(1/2)*n^(-1/2)
    
  }
  
  out$factor.p90.mean <- mean(out[,"factor.p90"])
  out$factor.p10.mean <- mean(out[,"factor.p10"])
  
  out <- cbind(obstime,out)
  out[,1] <- as.Date(out[,1])
  colnames(out)[1] <- "obstime"
  return(out)
}