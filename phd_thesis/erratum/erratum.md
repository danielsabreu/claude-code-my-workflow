# Erratum — Three Essays on Factor Models

**Daniel Abreu, PhD Thesis**  
**ISEG – Lisbon School of Economics and Management, Universidade de Lisboa**  
**Generated: 2026-06-01**

---

> **How to use this document.** Errors are listed by paper and by severity. Fix CRITICAL issues before any submission or final deposit. MAJOR issues affect meaning and should be corrected before the defense copy is printed. MINOR issues (typos, punctuation, duplicates) can be batched and corrected last.

---

## Summary

| Category | Count |
|----------|-------|
| **Total errors** | **59** |
| Critical (technical / mathematical) | 6 |
| Major (grammar / missing words affecting meaning) | 22 |
| Minor (typo / punctuation / duplicate word / style) | 31 |

**Critical issues at a glance:**
- Issue 6 — $c_t$ vs. $c$: threshold written as time-varying in one equation (Paper 1)
- Issue 22 — $\hat{\gamma}$ reported as 0.955 in text, 0.995 in figure caption (Paper 1)
- Issue 46 — Pervasiveness condition sums to $m_r$ instead of $N_r$ (Paper 3)
- Issue 47 — $\xi$ subscripts conflate factor-dimension and group-index notation (Paper 3)
- Issue 50 — SVD dimensions: $\mathbf{V}$ described with wrong dimensions (Paper 3)
- Issue 54 — Portuguese editorial comment left in active LaTeX source (Paper 3)

---

## Paper 1: Smooth Transition Factor Model

| # | Location | Type | Found | Correction |
|---|----------|------|-------|------------|
| 1 | `Chapters/1introduction.tex`, line 11 | Typo | "the typical converge rate" | "the typical **convergence** rate" |
| 2 | `Chapters/1introduction.tex`, line 13 | Grammar | "the need of two distinct sets of factors … in pre and post break subsamples" | "the need **for** two distinct sets … in pre**-** and post**-**break subsamples" (wrong preposition; missing hyphens in compound modifier) |
| 3 | `Chapters/1introduction.tex`, line 15 | Grammar | "the proposal of linearity test against" | "the proposal of **a** linearity test against" (missing article) |
| 4 | `Chapters/1introduction.tex`, line 19 | Grammar | "Although, the nonparametric approach" | "Although the nonparametric approach" (spurious comma after "Although") |
| 5 | `Chapters/1introduction.tex`, line 21 | Grammar | "section 8 present the empirical application" | "section 8 **presents** the empirical application" (subject–verb agreement) |
| **6** | `Chapters/2representation.tex`, line 25 | **CRITICAL — notation** | "values of $s_t$ higher than $c_t$" | "values of $s_t$ higher than $c$" (threshold is a constant $c$, not time-varying $c_t$; the subscript $t$ is incorrect and implies a moving threshold) |
| 7 | `Chapters/3estimation.tex`, line 23 | Grammar | "A common recommendation in literature" | "A common recommendation in **the** literature" (missing article) |
| 8 | `Chapters/3estimation.tex`, line 55 | Grammar | "associated to its largest $r$ eigenvalues" | "associated **with** its largest $r$ eigenvalues" (wrong preposition) |
| 9 | `Chapters/3estimation.tex`, line 75 | Grammar | "convergence to a local minima" | "convergence to a local **minimum**" ("minima" is plural; context needs singular) |
| 10 | `Chapters/7finalremarks.tex`, line 3 | Grammar | "we follow \citet{chen2014detecting} regression-based LM tests to the smooth transition context" | "we **adapt** \citet{chen2014detecting}'s regression-based LM tests to the smooth transition context" (missing possessive; "follow … tests to" is ungrammatical) |
| 11 | `Chapters/7finalremarks.tex`, line 5 | Missing word | "A smooth transition factor model with provides a good fit" | "A smooth transition factor model with **three factors** provides a good fit" (number of factors omitted after "with") |
| 12 | `Chapters/7finalremarks.tex`, line 5 | Grammar | "to contribute empirical analysis and forecasting" | "to contribute **to** empirical analysis and forecasting" (missing preposition) |
| 13 | `Chapters/5montecarlo.tex`, line 45 | Notation | In commented block: "$\beta_{f1}=\beta_{e2}=0.8$" | Mismatched subscripts — left side uses index 1, right side uses index 2. Correct to "$\beta_{f2}=\beta_{e2}=0.8$" |
| 14 | `Chapters/5montecarlo.tex`, line 84 | Grammar | Sentence starting "Let … , the innovations are distributed" | Dangling participle / comma splice. Split into two sentences: "Let … . The innovations are distributed as …" |
| 15 | `Chapters/5montecarlo.tex`, line 99 | Grammar | "sampled from an uniform distribution" | "sampled from **a** uniform distribution" (article "a" before consonant sound) |
| 16 | `Chapters/5montecarlo.tex`, line 122 | Punctuation | "we simulate a linear factor model with $r =2$" (no full stop before equation) | Add full stop: "…with $r=2$." |
| 17 | `Chapters/5montecarlo.tex`, line 137 | Grammar | "does not seems to be very impactful" | "does not **seem** to be very impactful" (incorrect verb form after "does not") |
| 18 | `Chapters/5montecarlo.tex`, line 141 | Missing word | "the power of the test notably higher" | "the power of the test **is** notably higher" (missing verb) |
| 19 | `Chapters/6empiricalapplication.tex`, line 7 | Spurious word | "variables with that are available" | "variables **that** are available" (remove "with") |
| 20 | `Chapters/6empiricalapplication.tex`, line 11 | Duplicate word | "which has a now a long tradition" | "which **now has** a long tradition" (duplicate "a"; wrong word order) |
| 21 | `Chapters/6empiricalapplication.tex`, line 15 | Logical error | "the linear $IC_1$ … suggests $\tilde{r}=6$, which is consistent with the idea that capturing regime-switching dynamics typically requires roughly twice as many linear factors" | The logic is inverted: the *linear* criterion over-counts because it cannot distinguish regime shifts from additional factors. Rephrase: "…$\tilde{r}=6$, consistent with the known result that ignoring regime shifts inflates the estimated number of factors." |
| **22** | `Chapters/6empiricalapplication.tex`, line 21 vs. figure caption | **CRITICAL — inconsistency** | $\hat{\gamma}=0.955$ in text; $\hat{\gamma}=0.995$ in figure note | One of these is a transcription error. Verify against estimation output and correct both places to the same value. |
| 23 | `Chapters/6empiricalapplication.tex`, table notes | Notation | Table header abbreviation "Dur. Cons." vs. note "Dur. Goods denotes Durable Consumer Goods" | Inconsistent abbreviation. Choose one form and use it consistently in both header and note. |

---

## Paper 2: Financial Cycle Measurement

| # | Location | Type | Found | Correction |
|---|----------|------|-------|------------|
| 24 | `1. INTRO.tex`, line 5 | Citation style | Inline citations used as parenthetical: should use `\citep{}` not `\citet{}` | Change `\citet{bernanke1999financial}`, `\citet{kiyotaki1997credit}`, `\citet{he2013intermediary}` to `\citep{}` where not used as grammatical subjects |
| 25 | `1. INTRO.tex`, line 7 | Duplicate citation | `\citet{menden2017dissecting}` appears twice in same sentence | Remove the duplicate citation key |
| 26 | `1. INTRO.tex`, line 9 | Wrong word | "useful to informal macroprudential policy" | "useful to **inform** macroprudential policy" ("informal" → "inform") |
| 27 | `1. INTRO.tex`, line 9 | Grammar | "the proposed measures exhibits useful" | "the proposed measures **exhibit** useful" (subject–verb agreement: plural "measures") |
| 28 | `2. DATA.tex`, line 25 | Duplicate word | "this transformation is more more suitable" | "this transformation is more suitable" (remove duplicate "more") |
| 29 | `2. DATA.tex`, line 39 | Wrong word | "To avoid conflating low-term movements" | "To avoid conflating **low-frequency** movements" ("low-term" is not standard) |
| 30 | `3. METHODOLOGY.tex`, line 33 | Grammar | "a hybrid approach that combine" | "a hybrid approach that **combines**" (subject–verb agreement) |
| 31 | `3. METHODOLOGY.tex`, line 96 | Citation note | EM algorithm cited as \citet{watson1983alternative} | The standard reference for EM in state-space models is \citet{shumway1982approach}; for the general EM it is \citet{dempster1977maximum}. Verify the author's intended reference. |
| 32 | `4. RESULTS.tex`, line 18 | Grammar | "the financial cycle stronger is more closely related to credit" | "the financial cycle **is more strongly** related to credit" (misplaced modifier) |
| 33 | `4. RESULTS.tex`, line 81 | Grammar | "have played an significant role" | "have played **a** significant role" (article "a" before consonant "s") |
| 34 | `4. RESULTS.tex`, line 92 | Grammar | "neither elevated or subdued" | "neither elevated **nor** subdued" (correlative conjunction: "neither … nor") |
| 35 | `4. RESULTS.tex`, line 131 | Duplicate word | "It serves serves as the recommended" | "It **serves** as the recommended" (remove duplicate) |
| 36 | `4. RESULTS.tex`, line 133 | Wrong phrase | "the area under the operating receiver curve (AUROC)" | "the area under the **receiver operating characteristic** curve (AUROC)" (standard terminology; correct order) |
| 37 | `4. RESULTS.tex`, line 133 | Grammar | "a global measure of accuracy and plot relates" | "a global measure of accuracy and **plots**" (wrong verb form; "AUROC … plots") |
| 38 | `4. RESULTS.tex`, line 147 | Duplicate word | "the policymaker is is less averse" | "the policymaker **is** less averse" (remove duplicate "is") |
| 39 | `4. RESULTS.tex`, line 147 | Grammar | "we consider balance preferences" | "we consider **balanced** preferences" ("balance" → "balanced") |

---

## Paper 3: Non-stationary DFM with Threshold Cointegration

| # | Location | Type | Found | Correction |
|---|----------|------|-------|------------|
| 40 | `main.tex`, line 47 | Grammar | "group r-specific variable" | "group-$r$-specific variable" or rephrase as "the variable $x_{r,it}$ belonging to group $r$" |
| 41 | `main.tex`, line 61 | Notation inconsistency | RHS of equation: $\boldsymbol{\Lambda}^*\boldsymbol{F}_{r,t}^*$ lacks subscript $r$ on $\boldsymbol{\Lambda}^*$ while $\boldsymbol{\Gamma}_r^*$ retains it | Change to $\boldsymbol{\Lambda}_r^*$ for consistency |
| 42 | `main.tex`, line 71 | Grammar | "normalisations of the factors space" | "normalisations of the **factor** space" (remove spurious plural "s") |
| 43 | `main.tex`, line 71 | Grammar | "used as the principle for the estimation" | "used as the **criterion** for the estimation" ("principle" → "criterion"; also add "objective function" after "least squares") |
| 44 | `main.tex`, line 75 | Punctuation | "Since, differencing removes persistent components" | "Since differencing removes persistent components" (remove spurious comma after "Since") |
| **45** | `main.tex`, Assumption 2b | **CRITICAL — technical** | Pervasiveness condition: $\frac{1}{m_r}\sum_{i=1}^{m_r} \boldsymbol{\gamma}_{r,i}\boldsymbol{\gamma}_{r,i}' \to \boldsymbol{\Sigma}_{\gamma_r}$ | Summation limit should be $N_r$ (number of units in group $r$), not $m_r$ (number of group-specific factors). Change to $\frac{1}{N_r}\sum_{i=1}^{N_r}$ |
| **46** | `main.tex`, Assumption 3c | **CRITICAL — notation** | $\mathbb{E}(\xi_{m_0,it}\xi_{m_r,jt})$ — subscripts $m_0, m_r$ conflate factor-dimension parameters with unit/group indices | Re-index with group labels: $\mathbb{E}(\xi_{r_1,it}\xi_{r_2,jt})$ or similar; clearly separate the "group" index from the "dimension" parameter |
| 47 | `main.tex`, line 181 | Grammar | "allows to effectively separate" | "allows **one** to effectively separate" (or "allows the effective separation of") |
| 48 | `main.tex`, line 213 | Punctuation | "Stack … $\boldsymbol{x}_{r,t}$ $r=1,...R$" | "Stack … $\boldsymbol{x}_{r,t}$, $r=1,\ldots,R$" (add comma; use `\ldots`) |
| **49** | `main.tex`, line 217 | **CRITICAL — technical** | SVD description: "$\boldsymbol{V}$ is $T \times N$" | For $\boldsymbol{X} = \boldsymbol{U}\boldsymbol{S}\boldsymbol{V}'$, $\boldsymbol{V}$ is $N \times N$ (full) or $N \times \min(T,N)$ (thin). The stated dimension "$T \times N$" corresponds to $\boldsymbol{V}'$, not $\boldsymbol{V}$. Correct the dimension statement to match the SVD variant used. |
| 50 | `main.tex`, line 234 | Grammar | "Let $\boldsymbol{\mathcal{F}}_t$ denote the stacked vector of all group-specific factors $Q=\sum_{r=1}^R m_r$" | Add "where $Q=\sum_{r=1}^R m_r$ is its dimension" (the definition of $Q$ reads as if it equals the vector) |
| 51 | `main.tex`, line 267 | Grammar | "particularly useful to model asymmetries in the adjustment towards equilibrium" | "particularly useful to model asymmetries in the adjustment **toward** equilibrium" (choose one spelling and use consistently throughout) |
| 52 | `main.tex`, line 303 | Notation | In equation: "$\Phi_{2i}$" (no comma between subscripts) | "$\Phi_{2,i}$" (add comma for consistency with $\Phi_{j,i}$ elsewhere) |
| **53** | `main.tex`, line 539 | **CRITICAL — editorial note left in source** | "Isto pode apagar-se?" | This Portuguese comment ("Can this be deleted?") is inside active LaTeX source. **Remove before compiling for submission or deposit.** |
| 54 | `main.tex`, line 421 | Technical | In Remark: "for all $\mathbf{x}, \mathbf{y} \in \mathbb{R}^R$" — dimension is $R$ | The companion matrix dimension is $Qp$, not $R$. Correct to $\mathbb{R}^{Qp}$ to match the definition of $\mathcal{A}_j$ above |

---

## Thesis Introduction and Conclusion

| # | Location | Type | Found | Correction |
|---|----------|------|-------|------------|
| 55 | `thesis_intro.tex`, line 17 | Duplicate citation | `\citep{su2017time,su2017time}` — same key cited twice | Remove the duplicate `su2017time` from the citation list |
| 56 | `conclusion.tex`, line 5 | Style | "With the advancement of data collection capability" | "With **advances in data collection**" (more natural phrasing for academic conclusion) |
| 57 | `conclusion.tex`, line 7 | Style | "often predicted by economic theory and observed in practice" | "often predicted by economic theory and **frequently** observed in practice" (minor formality improvement) |

---

## Critical Issues — Detail Notes

### Issue 6 — Threshold written as $c_t$ instead of $c$ (Paper 1)

In `2representation.tex` line 25, the location parameter of the logistic transition function is written as $c_t$ (with a time subscript), but the model defines $c$ as a constant parameter. This is not just a notation inconsistency — it implies the threshold moves over time, which would change the model interpretation entirely. Verify whether this is a typo or an intentional generalisation (if intentional, the estimation section and Monte Carlo must also reflect a time-varying threshold).

### Issue 22 — $\hat{\gamma}$ discrepancy (Paper 1)

The estimated smoothness parameter is reported as $\hat{\gamma}=0.955$ in the text (line 21 of `6empiricalapplication.tex`) and $\hat{\gamma}=0.995$ in the figure caption for the transition function plot. These two numbers differ enough ($\sim4\%$) that one must be a transcription error. Check the estimation output directly and correct both occurrences to the same value.

### Issue 45 — Pervasiveness condition (Paper 3)

In Assumption 2(b), the pervasiveness condition on global loadings $\boldsymbol{\gamma}_{r,i}$ sums over $i=1,\ldots,m_r$ (the number of group-specific factors), but the correct index should run over $i=1,\ldots,N_r$ (the number of cross-sectional units in group $r$). The standard pervasiveness condition in factor models (Chamberlain–Rothschild, Bai–Ng) sums over units, not over the factor dimension. This is a technical inaccuracy in the assumption statement.

### Issue 46 — Conflated notation in Assumption 3 (Paper 3)

The subscripts $m_0$ (number of global factors) and $m_r$ (number of group-$r$ factors) are used on the idiosyncratic error $\xi$ in Assumption 3(c), making it appear as if the error is indexed by the factor-dimension parameters rather than by the group and unit indices. Re-index with distinct symbols (e.g., $r_1, r_2$ for groups; $i, j$ for units within groups) to eliminate the ambiguity.

### Issue 49 — SVD dimension mismatch (Paper 3)

The algorithm description states "$\boldsymbol{V}$ is $T \times N$", but in the standard SVD $\boldsymbol{X} = \boldsymbol{U}\boldsymbol{S}\boldsymbol{V}'$, $\boldsymbol{V}$ is always $N \times K$ (where $K = \min(T,N)$ for thin SVD or $K = N$ for full SVD). The $T \times N$ dimension corresponds to $\boldsymbol{V}'$ (the transpose), not $\boldsymbol{V}$ itself. Confirm which convention is being used and correct the stated dimensions accordingly.

### Issue 53 — Portuguese editorial comment in source (Paper 3)

The phrase "Isto pode apagar-se?" (Portuguese: "Can this be deleted?") appears at line 539 of `main.tex` inside the active LaTeX body, not within a comment. It will appear verbatim in the typeset output. **This must be removed before the thesis is deposited or printed.**
