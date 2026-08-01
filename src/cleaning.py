"""Cleaning and QC steps for the synthetic lab dataset.

This is the module the notebook imports instead of copy-pasting the same five
cells into every analysis. It is also the file used in the AI-assistant segment
("explain what this cleaning script does") — so the docstrings are here to be
read, not just to exist.

All data in this project is synthetic. See data/README.md.
"""

from pathlib import Path

import pandas as pd

# Values outside these ranges are almost certainly data-entry errors rather than
# real physiology. Widen them if you ever point this at a different assay.
PLAUSIBLE_GLUCOSE_MMOL_L = (2.0, 30.0)
PLAUSIBLE_HBA1C_PERCENT = (3.0, 15.0)

DATA_DIR = Path(__file__).resolve().parent.parent / "data"


def load_labs(path=None):
    """Read the raw lab CSV.

    Deliberately does no cleaning — keeping "read it" and "fix it" separate means
    you can always look at what actually arrived.
    """
    path = Path(path) if path else DATA_DIR / "labs.csv"
    return pd.read_csv(path)


def tidy_labs(df):
    """Return a cleaned copy of the raw lab frame.

    Four steps, in this order:

    1. Strip whitespace from text columns. ``" South"`` and ``"South"`` are the
       same site, but every ``groupby`` in pandas disagrees until you fix it.
       (This is the bug behind ``debug/buggy.py`` — see that file.)
    2. Coerce the numeric columns properly. A column containing a single space
       is read as text, which silently turns every later mean into a string
       error or a wrong answer.
    3. Drop exact duplicate rows, which is how the same visit gets counted twice.
    4. Parse visit dates so they sort chronologically rather than alphabetically.

    Does not drop missing values — that is an analysis decision, not a cleaning
    one, so it stays with the analyst.
    """
    out = df.copy()

    for col in ("subject_id", "site"):
        out[col] = out[col].str.strip()

    for col in ("glucose_mmol_l", "hba1c_percent", "age_years"):
        # errors="coerce" turns " " and other junk into NaN instead of raising.
        out[col] = pd.to_numeric(out[col], errors="coerce")

    out = out.drop_duplicates()
    out["visit_date"] = pd.to_datetime(out["visit_date"])

    return out.reset_index(drop=True)


def qc_flags(df):
    """Add boolean QC columns without removing anything.

    Flagging beats filtering: the row stays visible, and whoever reads the output
    can see *why* it was excluded instead of wondering where it went.
    """
    out = df.copy()

    lo, hi = PLAUSIBLE_GLUCOSE_MMOL_L
    out["qc_glucose_implausible"] = ~out["glucose_mmol_l"].between(lo, hi) & out[
        "glucose_mmol_l"
    ].notna()

    lo, hi = PLAUSIBLE_HBA1C_PERCENT
    out["qc_hba1c_implausible"] = ~out["hba1c_percent"].between(lo, hi) & out[
        "hba1c_percent"
    ].notna()

    out["qc_incomplete"] = out[["glucose_mmol_l", "hba1c_percent"]].isna().any(axis=1)
    out["qc_pass"] = ~out[
        ["qc_glucose_implausible", "qc_hba1c_implausible", "qc_incomplete"]
    ].any(axis=1)

    return out


def flag_high_glucose(df, threshold):
    """Rows at or above ``threshold`` mmol/L.

    ``threshold`` is required on purpose. An earlier version defaulted it to 7.0,
    and every downstream notebook quietly inherited a clinical cutoff that nobody
    had chosen deliberately. Make the caller say what they mean.
    """
    return df[df["glucose_mmol_l"] >= threshold]


def summarise_by_site(df):
    """Mean glucose and HbA1c per site, QC-passing rows only."""
    passing = df[df["qc_pass"]] if "qc_pass" in df.columns else df
    return (
        passing.groupby("site")[["glucose_mmol_l", "hba1c_percent"]]
        .mean()
        .round(2)
        .sort_index()
    )
