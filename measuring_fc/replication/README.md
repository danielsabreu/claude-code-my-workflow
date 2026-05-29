# Replication Package
## Measuring the Financial Cycle: A Dynamic Factor Model Approach
**Daniel Abreu (Banco de Portugal) & Ivan De Lorenzo Buratta (Prometeia)**

---

## Overview

This package replicates all tables and figures in the paper. The analysis starts from the raw country-level panel dataset (`data/raw/df_country.RData`) and produces the paper's figures and intermediate outputs in a single pipeline run.

---

## Requirements

**R version:** 4.2 or later (tested on 4.4.x)

Install all required packages by running:

```r
source("scripts/R/00_setup.R")
```

Key packages: `dfms`, `vars`, `mFilter`, `pROC`, `tidyverse`, `ggplot2`, `patchwork`, `here`, `writexl`, `readxl`, `data.table`.

---

## Data

| File | Source | Description |
|---|---|---|
| `data/raw/df_country.RData` | BIS, OECD, ECB SDW (vintage 2025 Q3) | Country-level quarterly panel — the starting point for all analysis scripts. Covers 10 EU countries, 1995 Q3–2025 Q3. |
| `data/raw/basel_gap.RData` | BIS Credit-to-GDP Statistics | Credit-to-GDP gap (Basel gap) for all countries. |
| `data/raw/esrb.fcdb20220120.en.xlsx` | ESRB Financial Crises Database (2022-01-20) | Systemic banking crisis dates used in the early-warning analysis. |

The `df_country.RData` object contains a named list of data frames (one per country) with the following variables: `obstime`, `cred.nfc`, `cred.hh`, `rhp`, `sp`, `dsr`, `cred.2gdp`, `sprd.bond`.

**Data sources underlying `df_country.RData`:**

| Series | Original source |
|---|---|
| Credit to NFC, Credit to HH, Credit-to-GDP, DSR | BIS Total Credit and DSR Statistics |
| House prices | OECD Analytical House Prices Indicators |
| Share prices | OECD Main Economic Indicators (KEI); Yahoo Finance for 2025 Q1–Q3 extension |
| Bond yields / spreads | OECD KEI |

---

## How to Run

Set your working directory to the `replication/` folder, then run:

```r
# One-time setup (install packages)
source("scripts/R/00_setup.R")

# Full pipeline — produces all figures and intermediates
source("scripts/R/00_run_all.R")
```

The pipeline runs sequentially: `01 → 02 → 03 → 04 → 05`. Total runtime is approximately 15–25 minutes depending on hardware (the out-of-sample loop in `04_oos.R` is the bottleneck).

**Important:** Run from within the `replication/` folder. The `.here` file ensures `here::here()` resolves to `replication/` as the project root.

---

## Script Descriptions

| Script | Input | Output | Description |
|---|---|---|---|
| `01_data_processing.R` | `data/raw/df_country.RData` | `_outputs/df_model.RData`, `_outputs/summary_stats.*` | 2-year growth rate transformations, Butterworth filter, standardisation, country filtering |
| `02_factor_estimation.R` | `_outputs/df_model.RData` | `_outputs/df_dfm.RData`, `_outputs/df_ic_avar.RData`, `_outputs/df_loadings.RData`, `_outputs/df_dec.RData`, `_outputs/df_regimes.RData`, `_outputs/table_r2.*`; `Figures/var_exp.pdf`, `Figures/factor_medians.pdf`, `Figures/ci_medians.pdf`, `Figures/regimes_graph.pdf` | DFM estimation (PCA, QML, two-step); variance explained; confidence intervals; regime classification |
| `03_dec_ew_gar.R` | `_outputs/df_dec.RData`, `data/raw/esrb.fcdb20220120.en.xlsx`, `data/raw/basel_gap.RData` | `Figures/dec_graph.pdf`; `_outputs/df_auroc.*`, `_outputs/df_coords.*`, `_outputs/df_coords_alt.*` | Financial cycle decomposition; in-sample early-warning (AUROC, usefulness index) |
| `04_oos.R` | `data/raw/df_country.RData`, `data/raw/esrb.fcdb20220120.en.xlsx`, `data/raw/basel_gap.RData` | `Figures/oos_graph.pdf`; `_outputs/df_oos.*` | Simulated out-of-sample early-warning exercise (2006 Q1 – 2009 Q1) |
| `05_panel_figures.R` | `_outputs/df_dfm.RData`, `_outputs/df_ic_avar.RData`, `_outputs/df_dec.RData` | `Figures/panel_fc_*.pdf` (Appendix A), `Figures/final_panel_with_legend_*.pdf` (Appendix B), `Figures/panel_ci_*.pdf` (Appendix C) | Country-level panel figures for appendices |

Auxiliary functions are in `scripts/R/auxiliary/`. All paths are resolved via `here::here()`.

---

## Expected Outputs

After a complete pipeline run you should see:

**`scripts/R/_outputs/`**

| File | Created by |
|---|---|
| `df_model.RData` | Script 01 |
| `summary_stats.RData` / `.xlsx` | Script 01 |
| `df_dfm.RData` | Script 02 |
| `df_ic_avar.RData` | Script 02 |
| `df_loadings.RData` | Script 02 |
| `df_dec.RData` | Script 02 |
| `df_regimes.RData` | Script 02 |
| `table_r2.RData` / `.xlsx` | Script 02 |
| `df_auroc.RData` / `.xlsx` | Script 03 |
| `df_coords.RData` / `.xlsx` | Script 03 |
| `df_coords_alt.RData` / `.xlsx` | Script 03 |
| `df_oos.RData` / `.xlsx` | Script 04 |
| `sessionInfo.txt` | `00_run_all.R` |

**`Figures/`**

| File | Paper location |
|---|---|
| `var_exp.pdf` | Figure: Variance explained |
| `factor_medians.pdf` | Figure: Median financial cycle |
| `ci_medians.pdf` | Figure: Confidence intervals (median) |
| `regimes_graph.pdf` | Figure: Regime heatmap |
| `dec_graph.pdf` | Figure: Decomposition (median) |
| `oos_graph.pdf` | Figure: Out-of-sample predicted probability |
| `panel_fc_1_2.pdf` … `panel_fc_9_10.pdf` | Appendix A (country panels) |
| `final_panel_with_legend_1_2.pdf` … | Appendix B (decomposition panels) |
| `panel_ci_1_2.pdf` … `panel_ci_9_10.pdf` | Appendix C (CI panels) |

---

## Reproducibility

- **Fixed seed:** `20260413` (set in `00_run_all.R`).
- **Session info:** captured in `scripts/R/_outputs/sessionInfo.txt` after each full run.
- **Country sample:** Belgium (BE), Germany (DE), Spain (ES), Finland (FI), France (FR), United Kingdom (GB), Italy (IT), Netherlands (NL), Portugal (PT), Sweden (SE).
- **Sample period:** 1995 Q3 – 2025 Q3 (after transformation, effective start varies by country).

---

## Correspondence

Daniel Abreu — Banco de Portugal  
Ivan De Lorenzo Buratta — Prometeia
