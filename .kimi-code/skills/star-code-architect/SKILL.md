---
name: star-code-architect
description: >-
  Bootstrap or reorganize the project codebase (${CODE_NAME}/, read from .env) so research plans under
  metds/plans/ have a code home. When ${CODE_NAME}/ is missing or empty: mine the plan for a search
  profile, find and score candidate reference implementations on GitHub (plan fit, completeness, license,
  activity), let the user pick one, then clone it, strip its git history, record provenance, and rebrand
  it to CODE_NAME. When code already exists: survey it with read-only subagents instead. Both paths then
  design a target architecture plus a migration table, execute only user-approved migrations via
  subagents with per-group verification and git checkpoints, and write the spec to metds/codearc.md with
  thin pointers in AGENTS.md and .cursor/rules/. Use when the user runs /skill:star-code-architect, wants
  a reference implementation or starter codebase for a plan, wants to set up / scaffold ${CODE_NAME}/, or
  wants to organize / refactor the existing codebase and record its architecture. Bilingual (en/zh).
---

# Research Code Architect — codebase bootstrap & organization

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/skill:star-code-architect [GITHUB_URL | PLAN_NAME]` — pass a GitHub URL to skip the search and use that repo, a plan name (slug / numeric prefix / filename) to choose which plan drives the search, or no argument to auto-resolve both.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You give the research plan a code home. Upstream, `star-plan-coach` and `star-plan-decomposer` produce the strategy and executable sub-plans; downstream, `star-plan-executor` implements plan steps inside `${CODE_NAME}/` — but assumes that codebase exists. This skill produces it: a working, renamed, provenance-tracked codebase under `${CODE_NAME}/`, plus one authoritative architecture spec (`metds/codearc.md`) that tells every later agent where code belongs.

You **architect; you do not implement research features.** Feature work belongs to `star-plan-executor` against its sub-plans. If the user asks for new functionality mid-run, finish the architecture work and hand off.

## Core Principles

1. **The plan drives the code.** Read the root plan under `metds/plans/` first: the search profile (Branch A), the survey focus (Branch B), and the target architecture all derive from it. With no plan and no URL, offer to run `/skill:star-plan-coach` first — or take a topic / URL directly and proceed without one.
2. **Two gates; autonomous between them.** Gate 1: the user picks the reference repo from a scored shortlist. Gate 2: the user approves the target architecture and migration table. Everything between and after runs autonomously with bounded retries. Never do work a gate did not cover.
3. **Upstream layout is the baseline.** A cloned repo's organization is battle-tested; do not restructure it wholesale. Improvements happen as small, individually-approved, individually-verified migration items — for a fresh clone the migration table is often short or empty, and "no migrations" is a fine outcome.
4. **Conservative rebrand, full provenance.** Rename only what is safe and necessary (top-level package, imports, packaging metadata, entry points, README title), with a verification step after each rename. Registry strings, config type keys, and checkpoint-coupled names go **untouched** into a residual list. Strip `.git`, keep upstream `LICENSE` / `CITATION` files, and record source URL + commit + license in `${CODE_NAME}/UPSTREAM.md` before the import commit. Checklist: `references/rebrand_checklist.md`.
5. **The main loop orchestrates and verifies; subagents execute.** Surveys and migrations are delegated to narrow subagents with disjoint file ownership and structured returns. The main loop re-runs every check itself (never trusts a self-reported pass), commits a git checkpoint per verified group, retries ≤2, and rolls back what still fails. Contract: `references/orchestration_spec.md`.
6. **One spec, thin pointers.** The durable output is `metds/codearc.md` — directory responsibilities, placement rules, naming and style conventions, plan-component map, migration record, rename residuals. `AGENTS.md` gets a ≤10-line summary section pointing to it (edit `AGENTS.md` only — `CLAUDE.md` is a symlink to it), and `.cursor/rules/code-codearc.mdc` gets an always-on pointer. Never fork the spec's content into multiple files.

## Workflow

### Step 0: Orient & choose the branch

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. Interpret the argument: a GitHub URL → Branch A with Steps A1–A3 skipped; a `PLAN_NAME` (slug / numeric prefix / filename, matched against `metds/plans/*_plan.md`) → that plan drives the run; none → use the root plan (single-digit prefix `[0-9]_*_plan.md`; if several, ask which in the conversation).
3. If there is no plan and no URL, ask in the conversation: *run `/skill:star-plan-coach` first (recommended)* / *provide a GitHub URL* / *describe the topic now and search from that*.
4. If the plan exists but is not `finalized`, warn that the search profile and architecture will be shallow and offer: *continue anyway* / *finish the plan first*.
5. Choose the branch: `${CODE_NAME}/` missing or effectively empty (only placeholders like `.gitkeep`) → **Branch A (bootstrap)**. Real code present → **Branch B (organize)**. Only a handful of stray scripts → ask whether to bootstrap around them or organize what exists.

### Branch A: Bootstrap from a reference implementation

#### Step A1: Build the search profile

Extract from the plan: task domain, method keywords, framework and version constraints, baselines named in §2/§4, dataset and tooling needs. Show the profile as a short block before searching. Recipe: `references/repo_rubric.md`.

#### Step A2: Search & shortlist

Prefer `gh search repos` / `gh api` (structured stars / license / pushed_at), plus web search for official implementations of the baselines the plan names. Shortlist 5–10; skip archived repos, demo-only repos, and awesome-lists; prefer the origin repo over forks. If `gh` is unavailable or unauthenticated, fall back to web search. If nothing viable turns up, say so honestly and offer: refine the profile / start from a minimal from-scratch skeleton.

#### Step A3: Score the shortlist

Score each candidate with the rubric (`references/repo_rubric.md`): plan fit 30, completeness 20, license 15, activity 15, code quality 10, environment match 10. Shallow-read each README (and setup files if needed) — do not clone yet.

#### Step A4: Gate 1 — the user picks the repo

Present the top 3–5 in the conversation, one option per candidate: one-line why-it-fits, license, stars, last update, main risk. Always include an escape option ("none of these — refine the search / start from scratch"). If invoked with a URL, still show that repo's license, activity, and risks, and confirm before cloning.

#### Step A5: Land the clone

1. Shallow-clone to a temporary directory; record URL, commit SHA, commit date, and license.
2. If the implementation is a subdirectory of a monorepo, confirm the sub-path with the user and take only it.
3. Remove `.git`; move the content into `${CODE_NAME}/`; keep upstream `LICENSE` and `CITATION*` files in place.
4. Write `${CODE_NAME}/UPSTREAM.md` from `assets/upstream_template.md`.
5. Commit the import (stage only `${CODE_NAME}/`): `star-code-architect: import <repo> @ <short-sha>`.

#### Step A6: Conservative rebrand

Follow `references/rebrand_checklist.md`: top-level package directory, all imports, packaging metadata (`setup.py` / `pyproject.toml` name, packages, console entry points), README title and install snippets. After each rename: grep the old name to verify the count dropped as expected, then `python -m compileall -q ${CODE_NAME}` (needs no dependencies). Names on the do-not-touch list (registry strings, config `type:` keys, checkpoint `state_dict` prefixes, logger/wandb project names) go into the **residual table** for `codearc.md` §7. Commit: `star-code-architect: rebrand to <CODE_NAME>`.

#### Step A7: Runtime smoke (STOP-line aware)

If a usable conda env from `.env` exists, run `python -c "import <package>"` through it. Environment creation and dependency installation are usually heavy: prepare the exact commands (`conda create …`, `pip install -r …`); run light pure-Python installs only with the user's explicit in-session consent; anything with CUDA compilation or downloads over ~1 GB is always handed to the user (STOP line, `references/orchestration_spec.md`). Record what ran vs what is awaiting the user. For the full build, hand off to `/skill:star-env-builder` — it owns backend choice, dependency resolution, the tiered install, and smoke verification under its own install-plan gate.

#### Step A8: Light survey

Complete the repo map for Step C1 with a single read-only pass (`references/survey_spec.md`, light mode) — the scoring pass already covered the coarse structure; for small repos the main loop may do this itself.

### Branch B: Organize the existing codebase

#### Step B1: Survey

Dispatch read-only subagents, one per concern lane — structure & dependencies, config system, data pipeline, train/eval entrypoints, scripts & tools, tests & docs — at most 3 in parallel, each returning the structured report in `references/survey_spec.md`. The main loop merges them into the **repo map**: module inventory, dependency direction, ranked smells (only smells that would motivate a migration item).

### Converged: architecture, migration, specs

#### Step C1: Design the target architecture

From the repo map + the plan, draft: the directory layout (current layout is the baseline — Principle 3), placement rules for new code, naming and style conventions (match upstream style, CLAUDE.md §3), the plan-component map (each plan §3 component → target path, marked `exists` / `planned`), and the **migration table** — numbered items, each `old path → new path`, reason, risk level, and a bound check. Keep it minimal.

#### Step C2: Gate 2 — the user approves

Show the architecture summary and the numbered migration table as normal text. Then ask in the conversation: with ≤4 migration items, list them for individual approval; with more, offer *approve all* / *approve all except (name the numbers)* / *redesign*. Only approved items become the work list. "No migrations" is a valid outcome → skip to C4.

#### Step C3: Execute migrations

Partition approved items into groups with **disjoint file ownership** (`references/orchestration_spec.md`); independent groups may run ≤3 in parallel, dependent groups serially. Dispatch one subagent per group with the contract: scope verbatim ("ONLY these items"), explicit file list, mechanical moves + import fixes only — no opportunistic edits — runtime via the `.env` conda env, structured return (`changed` / `ran` / `check` / `blockers`). After each group the **main loop re-verifies** (compileall, import sweep, quick tests where runnable), then commits: `star-code-architect: migrate <ids> — <summary>`, staging only this skill's paths. Fail → feed the failure back, retry ≤2 → still failing: roll the group's paths back via git, mark the items `blocked` in the migration record, continue with other groups.

#### Step C4: Write the specs

1. `metds/codearc.md` from `assets/codearch_template.md`, all sections filled; body language follows the root plan's `language` (dialogue language if no plan).
2. `AGENTS.md`: append or update a `## Code Architecture` section — ≤10 lines: one-line purpose, 3–5 placement bullets, and "read `metds/codearc.md` before writing code". Edit `AGENTS.md` only; never create a separate `CLAUDE.md`.
3. `.cursor/rules/code-codearc.mdc` with `alwaysApply: true`: the same summary + pointer.

When these already exist, update in place — never append duplicates.

#### Step C5: Final verification

`python -m compileall -q ${CODE_NAME}` always; import sweep and a fast subset of upstream tests when the env is usable; the README's minimal demo if it is CPU-cheap. Heavy validation → prepared commands handed to the user. Report what was verified and what was not, with evidence (CLAUDE.md §7).

#### Step C6: Report & hand off

≤400 words: repo chosen (with license note), what landed where, renames done + residual count, migrations done / blocked, specs written, verification evidence, commands awaiting the user. **Hand off downstream:** `/skill:star-plan-executor <leaf>` now has a code home; `/skill:star-flow-status` shows the tree.

## State & File Rules

- Writes are limited to: `${CODE_NAME}/`, `metds/codearc.md`, the `## Code Architecture` section of `AGENTS.md`, and `.cursor/rules/code-codearc.mdc`. Never touch `metds/plans/*`.
- Provenance is non-negotiable: `${CODE_NAME}/UPSTREAM.md` exists before the import commit; upstream `LICENSE` / `CITATION*` files are never deleted or rewritten; license concerns are surfaced at Gate 1 and recorded in `codearc.md` §5.
- Git: one commit per landed phase or verified migration group, staging only `${CODE_NAME}/` and the specs this skill owns; a group's paths must be clean before it starts (conventions §1).
- The audit trail is the git checkpoints plus `codearc.md` §6 (migration record); this skill creates no `wkdrs/` run directory — it produces code and specs, not experiment artifacts.
- STOP line: environment builds with CUDA compilation, downloads over ~1 GB, full test suites, any training — prepare the command and hand it to the user; never launch autonomously.
- The residual rename list lives in `codearc.md` §7; later renames go through `star-plan-executor` steps or a re-run of this skill, each individually verified.

## Dialogue Discipline

- Both gates and all questions are asked in the conversation — one at a time. If it is unavailable (non-interactive `kimi -p`), fall back to plain text, still one question at a time, and require an explicit approval message before any gate-crossing side effect.
- `metds/codearc.md` body language follows the root plan's `language` (dialogue language if no plan); `UPSTREAM.md` is always English (factual metadata); keep technical terms in English inside Chinese documents.
