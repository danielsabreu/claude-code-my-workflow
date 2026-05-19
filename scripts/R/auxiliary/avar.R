# avar.R — Asymptotic confidence intervals for the PCA factor
#
# Implements the asymptotic result of Bai (2003, Theorem 3):
#   sqrt(N) * (F_hat_t - H * F_t^0)  ->  N(0, Avar(F_hat_t))
#   Avar(F_hat_t) = V_NT^{-2} * Gamma_t
#
# Gamma_t uses estimator (a) from Bai (2003) / Zhang (ch.3, eq. 3.2.5):
#   Gamma_hat_t = (1/N) * sum_i  e_hat_it^2 * lambda_hat_i^2
#
# This estimator is consistent when idiosyncratic errors are cross-
# sectionally uncorrelated but may be heteroskedastic across i and t.
# Estimator (c) (CS-HAC) is algebraically degenerate for PCA: by the
# first-order conditions of PCA, lambda' * (E'E/T) * lambda = 0 exactly,
# so the CS-HAC sum collapses to zero regardless of the data.
#
# Output columns
# --------------
# factor          : PCA factor estimate (unit-norm loading convention)
# factor.p90      : +ci_half(t)  — upper half of the time-varying neutral zone
# factor.p10      : -ci_half(t)  — lower half of the time-varying neutral zone
# factor.p90.mean : +mean(ci_half) — constant upper regime threshold (dashed line)
# factor.p10.mean : -mean(ci_half) — constant lower regime threshold (dashed line)
#
# Bands are centred at ZERO, not at the factor estimate.
# Interpretation: when |factor| > threshold → statistically significant deviation.
# This matches the old code's visual convention and the regime classification logic.

avar <- function(x, conf = 0.05) {

  obstime <- x[, 1]
  x       <- as.matrix(normalise(x[, 2:ncol(x)]))
  T_obs   <- nrow(x)   # number of time periods
  N       <- ncol(x)   # number of cross-sectional units (variables)

  # ---- PCA -------------------------------------------------------
  eig      <- base::eigen(cov(x), symmetric = TRUE)
  loadings <- as.matrix(eig$vectors[, 1, drop = FALSE])  # N x 1, unit norm
  f_hat    <- as.matrix(x %*% loadings)                  # T x 1

  # ---- V_NT: Bai (2003) uses first eigenvalue of (NT)^{-1}XX' ---
  # = first eigenvalue of X'X/(NT) = lambda_1(cov(X)) / N
  lambda1 <- eig$values[1]   # first eigenvalue of cov(X) = X'X/(T-1)
  V_NT    <- lambda1 / N     # Bai (2003) V_NT

  # ---- Residuals: e_hat_it = X_it - lambda_hat_i * F_hat_t ------
  e <- x - f_hat %*% t(loadings)    # T x N

  # ---- Gamma_hat_t (estimator a): time-varying ------------------
  # Gamma_hat_t = (1/N) * sum_i  e_it^2 * lambda_i^2
  lam2    <- as.numeric(loadings)^2          # N-vector of squared loadings
  gamma_t <- apply(e, 1, function(et) sum(et^2 * lam2)) / N   # length T

  # ---- Asymptotic variance: Avar_hat_t = V_NT^{-2} * Gamma_hat_t
  avar_t  <- gamma_t / V_NT^2    # = gamma_t * N^2 / lambda1^2

  # ---- CI half-width (time-varying) ------------------------------
  # My factor F_hat = lambda' x is sqrt(N) * Bai's PC2 factor.
  # Therefore SE(F_hat) = sqrt(N) * SE_PC2 = sqrt(Avar_hat_t)
  # (do NOT divide by N — that would apply the PC2 CLT to the wrong scale).
  z_alpha <- qnorm(1 - conf / 2)
  ci_half <- z_alpha * sqrt(avar_t)         # length T

  # ---- Output ----------------------------------------------------
  # Bands are centred at 0 (neutral-zone convention, matching old code):
  #   factor.p90 / factor.p10 : time-varying ±ci_half(t)
  #   factor.p90.mean / .p10.mean : constant ±mean(ci_half) — regime thresholds
  out <- data.frame(
    obstime         = as.Date(obstime),
    factor          = as.numeric(f_hat),
    factor.p90      =  ci_half,           # upper neutral-zone boundary (time-varying)
    factor.p10      = -ci_half,           # lower neutral-zone boundary (time-varying)
    factor.p90.mean =  mean(ci_half),     # constant upper regime threshold
    factor.p10.mean = -mean(ci_half)      # constant lower regime threshold
  )
  return(out)
}
