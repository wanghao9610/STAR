---
name: star-plan-executor
disable-model-invocation: true
description: >-
  Execute a leaf execution sub-plan (produced by star-plan-decomposer, under metds/plans/) against the
  project code. Orients in the codebase (${CODE_NAME}/, read from .env) to build a "current state vs
  required" gap list, enters Plan mode to turn the sub-plan's task breakdown into a concrete executable
  plan, gates it for approval, then dispatches one subagent per step to modify code and run light
  validation — stopping before heavy experiments (long/multi-GPU training, costly API calls) and handing
  those commands back to the user. Keeps intermediate files under tasks/<plan-name>/ and checkpoints
  durable execution state plus artifacts under wkdrs/<run>/ so runs resume across sessions. Syncs
  user-confirmed deviations and execution-settled values back into the sub-plan with a Revision History
  trail. Use when the user runs /skill:star-plan-executor, or wants to execute / implement / carry out /
  run a sub-plan, turn an execution plan into code and results, or start doing the work a plan describes.
  Bilingual (en/zh).
---

# Research Plan Executor — plan executor

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/skill:star-plan-executor PLAN_NAME`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`00`), or a filename (`00_mvp-three-tier_plan.md`).

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You take a **leaf execution sub-plan** and drive it to its done-criterion by actually changing code and running light validation. The upstream skill `star-plan-decomposer` produces the executable sub-plan (§1 objective / §2 inputs & deps / §3 task breakdown / §4 deliverables / §5 done-criteria / §6 local risks). This skill produces the **result**: code under `${CODE_NAME}/`, intermediate working files under `tasks/<plan-name>/`, generated artifacts and durable execution records under `wkdrs/<run>/`, and a verified done-criterion. Derive `<plan-name>` from the selected plan filename by removing `_plan.md`.

You **execute; you do not re-plan the research or re-decompose.** If §3 or §5 is too vague to execute, send the user back to `star-plan-decomposer` — do not re-derive the strategy here.

## Core Principles

1. **Read before you write.** Always orient in `${CODE_NAME}/` first — read the modules/entrypoints the sub-plan's §2 names before planning any change. Produce a "current state vs §3 requirements" gap list. Never assume code exists; `code/` may be greenfield (only `.gitkeep`), in which case the plan scaffolds from scratch — or, better, bootstrap a reference codebase first with `/skill:star-code-architect`. Reference: `references/orient_checklist.md`.
2. **Plan behind a gate, execute behind an agent.** The detailed executable plan (EXEC_PLAN) is produced in **Plan mode** and approved before any side effect. Execution is delegated to **subagents, one per step / step-group** — the main loop orchestrates and verifies; it does not edit code or launch jobs itself. Reference: `references/agent_dispatch_spec.md`.
3. **Stop before heavy experiments.** Agents write code and run **light validation only** (smoke tests, small-scale / no-finetune checks like an MVP done-criterion). Before any long/multi-GPU training run or costly API call, **stop**: write the prepared command into EXEC_LOG's "Awaiting user" area and hand it back. Never launch expensive or irreversible jobs autonomously. Rules: `references/stop_line_rules.md`.
4. **Files are the source of truth; checkpoint every step — and keep the sub-plan true.** Execution state lives in `wkdrs/<run>/` (`EXEC_PLAN.md` + `EXEC_LOG.md`); intermediate working files live in `tasks/<plan-name>/`. After each verified step, update the log. The sub-plan file gets a lightweight `exec_status` + `exec_runs` pointer — and, when execution provably diverges from it — or settles a value it left open that a method document will cite — a **user-confirmed sync-back** of the affected §2–§5 content plus a `## Revision History` entry (`references/plan_sync_rules.md`), so the plan a user rereads later matches what was actually executed. Chats end; files do not.
5. **Every step ends in a check; the run ends in the done-criterion.** Each step is verified narrowly before the next is dispatched; the whole run finishes on the sub-plan's §5 done-criterion. Reuse the project's verify and run helpers where useful. This is the project's Goal-Driven Execution (CLAUDE.md §4) and Verification (§7), executed.
6. **Use the project runtime and run surface.** All run commands go through `.env`'s `CONDA_HOME` / `PYTHON_HOME` — never system python, never hardcoded local paths (CLAUDE.md §6) — invoked via the project's run entrypoint `execs/run.sh` where one exists. Create `tasks/<plan-name>/` for intermediate files needed while executing that plan; put reusable launch scripts (including prepared STOP-line commands) under `execs/scpts/<run>.sh`, generated outputs and durable execution records in `wkdrs/<run>/`, data in `datas/`, and weights in `inits/`. Do not put generated run artifacts in `tasks/`.

## Workflow

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME` (slug / numeric prefix / full filename) against `metds/plans/*_plan.md`.
2. **Only leaves are executable.** If `PLAN_NAME` resolves to a node with children (non-empty `children:` frontmatter), do not execute it — list its leaves (prefix + slug + one-line objective) and ask in the conversation which leaf to execute, or offer to execute the leaves in dependency order, one at a time.
3. If no argument was given or the match is ambiguous, list available plans and ask.
4. Read the resolved sub-plan in full.

### Step 1: Readiness check

1. **Executability.** §3 Task Breakdown and §5 Done-Criteria must be concrete. If they are still largely `[TBD]` / `【待定】`, tell the user decomposition is unfinished and offer in the conversation: *go back to `/skill:star-plan-decomposer` to flesh it out* / *execute anyway (shallow, gaps stay `[TBD]`)*.
2. **Dependencies.** Check §2 Inputs & Dependencies: are the named datasets (`datas/`), weights (`inits/`), and code modules present? Are the upstream sibling leaves in the leaf's `depends_on` frontmatter list all marked `exec_status: done`? If a hard dependency is missing, **stop and report** — do not fabricate inputs. A missing dataset or weight is a decomposition gap, not a blocker to work around: name the data-readiness leaf that should own it, or route to `star-plan-decomposer <parent>` to add one.

### Step 2: Orient in the codebase

Follow `references/orient_checklist.md`:

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3). If the environment those paths name is missing or cannot run python, recommend building it with `/skill:star-env-builder` before executing; a package the run needs but the environment lacks is `/skill:star-env-builder add <package>` — this skill installs nothing itself.
2. Map `${CODE_NAME}/`. If empty, declare **greenfield**.
3. For each §3 step, decide whether the code to do it **exists / needs modifying / needs creating** — this mapping is the **gap list**.

### Step 3: Enter Plan mode → produce the executable plan

1. Enter Plan mode.
2. Refine §3 + the gap list into **EXEC_PLAN**: an ordered list of actions, each annotated `{files to touch / command to run (via conda) / artifact under wkdrs/<run>/ / bound check}`. Each action binds a verifiable check; the terminal action binds the §5 done-criterion.
3. **Draw the STOP line explicitly** (`references/stop_line_rules.md`): mark which actions the agent executes vs which are "prepare command, hand to user" (heavy experiments).
4. **Collect material divergences** from the sub-plan's §2–§5 into EXEC_PLAN's "Divergences from sub-plan" table, in delta form (ADDED / MODIFIED / REMOVED / ENRICHED — `references/plan_sync_rules.md`). A contradiction at the sub-plan's own granularity is a divergence; extra concreteness is not — except a value the plan left unstated that a method document will cite, which is an ENRICHED row naming that section.

### Step 4: Approval gate (exit Plan mode)

1. Exit Plan mode, presenting EXEC_PLAN + expected side effects: files to be written, commands to be run, where the STOP line falls, rough cost/runtime — and the divergence table, stated as "approving this plan also syncs these back into the sub-plan". Ask in the same gate whether to checkpoint each verified step as a git commit (recommended), naming any path that already carries uncommitted changes — those are never staged.
2. On approval, derive `<plan-name>` from the selected filename without `_plan.md` and create `tasks/<plan-name>/` for intermediate working files. Persist `wkdrs/<run>/EXEC_PLAN.md` from `assets/exec_plan_template.md` and initialize `wkdrs/<run>/EXEC_LOG.md` from `assets/exec_log_template.md`. **Run name = `<prefix>_<slug>`**; append a user-supplied suffix (`_v2`, a date) to distinguish re-runs — never invent timestamps. **Append** the run to the sub-plan's `exec_runs` list rather than replacing it: the history is what lets `/skill:star-expt-analyst aggregate` see every run of this leaf instead of only the last. A plan still carrying a single `exec_run:` is migrated here to `exec_runs: [<that run>]` before the new entry is appended.
3. **Sync divergences into the sub-plan.** If the divergence table is non-empty, the approval just given covers it: update the affected §2–§5 passages in place, append a `## Revision History` entry, bump `updated`, and mark each row `synced` (`references/plan_sync_rules.md`). The sub-plan now matches what is about to be executed.

### Step 5: Execute–verify loop (one agent per step / step-group)

For each step in EXEC_PLAN, in order:

1. Dispatch a subagent with the contract in `references/agent_dispatch_spec.md`: this step's goal, the exact files to touch, how to run via conda, the bound check, and "do **only** this step; return a structured result (changed / ran / check / blockers / handoff)".
2. When it returns, **the main loop re-runs the bound check** to confirm (do not trust a self-reported pass without evidence). Pass → checkpoint to `EXEC_LOG.md`, update the sub-plan's lightweight status, and — when the gate approved checkpointing — commit this step's files. Fail → diagnose, bounded retry (≤2) with the failure fed back; still failing → mark the step `blocked` and stop with the log.
3. **If the step is on the STOP line** (heavy experiment) → do **not** dispatch it to run; write the prepared command into EXEC_LOG's "Awaiting user" area and stop, handing it to the user.
4. If a retry or blocker changes the approach at the sub-plan's granularity (a step added/dropped/replaced, a deliverable path or done-criterion shifted), record a delta row under EXEC_LOG's "Pending amendments" and continue — these sync at Step 6, not mid-run.

Keep the main-loop reply concise; details live in the log.

### Step 6: Finalize / done-criterion verification

After all agent steps are `done`, verify the sub-plan's §5 done-criterion (reuse `/verify`, `/run` where useful). Met → set the sub-plan's `exec_status: done`, then offer once to delete the plan's `tasks/<plan-name>/` **scratch** — promote anything still worth keeping into `wkdrs/<run>/` first, and record the choice in `EXEC_LOG.md`; keeping it is a fine answer. **The offer never covers the plan's own tool scripts** (conventions §9): list them by name as retained, and delete one only if the user names it themselves. Not met → follow the sub-plan's §6 local fallback, or report the gap. Then run `references/exec_rubric.md` and report failing items (≤5, ranked, each with a concrete fix).

**Amendment sync (tactical signal).** If EXEC_LOG's "Pending amendments" is non-empty, present the batch via **one** question (*sync all / select which / skip*) and write confirmed rows back per `references/plan_sync_rules.md` (§2–§5 updated in place + `## Revision History` entry + `updated` bump, then check the rows off). Tactical only: anything touching §1/§6, a parent plan, or a kill-criterion is a strategy signal — route it through feedback reflux below, never sync it.

**Feedback reflux (strategy signal).** If the result contradicts an assumption the parent plan depends on — i.e. it matches a root §5 **kill-criterion**, or an MVP done-criterion the plan called the "cheap early test" came back negative — this is a strategy-level finding, not just a failed step. You do not edit the parent's §1–§6 (that stays with the coach/decomposer). Instead: record it in the run's `EXEC_LOG.md` "Notes / decisions" (which this skill owns), and in the Step 8 report **surface it explicitly** and recommend feeding it back via `/skill:star-plan-reviser <slug>` (audit the evidence and revise the plan under per-item approval), `/skill:star-plan-coach <slug>` (revisit risks/method), or `/skill:star-plan-decomposer <slug>` (re-scope the sub-plans). This closes the loop from execution back to strategy without violating write discipline.

### Step 7: Checkpoint & resume semantics

- **Source of truth**: `wkdrs/<run>/EXEC_LOG.md` — each step `pending`/`in_progress`/`done`/`blocked` + artifact path + any "Awaiting user" commands.
- The sub-plan frontmatter carries only `exec_status` + `exec_runs` (append-only, newest last; the last entry is the current run).
- On re-invoke, read the run dir, skip `done` steps, resume from the first unfinished step. If STOP-line commands were awaiting and their outputs now exist, resume at done-criterion verification.
- Sync-back is idempotent: rows marked `synced` (EXEC_PLAN) or checked off ("Pending amendments") are never re-applied; unsynced pending rows are re-offered at Step 6.

### Step 8: Report

What was verified (with evidence), where artifacts live, which commands were handed back to the user, which amendments were synced into the sub-plan, and remaining risks. If Step 6 surfaced a strategy signal (a root kill-criterion hit), state it and name the feedback path (`/skill:star-plan-reviser` / `/skill:star-plan-coach` / `/skill:star-plan-decomposer`). After a completed run, recommend `/skill:star-code-reviewer <leaf>` to audit the implementation against conventions and the sub-plan before revising or moving on. Where commands were handed back at the STOP line, add that once their outputs exist, `/skill:star-expt-analyst <leaf>` scores the results against the §5 done-criterion and says what they mean. Keep it under ~400 words.

## State & File Rules

- Intermediate working files live under `tasks/<plan-name>/`; execution state and generated artifacts live under `wkdrs/<run>/`. Never write execution logs into `metds/plans/` — the sub-plan gets only `exec_status` + `exec_runs` + `updated`. `tasks/<plan-name>/` holds this plan's own tool scripts (durable) plus its disposable scratch, and this skill owns the scratch's lifecycle: offer the scratch's deletion once at finalize when §5 is met, never the scripts (conventions §9). Generated artifacts and durable evidence never live there; never delete it unasked, and never touch another plan's `tasks/` directory.
- Code changes go under `${CODE_NAME}/`; data under `datas/`; weights under `inits/`; run scripts under `execs/scpts/` with `execs/run.sh` as the entrypoint (CLAUDE.md §5).
- Never launch heavy or irreversible jobs (long/multi-GPU training, full-dataset eval, costly API) autonomously; those cross the STOP line to the user.
- All run commands go through `.env`'s conda env; never system python, never hardcoded local paths.
- Edit the sub-plan's frontmatter (`exec_status`, `exec_runs`, `updated`) freely; edit its §2–§5 **only** through the user-confirmed sync-back protocol (`references/plan_sync_rules.md`), always in place and always paired with a `## Revision History` entry. Never rewrite §1 or §6 and never touch a parent plan — objective- or strategy-level divergence goes back through `star-plan-coach` / `star-plan-decomposer` (feedback reflux).
- Git: one commit per verified step, staging only the files that step touched, and only when the approval gate covered it; name pre-run dirty paths at the gate (conventions §1).
- Legal step status: `pending` / `in_progress` / `done` / `blocked` / `skipped`.

## Dialogue Discipline

- In non-interactive `kimi -p` runs (no human to answer), fall back: present EXEC_PLAN as plain text and require an explicit plain-text approval before any side effect — still gate before executing, still stop before heavy experiments, still confirm in plain text before any sync-back write to the sub-plan.
- The sub-plan's body language follows its `language`; keep technical terms in English inside Chinese plans.
