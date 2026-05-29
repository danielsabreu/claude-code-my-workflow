library(ggthemes)

FC_decomposition <- function(df) {
  
  var_names <- c("cred.nfc.roc.2yoy","cred.hh.roc.2yoy","rhp.roc.2yoy","sp.roc.2yoy","dsr.roc.2yoy","cred.2gdp.roc.2yoy","sprd.bond.diff.2y")
  df_normalised <- normalise(df[,var_names])
  df_normalised <- cbind(df[,c("obstime","pca")],df_normalised)
  df_aux <- df_normalised[,var_names]
  df_f <- df[,"pca"]
  
  reg <- lm(pca ~ 0 + #without intercept
                  cred.nfc.roc.2yoy +
                  cred.hh.roc.2yoy +
                  rhp.roc.2yoy +
                  sp.roc.2yoy +
                  dsr.roc.2yoy +
                  cred.2gdp.roc.2yoy +
                  sprd.bond.diff.2y,
            data = df_normalised
            )
  
  weights <- abs(reg$coefficients)/sum(abs(reg$coefficients))
  
  df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux)) 
  for (i in 1:ncol(df_aux2)) {df_aux2[,i] <- df_aux[,i]*weights[i]}
  
  # Normalise scale of contributions fit the graph with the decomposition graphs
  
  A <- df_aux2
  B <- rowSums(A) # df_f 
  
  A_scaled <- matrix(NA,nrow(df_aux2),ncol=ncol(df_aux2))
  for (i in 1:ncol(df_aux2)) {
    
    A_scaled[,i] <- (A[,i] - mean(A[,i])) / sd(A[,i]) * sd(B) + mean(B)    
  
    } 
  
  # reshape the data for ggplot
  df_aux3 <- cbind(df[,c("obstime","pca")],A_scaled)
  names(df_aux3) <- c("obstime","pca",var_names)
  df_graph <- reshape2::melt(df_aux3, id.vars = c("obstime"))
  
  # plot
  gg_dec <- ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
            geom_bar(data = df_graph[df_graph$variable != "pca", ], stat = "identity") +
            geom_line(data = df_graph[df_graph$variable == "pca", ], aes(x = obstime, y = value, color = variable), linewidth = 1.25) +
            geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +  # Horizontal line at y = 0
            labs(#title = "Financial cylce decomposition",
              x = "",
              y = "",
              fill = "Variables",
              color = "Variables") +
            scale_fill_manual(values = c("cred.nfc.roc.2yoy" = rgb(0, 70, 122, maxColorValue = 255),
                                         "cred.hh.roc.2yoy" = rgb(242, 200, 81, maxColorValue = 255),
                                         "rhp.roc.2yoy" = rgb(237, 26, 59, maxColorValue = 255),
                                         "sp.roc.2yoy" = rgb(50, 104, 49, maxColorValue = 255),
                                         "dsr.roc.2yoy" = rgb(245, 130, 50, maxColorValue = 255),
                                         "cred.2gdp.roc.2yoy" = rgb(111, 111, 111, maxColorValue = 255),
                                         "sprd.bond.diff.2y" = rgb(160, 210, 45, maxColorValue = 255)
            )) +
            scale_color_manual(values = c("pca" = "black")) +
            theme_base() +
            theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_blank(),legend.title = element_blank())
          
out <- list(reg=reg, dec = df_aux3, graph = gg_dec)  
  
}

# # Quadratic programming - Linear regression subject to constraints (each coef must be >0 and sum of coef sould = 1)
# library("quadprog")
# y <- as.matrix(df[,"pca"])
# x <- as.matrix(df_aux)
# Rinv <- solve(chol(t(x) %*% x))
# C <- cbind(rep(1,ncol(x)), diag(ncol(x)))
# b <- c(1,rep(0,ncol(x)))
# d <- t(y) %*% x  
# qp <- solve.QP(Dmat = Rinv, factorized = TRUE, dvec = d, Amat = C, bvec = b, meq = 1)
# qp$solution