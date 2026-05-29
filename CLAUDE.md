# CLAUDE.md — my-project

This repo holds multiple research projects. Each project lives in its own subfolder and has its own `CLAUDE.md` with project-specific context.

Shared infrastructure (agents, skills, rules, hooks, templates) lives in `.claude/` and is automatically available in every subfolder.

---

## Repo Layout

```
my-project/
├── CLAUDE.md          # This file — generic repo overview
├── MEMORY.md          # Cross-session memory (all projects)
├── .claude/           # Shared agents, skills, rules, hooks, templates
├── measuring_fc/      # Paper: Measuring the Financial Cycle (DFM approach)
└── misc/              # Template repo scaffolding (README, guide, docs)
```

Add a new project by creating a subfolder with its own `CLAUDE.md`. It will automatically inherit all `.claude/` infrastructure.

---

## Shared Principles

- **Plan first** — enter plan mode before non-trivial tasks
- **Quality gates** — nothing ships below 80/100
- **[LEARN] tags** — when corrected, save `[LEARN:category] wrong → right` to `MEMORY.md`

---

## Active Projects

| Folder | Description | Status |
|--------|-------------|--------|
| `measuring_fc/` | Measuring the Financial Cycle: A Dynamic Factor Model Approach | Pre-submission |

---

## Skills Quick Reference (shared across all projects)

| Command | What It Does |
|---------|-------------|
| `/review-paper [file]` | Manuscript review (`--adversarial` / `--peer [journal]`) |
| `/review-r [file]` | R code quality review |
| `/data-analysis [dataset]` | End-to-end R analysis pipeline |
| `/proofread [file]` | Grammar/typo/terminology review |
| `/validate-bib` | Cross-reference citations vs bibliography |
| `/lit-review [topic]` | Literature search + synthesis |
| `/audit-reproducibility [file]` | Verify paper numbers match script outputs |
| `/verify-claims [file]` | Chain-of-Verification fact-check |
| `/commit [msg]` | Stage, commit, PR, merge |
| `/context-status` | Show session health + context usage |
| `/permission-check` | Diagnose permission layer issues |
