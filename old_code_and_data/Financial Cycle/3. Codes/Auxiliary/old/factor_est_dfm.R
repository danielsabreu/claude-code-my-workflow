# Estimate factor and factor loadings function
factor.est <- function(x,r) {
  eigen <- eigen(cov(x))
  v <- eigen$vectors[,1:r]
  factors <- x %*% v
  ssr <- sum(diag(t(x - factors %*% t(v)) %*% (x - factors %*% t(v))))
  return(list(factors=factors,
              loadings=v,
              ssr=ssr))
}