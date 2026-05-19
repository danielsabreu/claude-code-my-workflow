# Manuscript Review: Measuring the Financial Cycle — A Dynamic Factor Model Approach

**Date:** 2026-05-19
**Reviewer:** review-paper skill (single-pass)
**File:** paper/main.tex
**Pipeline run:** 01 → 02 → 03 → 05 (completed without errors)
**Paper compiles to:** 47 pages, zero Overfull hbox warnings

---

## Summary Assessment

**Overall recommendation:** Revise and Resubmit (minor revisions)

The paper is in good shape for pre-submission. It makes a clear contribution: a transparent, country-specific DFM-based financial cycle indicator for 10 European countries, with three practical outputs — a variable decomposition, a regime classification framework, and an in-sample/OOS early-warning exercise. The methodology is technically sound, the results are well-narrated, and the pipeline is clean. The R code has been thoroughly reviewed and fixed (T1/T2 correction, CI centering at zero, 95% bands, crisis-averse usefulness). The three main revisions needed are: (1) expanding the underdeveloped conclusion, (2) resolving inconsistency in how dashed CI lines are described between main text and appendix, and (3) adding a citation for a specific policy claim. Several minor issues follow.

---

## Strengths

1. **Methodological transparency**: The DFM approach is simple enough to be replicable in policy institutions, and the decomposition methodology (zero-intercept regression + signed spread weight) is clearly explained.
2. **Three-estimator robustness**: Presenting PCA, QML, and TSTEP side-by-side across all exercises effectively demonstrates robustness to estimator choice.
3. **Technically corrected CI framework**: The 95% confidence bands, correctly centred at zero as a "neutral zone," with constant dashed-line thresholds for regime classification, are well-grounded in Bai (2003) theory.
4. **Rich early-warning section**: The augmentation with crisis-averse preferences (θ=0.7) strengthens the policy relevance. The Germany finding (BG usefulness near zero under θ=0.7 vs PCA's 0.13) is a useful and memorable result.
5. **OOS exercise narrative**: The OOS section correctly qualifies that absolute probability levels are anchored to the historical base rate, focusing attention on the trend (doubling from ~10% to ~20%) as the operationally meaningful signal.

---

## Major Concerns

### MC1: Conclusion is underdeveloped
- **Dimension:** Argument structure
- **Issue:** The conclusion is only three paragraphs and ends with a visible TODO comment. It restates results but does not discuss limitations, future research directions, or detailed policy takeaways. This is below the standard for a policy/central bank journal submission and is already flagged by the authors themselves.
- **Suggestion:** Expand to 5–7 paragraphs per the TODO: (i) pseudo-RT simplifying assumptions (no data vintages, no publication lags); (ii) future research directions (non-European countries, dynamic loadings, nowcasting extensions); (iii) broader policy takeaways on simplicity as a feature for practitioners; (iv) connection to the positive neutral CCyB literature. The methodology section's footnote on CS-HAC degeneracy could also be cited here as an acknowledged limitation.
- **Location:** `paper/sections/5_conclusion.tex`

### MC2: Inconsistent description of dashed CI lines between sections
- **Dimension:** Presentation / Technical accuracy
- **Issue:** The methodology section (line 119) correctly states: *"The mean of the upper and lower bounds provides a pair of constant dashed-line thresholds used for the regime classification throughout the paper."* Appendix C figure notes also correctly say: *"The dashed lines indicate the mean of the upper and lower confidence bounds."* However, the main results text (Section 4, paragraph on Figure~\ref{ci_medians}) says: *"the dashed lines denote the upper and lower confidence bounds"* — omitting that these are time-averaged (constant) lines, not the time-varying bounds. The main figure caption (ci_medians) has the same omission. A reader could interpret the dashed lines as tracking the time-varying CI, which they do not.
- **Suggestion:** In the ci_medians figure caption and the accompanying paragraph in Section 4, change *"the dashed lines denote the upper and lower confidence bounds"* to *"the dashed lines denote the time-averaged upper and lower confidence bounds, used as constant thresholds for regime classification."* The appendix caption is already correct; align the main text to it.
- **Location:** `paper/sections/4_results.tex` (ci_medians paragraph and figure caption)

### MC3: Missing citation for the 17 EEA authorities claim
- **Dimension:** Literature / Technical accuracy
- **Issue:** Section 4.3 states: *"As of November 2025, 17 macroprudential authorities in the European Economic Area (EEA) have implemented a positive neutral CCyB framework."* This is a specific numerical claim presented without a citation. Referees will flag this.
- **Suggestion:** Add a citation — likely the ESRB's CCyB monitoring dashboard or a recent ESRB publication documenting positive neutral CCyB adoptions across the EEA. If a direct citation is not available, rephrase as "A growing number of macroprudential authorities..." or footnote the data source.
- **Location:** `paper/sections/4_results.tex`, paragraph on policy implications

---

## Minor Concerns

### mc1: Citation command inconsistency in Introduction
- **Issue:** Line 5 of the Introduction uses `\citet{}` (produces "Author (Year)") in three successive inline parenthetical references: *"including the financial accelerator \citet{bernanke1999financial}, collateral constraints \citet{kiyotaki1997credit}, and correlated risk-taking by financial intermediaries \citet{he2013intermediary}."* In a parenthetical list after a noun phrase, `\citep{}` is more natural, producing "(Author, Year)."
- **Suggestion:** Switch all three to `\citep{}` or restructure the sentence: *"...including the financial accelerator (Bernanke et al., 1999), collateral constraints (Kiyotaki and Moore, 1997), and correlated risk-taking by financial intermediaries (He and Krishnamurthy, 2013)."*
- **Location:** `paper/sections/1_intro.tex`, line 5

### mc2: Figure label naming inconsistency
- **Issue:** Results section figures use bare labels (e.g., `\label{var_exp}`, `\label{factor_median}`, `\label{ci_medians}`), while appendix figures use `fig:` prefix (e.g., `\label{fig:fc_BE_DE}`, `\label{fig:ci_BE_DE}`). This is not a compilation error but creates confusion when cross-referencing.
- **Suggestion:** Standardise all labels to use the `fig:` prefix (e.g., `\label{fig:var_exp}`) and update all `\ref{}` calls accordingly. Or adopt the reverse convention consistently.
- **Location:** `paper/sections/4_results.tex`, `paper/appendices/`

### mc3: CS-HAC degeneracy claim needs a reference
- **Issue:** The footnote in Section 3 states that CS-HAC estimators are *"algebraically degenerate in the PCA setting"* because loadings are orthogonal to residuals by the PCA first-order conditions, so *"the full CS-HAC sum collapses to zero identically."* This is a non-obvious technical claim presented as self-evident.
- **Suggestion:** Add a citation (e.g., Zhang, 2019, or Bai 2003 supplementary material) or add one sentence of derivation: *"By the first-order condition of PCA, ∑_i λ̂_i ê_it = 0 for all t, so the CS-HAC cross-product sum ∑_{i≠j} λ̂_i λ̂_j ê_it ê_jt is not identified from the outer sum and collapses."*
- **Location:** `paper/sections/3_methodology.tex`, footnote in §3.4

### mc4: Factor order selection not explicitly stated in results
- **Issue:** The methodology section states p=4 for the VAR order (line 37: *"Based on standard information criteria, we select p=4"*) but does not explicitly state r=1 (single factor) with the same transparency in the results section. The reader must infer this from the paper title and figure captions.
- **Suggestion:** Add one sentence in Section 4.1 (Estimation results): *"In all countries, information criteria select a single common factor (r=1), consistent with the model's objective of extracting the dominant co-movement."*
- **Location:** `paper/sections/4_results.tex`, §4.1 opening paragraph

### mc5: Decomposition sign convention for bond spreads not fully explained
- **Issue:** The decomposition section states that bond spreads *"retain the sign of the regression coefficient"* and that *"spread compression signals financial cycle expansion."* This is correct but briefly explained. A referee who expects bond spreads to widen during crises might be puzzled.
- **Suggestion:** Add a parenthetical: *"...spread compression (declining spreads) signals expansion, so a negative coefficient on spreads correctly captures the inverse relationship between spread levels and the financial cycle."*
- **Location:** `paper/sections/4_results.tex`, §4.2 decomposition paragraph

### mc6: Conclusion still says "approximately 25%" — FIXED
- **Status:** Fixed during this review session (→ "around 20%"). Included here for the record.
- **Location:** `paper/sections/5_conclusion.tex`

---

## Referee Objections

### RO1: Are the CI bands economically meaningful or just a statistical artifact?
**Why it matters:** The 95% CI for the PCA factor is derived under large-N asymptotics (N=7 variables), but asymptotic approximations may be poor at N=7. A referee could argue the bands are too narrow (underestimating uncertainty) or that the "neutral zone" interpretation is not robust to the small N.
**How to address it:** Add a robustness footnote or brief discussion: *"With N=7, the asymptotic approximation should be treated as an approximation. The qualitative regime classifications are robust to modest perturbations of the threshold: classifying periods within ±10% of the time-averaged band as neutral does not materially alter the regime dates."* Alternatively, consider a small Monte Carlo exercise showing coverage properties at N=7, T=100.

### RO2: Why not use a real-time vintage dataset?
**Why it matters:** The OOS exercise uses final revised data and no publication lags. This is acknowledged but a referee may push back that the 10%-to-20% doubling could be inflated by data revisions (particularly credit variables, which are often revised significantly).
**How to address it:** The paper could add a brief sensitivity: *"Credit aggregates are generally subject to modest revisions, particularly for 2-year growth rates over the medium term. We verified that excluding the last two available observations for each country does not materially change the OOS predictions."* Or cite evidence that credit variables have small revisions over medium horizons.

### RO3: Is the model selection (r=1, p=4) stable across countries and time?
**Why it matters:** The paper uses a single-factor model for all 10 countries without reporting whether any country would prefer r=2. If Germany or Portugal prefer r=2, the r=1 constraint could distort the financial cycle interpretation.
**How to address it:** Report information criteria (IC1 or BIC3 from Bai/Ng) by country in an appendix or footnote table. Even a one-line note like *"In all countries, IC1 selects r=1; allowing r=2 does not change the dominant factor's interpretation"* would address this concern.

### RO4: Do the results change with the Butterworth filter parameters?
**Why it matters:** The choice of 4–25 year passband for the Butterworth filter is asserted but the AUROC / usefulness results may be sensitive to this parameter choice. A referee may ask for robustness to, e.g., 4–20 year or 4–30 year bands.
**How to address it:** Add a brief robustness paragraph (or appendix): *"The main results are robust to alternative frequency bands (4–20 and 4–30 year passbands), which yield qualitatively similar financial cycle trajectories and early-warning statistics."*

### RO5: Why does Belgium underperform its peers on AUROC (0.51 for PCA)?
**Why it matters:** An AUROC of 0.51 is effectively random. A referee may question whether the DFM is adding value for Belgium and whether the average is misleading.
**How to address it:** Add a footnote or brief discussion: *"The weak AUROC for Belgium likely reflects the relatively small number of crisis observations and the early timing of Belgian stress episodes (1990s), which fall mostly outside the post-1995 sample used in the estimation."* Cross-reference the descriptive statistics to show Belgium's sample period.

---

## Specific Comments

| Location | Issue | Action |
|---|---|---|
| `1_intro.tex` line 5 | `\citet` → `\citep` for parenthetical triple citation | Fix |
| `1_intro.tex` line 11 | No citation for the OOS "doubling" result claim in intro | Add forward reference to section 4 (e.g., "see Section~\ref{Results}") |
| `3_methodology.tex` line 37 | *"we select p=4"* — add how r=1 is selected | One sentence |
| `4_results.tex` CI paragraph | *"dashed lines denote the upper and lower confidence bounds"* | Add "time-averaged" |
| `4_results.tex` ci_medians caption | Same as above | Add "time-averaged" |
| `4_results.tex` positive neutral CCyB sentence | Missing citation for "17 authorities" | Add ESRB source |
| `5_conclusion.tex` | Expand to 5–7 paragraphs | Major (acknowledged TODO) |
| Appendix A captions | Correct and consistent — no changes needed | — |
| Appendix B captions | Correct and consistent — no changes needed | — |
| Appendix C captions | Correct and precise ("mean of upper and lower bounds") — no changes needed | — |

---

## Summary Statistics

| Dimension | Rating (1–5) |
|---|---|
| Argument Structure | 3 (conclusion underdeveloped) |
| Identification / DFM Specification | 4 |
| Econometrics | 4 (CI, T1/T2, θ now correct) |
| Literature | 4 |
| Writing Quality | 4 |
| Presentation | 4 (ci_medians caption inconsistency) |
| **Overall** | **4 / 5** |

**Quality score estimate:** 82/100
- Deductions: conclusion underdeveloped (-8), dashed-line inconsistency (-5), missing citation (-3), minor issues (-2)
- Above commit threshold (80), below PR threshold (90)
- Recommended: address MC1–MC3, then resubmit for PR

---

## Next Steps

1. **Expand conclusion** — address the TODO. Estimated 2–4 hours.
2. **Fix ci_medians text and caption** — add "time-averaged" qualifier. ~10 minutes.
3. **Add ESRB citation** — for 17 EEA authorities. ~10 minutes.
4. **Add r=1 selection sentence** — in Section 4.1. ~5 minutes.
5. **Fix \citet → \citep** in intro. ~5 minutes.
6. After these fixes, recompile and re-score. Target: ≥88/100.
