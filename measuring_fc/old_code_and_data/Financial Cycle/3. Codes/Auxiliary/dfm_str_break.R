dfm_str_brk <- function(x,grid,r=1) {

  best.ssr <- Inf
  
  t <- nrow(x)
  
  grid_results <- as.data.frame(matrix(NA,nrow(grid),2)) # grid_results <- as.data.frame(matrix(NA,nrow(grid),4))
  grid_results[,1] <- as.Date(grid_results[,1])
  colnames(grid_results) <- c("break.date","ssr") # colnames(grid_results) <- c("break.date","ssr","lr","w")
  
  for(i in 1:nrow(grid)) {
    
    # Create pre and post break data
    x_1 <- x[x$obstime<=grid[i,1],colnames(x)!="obstime"]
    x_2 <- x[x$obstime>grid[i,1],colnames(x)!="obstime"]
    
    x_1 <- as.matrix(x_1)
    x_2 <- as.matrix(x_2)
    
    # Factor model PCA estimation with pre and post break data
    factor_est_1 <- factor_est_cp(x_1)
    factor_est_2 <- factor_est_cp(x_2)
    
    # Regime specific Loadings
    lambda_1 <- as.matrix(factor_est_1$loadings)
    lambda_2 <- as.matrix(factor_est_2$loadings)
    
    # Regime specific factors
    factor_1 <- factor_est_1$factor 
    factor_2 <- factor_est_2$factor
    factor <- rbind(as.matrix(factor_1),as.matrix(factor_2))
    
    # Regime specific SSR
    ssr_1 <- factor_est_1$ssr
    ssr_2 <- factor_est_2$ssr
    
    # Regime specific residuals
    e_1 <- as.matrix(factor_est_1$e)
    e_2 <- as.matrix(factor_est_2$e)
    
    # Objective function to estimate break date
    ssr <- ssr_1 + ssr_2
    
    # Collect results
    grid_results[i,1] <- as.Date(grid[i,1])
    grid_results[i,2] <- ssr

    if(ssr <= best.ssr) {
      best.ssr <- ssr
      best.factor_1 <- factor_1
      best.factor_2 <- factor_2
      best.factor <- factor
      best.loadings1 <- lambda_1
      best.loadings2 <- lambda_2
      best.e1 <- e_1
      best.e2 <- e_2
      best.break.date <- as.Date(grid[i,1])
    }
    
  }
  
  # Correct for the sign of the factors. Because the loadings and factors are not identifiable (since they enter the model manipulatively) we correct for the signs by following the result of the linear DFM
  factor_est <- factor_est_cp(x[,colnames(x)!="obstime"])
  factor_lin <- as.matrix(factor_est$factor)
  best.break.date.i <- which(x$obstime == best.break.date)
  factor_lin_1 <- factor_lin[1:best.break.date.i,]
  factor_lin_2 <- factor_lin[(best.break.date.i+1):nrow(factor_lin),]
  cor_1 <- cor(factor_lin_1,best.factor_1)
  cor_2 <- cor(factor_lin_2,best.factor_2)
  if(cor_1<0) {best.factor_1 <- best.factor_1*(-1)}
  if(cor_2<0) {best.factor_2 <- best.factor_2*(-1)}
  
  out <- list(ssr = best.ssr,
              break.date = best.break.date,
              break.date.i = best.break.date.i,
              factor_1 = best.factor_1,
              factor_2 = best.factor_2,
              factor = best.factor,
              loadings1 = best.loadings1,
              loadings2 = best.loadings2,
              e1 = best.e1,
              e2 = best.e2,
              grid_results = grid_results
              ) 
  
  return(out)
}