# STAGED FOR THE DEBUGGER DEMO (segment 5). Do not fix before the session.
#
# This is the R twin of debug/buggy.py — same bug, same shape, same payoff. It
# exists so you can switch the debugger demo to RStudio if the segment-1 show of
# hands comes back R-heavy. It is the ONLY demo in the deck worth switching.
#
# Run it and you get:
#
#     [1] "North: 6.30 mmol/L (assay-adjusted)"
#     Error in site_means[[site]] : subscript out of bounds
#
# (Python's twin raises one line later, on `mean_value + 0.1`, because .get()
# returns None rather than erroring. Same bug, slightly different landing spot.)
#
# Note what happens first: it reports North correctly, THEN dies on South. Code
# that half-works is the most misleading kind.
#
# The room's instinct will be to add print()/cat() calls. Instead, click the gutter
# next to the marked line in report_row() and hit Source (Cmd/Ctrl+Shift+S) — the
# same gesture as VSCode. When the prompt becomes Browse[1]>, type
# nchar(names(site_means)) and look:
#
#     [1] "  South" " South"  "North"
#
# Three groups, not two, and no name "South" at all — because we skipped
# tidy_labs() and never trimmed the `site` column. report_row() asks for
# "South" and the lookup fails.
#
# WHY THIS BUG: nothing failed at the point of the mistake. The data was wrong
# well before R complained, and a cat() on the wrong variable tells you nothing.
#
# TO RUN:  source("debug/buggy.R")    (from the repo root, inside the .Rproj)

source("R/cleaning.R")

TARGET_SITES <- c("North", "South")

#' Mean glucose per site.
#'
#' Note what is missing: we load the raw frame and group it directly, without
#' calling tidy_labs() first. That is the entire bug, one line from correct.
mean_glucose_by_site <- function(df) {
  numeric <- df |>
    mutate(glucose_mmol_l = suppressWarnings(as.numeric(glucose_mmol_l)))

  means <- numeric |>
    group_by(site) |>
    summarise(m = round(mean(glucose_mmol_l, na.rm = TRUE), 2), .groups = "drop")

  # A named vector, so the lookup below is by name — same as the Python dict.
  stats::setNames(means$m, means$site)
}

report_row <- function(site_means, site) {
  #  <<< SET THE BREAKPOINT ON THE NEXT LINE >>>
  # Click the gutter left of the line number (or Shift+F9), then click Source
  # (Cmd/Ctrl+Shift+S). At the Browse[1]> prompt, try: nchar(names(site_means))
  #
  # Fallback: if a breakpoint refuses to activate — a grey hollow circle instead of
  # a solid red one means it is pending because the file has not been sourced —
  # uncomment the browser() below instead. It always works, and it is the right
  # tool for top-level script lines, where gutter breakpoints are unreliable.
  # browser()
  mean_value <- site_means[[site]]

  # This is where it errors — one line after the actual mistake, which is
  # exactly why print-debugging sends you hunting in the wrong place.
  adjusted <- mean_value + 0.1

  sprintf("%s: %.2f mmol/L (assay-adjusted)", site, adjusted)
}

main <- function() {
  df <- load_labs()
  site_means <- mean_glucose_by_site(df)

  print(site_means)
  for (site in TARGET_SITES) {
    print(report_row(site_means, site))
  }
}

main()

# ---------------------------------------------------------------------------
# Facilitator notes
#
# * PRINTING site_means HIDES THE BUG. R pads names to equal width, so all three
#   look identically spaced and you simply cannot see the leading whitespace:
#       South   South   North
#        6.60    7.43    6.20
#   Use names() (quotes make it visible) or nchar() (7 6 5 — numeric proof). This
#   is the R-specific reason the reveal has to be explicit; Python's dict repr
#   shows the quotes for free.
# * `site_means[["South"]]` on a named vector whose name is " South" throws
#   "subscript out of bounds" rather than returning NULL — so in R the error can
#   land ON the lookup line rather than after it. Either way the Environment pane
#   shows you the whitespace instantly, which is the point.
# * The breakpoint stops TWICE — once per entry in TARGET_SITES. `c` continues.
# * To demo the fix: change mean_glucose_by_site() to pipe through tidy_labs()
#   first, then re-source. Two sites, no error.
# * Type  Q  to leave the browser. Tell the room that, or you will be stuck in
#   it while forty people watch.
# ---------------------------------------------------------------------------
