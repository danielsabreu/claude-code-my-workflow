# Estimate factor and factor loadings function
factor_est_cp <- function(x,r) {
  t <- nrow(x)
  x <- as.matrix(x)
  xx <- x %*% t(x)
  eigen <- eigen(xx)
  f <- sqrt(t)*eigen$vectors[,1:r]
  lambda <- (t(f) %*% x)/t
  ssr <- sum(diag(t(x - f %*% lambda) %*% (x - f %*% lambda)))
  return(list(factor=f,loadings=lambda,ssr=ssr))
}
# 
# # Estimate factor and factor loadings function
# factor.est <- function(x,r) {
#   eigen <- eigen(cov(x))
#   v <- eigen$vectors[,1:r]
#   factors <- x %*% v
#   ssr <- sum(diag(t(x - factors %*% t(v)) %*% (x - factors %*% t(v)))/(nrow(x)*ncol(x)))
#   return(list(factors=factors,
#               loadings=v,
#               ssr=ssr))
# }