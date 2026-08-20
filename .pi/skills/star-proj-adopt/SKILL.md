---
name: star-proj-adopt
disable-model-invocation: true
description: >-
  Adopt an already-started project into STAR without disturbing it. Phase `survey` inspects the repository
  read-only (source layout, runtime, data / weights / output locations, entrypoints, git history, prior
  runs), confirms the mapping, then puts the mechanical setup in place — writes .env, reaches large
  existing directories by symlink instead of moving them, wraps existing launch commands into execs/scpts/
  — and records a work inventory of what is already built, run, and concluded in metds/adopt.md, with the
  user's chosen historical runs under wkdrs/. Phase `backfill` runs once the plan tree exists: it matches
  that inventory to the leaves and, per leaf and only on the user's confirmation, records exec_status /
  exec_runs so the tree shows real progress instead of 0%. Use when the user runs /star-proj-adopt, wants
  to bring an existing / partially finished project into STAR, asks how to onboard a repo that did not
  start from the template, or needs finished work reflected in the tree. Bilingual (en/zh).
---

# Research Project Adopt — bring an in-progress project into STAR

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/star-proj-adopt [survey | backfill] [DESCRIPTION]` — no argument auto-selects: no `metds/adopt.md` → `survey`; an adoption record plus a decomposed plan tree (≥1 sub-plan carrying `parent:`) → `backfill`. An explicit phase name overrides detection; re-running `survey` on an adopted project re-inspects and updates the record rather than starting over. Anything left is a description (conventions §7.12): in your own words, what this run is for — a lead the run may follow and record, never an instruction standing in for a confirmation point. Prose matching none of the above is description alone: run as if no argument was given, and say so first. A lone token that looks like an argument and matches nothing is not a description — ask which was meant. An optional `involve=low|medium|high` token may accompany any argument (e.g. `… involve=low`): it sets this run's `involve` level (conventions §7.7) and is stripped before argument or description is read.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What an adoption acts on — §0 vocabulary, §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout, §10 the skill roster — arrives through the opening load below. One section stays out: §11 execution branches, whose nine items this skill never performs — it creates, merges and discards no branch and no worktree — and whose one rule for every other skill, that a commit made while the checkout sits on another run's execution branch rides into that leaf's merge, is restated in State & File Rules beside the commit rule it qualifies. The document's preamble stays out too, its precedence rule being the one this paragraph opens with. Read the whole file if a run ever needs it.

Before acting, load it in one message — three `bash` calls with the project root as the working directory, plus a `read` of `<this skill's directory>/references/adopt_spec.md`, all sent together.

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
awk '/^## /{k=/^## (0|1|2|3|4|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (9|10)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

One message, four results. `STAR_LANG` sets the reply language, `INVOLVE` the question level, and folding both into the opening message keeps neither costing a round trip of its own. The calls stay separate because each tool result carries its own size limit: a result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid — and the conventions excerpt is about 47 KB in total, split 21, 18 and 8 across its three calls. Each `awk` prints the sections named above it and nothing else; if any of them is missing from what it prints — a stale synced copy of the conventions may number its sections differently — read the file whole instead. `references/adopt_spec.md` (Chinese: `references/adopt_spec_zh.md`) is the spec the Workflow below follows — the survey recipe, the inventory format, and the symlink / wrapper rules. The `assets/` templates are not part of the load: each is read at the step that writes from it.


**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the `.env` lookup's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

Every other STAR skill assumes a project begun from the template: `.env` configured, layout in place, plans under `metds/plans/` describing work not yet done. You exist for the project that did not — real code, a working environment, months of commits, results in hand. You make it legible to the rest of the family **without asking it to change**: nothing moves, nothing is renamed, nothing already written is overwritten.

You are the on-ramp, not the driver. You do not survey the code architecture (`/star-code-architect` Branch B owns that), do not author research strategy (`/star-plan-coach` and `/star-plan-decomposer` own the plan tree), and do not judge results (`/star-expt-analyst`). You establish the runtime, record what exists as evidence, and later reconcile it with the tree the coach and decomposer build.

## Core Principles

1. **Never overwrite, never move, never rename.** The one constraint the whole skill turns on. Existing files keep their content, existing directories their location and name, and the environment the project already runs in is the one STAR uses. A conflict is a question, never a resolution: when a path you would write exists, show its content and ask. `CODE_NAME` points at whatever the source directory is already called.
2. **Reach large directories, do not relocate them.** Existing data, weights, and output trees are wired in with symlinks at `datas/`, `inits/`, `wkdrs/` so `DATA_DIR` / `INIT_DIR` / `WORK_DIR` resolve, while every absolute path in existing code and scripts keeps working. A directory already in the right place needs no link; a link is never created over a non-empty real directory.
3. **Evidence, not recall.** Every row of the work inventory cites its source — a path, a commit, a script, a log line. What the repository does not show is recorded as unknown and asked about, never inferred from the shape of a typical project.
4. **Reconstruction is always labeled.** A record written after the fact is not an execution record. Every historical run recorded this way carries a header: reconstructed during adoption, on what date, from what evidence — so no later reader mistakes it for `/star-plan-executor` output.
5. **Adoption does not invent research strategy.** You can read what was built and run; not why, what claim it serves, or what would have killed it. The inventory stays descriptive; §4-style claims and kill-criteria are left for `/star-plan-coach` to elicit from the user. A plan tree fabricated from a git log is worse than no plan tree.
6. **The narrow write on plans.** `metds/plans/*` belongs to the coach, decomposer, executor, and reviser (conventions §8). Your one exception is frontmatter `exec_status:` and `exec_runs:` on leaves, in `backfill`, each leaf individually confirmed by the user. Plan bodies, `status:`, `finalized:`, `children:`, `depends_on` — never yours, in either phase.
7. **Two confirmation points; autonomous between them.** Confirmation point 1: the user confirms the survey mapping (source, runtime, data / weights / outputs) before anything is written. Confirmation point 2: the user picks which historical runs get recorded. `backfill` adds a third of its own, per-leaf. Never do work a confirmation point did not cover.

## Workflow

Follow `references/adopt_spec.md` (Chinese: `references/adopt_spec_zh.md`) — the opening message under Shared conventions already loaded it; the shape is:

### Phase `survey`

#### Step S1: Survey (read-only)

Detect, without writing anything: candidate source directories (top-level importable packages, the one the entrypoints import), the runtime in use (`conda env list`, a `.venv`, `which python`, an env name in existing scripts), where data / weights / outputs live, the launch entrypoints and how they are invoked, the existing tests, and the git history shape (first commit, commit count, active paths). Present the mapping as one compact block, marking every low-confidence line.

The survey may fan out **by area** — source, runtime, data, weights, outputs, entrypoints — one read-only `star_subagent` dispatch each (`agent: "star-collector"`), run in parallel, each held to this verbatim scope: "read-only — do not run the project's code, do not import its package, do not create or repair any environment; write nothing." Each pass returns findings, evidence paths, alternatives and unknowns — and **no confidence label**: in `adopt_spec.md` confidence decides what reaches Confirmation point 1, so it is assigned afterwards, over all six areas at once, rather than inside any one of them. Confirming a `certain` line takes a command (`test -d`, an interpreter version check), not a re-read, so the repository's bulk never comes back. This is the expensive part of an unfamiliar repository; S4 below builds on what these areas gathered instead of walking their sources again.

#### Step S2: Confirmation point 1 — confirm the mapping

Ask through `star_questionnaire`, one question at a time, only about what the survey could not settle: the `CODE_NAME` directory, the `PYTHON_HOME` interpreter, the existing data / weights / output roots. Options come from the survey with the recommendation marked. Nothing is written until the user answers.

#### Step S3: Put the mechanical setup in place

In this order, each step reported as done or skipped-because-it-exists:

1. `.env` — from `.env.example` when absent. When it exists, never rewrite a value already set: show the diff you would make and ask per conflicting key.
2. Symlinks for `datas/`, `inits/`, `wkdrs/` per Principle 2. Skip and say so when the path is a non-empty real directory.
3. `execs/` — `run.sh` and `update.sh` only if missing. For each launch entrypoint, one `execs/scpts/<name>.sh` that **calls the project's existing command**, unchanged, through the exported paths. Never rewrite the project's own launcher.
4. Verify: `bash execs/run.sh --list` lists the wrappers, and the resolved interpreter reports its version. Report what ran and what did not.

#### Step S4: Build the work inventory

From git log, the entrypoints, the output directories, and the README, assemble the inventory defined in `references/adopt_spec.md`: one row per identifiable unit of finished or in-flight work — what it is, its state (`built` / `run` / `concluded` / `abandoned`), and its evidence paths. This is the seed `/star-plan-coach` reads; a description of the repository, not a plan (Principle 5). The S1 areas already walked git history, the entrypoints and the output directories: build from what they returned, opening only what none covered. The main agent merges and owns every judgment, including the rule that two commits plus an output directory describing one thing is one row.

#### Step S5: Confirmation point 2 — record the historical runs worth keeping

List the prior runs the survey found — path, date, what it appears to have produced, any metric visible in its logs. Ask once over the numbered list which to record — more than four runs cannot be options (conventions §7.3), so offer *record all* / *record some (say the numbers)* / *record none*. Symlink each chosen run to `wkdrs/<run>/` and write a minimal `EXEC_LOG.md` from `assets/exec_log_reconstructed.md` — a reconstructed header (Principle 4), the command where recoverable, the artifacts present, and explicitly no step table. The rest stay in the inventory as evidence only, and the report says how many were left out.

#### Step S6: Write the record & route

Write `metds/adopt.md` from `assets/adopt_template.md`. Then route, in order: `/star-code-architect` for the architecture spec, `/star-plan-coach` for the research plan, `/star-plan-decomposer` for the leaves, and finally `/star-proj-adopt backfill` to make the tree reflect what is already done.

### Phase `backfill`

#### Step B1: Match inventory to leaves

Read `metds/adopt.md` and every leaf in `metds/plans/` (conventions §5.4). A small tree (≤ ~8 leaves) is usually simplest to read in the main agent; larger, partition the leaves into disjoint read-only collectors returning, per leaf, `{leaf, deliverable_paths, step_paths, done_criterion (quoted verbatim), exec_status, overlap, weak}` — the matching rule uses only those, never the whole plan body. The main agent re-reads §5 in full for every leaf it proposes as `done`, and keeps the many-to-many rule and the confirmation point. Propose a mapping table: inventory item → leaf → the state it argues for (`done` / `in_progress`) → the evidence. Report both misfits honestly — inventory items no leaf covers (work the plan tree forgot), and leaves nothing in the inventory reaches (genuinely new work, the normal case and not a problem).

#### Step B2: Confirmation point 3 — per-leaf confirmation

The user confirms leaf by leaf — one question over the numbered rows when there are several (*confirm all* / *confirm some (say the numbers)* / *confirm none*), one question each at four or fewer. An unconfirmed leaf is left exactly as it is. A leaf marked `done` with no recorded run is allowed, and noted: `/star-flow-status` will flag it as done-with-no-run, the honest state.

#### Step B3: Write, record, report

On confirmed leaves only, set `exec_status:` and, where a run was recorded in S5, `exec_runs:` — frontmatter fields only, nothing else in the file (Principle 6). On a confirmed match whose run was recorded, also set that reconstructed `EXEC_LOG.md`'s `source_plan:` to the leaf's filename — the user just confirmed that correspondence, and a log left saying `(none)` trips the status skill's orphaned-run flag on every adopted run. Append a dated backfill record to `metds/adopt.md` naming every leaf touched and its evidence, and set frontmatter `backfilled:` to today's date — even with no leaf confirmed, the phase ran and the record says so. The status skill's coverage row reads that field; unset, it keeps firing on a healthy project. Report, then route to `/star-flow-status` for the first honest picture of the adopted project.

## State & File Rules

- The durable output is `metds/adopt.md` (conventions §8). Writes are otherwise limited to: `.env`, the `datas/` / `inits/` / `wkdrs/` symlinks, `execs/run.sh`, `execs/update.sh`, `execs/scpts/*.sh`, the recorded `wkdrs/<run>/` links and their reconstructed `EXEC_LOG.md`, and — in `backfill` only — the two frontmatter fields on confirmed leaves.
- Never touched in either phase: `${CODE_NAME}/` and everything under it, the project's own launchers, configs, and CI, `metds/ideas/**`, `metds/refs/**`, `metds/codearc.md`, the compiled `metds/*.md`, and every part of a plan file outside those two fields.
- Real dates only, from the system clock (conventions §4) — the adoption date, each recorded run's date, the backfill date.
- STOP line (conventions §2): nothing here trains, evaluates, installs, or deletes. The survey is read-only, the verification is `--list` plus an interpreter version check. Environment repair belongs to `/star-env-builder`; a runtime that cannot run python is a blocker to report, not one to fix.
- Git: offered once at the end of each phase, staging only the paths this skill wrote — `star-proj-adopt: <phase> — <summary>` (conventions §1). `.env` and the ignored trees stay out of history. A path that already carried uncommitted changes when the run started is never staged — common in an adopted repository: name those paths rather than working around them.
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).

## Dialogue Discipline

- All three confirmation points go through `star_questionnaire`, one per call — still one at a time, still an explicit answer before any write past a confirmation point.
- **Material a question is about goes in the text of the same message, above the call** — the prior-run list, the proposed leaf rows. The options carry the answers and none of the material; read the message back before it goes out: options with nothing above them mean the material was skipped, not shortened.
- Lead with what the survey found and what it could not settle — a confidently wrong `CODE_NAME` costs the user every downstream skill.
- Say plainly what adoption did **not** do: read the code architecture, write a research plan, judge any result. Name the skill that owns each.
- `metds/adopt.md` body language follows the dialogue language at creation and is kept on re-run. Keep paths, package names, commit SHAs, and metric names in English inside Chinese documents.
