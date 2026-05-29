# =============================================================================
# 00_run_all.R — Replication orchestrator
# Financial Cycle: A Dynamic Factor Model Approach
# Abreu & De Lorenzo Buratta
#
# Run this script from within the replication/ folder (set working directory
# to replication/ before sourcing, or open the .here file in RStudio).
#
# Pipeline:
#   01_data_processing.R  — transformations, filtering, standardisation
#   02_factor_estimation.R — DFM estimation (PCA, QML, two-step), figures, tables
#   03_dec_ew_gar.R       — decomposition, early-warning, AUROC
#   04_oos.R              — out-of-sample exercise (2006 Q1 – 2009 Q1)
#   05_panel_figures.R    — appendix country panels (A, B, C)
#
# Reproducibility contract:
#   - Fixed seed set below; do not change without a recorded reason.
#   - All paths resolved via here::here() — never setwd().
#   - sessionInfo() written to scripts/R/_outputs/sessionInfo.txt.
# =============================================================================

suppressPackageStartupMessages({
  if (!requireNamespace("here", quietly = TRUE)) {
    stop("Install 'here' first: install.packages('here')")
  }
  library(here)
})

# Seed: set once here, propagated to all downstream scripts.
PROJECT_SEED <- 20260413L
set.seed(PROJECT_SEED)

# Output directory
OUT_DIR <- here("scripts", "R", "_outputs")
dir.create(OUT_DIR,            showWarnings = FALSE, recursive = TRUE)
dir.create(here("Figures"),    showWarnings = FALSE, recursive = TRUE)

# Pipeline
pipeline <- c(
  "01_data_processing.R",
  "02_factor_estimation.R",
  "03_dec_ew_gar.R",
  "04_oos.R",
  "05_panel_figures.R"
)

message("Running replication pipeline (seed = ", PROJECT_SEED, ") ...")

timings <- vapply(pipeline, function(script) {
  path <- here("scripts", "R", script)
  if (!file.exists(path)) stop("Missing script: ", path)
  start <- Sys.time()
  source(path, local = FALSE)
  elapsed <- as.numeric(Sys.time() - start, units = "secs")
  message(sprintf("  %s  %.1fs", script, elapsed))
  elapsed
}, numeric(1))

# Capture session info for reviewers
writeLines(capture.output(sessionInfo()),
           con = file.path(OUT_DIR, "sessionInfo.txt"))

message("")
message("Pipeline complete. Total: ", sprintf("%.1fs", sum(timings)))
message("Outputs written to:")
message("  scripts/R/_outputs/   — intermediates (.RData, .xlsx)")
message("  Figures/              — figures (.pdf)")

invisible(list(timings = timings, seed = PROJECT_SEED))
