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
  Build and verify the project's Python runtime so plan execution has a working interpreter. Reads .env:
  a valid CONDA_HOME creates conda env ENV_NAME (argument, default CODE_NAME); otherwise a .venv in the
  root. An existing environment is never deleted — after confirmation it is renamed to a dated backup
  first. Dependencies come from the first source that has them: existing CODE_NAME/requirements* →
  packaging metadata (pyproject / setup.py / environment.yml) → import scan of the code, written out as
  requirements.txt plus a requirements/ folder (framework|runtime|optional.txt, conda-only in conda.txt).
  Installs uv > pip > conda, CUDA-aware, behind one install-plan confirmation, then checks imports,
  framework/GPU and the entrypoint and writes ENV_REPORT.md under wkdrs/. Use when the user runs
  /star-env-builder, when a run names it as the next action, wants the conda env or venv created or
  rebuilt, needs dependencies resolved and installed, or wants the environment verified. Bilingual
  (en/zh).
---

# Research Env Builder — runtime environment setup

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/star-env-builder [ENV_NAME | add <package>…] [DESCRIPTION]` — the conda environment name to create, omitted to use `CODE_NAME` from `.env`; `add` installs one or more packages into the environment `.env` already names and records them in the requirements layout. Anything left after that is a description (conventions §7.12): in your own words, what this run is for — a lead the run may follow and may record, never an instruction that stands in for a confirmation point. Prose that matches none of the above is description alone: run as if no argument was given, and say so first. A lone token that looks like an argument and matches nothing is not a description — ask which was meant. `add` is the exception: every token after it is a package name, never a description. An optional `involve=low|medium|high` token may accompany any argument (e.g. `… involve=low`): it sets the `involve` level for this run (conventions §7.7), is part of neither the argument nor the description, and is stripped before either is read.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares — §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout; this file states what is specific to this one, and wins wherever it is stricter. Before acting, load it in one message, together with the two references every run reaches — the installer policy (Steps 5 and 8) and the runnable-check spec (Steps 6 and 8): the conventions file, `<this skill's directory>/references/installer_policy.md`, and `<this skill's directory>/references/runnable_check_spec.md` each as its own `Read` call, plus one Bash call in the same message, with the project root as the working directory, carrying exactly:

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
```

One message, four results — still one round trip. Keep the files out of the Bash command: each tool result has its own size limit, and a Bash result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid, and the conventions file alone is already past that limit before the two references stack on top. Bash carries only what only Bash can do — here, the `.env` lookup above. References tied to a single step stay lazy: `references/dependency_resolution.md` (Step 3) and `assets/env_report_template.md` (the report-writing steps) are read when their step arrives, not up front.

**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the `.env` lookup's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

You give the codebase a working runtime. Upstream, `star-code-architect` writes `${CODE_NAME}/` but stops at the environment — its runtime-check step prepares install commands and hands them to the user (STOP line). Downstream, `star-plan-executor` runs every command through the `.env` environment and assumes it works. This skill produces that environment: a conda env or `.venv` resolved from `.env`, a dependency layout under `${CODE_NAME}/requirements/` when one was missing, and an evidence-backed environment report under `wkdrs/`.

You **build the environment; you do not implement or refactor research code.** The only writes into `${CODE_NAME}/` are generated requirements files. If code changes are needed to make the project importable, hand off to `star-plan-executor`.

## Core Principles

1. **`.env` is the only path source; never activate** (conventions §3). Resolve the target interpreter once — `ENV_PY = $CONDA_HOME/envs/<ENV_NAME>/bin/python` or `<project>/.venv/bin/python` — and run everything through that absolute path. This skill owns the environment: it is the only one that may create, rename, or install into one.
2. **One confirmation point; situational asks.** The single confirmation point is install-plan approval (Step 4): nothing installs before it; everything it covers runs autonomously after it. Situational questions — overwrite an existing env, a CUDA mismatch, uv missing, a conda-only dependency under a venv backend — are asked when hit, via AskUserQuestion, one question per call, each with a recommendation.
3. **Rename, never delete.** An existing environment is backed up by renaming to `<name>_<YYYYMMDD>` — the date from `date +%Y%m%d` at run time, never invented. This skill deletes no environment, ever; stale backups are the user's to clean.
4. **Category is policy; the install order is uv > pip > conda.** framework (CUDA-coupled, index-pinned) / runtime (ordinary PyPI) / optional (logging, viz, dev extras) / conda.txt (system-isolation items). Each category has its own install route and failure handling: prefer uv, fall back to pip per package, use conda only for the whitelist and only under a conda backend. Policy: `references/installer_policy.md`.
5. **Adopt what exists; generate only what is missing.** An existing requirements layout is installed as-is, never rewritten. Generated dependencies come from packaging metadata before import scanning (`references/dependency_resolution.md`), go into `requirements.txt` plus a `requirements/` folder, and are committed once the build is verified.
6. **Evidence-based acceptance.** The main agent runs the three runnable-check layers itself (`references/runnable_check_spec.md`) and reports what was verified with evidence, not that it "works" (CLAUDE.md §11). Chats end, files do not: the report and version list go to `wkdrs/env_<ENV_NAME>_<date>/`.

## Workflow

### Step 0: Preliminary check

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. `ENV_NAME` := the argument, else `CODE_NAME`. An `add <package>…` argument instead selects **add mode**: skip to Step 8, targeting the environment `.env` already names — nothing is created, renamed, or rebuilt.
3. Detect and record (this feeds the install plan and the report): platform + arch; `nvidia-smi` (driver's CUDA ceiling); `nvcc --version` / `CUDA_HOME` (local toolkit, often absent); `$CONDA_HOME/bin/conda --version`; `uv --version`.
4. `${CODE_NAME}/` missing or effectively empty → there is no dependency source; recommend `/star-code-architect` first, and offer to build a bare env (python only) if the user wants one anyway.

### Step 1: Choose the backend (deterministic)

- `CONDA_HOME` non-empty **and** the path exists → **conda backend**: `$CONDA_HOME/bin/conda create -n <ENV_NAME> python=<X.Y> -y`.
- Otherwise → **venv backend** at `<project>/.venv`: prefer `uv venv .venv --python <X.Y>`; else `$PYTHON_HOME/bin/python -m venv .venv`; last resort `python3 -m venv .venv`. An `ENV_NAME` argument is meaningless here — say so if one was passed, then continue.
- Python version: `requires-python` (pyproject.toml) → `python_requires` (setup.py / setup.cfg) → the upstream README's stated version → default 3.10. Conflicting signals → ask.
- Record `ENV_PY` (absolute path) and use it for every later command.

### Step 2: When the environment already exists

- conda: `<ENV_NAME>` already in `conda env list` → ask one question with three options: **backup & rebuild** (rename to `<ENV_NAME>_$(date +%Y%m%d)` via `conda rename`; older conda lacking `rename`: `create --clone` + `remove`, warn that disk usage doubles temporarily) / **verify & repair in place** (skip creation; jump to Step 5 for failed items or Step 6 — the resume path when a previous run was interrupted) / **abort** (exit cleanly, nothing touched).
- venv: `.venv` exists → same three-way ask → backup is `mv .venv .venv_$(date +%Y%m%d)`. Note in the report: a moved venv has its old absolute paths baked into scripts — it is a frozen backup to consult or restore from, not an activatable environment.
- Backup name already taken → append `-<HHMM>` (also from `date`).

### Step 3: Resolve dependencies (first signal wins)

Recipe and mapping table: `references/dependency_resolution.md`.

1. `${CODE_NAME}/requirements.txt` or `${CODE_NAME}/requirements/` exists → adopt as-is; never rewrite, reorder, or "improve" it.
2. Else packaging metadata — `pyproject.toml [project.dependencies]`, `setup.py` / `setup.cfg` `install_requires`, `environment.yml` — transcribe into the generated requirements files, keeping every version constraint.
3. Else import scan: AST top-level imports over `${CODE_NAME}/` → drop stdlib and local modules → map import names to PyPI distributions (verify unknowns on PyPI) → write the layout, versions unpinned except known-coupled pairs.

Generated layout: `requirements.txt` holds only `-r requirements/framework.txt` and `-r requirements/runtime.txt` lines (optional referenced as a comment); `requirements/framework.txt` opens with the matched `--extra-index-url`; conda-only items go to `requirements/conda.txt` with a "conda installs this, not pip" header. Files are written now, committed in Step 7 after the build is verified.

### Step 4: Confirmation point — the user approves the install plan

Present as normal text: backend + env name + python version; dependency source used; per-category package counts and notable pins; the torch↔CUDA match (detected driver ceiling vs chosen wheel index); rough download size of the big wheels; conda.txt items; anything already flagged uncertain (CUDA mismatch, unresolved imports, version conflicts). Then ask via AskUserQuestion: *approve and build* / *adjust (say what)* / *abort*. Uncertainties are settled here — never silently.

### Step 5: Install (uv > pip > conda)

Policy, whitelist, and wheel-index matrix: `references/installer_policy.md` — arrived with the opening load. Order: `conda.txt` (conda backend only) → `framework.txt` → `runtime.txt` → `optional.txt` (only if the approved plan included it) → editable project install (`--no-deps -e`) when packaging metadata exists.

- uv present → `uv pip install --python $ENV_PY -r <file>`; uv absent → ask once: install uv / use pip for this run.
- Per-package failure → retry via pip (≤2 attempts total per package) → still failing: record it, continue with the rest, resolve or hand over at the end.
- venv backend hits a conda-only item → stop and ask: user installs it system-wide themselves / skip it / use a pip alternative if one exists.
- Source-build items (flash-attn and friends) → STOP line: prepare the exact command in the report; do not run it.
- Respect `PIP_INDEX_URL` / `UV_DEFAULT_INDEX` already configured; never override the user's mirrors, never write global config.

### Step 6: Runnable check (three layers, run by the main agent)

Spec and evidence format: `references/runnable_check_spec.md` — arrived with the opening load.

- **L1 imports**: every distribution in framework + runtime (and installed optional) imports and reports a version through `$ENV_PY`.
- **L2 framework**: `torch.cuda.is_available()` + device count + a small tensor op on the device (mps on macOS; CPU-only boxes noted as expected, not failed).
- **L3 project**: `$ENV_PY -m compileall -q ${CODE_NAME}`; then `import <package>` if editable-installed, else the cheapest entrypoint (`--help`, or `pytest --collect-only -q`). No data, no weights, no downloads — minutes, not hours.

A failed layer → diagnose from the traceback, fix (a missing transitive dep goes into the right generated requirements file), re-run the layer; ≤2 fix rounds per layer → still failing: mark it `blocked` with the error tail and continue where independent.

### Step 7: Report, version list, commit

1. Write `wkdrs/env_<ENV_NAME>_<YYYYMMDD>/ENV_REPORT.md` from `assets/env_report_template.md`: identity + `ENV_PY`, machine detection, backup renames, per-category install results, the runnable-check results with evidence, failures/blocked items, awaiting-user commands.
2. `uv pip freeze --python $ENV_PY` (or `$ENV_PY -m pip freeze`) → `freeze.txt` alongside the report.
3. Requirements files generated this run (including deps added while diagnosing runnable-check failures) are committed now: `star-env-builder: add requirements layout`, staging only `${CODE_NAME}/requirements*`.
4. `.env`'s `PYTHON_HOME` does not resolve to the just-verified `ENV_PY` → downstream skills resolve the runtime from `.env`: offer to point `PYTHON_HOME` at the environment just built (conda: `$CONDA_HOME/envs/<ENV_NAME>`; venv: `<project>/.venv`) — only with explicit confirmation.
5. Chat report ≤500 words: what was verified (with evidence), failures, awaiting-user commands. **Hand off downstream:** `/star-plan-executor <leaf>` now has a runtime; `/star-flow-status` shows what to run next.


### Step 8: Add packages (add mode only)

The environment already exists; this mode installs into it and records what it installed. It creates, renames, and rebuilds nothing — a broken environment is a full run's job (Step 2's *verify & repair in place*).

1. Resolve `ENV_PY` from `.env` (Principle 1). No usable interpreter → say so and recommend a full `/star-env-builder` run; install nothing.
2. Categorise each package per `references/installer_policy.md` — framework / runtime / optional / conda-only — and say which requirements file each will be recorded in.
3. **Confirmation point** (Principle 2 — nothing installs before it): present the packages, their categories, the versions and index that will be used, the download size when it is large, and any CUDA coupling; ask *approve and install* / *adjust* / *abort*.
4. Install in the uv > pip > conda order (conda only under a conda backend and only for the whitelist). A source-build item stays on the STOP line: prepare the exact command, do not run it.
5. Run the runnable check on the new packages only (`references/runnable_check_spec.md`): L1 — each imports and reports a version through `$ENV_PY`; a new framework package also gets L2. A failure → diagnose, one bounded retry, then mark it `blocked` and report; never leave a package installed but unverified.
6. Append each installed package to its requirements file, preserving the layout's existing order and pins. Append an `## Added <date>` block to the newest `wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md` (none exists → write a fresh report). Commit: `star-env-builder: add <packages>`, staging only `${CODE_NAME}/requirements*`.
7. Report ≤500 words: what installed, what each requirements file gained, the runnable-check evidence, anything blocked or awaiting the user.

## State & File Rules

- Writes are limited to: the environment itself (under `$CONDA_HOME/envs/` or `<project>/.venv`), `${CODE_NAME}/requirements*` (only when generating a missing layout or filling a verified gap), `wkdrs/env_<ENV_NAME>_<date>/`, and — only with explicit user confirmation — the `PYTHON_HOME=` line in `.env`. Never touch source code, `metds/plans/*`, or other skills' outputs.
- Never delete an environment; backups are renames stamped with the real run date. Never invent timestamps.
- Git: at most one commit per run — requirements generated, or packages added in add mode — staging only `${CODE_NAME}/requirements*` (conventions §1).
- Installs approved at the confirmation point run autonomously, including framework-scale downloads. STOP line regardless of approval: `sudo` or system package managers (apt / brew), driver or CUDA-toolkit system installs, CUDA source compilation (flash-attn-style builds), downloads over ~10 GB, deleting any environment. Prepare those as exact commands in the report instead.
- Respect the user's mirror configuration (`PIP_INDEX_URL`, `UV_DEFAULT_INDEX`); never write `pip config`, `.condarc`, or `uv.toml`.
- On a repeat invocation: if a matching `wkdrs/env_<ENV_NAME>_*/ENV_REPORT.md` exists and the env is present, prefer **verify & repair in place** (Step 2) — resume from its failures instead of rebuilding.

## Dialogue Discipline

- The confirmation point and all situational questions go through AskUserQuestion — one question per call, each with a recommendation. If it is unavailable (headless / scripted), fall back to plain text, still one at a time; the install plan then needs an explicit approval message before anything installs.
- Reply in the user's language; load `*_zh.md` resources for Chinese dialogue.
- `ENV_REPORT.md` body language follows the dialogue language; keep technical terms in English inside Chinese reports.
