###############################################################
# _theme.R — Shared figure theme and PDF save helpers
# Source at the top of every script that produces figures.
###############################################################

library(ggplot2)

# Publication-ready minimal theme
theme_paper <- function(base_size = 9) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor    = element_blank(),
      panel.grid.major.x  = element_blank(),
      panel.grid.major.y  = element_line(colour = "grey88", linewidth = 0.3),
      axis.line           = element_line(colour = "grey40",  linewidth = 0.3),
      axis.ticks          = element_line(colour = "grey40",  linewidth = 0.3),
      axis.ticks.length   = unit(0.15, "cm"),
      axis.text           = element_text(size = 7, colour = "grey20"),
      axis.title          = element_text(size = 7.5, colour = "grey20"),
      legend.text         = element_text(size = 7),
      legend.title        = element_blank(),
      legend.key.size     = unit(0.35, "cm"),
      legend.position     = "bottom",
      legend.spacing.x    = unit(0.2, "cm"),
      plot.background     = element_rect(fill = "white", colour = NA),
      plot.title          = element_text(size = 8.5, face = "bold",
                                         colour = "grey10", hjust = 0),
      strip.text          = element_text(size = 8, face = "bold"),
      panel.border        = element_rect(fill = NA, colour = "grey80",
                                         linewidth = 0.3)
    )
}

# Colour palette — consistent across all paper figures
COLOURS <- list(
  pca    = "#00467A",                             # deep blue
  qml    = "#B22222",                             # dark red
  tstep  = "#336600",                             # dark green
  nfc    = rgb(  0,  70, 122, maxColorValue=255), # deep blue
  hh     = rgb(242, 200,  81, maxColorValue=255), # gold
  rhp    = rgb(237,  26,  59, maxColorValue=255), # red
  sp     = rgb( 50, 104,  49, maxColorValue=255), # forest green
  dsr    = rgb(245, 130,  50, maxColorValue=255), # orange
  c2gdp  = rgb(111, 111, 111, maxColorValue=255), # grey
  spread = rgb(160, 210,  45, maxColorValue=255), # lime
  ribbon = "grey80"
)

# Human-readable variable labels (for decomposition legend)
VAR_LABELS <- c(
  "cred.nfc.roc.2yoy"  = "Credit NFC",
  "cred.hh.roc.2yoy"   = "Credit HH",
  "rhp.roc.2yoy"       = "House prices",
  "sp.roc.2yoy"        = "Share prices",
  "dsr.roc.2yoy"       = "DSR",
  "cred.2gdp.roc.2yoy" = "Credit-to-GDP",
  "sprd.bond.diff.2y"  = "Bond spread"
)

DEC_COLOURS <- c(
  "Credit NFC"    = COLOURS$nfc,
  "Credit HH"     = COLOURS$hh,
  "House prices"  = COLOURS$rhp,
  "Share prices"  = COLOURS$sp,
  "DSR"           = COLOURS$dsr,
  "Credit-to-GDP" = COLOURS$c2gdp,
  "Bond spread"   = COLOURS$spread
)

# Full country names
COUNTRY_NAMES <- c(
  BE = "Belgium",     DE = "Germany",
  ES = "Spain",       FI = "Finland",
  FR = "France",      GB = "United Kingdom",
  IT = "Italy",       NL = "Netherlands",
  PT = "Portugal",    SE = "Sweden"
)

# Save a ggplot as a vector PDF figure for LaTeX \includegraphics{}
# PDF gives perfect vector quality and is accepted at all journals.
save_fig <- function(plot, filename, width = 6.27, height = 3.2) {
  # Accept either .pdf or .tikz filename (strip extension, always save as .pdf)
  base <- sub("\\.(tikz|pdf)$", "", filename)
  path <- file.path(FIGURES_DIR, paste0(base, ".pdf"))
  ggplot2::ggsave(path, plot = plot, device = "pdf",
                  width = width, height = height, units = "in")
  message("Saved: ", basename(path))
  invisible(path)
}

# Alias kept for backward compatibility with any save_tikz calls
save_tikz <- save_fig
