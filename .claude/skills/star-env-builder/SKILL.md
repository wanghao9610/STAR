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
  star-env-builder, when a run names it as the next action, wants the conda env or venv created or
  rebuilt, needs dependencies resolved and installed, or wants the environment verified. Bilingual
  (en/zh).
---

# Research Env Builder — runtime environment setup

Match the user's language. `.env`'s `STAR_LANG` replaces it wherever it is set (conventions §7.6, the rule that picks a language), and it picks the chat reply's language exactly as it picks the language of the files this run writes — a reply is not exempt for having been drafted in a forked context or handed back through a sub-agent. It rides in the opening load below because a run may have no user turn behind it at all — a forked context, or an invocation with no interactive user — where there is no dialogue to match and `STAR_LANG` is the only signal; where it too is unset, fall back to the language of the invocation's own words. For Chinese, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Any other language loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `star-env-builder [ENV_NAME | add <package>…] [DESCRIPTION]` — the conda environment name to create, omitted to use `CODE_NAME` from `.env`; `add` installs packages into the environment `.env` already names and records them in the requirements layout. Anything left over is a description (conventions §7.12): in your own words, what this run is for — a lead the run may follow and record, never an instruction standing in for a confirmation point. Prose matching none of the above is description alone: run as if no argument was given, saying so first. A lone argument-like token that matches nothing is not a description — ask which was meant. `add` is the exception: every token after it is a package name. An optional `involve=low|medium|high` token may accompany any argument (e.g. `… involve=low`): it sets this run's `involve` level (conventions §7.7) and is stripped before the argument and description are read. A `tier=<name>` token, which the delegate of a relocated run carries (conventions §10.8), is stripped the same way as `involve=` before anything else is read, and is neither argument nor description.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What building a runtime acts on — §0 vocabulary, §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §7 dialogue, §8 the output table, §10 the skill roster — arrives through the opening load below. Three sections stay out: §6 delegation (the main agent runs the three runnable-check layers itself — Principle 6 and Step 6 say so, and no step here dispatches), §9 project layout (State & File Rules enumerate every path it may write, and every tree it may not, more strictly than that section states them), and §11 execution branches, whose nine items this skill never performs — it creates, merges and discards no branch and no worktree — and whose one rule for every other skill, that a commit made while the checkout sits on another run's execution branch rides into that leaf's merge, is restated in State & File Rules beside the commit rule it qualifies. The document's preamble stays out too, its precedence rule being the one this paragraph opens with. Read the whole file if a run ever needs one of them.

Before acting, load it in one message — three Bash calls with the project root as the working directory, plus a `Read` each of the two references every run reaches, the installer policy (Steps 5 and 8) and the runnable-check spec (Steps 6 and 8): `<this skill's directory>/references/installer_policy.md` and `<this skill's directory>/references/runnable_check_spec.md`, all sent together.

```bash
grep -sE '^(STAR_LANG|INVOLVE|STAR_(PLAN|EXEC|READ)_MODEL)=' .env || echo 'STAR_LANG / INVOLVE / STAR_*_MODEL: unset'   # reply language, question level, model tiers (§7.6, §7.7, §10.8)
awk '/^## /{k=/^## (0|1|2|3|4|5)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (10)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

One message, five results. `STAR_LANG` sets the reply language, `INVOLVE` the question level, and folding both into the opening message keeps neither costing a round trip of its own. The three model keys ride the same lookup: they are where this run and every delegate it dispatches take their model from (§10.8). The calls stay separate because each tool result carries its own size limit: a result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid — and the conventions excerpt is about 48 KB in total, split 14, 21 and 12 across its three calls. Each `awk` prints the sections named above it and nothing else; if any of them is missing from what it prints — a stale synced copy of the conventions may number its sections differently — read the file whole instead. References tied to a single step stay lazy: `references/dependency_resolution.md` (Step 3) and `assets/env_report_template.md` (the report-writing steps) are read when their step arrives, not up front.


**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and every value the `.env` lookup returned. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

**Passing a tier model.** Resolve the `claude` entry, or the untagged fallback, before dispatch. Pass the resolved value as `Agent`'s `model` for every delegate of that tier; omit it when empty. Use a model accepted by the current tool, preserving the role and write limits specified below. A blind read receives only its artifact and rubric, never the producing conversation. If the model is unavailable, keep the run here and give one reason; after a rejected dispatch, verify it started no work before falling back. The delegate resolves its own actual model from its own session provenance, never from the requested alias or the parent's transcript.

## Role

You give the codebase a working runtime. Upstream, `star-code-architect` writes `${CODE_NAME}/` but stops at the environment — its runtime-check step prepares install commands and hands them to the user (STOP line). Downstream, `star-plan-executor` runs every command through the `.env` environment and assumes it works. This skill produces that environment: a conda env or `.venv` resolved from `.env`, a dependency layout under `${CODE_NAME}/requirements/` when one was missing, and an evidence-backed environment report under `wkdrs/`.

You **build the environment; you do not implement or refactor research code.** The only writes into `${CODE_NAME}/` are generated requirements files. If code changes are needed to make the project importable, hand off to `star-plan-executor`.

## Core Principles

1. **`.env` is the only path source; never activate** (conventions §3). Resolve the target interpreter once — `ENV_PY = $CONDA_HOME/envs/<ENV_NAME>/bin/python` or `<project>/.venv/bin/python` — and run everything through that absolute path. This skill owns the environment: only it may create, rename, or install into one.
2. **One confirmation point; situational asks.** The single confirmation point is install-plan approval (Step 4): nothing installs before it; everything it covers runs autonomously after it. Situational questions — overwrite an existing env, a CUDA mismatch, uv missing, a conda-only dependency under a venv backend — are asked when hit, via AskUserQuestion.
3. **Rename, never delete.** An existing environment is backed up by renaming it to `<name>_<YYYYMMDD>` — the date from `date +%Y%m%d` at run time, never invented. Stale backups are the user's to clean.
4. **Category is policy; the install order is uv > pip > conda.** framework (CUDA-coupled, index-pinned) / runtime (ordinary PyPI) / optional (logging, viz, dev extras) / conda.txt (system-isolation items). Each category has its own route and failure handling: prefer uv, fall back to pip per package, conda only for the whitelist and only under a conda backend. Policy: `references/installer_policy.md`.
5. **Adopt what exists; generate only what is missing.** Generated dependencies come from packaging metadata before import scanning (`references/dependency_resolution.md`), go into `requirements.txt` plus a `requirements/` folder, and are committed once the build is verified.
6. **Evidence-based acceptance.** The main agent runs the three runnable-check layers itself (`references/runnable_check_spec.md`) and reports what was verified with evidence, not that it "works" (CLAUDE.md §11). The report and version list go to `wkdrs/env_<ENV_NAME>_<date>/`.

## Workflow

**Where this run executes.** Decide once, before the first step below, whether this run stays here or moves to its tier's model (conventions §10.8; the roster's tier column names the tier, and a mode listed there as an exception overrides it). It moves only when all four hold. The `STAR_<TIER>_MODEL` value the opening load returned names a model for this harness — where it carries `<harness>:<model>` entries, the entry tagged with the tree you are running from, an untagged entry where none is tagged for it, and neither present reading as empty (conventions §10.8). That value is not an alias of the model this run is already on — an alias being the family name inside the id, `opus` for `claude-opus-5[1m]`, or the id itself, a context-window suffix aside — where that model is what the resolver command in your session context's provenance line prints, run once here, or failing that the id the line states; where nothing names it, the run stays. This run is not itself a delegate carrying a `tier=` token — a token stripped from the invocation before anything else in it is read, like `involve=`. And no question this run would still put to the user is left in it — a confirmation point this manifest asks at every level, or a judgment call the resolved level still asks — judged now for this run's mode and level against the files on disk, because a delegate cannot put one to the user: a point that only what the run finds could raise counts as still open, a STOP-line hand-back is a return rather than a question, and a judgment call the level takes unasked is none. Moving means: dispatch one writing sub-agent on that model, briefed to read this skill's manifest in full and follow it, with the invocation text exactly as it arrived plus `involve=<level> tier=<tier>`, the dialogue language in one line where `STAR_LANG` is empty, and, where this run holds one, its `auto=unattended` grant; wait for it, relay its reply unchanged, and count the files it wrote as this run's artifacts, their provenance its model. An empty key changes nothing and is not mentioned; a set key that leaves the run here earns one line saying why. A harness that cannot name the model a delegate runs on stays in every case.

For this skill the fourth condition never holds — the install-plan approval, and in `add` mode the confirmation point nothing installs before, is asked at every level — so the run stays here.

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

- conda: `<ENV_NAME>` already in `conda env list` → ask one question, three options: **backup & rebuild** (rename to `<ENV_NAME>_$(date +%Y%m%d)` via `conda rename`; older conda lacking `rename`: `create --clone` + `remove`, warn that disk usage temporarily doubles) / **verify & repair in place** (skip creation; jump to Step 5 for failed items or Step 6 — the resume path after an interrupted run) / **abort** (exit cleanly, nothing touched).
- venv: `.venv` exists → same three-way ask → backup is `mv .venv .venv_$(date +%Y%m%d)`. Note in the report: a moved venv has old absolute paths baked into its scripts — a frozen backup to consult or restore from, not an activatable environment.
- Backup name already taken → append `-<HHMM>` (also from `date`).

### Step 3: Resolve dependencies (first signal wins)

Recipe and mapping table: `references/dependency_resolution.md`.

1. `${CODE_NAME}/requirements.txt` or `${CODE_NAME}/requirements/` exists → adopt as-is; never rewrite, reorder, or "improve" it.
2. Else packaging metadata — `pyproject.toml [project.dependencies]`, `setup.py` / `setup.cfg` `install_requires`, `environment.yml` — transcribe into the generated requirements files, keeping every version constraint.
3. Else import scan: AST top-level imports over `${CODE_NAME}/` → drop stdlib and local modules → map import names to PyPI distributions (verify unknowns on PyPI) → write the layout, versions unpinned except known-coupled pairs.

Generated layout: `requirements.txt` holds only `-r requirements/framework.txt` and `-r requirements/runtime.txt` lines (optional referenced as a comment); `requirements/framework.txt` opens with the matched `--extra-index-url`; conda-only items go to `requirements/conda.txt` with a "conda installs this, not pip" header. Written now, committed in Step 7 after the build is verified.

### Step 4: Confirmation point — the user approves the install plan

Present as normal text: backend + env name + python version; dependency source used; per-category package counts and notable pins; the torch↔CUDA match (detected driver ceiling vs chosen wheel index); rough download size of the big wheels; conda.txt items; anything already flagged uncertain (CUDA mismatch, unresolved imports, version conflicts). Then ask via AskUserQuestion: *approve and build* / *adjust (say what)* / *abort*. Uncertainties are settled here — never silently.

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
4. `.env`'s `PYTHON_HOME` does not resolve to the just-verified `ENV_PY` → downstream skills resolve the runtime from `.env`: offer to point `PYTHON_HOME` at it (conda: `$CONDA_HOME/envs/<ENV_NAME>`; venv: `<project>/.venv`) — only with explicit confirmation.
5. Chat report ≤500 words: what was verified (with evidence), failures, awaiting-user commands. **Hand off downstream:** `star-plan-executor <leaf>` now has a runtime; `star-flow-status` shows what to run next.


### Step 8: Add packages (add mode only)

`add <package>…` runs this step and no other, and its seven items — resolving `ENV_PY`, categorising each package, the confirmation point nothing installs before, the tiered install, the runnable check on the new packages alone, the requirements and report updates, and the closing report — are in `references/add_mode.md`, read when that is the mode and not before. A run that builds or repairs an environment reads none of it.

## State & File Rules

- Write only to: the environment itself (under `$CONDA_HOME/envs/` or `<project>/.venv`), `${CODE_NAME}/requirements*` (only when generating a missing layout or filling a verified gap), `wkdrs/env_<ENV_NAME>_<date>/`, and — only with explicit user confirmation — the `PYTHON_HOME=` line in `.env`. Never touch source code, `metds/plans/*`, or other skills' outputs.
- Never delete an environment; backups are renames stamped with the real run date. Never invent timestamps.
- Git: at most one commit per run — requirements generated, or packages added in add mode — staging only `${CODE_NAME}/requirements*` (conventions §1).
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).
- Installs approved at the confirmation point run autonomously, including framework-scale downloads. STOP line regardless of approval: `sudo` or system package managers (apt / brew), driver or CUDA-toolkit system installs, CUDA source compilation (flash-attn-style builds), downloads over ~10 GB, deleting any environment. Prepare those as exact commands in the report instead.
- Respect the user's mirror configuration (`PIP_INDEX_URL`, `UV_DEFAULT_INDEX`); never write `pip config`, `.condarc`, or `uv.toml`.
- Repeat invocation: a matching `wkdrs/env_<ENV_NAME>_*/ENV_REPORT.md` exists and the env is present → prefer **verify & repair in place** (Step 2), resuming from its failures instead of rebuilding.

## Dialogue Discipline

- The confirmation point and all situational questions go through AskUserQuestion — one question per call, each with a recommendation. If it is unavailable (headless / scripted), fall back to plain text, still one at a time; the install plan then needs an explicit approval message before anything installs.
- `ENV_REPORT.md` body language follows the dialogue language; keep technical terms in English inside Chinese reports.
