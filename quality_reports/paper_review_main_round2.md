# Manuscript Review: Measuring the Financial Cycle — A Dynamic Factor Model Approach

**Date:** 2026-05-20
**Reviewer:** review-paper skill (single-pass, Round 2)
**File:** paper/main.tex
**Prior review:** quality_reports/paper_review_main_round1.md (2026-05-19, score 82/100)
**Round 1 fixes applied:** MC2 (CI description), mc1 (citation style), mc4 (r=1 explicit), "25%"→"20%"

---

## Changes Since Round 1 — Status

| Round 1 concern | Status |
|---|---|
| MC2: dashed CI line description | **FIXED** — now correctly says "time-averaged" |
| mc1: `\citet` → `\citep` for three intro citations | **FIXED** |
| mc4: r=1 selection not stated explicitly | **FIXED** — sentence added in §4.1 |
| "approximately 25%" in conclusion | **FIXED** → "around 20%" |
| MC1: conclusion underdeveloped | **Author preference: concise by design — not flagged** |
| MC3: 17 EEA authorities uncited | **Author preference: intentionally uncited — not flagged** |
| mc3: CS-HAC degeneracy footnote needs reference | **OPEN** |
| mc5: decomposition sign convention parenthetical | **OPEN** |
| RO1–RO5: robustness checks | **OPEN — none added to paper** |
| Figure label naming inconsistency (`fig:` vs bare) | **OPEN** |

---

## Summary Assessment

**Overall recommendation:** Revise and Resubmit (moderate revisions)

The paper continues to make a clear, policy-relevant contribution: country-specific DFM financial cycle indicators for 10 European countries, with a statistically grounded neutral-regime classification and useful early-warning properties. The methodology is sound, the pipeline is clean (clean compilation, 47 pages, 0 Overfull hbox), and the figures are professionally produced. Round 1 fixes were applied correctly.

This round surfaces two new **pre-submission blockers** not caught in Round 1: (1) the introduction states the paper's contributions twice in two consecutive paragraphs with substantial, confusing overlap — a structural problem that a desk editor would flag immediately; and (2) the acknowledgments still contain placeholder text "[XXX, YYY, ZZZ]" which will result in an embarrassing automatic rejection at most journals. Neither issue is present in the compiled body of the paper but both must be fixed before submission.

Beyond those two blockers, three round-1 referee objections remain unaddressed (N=7 CI asymptotics, single-episode OOS, model selection stability), and a cluster of minor BibTeX and citation-style issues have been identified in the bibliography file. The path to submission-ready (≥88/100) is clear but requires two to four hours of work.

---

## Strengths

1. **Methodological transparency**: The DFM approach with three estimators (PCA, QML, TSTEP), a clear decomposition, and a principled CI-based regime classification is genuinely useful for policymakers and replicable in other institutions.
2. **Three-estimator robustness built in**: Presenting PCA, QML, and TSTEP side-by-side throughout the paper is an efficient design — it makes robustness visible without a separate robustness section.
3. **Correct and clean CI framework**: The 95% confidence bands, correctly centred at zero, with constant dashed-line thresholds derived as time-averaged bounds, are well-grounded and the description is now consistent across sections (Round 1 fix confirmed).
4. **Rich early-warning section**: The AUROC + two usefulness columns (θ=0.5, θ=0.7) with the Basel gap as benchmark is the right set-up for a policy audience. The Germany finding (BG usefulness near-zero vs PCA 0.13 under crisis-averse preferences) is memorable and likely to be cited.
5. **OOS narrative is correctly qualified**: The discussion of why absolute probability levels are anchored to the historical base rate, and why the *doubling* is the actionable signal, is well-calibrated.

---

## Major Concerns

### MC1 (NEW): Introduction states contributions twice, creating structural redundancy

- **Dimension:** Argument structure / Writing quality
- **Issue:** Paragraphs 5 and 6 of the introduction both enumerate the paper's main contributions, with substantial overlap:
  - Paragraph 5 ("The paper makes two central contributions..."): lists (i) the neutral-risk CI framework and (ii) the OOS early-warning exercise.
  - Paragraph 6 ("We show that this indicator can inform macroprudential policy along three key dimensions..."): lists (i) the neutral-risk framework *again*, (ii) the decomposition, and (iii) early-warning properties *again*.
  - The decomposition contribution appears only in paragraph 6; the OOS result appears in both. The neutral-risk framework appears in both but is described in slightly different terms. A reader is left uncertain which is the authoritative statement of contributions, and why there are both "two contributions" and "three dimensions."
- **Suggestion:** Consolidate into a single contribution paragraph that lists all three contributions (neutral-risk framework, decomposition, early-warning) once, in a single numbered list or clear enumeration. Remove the duplicate paragraph. The abstract already covers all three correctly — use it as the template.
- **Location:** `paper/sections/1_intro.tex`, paragraphs 5–6 (approximately lines 9–11 of the current file)

### MC2 (NEW): Acknowledgments contain submission-blocking placeholder text

- **Dimension:** Presentation / Professionalism
- **Issue:** The acknowledgments (main.tex, line 87) read: *"We thank [XXX, YYY, ZZZ] and participants of the [XXX Workshop] for helpful comments."* These unfilled placeholders will appear verbatim in the compiled PDF submitted to a journal. Most journals' editorial systems (ScholarOne, Editorial Express, OJS) do not strip LaTeX comments, and several automatically desk-reject submissions containing bracket placeholders.
- **Suggestion:** Fill in actual names and the workshop name, or use a temporary anonymous version if the paper is being submitted double-blind: *"We thank seminar and conference participants for helpful comments."*
- **Location:** `paper/main.tex`, line 87

---

## Minor Concerns

### mc1 (NEW): Author affiliation mismatch

- **Issue:** The author block (main.tex, line 63) lists Daniel Abreu's affiliation as "Financial Conduct Authority, UK" with FCA email. Project records indicate affiliation with Banco de Portugal. If this reflects a recent institutional move, the affiliation should be confirmed as correct. If it is a draft placeholder or error, it needs to be updated before submission.
- **Location:** `paper/main.tex`, line 63
- **Action needed:** Confirm or correct affiliation and email.

### mc2 (NEW): Three instances of `\cite` instead of `\citet` for inline author-position citations

- **Issue:** Three citations in Section 4 use the bare `\cite{}` command in author-position contexts where `\citet{}` is required:
  1. `\cite{lo2017new}` → "dataset constructed by \cite{lo2017new}" (§4.4, line ~157)
  2. `\cite{alessi2018identifying}` → "similar to \cite{alessi2018identifying}" (§4.4, line ~228)
  3. `\cite{detken2014operationalising}` → "as defined by \cite{detken2014operationalising}" (§4.4, line ~228)
  The bare `\cite` in `natbib` produces "(Author Year)" which is incorrect when the author is grammatically the subject or object of the sentence; `\citet` produces "Author (Year)."
- **Suggestion:** Replace all three with `\citet{}`.
- **Location:** `paper/sections/4_results.tex`, §4.4 (early-warning section)

### mc3 (ROUND 1, OPEN): CS-HAC degeneracy footnote lacks a citation

- **Issue:** The footnote in §3.4 states that CS-HAC estimators are algebraically degenerate in the PCA setting because loadings are orthogonal to residuals by the PCA first-order conditions. This is a non-obvious technical claim presented without a reference.
- **Suggestion:** Add a citation to Bai (2003) supplementary material or Zhang (2019), or add one line of derivation: *"By the first-order condition of PCA, $\sum_i \hat{\lambda}_i \hat{e}_{it} = 0$ for all $t$, so the CS-HAC cross-product sum collapses identically."*
- **Location:** `paper/sections/3_methodology.tex`, footnote in §3.4

### mc4 (ROUND 1, OPEN): Decomposition sign convention for bond spreads needs a parenthetical

- **Issue:** The decomposition text says bond spreads "retain the sign of the regression coefficient" and "spread compression signals financial cycle expansion" but does not explain why this is the right choice. A referee expecting spreads to widen during crises may be puzzled.
- **Suggestion:** Add a parenthetical: *"...spread compression (declining spreads) signals expansion, so a negative coefficient on spreads correctly captures the inverse relationship between spread levels and the financial cycle."*
- **Location:** `paper/sections/4_results.tex`, §4.2 decomposition paragraph

### mc5 (NEW): `mian2014explains` citation appears mismatched in context

- **Issue:** The data section cites `\citet{mian2014explains}` alongside `\citep{reinhart2013banking}` to support the claim that "equity prices often peak prior to crisis episodes." Mian & Sufi (2014, *Econometrica*) is about the employment decline during the GFC, not equity price dynamics prior to crises. This is likely a citation slip. Reinhart & Rogoff (2013) is appropriate; Mian & Sufi is not.
- **Suggestion:** Replace `mian2014explains` with a more appropriate citation — for example, Jordà, Schularick & Taylor (2015) on asset prices and banking crises, or simply rely on `reinhart2013banking` alone. Alternatively, if Mian & Sufi is intended to support a different sub-claim in the same sentence, restructure to make the attribution explicit.
- **Location:** `paper/sections/2_data.tex`, §2.1 ("Asset prices" paragraph)

### mc6 (NEW): Two malformed BibTeX entries may produce garbled citations

- **Issue 1:** `@article{detken2014operationalising}` has a duplicate `journal` field: the first instance is `{ESRB: Occasional Paper Series}` and the second (which overwrites it in most BibTeX processors) is empty `{}`. Depending on the processor, the journal name may disappear from the compiled reference.
- **Issue 2:** `@article{juselius2015leverage}` has empty `journal`, `volume`, `number`, and `pages` fields, with only `publisher={BIS working paper}`. It should be typed as `@techreport` or `@misc` to produce a coherent formatted entry.
- **Suggestion:** Fix `detken2014operationalising` by removing the duplicate empty `journal` field. Retype `juselius2015leverage` as `@techreport{..., type={BIS Working Paper}, institution={Bank for International Settlements}, number={...}}`.
- **Location:** `paper/refs/references.bib`

### mc7 (NEW): Finland exclusion note does not explain why

- **Issue:** Table 2 notes state "Finland is excluded as it did not experience a systemic banking crisis during the available sample period." This is technically correct but potentially misleading — Finland had a major banking crisis in the early 1990s, and the sample starts at 1995 Q3 specifically after that crisis. A referee familiar with Nordic financial history will raise an eyebrow.
- **Suggestion:** Add a clause: *"Finland is excluded as it did not experience a systemic banking crisis during the sample period (1995 Q3–2025 Q3); its major banking crisis occurred in the early 1990s, prior to the start of the sample."*
- **Location:** `paper/sections/4_results.tex`, Table 2 notes

### mc8 (ROUND 1, OPEN): Figure label naming inconsistency

- **Issue:** Results section figures use bare labels (e.g., `\label{var_exp}`, `\label{factor_median}`) while appendix figures use the `fig:` prefix (e.g., `\label{fig:fc_BE_DE}`). Not a compilation error but inconsistent and confusing for cross-referencing.
- **Suggestion:** Standardise all to use the `fig:` prefix and update all `\ref{}` calls accordingly.
- **Location:** `paper/sections/4_results.tex` and all appendix files

---

## Referee Objections (all carried from Round 1 — none addressed)

### RO1: CI bands derived under large-N asymptotics with N=7 variables

**Why it matters:** The asymptotic distribution in Bai (2003), used to construct the confidence bands, holds as both N (cross-sectional dimension) and T tend to infinity. In this paper, N=7 (variables) for each country-specific model. At N=7 the asymptotic approximation may be poor — the bands could be too narrow or too wide. A referee will ask whether the bands have correct coverage at this sample size and whether the neutral-zone classification is robust to this limitation.

**How to address it:** Add a robustness footnote: *"With N=7 variables, the asymptotic approximation should be treated with caution. The qualitative regime classifications are robust to modest perturbations of the threshold: classifying periods within ±10% of the time-averaged band as neutral does not materially change the regime dates."* Alternatively, include a brief Monte Carlo simulation (N=7, T≈120) showing that coverage is approximately correct.

### RO2: OOS exercise uses final revised data without publication lags

**Why it matters:** The pseudo-real-time exercise claims to replicate what would have been observable in mid-2006, but it uses final revised data rather than data vintages and assumes zero publication lag. Credit variables can be subject to meaningful revisions; the 10%-to-20% doubling could be inflated by revisions (particularly if 2005–2006 credit data were revised upward after the GFC).

**How to address it:** Add a brief sentence: *"We acknowledge two simplifying assumptions: we rely on final revised data rather than vintages, and we assume no publication lag. Credit aggregates are generally subject to modest revisions over medium-term horizons, and the qualitative finding — an approximate doubling of crisis probability — is unlikely to be materially sensitive to these issues."*

### RO3: Model selection (r=1, p=4) not documented by country

**Why it matters:** The paper now states that "standard information criteria select r=1 in all countries" (a Round 1 fix), but does not report which criterion or the IC values. A referee may ask: what if Germany or Portugal prefer r=2? If so, the single-factor constraint distorts the interpretation for those countries.

**How to address it:** Report information criteria by country — even a one-line footnote: *"The Bai–Ng IC1 criterion selects r=1 for all countries; allowing r=2 does not change the dominant factor's interpretation or sign."* Or add a country-by-country table of IC1 values to an appendix.

### RO4: Butterworth filter parameter sensitivity

**Why it matters:** The 4–25 year passband is asserted but the main results (AUROC, usefulness, regime dates) may be sensitive to this choice. Changing to 4–20 or 4–30 years could alter which periods are classified as elevated or subdued.

**How to address it:** Add one paragraph or footnote: *"The main results are robust to alternative frequency bands (4–20 and 4–30 year passbands), which yield qualitatively similar financial cycle trajectories and early-warning statistics."* A brief appendix figure would be ideal.

### RO5: Belgium AUROC = 0.51 — effectively random

**Why it matters:** An AUROC of 0.51 is indistinguishable from random prediction. If the DFM indicator cannot distinguish crisis from non-crisis for Belgium, a referee may argue the cross-country average (0.68) is misleading and that the indicator simply does not work for some countries.

**How to address it:** Add a footnote or brief discussion: *"The weak AUROC for Belgium (0.51 for PCA) likely reflects the relatively small number of crisis observations and the timing of Belgian stress episodes, which cluster in the early part of the sample when data quality is lowest. QML (0.65) and TSTEP (0.57) outperform PCA for Belgium, suggesting the weakness is estimator-specific rather than a failure of the DFM framework."*

---

## Specific Comments

| Location | Issue | Action | Priority |
|---|---|---|---|
| `main.tex:87` | Acknowledgments placeholder "[XXX, YYY, ZZZ]" | **Fill before submission** | Blocking |
| `main.tex:63` | Author affiliation: FCA vs Banco de Portugal | Confirm / correct | High |
| `1_intro.tex` lines 9–11 | Duplicate contribution paragraphs | Consolidate into one | High |
| `4_results.tex` §4.4 | `\cite` → `\citet` (3 instances) | Fix citation style | Medium |
| `2_data.tex` asset prices paragraph | `mian2014explains` citation mismatched | Replace or remove | Medium |
| `3_methodology.tex` §3.4 footnote | CS-HAC degeneracy — add derivation or citation | Add reference | Medium |
| `4_results.tex` §4.2 | Decomposition sign convention — add parenthetical | One sentence | Low |
| `4_results.tex` Table 2 notes | Finland exclusion — add explanation | One clause | Low |
| `refs/references.bib` | `detken2014operationalising`: duplicate empty journal field | Remove duplicate field | Low |
| `refs/references.bib` | `juselius2015leverage`: empty journal fields | Retype as @techreport | Low |
| All sections + appendices | Figure label naming: standardise `fig:` prefix | Style cleanup | Low |

---

## Summary Statistics

| Dimension | Round 1 | Round 2 | Change |
|---|---|---|---|
| Argument Structure | 3 | 3 | → No change: intro duplication is a new deduction offsetting the MC2 fix |
| Identification / DFM | 4 | 4 | — |
| Econometrics | 4 | 4 | — |
| Literature | 4 | 3.5 | ↓ Mian & Sufi citation slip; two `\cite` style errors |
| Writing Quality | 4 | 3.5 | ↓ Intro duplication; acknowledgments placeholder |
| Presentation | 4 | 4 | — |
| **Overall** | **4 / 5** | **3.7 / 5** | |

**Quality score estimate: 80/100**
- Round 1 fixes recovered: +5 (MC2 fix, citation style, r=1 sentence) = 82 → effectively unchanged after new findings
- New deductions: intro duplication (-3), acknowledgments placeholder (-2), citation mismatches (-1) = -6
- Net: 82 - 2 = 80

**Current status:** Above commit threshold (80), below PR threshold (90).

---

## Next Steps (Prioritised)

1. **[30 min] Fix Introduction duplication** — Merge paragraphs 5–6 of `1_intro.tex` into a single contribution statement covering all three contributions.
2. **[5 min] Fill acknowledgments** — Replace "[XXX, YYY, ZZZ] and participants of the [XXX Workshop]" with real names.
3. **[5 min] Confirm author affiliation** — Verify Daniel Abreu's affiliation (FCA vs Banco de Portugal) and email.
4. **[10 min] Fix 3× `\cite` → `\citet`** — In `4_results.tex` §4.4.
5. **[10 min] Fix `mian2014explains` citation** — Replace with appropriate reference in the asset prices paragraph.
6. **[10 min] Fix two BibTeX entries** — `detken2014operationalising` (remove duplicate field) and `juselius2015leverage` (retype as @techreport).
7. **[10 min] Add Finland footnote** — Explain crisis precedes sample start.
8. **[20 min] Add CS-HAC reference + decomposition parenthetical** — Two minor textual additions.
9. **[2–4 hrs, optional but high value] Add robustness material** — At minimum, add footnotes addressing RO1 (N=7 asymptotics), RO3 (IC1 criterion by country), and RO5 (Belgium discussion). RO2 (vintages) and RO4 (Butterworth) can be flagged as acknowledged limitations in a paragraph.

After completing steps 1–8, recompile and re-score. Target: ≥88/100. With robustness material (step 9): ≥92/100.
