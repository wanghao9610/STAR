---
name: star-env-builder
disable-model-invocation: true
description: >-
  Build and verify the project's Python runtime environment so plan execution has a working
  interpreter. Reads .env: a valid CONDA_HOME creates conda env ENV_NAME (argument, default
  CODE_NAME); otherwise a .venv under the project root. An existing environment is never
  deleted — after user confirmation it is renamed to a dated backup (real run date) before
  rebuilding. Dependencies resolve first-signal-wins: existing CODE_NAME/requirements* →
  packaging metadata (pyproject / setup.py / environment.yml) → import scan of the code,
  with generated results written to a two-tier layout (requirements.txt referencing
  requirements/framework|runtime|optional.txt; conda-only items in requirements/conda.txt).
  Installs through a uv > pip > conda ladder with CUDA-aware framework wheel selection
  behind a single install-plan gate, then smoke-tests in three layers (imports →
  framework/GPU → project entrypoint) and writes ENV_REPORT.md plus a version freeze under
  wkdrs/. Use when the user runs /star-env-builder, wants the project's conda env or venv
  created or rebuilt, needs dependencies resolved and installed, or wants the runtime
  environment verified. Bilingual (en/zh).
---

# Research Env Builder — runtime environment bootstrap

Match the user's language; load `*_zh.md` resources for Chinese dialogue.

Invocation: `/star-env-builder [ENV_NAME | add <package>…]` — the conda environment name to create, omitted to use `CODE_NAME` from `.env`; `add` installs one or more packages into the environment `.env` already names and records them in the requirements layout.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You give the codebase a working runtime. Upstream, `star-code-architect` lands `${CODE_NAME}/` but stops at the environment — its runtime-smoke step prepares install commands and hands them to the user (STOP line). Downstream, `star-plan-executor` runs every command through the `.env` environment and assumes it works. This skill produces that environment: a conda env or `.venv` resolved from `.env`, a dependency layout under `${CODE_NAME}/requirements/` when one was missing, and an evidence-backed environment report under `wkdrs/`.

You **build the environment; you do not implement or refactor research code.** The only writes into `${CODE_NAME}/` are generated requirements files. If code changes are needed to make the project importable, hand off to `star-plan-executor`.

## Core Principles

1. **`.env` is the only path source; never activate** (conventions §3). Resolve the target interpreter once — `ENV_PY = $CONDA_HOME/envs/<ENV_NAME>/bin/python` or `<project>/.venv/bin/python` — and run everything through that absolute path. This skill owns the environment: it is the only one that may create, rename, or install into one.
2. **One gate; situational asks.** The single gate is install-plan approval (Step 4): nothing installs before it; everything it covers runs autonomously after it. Situational questions — overwrite an existing env, a CUDA mismatch, uv missing, a conda-only dependency under a venv backend — are asked when hit, as plain-text questions, one at a time, each with a recommendation; wait for an explicit answer before acting.
3. **Rename, never delete.** An existing environment is backed up by renaming to `<name>_<YYYYMMDD>` — the date from `date +%Y%m%d` at run time, never invented. This skill deletes no environment, ever; stale backups are the user's to clean.
4. **Category is policy; the ladder is uv > pip > conda.** framework (CUDA-coupled, index-pinned) / runtime (ordinary PyPI) / optional (logging, viz, dev extras) / conda.txt (system-isolation items). Each category has its own install route and failure handling: prefer uv, fall back to pip per package, use conda only for the whitelist and only under a conda backend. Policy: `references/installer_policy.md`.
5. **Adopt what exists; generate only what is missing.** An existing requirements layout is installed as-is, never rewritten. Generated dependencies come from packaging metadata before import scanning (`references/dependency_resolution.md`), land in the two-tier layout, and are committed as a code asset once the build is verified.
6. **Evidence-based acceptance.** The main loop runs the three smoke layers itself (`references/smoke_test_spec.md`) and reports what was verified with evidence, not that it "works" (AGENTS.md §7). Chats end, files do not: the report and version freeze go to `wkdrs/env_<ENV_NAME>_<date>/`.

## Workflow

### Step 0: Preflight

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. `ENV_NAME` := the argument, else `CODE_NAME`. An `add <package>…` argument instead selects **add mode**: skip to Step 8, targeting the environment `.env` already names — nothing is created, renamed, or rebuilt.
3. Probe and record (this feeds the install plan and the report): platform + arch; `nvidia-smi` (driver's CUDA ceiling); `nvcc --version` / `CUDA_HOME` (local toolkit, often absent); `$CONDA_HOME/bin/conda --version`; `uv --version`.
4. `${CODE_NAME}/` missing or effectively empty → there is no dependency source; recommend `/star-code-architect` first, and offer to build a bare env (python only) if the user wants one anyway.

### Step 1: Choose the backend (deterministic)

- `CONDA_HOME` non-empty **and** the path exists → **conda backend**: `$CONDA_HOME/bin/conda create -n <ENV_NAME> python=<X.Y> -y`.
- Otherwise → **venv backend** at `<project>/.venv`: prefer `uv venv .venv --python <X.Y>`; else `$PYTHON_HOME/bin/python -m venv .venv`; last resort `python3 -m venv .venv`. An `ENV_NAME` argument is meaningless here — say so if one was passed, then continue.
- Python version: `requires-python` (pyproject.toml) → `python_requires` (setup.py / setup.cfg) → the upstream README's stated version → default 3.10. Conflicting signals → ask.
- Record `ENV_PY` (absolute path) and use it for every later command.

### Step 2: Collision handling

- conda: `<ENV_NAME>` already in `conda env list` → ask one question with three options: **backup & rebuild** (rename to `<ENV_NAME>_$(date +%Y%m%d)` via `conda rename`; older conda lacking `rename`: `create --clone` + `remove`, warn that disk usage doubles temporarily) / **verify & repair in place** (skip creation; jump to Step 5 for failed items or Step 6 — the resume path when a previous run was interrupted) / **abort** (exit cleanly, nothing touched).
- venv: `.venv` exists → same three-way ask → backup is `mv .venv .venv_$(date +%Y%m%d)`. Note in the report: a moved venv has its old absolute paths baked into scripts — it is a frozen backup for reference and rollback, not an activatable environment.
- Backup name already taken → append `-<HHMM>` (also from `date`).

### Step 3: Resolve dependencies (first signal wins)

Recipe and mapping table: `references/dependency_resolution.md`.

1. `${CODE_NAME}/requirements.txt` or `${CODE_NAME}/requirements/` exists → adopt as-is; never rewrite, reorder, or "improve" it.
2. Else packaging metadata — `pyproject.toml [project.dependencies]`, `setup.py` / `setup.cfg` `install_requires`, `environment.yml` — transcribe into the two-tier layout, keeping every version constraint.
3. Else import scan: AST top-level imports over `${CODE_NAME}/` → drop stdlib and local modules → map import names to PyPI distributions (verify unknowns on PyPI) → write the layout, versions unpinned except known-coupled pairs.

Generated layout: `requirements.txt` holds only `-r requirements/framework.txt` and `-r requirements/runtime.txt` lines (optional referenced as a comment); `requirements/framework.txt` opens with the matched `--extra-index-url`; conda-only items go to `requirements/conda.txt` with a "conda installs this, not pip" header. Files are written now, committed in Step 7 after the build is verified.

### Step 4: Gate — the user approves the install plan

Present as normal text: backend + env name + python version; dependency source used; per-category package counts and notable pins; the torch↔CUDA match (detected driver ceiling vs chosen wheel index); rough download size of the big wheels; conda.txt items; anything already flagged uncertain (CUDA mismatch, unresolved imports, version conflicts). Then ask as one plain-text question: *approve and build* / *adjust (say what)* / *abort* — wait for an explicit answer. Uncertainties are settled here — never silently.

### Step 5: Install (tiered ladder)

Policy, whitelist, and wheel-index matrix: `references/installer_policy.md`. Order: `conda.txt` (conda backend only) → `framework.txt` → `runtime.txt` → `optional.txt` (only if the approved plan included it) → editable project install (`--no-deps -e`) when packaging metadata exists.

- uv present → `uv pip install --python $ENV_PY -r <file>`; uv absent → ask once: install uv / use pip for this run.
- Per-package failure → retry via pip (≤2 attempts total per package) → still failing: record it, continue with the rest, resolve or hand over at the end.
- venv backend hits a conda-only item → stop and ask: user installs it system-wide themselves / skip it / use a pip alternative if one exists.
- Source-build items (flash-attn and friends) → STOP line: prepare the exact command in the report; do not run it.
- Respect `PIP_INDEX_URL` / `UV_DEFAULT_INDEX` already configured; never override the user's mirrors, never write global config.

### Step 6: Smoke test (three layers, run by the main loop)

Spec and evidence format: `references/smoke_test_spec.md`.

- **L1 imports**: every distribution in framework + runtime (and installed optional) imports and reports a version through `$ENV_PY`.
- **L2 framework**: `torch.cuda.is_available()` + device count + a small tensor op on the device (mps on macOS; CPU-only boxes noted as expected, not failed).
- **L3 project**: `$ENV_PY -m compileall -q ${CODE_NAME}`; then `import <package>` if editable-installed, else the cheapest entrypoint (`--help`, or `pytest --collect-only -q`). No data, no weights, no downloads — minutes, not hours.

A failed layer → diagnose from the traceback, fix (a missing transitive dep goes into the right generated requirements file), re-run the layer; ≤2 fix rounds per layer → still failing: mark it `blocked` with the error tail and continue where independent.

### Step 7: Report, snapshot, commit

1. Write `wkdrs/env_<ENV_NAME>_<YYYYMMDD>/ENV_REPORT.md` from `assets/env_report_template.md`: identity + `ENV_PY`, machine probe, backup renames, per-category install results, the smoke matrix with evidence, failures/blocked items, awaiting-user commands.
2. `uv pip freeze --python $ENV_PY` (or `$ENV_PY -m pip freeze`) → `freeze.txt` alongside the report.
3. Requirements files generated this run (including deps added during smoke diagnosis) are committed now: `star-env-builder: add requirements layout`, staging only `${CODE_NAME}/requirements*`.
4. `.env`'s `PYTHON_HOME` does not resolve to the just-verified `ENV_PY` → downstream skills resolve the runtime from `.env`: offer to point `PYTHON_HOME` at the environment just built (conda: `$CONDA_HOME/envs/<ENV_NAME>`; venv: `<project>/.venv`) — only with explicit confirmation.
5. Chat report ≤400 words: what was verified (with evidence), failures, awaiting-user commands. **Hand off downstream:** `/star-plan-executor <leaf>` now has a runtime; `/star-plan-status` shows what to run next.


### Step 8: Add packages (add mode only)

The environment already exists; this mode installs into it and records what it installed. It creates, renames, and rebuilds nothing — a broken environment is a full run's job (Step 2's *verify & repair in place*).

1. Resolve `ENV_PY` from `.env` (Principle 1). No usable interpreter → say so and recommend a full `/star-env-builder` run; install nothing.
2. Categorise each package per `references/installer_policy.md` — framework / runtime / optional / conda-only — and say which requirements file each will land in.
3. **Gate** (Principle 2 — nothing installs before it): present the packages, their categories, the versions and index that will be used, the download size when it is large, and any CUDA coupling; ask *approve and install* / *adjust* / *abort*.
4. Install through the ladder (uv > pip > conda; conda only under a conda backend and only for the whitelist). A source-build item stays on the STOP line: prepare the exact command, do not run it.
5. Smoke the new packages only (`references/smoke_test_spec.md`): L1 — each imports and reports a version through `$ENV_PY`; a new framework package also gets L2. A failure → diagnose, one bounded retry, then mark it `blocked` and report; never leave a package installed but unverified.
6. Append each installed package to its requirements file, preserving the layout's existing order and pins. Append an `## Added <date>` block to the newest `wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md` (none exists → write a fresh report). Commit: `star-env-builder: add <packages>`, staging only `${CODE_NAME}/requirements*`.
7. Report ≤400 words: what installed, what each requirements file gained, the smoke evidence, anything blocked or awaiting the user.

## State & File Rules

- Writes are limited to: the environment itself (under `$CONDA_HOME/envs/` or `<project>/.venv`), `${CODE_NAME}/requirements*` (only when generating a missing layout or filling a verified gap), `wkdrs/env_<ENV_NAME>_<date>/`, and — only with explicit user confirmation — the `PYTHON_HOME=` line in `.env`. Never touch source code, `metds/plans/*`, or other skills' outputs.
- Never delete an environment; backups are renames stamped with the real run date. Never invent timestamps.
- Git: at most one commit per run — requirements generated, or packages added in add mode — staging only `${CODE_NAME}/requirements*` (conventions §1).
- Gate-approved installs run autonomously, including framework-scale downloads. STOP line regardless of approval: `sudo` or system package managers (apt / brew), driver or CUDA-toolkit system installs, CUDA source compilation (flash-attn-style builds), downloads over ~10 GB, deleting any environment. Prepare those as exact commands in the report instead.
- Respect the user's mirror configuration (`PIP_INDEX_URL`, `UV_DEFAULT_INDEX`); never write `pip config`, `.condarc`, or `uv.toml`.
- Re-invoke semantics: if a matching `wkdrs/env_<ENV_NAME>_*/ENV_REPORT.md` exists and the env is present, prefer **verify & repair in place** (Step 2) — resume from its failures instead of rebuilding.

## Dialogue Discipline

- Ask one plain-text question at a time, each with a recommendation, and wait for the answer (Cursor has no structured question tool); the install plan needs an explicit approval message before anything installs.
- `ENV_REPORT.md` body language follows the dialogue language; keep technical terms in English inside Chinese reports.
