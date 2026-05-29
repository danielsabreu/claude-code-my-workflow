test_str_brk <- function(x,grid,r=1) {

  t <- nrow(x)

  sup_lr <- matrix(-Inf,1,ncol(x)-1)
  sup_w <- matrix(-Inf,1,ncol(x)-1)
  sup_lm <- matrix(-Inf,1,ncol(x)-1)
  
  w_results <- as.data.frame(matrix(NA,nrow(grid),ncol(x)))
  w_results[,1] <- as.Date(as.matrix(grid[,1]))
  colnames(w_results) <- colnames(x)
  colnames(sup_w) <- colnames(x)[-1]
  
  lr_results <- as.data.frame(matrix(NA,nrow(grid),ncol(x)))
  lr_results[,1] <- as.Date(as.matrix(grid[,1]))
  colnames(lr_results) <- colnames(x)
  colnames(sup_lr) <- colnames(x)[-1]
  
  lm_results <- as.data.frame(matrix(NA,nrow(grid),ncol(x)))
  lm_results[,1] <- as.Date(as.matrix(grid[,1]))
  colnames(lm_results) <- colnames(x)
  colnames(sup_lm) <- colnames(x)[-1]
  
  ee_lin <- factor_est_cp(x[,colnames(x)!="obstime"])$ee # vector of individual equation ssr
  e_lin <- factor_est_cp(x[,colnames(x)!="obstime"])$e # residuals
  f_lin <- factor_est_cp(x[,colnames(x)!="obstime"])$factor


  for(i in 1:nrow(grid)) {
    
    # Create pre and post break data
    x_1 <- x[1:grid[i,2],colnames(x)!="obstime"]
    x_2 <- x[(grid[i,2]+1):nrow(x),colnames(x)!="obstime"]
    
    x_1 <- as.matrix(x_1)
    x_2 <- as.matrix(x_2)
    
    # LM and Wald statistic
    f_lin_1 <- as.matrix(f_lin[1:nrow(x_1)])
    f_lin_2 <- as.matrix(f_lin[(nrow(x_1)+1):nrow(x)])
    
    f_aux <- matrix(0,nrow(x),1)
    f_aux[(nrow(x_1)+1):nrow(x),1] <- f_lin_2

    for(j in 1:ncol(x_1)) {
      
      # LR 
      reg_1 <- lm(x_1[,j] ~ f_lin_1)
      reg_2 <- lm(x_2[,j] ~ f_lin_2)
      ssr_lin_1 <- sum(reg_1$residuals^2)
      ssr_lin_2 <- sum(reg_2$residuals^2)
      ssr_lin <- ee_lin[j]
      lr <- t*(log(ssr_lin)-log(ssr_lin_1+ssr_lin_2))
      lr_results[i,j+1] <- lr
      
      # Wald
      reg_w <- lm(x[,j+1]~f_lin+f_aux)
      t_ratio <- summary(reg_w)$coefficients[3,"t value"] #(ssr_lin - (ssr_lin_1+ssr_lin_2))/((ssr_lin_1+ssr_lin_2)/(t-2*r))
      w <- t_ratio^2
      w_results[i,j+1] <- w
      
      # LM 
      reg_lm <- lm(e_lin[,j]~ f_lin+f_aux)
      lm <- t*summary(reg_lm)$r.squared
      lm_results[i,j+1] <- lm
      
      # Store test statistics 
      if(lr >= sup_lr[j]) {sup_lr[j] <- lr}
      if(w >= sup_w[j]) {sup_w[j] <- w}
      if(lm >= sup_lm[j]) {sup_lm[j] <- lm}
      
      sup_stat <- rbind(sup_lr,sup_w,sup_lm)
      sup_stat <- cbind(c("sup.lr","sup.w","sup.lm"),sup_stat)
      colnames(sup_stat)[1] <- "test.stat"
      
    }

  }
  
  out <- list(w_results = w_results,
              lr_results = lr_results,
              lm_results = lm_results,
              sup_stat = sup_stat,
              sup_lr = sup_lr,
              sup_w = sup_w,
              sup_lm =sup_lm
              ) 
  
  return(out)
  
}