FC_decomposition <- function(df) {
  
  var_names <- c("cred.nfc.roc.2yoy","cred.hh.roc.2yoy","rhp.roc.2yoy","sp.roc.2yoy","dsr.roc.2yoy","cred.2gdp.roc.2yoy","sprd.bond.diff.2y")
  df_normalised <- normalise(df[,var_names])
  df_normalised <- cbind(df[,c("obstime","pca")],df_normalised)
  df_aux <- df_normalised[,var_names]
  df_f <- as.numeric(df[["pca"]])
  
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
  
  # Use absolute values for all variables except spreads, which retain their sign
  # (spread compression signals financial cycle expansion, not widening)
  weights <- abs(reg$coefficients)/sum(abs(reg$coefficients))
  weights["sprd.bond.diff.2y"] <- reg$coefficients["sprd.bond.diff.2y"]/sum(abs(reg$coefficients))

  df_aux2 <- matrix(NA,nrow = nrow(df_aux),ncol = ncol(df_aux))
  for (i in 1:ncol(df_aux2)) {df_aux2[,i] <- df_aux[,i]*weights[i]}

  # Scale contributions so that their sum matches the scale of pca
  A <- df_aux2
  B <- rowSums(A)
  scale_factor <- lm(df_f ~ B - 1)$coefficients[1]
  A_scaled <- A * scale_factor

  # reshape the data for ggplot
  df_aux3 <- cbind(df[,c("obstime","pca")],A_scaled)
  names(df_aux3) <- c("obstime","pca",var_names)
  df_graph <- reshape2::melt(df_aux3, id.vars = c("obstime"))
  
  label_map <- c(
    "cred.nfc.roc.2yoy" = "Credit NFC",
    "cred.hh.roc.2yoy"  = "Credit HH",
    "rhp.roc.2yoy"      = "House prices",
    "sp.roc.2yoy"       = "Share prices",
    "dsr.roc.2yoy"      = "DSR",
    "cred.2gdp.roc.2yoy"= "Credit-to-GDP",
    "sprd.bond.diff.2y" = "Bond spread",
    "pca"               = "PCA"
  )
  df_graph$variable <- factor(df_graph$variable,
                               levels = names(label_map),
                               labels = label_map)

  # plot
  gg_dec <- ggplot(df_graph, aes(x = obstime, y = value, fill = variable)) +
            geom_bar(data = df_graph[df_graph$variable != "PCA", ], stat = "identity") +
            geom_line(data = df_graph[df_graph$variable == "PCA", ], aes(x = obstime, y = value, color = variable), linewidth = 1.25) +
            geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
            labs(x = "", y = "", fill = "", color = "") +
            scale_fill_manual(values = c(
              "Credit NFC"    = rgb(0, 70, 122, maxColorValue = 255),
              "Credit HH"     = rgb(242, 200, 81, maxColorValue = 255),
              "House prices"  = rgb(237, 26, 59, maxColorValue = 255),
              "Share prices"  = rgb(50, 104, 49, maxColorValue = 255),
              "DSR"           = rgb(245, 130, 50, maxColorValue = 255),
              "Credit-to-GDP" = rgb(111, 111, 111, maxColorValue = 255),
              "Bond spread"   = rgb(160, 210, 45, maxColorValue = 255)
            )) +
            scale_color_manual(values = c("PCA" = "black"))
          
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