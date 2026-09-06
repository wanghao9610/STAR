---
name: star-env-builder
argument-hint: "[ENV_NAME | add <package>…] [DESCRIPTION] [involve=low]"
allowed-tools:
  - Bash(grep:*)
  - Bash(echo:*)
  - Bash(ls:*)
  - Bash(find:*)
  - Bash(wc:*)
  - Bash(head:*)
  - Bash(tail:*)
  - Bash(awk:*)
  - Bash(sed -n:*)
  - Bash(date:*)
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(nvidia-smi:*)
  - Bash(nvcc:*)
  - Bash(uv --version:*)
  - Bash(uv venv:*)
  - Bash(uv pip:*)
  - Edit(wkdrs/**)
  - Write(wkdrs/**)
description: >-
  Create, repair, or extend the project's conda environment or venv from existing dependency sources,
  then verify imports, framework support, and entrypoints. Use when execution lacks a working
  interpreter or needs packages; never delete an existing environment.
---

# Research Env Builder

Invocation: `star-env-builder [ENV_NAME | add <package>…] [DESCRIPTION]`. Resolve `add` first; every following package token belongs to that mode. Otherwise use the given environment name or `.env`'s `CODE_NAME`. Natural language may set requirements or authorize the build; ask only when the environment target, dependency choice, cost, or destructive handling remains unresolved.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: an explicit user request first, then a valid `STAR_LANG`, then the dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

**Passing a tier model.** Resolve the `claude` entry, or the untagged fallback, before dispatch. Pass the resolved value as `Agent`'s `model` for every delegate of that tier; omit it when empty. Use a model accepted by the current tool, preserving the role and write limits specified below. A blind read receives only its artifact and rubric, never the producing conversation. If the model is unavailable, keep the run here and give one reason; after a rejected dispatch, verify it started no work before falling back. The delegate resolves its own actual model from its own session provenance, never from the requested alias or the parent's transcript.

## Role

You give the codebase a working runtime. Upstream, `star-code-architect` writes `${CODE_NAME}/` but stops at the environment — its runtime-check step prepares install commands and hands them to the user (STOP line). Downstream, `star-plan-executor` runs every command through the `.env` environment and assumes it works. This skill produces that environment: a conda env or `.venv` resolved from `.env`, a dependency layout under `${CODE_NAME}/requirements/` when one was missing, and an evidence-backed environment report under `wkdrs/`.

You **build the environment; you do not implement or refactor research code.** The only writes into `${CODE_NAME}/` are generated requirements files. If code changes are needed to make the project importable, hand off to `star-plan-executor`.

## Core Principles

1. **`.env` is the only path source; never activate** (conventions §3). Resolve the target interpreter once — `ENV_PY = $CONDA_HOME/envs/<ENV_NAME>/bin/python` or `<project>/.venv/bin/python` — and run everything through that absolute path. This skill owns the environment: only it may create, rename, or install into one.
2. **Show the install plan; ask only for unresolved material choices.** A clear request to build or extend the named environment authorizes the matching plan once its dependencies and cost stay within that request. Ask via AskUserQuestion when the target, dependency set, CUDA choice, cost, or treatment of an existing environment remains unresolved; everything settled runs autonomously.
3. **Rename, never delete.** An existing environment is backed up by renaming it to `<name>_<YYYYMMDD>` — the date from `date +%Y%m%d` at run time, never invented. Stale backups are the user's to clean.
4. **Category is policy; the install order is uv > pip > conda.** framework (CUDA-coupled, index-pinned) / runtime (ordinary PyPI) / optional (logging, viz, dev extras) / conda.txt (system-isolation items). Each category has its own route and failure handling: prefer uv, fall back to pip per package, conda only for the whitelist and only under a conda backend. Policy: `references/installer_policy.md`.
5. **Adopt what exists; generate only what is missing.** Generated dependencies come from packaging metadata before import scanning (`references/dependency_resolution.md`), go into `requirements.txt` plus a `requirements/` folder, and are committed once the build is verified.
6. **Evidence-based acceptance.** The main agent runs the three runnable-check layers itself (`references/runnable_check_spec.md`) and reports what was verified with evidence, not that it "works" (CLAUDE.md §11). The report and version list go to `wkdrs/env_<ENV_NAME>_<date>/`.

## Workflow

**Where this run executes.** Apply the whole-run handoff in conventions §10.8 before Step 0 on the EXEC tier. Existing authorization of the concrete environment, dependency set, and cost counts; keep the run here only while a required decision remains.

### Step 0: Preliminary check

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. `ENV_NAME` := the argument, else `CODE_NAME`. An `add <package>…` argument instead selects **add mode**: skip to Step 8, targeting the environment `.env` already names — nothing created, renamed, or rebuilt.
3. Detect and record (feeds the install plan and the report): platform + arch; `nvidia-smi` (driver's CUDA ceiling); `nvcc --version` / `CUDA_HOME` (local toolkit, often absent); `$CONDA_HOME/bin/conda --version`; `uv --version`.
4. `${CODE_NAME}/` missing or effectively empty → no dependency source; recommend `star-code-architect` first, and offer a bare env (python only) if the user wants one anyway.

### Step 1: Choose the backend (deterministic)

- `CONDA_HOME` non-empty **and** the path exists → **conda backend**: `$CONDA_HOME/bin/conda create -n <ENV_NAME> python=<X.Y> -y`.
- Otherwise → **venv backend** at `<project>/.venv`: prefer `uv venv .venv --python <X.Y>`; else `$PYTHON_HOME/bin/python -m venv .venv`; last resort `python3 -m venv .venv`. `ENV_NAME` is meaningless here — say so if one was passed, then continue.
- Python version: `requires-python` (pyproject.toml) → `python_requires` (setup.py / setup.cfg) → the upstream README's stated version → default 3.10. Conflicting signals → ask.
- Record `ENV_PY` (absolute path) and use it for every later command.

### Step 2: When the environment already exists

- conda: `<ENV_NAME>` already in `conda env list` → honor a previously specified rebuild or repair choice; otherwise ask once between **backup & rebuild**, **verify & repair in place**, and **abort**, showing that clone-based backup may temporarily double disk use.
- venv: `.venv` exists → honor the same prior choice or ask once; backup is `mv .venv .venv_$(date +%Y%m%d)`. Note that a moved venv is a frozen backup because its scripts retain old absolute paths.
- Backup name already taken → append `-<HHMM>` (also from `date`).

### Step 3: Resolve dependencies (first signal wins)

Recipe and mapping table: `references/dependency_resolution.md`.

1. `${CODE_NAME}/requirements.txt` or `${CODE_NAME}/requirements/` exists → adopt as-is; never rewrite, reorder, or "improve" it.
2. Else packaging metadata — `pyproject.toml [project.dependencies]`, `setup.py` / `setup.cfg` `install_requires`, `environment.yml` — transcribe into the generated requirements files, keeping every version constraint.
3. Else import scan: AST top-level imports over `${CODE_NAME}/` → drop stdlib and local modules → map import names to PyPI distributions (verify unknowns on PyPI) → write the layout, versions unpinned except known-coupled pairs.

Generated layout: `requirements.txt` holds only `-r requirements/framework.txt` and `-r requirements/runtime.txt` lines (optional referenced as a comment); `requirements/framework.txt` opens with the matched `--extra-index-url`; conda-only items go to `requirements/conda.txt` with a "conda installs this, not pip" header. Written now, committed in Step 7 after the build is verified.

### Step 4: Settle the install plan

Present the backend, environment, Python version, dependency source, package counts and pins, torch↔CUDA match, rough large-wheel download size, conda-only items, and unresolved conflicts. If the request already authorizes this exact plan and introduces no new material cost or choice, proceed and record that authorization. Otherwise ask once via AskUserQuestion to build, adjust, or abort. Never hide an uncertainty.

### Step 5: Install (uv > pip > conda)

Policy, whitelist, and wheel-index matrix: `references/installer_policy.md`. Order: `conda.txt` (conda backend only) → `framework.txt` → `runtime.txt` → `optional.txt` (only if approved) → editable project install (`--no-deps -e`) when packaging metadata exists.

- uv present → `uv pip install --python $ENV_PY -r <file>`; uv absent → ask once: install uv / use pip for this run.
- Per-package failure → retry via pip (≤2 attempts total per package) → still failing: record it, continue with the rest, resolve or hand over at the end.
- venv backend hits a conda-only item → stop and ask: user installs it system-wide themselves / skip it / a pip alternative if one exists.
- Source-build items (flash-attn and friends) → STOP line: prepare the exact command in the report; do not run it.
- Respect `PIP_INDEX_URL` / `UV_DEFAULT_INDEX` already configured; never write global config.

### Step 6: Runnable check (three layers, run by the main agent)

Spec and evidence format: `references/runnable_check_spec.md`.

- **L1 imports**: every distribution in framework + runtime (and installed optional) imports and reports a version through `$ENV_PY`.
- **L2 framework**: `torch.cuda.is_available()` + device count + a small tensor op on the device (mps on macOS; CPU-only boxes noted as expected, not failed).
- **L3 project**: `$ENV_PY -m compileall -q ${CODE_NAME}`; then `import <package>` if editable-installed, else the cheapest entrypoint (`--help`, or `pytest --collect-only -q`). No data, no weights, no downloads — minutes, not hours.

A failed layer → diagnose from the traceback, fix (a missing transitive dep goes into the right generated requirements file), re-run it; ≤2 fix rounds per layer → still failing: mark it `blocked` with the error tail and continue where independent.

### Step 7: Report, version list, commit

1. Write `wkdrs/env_<ENV_NAME>_<YYYYMMDD>/ENV_REPORT.md` from `assets/env_report_template.md`: identity + `ENV_PY`, machine detection, backup renames, per-category install results, the runnable-check results with evidence, failures/blocked items, awaiting-user commands.
2. `uv pip freeze --python $ENV_PY` (or `$ENV_PY -m pip freeze`) → `freeze.txt` alongside the report.
3. Requirements files generated this run (including deps added while diagnosing runnable-check failures) are committed now: `star-env-builder: add requirements layout`, staging only `${CODE_NAME}/requirements*`.
4. `.env`'s `PYTHON_HOME` does not resolve to the verified `ENV_PY` → update it when that exact configuration change was authorized; otherwise show the proposed one-line change and ask because it changes a key runtime input.
5. Chat report ≤500 words: what was verified (with evidence), failures, awaiting-user commands. **Hand off downstream:** `star-plan-executor <leaf>` now has a runtime; `star-flow-status` shows what to run next.


### Step 8: Add packages (add mode only)

`add <package>…` runs this step and no other, and its seven items — resolving `ENV_PY`, categorising each package, the confirmation point nothing installs before, the tiered install, the runnable check on the new packages alone, the requirements and report updates, and the closing report — are in `references/add_mode.md`, read when that is the mode and not before. A run that builds or repairs an environment reads none of it.

## State & File Rules

- Write only to: the environment itself (under `$CONDA_HOME/envs/` or `<project>/.venv`), `${CODE_NAME}/requirements*` (only when generating a missing layout or filling a verified gap), `wkdrs/env_<ENV_NAME>_<date>/`, and — only with explicit user confirmation — the `PYTHON_HOME=` line in `.env`. Never touch source code, `metds/plans/*`, or other skills' outputs.
- Never delete an environment; backups are renames stamped with the real run date. Never invent timestamps.
- Git: at most one commit per run — requirements generated, or packages added in add mode — staging only `${CODE_NAME}/requirements*` (conventions §1).
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).
- Authorized installs run autonomously, including disclosed framework-scale downloads. The STOP line still covers `sudo` or system package managers, driver or CUDA-toolkit system installs, CUDA source compilation, downloads over ~10 GB, and deleting an environment; prepare exact commands instead.
- Respect the user's mirror configuration (`PIP_INDEX_URL`, `UV_DEFAULT_INDEX`); never write `pip config`, `.condarc`, or `uv.toml`.
- Repeat invocation: a matching `wkdrs/env_<ENV_NAME>_*/ENV_REPORT.md` exists and the env is present → prefer **verify & repair in place** (Step 2), resuming from its failures instead of rebuilding.

## Dialogue Discipline

- Apply conventions §7.2 and §7.7. Existing authorization of the same target, package set, and disclosed cost remains valid; ask one concrete question through AskUserQuestion only when one of those material inputs is still unresolved, with concise plain text as the fallback when unavailable.
- `ENV_REPORT.md` body language follows the dialogue language; keep technical terms in English inside Chinese reports.
