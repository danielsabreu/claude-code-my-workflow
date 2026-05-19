###############################################################
# _paths.R — Project-wide path constants
# Source this at the top of every replication script.
# All paths are relative to the repository root via here::here().
###############################################################

if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
library(here)

RAW_DIR       <- here::here("data", "raw")
PROCESSED_DIR <- here::here("data", "processed")
OUTPUTS_DIR   <- here::here("scripts", "R", "_outputs")
FIGURES_DIR   <- here::here("Figures")
AUX_DIR       <- here::here("scripts", "R", "auxiliary")

# Create output directories if they don't exist
dir.create(OUTPUTS_DIR,   showWarnings = FALSE, recursive = TRUE)
dir.create(PROCESSED_DIR, showWarnings = FALSE, recursive = TRUE)
