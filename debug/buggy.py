"""STAGED FOR THE DEBUGGER DEMO (segment 5). Do not fix before the session.

Run it and you get:

    TypeError: unsupported operand type(s) for +: 'NoneType' and 'float'

Note what happens first: it prints North correctly, THEN dies on South. Code that
half-works is the most misleading kind.

The room's instinct will be to add print statements. Set a breakpoint on the
marked line instead, look at `site_means` in the Variables panel, and the cause
is visible in about two seconds — the keys have leading whitespace:

    {'  South': 6.6, ' South': 7.43, 'North': 6.2}

Three groups, not two, and no key named "South" at all — because we skipped
tidy_labs() and never trimmed the `site` column. `report_row()` asks for
"South", `.get()` hands back None, and the arithmetic on the next line raises.

WHY THIS BUG: it is the failure mode this whole session is about. Nothing
crashed at the point of the mistake. The data was wrong for twenty lines before
Python noticed, and a print() on the wrong variable tells you nothing.

TO RUN:  python debug/buggy.py       (from the repo root)
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from cleaning import load_labs  # noqa: E402  (path juggling has to come first)

TARGET_SITES = ["North", "South"]


def mean_glucose_by_site(df):
    """Mean glucose per site.

    Note what is missing: we load the raw frame and group it directly, without
    calling tidy_labs() first. That is the entire bug, and it is one line away
    from being correct.
    """
    numeric = df.copy()
    numeric["glucose_mmol_l"] = numeric["glucose_mmol_l"].astype(float)

    means = {}
    for site, group in numeric.groupby("site"):
        means[site] = round(group["glucose_mmol_l"].mean(), 2)
    return means


def report_row(site_means, site):
    #  <<< SET THE BREAKPOINT ON THE NEXT LINE >>>
    # Hover over `site_means`, or open the Variables panel. Look at the keys.
    mean_value = site_means.get(site)

    # This is where it explodes — one line after the actual mistake, which is
    # exactly why print-debugging sends you hunting in the wrong place.
    adjusted = mean_value + 0.1

    return f"{site}: {adjusted:.2f} mmol/L (assay-adjusted)"


def main():
    df = load_labs()
    site_means = mean_glucose_by_site(df)

    print("Site means:", site_means)
    for site in TARGET_SITES:
        print(report_row(site_means, site))


if __name__ == "__main__":
    main()
