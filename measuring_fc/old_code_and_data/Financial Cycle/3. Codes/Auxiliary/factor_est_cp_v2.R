# Factor estimation as in DFM package
factor_est_cp <- function(x,r=1) {
  t <- nrow(x)
  x <- as.matrix(x)
  xx <- cov(x)
  eigen <- eigen(xx)
  lambda <- as.matrix(eigen$vectors[,1:1])
  f <- as.matrix(x %*% lambda)
  e <- x - f %*% t(lambda)
  ee <- diag(t(e)%*%e)
  ssr <- sum(diag(t(e)%*%e))
  return(list(factor=f,loadings=lambda,ssr=ssr,e=e,ee=ee))
}