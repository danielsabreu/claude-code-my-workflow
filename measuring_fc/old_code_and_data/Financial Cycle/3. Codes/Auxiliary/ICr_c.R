ICr_c <- function (X, max.r = min(20, ncol(X) - 1)) 
{
  X <- as.matrix(normalise(X))
  n <- ncol(X)
  TT <- nrow(X)
  eigen_decomp <- eigen(cov(X), symmetric = TRUE)
  evs <- eigen_decomp$vectors
  F_pca <- X %*% evs
  Tn <- TT * n
  npTdTn <- (n + TT)/Tn
  minnT <- min(n, TT)
  c1 <- npTdTn * log(1/npTdTn)
  c2 <- npTdTn * log(minnT)
  c3 <- log(minnT)/minnT
  cvec <- c(c1, c2, c3)
  result <- matrix(0, max.r, 3)
  result_logV <- matrix(0, max.r, 3)
  result_cvec <- matrix(0, max.r, 3)
  for (r in 1:max.r) {
    res <- X - tcrossprod(F_pca[, 1:r], evs[, 1:r])
    logV <- log(sum(colSums(res^2)/Tn))
    result_logV[r,] <- logV
    result_cvec[r,] <- r * cvec
    result[r,] <- logV + r * cvec
  }
  dimnames(result) <- list(r = 1:max.r, IC = paste0("IC",1:3))
  dimnames(result_logV) <- list(r = 1:max.r, IC = paste0("IC",1:3))
  dimnames(result_cvec) <- list(r = 1:max.r, IC = paste0("IC",1:3))
  class(result) <- "table"
  colnames(F_pca) <- paste0("PC", 1:n)
  res_obj <- list(F_pca = F_pca, eigenvalues = eigen_decomp$values, 
                  IC = result, r.star = apply(result, 2, which.min),logV = result_logV, cvec = result_cvec)
  class(res_obj) <- "ICr"
  return(res_obj)
}