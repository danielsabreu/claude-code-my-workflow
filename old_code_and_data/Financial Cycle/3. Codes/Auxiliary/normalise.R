# Normalize data function
normalise <- function(x) {
  x <- as.matrix(x)
  Mx <- colMeans(x,na.rm=TRUE)
  Wx <- apply(x, MARGIN = 2, FUN = sd,na.rm=TRUE)
  for(i in 1:ncol(x)){x[,i] <- (x[,i] - Mx[i])/Wx[i]}
  x <- as.data.frame(x)
  return(x) 
}