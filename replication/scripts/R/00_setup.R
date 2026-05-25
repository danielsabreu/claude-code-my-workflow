###############################################################
# 00_setup.R
# Financial Cycle Replication Package — Abreu & De Lorenzo Buratta
#
# Run once before executing scripts 01–05.
# Installs all packages required by the analysis pipeline.
###############################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- c(
  # Core tidyverse
  "tidyverse", "dplyr", "tidyr", "purrr", "readr", "stringr",
  # Dates
  "lubridate", "zoo", "xts",
  # Data import/export
  "readxl", "writexl",
  # File paths
  "here",
  # Factor models / DFM
  "vars", "dfms",
  # Filters
  "mFilter", "signal",
  # Unit roots / seasonal
  "urca", "seasonal",
  # Early warning / classification
  "pROC",
  # Data reshaping
  "reshape2", "data.table",
  # Visualization
  "ggplot2", "patchwork", "scales"
)

new_packages <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
if (length(new_packages) > 0) {
  message("Installing: ", paste(new_packages, collapse = ", "))
  install.packages(new_packages)
}

invisible(lapply(required_packages, library, character.only = TRUE))
message("Setup complete. All packages loaded.")
