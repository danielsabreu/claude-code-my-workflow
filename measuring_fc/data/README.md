# Data Sources — Financial Cycle Project

This directory contains the **fixed** raw data files used in the replication package.
These files should not be modified. All transformations are applied by the R scripts in `scripts/R/`.

## Files in `raw/`

| File | Source | Vintage | Description |
|---|---|---|---|
| `sdw_q_join.RData` | ECB Statistical Data Warehouse | 2024 Q3 | Quarterly financial variables for European countries (house prices, share prices, shadow rates) downloaded via ECB SDW API |
| `SRIs_20180530_including_readme.RData` | ECB/ESRB CCyB Taskforce | 2018-05-30 | Systemic risk indicators including debt service ratio (DSR) backcast used to extend BIS DSR series |
| `shadow_rates.xlsx` | Wu & Xia (2016) / Krippner | 2024 Q3 | Shadow short rates for European countries |
| `esrb.fcdb20220120.en.xlsx` | ESRB Financial Crises Database | 2022-01-20 | Systemic banking crisis dates for European countries (Lo Duca et al., 2017) |
| `df.RData` | Derived | 2024 Q3 | Main panel dataset after merging BIS, OECD, and ECB sources |
| `df_vars.RData` | Derived | 2024 Q3 | Processed variable dataset prior to DFM estimation |
| `df_country.RData` | Derived | 2024 Q3 | Country-level panel list used as starting point for script 01 and script 04 |
| `basel_gap.RData` | BIS (derived) | — | Credit-to-GDP gap (Basel gap) for all countries. Created by `scripts/R/00_refresh_data.R`. Run that script before executing scripts 03 and 04. |

## Vintage

Current vintage: **2025 Q3** (extended 2026-05-17 from 2024 Q3 baseline).
See `data/raw/vintage.txt` for machine-readable vintage metadata.

**Note on share prices (2024 Q4 – 2025 Q3):** The OECD FINMARK dataset used in the original extraction (`DSD_STES@DF_FINMARK`) was unavailable as of May 2026 (API endpoint deprecated). For the extension period, share prices are sourced from Yahoo Finance national equity indices (BEL 20, DAX, IBEX 35, OMX Helsinki 25, CAC 40, FTSE 100, FTSE MIB, AEX, PSI 20, OMX Stockholm 30). Historical data (pre-2024 Q4) uses the original OECD source.

---

## Data not included (fetched live in original code)

The following data were originally pulled via API in `1_EXTRACT_DATA.R`. For the replication package, we use the fixed derived files above (`df.RData`, `df_vars.RData`) as starting points, which incorporate all these sources:

| Source | Series | Access |
|---|---|---|
| BIS Total Credit Statistics | Credit to NFC, Credit to HH, Credit-to-GDP, DSR | https://data.bis.org |
| OECD Main Economic Indicators | House prices, Share prices | https://stats.oecd.org |
| ECB SDW | Shadow rates, sovereign bond yields | https://sdw.ecb.europa.eu |

## Countries

BE (Belgium), DE (Germany), ES (Spain), FI (Finland), FR (France),
GB (United Kingdom), IT (Italy), NL (Netherlands), PT (Portugal), SE (Sweden)

## Sample period

1995 Q3 – 2024 Q3

## File format

`.RData` files are R binary format, readable with `load("file.RData")`.
`.xlsx` files are Excel format, readable with `readxl::read_excel("file.xlsx")`.
