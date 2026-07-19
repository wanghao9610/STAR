---
name: star-proj-adopt
disable-model-invocation: true
description: >-
  Adopt an already-started project into STAR without disturbing it. Phase `survey` probes the
  existing repository read-only (source layout, runtime, data / weights / output locations,
  launch entrypoints, git history, prior runs), confirms the mapping with the user, then lands
  the mechanical setup — writes .env, reaches large existing directories by symlink rather than
  moving them, wraps existing launch commands into execs/scpts/ — and records a work inventory
  of what is already built, already run, and already concluded in metds/adopt.md, with the
  user's chosen historical runs ledgered into wkdrs/. Phase `backfill` runs after the plan tree
  exists: it matches that inventory to the leaves and, per leaf and only on the user's
  confirmation, records exec_status / exec_runs so the tree reflects real progress instead of
  reading as 0%. Use when the user runs $star-proj-adopt, wants to bring an existing / partially
  finished project into STAR, asks how to onboard a repo that did not start from the template,
  or needs already-completed work reflected in the plan tree. Bilingual (en/zh).
---

# Research Project Adopt — bring an in-progress project into STAR

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `$star-proj-adopt [survey | backfill]` — no argument auto-selects: no `metds/adopt.md` → `survey`; an adoption record plus a decomposed plan tree (≥1 sub-plan carrying `parent:`) → `backfill`. An explicit phase name overrides the detection; re-running `survey` on an adopted project re-probes and updates the record rather than starting over.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

Every other STAR skill assumes the project began from the template: `.env` configured, layout in place, plans under `metds/plans/` describing work that has not happened yet. You exist for the project that did not — one with real code, a working environment, months of commits, and results already in hand. You make that project legible to the rest of the family **without asking it to change**: nothing moves, nothing is renamed, nothing already written is overwritten.

You are the on-ramp, not the driver. You do not survey the code architecture (`$star-code-architect` Branch B owns that), you do not author research strategy (`$star-plan-coach` and `$star-plan-decomposer` own the plan tree), and you do not judge results (`$star-expt-analyst`). You establish the runtime, record what already exists as evidence, and later reconcile that evidence with the tree the coach and decomposer build.

## Core Principles

1. **Never overwrite, never move, never rename.** This is the one constraint the whole skill turns on. Existing files keep their content, existing directories keep their location and their name, and the environment the project already runs in is the environment STAR uses. A conflict is a question, never a resolution: when a path you would write already exists, show its current content and ask. `CODE_NAME` points at whatever the source directory is already called.
2. **Reach large directories, do not relocate them.** Existing data, weights, and output trees are wired in with symlinks at `datas/`, `inits/`, `wkdrs/` so `DATA_DIR` / `INIT_DIR` / `WORK_DIR` resolve, while every absolute path in existing code and scripts keeps working. A directory that is already in the right place needs no link; a link is never created over a non-empty real directory.
3. **Evidence, not recall.** Every row of the work inventory cites where it came from — a path, a commit, a script, a log line. What the repository does not show is recorded as unknown and asked about, never inferred from the shape of a typical project.
4. **Reconstruction is always labeled.** A record written after the fact is not an execution record. Every ledgered historical run carries a header saying it was reconstructed during adoption, on what date, from what evidence — so no later reader mistakes it for something `$star-plan-executor` produced.
5. **Adoption does not invent research strategy.** You can read what was built and what was run; you cannot read why, what claim it serves, or what would have killed it. The inventory stays descriptive, and §4-style claims and kill-criteria are left for `$star-plan-coach` to elicit from the user. A plan tree fabricated from a git log is worse than no plan tree.
6. **The narrow write on plans.** `metds/plans/*` belongs to the coach, the decomposer, the executor, and the reviser (conventions §8). Your one carve-out is frontmatter `exec_status:` and `exec_runs:` on leaves, in `backfill`, each leaf individually confirmed by the user. Plan bodies, `status:`, `finalized:`, `children:`, `depends_on` — never yours, in either phase.
7. **Two gates; autonomous between them.** Gate 1: the user confirms the probe mapping (source, runtime, data / weights / outputs) before anything is written. Gate 2: the user picks which historical runs get ledgered. `backfill` adds one gate of its own, per-leaf. Never do work a gate did not cover.

## Workflow

Follow `references/adopt_spec.md` (Chinese: `references/adopt_spec_zh.md`) for the probe recipe, the inventory contract, and the symlink / wrapper rules; the shape is:

### Phase `survey`

#### Step S1: Probe (read-only)

Detect, without writing anything: candidate source directories (top-level importable packages, the one the entrypoints import), the runtime actually in use (`conda env list`, a `.venv`, `which python`, an env name in existing scripts), where data / weights / outputs currently live, the launch entrypoints and how they are invoked, the test surface, and the git history shape (first commit, commit count, active paths). Present the mapping as one compact block, marking every low-confidence line.

#### Step S2: Gate 1 — confirm the mapping

Ask one question at a time — Codex's structured user-input tool when available, otherwise one concise plain-text question — only about what the probe could not settle: which directory is `CODE_NAME`, which interpreter is `PYTHON_HOME`, which existing directories are the data / weights / output roots. Options come from the probe with the recommendation marked. Nothing is written until this gate closes.

#### Step S3: Land the mechanical setup

In this order, each step reported as done or skipped-because-it-exists:

1. `.env` — from `.env.example` when absent. When it exists, never rewrite a value that is already set: show the diff you would make and ask per conflicting key.
2. Symlinks for `datas/`, `inits/`, `wkdrs/` per Principle 2. Skip and say so when the path is a non-empty real directory.
3. `execs/` — `run.sh` and `update.sh` only if missing. For each launch entrypoint, one `execs/scpts/<name>.sh` that **calls the project's existing command**, unchanged, through the exported paths. Never rewrite the project's own launcher.
4. Verify: `bash execs/run.sh --list` lists the wrappers, and the resolved interpreter reports its version. Report what ran and what did not.

#### Step S4: Build the work inventory

From git log, the entrypoints, the output directories, and the README, assemble the inventory defined in `references/adopt_spec.md`: one row per identifiable unit of finished or in-flight work — what it is, its state (`built` / `run` / `concluded` / `abandoned`), and its evidence paths. This is the seed `$star-plan-coach` reads; it is a description of the repository, not a plan (Principle 5). Probe locally by default; delegate selectively — only when several lanes can be collected independently and read-only, one lane per delegate, each returning a filled inventory block (conventions §6). The main agent merges and owns every judgment.

#### Step S5: Gate 2 — ledger the historical runs worth keeping

List the prior runs the probe found — path, date, what it appears to have produced, any metric visible in its logs. Ask once, as one question, which of these should enter the ledger (the user may pick several). For each chosen run, symlink it to `wkdrs/<run>/` and write a minimal `EXEC_LOG.md` from `assets/exec_log_reconstructed.md` — a reconstructed header (Principle 4), the command if it is recoverable, the artifacts present, and explicitly no step table. The rest stay in the inventory as evidence only, and the report says how many were left out.

#### Step S6: Write the record & route

Write `metds/adopt.md` from `assets/adopt_template.md`. Then route, in order: `$star-code-architect` for the architecture spec (its Branch B surveys the existing code — that is not yours to duplicate), `$star-plan-coach` for the research plan (it reads the inventory as its seed), `$star-plan-decomposer` for the leaves, and finally `$star-proj-adopt backfill` to make the tree reflect what is already done.

### Phase `backfill`

#### Step B1: Match inventory to leaves

Read `metds/adopt.md` and every leaf in `metds/plans/` (conventions §5.4). Propose a mapping table: inventory item → leaf → the state it argues for (`done` / `in_progress`) → the evidence. Report both kinds of misfit honestly — inventory items no leaf covers (work the plan tree forgot), and leaves nothing in the inventory reaches (genuinely new work, which is the normal case and not a problem).

#### Step B2: Gate 3 — per-leaf confirmation

The user confirms leaf by leaf — one question listing the proposed rows when there are several (the user may confirm several), one question each when there are few. An unconfirmed leaf is left exactly as it is. A leaf the user marks `done` that has no ledgered run is allowed, and is noted: `$star-flow-status` will flag it as done-with-no-run, which is the honest state.

#### Step B3: Write, record, report

On confirmed leaves only, set `exec_status:` and, where a run was ledgered in S5, `exec_runs:` — frontmatter fields only, nothing else in the file (Principle 6). On a confirmed match whose run was ledgered, also set that reconstructed `EXEC_LOG.md`'s `source_plan:` to the leaf's filename — the user just confirmed exactly that correspondence, and a log left saying `(none)` would trip the status skill's orphaned-run flag on every adopted run. Append a dated backfill record to `metds/adopt.md` naming every leaf touched and the evidence behind it, and set its frontmatter `backfilled:` to today's date — even when no leaf was confirmed, the phase ran and the record says so. That field is what the status skill's coverage row reads; left unset, the row would keep firing on a healthy project. Report, then route to `$star-flow-status` for the first honest picture of the adopted project.

## State & File Rules

- The durable output is `metds/adopt.md` (conventions §8). Writes are otherwise limited to: `.env`, the `datas/` / `inits/` / `wkdrs/` symlinks, `execs/run.sh`, `execs/update.sh`, `execs/scpts/*.sh`, the ledgered `wkdrs/<run>/` links and their reconstructed `EXEC_LOG.md`, and — in `backfill` only — the two frontmatter fields on confirmed leaves.
- Never touched in either phase: `${CODE_NAME}/` and everything under it, the project's own launchers, configs, and CI, `metds/ideas/**`, `metds/refs/**`, `metds/codearc.md`, the compiled `metds/*.md`, and every part of a plan file outside those two fields.
- Real dates only, from the system clock (conventions §4) — the adoption date, each ledgered run's date, the backfill date.
- STOP line (conventions §2): nothing here trains, evaluates, installs, or deletes. The probe is read-only, the verification is `--list` plus an interpreter version check. Environment repair belongs to `$star-env-builder`; if the runtime cannot run python, that is a blocker to report, not one to fix.
- Git: offered once at the end of each phase, staging only the paths this skill wrote — `star-proj-adopt: <phase> — <summary>` (conventions §1). `.env` and the ignored trees stay out of history. A path that already carried uncommitted changes when the run started is never staged, and in an adopted repository that is common: name those paths rather than working around them.

## Dialogue Discipline

- Ask one question at a time — Codex's structured user-input tool when available, otherwise concise plain text — and wait for the answer. All three gates require an explicit answer before any gate-crossing write.
- Lead with what the probe found and what it could not settle. An unknown reported as unknown is the point of this skill; a confidently wrong `CODE_NAME` costs the user every downstream skill.
- Say plainly what adoption did **not** do: it did not read the code architecture, did not write a research plan, and did not judge any result. Name the skill that owns each.
- `metds/adopt.md` body language follows the dialogue language at creation and is kept on re-run. Keep paths, package names, commit SHAs, and metric names in English inside Chinese documents.
