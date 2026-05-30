# Panel Figures + tikzDevice Integration
**Status:** DRAFT  
**Date:** 2026-05-17

---

## Context

The pipeline now generates 6 main paper figures (PNG). Three gaps remain:
1. **Appendix panels not generated** — scripts 02/03 don't produce the 15 individual-country panel figures needed for Appendices A, B, C (currently the old 2024 Q3 PNGs from `old_overleaf` are still in `Figures/`)
2. **Figures are raster PNGs** — user wants tikzDevice output (.tikz files) so LaTeX renders them with the document's own fonts, giving perfect typographic consistency
3. **LaTeX formatting** — appendix figures have no captions, no country labels, and loose float placement; needs a clean publication-quality structure

**Outcome:** All 21 figures (6 main + 15 panels) regenerated as tikzDevice `.tikz` files; LaTeX document restructured so appendices are properly captioned and formatted; paper compiles cleanly from a single XeLaTeX pass (bibtex + 2 more passes for references).

---

## Design decisions

| Decision | Choice | Reason |
|---|---|---|
| tikzDevice format | `standAlone = FALSE` | Files are `\input{}`'d into the document, which compiles them with the document's XeLaTeX engine and fonts |
| Country ordering | Alphabetical: BE, DE, ES, FI, FR, GB, IT, NL, PT, SE | Consistent and systematic |
| Panel pairing | (BE, DE), (ES, FI), (FR, GB), (IT, NL), (PT, SE) | 5 panels × 2 countries each |
| Panel layout | patchwork: 2 countries stacked vertically per tikz file | Self-contained file, simple LaTeX |
| Figure dimensions | Width = 6.27in (A4 textwidth − 2in margins); single-country height = 2.8in; 2-country panel = 5.8in | Fills the text column correctly |
| Shared theme | New `_theme.R` with `theme_paper()` | Replaces `theme_base()` throughout; clean minimal look compatible with tikzDevice |
| Main figures | Regenerated as tikzDevice (replace current PNGs) | Consistent rendering |
| Script structure | New `scripts/R/05_panel_figures.R` for all 15 panels; 02/03/04 regenerate main figures | Clean separation of concerns |

---

## Figure inventory

### Main paper figures (script 02, 03, 04 → .tikz)

| File | Script | Content |
|---|---|---|
| `var_exp.tikz` | 02 | Bar chart: variance explained by first factor, per country |
| `factor_medians.tikz` | 02 | Median financial cycle + IQR across estimators |
| `ci_medians.tikz` | 02 | Median factor + 80% CIs (cross-country aggregate) |
| `regimes_graph.tikz` | 02 | Heatmap: elevated/neutral/subdued regimes by country-year |
| `dec_graph.tikz` | 03 | Stacked bar decomposition: median across countries |
| `oos_graph.tikz` | 04 | OOS predicted crisis probability (median + IQR) |

### Appendix A — Factor estimates (script 05 → .tikz)

| File | Countries | Content |
|---|---|---|
| `panel_fc_1_2.tikz` | BE, DE | PCA + QML + TSTEP factor estimates, stacked 2-country |
| `panel_fc_3_4.tikz` | ES, FI | same |
| `panel_fc_5_6.tikz` | FR, GB | same |
| `panel_fc_7_8.tikz` | IT, NL | same |
| `panel_fc_9_10.tikz` | PT, SE | same |

### Appendix B — Decomposition (script 05 → .tikz)

| File | Countries | Content |
|---|---|---|
| `final_panel_with_legend_1_2.tikz` | BE, DE | Stacked bar decomposition, 2-country |
| `final_panel_with_legend_3_4.tikz` | ES, FI | same |
| `final_panel_with_legend_5_6.tikz` | FR, GB | same |
| `final_panel_with_legend_7_8.tikz` | IT, NL | same |
| `final_panel_with_legend_9_10.tikz` | PT, SE | same |

### Appendix C — Confidence intervals (script 05 → .tikz)

| File | Countries | Content |
|---|---|---|
| `panel_ci_1_2.tikz` | BE, DE | Factor + 80% CI bands, 2-country |
| `panel_ci_3_4.tikz` | ES, FI | same |
| `panel_ci_5_6.tikz` | FR, GB | same |
| `panel_ci_7_8.tikz` | IT, NL | same |
| `panel_ci_9_10.tikz` | PT, SE | same |

---

## Implementation steps

### Step 1 — Create `scripts/R/auxiliary/_theme.R`

Shared paper theme function:
```r
theme_paper <- function(base_size = 9) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor   = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(colour = "grey88", linewidth = 0.3),
      axis.line          = element_line(colour = "grey40", linewidth = 0.3),
      axis.ticks         = element_line(colour = "grey40", linewidth = 0.3),
      axis.text          = element_text(size = 7),
      legend.text        = element_text(size = 7),
      legend.key.size    = unit(0.35, "cm"),
      legend.position    = "bottom",
      plot.background    = element_rect(fill = "white", colour = NA),
      strip.text         = element_text(size = 8, face = "bold")
    )
}

# Helper: save figure as tikz
save_tikz <- function(plot, filename, width = 6.27, height = 3.2) {
  path <- file.path(FIGURES_DIR, filename)
  tikzDevice::tikz(path, width = width, height = height, standAlone = FALSE,
                   sanitize = TRUE)
  print(plot)
  dev.off()
  invisible(path)
}
```

Color palette (consistent with current figures):
```r
COLOURS <- list(
  nfc    = rgb(0,   70,  122, maxColorValue = 255),   # deep blue
  hh     = rgb(242, 200,  81, maxColorValue = 255),   # gold
  rhp    = rgb(237,  26,  59, maxColorValue = 255),   # red
  sp     = rgb( 50, 104,  49, maxColorValue = 255),   # green
  dsr    = rgb(245, 130,  50, maxColorValue = 255),   # orange
  c2gdp  = rgb(111, 111, 111, maxColorValue = 255),   # grey
  spread = rgb(160, 210,  45, maxColorValue = 255),   # lime
  pca    = "#003366",
  qml    = "#cc0000",
  tstep  = "#336600"
)
```

### Step 2 — Update scripts 02, 03, 04 to use tikzDevice

Replace all `png(...)` / `ggsave(...)` calls with `save_tikz(plot, "filename.tikz")`.  
Source `_theme.R` at the top. Replace `theme_base()` with `theme_paper()`.  
Add `library(tikzDevice)` and `library(patchwork)`.

Also add `save_tikz()` calls for:
- Country-level `conf_graph` per country → `ci_medians_*.tikz` (feeds Appendix C aggregate) — already done via main `ci_medians.tikz`

### Step 3 — Create `scripts/R/05_panel_figures.R`

Structure:
```
Preamble: source _paths.R + _theme.R, load packages
Load data: df_dfm, df_ic_avar, df_dec from _outputs/

PAPER_COUNTRIES <- c("BE","DE","ES","FI","FR","GB","IT","NL","PT","SE")
COUNTRY_NAMES   <- c(BE="Belgium",DE="Germany",ES="Spain",FI="Finland",
                     FR="France",GB="United Kingdom",IT="Italy",
                     NL="Netherlands",PT="Portugal",SE="Sweden")
PAIRS <- list(c("BE","DE"), c("ES","FI"), c("FR","GB"), c("IT","NL"), c("PT","SE"))

For each pair (k, countries):
  Appendix A: build 2 country ggplots (PCA+QML+TSTEP + CI ribbon)
              combine with patchwork (2 rows)
              save_tikz(combined, paste0("panel_fc_", 2k-1, "_", 2k, ".tikz"),
                        width=6.27, height=5.8)
              
  Appendix B: apply FC_decomposition to each country's dec data
              combine 2 decomposition bar charts with patchwork
              save_tikz(combined, paste0("final_panel_with_legend_", ..., ".tikz"),
                        width=6.27, height=5.8)
              
  Appendix C: build 2 country CI plots (factor + shaded bands + dashed bounds)
              combine with patchwork
              save_tikz(combined, paste0("panel_ci_", ..., ".tikz"),
                        width=6.27, height=5.8)
```

Each country plot in Appendix A shows:
- Grey ribbon: IQR across all estimators (25th–75th pct)
- Solid line (blue): PCA estimate
- Dashed line (red): QML estimate  
- Dotted line (green): TSTEP estimate
- Horizontal zero line
- `ggtitle(COUNTRY_NAMES[ctry])` for identification
- Shaded recession/crisis bands from ESRB dates (optional, discussed below)

Each country plot in Appendix C shows:
- Grey ribbon: 80% confidence band (factor.p10 to factor.p90)
- Solid line: factor estimate
- Dashed lines: mean of upper/lower bounds (threshold for regime classification)
- Zero line

### Step 4 — Update `paper/main.tex`

Add to preamble:
```latex
%% tikz (for figures generated via tikzDevice)
\usepackage{tikz}
```

### Step 5 — Update main paper figure includes (4_results.tex)

Change all `\includegraphics{filename}` to `\input{../Figures/filename.tikz}` for the 6 main figures. Wrap each in the existing figure environment (no structural change needed, just the include command).

### Step 6 — Rewrite appendix .tex files

Replace bare `\includegraphics` blocks with properly structured figure environments:

```latex
% appendix_a_fc.tex example
\begin{figure}[h]
\centering
\input{../Figures/panel_fc_1_2.tikz}
\caption{Financial cycle estimates: Belgium (BE) and Germany (DE)}
\caption*{\footnotesize \textbf{Notes:} ...}
\label{fig:fc_BE_DE}
\end{figure}
\FloatBarrier
```

Repeat for each panel. Add a section-level caption note at the start of each appendix explaining what is shown.

---

## Files modified

| File | Change |
|---|---|
| `scripts/R/auxiliary/_theme.R` | New — `theme_paper()` + `save_tikz()` + `COLOURS` |
| `scripts/R/05_panel_figures.R` | New — generates all 15 panel .tikz files |
| `scripts/R/02_factor_estimation.R` | png → tikzDevice; theme_base → theme_paper; source _theme.R |
| `scripts/R/03_dec_ew_gar.R` | png → tikzDevice; theme_base → theme_paper |
| `scripts/R/04_oos.R` | png → tikzDevice; theme_base → theme_paper |
| `paper/main.tex` | Add `\usepackage{tikz}` |
| `paper/sections/4_results.tex` | 6× `\includegraphics` → `\input` |
| `paper/appendices/appendix_a_fc.tex` | Full rewrite: 5 captioned figure environments |
| `paper/appendices/appendix_b_dec.tex` | Full rewrite: 5 captioned figure environments |
| `paper/appendices/appendix_c_ci.tex` | Full rewrite: 5 captioned figure environments |

---

## Verification

1. `Rscript scripts/R/02_factor_estimation.R` — 6 .tikz files appear in `Figures/`
2. `Rscript scripts/R/03_dec_ew_gar.R` — dec_graph.tikz appears
3. `Rscript scripts/R/04_oos.R` — oos_graph.tikz appears
4. `Rscript scripts/R/05_panel_figures.R` — 15 panel .tikz files appear
5. `cd paper && xelatex -interaction=nonstopmode main.tex` — no errors, PDF output
6. Inspect PDF: all appendix panels show 2025 Q3 data, all figures have captions, text is LaTeX-typeset (not raster)

---

## Text changes summary (already implemented — for reference)

The following changes were made to the paper text in the sessions leading up to this plan:

### `paper/sections/4_results.tex`

| Location | Original | Change |
|---|---|---|
| Subsection 4.4 title | "Relation with Financial crisis" | "Identification of financial crises" |
| §4.3 decomposition intro | Brief sentence; no explanation of constant treatment | Full methodological paragraph: no-intercept regression, normalized weights, bond spread sign retention, uniform scaling for additivity |
| §4.3 decomposition caption | Generic; no note on bar additivity | Explicit: bars sum to fitted value from zero-intercept projection; bond spread signed; uniform scale factor applied |
| §4.4 usefulness "measure" (×2) | "usefulness measure" | "usefulness index" throughout |
| §4.4 residual events sentence | Awkward, hard to read | Rewritten: 3 clear sentences explaining what residual events are, why they arise, why they are included |
| §4.4 OOS probability paragraph | "The results show the model would produce a signal..." with caution leading | Rewritten to lead positively: "The key finding is the trajectory... more than doubles"; caveat placed after, framing it as expected given training sample; ends on strong policy conclusion |

### `paper/main.tex`

| Location | Original | Change |
|---|---|---|
| Author footnote block | Placeholder `{\color{blue} * XXX. E-mail: YYY...}` | Filled: Daniel Abreu (Banco de Portugal); Ivan De Lorenzo Buratta (Prometeia) with correct email addresses |
| Abstract | "more than doubling" (no numbers) | "more than doubling — from approximately 10\% in early 2006 to around 25\% by 2007" |
| Acknowledgments | Placeholder workshop/person names | Generic placeholder retained (to be filled before submission) |

### `paper/sections/3_methodology.tex`

| Location | Original | Change |
|---|---|---|
| Footnote on normalisation (line 26) | `\footnote{\footnote{...}}` — double-nested footnote (LaTeX bug) | Fixed to single `\footnote{}` |
| Matrix equation newlines | `\boldsymbol{f}_t \` (broken `\\`) | Corrected to `\\` in all matrix environments |
| "Quasi-maximum likelihood" paragraph label | "Quasi-maximum likelihood (QML) estimation." | Lowercased to "Quasi-maximum likelihood (QML) estimation." (minor style) |

### `paper/sections/5_conclusion.tex`

| Location | Original | Change |
|---|---|---|
| Entire section | 3 short paragraphs | Added `% TODO` markers for expansion; content preserved; expansion deferred to next session |
