# Plan: PhD Thesis Workflow Bootstrap + Defense Preparation

**Status:** COMPLETED  
**Date:** 2026-06-01  
**Author:** Claude (plan-first workflow)

---

## Context

The `phd_thesis/` project has the full `.claude/` infrastructure but four gaps need closing before productive work can begin:

1. No `CLAUDE.md` or `MEMORY.md` at the project root — skills and agents have no project context.
2. `compile-paper` skill uses `bibtex`, but this project uses `biblatex + biber` — citations silently fail.
3. Target journals (IJCB, Economic Policy) are absent from the referee calibration profiles.
4. Three defense preparation deliverables are requested: Beamer slide deck, erratum, and Q&A document.

**Three-paper thesis structure (ISEG — Universidade de Lisboa):**
| # | Paper | Method | Key result |
|---|-------|--------|------------|
| 1 | Smooth Transition Factor Model (STFM) | NLS + PCA + logistic transition | 3-factor model improves US macro forecasts |
| 2 | Non-stationary DFM with Threshold Cointegration | Threshold/band VECM + grid search | Global yield curve shows discontinuous adjustment |
| 3 | Financial Cycle Measurement | DFM extracting common latent factor | Early-warning for crises; neutral risk thresholds |

---

## Files to Create / Modify

| Action | File | Task |
|--------|------|------|
| CREATE | `CLAUDE.md` | Config |
| CREATE | `MEMORY.md` | Config |
| MODIFY | `.claude/skills/compile-paper/SKILL.md` | Config |
| MODIFY | `.claude/references/journal-profiles.md` | Config |
| CREATE | `slides/defense_slides.tex` | Slides |
| CREATE | `erratum/erratum.md` | Erratum |
| CREATE | `discussion_prep/defense_qa.md` | Q&A |

---

## Task 1: Configuration Bootstrap

### 1a. Create `CLAUDE.md`

Content:
- **Project identity**: PhD thesis, ISEG – Universidade de Lisboa, 3-paper compilation
- **Three papers** with exact paths, status, target journals, bibliography files:
  - Paper 1 — *Smooth Transition Factor Model*: `Thesis_20251001/Smooth_transition_factor_model_paper/main.tex`, bib: `references.bib`
  - Paper 2 — *Non-stationary DFM with Threshold Cointegration*: `Thesis_20251001/Non-stationary dynamic factor model with threshold cointegration/main.tex`, bib: `FactorCointegration.bib`
  - Paper 3 — *Financial Cycle*: `Thesis_20251001/Financial cycle/main.tex`, co-author Ivan De Lorenzo Buratta (Prometeia), target IJCB / Economic Policy, pre-submission, bib: `REFERENCES.bib`
- **Master file**: `Thesis_20251001/Thesis.tex` (subfiles; each paper's `main.tex` compiles standalone)
- **Bibliography backend**: `biblatex + biber` (NOT bibtex); `refsection=chapter`
- **Compile instructions**: `/compile-paper "Thesis_20251001/Financial cycle/main.tex"`; full thesis: `/compile-paper "Thesis_20251001/Thesis.tex"`
- **Key invariant**: never use `bibtex` — always `biber`
- **Skills quick reference**: paths adapted to this project

### 1b. Create `MEMORY.md`

Seeded with:
- Institution: ISEG – Universidade de Lisboa
- Co-author: Ivan De Lorenzo Buratta (Prometeia) on Paper 3
- Target journals: IJCB, Economic Policy (Paper 3)
- Bibliography backend: biber (never bibtex)
- Financial cycle paper: measurement paper — not causal identification; do not flag absence of IV/DiD
- Conclusion intentionally short (do not flag)
- 17 EEA CCyB claim intentionally uncited (do not flag)
- Defense preparation materials live in `discussion_prep/`

### 1c. Update `compile-paper` skill — biber detection

Modify Step 2 of `.claude/skills/compile-paper/SKILL.md`. Replace `bibtex "$TEX_BASE"` with:

```bash
# Detect bibliography backend: use biber for biblatex projects
if grep -ql "biblatex" "${TEX_BASE}.tex" 2>/dev/null || \
   grep -ql "biblatex" "$(dirname "${TEX_BASE}.tex")"/*.tex 2>/dev/null; then
    biber "$TEX_BASE"
else
    bibtex "$TEX_BASE"
fi
```

Add bullet to "Important" section: "For biblatex projects (detectable by `\usepackage{biblatex}` in the preamble), `biber` replaces `bibtex` in Step 2."

### 1d. Add journal profiles — IJCB and Economic Policy

Append to `.claude/references/journal-profiles.md`:

**IJCB (International Journal of Central Banking)**
- Scope: monetary policy, financial stability, systemic risk measurement, macroprudential tools
- Accepts DFM/factor models as standard; robustness to factor selection and country coverage is load-bearing
- Policy hook required: results must speak to macroprudential calibration or monetary policy
- Domain referee weights: MEASUREMENT 0.30, POLICY 0.25, CREDIBILITY 0.20, STRUCTURAL 0.15, THEORY 0.05, SKEPTIC 0.05
- Methods referee: robustness/sensitivity (factor number, country sample, vintage, bandwidth) — 40% weight
- Typical desk-reject: no policy hook; purely theoretical; no comparison with BIS/ECB indicators
- Table format: standard; SE in parentheses; stars optional

**Economic Policy (Oxford)**
- Scope: policy-relevant empirical economics, EU/OECD focus; broad readership (economists + policymakers)
- MANDATORY: non-technical summary section ("Panel discussion" format); "so what" must be answerable to non-specialist
- Policy hook must be front-loaded; pure methodology does not pass desk review
- Domain referee weights: POLICY 0.40, CREDIBILITY 0.20, MEASUREMENT 0.20, STRUCTURAL 0.10, THEORY 0.05, SKEPTIC 0.05
- Methods referee: lighter than top-5; robustness checked but not exhaustive
- Typical desk-reject: too technical without policy payoff; no EU/global policy angle
- Table format: accessible; footnotes for technical details

---

## Task 2: Beamer Defense Slides

**Output:** `slides/defense_slides.tex`  
**Length:** ~30 slides (1 min/slide, 30 min total)  
**Audience:** PhD committee at ISEG  
**Preamble:** standard Beamer (Warsaw or Madrid theme, no exotic packages); self-contained (no subfiles dependency)

### Slide structure

| Section | Slides | Content |
|---------|--------|---------|
| Title + overview | 2 | Thesis title, institution, date; map of 3 papers and common thread (nonlinearity + factor models) |
| Paper 1: STFM | 7 | Motivation → Model → Estimation → Linearity test → Monte Carlo → Empirical (FRED-QD) → Key takeaway |
| Paper 2: Nonstationary DFM | 7 | Motivation → Model setup → Threshold/band VECM → Estimation → MC evidence → Yield curve result → Key takeaway |
| Paper 3: Financial Cycle | 8 | Motivation → Limitations of credit gap → DFM setup → Country evidence → Early warning → Thresholds → Policy link → Key takeaway |
| Conclusions | 3 | Cross-paper contribution, methodological advances, future research |
| Q&A placeholder | 1 | Blank "Thank you / Questions" slide |

**Total: 28 slides** (leave breathing room for introductory context at each section)

**Implementation approach:** Write the `.tex` file directly in Beamer, using `\begin{frame}` blocks. Pull key equations and findings from the paper source files. Use `itemize` for bullet points; include the most important figure reference from each paper (cite the PDF filenames that already exist in the repo).

---

## Task 3: Erratum

**Output:** `erratum/erratum.md`  
**Source:** Read `.tex` source files for all 3 papers (not the PDF — source is authoritative for corrections)  
**Approach:** Spawn the `proofreader` agent on each paper in sequence; synthesize findings into a structured erratum

**Erratum format:**
```
## Erratum — [Paper Title]
| Location | Type | Found | Correction |
|----------|------|-------|------------|
| Chap 2, eq. (3) | Math notation | ... | ... |
| p. 14, ¶2 | Typo | "recieve" | "receive" |
```

**Scope per paper:** Introduction, body chapters, appendices (skip bibliography formatting)  
**Types to flag:** Typos, grammatical errors, inconsistent notation, undefined symbols, broken cross-references, equation numbering gaps, missing/extra spaces around math, inconsistent capitalization of section titles

---

## Task 4: Defense Q&A Document

**Output:** `discussion_prep/defense_qa.md`  
**Format:** Structured Q&A with category headers; each question has a suggested answer (3-5 sentences)

**Question categories and counts:**

| Category | Count | Example scope |
|----------|-------|---------------|
| Technical — STFM | 5 | Identification of transition function; consistency of estimator; choice of logistic vs exponential |
| Technical — Nonstationary DFM | 5 | Unit root pre-testing; grid search sensitivity; band vs threshold model choice |
| Technical — Financial Cycle | 5 | Factor selection (1 factor vs k); country homogeneity; out-of-sample EWS performance |
| Policy relevance | 5 | Why DFM over credit-to-GDP gap; CCyB practical use; ESRB/ECB compatibility |
| Literature positioning | 5 | How STFM differs from Bai & Ng (2002); connection to Bernanke et al.; BIS cycle vs your cycle |
| General methodology | 4 | Why 3 papers in one thesis; common methodological thread; limitations of factor models in general |
| Cross-paper questions | 3 | Do the 3 papers speak to each other? Could you combine them? What's next? |

**Total: ~32 questions** with suggested answers

**Implementation:** Draw on my current understanding of all 3 papers (from the context gathered in this session) plus the paper source files for specific numbers, citations, and technical details.

---

## Execution Sequence

Tasks are ordered by dependency:

1. **Task 1 (Config)** — no reading required; execute first, creates foundation
2. **Task 2 (Slides)** — read paper source files during writing; run `/compile-latex` at end to verify
3. **Task 3 (Erratum)** — spawn proofreader agent per paper; synthesize
4. **Task 4 (Q&A)** — can run in parallel with Task 3 once paper content is read

Tasks 3 and 4 can overlap since they both just need read access to the paper source files.

---

## Verification

| Deliverable | Check |
|-------------|-------|
| CLAUDE.md | No placeholder text remains; paths resolve to existing files |
| MEMORY.md | Consistent with memory index; no conflicting facts |
| compile-paper | Biber detection works: grep confirms `biblatex` in Thesis.tex |
| Journal profiles | IJCB and Economic Policy entries present and follow existing schema |
| Slides | `xelatex defense_slides.tex` compiles without errors; PDF renders ~28 slides |
| Erratum | At least one real finding per paper (if zero findings, re-check source carefully) |
| Q&A | All 7 categories present; answers cite specific paper claims (not generic) |

---

## Out of scope

- R scripts: don't exist yet; `/review-r`, `/data-analysis`, `/audit-reproducibility` deferred
- Financial cycle paper standalone PDF: not compiled (Financial cycle/main.tex depends on full Thesis.tex preamble for some commands — full-thesis compile is the safe path)
- Slides for individual papers (not the defense deck): deferred
