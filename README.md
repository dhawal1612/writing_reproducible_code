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
cd writing_reproducible_code

python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt

jupyter lab                        # then open notebooks/01_explore.ipynb
```

Your shell prompt should change when the venv activates — that's the visual cue that
you're installing into the sandbox rather than into your system Python.

**Tested on CPython 3.11–3.14.** Check yours with `python3 -V`.

### If the install fails

If you see pip printing `Compiling Cython source ...` or `Building wheel for pandas`
followed by a wall of C compiler errors, pip could not find a prebuilt wheel for your
Python and tried to build the package from source instead.

That is almost always a **version mismatch, not a broken laptop**: the pinned version
predates your Python, so no wheel exists for it. The giveaway is an error like
`too few arguments to function call, expected 6, have 5` — that is C code written against
an older CPython.

Two ways out:

```bash
# 1. Confirm the diagnosis: refuse to compile, and pip will say so plainly.
pip install --only-binary=:all: -r requirements.txt

# 2. Then either use a Python in the tested range, or regenerate the recipe
#    for your own Python and commit the result:
pip install pandas numpy matplotlib jupyterlab
pip freeze > requirements.txt
```

Keep `--only-binary=:all:` in your back pocket generally. It turns a ten-minute
compile-and-fail into a one-line "no wheel for this" answer.

> This is the "it works on my machine" problem in its purest form, and it cuts both ways:
> a pin that is too loose gives your labmate different results, and a pin that is too tight
> stops them installing at all. Neither is solved by not pinning — it is solved by pinning
> *and* saying which Pythons you tested.

## Setup — R

Open `demo-repo.Rproj` **first** — working inside an RStudio Project is what makes the
relative paths in these scripts behave. The project ships already activated, so opening it
switches R to a private per-project library automatically.

```r
install.packages("renv")   # one-time, if you don't have it
renv::restore()            # installs the exact versions in renv.lock
```

Then open `analysis/01_explore.Rmd`.

**Tested on R 4.6.1 (arm64 macOS).** Check yours with `R.version.string`.

`renv.lock` is a **generated** lockfile — 49 packages, every transitive dependency pinned.
That is the R equivalent of `pip freeze`, and it is what makes `renv::restore()` reliable.

### See the sandbox, don't just trust it

Python users get an obvious signal: their shell prompt changes when the venv activates. In R
the activation is automatic and therefore invisible, which is more convenient and less
educational. So look at it directly:

```r
.libPaths()
```

Inside this project, the first path is the project's own library:

```
.../demo-repo/renv/library/macos/R-4.6/aarch64-apple-darwin23
```

Run the same command in a plain R session outside the project and you'll get your global
library instead. **That difference is the sandbox.** It is worth doing once, because
"isolated per-project packages" stays abstract until you have seen the two paths side by
side.

### Prompts you may see, and what to answer

**The renv welcome message**, on first use of renv on a machine — a wall of text about
creating a `renv/` folder and a cache under `~/Library/Caches/`, ending in
`Do you want to proceed? [y/N]:`. Answer **`y`**. Nothing is installed yet at that point.

**"…project that hasn't been activated yet"** — three options, choose **`1: Activate the
project and use the project library.`** You should not normally see this, because the repo
commits its activation files; you would only hit it if `.Rprofile` or `renv/activate.R`
were missing. Option 2 works but installs into your *global* library, which defeats the
entire point of segment 3 — no sandbox, so every project's packages go back to fighting
each other.

**"The following package(s) were not installed successfully… Would you like to try
installing the latest available versions? [y/N]"** — answer **`y`**. See below for why this
can happen and why it is not your fault.

### If a package fails to build from source

If `renv::restore()` reports a compile failure with errors like

```
error: use of undeclared identifier 'Rf_allocSExp'
error: use of undeclared identifier 'SET_TRUELENGTH'
```

that is a **version mismatch, not a broken laptop**. Those are R internals that recent R
releases stopped exposing. A package version published before your R version can call them
in its C++ and simply will not compile against a newer R.

Say **`y`** to renv's "try the latest available versions?" offer. Newer versions have the
fix and usually arrive as prebuilt binaries. Then:

```r
renv::status()      # see what is out of sync
renv::snapshot()    # write the working versions into renv.lock
```

> **One gotcha worth knowing:** renv installs as a transaction, so if any package in the set
> fails, the whole batch can be rolled back — including packages whose own lines said
> `✔ installed`. If something is missing afterwards, install it explicitly rather than
> trusting the log:
> ```r
> renv::install(c("rmarkdown", "rprojroot"))
> renv::snapshot()
> ```

This is the same failure the Python side has, for the same reason. See
[If the install fails](#if-the-install-fails) above — `pandas==2.1.4` would not build on
Python 3.14 either. **A pin too loose gives your labmate different results; a pin too tight
stops them installing at all.** Neither is fixed by refusing to pin — it is fixed by pinning
*and* recording which runtime you tested.

### What renv adds to your project, and what to commit

| Path | Commit it? | What it is |
|---|---|---|
| `renv.lock` | **yes** | The recipe. The whole point. |
| `.Rprofile` | **yes** | One line that activates renv when the project opens. |
| `renv/activate.R` | **yes** | The bootstrap script `.Rprofile` calls. |
| `renv/settings.json` | **yes** | Project renv settings. |
| `renv/.gitignore` | **yes** | renv's own ignore rules. |
| `renv/library/` | **no** | The sandbox itself — 3.4 MB here, machine-specific, rebuildable. |

`git status` looks busy the first time you activate. That is expected: four small text files
to commit, and a library that is already ignored.

**Commit the recipe, never the sandbox.** Same rule as `.venv/` and `requirements.txt`.

### Don't want renv at all?

Perfectly reasonable if you just want to run the exercise:

```r
install.packages(c("dplyr", "readr", "rmarkdown", "rprojroot"))
```

Everything here works with plain global packages. You lose the isolation, which is the thing
segment 3 is about — but nothing *requires* renv.

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
| `debug/buggy.R` | The R twin. Set a breakpoint on the marked line and hit Source; `browser()` is commented out as a fallback. |
| `requirements.txt` / `renv.lock` | The two recipes. This is the "environment" leg of the stool. |
| `.gitignore` | A real starter list covering both toolchains — including the files that can leak patient data invisibly. |
| `reset-demo.sh` | Puts the hidden-state trap back after you've solved it, so you can try again. |
| `demo-repo.Rproj` | The RStudio Project. Open **this**, not the individual files. |
| `.Rprofile` and `renv/` | **Plumbing — you never need to read or edit these.** One line in `.Rprofile` switches R to this project's private package library the moment you open the project. `renv/activate.R` is the 1400-line script that does it. Committed because they are what make `renv::restore()` just work for you instead of erroring. |

> **Two files here are worth understanding rather than skipping:** `requirements.txt` and
> `renv.lock`. Everything else in this table is either the analysis itself or plumbing.

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

### Putting the trap back

Once you've fixed it, the broken version is gone from your working copy — and **JupyterLab
autosaves**, so you don't have to press Ctrl+S to lose it. To reset:

```bash
./reset-demo.sh
```

That restores only `notebooks/01_explore.ipynb` and `analysis/01_explore.Rmd` from your last
commit, clears render leftovers, and then *verifies* the trap is actually back rather than
assuming. Run it before each rehearsal, and again before you push.

Use the script rather than `git restore .` — the blunt version would also throw away edits
to `requirements.txt` or `README.md` that you meant to keep.

### 2. Meet the debugger

```bash
python debug/buggy.py
```
```r
source("debug/buggy.R")
```

Both crash. Both crash *one line after the actual mistake*, which is exactly why adding
print statements sends you hunting in the wrong place. Set a breakpoint (Python) or use
a breakpoint plus Source (R), look at the variable, and the cause is obvious in about
two seconds. In R you must type `nchar(names(site_means))` — printing the vector pads the
names and hides the whitespace entirely.

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
