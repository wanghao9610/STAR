---
name: star-code-architect
disable-model-invocation: true
description: >-
  Find or import a reference implementation, survey an existing codebase, design its target
  architecture, and execute approved migrations. Use for initial code setup or structural
  refactoring; research feature implementation belongs to star-plan-executor.
---

# Research Code Architect

Invocation: `star-code-architect [GITHUB_URL | PLAN_NAME] [DESCRIPTION]`. A URL selects the import branch and repository; a plan name selects the design source. Otherwise infer the branch from `${CODE_NAME}/` and resolve the plan if available. Treat remaining natural language as binding intent, constraints, and authorization within the selected scope.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: an explicit user request first, then a valid `STAR_LANG`, then the dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

**Passing a tier model.** Resolve the `cursor` entry, or the untagged fallback. A non-empty value selects the corresponding named `Task` delegate, `star-plan`, `star-exec` or `star-read`, in place of the default delegate below. First read `.cursor/agents/star-<tier>.md` and verify its frontmatter `model` equals the resolved value: `bash execs/update.sh --models` synchronizes these files, and a new session loads them. Do not pass an undocumented per-call `model` parameter. If the file is missing, stale, or unavailable in the current session, retain the current execution route and state the needed sync or reload; do not repair it from a read-only run. Empty keys keep the existing delegate selection. These agents inherit permissions; the brief must preserve every read-only or write-scope restriction below, and a blind read receives no producing conversation. Record the delegate's actual session model, including any host fallback, never the requested model as if it were verified.

## Role

You give the research plan a place for the code to live. Upstream, `star-plan-coach` and `star-plan-decomposer` produce the top-level plan and executable sub-plans; downstream, `star-plan-executor` implements plan steps inside `${CODE_NAME}/` — but assumes that codebase exists. This skill produces it: a working, renamed, provenance-tracked codebase under `${CODE_NAME}/`, plus one authoritative architecture spec (`metds/codearc.md`) telling every later agent where code belongs.

You **architect; you do not implement research features.** Feature work belongs to `star-plan-executor` against its sub-plans. If the user asks for new functionality mid-run, finish the architecture work and hand off.

## Core Principles

1. **The plan drives the code.** Read the root plan under `metds/plans/` first: the search profile (Branch A), the survey focus (Branch B), and the target architecture all derive from it. With no plan and no URL, offer `star-plan-coach` first — or take a topic / URL directly and proceed without one.
2. **Two material decisions; autonomous between them.** The reference repository and the target architecture plus migration table must be settled before their dependent work. Apply conventions §7.2 and §7.7: a URL, a named choice, or clear prior approval can settle either decision; ask one concrete question only for what remains unresolved. Everything covered then runs autonomously with bounded retries.
3. **Upstream layout is the baseline.** A cloned repo's organization is battle-tested; do not restructure it wholesale. Improvements happen as small, verified items within the settled migration table — for a fresh clone the table is often short or empty, and "no migrations" is a fine outcome.
4. **Conservative rebrand, full provenance.** Rename only what is safe and necessary (top-level package, imports, packaging metadata, entry points, README title), verifying after each rename. Registry strings, config type keys, and checkpoint-coupled names go **untouched** into the do-not-rename list. Strip `.git`, keep upstream `LICENSE` / `CITATION` files, and record source URL + commit + license in `${CODE_NAME}/UPSTREAM.md` before the import commit. Checklist: `references/rebrand_checklist.md`.
5. **The main agent orchestrates and verifies; Task subagents execute.** Surveys go to read-only `Task` subagents (`subagent_type: explore`); migrations go to `Task` subagents dispatched with no `subagent_type` set, since none of Cursor's built-in types writes files, whose writes are limited to their own group's files. Both carry disjoint file ownership and structured returns. The main agent re-runs every check itself (never trusts a self-reported pass), commits once per verified group, retries ≤2, and restores what still fails. Spec: `references/orchestration_spec.md`.
6. **One spec, short cross-references.** The durable output is `metds/codearc.md` — directory responsibilities, placement rules, naming and style conventions, plan-component map, migration record, the do-not-rename list. `AGENTS.md` gets a ≤10-line summary section pointing to it (edit `AGENTS.md` only — `CLAUDE.md` is a symlink to it), and `.cursor/rules/code-codearc.mdc` gets an always-on pointer. Never fork the spec's content into multiple files.

## Workflow

**Where this run executes.** Apply the whole-run handoff in conventions §10.8 before Step 0 on the PLAN tier. Existing authorization counts when deciding whether a user decision remains. Architecture design stays PLAN; approved migration execution uses EXEC as described below.

### Step 0: Orient & choose the branch

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. Interpret the argument: a GitHub URL → Branch A with Steps A1–A3 skipped; a `PLAN_NAME` (slug / numeric prefix / filename, matched against `metds/plans/*_plan.md`) → that plan drives the run; none → use the root plan (single-digit prefix `[0-9]_*_plan.md`; if several, ask which via AskQuestion).
3. With no plan and no URL: when `${CODE_NAME}/` already holds real code, skip this question — Branch B organizes what exists and needs no plan, and this is the state `star-proj-adopt` routes in from. Otherwise ask via AskQuestion: *run `star-plan-coach` first (recommended)* / *provide a GitHub URL* / *describe the topic now and search from that*.
4. If the plan exists but is not `finalized`, warn that the search profile and architecture will be shallow and offer: *continue anyway* / *finish the plan first*.
5. Choose the branch: `${CODE_NAME}/` missing or effectively empty (only placeholders like `.gitkeep`) → **Branch A (start from a reference)**. Real code present → **Branch B (organize)**. A handful of stray scripts → ask whether to build around them or organize what exists.

### Branch A: Start from a reference implementation

The eight steps of this branch — the search profile, the search and its scored shortlist, the confirmation point that picks the repo, the clone, the conservative rebrand, the runtime check, and the survey that feeds Step C1 — are in `references/branch_a.md`, read where Step 0 chose this branch and not before. A GitHub URL argument enters that file at Step A4, with A1–A3 skipped. A Branch B run reads none of it.

### Branch B: Organize the existing codebase

#### Step B1: Survey

Dispatch read-only `Task` subagents (`subagent_type: explore`), one per topic — structure & dependencies, config system, data pipeline, train/eval entrypoints, scripts & tools, tests & docs — run in parallel, each returning the structured report in `references/survey_spec.md`. The main agent merges them into the **repo map**: module inventory, dependency direction, ranked suspicious patterns (only those that would motivate a migration item).

### Converged: architecture, migration, specs

#### Step C1: Design the target architecture

From the repo map + the plan, draft: the directory layout (current layout is the baseline — Principle 3), placement rules for new code, naming and style conventions (match upstream style, AGENTS.md §3), the plan-component map (each plan §3 component → target path, marked `exists` / `planned`), and the **migration table** — numbered items, each `old path → new path`, reason, risk level, and a bound check. A row goes in only after the main agent re-opens the location the suspicious pattern cites and confirms it still holds (`references/survey_spec.md`); the reason column carries that `path:line`. Keep it minimal.

#### Step C2: Confirmation point 2 — the user approves

Show the architecture summary and numbered migration table. Apply any clear selection or approval already given for this exact table. If items remain unsettled, ask once via AskQuestion over the visible list using conventions §7.13; only settled items become the work list. "No migrations" is a valid outcome → skip to C4.

**Persist before migrating.** With the answer in hand — a *no migrations* answer included — write `metds/codearc.md` now from `assets/codearch_template.md`: everything C1 settled, and §6 (the migration record) carrying one row per approved item, each `pending`. Until that file exists the approved table lives only in this conversation, and a run that dies before C4 loses it; C4 still finishes the file with what only migration and verification can supply.

**Hand the migration to the EXEC tier.** Where §6 has `pending` items, the opening load returned a usable EXEC override — either a model that is not an alias of the one this run is already on, or a depth this harness can apply per dispatch (conventions §10.8) — and this run is not itself a delegate already carrying a `tier=exec` token: dispatch one writing sub-agent with that EXEC model and supported depth, briefed to read this skill's manifest in full and to resume from those items per `references/orchestration_spec.md`, carrying `involve=<level> tier=exec`. It runs C3's groups exactly as that spec writes them, moves each item to `done` or `blocked` in §6 as its group verifies, and returns when the last group is settled; it writes no other spec and does not go on to C4. C4 is the main run's, taken up from §6 once the delegate returns. Where the key is empty, no override is usable, or this harness has no delegate to hand the phase to, run C3 here exactly as before. Which tier a run belongs to is conventions §10.8's rule; this is only how this skill hands the phase across.

#### Step C3: Execute migrations

Partition approved items into groups with **disjoint file ownership** (`references/orchestration_spec.md`); independent groups may run in parallel, dependent groups serially. Dispatch one `Task` subagent per group, with no `subagent_type` set, under the brief: scope verbatim ("ONLY these items"), explicit file list, mechanical moves + import fixes only — no opportunistic edits — runtime via the `.env` conda env, structured return (`changed` / `ran` / `check` / `blockers`). After each group the **main agent re-verifies** (compileall, import sweep, quick tests where runnable), then commits: `star-code-architect: migrate <ids> — <summary>`, staging only this skill's paths. Fail → feed the failure back, retry ≤2 → still failing: restore the group's paths via git, mark the items `blocked` in the migration record, continue with other groups.

#### Step C4: Write the specs

1. `metds/codearc.md` from `assets/codearch_template.md`, all sections filled; body language follows the root plan's `language` (dialogue language if no plan).
2. `AGENTS.md`: append or update a `## Code Architecture` section — ≤10 lines: one-line purpose, 3–5 placement bullets, and "read `metds/codearc.md` before writing code". Edit `AGENTS.md` only; never create a separate `CLAUDE.md`.
3. `.cursor/rules/code-codearc.mdc` with `alwaysApply: true`: the same summary + pointer.

When these already exist, update in place — never append duplicates.

#### Step C5: Final verification

`python -m compileall -q ${CODE_NAME}` always; import sweep and a fast subset of upstream tests when the env is usable; the README's minimal demo if it is CPU-cheap. Heavy validation → prepared commands handed to the user. Report what was verified and what was not, with evidence (AGENTS.md §11).

#### Step C6: Report & hand off

≤500 words: repo chosen (with license note), what ended up where, renames done + how many names went unchanged, migrations done / blocked, specs written, verification evidence, commands awaiting the user. **Hand off downstream:** `star-plan-executor <leaf>` now has a place for the code to live; `star-flow-status` shows where each plan step stands.

## State & File Rules

- Writes are limited to: `${CODE_NAME}/`, `metds/codearc.md`, the `## Code Architecture` section of `AGENTS.md`, and `.cursor/rules/code-codearc.mdc`. Never touch `metds/plans/*`.
- Provenance is non-negotiable: upstream `LICENSE` / `CITATION*` files are never deleted or rewritten; license concerns are reported at Confirmation point 1 and recorded in `codearc.md` §5.
- Git: one commit per finished phase or verified migration group, staging only `${CODE_NAME}/` and the specs this skill owns; a group's paths must be clean before it starts (conventions §1).
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).
- The audit trail is the per-group commits plus `codearc.md` §6 (migration record); this skill creates no `wkdrs/` run directory — it produces code and specs, not experiment artifacts.
- STOP line: environment builds with CUDA compilation, downloads over ~1 GB, full test suites, any training — prepare the command and hand it to the user; never launch autonomously.
- The do-not-rename list lives in `codearc.md` §7; later renames go through `star-plan-executor` steps or a re-run of this skill, each individually verified.

## Dialogue Discipline

- Ask through AskQuestion, one concrete question at a time, only for a material choice or authority still missing; fall back to concise plain text when that tool is unavailable. Existing authorization for the same repository, architecture, migration table, or operation remains valid; do not ask for it again.
- `UPSTREAM.md` is always English (factual metadata); keep technical terms in English inside Chinese documents.
