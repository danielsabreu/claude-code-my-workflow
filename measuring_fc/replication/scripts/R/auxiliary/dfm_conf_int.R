dfm_conf_int <- function(x,model_results,grid,trim=0.15,n_boot=250, p=0.85) {

  names <- colnames(x)
  
  df_boot <- matrix(NA,n_boot,3)
  df_boot[,1] <- 1:n_boot
  colnames(df_boot) <- c("n_boot","break.date.i","break.date.frac")
  
  df_w <- matrix(NA,n_boot,ncol(x))
  colnames(df_w) <- c("n_boot",names[-1])
  df_lr <- matrix(NA,n_boot,ncol(x))
  colnames(df_lr) <- c("n_boot",names[-1])
  df_lm <- matrix(NA,n_boot,ncol(x))
  colnames(df_lm) <- c("n_boot",names[-1])
  
  # Change point model
  f1 <- as.matrix(model_results$factor_1)
  f2 <- as.matrix(model_results$factor_2)
  lambda1 <- as.matrix(model_results$loadings1)
  lambda2 <- as.matrix(model_results$loadings2)
  x_fit1 <- f1 %*% lambda1
  x_fit2 <- f2 %*% lambda2
  x_fit <- rbind(x_fit1,x_fit2)
  e1 <- model_results$e1
  e2 <- model_results$e2
  e <- rbind(e1,e2)
  
  e_boot <- matrix(NA,nrow(e),ncol(e))
  e_lin_boot <- matrix(NA,nrow(e),ncol(e))
  
  # Linear factor model

  e_lin <- factor_est_cp(x[,colnames(x)!="obstime"])$e # vector of individual equation ssr
  x_lin_fit <- factor_est_cp(x[,colnames(x)!="obstime"])$factor %*% factor_est_cp(x[,colnames(x)!="obstime"])$loadings
  alpha_hat <- diag(lm(e~0+lag(e))$coefficients)
  dates <- as.matrix(model_results$grid_results[,1])
  
  # Block bootstrap objects
  n <- nrow(x)
  blocks <- list()
  block_size <- 4 #round(n^(1/3)) #use this for blocks with overlap
  
  # create blocks without overlap
  num_blocks <- ceiling(n / block_size)
  if (n %% block_size != 0) {
    num_blocks <- num_blocks - 1
  }

  for (i in 1:num_blocks) {
    start_index <- (i - 1) * block_size + 1
    end_index <- min(i * block_size, n)
    blocks[[i]] <- x[start_index:end_index,]
  }

  # Add the remaining observations to the last block
  if (n %% block_size != 0) {
    start_index <- num_blocks * block_size + 1
    end_index <- n
    if (length(blocks) > 0) {
      blocks[[num_blocks]] <- rbind(blocks[[num_blocks]], x[start_index:end_index,])
    } else {
      blocks[[1]] <- x[start_index:end_index,]
    }
  }
  
  # # create blocks with overlap
  # num_blocks <- n - block_size + 1
  # for (i in 1:num_blocks) {
  #   blocks[[i]] <- x[i:(i + block_size - 1),]
  # }
  
  num_blocks_to_draw <- ceiling(n/block_size)
  df_w_block <- matrix(NA,n_boot,ncol(x))
  colnames(df_w_block) <- c("n_boot",names[-1])
  df_lr_block <- matrix(NA,n_boot,ncol(x))
  colnames(df_lr_block) <- c("n_boot",names[-1])
  df_lm_block <- matrix(NA,n_boot,ncol(x))
  colnames(df_lm_block) <- c("n_boot",names[-1])
  
  
  for(i in 1:n_boot) {
    
    # Bootstrap confidence bands for the change point
    
    for(j in 1:ncol(e)) {
    
      e_boot[,j] <- sample(e[,j], size = nrow(e), replace = TRUE)
      
    }
    
    x_boot <- x_fit + e_boot
    x_boot <- as.data.frame(cbind(x[,1],x_boot))
    x_boot[,1] <- as.Date(x_boot[,1])
    colnames(x_boot)[1] <- c("obstime")
    cp_model <- dfm_str_brk(x_boot,dates)  
    df_boot[i,2] <- cp_model$break.date.i
    df_boot[i,3] <- cp_model$break.date.i/nrow(e)
    
    # # Bootstrap critical values of the structural break test (PAIRWISE NONPARAMETRIC)
    # 
    # bootstrap_i <- sample(1:n, size = n, replace = TRUE)
    # bootstrap_sample <- x[bootstrap_i,]
    # bootstrap_sample[,1] <- as.Date(bootstrap_sample[,1])
    # grid_boot <- create_grid(bootstrap_sample[,1],trim)
    # df_test <-  test_str_brk(bootstrap_sample,grid_boot)
    # df_w[i,] <- cbind(i,df_test$sup_w)
    # df_lr[i,] <- cbind(i,df_test$sup_lr)
    # df_lm[i,] <- cbind(i,df_test$sup_lm)
    
    # WILD BOOTSTRAP
    for(j in 1:ncol(e_lin)) {

      e_star <- e_lin[,j]*rnorm(nrow(e_lin),mean=0,sd=1) #sample(e_lin[,j], size = nrow(e_lin), replace = TRUE)
      e_star_lag <- lag(e_star,1)
      e_star_lag[1] <- e_star[1]
      e_lin_boot[,j] <- alpha_hat[j]*e_star_lag
      #e_lin_boot[,j] <- e_lin[,j]*rnorm(nrow(e_lin),mean=0,sd=1) # sample(e_lin[,j], size = nrow(e_lin), replace = TRUE)
    }

    x_boot_lin <- x_lin_fit + e_lin_boot
    x_boot_lin <- as.data.frame(cbind(x[,1],x_boot_lin))
    x_boot_lin[,1] <- as.Date(x_boot_lin[,1])
    colnames(x_boot_lin)[1] <- c("obstime")

    df_test <-  test_str_brk(x_boot_lin,grid)
    df_w[i,] <- cbind(i,df_test$sup_w)
    df_lr[i,] <- cbind(i,df_test$sup_lr)
    df_lm[i,] <- cbind(i,df_test$sup_lm)
    
    # Block Bootstrap critical values of the structural break test (NONPARAMETRIC)
    
    resampled_blocks <- sample(blocks, size = num_blocks_to_draw, replace = TRUE)
    bootstrap_sample <- do.call(rbind, resampled_blocks)
    bootstrap_sample <- bootstrap_sample[1:n, ]
    bootstrap_sample[,1] <- as.Date(bootstrap_sample[,1])
    grid_boot_block <- create_grid(bootstrap_sample[,1],trim)
    df_test <-  test_str_brk(bootstrap_sample,grid_boot_block)
    df_w_block[i,] <- cbind(i,df_test$sup_w)
    df_lr_block[i,] <- cbind(i,df_test$sup_lr)
    df_lm_block[i,] <- cbind(i,df_test$sup_lm)
    
  } 
  
  # Break date estimates confidence interval
  p10 <- round(quantile(df_boot[,2],1-p),digits=3)
  p90 <- round(quantile(df_boot[,2],p),digits=3)
  conf_int <- c(p10,p90)
  
  # Bootstrap critical values for the structural break test
  w_cv <- c(round(quantile(df_w[,-1],p),digits=3),round(quantile(df_w[,-1],p+(1-p)/2),digits=3))
  lr_cv <- c(round(quantile(df_lr[,-1],p),digits=3),round(quantile(df_lr[,-1],p+(1-p)/2),digits=3))
  lm_cv <- c(round(quantile(df_lm[,-1],p),digits=3),round(quantile(df_lm[,-1],p+(1-p)/2),digits=3))
  
  # Block Bootstrap critical values for the structural break test
  w_cv_block <- c(round(quantile(df_w_block[,-1],p),digits=3),round(quantile(df_w_block[,-1],p+(1-p)/2),digits=3))
  lr_cv_block <- c(round(quantile(df_lr_block[,-1],p),digits=3),round(quantile(df_lr_block[,-1],p+(1-p)/2),digits=3))
  lm_cv_block <- c(round(quantile(df_lm_block[,-1],p),digits=3),round(quantile(df_lm_block[,-1],p+(1-p)/2),digits=3))
  
  # Collect outputs of the function
  out <- list(df_boot=df_boot,
              df_w = df_w,
              df_lr=df_lr,
              df_lm=df_lm,
              df_w_block = df_w_block,
              df_lr_block=df_lr_block,
              df_lm_block=df_lm_block,
              conf_int=conf_int,
              w_cv = w_cv,
              lr_cv = lr_cv,
              lm_cv = lm_cv,
              w_cv_block = w_cv_block,
              lr_cv_block = lr_cv_block,
              lm_cv_block = lm_cv_block)
  
  return(out)
  
}