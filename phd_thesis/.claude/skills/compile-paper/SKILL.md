---
name: compile-paper
description: Compile the LaTeX paper with XeLaTeX (3 passes + bibtex). Use when user says "compile the paper", "build the paper", "rebuild the PDF", "run latex on the paper", or asks why `paper/main.tex` isn't producing a PDF. Operates on `paper/main.tex`.
argument-hint: "[optional: path to .tex master file, defaults to paper/main.tex]"
allowed-tools: ["Read", "Bash", "Glob"]
---

# Compile LaTeX Paper

Compile the manuscript using XeLaTeX with full citation resolution.

## Steps

### 1. Resolve the target file

If `$ARGUMENTS` is provided, use it as the master `.tex` file.
Otherwise default to `paper/main.tex`.

Derive:
- `TEX_DIR` = directory containing the master file (e.g. `paper/`)
- `TEX_BASE` = filename without extension (e.g. `main`)

### 2. Run the 3-pass compile sequence

```bash
cd "$TEX_DIR"
xelatex -interaction=nonstopmode "$TEX_BASE".tex
# Detect bibliography backend from .aux (biblatex writes \abx@aux@ markers after pass 1)
if grep -q "\\\\abx@aux" "${TEX_BASE}.aux" 2>/dev/null; then
    biber "$TEX_BASE"
else
    bibtex "$TEX_BASE"
fi
xelatex -interaction=nonstopmode "$TEX_BASE".tex
xelatex -interaction=nonstopmode "$TEX_BASE".tex
```

No `TEXINPUTS` override needed — the paper's preamble is self-contained in `paper/`.
BibTeX auto-discovers `refs/references.bib` via the `\bibliography{refs/references}` directive in `main.tex`.

### 3. Check the log for issues

After the final pass, grep `"$TEX_BASE".log`:

```bash
# Overfull hbox warnings
grep -c "Overfull" "$TEX_BASE".log

# Undefined references or citations
grep "undefined" "$TEX_BASE".log | grep -v "^%"

# Labels changed (needs another pass)
grep "Label(s) may have changed" "$TEX_BASE".log
```

### 4. Report results

Always report:
- **Compilation**: success or failure (with first error if failed)
- **Page count**: from the `Output written on` line in the log
- **Overfull hbox count**: number of warnings (0 is ideal; ≤5 acceptable for a paper draft)
- **Undefined references**: list any remaining after 3 passes (indicates missing `\label` or bib entry)
- **BibTeX warnings**: surface any `Warning--` lines from the bibtex pass (missing fields are pre-existing noise; new ones should be flagged)

## Why 3 passes?
1. **Pass 1** — XeLaTeX builds `.aux` with citation keys and label positions
2. **BibTeX** — reads `.aux`, writes `.bbl` with formatted references
3. **Pass 2** — XeLaTeX incorporates the bibliography
4. **Pass 3** — XeLaTeX resolves all forward references and cross-references with final page numbers

## Important
- **Always use XeLaTeX**, never pdflatex — the paper uses Unicode math and fontspec
- **Do not add TEXINPUTS** — this is a paper, not a Beamer deck; no separate Preambles/ directory
- **Biber vs bibtex**: Projects using `biblatex` require `biber` instead of `bibtex`. The compile sequence auto-detects this by checking for `\abx@aux@` markers in the `.aux` file after pass 1. Never manually run `bibtex` on a `biblatex` project — it will silently produce no output.
- If compilation fails on pass 1, stop and report the first `! ` error line from the log — do not run bibtex or subsequent passes on a broken build
- BibTeX warnings about missing `volume`/`pages` on specific keys (`fisher1933debt`, `lang2019anticipating`, `lo2017new`) are pre-existing and can be noted but not flagged as new issues
