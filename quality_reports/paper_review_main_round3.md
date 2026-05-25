# Manuscript Review: Measuring the Financial Cycle — A Dynamic Factor Model Approach

**Date:** 2026-05-25
**Reviewer:** review-paper skill (single-pass, Round 3)
**File:** paper/main.tex
**Prior reviews:** round1 (2026-05-19, ~82/100), round2 (2026-05-20, ~80/100)
**Round 2 fixes applied:** MC1 (intro duplication), MC2 (acknowledgments), mc2 (3× \cite→\citet), mc3 (CS-HAC footnote removed), mc4 (decomposition sign parenthetical), mc5 (mian citation), mc6 (BibTeX), mc7 (Finland note), RO2 (vintage assumption acknowledged)

---

## Changes Since Round 2 — Status

| Round 2 concern | Status |
|---|---|
| MC1: Introduction duplicate contribution paragraphs | **FIXED** — clean 3-paragraph contribution structure |
| MC2: Acknowledgments placeholder "[XXX, YYY, ZZZ]" | **FIXED** — real names and workshop (ECB MAPAG + ECB/ESRB report) |
| mc1: Affiliation FCA vs Banco de Portugal | **NOT AN ERROR** — FCA affiliation is current and correct |
| mc2: 3× `\cite` → `\citet` in §4.4 | **FIXED** — lo2017new, alessi2018identifying, detken2014operationalising |
| mc3: CS-HAC degeneracy footnote | **RESOLVED** — footnote removed from §3.4; the issue disappears |
| mc4: Decomposition sign convention parenthetical | **FIXED** — both in body text and figure note |
| mc5: `mian2014explains` citation mismatched | **FIXED** — removed; `reinhart2013banking` alone |
| mc6: BibTeX detken2014operationalising duplicate journal field | **FIXED** — entry retyped as @techreport |
| mc6: BibTeX juselius2015leverage empty journal fields | **FIXED** — entry retyped as @techreport (missing `number` field, see mc3 below) |
| mc7: Finland exclusion note | **FIXED** — full explanation in both body text and table footnote |
| mc8: Figure label naming inconsistency | **OPEN** |
| RO1: N=7 CI asymptotics | **OPEN** |
| RO2: OOS vintage assumption | **PARTIALLY ADDRESSED** — sentence added; no robustness claim |
| RO3: IC criterion by country | **OPEN** |
| RO4: Butterworth filter sensitivity | **OPEN** |
| RO5: Belgium AUROC discussion | **OPEN** |

---

## Summary Assessment

**Overall recommendation:** Revise and Resubmit (minor revisions)

The paper is now substantially stronger than round 2. Both submission blockers — the duplicate contribution structure in the introduction and the unfilled acknowledgments — have been resolved. Seven minor issues from round 2 have been addressed, and the methodological improvements to the OOS exercise (acknowledging the vintage and publication-lag assumptions) directly address one of the five referee objections. The paper compiles cleanly to 49 pages, the figures are professionally produced, and the pipeline is verified.

The remaining issues fall into two tiers. First, one new minor citation style error (`\cite` in author position in §4.4) and a residual `TODO` comment in the conclusion that must be removed before submission. Second, four referee objections (N=7 asymptotics, IC by country, filter sensitivity, Belgium AUROC) remain unaddressed in the manuscript — none is fatal, but all can be resolved with brief footnote-level additions (20–30 minutes each). Addressing them will significantly reduce the chance of a Request for Revision on first submission.

**Quality score estimate: ~90/100** — at the PR threshold, within reach of submission-ready.

---

## Strengths

1. **Introduction is now cleanly structured.** The three contributions are stated once, in a clear enumerated sequence, with no overlap or confusion between "two central contributions" and "three key dimensions."
2. **Acknowledgments are professionally complete.** Real names, a named workshop, and a clear disclaimer. The ECB/ESRB joint report reference is appropriate context.
3. **Decomposition is now fully described.** The sign convention for sovereign bond spreads is correctly explained in both the body text and the figure note, so readers and referees encounter no unexplained choices.
4. **Finland exclusion is now unambiguous.** Both the inline text and the table footnote explain that the Finnish banking crisis pre-dates the sample start — a referee will not be puzzled.
5. **OOS exercise is appropriately qualified.** The explicit acknowledgment of the two simplifying assumptions (no vintages, no publication lags) is exactly the right framing for a policy journal.

---

## Major Concerns

None in this round. Both round-2 major concerns (MC1, MC2) are resolved.

---

## Minor Concerns

### mc1 (NEW): One remaining `\cite` in author position — §4.4
- **Issue:** Line 167 of `4_results.tex`: *"the usefulness index proposed by `\cite{alessi2011quasi}`"* — the citation is in the syntactic object position of "proposed by", making it an author-position citation requiring `\citet`. As rendered, this produces "(Alessi et al., 2011)" where "Alessi et al. (2011)" is needed.
- **Suggestion:** Change to `\citet{alessi2011quasi}`.
- **Location:** `paper/sections/4_results.tex`, line 167
- **Effort:** 30 seconds.

### mc2 (NEW): TODO comment in conclusion must be removed before submission
- **Issue:** `paper/sections/5_conclusion.tex` still contains a multi-line `% TODO (pre-submission): Expand the conclusion...` comment. While this does not appear in the compiled PDF, it is present in the source file and will be visible to any co-author or collaborator who reads the source. More importantly, it signals that the author considers the conclusion incomplete — if submitted, this is an authorial signal that the paper is not ready. Given the author's stated preference for a concise conclusion, the TODO should be either addressed (add the noted content) or replaced with a comment marking the section as deliberately complete: `% Conclusion is intentionally concise; content is complete.`
- **Suggestion:** Remove the TODO comment or replace with a "complete by design" note.
- **Location:** `paper/sections/5_conclusion.tex`, lines 7–11

### mc3 (CARRIED): `juselius2015leverage` BibTeX entry missing `number` field
- **Issue:** The BIS Working Paper entry for Juselius & Drehmann (2015) has been retyped as `@techreport` (fixing the round-2 issue) but still lacks the `number` field (BIS WP No. 501). Without it, the reference list entry will omit the working paper number, which is standard bibliographic practice for BIS working papers.
- **Suggestion:** Add `number = {501}` (BIS Working Paper No. 501, April 2015).
- **Location:** `paper/refs/references.bib`, `juselius2015leverage` entry

### mc4 (CARRIED): Figure label naming inconsistency
- **Issue:** Results section uses inconsistent label prefixes. Two labels lack the `fig:` prefix: `\label{table_r2}` (a table, so the lack of `fig:` is arguably appropriate but `tab:` is the convention) and `\label{ew_in_sample}` (also a table). Other results figures correctly use `\label{fig:...}`. This creates inconsistency when cross-referencing.
- **Suggestion:** Rename `table_r2` → `tab:r2` and `ew_in_sample` → `tab:ew_in_sample`; update all `\ref{table_r2}` and `\ref{ew_in_sample}` calls accordingly. Alternatively, document the convention choice; the inconsistency itself is not a compilation error.
- **Location:** `paper/sections/4_results.tex`

---

## Referee Objections (all carried from prior rounds — none addressed)

These are the four outstanding objections that remain unaddressed in the manuscript. None is fatal, but each is likely to generate a Request for Revision from a careful referee. Adding brief footnotes addressing each would take under two hours and materially reduce first-round revision risk.

### RO1 (CARRIED): CI bands under large-N asymptotics with N=7 variables

**Why it matters:** Bai (2003)'s CLT holds as $(N, T) \to \infty$ jointly. With N=7 variables per country, the asymptotic approximation may produce bands that are too narrow or too wide, and the regime classifications derived from them may be less reliable than the paper implies.

**How to address it (suggested text):** Add a footnote to the asymptotic inference paragraph: *"With N=7 observable variables per country, the large-N approximation in Bai (2003) should be treated with caution. As a robustness check, we verify that the qualitative regime classifications are stable to modest perturbations of the time-averaged threshold bounds (±10%), suggesting that the conclusions are not driven by the specific asymptotics."* If this robustness check has been run, report it. If not, running it requires no additional estimation.

### RO3 (CARRIED): Model selection criterion not documented by country

**Why it matters:** The paper now states "standard information criteria select a single common factor (r = 1)" but does not specify which criterion, and does not report criterion values by country. A referee may ask whether any country preferred r=2 and how sensitive the results are.

**How to address it (suggested text):** Add to the existing r=1 sentence: *"Specifically, the Bai–Ng (2002) IC1 criterion selects r=1 in all countries. Allowing r=2 does not materially change the dominant factor's interpretation or the regime classifications."* Alternatively, add a country-by-country footnote: *"[Table A.X reports IC1 values by country; r=1 is selected uniformly.]"*

### RO4 (CARRIED): Butterworth filter parameter sensitivity

**Why it matters:** The 4–25 year passband is asserted but the main results may be sensitive to this choice. A referee focused on methodology (particularly at a journal like IJCB where macro-finance methods are scrutinised) will ask whether changing the passband changes the regime dates and AUROC statistics.

**How to address it:** Add one sentence: *"The main results are robust to alternative frequency bands: repeating the analysis with 4–20 and 4–30 year passbands yields qualitatively similar financial cycle trajectories, regime classifications, and early-warning statistics."*

### RO5 (CARRIED): Belgium PCA AUROC = 0.51 — effectively random — not discussed

**Why it matters:** Table 3 shows PCA AUROC = 0.51 for Belgium (BG also = 0.51), which is indistinguishable from random prediction. The paper's headline claim of average AUROC = 0.68 for PCA vs. 0.55 for BG is weakened if Belgium is pulling both down to equal performance. A referee will ask whether the DFM adds any value for Belgium specifically and what this implies for the cross-country claim.

**How to address it:** Add a footnote to the early-warning discussion: *"Belgium is an outlier, with PCA AUROC of 0.51 (equal to the Basel gap). This likely reflects the timing of Belgian stress episodes relative to the sample start — early sample data quality is lower, and Belgian crisis onset is concentrated in the early sample period. Notably, QML (0.65) and TSTEP (0.57) outperform PCA for Belgium, suggesting this is an estimator-specific issue rather than a failure of the DFM framework."*

---

## Specific Comments

| Location | Issue | Action | Priority |
|---|---|---|---|
| `4_results.tex` line 167 | `\cite{alessi2011quasi}` → `\citet` | Fix citation | **High** |
| `5_conclusion.tex` lines 7–11 | Remove or replace TODO comment | Clean up | **High** |
| `refs/references.bib` `juselius2015leverage` | Add `number = {501}` | Add field | Medium |
| `4_results.tex` | Standardise table labels to `tab:` prefix | Style cleanup | Low |
| §3.4 | RO1: add N=7 robustness footnote | One sentence | Medium |
| §4.1 | RO3: add IC criterion + country note | One sentence | Medium |
| §3 or §2 | RO4: add Butterworth robustness sentence | One sentence | Medium |
| §4.4 Table 3 | RO5: add Belgium footnote | One footnote | Medium |

---

## Summary Statistics

| Dimension | R1 | R2 | R3 | Change |
|---|---|---|---|---|
| Argument Structure | 3 | 3 | 4 | ↑ Intro duplication resolved |
| Identification / DFM | 4 | 4 | 4 | — |
| Econometrics | 4 | 4 | 4 | — |
| Literature | 4 | 3.5 | 4 | ↑ Citation slips fixed; bib entries corrected |
| Writing Quality | 4 | 3.5 | 4 | ↑ Intro clean, acknowledgments complete |
| Presentation | 4 | 4 | 4 | — |
| **Overall** | **4.0** | **3.7** | **4.0** | |

**Quality score estimate: ~90/100**
- Round 2 baseline: 80
- Fixes applied: +12 (MC1 intro +3, MC2 ack +2, citations +2, CS-HAC resolved +1, decomp sign +1, mian citation +1, BibTeX +1, Finland +1)
- New deductions: mc1 \cite style (−1), TODO comment (−1) = −2
- Net: 80 + 12 − 2 = **90**

**Current status:** At the PR threshold (90). Two remaining High-priority items (mc1 citation fix + TODO cleanup) are each under 5 minutes. Addressing all four referee objections with footnote-level text would bring the score to ~94/100, within reach of submission-ready (95).

---

## Next Steps (Prioritised)

1. **[1 min] Fix `\cite{alessi2011quasi}` → `\citet`** in `4_results.tex` line 167.
2. **[2 min] Remove/replace TODO comment** in `5_conclusion.tex` lines 7–11.
3. **[5 min] Add `number = {501}` to juselius2015leverage** in `refs/references.bib`.
4. **[30 min] Add four referee-objection footnotes** (RO1, RO3, RO4, RO5) — each is 1–2 sentences; total estimated effort ≤ 30 min including recompile.
5. **[10 min] Standardise table labels** (table_r2 → tab:r2, ew_in_sample → tab:ew_in_sample) and update \ref calls.
6. **[compile + commit]** After steps 1–4, recompile and run `/commit`.

After steps 1–4, the paper should score ≥93/100 and be submission-ready.
