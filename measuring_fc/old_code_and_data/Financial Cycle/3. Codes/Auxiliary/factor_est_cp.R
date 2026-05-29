factor_est_cp <- function(x,r=1) {
  t <- nrow(x)
  x <- as.matrix(x)
  xx <- x %*% t(x)
  eigen <- eigen(xx)
  f <- sqrt(t)*eigen$vectors[,1:r]
  lambda <- (t(f) %*% x)/t
  e <- x - f %*% lambda
  ee <- diag(t(e)%*%e)
  ssr <- sum(diag(t(e)%*%e))
  return(list(factor=f,loadings=lambda,ssr=ssr,e=e,ee=ee))
}