# CLAUDE.md — phd_thesis

PhD thesis at ISEG — Instituto Superior de Economia e Gestão, Universidade de Lisboa. Three-paper dissertation on nonlinear and nonstationary dynamic factor models, with applications to macroeconomic forecasting, financial market dynamics, and financial cycle measurement for macroprudential policy.

---

## Thesis Layout

```
phd_thesis/
├── CLAUDE.md                    # This file
├── MEMORY.md                    # Cross-session project memory
├── Thesis_20251001/             # All papers and the master thesis file
│   ├── Thesis.tex               # Master document (subfiles; biblatex + biber)
│   ├── Smooth_transition_factor_model_paper/   # Paper 1
│   ├── Financial cycle/                        # Paper 2 (co-authored; pre-submission)
│   └── Non-stationary dynamic factor model with threshold cointegration/  # Paper 3
├── slides/                      # Beamer defense slides
├── erratum/                     # Erratum documents
├── discussion_prep/             # Defense Q&A and preparation materials
└── quality_reports/             # Plans, session logs, review reports
```

---

## Three Papers

### Paper 1 — Smooth Transition Factor Model (STFM)

| Field | Value |
|-------|-------|
| **Master file** | `Thesis_20251001/Smooth_transition_factor_model_paper/main.tex` |
| **Bibliography** | `Thesis_20251001/Smooth_transition_factor_model_paper/references.bib` |
| **Status** | Thesis chapter |
| **Target journal** | TBD (econometrics / forecasting) |

**Summary.** Extends factor models to capture gradual, smooth regime shifts via a logistic transition function. Estimation combines NLS for transition parameters with PCA for factor extraction. Includes a linearity test (LM statistic with Taylor expansion of the transition function) and a factor number selection criterion. Empirical application on FRED-QD data shows 3-factor smooth transition model improves US macro forecasts over linear benchmarks.

---

### Paper 2 — Financial Cycle Measurement (DFM)

| Field | Value |
|-------|-------|
| **Master file** | `Thesis_20251001/Financial cycle/main.tex` |
| **Bibliography** | `Thesis_20251001/Financial cycle/REFERENCES.bib` |
| **Status** | Pre-submission |
| **Target journals** | IJCB (International Journal of Central Banking) / Economic Policy |
| **Co-author** | Ivan De Lorenzo Buratta (Prometeia) |

**Summary.** Proposes a DFM-based approach to measure country-specific financial cycles for European economies. Extracts a single latent common factor from credit, asset prices, and leverage indicators. Constructs statistically grounded neutral risk thresholds. Demonstrates strong early-warning capacity for the 2008 Global Financial Crisis. Directly applicable to calibration of the Countercyclical Capital Buffer (CCyB).

**Style invariants — do not flag in review:**
- Conclusion section is intentionally short.
- The claim about 17 EEA CCyB jurisdictions is intentionally uncited.
- This is a **measurement paper**, not a causal/identification paper. Absence of IV or DiD is deliberate, not a weakness.

---

### Paper 3 — Non-stationary DFM with Threshold Cointegration

| Field | Value |
|-------|-------|
| **Master file** | `Thesis_20251001/Non-stationary dynamic factor model with threshold cointegration/main.tex` |
| **Bibliography** | `Thesis_20251001/Non-stationary dynamic factor model with threshold cointegration/FactorCointegration.bib` |
| **Status** | Thesis chapter |
| **Target journal** | TBD (econometrics journals) |

**Summary.** Develops a two-level factor model accommodating I(1) processes with threshold and band vector error-correction mechanisms. Estimation uses SVD initialization followed by sequential least squares with a joint grid search over the threshold parameter and cointegrating vector. Monte Carlo evidence shows good finite-sample performance. Empirical application to the global term structure of interest rates reveals discontinuous adjustment consistent with financial friction theory.

---

## Compilation

This project uses **biblatex + biber** — never bibtex. The backend is declared in the master file:

```latex
\usepackage[style=authoryear,backend=biber,refsection=chapter,natbib=true]{biblatex}
```

Each paper's `main.tex` is a subfile (`\documentclass[Thesis.tex]{subfiles}`) and can be compiled standalone.

```bash
# Compile a single paper
/compile-paper "Thesis_20251001/Financial cycle/main.tex"
/compile-paper "Thesis_20251001/Smooth_transition_factor_model_paper/main.tex"
/compile-paper "Thesis_20251001/Non-stationary dynamic factor model with threshold cointegration/main.tex"

# Compile the full thesis
/compile-paper "Thesis_20251001/Thesis.tex"
```

The `compile-paper` skill auto-detects biber vs bibtex from the `.aux` file after the first pass.

---

## Skills Quick Reference

| Command | Use |
|---------|-----|
| `/compile-paper "Thesis_20251001/Financial cycle/main.tex"` | Compile financial cycle paper |
| `/compile-paper "Thesis_20251001/Thesis.tex"` | Compile full thesis |
| `/review-paper --peer IJCB "Thesis_20251001/Financial cycle/main.tex"` | Peer review calibrated to IJCB |
| `/review-paper --peer "Economic Policy" "Thesis_20251001/Financial cycle/main.tex"` | Peer review calibrated to Economic Policy |
| `/validate-bib` | Cross-check all citations vs bibliography files |
| `/proofread` | Grammar, typos, and consistency check |
| `/compile-latex slides/defense_slides.tex` | Compile Beamer defense slides |
| `/commit` | Stage, commit, PR, merge |
| `/context-status` | Check session health and context usage |

---

## Defense Preparation Materials

| File | Contents |
|------|----------|
| `slides/defense_slides.tex` | Beamer deck, ~28 slides, 30-minute defense |
| `erratum/erratum.md` | Errors found in thesis text (typos, notation, technical) |
| `discussion_prep/defense_qa.md` | ~32 Q&A pairs covering technical, policy, and general questions |
