# data/

## `labs.csv` — SYNTHETIC. Not real data. Not derived from real data.

Fifteen invented rows, generated for a teaching demo. Subject IDs are sequential
placeholders (`SUBJ-001`…). Dates, ages, and lab values were made up to be
plausible-looking, nothing more. There is no underlying cohort, no source
dataset, and no de-identification step — because there was never anything to
de-identify.

**This is the only dataset that ever appears in this session, and it is fake on purpose.**

### The mess is deliberate

`cleaning.py` / `cleaning.R` exist to fix these, so don't tidy them up:

| Row | Problem | Why it's here |
|---|---|---|
| every `South` row | Leading whitespace in `site` — `" South"` on most, `"  South"` on two | Drives the debugger demo. Grouping the raw frame yields three groups and **no key named `"South"`**, so a lookup for `"South"` returns nothing. `North` is clean, so the script half-works, which is the insidious part. |
| SUBJ-009 | Empty `glucose_mmol_l` | Missing-value handling |
| SUBJ-010 | Exact duplicate row | Deduplication — 15 rows in, 14 out |
| SUBJ-011 | `hba1c_percent` is a single space, not empty | The nastier kind of missing — looks fine in a spreadsheet, reads as text |

Verified values after `tidy_labs()` + `qc_flags()`, if you need to check a demo is
behaving: **14 rows, 12 passing QC, sites `['North', 'South']`.** Five visits at or above
7.0 mmol/L. Site means: North 6.28 / 6.12, South 7.23 / 6.83.

### A note for the session

In real work this file would live **outside** the repo, and the repo would hold a
path to it. It is committed here only because it is fake and the repo needs to be
clonable in one step. Say that out loud when you show it — otherwise you have
just demonstrated the habit you spend segment 7 warning against.
