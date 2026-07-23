---
env_name: <ENV_NAME>
backend: conda            # conda / venv
created: <YYYY-MM-DD>     # real run date (date +%Y%m%d), never invented
status: verified          # verified / partial / blocked
model_id: <model id, copied verbatim from what your runtime states this session — your Kimi session reports it where available; "unrecorded" only if the session names none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
---

# Environment Report — <ENV_NAME>

A fresh session should be able to use — or rebuild — this environment from this file alone.

## Identity

- Interpreter (`ENV_PY`): `<absolute path>`   ← run everything through this path; never `source activate`
- Backend: conda (`$CONDA_HOME/envs/<ENV_NAME>`) / venv (`<project>/.venv`)
- Python: `<version>`
- Previous environment backed up as: `<name>_<YYYYMMDD>` / none
  <!-- A renamed venv keeps stale absolute paths inside its scripts: frozen backup only, not activatable. -->

## Machine probe

- OS / arch: <…>
- GPU / driver: <nvidia-smi one-liner, or "none">
- Driver CUDA ceiling: <X.Y> · Local toolkit (nvcc): <X.Y / absent>
- Framework wheel index chosen: `<url / default PyPI>` — <why: ceiling, pin, platform>

## Dependency source

- Source used: existing requirements / packaging metadata (<files>) / import scan
- Files written this run: <list, or "none — layout pre-existed">
- Commit: `star-env-builder: add requirements layout` (<sha>) / none

## Install results

<!-- One row per category actually processed. Failed = count, details under Failures. -->

| Category | File | Requested | Installed | Failed | Route |
|---|---|---|---|---|---|
| conda | requirements/conda.txt | | | | conda |
| framework | requirements/framework.txt | | | | uv |
| runtime | requirements/runtime.txt | | | | uv |
| optional | requirements/optional.txt | | | | skipped |
| project | `-e ${CODE_NAME}` (`--no-deps`) | | | | uv |

## Smoke matrix

<!-- Filled by the main loop from its own runs. Result: pass / blocked / skipped (reason).
     Evidence is the actual output tail — an empty cell is not acceptable for pass. -->

| Layer | Check | Command | Result | Evidence |
|---|---|---|---|---|
| L1 | | | | |
| L2 | | | | |
| L3 | | | | |

## Failures & blocked

<!-- Error tails, diagnosis, what was tried (≤2 rounds per layer), current state. -->

## Awaiting user (STOP line)

<!-- Source builds, sudo/system installs, >10 GB downloads. Exact command + why it crossed the
     line + what to do afterwards. -->

- [ ] `<exact command>` — <why: source build / sudo / size>. Afterwards: re-run `/skill:star-env-builder <ENV_NAME>` and choose *verify & repair in place*.

## Snapshot

Exact versions: [`freeze.txt`](freeze.txt) — `uv pip freeze --python $ENV_PY` (or `$ENV_PY -m pip freeze`).
