---
name: star-proj-adopt
disable-model-invocation: true
description: >-
  Adopt an existing project into STAR by surveying it, mapping files and historical work, adding
  minimal workflow scaffolding, then backfilling confirmed progress into a later plan tree. Use for
  repositories that did not start from STAR; preserve existing data and code.
---

# Research Project Adopt — bring an in-progress project into STAR

Invocation: `star-proj-adopt [survey | backfill] [DESCRIPTION]`. Resolve the phase first: no adoption record selects `survey`; an adoption record plus a decomposed tree selects `backfill`; an explicit phase wins. Re-running `survey` updates the record. Natural language may settle mappings, selected historical runs, or backfill rows within its stated scope.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: an explicit user request first, then a valid `STAR_LANG`, then the dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

**Passing a tier model and depth.** Resolve the `kimi` entry, or the untagged fallback, before dispatch. When the current `Agent` / `AgentSwarm` schema exposes `model`, pass the resolved value on each dispatch of that tier; it must be an alias accepted by the configured secondary-model pool. Where the entry carries a depth, pass instead the pool alias that binds that model at that depth — conventionally `<model>-<depth>`, a `[models]` variant with that `default_effort` the user registers in the pool (conventions §10.8) — and a configured depth is reason enough to dispatch even when the tier model is an alias of this session's; where no pool entry binds that depth, pass the model alone and say once that the depth went unapplied. An empty value omits the parameter. With no selectable pool, forced pool selection, or an unavailable alias, retain the current execution route and state why when the key is set; do not edit the user's global Kimi configuration. A blind read starts without the producing conversation. Keep the role and write limits below. After a rejected dispatch, verify it started no work before falling back. The delegate records its own actual session model, never the requested alias or the parent's resolver.

## Role

Every other STAR skill assumes a project begun from the template: `.env` configured, layout in place, plans under `metds/plans/` describing work not yet done. You exist for the project that did not — real code, a working environment, months of commits, results in hand. You make it legible to the rest of the family **without asking it to change**: nothing moves, nothing is renamed, nothing already written is overwritten.

You are the on-ramp, not the driver. You do not survey the code architecture (`star-code-architect` Branch B owns that), do not author research strategy (`star-plan-coach` and `star-plan-decomposer` own the plan tree), and do not judge results (`star-expt-analyst`). You establish the runtime, record what exists as evidence, and later reconcile it with the tree the coach and decomposer build.

## Core Principles

1. **Never overwrite, never move, never rename.** Existing files keep their content, directories their location and name, and STAR uses the working environment already present. When a proposed write conflicts, honor any specific handling already authorized; otherwise show the content and ask because valuable existing work is at stake. `CODE_NAME` keeps the source directory's current name.
2. **Reach large directories, do not relocate them.** Existing data, weights, and output trees are wired in with symlinks at `datas/`, `inits/`, `wkdrs/` so `DATA_DIR` / `INIT_DIR` / `WORK_DIR` resolve, while every absolute path in existing code and scripts keeps working. A directory already in the right place needs no link; a link is never created over a non-empty real directory.
3. **Evidence, not recall.** Every row of the work inventory cites its source — a path, a commit, a script, a log line. What the repository does not show is recorded as unknown and asked about, never inferred from the shape of a typical project.
4. **Reconstruction is always labeled.** A record written after the fact is not an execution record. Every historical run recorded this way carries a header: reconstructed during adoption, on what date, from what evidence — so no later reader mistakes it for `star-plan-executor` output.
5. **Adoption does not invent research strategy.** You can read what was built and run; not why, what claim it serves, or what would have killed it. The inventory stays descriptive; §4-style claims and kill-criteria are left for `star-plan-coach` to elicit from the user. A plan tree fabricated from a git log is worse than no plan tree.
6. **The narrow write on plans.** `metds/plans/*` belongs to the coach, decomposer, executor, and reviser. The sole exception is `exec_status:` and `exec_runs:` on leaves in `backfill`, limited to rows the user has already selected or accepts from the visible proposal. Plan bodies and all other state remain untouched.
7. **Settle three material choices; automate the rest.** Before dependent writes, settle the survey mapping, which historical runs to record, and the proposed backfill rows. Apply clear choices already present in the request or session; ask only for unresolved rows or mappings under conventions §7.2 and §7.7.

## Workflow

After resolving the phase, read `references/adopt_spec.md` for `survey` or `references/backfill.md` for `backfill`; do not load the other branch.

**Where this run executes.** Apply the whole-run handoff in conventions §10.8 before Step 0. `survey` uses EXEC and `backfill` uses PLAN. A mapping, historical-run selection, or backfill choice already settled by the request is not asked again.

### Phase `survey`

#### Step S1: Survey (read-only)

Detect, without writing anything: candidate source directories (top-level importable packages, the one the entrypoints import), the runtime in use (`conda env list`, a `.venv`, `which python`, an env name in existing scripts), where data / weights / outputs live, the launch entrypoints and how they are invoked, the existing tests, and the git history shape (first commit, commit count, active paths). Present the mapping as one compact block, marking every low-confidence line.

The survey may fan out **by area** — source, runtime, data, weights, outputs, entrypoints — one read-only `Agent` subagent (`subagent_type: explore`) each, run in parallel, each briefed verbatim: "read-only — do not run the project's code, do not import its package, do not create or repair any environment; write nothing." Each returns findings, evidence paths, alternatives and unknowns — and **no confidence label**: in `adopt_spec.md` confidence decides what reaches Confirmation point 1, so the main agent assigns `certain` / `likely` / `unknown` itself. Confirming a `certain` line takes a command (`test -d`, an interpreter version check), not a re-read, so the repository's bulk never comes back. This is the expensive part of an unfamiliar repository; S4 below builds on what these areas gathered instead of walking their sources again.

#### Step S2: Confirmation point 1 — confirm the mapping

Apply mapping choices already stated by the user. For any unresolved `CODE_NAME`, `PYTHON_HOME`, or data / weights / output root, ask one concrete question via AskUserQuestion from the surveyed candidates before dependent writes.

#### Step S3: Put the mechanical setup in place

In this order, each step reported as done or skipped-because-it-exists:

1. `.env` — from `.env.example` when absent. Preserve existing values unless the user specifically authorized the shown conflicting-key change; otherwise ask only about those keys.
2. Symlinks for `datas/`, `inits/`, `wkdrs/` per Principle 2. Skip and say so when the path is a non-empty real directory.
3. `execs/` — `run.sh` and `update.sh` only if missing. For each launch entrypoint, one `execs/scpts/<name>.sh` that **calls the project's existing command**, unchanged, through the exported paths. Never rewrite the project's own launcher.
4. Verify: `bash execs/run.sh --list` lists the wrappers, and the resolved interpreter reports its version. Report what ran and what did not.

#### Step S4: Build the work inventory

From git log, the entrypoints, the output directories, and the README, assemble the inventory defined in `references/adopt_spec.md`: one row per identifiable unit of finished or in-flight work — what it is, its state (`built` / `run` / `concluded` / `abandoned`), and its evidence paths. This is the seed `star-plan-coach` reads; a description of the repository, not a plan (Principle 5). The S1 areas already walked git history, the entrypoints and the output directories: build from what they returned, opening only what none covered. The main agent merges and owns every judgment, including the rule that two commits plus an output directory describing one thing is one row.

#### Step S5: Confirmation point 2 — record the historical runs worth keeping

List the prior runs — path, date, apparent output, and any visible logged metric. Apply an existing selection; if it does not settle the list, ask once via AskUserQuestion over the visible rows. Symlink each chosen run to `wkdrs/<run>/` and write a minimal reconstructed `EXEC_LOG.md` from `assets/exec_log_reconstructed.md`; keep all others as inventory evidence and report the count omitted.

#### Step S6: Write the record & route

Write `metds/adopt.md` from `assets/adopt_template.md`. Then route, in order: `star-code-architect` for the architecture spec, `star-plan-coach` for the research plan, `star-plan-decomposer` for the leaves, and finally `star-proj-adopt backfill` to make the tree reflect what is already done.

### Phase `backfill`

This phase matches the work inventory against the decomposed plan tree and proposes the `exec_status` each match earns. Its steps, and the matching rules that were section 7 of `adopt_spec.md`, are in `references/backfill.md`, read where Step 0 resolved this phase and not before. A `survey` run reads none of it.

## State & File Rules

- The durable output is `metds/adopt.md` (conventions §8). Writes are otherwise limited to: `.env`, the `datas/` / `inits/` / `wkdrs/` symlinks, `execs/run.sh`, `execs/update.sh`, `execs/scpts/*.sh`, the recorded `wkdrs/<run>/` links and their reconstructed `EXEC_LOG.md`, and — in `backfill` only — the two frontmatter fields on confirmed leaves.
- Never touched in either phase: `${CODE_NAME}/` and everything under it, the project's own launchers, configs, and CI, `metds/ideas/**`, `metds/refs/**`, `metds/codearc.md`, the compiled `metds/*.md`, and every part of a plan file outside those two fields.
- Real dates only, from the system clock (conventions §4) — the adoption date, each recorded run's date, the backfill date.
- STOP line (conventions §2): nothing here trains, evaluates, installs, or deletes. The survey is read-only, the verification is `--list` plus an interpreter version check. Environment repair belongs to `star-env-builder`; a runtime that cannot run python is a blocker to report, not one to fix.
- Git: offered once at the end of each phase, staging only the paths this skill wrote — `star-proj-adopt: <phase> — <summary>` (conventions §1). `.env` and the ignored trees stay out of history. A path that already carried uncommitted changes when the run started is never staged — common in an adopted repository: name those paths rather than working around them.
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).

## Dialogue Discipline

- Ask one concrete question at a time through AskUserQuestion only for a mapping, run selection, backfill row, overwrite, or other material authority still unresolved; use concise plain text if the tool is unavailable. Existing explicit choices for the same scope remain valid and are not asked again.
- **Material a question is about goes in the text of the same message, above the call** — the prior-run list, the proposed leaf rows. The options carry the answers and none of the material; read the message back before it goes out: options with nothing above them mean the material was skipped, not shortened.
- Lead with what the survey found and what it could not settle — a confidently wrong `CODE_NAME` costs the user every downstream skill.
- Say plainly what adoption did **not** do: read the code architecture, write a research plan, judge any result. Name the skill that owns each.
- `metds/adopt.md` body language follows the dialogue language at creation and is kept on re-run. Keep paths, package names, commit SHAs, and metric names in English inside Chinese documents.
