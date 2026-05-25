# avar.R — Asymptotic confidence intervals for the PCA factor
#
# Implements Zhang (ch. 3, eq. 3.2.3 and 3.2.5) / Bai (2003):
#
#   sqrt(N) * (f_hat_t - H' * f_t^0)  ->  N(0, V^{-1} Q Gamma_t Q' V^{-1})
#
# where:
#   f_hat_t   : r x 1 vector of PCA factor estimates at time t
#   f_t^0     : r x 1 vector of true (population) common factors at time t
#   H         : r x r rotation matrix (rotational indeterminacy of PCA)
#   V_NT      : r x r diagonal matrix of r largest eigenvalues of (NT)^{-1} XX'
#   V         : plim of V_NT
#   Q         : plim_{T->inf} F_hat' F^0 / T  (r x r)
#   Gamma_t   : lim_{N->inf} N^{-1} sum_i sum_j lambda_i^0 lambda_j^0'
#               E(e_it e_jt)  (r x r cross-sectional covariance at time t)
#
# Consistent estimator of the asymptotic variance (Zhang eq. 3.2.5):
#   Avar_hat(f_hat_t) = V_NT^{-1} * Gamma_hat_t * V_NT^{-1}
#
# Gamma_hat_t uses estimator (c) from Bai (2003) / Zhang (ch. 3, eq. 3.2.5):
#   Gamma_hat_t = Gamma_hat  (time-invariant for estimator c)
#
#   Gamma_hat = (1/n) * sum_{i=1}^{n} sum_{j=1}^{n}
#               lambda_hat_i * lambda_hat_j' * (1/T) * sum_{s=1}^{T} e_hat_is * e_hat_js
#
#   n = min(floor(sqrt(N)), floor(sqrt(T))) — cross-sectional truncation parameter.
#   lambda_hat_i : r x 1 vector of PCA loadings for variable i
#   e_hat_it     : x_it - lambda_hat_i' * f_hat_t  (estimated idiosyncratic component)
#
# Truncation to n << N is essential: summing over all N cross-sections
# would collapse Gamma_hat to zero by the PCA first-order conditions
# (sum_i lambda_hat_i * e_hat_it = 0 for every t). Using only the first n
# variables avoids this degeneracy and allows for limited cross-sectional
# dependence in the idiosyncratic errors.
#
# Because estimator (c) averages e_hat_is * e_hat_js over all T periods,
# Gamma_hat does not depend on t; the resulting confidence bands have constant width.
#
# For r = 1, all quantities are scalars:
#   Gamma_hat = (1/n) * (lambda_hat_{1:n}' * E_{1:n}' * E_{1:n} * lambda_hat_{1:n}) / T
#   Avar_hat  = Gamma_hat / V_NT^2
#
# Implementation note (normalisation):
#   The factor f_hat_t = v_hat' * x_t  uses a unit-norm eigenvector v_hat.
#   This equals sqrt(N) * f_hat_t^{PC2}, where f_hat_t^{PC2} = N^{-1} Lambda_hat' x_t
#   is Bai's PC2 factor.  The CLT (eq. 3.2.3) is for f_hat_t^{PC2}, whose SE is
#   sqrt(Avar / N). Since f_hat_t = sqrt(N) * f_hat_t^{PC2}, SE(f_hat_t) = sqrt(Avar).
#   Therefore the CI half-width is z_{alpha/2} * sqrt(Avar) (no extra 1/sqrt(N)).
#
# Output columns
# --------------
# factor          : PCA factor estimate (unit-norm loading convention)
# factor.p90      : +ci_half  — constant upper neutral-zone boundary
# factor.p10      : -ci_half  — constant lower neutral-zone boundary
# factor.p90.mean : +ci_half  — constant upper regime threshold (same as p90)
# factor.p10.mean : -ci_half  — constant lower regime threshold (same as p10)
#
# Bands are centred at ZERO, not at the factor estimate.
# Interpretation: |factor| > ci_half  <=>  reject H0: f_t^0 = 0 at level alpha.

avar <- function(x, conf = 0.05) {

  obstime <- x[, 1]
  x       <- as.matrix(normalise(x[, 2:ncol(x)]))
  T_obs   <- nrow(x)   # number of time periods (T)
  N       <- ncol(x)   # number of cross-sectional units (N)

  # ---- PCA -------------------------------------------------------
  # Eigendecomposition of (NT)^{-1} X'X — exact formula per Zhang eq. 3.2.5 / Bai (2003).
  # X'X and XX' share the same nonzero eigenvalues; the N x N form is cheaper when N < T.
  XtX_NT   <- crossprod(x) / (N * T_obs)                # (NT)^{-1} X'X, N x N
  eig      <- base::eigen(XtX_NT, symmetric = TRUE)
  loadings <- as.matrix(eig$vectors[, 1, drop = FALSE])  # N x 1 unit-norm PC loading (lambda_hat)
  f_hat    <- as.matrix(x %*% loadings)                  # T x 1 factor estimates (F_hat_t)

  # ---- V_NT: largest eigenvalue of (NT)^{-1} X'X ----------------
  # Directly from the eigendecomposition above — no T/(T-1) correction needed.
  V_NT <- eig$values[1]

  # ---- Residuals: e_hat_it = x_it - lambda_hat_i' F_hat_t  (Zhang eq. 3.2.5) ----
  e <- x - f_hat %*% t(loadings)    # T x N

  # ---- Gamma_hat (estimator c): CS-HAC with truncation n << N ---
  # n = min(floor(sqrt(N)), floor(sqrt(T_obs))) per Bai (2003)
  n_cs <- min(floor(sqrt(N)), floor(sqrt(T_obs)))
  n_cs <- max(n_cs, 1L)   # safeguard: at least 1

  e_tr   <- e[, 1L:n_cs, drop = FALSE]           # T x n_cs: first n_cs residuals
  lam_tr <- as.numeric(loadings[1L:n_cs])        # n_cs-vector: lambda_hat_{1:n}

  # (1/T) * sum_s e_is e_js  ->  n_cs x n_cs cross-product matrix
  EE_avg <- crossprod(e_tr) / T_obs             # n_cs x n_cs

  # Gamma_hat = (1/n) * lam_tr' EE_avg lam_tr   (scalar for r=1)
  gamma_c <- as.numeric(t(lam_tr) %*% EE_avg %*% lam_tr) / n_cs

  # ---- Asymptotic variance: Avar_hat = V_NT^{-2} * Gamma_hat ----
  # (scalar form for r = 1; generalises to V_NT^{-1} Gamma V_NT^{-1})
  avar_scalar <- gamma_c / V_NT^2

  # ---- CI half-width (constant across time) ----------------------
  # F_hat_t = lambda_hat' x_t  (unit-norm) = sqrt(N) * F_hat_t^{PC2}.
  # CLT (Zhang eq. 3.2.3) is for F_hat_t^{PC2}; SE(PC2) = sqrt(Avar / N).
  # SE(F_hat_t) = sqrt(N) * SE(PC2) = sqrt(Avar).  No extra 1/sqrt(N).
  z_alpha  <- qnorm(1 - conf / 2)
  ci_half  <- z_alpha * sqrt(avar_scalar)       # scalar: constant over t

  # ---- Output ----------------------------------------------------
  # Bands centred at 0; constant width because estimator (c) is time-invariant.
  out <- data.frame(
    obstime         = as.Date(obstime),
    factor          = as.numeric(f_hat),
    factor.p90      =  ci_half,
    factor.p10      = -ci_half,
    factor.p90.mean =  ci_half,
    factor.p10.mean = -ci_half
  )
  return(out)
}
