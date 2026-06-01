# MEMORY.md — phd_thesis

Cross-session memory for the PhD thesis project. Updated as new learnings emerge. Keep under 200 lines.

---

## Project Identity

- **Institution**: ISEG — Instituto Superior de Economia e Gestão, Universidade de Lisboa
- **Thesis**: Three-paper dissertation — nonlinear/nonstationary dynamic factor models
- **Candidate**: Daniel Abreu (Financial Conduct Authority, London)

---

## Paper Notes

### Financial Cycle Paper (Paper 2)
- Co-author: Ivan De Lorenzo Buratta (Prometeia, Bologna)
- Target journals: IJCB or Economic Policy (Oxford)
- Status: Pre-submission (as of 2026-06-01)
- [LEARN:style] Conclusion is intentionally short — do not flag in reviews
- [LEARN:style] Claim about 17 EEA CCyB jurisdictions is intentionally uncited — do not flag
- [LEARN:framing] Measurement paper: contributions are in index construction and early-warning validation, NOT causal identification. Never flag absence of IV/DiD as a weakness.

---

## Technical Invariants

- [LEARN:latex] This thesis uses `biblatex + biber` (`backend=biber` in Thesis.tex). Always use biber; bibtex will silently fail to resolve citations.
- [LEARN:latex] Papers are subfiles (`\documentclass[Thesis.tex]{subfiles}`); each compiles standalone via XeLaTeX.
- [LEARN:structure] All paper source files live under `Thesis_20251001/`. There is no `paper/` folder; skip the default `paper/main.tex` path.

---

## Workflow Invariants

- Defense preparation materials live in `discussion_prep/` (Q&A and prep notes)
- Erratum lives in `erratum/`
- Beamer defense slides live in `slides/`
