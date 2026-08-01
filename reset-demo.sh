#!/usr/bin/env bash
# reset-demo.sh — put the two teaching files back to their deliberately-broken state.
#
# WHY YOU NEED THIS: JupyterLab autosaves every couple of minutes. You do not have to
# press Ctrl+S to lose the trap — just opening the notebook and running it is enough to
# overwrite the stale outputs and the out-of-order execution counts that make the demo
# work. Run this after every rehearsal, and after the session itself.
#
# Restores ONLY notebooks/01_explore.ipynb and analysis/01_explore.Rmd.
# Deliberately leaves every other change alone — `git restore .` would also wipe out
# edits to requirements.txt or README.md that you want to keep.
#
#   ./reset-demo.sh
#
set -euo pipefail
cd "$(dirname "$0")"

TEACHING_FILES=(notebooks/01_explore.ipynb analysis/01_explore.Rmd)

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not a git repo, so there is nothing to restore from."
  echo "       Run 'git init && git add . && git commit' on the BROKEN state first."
  exit 1
fi
if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "ERROR: no commits yet — nothing to restore from."
  echo "       Commit the broken state first, or this script has no reference point."
  exit 1
fi

echo "Restoring the teaching files from HEAD..."
git restore --source=HEAD -- "${TEACHING_FILES[@]}"

# Byproducts of running/knitting. All are gitignored, but stale ones confuse a rehearsal.
rm -rf notebooks/.ipynb_checkpoints analysis/.ipynb_checkpoints
rm -rf analysis/01_explore.html analysis/01_explore_files analysis/01_explore.nb.html
find . -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true

# Verify the trap is actually back, rather than trusting that it is.
python3 - <<'PY'
import json, re, sys

# An ASSIGNMENT TO threshold — not merely a mention of it. Lines like
#   flagged = flag_high_glucose(labs, threshold)
# use the variable and must not count; only `threshold = ...` / `threshold <- ...` do.
ASSIGN = re.compile(r"^\s*threshold\s*(<-|=)[^=]")

def assigns_threshold(lines):
    return any(ASSIGN.match(ln) for ln in lines if not ln.strip().startswith("#"))

nb = json.load(open("notebooks/01_explore.ipynb"))
codes = [c for c in nb["cells"] if c["cell_type"] == "code"]
ec  = [c.get("execution_count") for c in codes]
nb_lines = [ln for c in codes for ln in "".join(c["source"]).splitlines()]
outs = sum(1 for c in codes if c.get("outputs"))
errs = sum(1 for c in codes for o in c.get("outputs", []) if o.get("output_type") == "error")

checks = [
    ("execution counts are out of order [1, 2, 7, 4]", ec == [1, 2, 7, 4]),
    ("no cell assigns `threshold`",                    not assigns_threshold(nb_lines)),
    ("all 4 code cells carry saved output",            outs == 4),
    ("no saved ERROR output (stale GOOD output is the trap)", errs == 0),
]
bad = [n for n, ok in checks if not ok]
for n, ok in checks:
    print(f"  {'ok  ' if ok else 'FAIL'} {n}")

# Check CHUNK CODE only. The prose deliberately contains the string
# "threshold <- 7.0" as an instruction, so scanning the whole file false-positives.
lines = open("analysis/01_explore.Rmd").read().splitlines()
chunk_code, inside = [], False
for ln in lines:
    if ln.startswith("```{r"):
        inside = True
    elif ln.startswith("```"):
        inside = False
    elif inside:
        chunk_code.append(ln)
if assigns_threshold(chunk_code):
    bad.append("Rmd chunk assigns threshold")
    print("  FAIL Rmd: a chunk assigns `threshold` — trap is gone")
else:
    print("  ok   Rmd: no chunk assigns `threshold`")

print()
if bad:
    print("TRAP IS BROKEN — do not push. Check whether HEAD itself got a fixed version committed:")
    print("  git log --oneline -- notebooks/01_explore.ipynb")
    sys.exit(1)
print("Trap intact. Safe to push.")
PY

echo
echo "Remaining changes in the working tree (these are yours, untouched):"
git status --short || true
