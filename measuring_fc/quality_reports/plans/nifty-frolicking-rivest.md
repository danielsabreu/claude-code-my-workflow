# Plan: Move Acknowledgements to Title Footnote

**Status:** COMPLETED  
**Date:** 2026-05-27  
**Context:** Internal colleague review of `paper/main.tex`. First comment: acknowledgements should appear as a footnote on the paper title, not as a standalone block after the abstract.

---

## Current state (`paper/main.tex`)

```latex
\title{\textbf{Measuring the Financial Cycle:\\A Dynamic Factor Model Approach}}
```

After the abstract (lines 85–88), there is a freestanding block:

```latex
\begin{footnotesize}
\noindent
\textit{Acknowledgments:} We thank ...
\end{footnotesize}
```

This renders as a small-font paragraph on the title page below the abstract — not a proper footnote.

---

## Change

**File:** `paper/main.tex`

**Step 1 — attach `\thanks{}` to the title:**

```latex
\title{%
  \textbf{Measuring the Financial Cycle:\\A Dynamic Factor Model Approach}%
  \thanks{We thank António Antunes, Ana Cristina Leal, Pedro Duarte Neves,
  Vítor Oliveira, and Fátima Silva, as well as members of the ECB
  Macroprudential Analysis Group and members of the Joint ECB/ESRB report
  \textit{Using the countercyclical capital buffer to build resilience early
  in the cycle}, for helpful comments. The views expressed in this article
  are those of the authors and do not necessarily represent the positions of
  the Financial Conduct Authority or Prometeia. Any errors are ours.
  Competing interests: the authors declare none.}}
```

**Step 2 — delete the freestanding block** (lines 85–88):

```latex
\begin{footnotesize}
\noindent
\textit{Acknowledgments:} We thank ... [entire block removed]
\end{footnotesize}
```

---

## Result

LaTeX's `\thanks{}` on `\title{}` produces a `*`-marked footnote at the bottom of the title page, which is the standard journal convention for acknowledgements linked to the paper title.

---

## Verification

Run `/compile-paper` after the edit and confirm:
- Title page shows a `*` superscript on the title
- Acknowledgements appear as a footnote at the bottom of page 1
- The freestanding block between the abstract and `\newpage` is gone
