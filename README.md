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
relative paths in these scripts behave. Then:

```r
install.packages("renv")   # one-time, if you don't have it
renv::init()               # activates the project, finds what the code needs, installs it
```

Then open `analysis/01_explore.Rmd`.

**Use `renv::init()`, not `renv::restore()`.** Both are in the session slides and both are
correct in general — but for *this* repo `init()` is the one that works. Why is explained
below.

### The two prompts you'll see, and what to answer

**1. The renv welcome message** — a wall of text explaining that renv will create a `renv/`
folder, a `.Rprofile`, and a package cache under `~/Library/Caches/`, ending in:

```
Do you want to proceed? [y/N]:
```

Answer **`y`**. This is renv introducing itself on first use, once per machine. Nothing is
installed yet at this point.

**2. If you ran `renv::restore()`** you'll get this instead:

```
It looks like you've called renv::restore() in a project that hasn't been activated yet.
How would you like to proceed?

1: Activate the project and use the project library.
2: Do not activate the project and use the current library paths.
3: Cancel and resolve the situation another way.
```

Answer **`1`**.

- **1 — Activate** is what you want. "Activated" means the project has an `renv/activate.R`
  and a `.Rprofile` that switch R to a private, per-project library whenever you open the
  project. This repo ships `renv.lock` but *not* that scaffolding, which is exactly why
  renv is asking. Option 1 creates it.
- **2 — Don't activate** installs into your global library instead. It will work, but it
  defeats the entire point of segment 3: no sandbox, so this project's packages and every
  other project's packages go back to fighting each other.
- **3 — Cancel** changes nothing.

### ⚠️ Why `init()` rather than `restore()` here

`renv.lock` in this repo is a **hand-written teaching artifact** — it exists so you can open
it and see the format (a pinned R version, a pinned version per package). It lists six
packages, but **not their dependencies**: `dplyr` alone needs `cli`, `glue`, `rlang`,
`vctrs`, `tibble` and about eight more, none of which are recorded.

`renv::restore()` installs *what the lockfile says* — so restoring from this minimal
lockfile can leave you with a `dplyr` that fails to load, complaining about a missing
dependency. That is not a bug in renv; it is a lockfile that was written by hand instead of
generated.

`renv::init()` avoids the problem by **scanning the code** for `library()` and `::` calls,
resolving the full dependency tree itself, and installing that. Afterwards:

```r
renv::snapshot()    # regenerate renv.lock properly, from what is actually installed
```

Now `renv.lock` is a real lockfile with every transitive dependency pinned — which is what
`pip freeze` does on the Python side, and what you'd have in a real project.

> **This is a genuine lesson, not just a wart.** A lockfile you *wrote* is documentation. A
> lockfile you *generated* is reproducible. Only one of them survives contact with a
> labmate's laptop.

### What renv adds to your project, and what to commit

After activating you'll see new files. This trips people up, so:

| Path | Commit it? | What it is |
|---|---|---|
| `renv.lock` | **yes** | The recipe. The whole point. |
| `.Rprofile` | **yes** | One line that activates renv when the project opens. |
| `renv/activate.R` | **yes** | The bootstrap script `.Rprofile` calls. |
| `renv/settings.json` | **yes** | Project renv settings. |
| `renv/library/` | **no** | The sandbox itself — big, machine-specific, rebuildable. |

The repo's `.gitignore` already excludes `renv/library/`, and renv adds its own ignore rules
too (it writes an `renv/.gitignore` and may append to the root one). If `git status` looks
busy after activating, that is expected — check the table above before committing.

**Commit the recipe, never the sandbox.** Same rule as `.venv/` and `requirements.txt`.

### Don't want renv at all?

Perfectly reasonable if you just want to run the exercise:

```r
install.packages(c("dplyr", "readr", "rmarkdown", "rprojroot"))
```

Everything in this repo works with plain global packages. You lose the isolation, which is
the thing segment 3 is about — but nothing here *requires* renv.

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
