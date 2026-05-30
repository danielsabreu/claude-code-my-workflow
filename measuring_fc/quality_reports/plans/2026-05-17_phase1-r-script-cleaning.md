# Phase 1 — R Script Cleaning & Replication Package Foundation
**Status:** APPROVED — COMPLETED 2026-05-17  
**Date:** 2026-05-17  
**Follows:** 2026-05-17_financial-cycle-project-setup.md (Phase 0)

---

## Context

The 4 replication scripts (`01`–`04`) were migrated from the institutional environment. They are not yet runnable outside Banco de Portugal's network due to: hardcoded absolute paths (`G:/6.APM/...`), sourced auxiliary functions not in the repo, institutional proxy settings, and live BIS API calls for the Basel gap embedded inside analysis scripts.

**Design decision (confirmed by user):** The Basel gap and all raw data will be part of a fixed, augmented dataset. There will be a separate `00_refresh_data.R` script (NOT part of the replication package) that fetches new data from BIS/OECD/ECB and augments the existing raw files. The replication scripts (01–04) load only from fixed files in `data/raw/` and `data/processed/` — no API calls.

---

## Inventory of Issues Found

| Script | Issue | Severity |
|---|---|---|
| All 4 | `setwd("G:/6.APM/...")` | Critical — breaks on any other machine |
| All 4 | `load("G:/6.APM/...")` and `save(..., "2. Data/...")` | Critical |
| All 4 | `source("G:/6.APM/.../Auxiliary/...")` | Critical — auxiliary functions not in repo |
| 02, 04 | Proxy env vars at top (`Sys.setenv(http_proxy...)`) | Major — remove |
| 03, 04 | Live BIS API call for Basel gap (`fetch_dataset(...)`) | Major — replace with fixed file load |
| 03 | Syntax error: `df_esrb_residual` pipe chain truncated with trailing `%>%` | Critical — script doesn't run |
| 01, 04 | `load("df_country.RData")` — file not yet in `data/raw/` | Critical |
| All 4 | Figure output: `png("file.png", ...)` with no path → writes to working dir | Major |
| All 4 | Data output: `save(..., file = "2. Data/...")` → wrong path | Major |
| All 4 | `rm(list=ls())` at top — fine for standalone scripts | Minor |
| 02, 03 | Uses `theme_base()` from ggthemes — should use project theme | Minor |
| 00_setup.R | Missing packages: `vars`, `nowcasting`, `dfms`, `mFilter`, `BISdata`, `rmsumst`, `data.table`, `ggthemes`, `purrr`, `lubridate`, `signal` | Major |

---

## Plan

### Step 1 — Copy missing raw data & auxiliary functions

**1a.** Copy `df_country.RData` from `old_code_and_data/Financial Cycle/2. Data/` to `data/raw/`

**1b.** Copy all auxiliary R files from `old_code_and_data/Financial Cycle/3. Codes/Auxiliary/` to `scripts/R/auxiliary/`:
- `avar.R`, `boundaryFstats.R`, `BW_filter.R`, `dfm_conf_int.R`, `FC_decomposition.R`
- `filterhp.R`, `get_coords.R`, `getauroc.R`, `getfilter.R`, `getseas.R`, `getseas_v2.R`
- `ICr_c.R`, `main_with_pass.R`, `normalise.R`, `transform_2yoy.R`, `trend_filterHP.R`, `urtests.R`

**1c.** Cache Basel gap data: Extract from the BIS data already embedded in `sdw_q_join.RData` or saved outputs in `old_code_and_data`. If not present, note that `00_refresh_data.R` must be run once to create `data/raw/basel_gap.RData`.

### Step 2 — Create `scripts/R/auxiliary/` path helper

Add a single `_paths.R` file to `scripts/R/auxiliary/` that defines paths using `here::here()`:
```r
RAW_DIR       <- here::here("data", "raw")
PROCESSED_DIR <- here::here("data", "processed")
OUTPUTS_DIR   <- here::here("scripts", "R", "_outputs")
FIGURES_DIR   <- here::here("Figures")
AUX_DIR       <- here::here("scripts", "R", "auxiliary")
```
Every script will `source(here::here("scripts", "R", "auxiliary", "_paths.R"))` at the top.

### Step 3 — Clean `01_data_processing.R`

Changes:
- Remove `rm(list=ls())` and `setwd()`
- Add `library(here)` + `source(_paths.R)`
- Replace `source("G:/...Auxiliary/X.R")` with `source(file.path(AUX_DIR, "X.R"))` for each auxiliary function
- Replace `load("G:/...df_country.RData")` with `load(file.path(RAW_DIR, "df_country.RData"))`
- Replace `save(df_model, file = "2. Data/df_model.RData")` with `save(df_model, file = file.path(OUTPUTS_DIR, "df_model.RData"))`
- Replace `write_xlsx(summary_stats, "G:/...")` with `writexl::write_xlsx(summary_stats, file.path(OUTPUTS_DIR, "summary_stats.xlsx"))`
- Save `summary_stats` as RData to `_outputs/` as well
- Update `00_setup.R` with any missing packages

### Step 4 — Clean `02_factor_estimation.R`

Changes:
- Remove `rm(list=ls())` and `setwd()`
- Add `library(here)` + `source(_paths.R)`
- Replace all `source("G:/...Auxiliary/X.R")` with `source(file.path(AUX_DIR, "X.R"))`
- Replace `load("G:/...df_model.RData")` with `load(file.path(OUTPUTS_DIR, "df_model.RData"))`
- Replace all `save(...)` with paths using `OUTPUTS_DIR`
- Replace figure outputs: `png("var_exp.png", ...)` → `png(file.path(FIGURES_DIR, "var_exp.png"), width = 1200, height = 600, res = 150)`
- Remove debug/scratch graphs (the `png("factor.png", ...)` and `png("pca_conf.png", ...)` blocks — these are diagnostic plots not in the paper)
- Replace `write_xlsx(table_r2, "G:/...")` with path to `OUTPUTS_DIR`
- Remove or update the `write_xlsx(conf_int_graph, path = "G:/...")` reference

### Step 5 — Clean `03_dec_ew_gar.R`

Changes:
- Add `library(here)` + `source(_paths.R)` preamble
- Replace all `source("G:/...Auxiliary/X.R")` with `source(file.path(AUX_DIR, "X.R"))`
- **Fix syntax error:** complete the `df_esrb_residual` pipe chain by adding the missing closing parenthesis and removing the dangling `%>%` — use the correct definition from `04_oos.R` as the reference
- Replace `load("G:/...df_dec.RData")` with `load(file.path(OUTPUTS_DIR, "df_dec.RData"))`
- Replace live BIS Basel gap fetch with: `load(file.path(RAW_DIR, "basel_gap.RData"))` — add a `stopifnot(file.exists(...))` with a clear error message directing user to run `00_refresh_data.R` if missing
- Replace `read_xlsx("G:/...esrb...")` with `read_xlsx(file.path(RAW_DIR, "esrb.fcdb20220120.en.xlsx"), ...)`
- Replace figure `png(...)` outputs with `file.path(FIGURES_DIR, "...")`
- Replace `write_xlsx(...)` outputs with `file.path(OUTPUTS_DIR, "...")`

### Step 6 — Clean `04_oos.R`

Changes:
- Remove `rm(list=ls())` and `setwd()`
- Add `library(here)` + `source(_paths.R)`
- Replace all `source("G:/...Auxiliary/X.R")` with `source(file.path(AUX_DIR, "X.R"))`
- Replace `load("G:/...df_country.RData")` with `load(file.path(RAW_DIR, "df_country.RData"))`
- Replace live BIS Basel gap fetch with `load(file.path(RAW_DIR, "basel_gap.RData"))`
- Replace `read_xlsx("G:/...esrb...")` with `read_xlsx(file.path(RAW_DIR, "esrb.fcdb20220120.en.xlsx"), ...)`
- Replace figure `png(...)` with `file.path(FIGURES_DIR, "oos_graph.png")`

### Step 7 — Update `00_setup.R`

Add all packages actually used across all 4 scripts that are missing:
`vars`, `nowcasting`, `dfms`, `mFilter`, `BISdata`, `rmsumst`, `data.table`, `ggthemes`, `purrr`, `lubridate`, `pROC`, `signal`

### Step 8 — Create `00_refresh_data.R` skeleton

A new script (separate from the replication package) that documents where to augment the raw data:
```
scripts/R/00_refresh_data.R
```
This script will (in a future session):
- Fetch fresh BIS data (credit, DSR, credit-to-GDP, Basel gap)
- Extend the existing `df.RData` / `df_country.RData` with new observations
- Save augmented files back to `data/raw/`

For now, it is a documented skeleton with `# TODO` sections.

### Step 9 — Update `data/README.md`

Add entries for:
- `df_country.RData` (now in `data/raw/`)
- `basel_gap.RData` (to be created by `00_refresh_data.R`)
- `scripts/R/auxiliary/` directory documentation

---

## Files Modified

| File | Action |
|---|---|
| `data/raw/df_country.RData` | Copy from old_code_and_data |
| `scripts/R/auxiliary/*.R` | Copy ~17 files from old_code_and_data |
| `scripts/R/auxiliary/_paths.R` | New — path helper |
| `scripts/R/00_setup.R` | Update package list |
| `scripts/R/00_refresh_data.R` | New skeleton |
| `scripts/R/01_data_processing.R` | Clean paths, sources, saves |
| `scripts/R/02_factor_estimation.R` | Clean paths, sources, saves, figures |
| `scripts/R/03_dec_ew_gar.R` | Clean + fix syntax error + replace Basel gap fetch |
| `scripts/R/04_oos.R` | Clean paths, sources, figures + replace Basel gap fetch |
| `data/README.md` | Add df_country.RData entry |

---

## Verification

After implementation:
1. Each script loads without `source()` or `load()` errors on a machine without `G:/` drive
2. All `save()` and `write_xlsx()` calls point to `scripts/R/_outputs/` or `Figures/`
3. Script 03 has no syntax errors (R parse check: `parse(file = "03_dec_ew_gar.R")`)
4. `00_setup.R` installs all required packages without missing-package errors
5. Run `Rscript scripts/R/01_data_processing.R` and confirm it produces `scripts/R/_outputs/df_model.RData`

---

## Out of scope for this session

- Actually running the full pipeline end-to-end (that's Phase 1.4 — /audit-reproducibility)
- Building the data refresh workflow in detail (future session)
- Figure quality improvements (Phase 2.4)
