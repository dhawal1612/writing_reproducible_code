# Cleaning and QC steps for the synthetic lab dataset.
#
# The R counterpart of src/cleaning.py. Same four cleaning steps, same QC flags,
# same argument choices — so a student who reads one can read the other. This is
# also the file to use if you switch the AI-assistant demo to R.
#
# All data in this project is synthetic. See data/README.md.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

# Values outside these ranges are almost certainly data-entry errors rather than
# real physiology. Widen them if you point this at a different assay.
PLAUSIBLE_GLUCOSE_MMOL_L <- c(2.0, 30.0)
PLAUSIBLE_HBA1C_PERCENT  <- c(3.0, 15.0)

#' Read the raw lab CSV.
#'
#' Deliberately does no cleaning — keeping "read it" and "fix it" separate means
#' you can always look at what actually arrived.
load_labs <- function(path = "data/labs.csv") {
  # col_types set explicitly: let readr guess and the whitespace-only hba1c
  # column silently becomes character on some machines and numeric on others.
  read_csv(
    path,
    col_types = cols(
      subject_id     = col_character(),
      visit_date     = col_date(format = "%Y-%m-%d"),
      age_years      = col_double(),
      glucose_mmol_l = col_character(),
      hba1c_percent  = col_character(),
      site           = col_character()
    )
  )
}

#' Return a cleaned copy of the raw lab frame.
#'
#' Four steps, in this order:
#'   1. Trim whitespace from text columns. " South" and "South" are the same
#'      site, but every group_by() disagrees until you fix it. (This is the bug
#'      behind debug/buggy.R — see that file.)
#'   2. Coerce the numeric columns properly. A column holding a single space is
#'      read as text, which turns every later mean into NA or an error.
#'   3. Drop exact duplicate rows — how the same visit gets counted twice.
#'   4. Sort chronologically.
#'
#' Does not drop missing values: that is an analysis decision, not a cleaning
#' one, so it stays with the analyst.
tidy_labs <- function(df) {
  df |>
    mutate(
      across(c(subject_id, site), trimws),
      # as.numeric(" ") is NA with a warning; suppress it because it is expected.
      across(c(glucose_mmol_l, hba1c_percent), \(x) suppressWarnings(as.numeric(x)))
    ) |>
    distinct() |>
    arrange(visit_date, subject_id)
}

#' Add boolean QC columns without removing anything.
#'
#' Flagging beats filtering: the row stays visible, and whoever reads the output
#' can see *why* it was excluded instead of wondering where it went.
qc_flags <- function(df) {
  df |>
    mutate(
      qc_glucose_implausible = !is.na(glucose_mmol_l) &
        (glucose_mmol_l < PLAUSIBLE_GLUCOSE_MMOL_L[1] |
           glucose_mmol_l > PLAUSIBLE_GLUCOSE_MMOL_L[2]),
      qc_hba1c_implausible = !is.na(hba1c_percent) &
        (hba1c_percent < PLAUSIBLE_HBA1C_PERCENT[1] |
           hba1c_percent > PLAUSIBLE_HBA1C_PERCENT[2]),
      qc_incomplete = is.na(glucose_mmol_l) | is.na(hba1c_percent),
      qc_pass = !(qc_glucose_implausible | qc_hba1c_implausible | qc_incomplete)
    )
}

#' Rows at or above `threshold` mmol/L.
#'
#' `threshold` is required on purpose. An earlier version defaulted it to 7.0 and
#' every downstream script quietly inherited a clinical cutoff nobody had chosen
#' deliberately. Make the caller say what they mean.
flag_high_glucose <- function(df, threshold) {
  if (missing(threshold)) stop("flag_high_glucose(): give me a threshold explicitly.")
  filter(df, glucose_mmol_l >= threshold)
}

#' Mean glucose and HbA1c per site, QC-passing rows only.
summarise_by_site <- function(df) {
  passing <- if ("qc_pass" %in% names(df)) filter(df, qc_pass) else df
  passing |>
    group_by(site) |>
    summarise(
      glucose_mmol_l = round(mean(glucose_mmol_l, na.rm = TRUE), 2),
      hba1c_percent  = round(mean(hba1c_percent,  na.rm = TRUE), 2),
      .groups = "drop"
    ) |>
    arrange(site)
}
