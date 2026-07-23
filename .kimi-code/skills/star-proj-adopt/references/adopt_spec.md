# Adoption Spec — probe recipe, inventory contract, and write rules

The exact rules behind `star-proj-adopt`. `SKILL.md` states the shape; this file states what counts.

## 1. The probe (read-only)

Six lanes. Each returns findings plus a confidence: `certain` (one unambiguous match), `likely` (one match, weak signal), `unknown` (none or several). Only `likely` and `unknown` lines reach Gate 1 — a `certain` line is reported, not asked about.

| Lane | Look at | `certain` when |
|---|---|---|
| Source | Top-level dirs holding `__init__.py`; what the entrypoints import; `pyproject.toml` / `setup.py` `name` and `packages` | exactly one importable top-level package, and the entrypoints import it |
| Runtime | `conda env list`, `.venv/`, `which python`, env names inside existing scripts, `environment.yml` / `requirements*.txt` | exactly one env whose name matches the project or whose python imports the source package |
| Data | Dirs named `data*` / `dataset*`, paths in configs and dataloader defaults, large non-code trees | one path, referenced by more than one config or script |
| Weights | Dirs named `ckpt*` / `checkpoint*` / `weights` / `pretrained` / `models`, `.pt` / `.pth` / `.safetensors` / `.bin` clusters | one path holding the checkpoints the entrypoints load |
| Outputs | Dirs named `out*` / `runs` / `logs` / `exp*` / `work_dir*`, TensorBoard event files, per-run subdirectory patterns | one path whose subdirectories look like runs (timestamps, config names) |
| Entrypoints | Executable scripts, `if __name__ == "__main__"`, `console_scripts`, `Makefile` / `*.sh` targets, README commands | — always reported as a list, never a single answer |

Also record, for the inventory: first commit date, commit count, the 20 most recently changed paths, and any README section describing status or results.

**Nothing in this lane writes.** Do not run the project's code, do not import its package, do not create the environment.

## 2. The mapping block

Report the probe as one block before Gate 1, one line per lane:

```
source     CODE_NAME=<dir>            certain   (only importable package; imported by train.py)
runtime    PYTHON_HOME=<path>         likely    (conda env "ovd"; matches env name in scripts/train.sh)
data       datas/ -> <path>           certain   (referenced by 4 configs)
weights    inits/ -> <path>           unknown   (no checkpoint dir found)
outputs    wkdrs/ -> <path>           likely     (12 timestamped subdirs)
entry      3 launchers                 —         (scripts/train.sh, scripts/eval.sh, tools/infer.py)
```

## 3. Symlink rules

For each of `datas/`, `inits/`, `wkdrs/`, in this order:

1. Path does not exist → create the symlink to the confirmed target.
2. Path is an empty directory (or holds only `.gitkeep`) → remove the placeholder, create the symlink.
3. Path is already a symlink to the same target → leave it, report `already linked`.
4. Path is a symlink to a **different** target, or a **non-empty real directory** → do nothing, report the conflict, ask. Never replace it, never merge into it.
5. The confirmed target is inside the repository and already in the right place → no link needed, report `already in place`.

A target outside the repository is normal and fine; record its absolute path in `metds/adopt.md`. A target on a network or removable mount is recorded with that caveat.

## 4. Wrapper rules

One `execs/scpts/<name>.sh` per entrypoint the user kept. The wrapper **calls the existing command and changes nothing about it**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Adopted wrapper: calls the project's existing launcher unchanged.
# Source: scripts/train.sh (adopted <YYYY-MM-DD>)

cd "${ROOT_DIR}"
bash scripts/train.sh "$@"
```

Rules: never edit the wrapped script; never inline its body; never "improve" its arguments. When the existing command hardcodes a path that a symlink now also reaches, leave the hardcoded path alone — both resolve, and rewriting it is a code change, which is out of bounds. `<name>` distinguishes the task (conventions §9), and a name already taken in `execs/scpts/` is a conflict to ask about, not to suffix.

## 5. The work inventory contract

One row per identifiable unit of finished or in-flight work. Fewer, well-evidenced rows beat many speculative ones — if two commits and one output dir describe one thing, that is one row.

| Field | Content |
|---|---|
| `id` | `W1`, `W2`, … — stable, referenced by the backfill record |
| `what` | One descriptive line. What was built or run, in the repository's own vocabulary |
| `state` | `built` (code exists, no run found) / `run` (a run produced output) / `concluded` (a result is written down somewhere) / `abandoned` (superseded or explicitly dropped) |
| `evidence` | Paths, commit SHAs, script names, log lines. At least one. A row with no evidence does not exist |
| `run_dir` | The prior run directory, when `state` is `run` or `concluded`; else empty |
| `metric` | Any number visible in a log, README, or result file, quoted verbatim with its source. Never computed, never rounded |

**What never enters a row:** why the work was done, what claim it supports, whether it succeeded, what should happen next. Those are the coach's to elicit and the analyst's to judge (SKILL.md Principle 5).

## 6. Ledger rules (Gate 2)

For each run the user selects:

1. Symlink the existing run directory to `wkdrs/<run>/`, where `<run>` is its existing name when that name is already distinctive, and `<existing>_<date-of-run>` when it is not (`output/`, `run1/`).
2. Write `wkdrs/<run>/EXEC_LOG.md` from `assets/exec_log_reconstructed.md`. If the link points into a read-only or external location, write the log to `wkdrs/<run>_adopted/EXEC_LOG.md` instead and say so in the report.
3. The reconstructed log carries: the `reconstructed:` header with the adoption date, `source_plan: (none — adopted before the plan tree existed)`, the command if it is recoverable verbatim from a script or a saved config, the artifacts present, and any metric quoted per §5. **No step table** — there were no steps to record, and inventing them is the failure mode this whole rule exists to prevent.
4. Never write into the linked directory itself. The `EXEC_LOG.md` goes at the `wkdrs/` level.

An `EXEC_LOG.md` already present in a selected run directory is left untouched, and the run is reported as `already ledgered`.

## 7. Backfill matching (Phase `backfill`)

A leaf is matched to an inventory row only on **evidence overlap**: the leaf's §4 deliverable paths or §3 steps name a path, script, or module that appears in the row's `evidence` or `run_dir`. Name similarity alone is not a match — propose it as `weak` and let the user decide.

State proposed per matched leaf:

| Inventory `state` | Proposed leaf `exec_status` |
|---|---|
| `concluded` | `done` |
| `run` | `done` when the leaf's §5 done-criterion is visibly met by the evidence; otherwise `in_progress` |
| `built` | `in_progress` |
| `abandoned` | no proposal — report it and let the user decide |

`exec_runs` is set only when that row's run was ledgered in Gate 2; a `done` leaf with no ledgered run is left with `exec_status` alone and flagged in the report as one `/skill:star-flow-status` will list under done-with-no-run. On a confirmed match whose run was ledgered, the reconstructed log's `source_plan:` is updated to the leaf's filename in the same pass — the confirmation is precisely that correspondence.

Never propose `blocked`, never write `depends_on`, never reorder anything. When one inventory row matches several leaves, or several rows match one leaf, present it as-is and ask — a many-to-many match usually means the decomposition and the history disagree, which is information, not an error to smooth over.
