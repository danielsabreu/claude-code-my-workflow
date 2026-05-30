# Data Refresh — Updated Dataset for Submission
**Status:** COMPLETED 2026-05-17  
**Date:** 2026-05-17

---

## Context

The current `data/raw/df_country.RData` has a 2024 Q3 vintage. For submission, we want the most recent data available from BIS and OECD APIs. The refresh is **incremental**: load the existing dataset, fetch only observations after the last available date, bind them on, and save. This avoids re-downloading years of data unnecessarily and preserves the DSR backcast already embedded in the historical observations.

The result feeds two outputs:
1. `data/raw/df_country.RData` — updated raw panel (input to `01_data_processing.R`)
2. `data/raw/basel_gap.RData` — updated Basel gap series (input to `03_dec_ew_gar.R` and `04_oos.R`)

---

## Key facts from the reference script

**Data sources (all public APIs):**

| Variable | Source | BIS/OECD dataset |
|---|---|---|
| Credit to NFC | BIS | WS_TC_csv_col.zip, series `N:A:M:XDC:A` |
| Credit to HH | BIS | WS_TC_csv_col.zip, series `H:A:M:XDC:A` |
| Credit-to-GDP ratio | BIS | WS_CREDIT_GAP_csv_col.zip, series `P:A:A` |
| DSR | BIS | WS_DSR_csv_col.zip, series `P` |
| House prices (real, s.a.) | OECD | `OECD.ECO.MPD,DSD_AN_HOUSE_PRICES@DF_HOUSE_PRICES,` |
| Share prices (monthly→quarterly) | OECD | `OECD.SDD.STES,DSD_STES@DF_FINMARK,` |
| Bond yields/spreads (vs DE) | OECD | `OECD.SDD.STES,DSD_KEI@DF_KEI,4.0` |
| Basel gap (HP-filtered) | BIS | WS_CREDIT_GAP_csv_col.zip, series `P:A:B` |

**Countries:** BE, DE, ES, FI, FR, GB, IT, NL, PT, SE

**DSR backcast:** The original script backcasts DSR from the CCyB taskforce data (`SRIs_20180530_including_readme.RData`) for the pre-BIS period. This backcast is already embedded in the existing `df_country.RData`. For new observations (post-2024 Q3), BIS DSR data covers all our countries directly — no backcast needed.

---

## Implementation plan

### Step 1 — Load existing data and find last observation date

```r
load(file.path(RAW_DIR, "df_country.RData"))
# Find the most recent date that ALL countries share
max_dates <- sapply(df_country, function(df) max(df$obstime))
cutoff    <- min(max_dates)  # conservative: extend from the earliest "latest" date
```

### Step 2 — Fetch BIS data (full download, filter new obs)

BIS datasets are bulk downloads (no date-range API). Download full zip to tempdir, then filter for `obstime > cutoff`. Variables:
- Credit NFC + HH: `WS_TC_csv_col.zip`
- Credit-to-GDP ratio: `WS_CREDIT_GAP_csv_col.zip` (series P:A:A)
- DSR: `WS_DSR_csv_col.zip` (series P)
- Basel gap: `WS_CREDIT_GAP_csv_col.zip` (series P:A:B) — save separately as `basel_gap.RData`

Apply same parsing as reference: extract country code from Series field, parse quarter dates, rename ts_ids.

### Step 3 — Fetch OECD data (filtered by start date)

`get_dataset()` supports time filtering. Use `startTime = format(cutoff, "%Y-Q%q")` to fetch only new observations:
- House prices: quarterly, direct filter
- Share prices: monthly, filter then collapse to end-of-quarter
- Bond yields: monthly, compute spread vs Germany, collapse to end-of-quarter

### Step 4 — Bind new observations to existing data

For each country:
```r
new_obs  <- new_long[new_long$country == c & new_long$obstime > cutoff, ]
df_country[[c]] <- bind_rows(df_country[[c]], pivot_wider(new_obs))
```
Preserve column order: `c("obstime", "cred.nfc", "cred.hh", "rhp", "sp", "dsr", "cred.2gdp", "sprd.bond")`.
Drop countries that no longer have all 8 variables.

### Step 5 — Save

```r
save(df_country,       file = file.path(RAW_DIR, "df_country.RData"))
save(bis_cred2gdp_gap, file = file.path(RAW_DIR, "basel_gap.RData"))
```

Also save a vintage metadata file:
```r
writeLines(paste("Vintage:", Sys.Date(), "\nCutoff extended from:", cutoff, "\nNew quarters:", n_new),
           file.path(RAW_DIR, "vintage.txt"))
```

---

## Files modified

| File | Action |
|---|---|
| `scripts/R/00_refresh_data.R` | Replace TODO stubs with full implementation |
| `data/raw/df_country.RData` | Updated with new observations |
| `data/raw/basel_gap.RData` | Created / updated |
| `data/raw/vintage.txt` | New — tracks dataset vintage |

---

## Verification

1. Script runs without errors
2. `max(sapply(df_country, function(df) max(df$obstime)))` > `"2024-09-30"` — confirms new data was added
3. `file.exists(file.path(RAW_DIR, "basel_gap.RData"))` — TRUE
4. All 10 countries still present in updated `df_country`
5. No NA columns (all 8 variables present per country)
