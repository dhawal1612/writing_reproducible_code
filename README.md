# Reproducible Code — demo repo

Companion repo for the session *Writing Reproducible Code — Could a Labmate Clone Your
Work and Reproduce Your Figure?*

**All data here is synthetic.** Fifteen invented rows. See [`data/README.md`](data/README.md).

> ### This repo is deliberately a little broken
>
> `notebooks/01_explore.ipynb` and `analysis/01_explore.Rmd` both contain a real
> hidden-state bug, on purpose. They display correct-looking output that **cannot be
> reproduced from a clean start**. Finding that out yourself is the exercise — see
> [Your turn](#your-turn) at the bottom.
>
> Don't file it as a bug. It is the point.

---

## Setup — Python

```bash
git clone <this-repo-url>
cd demo-repo

python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt

jupyter lab                        # then open notebooks/01_explore.ipynb
```

Your shell prompt should change when the venv activates — that's the visual cue that
you're installing into the sandbox rather than into your system Python.

## Setup — R

```r
install.packages("renv")           # one-time, if you don't have it
renv::restore()                    # reads renv.lock, installs those versions
```

Open `demo-repo.Rproj` **first** — working inside an RStudio Project is what makes the
relative paths in these scripts behave. Then open `analysis/01_explore.Rmd`.

> `renv.lock` here is a small hand-written starter so you can see the format. Run
> `renv::snapshot()` once you've installed things and it will regenerate properly
> from your actual library.

### Change these three RStudio settings before you start

Tools → Global Options → General:

1. **Uncheck** "Restore .RData into workspace at startup"
2. Set "Save workspace to .RData on exit" → **Never**
3. Always work inside a Project (you just did, by opening the `.Rproj`)

Settings 1 and 2 matter twice: they stop hidden state surviving a restart, **and** they
stop `.RData` quietly writing a binary copy of whatever was in your session to disk. In a
clinical environment that second one is a data-handling problem, not a tidiness problem.

---

## What's in here

| Path | What it is |
|---|---|
| `data/labs.csv` | Synthetic lab results. Deliberately messy — whitespace, a duplicate, two flavours of missing. |
| `src/cleaning.py` | The Python module the notebook imports instead of pasting the same cells five times. |
| `R/cleaning.R` | The R twin of the same module. Same steps, same argument choices. |
| `notebooks/01_explore.ipynb` | Python analysis. **Contains the hidden-state trap.** |
| `analysis/01_explore.Rmd` | R analysis. Contains the same trap. |
| `debug/buggy.py` | Staged for the debugger segment. Fails with a `TypeError` one line after the real mistake. |
| `debug/buggy.R` | The R twin, with `browser()` already in place. |
| `requirements.txt` / `renv.lock` | The two recipes. This is the "environment" leg of the stool. |
| `.gitignore` | A real starter list covering both toolchains — including the files that can leak patient data invisibly. |

---

## Your turn

### 1. Meet the hidden-state trap

**Python:** open `notebooks/01_explore.ipynb`. Before running anything, look at the
execution numbers in the brackets: `1, 2, 7, 4`. That's the order the cells actually ran
in — which is what real exploratory work looks like. Now hit **Kernel → Restart & Run
All**. It fails at a cell that has visible, plausible, *wrong-because-unreproducible*
output.

**R:** open `analysis/01_explore.Rmd`. Run the chunks top to bottom — fine. Now hit
**Knit**. It fails, because knitting always uses a fresh R session. R Markdown has this
check built in and most people never notice.

Then fix it, and re-run from clean. That's the habit.

### 2. Meet the debugger

```bash
python debug/buggy.py
```
```r
source("debug/buggy.R")
```

Both crash. Both crash *one line after the actual mistake*, which is exactly why adding
print statements sends you hunting in the wrong place. Set a breakpoint (Python) or use
the `browser()` that's already there (R), look at the variable, and the cause is obvious
in about two seconds.

The bug is a realistic one: a group key with leading whitespace, because someone skipped
the cleaning step.

### 3. Ask an AI assistant to explain something

Point it at `src/cleaning.py` or `R/cleaning.R` and ask what the QC step does and why
`flag_high_glucose()` refuses to have a default threshold. Then check its answer against
the code. That verification step is the whole skill.

---

## The one rule

**If it identifies a patient or unlocks a system, it does not go in the repo. Period.**

Git history is forever — deleting a secret in your next commit does not remove it. A
committed credential must be **rotated**, not deleted. A committed patient file must be
**reported**, not quietly removed. When in doubt, ask before you commit.
