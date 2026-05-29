load("scripts/R/_outputs/df_ic_avar.RData")
load("scripts/R/_outputs/df_model.RData")
load("scripts/R/_outputs/df_oos.RData")

# Variance explained
cat("=== Variance explained ===\n")
for (cc in names(df_ic_avar)) {
  ve <- df_ic_avar[[cc]][["var_exp"]]
  if (!is.null(ve)) cat(cc, ":", round(ve * 100, 1), "%\n")
}

# Sample dates in estimation model
cat("\n=== df_model sample ===\n")
for (cc in names(df_model)) {
  d <- df_model[[cc]]
  cat(cc, ": n=", nrow(d), "from", format(min(d[[1]])), "to", format(max(d[[1]])), "\n")
}

# OOS: pca column is crisis probability (0-100 or 0-1?)
cat("\n=== OOS pca stats ===\n")
cat("range:", round(range(df_oos$pca, na.rm=TRUE), 3), "\n")
# If range includes values > 1, it's in percentage
if (max(df_oos$pca, na.rm=TRUE) > 1) {
  df_oos$pca_prob <- df_oos$pca / 100
} else {
  df_oos$pca_prob <- df_oos$pca
}
oos_smry <- aggregate(pca_prob ~ quarter, data=df_oos, FUN=median)
oos_smry <- oos_smry[order(oos_smry$quarter), ]
cat("OOS start (~2006Q1):", round(oos_smry$pca_prob[1]*100, 1), "%\n")
cat("OOS peak:", round(max(oos_smry$pca_prob)*100, 1), "% at",
    format(oos_smry$quarter[which.max(oos_smry$pca_prob)]), "\n")
cat("Full series:\n")
print(data.frame(quarter=oos_smry$quarter, prob_pct=round(oos_smry$pca_prob*100, 1)))
