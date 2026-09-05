---
name: star-code-architect
disable-model-invocation: true
description: >-
  Set up or reorganize the project codebase (${CODE_NAME}/, from .env) so research plans under
  metds/plans/ have a place for the code to live. When ${CODE_NAME}/ is missing or empty: read the plan
  for what to search for, find and score candidate reference implementations on GitHub (plan fit,
  completeness, license, activity), let the user pick, then clone it, strip its git history, record
  provenance, and conservatively rebrand it to CODE_NAME. When code already exists: survey it with
  a read-only survey instead. Both paths then design a target architecture plus a migration table,
  execute only user-approved migrations one group at a time with verification and a commit per
  group, and write the spec to metds/codearc.md, cross-referenced in AGENTS.md.
  Use when the user runs star-code-architect, wants a reference implementation or starter codebase for a
  plan, wants to set up / scaffold ${CODE_NAME}/, or wants to organize / refactor the existing codebase.
  Bilingual (en/zh).
---

# Research Code Architect — codebase setup & organization

Match the user's language. `.env`'s `STAR_LANG` replaces it wherever it is set (conventions §7.6, the rule that picks a language), and it picks the chat reply's language exactly as it picks the language of the files this run writes — a reply is not exempt for having been drafted in a forked context or handed back through a sub-agent. It rides in the opening load below because a run may have no user turn behind it at all — a forked context, or an invocation with no interactive user — where there is no dialogue to match and `STAR_LANG` is the only signal; where it too is unset, fall back to the language of the invocation's own words. For Chinese, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Any other language loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `star-code-architect [GITHUB_URL | PLAN_NAME] [DESCRIPTION]` — pass a GitHub URL to skip the search and use that repo, a plan name (slug / numeric prefix / filename) to choose which plan drives the search, or no argument to auto-resolve both. Anything left is a description (conventions §7.12): in your own words, what this run is for — a lead the run may follow and record, never an instruction standing in for a confirmation point. Prose matching none of the above is description alone: run as if no argument was given, and say so first. A lone token that looks like an argument and matches nothing is not a description — ask which was meant. An optional `involve=low|medium|high` token may accompany any argument (e.g. `… involve=low`): it sets this run's `involve` level (conventions §7.7), belongs to neither the argument nor the description, and is stripped before either is read. A `tier=<name>` token, which the delegate of a relocated run carries (conventions §10.8), is stripped the same way as `involve=` before anything else is read, and is neither argument nor description.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What an architect acts on — §0 vocabulary, §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout, §10 the skill roster — arrives through the opening load below. One section stays out: §11 execution branches, whose nine items this skill never performs — it creates, merges and discards no branch and no worktree — and whose one rule for every other skill, that a commit made while the checkout sits on another run's execution branch rides into that leaf's merge, is restated in State & File Rules beside the commit rule it qualifies. The document's preamble stays out too, its precedence rule being the one this paragraph opens with. Read the whole file if a run ever needs one of them.

Before acting, load it in one message — three `bash` calls, with the project root as the working directory, sent together.

```bash
grep -sE '^(STAR_LANG|INVOLVE|STAR_(PLAN|EXEC|READ)_MODEL)=' .env || echo 'STAR_LANG / INVOLVE / STAR_*_MODEL: unset'   # reply language, question level, model tiers (§7.6, §7.7, §10.8)
awk '/^## /{k=/^## (0|1|2|3|4|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (9|10)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

One message, three results. `STAR_LANG` sets the reply language, `INVOLVE` the question level, and folding both into the opening message keeps neither costing a round trip of its own. The three model keys ride the same lookup: they are where this run and every delegate it dispatches take their model from (§10.8). The calls stay separate because each tool result carries its own size limit: a result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid — and the conventions excerpt is about 56 KB in total, split 21, 21 and 14 across its three calls. Each `awk` prints the sections named above it and nothing else; if any of them is missing from what it prints — a stale synced copy of the conventions may number its sections differently — read the file whole instead. These calls are this skill's only unconditional load: every file under `references/` and `assets/` belongs to one branch or step and is read where that step cites it, not front-loaded.


**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and every value the `.env` lookup returned. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

**Passing a tier model.** Resolve the `pi` entry, or the untagged fallback, using Pi's `provider/model` spelling. Pass it to `star_subagent` as `model` in single mode, or in each selected `tasks[]` / `chain[]` item. It overrides the named agent's model; an empty tier value omits the parameter and preserves inheritance. Use `star-auditor` for a blind read, `star-collector` for bounded collection, and `star-implementer` for execution actions. A whole skill or phase needs a general delegate: use `star-runner`, whose authority is that skill and the supplied brief. Every dispatch starts in a fresh process; preserve the scope and write limits below. If the installed extension has no `model` field or the model is unavailable, retain the current execution route and give one reason when the key is set. After a rejected dispatch, verify it started no work before falling back. The delegate records its actual session model, not the requested alias or the parent's resolver.

## Role

You give the research plan a place for the code to live. Upstream, `star-plan-coach` and `star-plan-decomposer` produce the top-level plan and executable sub-plans; downstream, `star-plan-executor` implements plan steps inside `${CODE_NAME}/` — but assumes that codebase exists. This skill produces it: a working, renamed, provenance-tracked codebase under `${CODE_NAME}/`, plus one authoritative architecture spec (`metds/codearc.md`) telling every later agent where code belongs.

You **architect; you do not implement research features.** Feature work belongs to `star-plan-executor` against its sub-plans. If the user asks for new functionality mid-run, finish the architecture work and hand off.

## Core Principles

1. **The plan drives the code.** Read the root plan under `metds/plans/` first: the search profile (Branch A), the survey focus (Branch B), and the target architecture all derive from it. With no plan and no URL, offer `star-plan-coach` first — or take a topic / URL directly and proceed without one.
2. **Two confirmation points; autonomous between them.** Confirmation point 1: the user picks the reference repo from a scored shortlist. Confirmation point 2: the user approves the target architecture and migration table. Everything between and after runs autonomously with bounded retries. Never do work a confirmation point did not cover.
3. **Upstream layout is the baseline.** A cloned repo's organization is battle-tested; do not restructure it wholesale. Improvements happen as small, individually-approved, individually-verified migration items — for a fresh clone the migration table is often short or empty, and "no migrations" is a fine outcome.
4. **Conservative rebrand, full provenance.** Rename only what is safe and necessary (top-level package, imports, packaging metadata, entry points, README title), verifying after each rename. Registry strings, config type keys, and checkpoint-coupled names go **untouched** into the do-not-rename list. Strip `.git`, keep upstream `LICENSE` / `CITATION` files, and record source URL + commit + license in `${CODE_NAME}/UPSTREAM.md` before the import commit. Checklist: `references/rebrand_checklist.md`.
5. **The main agent orchestrates and verifies; subagents execute.** Surveys go to read-only `star_subagent` dispatches (`agent: "star-collector"`); migrations go to `star_subagent` dispatches (`agent: "star-implementer"`) whose writes are limited to their own group's files. Both carry disjoint file ownership and structured returns. The main agent re-runs every check itself (never trusts a self-reported pass), commits once per verified group, retries ≤2, and restores what still fails. Spec: `references/orchestration_spec.md`.
6. **One spec, short cross-references.** The durable output is `metds/codearc.md` — directory responsibilities, placement rules, naming and style conventions, plan-component map, migration record, the do-not-rename list. `AGENTS.md` gets a ≤10-line summary section pointing to it (edit `AGENTS.md` only — `CLAUDE.md` is a symlink to it). That summary is the always-on pointer here and the only one: Pi loads `AGENTS.md` as a context file at startup, so there is no second always-on channel to keep in step. Never fork the spec's content into multiple files.

## Workflow

**Where this run executes.** Decide once, before the first step below, whether this run stays here or moves to its tier's model (conventions §10.8; the roster's tier column names the tier, and a mode listed there as an exception overrides it). It moves only when all four hold. The `STAR_<TIER>_MODEL` value the opening load returned names a model for this harness — where it carries `<harness>:<model>` entries, the entry tagged with the tree you are running from, an untagged entry where none is tagged for it, and neither present reading as empty (conventions §10.8). That value is not an alias of the model this run is already on — an alias being the family name inside the id, `opus` for `claude-opus-5[1m]`, or the id itself, a context-window suffix aside — where that model is what the resolver command in your session context's provenance line prints, run once here, or failing that the id the line states; where nothing names it, the run stays. This run is not itself a delegate carrying a `tier=` token — a token stripped from the invocation before anything else in it is read, like `involve=`. And no question this run would still put to the user is left in it — a confirmation point this manifest asks at every level, or a judgment call the resolved level still asks — judged now for this run's mode and level against the files on disk, because a delegate cannot put one to the user: a point that only what the run finds could raise counts as still open, a STOP-line hand-back is a return rather than a question, and a judgment call the level takes unasked is none. Moving means: dispatch one writing sub-agent on that model, briefed to read this skill's manifest in full and follow it, with the invocation text exactly as it arrived plus `involve=<level> tier=<tier>`, the dialogue language in one line where `STAR_LANG` is empty, and, where this run holds one, its `auto=unattended` grant; wait for it, relay its reply unchanged, and count the files it wrote as this run's artifacts, their provenance its model. An empty key changes nothing and is not mentioned; a set key that leaves the run here earns one line saying why. A harness that cannot name the model a delegate runs on stays in every case.

For this skill the fourth condition never holds — Confirmation point 2, the user's approval of the target architecture and the migration table, is asked at every level in both branches before anything is written, and Branch A adds Confirmation point 1, the repo pick, unless a GitHub URL settles it — so the run stays here; its tier change is the hand-over of the approved migrations to the EXEC tier, below.

### Step 0: Orient & choose the branch

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. Interpret the argument: a GitHub URL → Branch A with Steps A1–A3 skipped; a `PLAN_NAME` (slug / numeric prefix / filename, matched against `metds/plans/*_plan.md`) → that plan drives the run; none → use the root plan (single-digit prefix `[0-9]_*_plan.md`; if several, ask which).
3. With no plan and no URL: when `${CODE_NAME}/` already holds real code, skip this question — Branch B organizes what exists and needs no plan, and this is the state `star-proj-adopt` routes in from. Otherwise ask: *run `star-plan-coach` first (recommended)* / *provide a GitHub URL* / *describe the topic now and search from that*.
4. If the plan exists but is not `finalized`, warn that the search profile and architecture will be shallow and offer: *continue anyway* / *finish the plan first*.
5. Choose the branch: `${CODE_NAME}/` missing or effectively empty (only placeholders like `.gitkeep`) → **Branch A (start from a reference)**. Real code present → **Branch B (organize)**. A handful of stray scripts → ask whether to build around them or organize what exists.

### Branch A: Start from a reference implementation

The eight steps of this branch — the search profile, the search and its scored shortlist, the confirmation point that picks the repo, the clone, the conservative rebrand, the runtime check, and the survey that feeds Step C1 — are in `references/branch_a.md`, read where Step 0 chose this branch and not before. A GitHub URL argument enters that file at Step A4, with A1–A3 skipped. A Branch B run reads none of it.

### Branch B: Organize the existing codebase

#### Step B1: Survey

Survey by topic — structure & dependencies, config system, data pipeline, train/eval entrypoints, scripts & tools, tests & docs — one read-only `star_subagent` dispatch each (`agent: "star-collector"`), each returning the structured report in `references/survey_spec.md`. Merge them into the **repo map**: module inventory, dependency direction, ranked suspicious patterns (only those that would motivate a migration item).

### Converged: architecture, migration, specs

#### Step C1: Design the target architecture

From the repo map + the plan, draft: the directory layout (current layout is the baseline — Principle 3), placement rules for new code, naming and style conventions (match upstream style, AGENTS.md §3), the plan-component map (each plan §3 component → target path, marked `exists` / `planned`), and the **migration table** — numbered items, each `old path → new path`, reason, risk level, and a bound check. A row goes in only after the main agent re-opens the location the suspicious pattern cites and confirms it still holds (`references/survey_spec.md`); the reason column carries that `path:line`. Keep it minimal.

#### Step C2: Confirmation point 2 — the user approves

Show the architecture summary and the numbered migration table as normal text. Then ask: with ≤4 items, ask over the numbered ones and let the user reply with the numbers to approve; with more, offer *approve all* / *approve all except (name the numbers)* / *answer my questions on the ones I name first* / *redesign* — the list-then-one-question shape conventions §7.13 defines. Wait for the explicit answer; only approved items become the work list. "No migrations" is a valid outcome → skip to C4.

**Persist before migrating.** With the answer in hand — a *no migrations* answer included — write `metds/codearc.md` now from `assets/codearch_template.md`: everything C1 settled, and §6 (the migration record) carrying one row per approved item, each `pending`. Until that file exists the approved table lives only in this conversation, and a run that dies before C4 loses it; C4 still finishes the file with what only migration and verification can supply.

**Hand the migration to the EXEC tier.** Where §6 has `pending` items, the `STAR_EXEC_MODEL` value the opening load returned is non-empty and not an alias of the model this run is already on (conventions §10.8), and this run is not itself a delegate already carrying a `tier=exec` token: dispatch one writing sub-agent on that model, briefed to read this skill's manifest in full and to resume from those items per `references/orchestration_spec.md`, carrying `involve=<level> tier=exec`. It runs C3's groups exactly as that spec writes them, moves each item to `done` or `blocked` in §6 as its group verifies, and returns when the last group is settled; it writes no other spec and does not go on to C4. C4 is the main run's, taken up from §6 once the delegate returns. Where the key is empty, its value an alias of the model this run is on, or this harness has no delegate to hand the phase to, run C3 here exactly as before. Which tier a run belongs to is conventions §10.8's rule; this is only how this skill hands the phase across.

#### Step C3: Execute migrations

Partition approved items into groups with **disjoint file ownership** (`references/orchestration_spec.md`); independent groups may run in parallel, dependent groups serially. Dispatch one `star_subagent` (`agent: "star-implementer"`) per group with the brief: scope verbatim ("ONLY these items"), explicit file list, mechanical moves + import fixes only — no opportunistic edits — runtime via the `.env` conda env, structured return (`changed` / `ran` / `check` / `blockers`). After each group the **main agent re-verifies** (compileall, import sweep, quick tests where runnable), then commits: `star-code-architect: migrate <ids> — <summary>`, staging only this skill's paths. Fail → feed the failure back, retry ≤2 → still failing: restore the group's paths via git, mark the items `blocked` in the migration record, continue with other groups.

#### Step C4: Write the specs

1. `metds/codearc.md` from `assets/codearch_template.md`, all sections filled; body language follows the root plan's `language` (dialogue language if no plan).
2. `AGENTS.md`: append or update a `## Code Architecture` section — ≤10 lines: one-line purpose, 3–5 placement bullets, and "read `metds/codearc.md` before writing code". Edit `AGENTS.md` only; never create a separate `CLAUDE.md`.
3. Nothing else. Pi reads `AGENTS.md` at startup, so item 2 is already the always-on pointer; do not write a second copy of the summary anywhere.

When these already exist, update in place — never append duplicates.

#### Step C5: Final verification

`python -m compileall -q ${CODE_NAME}` always; import sweep and a fast subset of upstream tests when the env is usable; the README's minimal demo if it is CPU-cheap. Heavy validation → prepared commands handed to the user. Report what was verified and what was not, with evidence (AGENTS.md §11).

#### Step C6: Report & hand off

≤500 words: repo chosen (with license note), what ended up where, renames done + how many names went unchanged, migrations done / blocked, specs written, verification evidence, commands awaiting the user. **Hand off downstream:** `star-plan-executor <leaf>` now has a place for the code to live; `star-flow-status` shows where each plan step stands.

## State & File Rules

- Writes are limited to: `${CODE_NAME}/`, `metds/codearc.md`, and the `## Code Architecture` section of `AGENTS.md`. Never touch `metds/plans/*`.
- Provenance is non-negotiable: upstream `LICENSE` / `CITATION*` files are never deleted or rewritten; license concerns are reported at Confirmation point 1 and recorded in `codearc.md` §5.
- Git: one commit per finished phase or verified migration group, staging only `${CODE_NAME}/` and the specs this skill owns; a group's paths must be clean before it starts (conventions §1).
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).
- The audit trail is the per-group commits plus `codearc.md` §6 (migration record); this skill creates no `wkdrs/` run directory — it produces code and specs, not experiment artifacts.
- STOP line: environment builds with CUDA compilation, downloads over ~1 GB, full test suites, any training — prepare the command and hand it to the user; never launch autonomously.
- The do-not-rename list lives in `codearc.md` §7; later renames go through `star-plan-executor` steps or a re-run of this skill, each individually verified.

## Dialogue Discipline

- Both confirmation points and all questions go through `star_questionnaire` — one question per call: still one at a time, and an explicit approval message is required before anything past a confirmation point is written or run.
- `UPSTREAM.md` is always English (factual metadata); keep technical terms in English inside Chinese documents.
