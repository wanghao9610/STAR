---
name: star-plan-executor
description: >-
  Execute a leaf research sub-plan from metds/plans/ against the project code. Orient in the
  codebase using .env, turn the sub-plan into a concrete checked execution plan, implement it with
  surgical changes, run light validation, keep intermediate working files under a plan-specific
  tasks directory, record progress under a run-specific wkdrs directory, and stop before
  long or costly experiments by handing the exact command to the user. Writes user-confirmed
  deviations and values settled by execution back into the sub-plan and adds a Revision History entry, keeping the plan file true to
  what was actually executed. Use when the user invokes
  $star-plan-executor or asks Codex to execute, implement, carry out, or run a research sub-plan.
  Supports resume across sessions and bilingual English/Chinese work.
---

# Research Plan Executor

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `$star-plan-executor PLAN_NAME`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`00`), or a filename (`00_mvp-three-tier_plan.md`). An optional `involve=low|medium|high` token may accompany `PLAN_NAME` (e.g. `… involve=low`): it sets the `involve` level for this run (conventions §7.7), is not part of `PLAN_NAME`, and is stripped before resolution.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. Its read is this skill's whole opening load — one message, before acting: the conventions file arrives through its own `Read` call, never `cat`-ed into a Bash command — a Bash result past roughly 30 KB is spilled to a file that costs a second round trip to read back, and the conventions file alone is past that limit — plus one small Bash call in the same message, with the project root as the working directory: `grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)`. An executor commits, runs, and writes the sub-plan back, so every section applies (§1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout), and nothing else needs loading before Step 0. The `references/*.md` files this skill names are step-time material — load each where its step cites it, not up front. The `grep` is the §7.6/§7.7 lookup only — `STAR_LANG` sets the reply language, `INVOLVE` the question level — folded into the opening message so neither costs a round trip of its own; the full `.env` runtime (§3) is still resolved at its own step, Step 2.

**Reusing an earlier load.** A second STAR skill in the same conversation does not pay for this twice. Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the probe's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again — a wasted read costs one message, a wrong assumption costs the run. What never carries over is a collector digest, where one is loaded above: it is a snapshot of files a skill run may have written to since, so the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

Drive one **leaf execution sub-plan** to its done-criterion by changing code and running light validation. The upstream `$star-plan-decomposer` owns the sub-plan's strategy and task breakdown. This skill owns implementation results: code under `${CODE_NAME}/`, intermediate working files under `tasks/<plan-name>/`, and generated artifacts plus verification evidence under `wkdrs/<run>/`. Derive `<plan-name>` from the selected plan filename by removing `_plan.md` (for example, `00_demo_plan.md` → `tasks/00_demo/`).

Execute; do not re-strategize or silently re-decompose. If §3 or §5 is too vague to execute, report the concrete gaps and route back to `$star-plan-decomposer`.

## Core Principles

1. **Read before writing.** Inspect `.env`, the named inputs, the relevant code, and the actual launch entry point before planning a change. Produce a current-state-versus-required gap list. Follow `references/orient_checklist.md`.
2. **Make the plan visible, then proceed within scope.** Convert the sub-plan into an `EXEC_PLAN` whose actions each name files, commands, artifacts, and the action's own check. Use Codex's progress-plan mechanism when available and summarize the plan in commentary. Invoking this executor authorizes ordinary in-scope implementation and light validation; request new direction only when a decision would materially change scope or require new authority.
3. **Delegate selectively.** Execute locally by default. Delegate only bounded, independent work when collaboration tools are available and delegation materially helps. Never create one subagent per trivial sequential step. Give each delegate the narrow contract in `references/agent_dispatch_spec.md`; the main agent remains responsible for integration and re-running checks. That file's tree discipline — a clean tree for this action's files before it starts, restore before retry, and an explicit decision about the edits of an action that ended `blocked` — binds local execution just as it binds a delegate: the abandoned edits are the same edits either way.
4. **Stop before heavy or irreversible work.** Long or multi-GPU training, full-dataset evaluation, costly API calls, unbounded jobs, and overwrites of valuable artifacts cross the STOP line. Prepare a reproducible command and hand it to the user; do not launch it. Follow `references/stop_line_rules.md`.
5. **Checkpoint verified state — and keep the sub-plan true.** Store `EXEC_PLAN.md` and `EXEC_LOG.md` under `wkdrs/<run>/`. Update the log after each action's check. Keep only `exec_status`, `exec_runs`, and `updated` in the sub-plan frontmatter — plus, when execution provably diverges from the sub-plan — or settles a value it left open that a method document will cite — a **user-confirmed write-back** of the affected §2–§5 content with a `## Revision History` entry (`references/plan_sync_rules.md`), so the plan a user rereads later matches what was actually executed.
6. **Use the project runtime and layout.** Read `CONDA_HOME`, `PYTHON_HOME`, and `CODE_NAME` from `.env`; never guess local paths or use system Python. Use `execs/run.sh` when it is the project entrypoint. Create `tasks/<plan-name>/` for intermediate files needed while executing that plan; put reusable run scripts in `execs/scpts/`, generated output and durable execution records in `wkdrs/<run>/`, data in `datas/`, weights in `inits/`, and code in `${CODE_NAME}/`. Do not put generated run artifacts in `tasks/`. Follow `AGENTS.md`.

## Workflow

### Step 0: Resolve the target

1. Match `PLAN_NAME` against `metds/plans/*_plan.md` by slug, numeric prefix, or full filename.
2. Only leaves are executable. If the target has non-empty `children:`, list its leaves and ask which one to execute (recommend the first ready one), or offer to process them one at a time in dependency order.
3. If the target is absent or ambiguous, list concise candidates and ask one direct question.
4. Read the selected sub-plan in full.

### Step 1: Check readiness

1. Require concrete §3 Task Breakdown and §5 Done-Criteria. If they are mostly `[TBD]` / `【待定】`, report the missing decisions and ask whether to return to `$star-plan-decomposer` (recommended) or continue with the remaining uncertainty explicitly recorded.
2. Verify named datasets, weights, code modules, and every `depends_on` sibling. If a hard dependency is missing or an upstream sibling is not `exec_status: done`, stop and report the exact blocker. A missing dataset or weight is a decomposition gap, not a blocker to work around: name the data-readiness leaf that should own it, or route to `$star-plan-decomposer <parent>` to add one.
3. Derive the intermediate workspace as `tasks/<plan-name>/`, where `<plan-name>` is the selected filename without `_plan.md`. If the selected leaf already has `exec_runs`, read its current run's `wkdrs/<run>/EXEC_LOG.md` and resume it. Otherwise use run name `<prefix>_<slug>`. If that run directory already exists but is not a resumable run for this leaf, ask for a distinguishing suffix; never invent one.

### Step 2: Orient

Follow `references/orient_checklist.md`:

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3). If the environment those paths name is missing or cannot run python, recommend building it with `$star-env-builder` before executing.
2. Map `${CODE_NAME}/` and declare empty codebase when it contains no implementation — or bootstrap a reference codebase first with `$star-code-architect`.
3. Trace each §3 step to real files and classify it as exists / modify / create.
4. Identify the actual run and test entrypoints.

### Step 3: Build and checkpoint EXEC_PLAN

1. Refine §3 plus the gap list into ordered actions. Each action must bind `{files / command through project env / artifact / check}`; the final action binds the §5 done-criterion.
2. Mark the STOP line explicitly and estimate runtime/cost when known.
3. Collect material divergences from the sub-plan's §2–§5 into EXEC_PLAN's "Divergences from sub-plan" table, in delta form (ADDED / MODIFIED / REMOVED / ENRICHED — `references/plan_sync_rules.md`). A contradiction at the sub-plan's own granularity is a divergence; extra concreteness is not — except a value the plan left unstated that a method document will cite, which is an ENRICHED row naming that section.
4. Show a concise plan and expected side effects in commentary, and ask once whether to checkpoint each verified action as a git commit (recommended), naming any path that already carries uncommitted changes — those are never staged. Say what saying no costs: without per-action commits, every verified action stays uncommitted, so if something has to be restored later, the only record of where each action started is the one this run keeps itself (`references/agent_dispatch_spec.md`). Pause only for a material scope choice, a non-empty divergence table (confirm its rows with the user before executing), or a STOP-line action that requires user execution.
5. Create `tasks/<plan-name>/` for this plan's intermediate working files. Create `wkdrs/<run>/EXEC_PLAN.md` from the matching language template and initialize `EXEC_LOG.md` there. Update the sub-plan frontmatter to `exec_status: in_progress` and **append** this run to `exec_runs` rather than replacing the last entry — the history is what lets `$star-expt-analyst aggregate` see every run of this leaf. A plan still carrying a single `exec_run:` is migrated to `exec_runs: [<that run>]` first. Sync the confirmed divergence rows into the sub-plan now: update the affected §2–§5 passages in place, append a `## Revision History` entry, bump `updated`, and mark each row `synced`.

### Step 4: Execute and verify

For each unfinished action:

1. Choose local execution or selective delegation. When delegating, use `references/agent_dispatch_spec.md` and keep file ownership non-overlapping.
2. Make only the action's necessary changes and run its own narrow check through the project environment.
3. Re-run or independently inspect the action's own check in the main agent. On pass, checkpoint the evidence and artifact path, and commit this action's files when checkpointing was approved. On fail, the main agent's own re-run is the evidence: read the `file:line` the failure names, and open the delegate's full diff only when deciding `blocked` or when the failure looks like a sub-plan-granularity problem. Restore this action's files before retrying, diagnose and retry at most twice when a concrete fix is available; otherwise mark the action `blocked`, settle what happens to its edits (`agent_dispatch_spec.md`), and stop.
4. If the action crosses the STOP line, prepare the exact command (and optionally `execs/scpts/<run>.sh`), record it under `Awaiting user`, and stop without running it.
5. If a retry or blocker changes the approach at the sub-plan's granularity (a step added/dropped/replaced, a deliverable path or done-criterion shifted), record a delta row under EXEC_LOG's `Pending amendments` and continue — these sync at finalize, not mid-run.

### Step 5: Finalize

1. Run the sub-plan's §5 done-criterion and record the evidence in `EXEC_LOG.md`.
2. If met, set the run and sub-plan `exec_status: done`, then offer once to delete the plan's `tasks/<plan-name>/` **scratch** — promote anything still worth keeping into `wkdrs/<run>/` first, and record the choice in `EXEC_LOG.md`; keeping it is a fine answer. **The offer never covers the plan's own tool scripts** (conventions §9): list them by name as retained, and delete one only if the user names it themselves. If unmet, follow the local fallback in §6 or report the verified gap.
3. If EXEC_LOG's `Pending amendments` is non-empty, present the batch once (sync all / select which / skip, recommendation marked) and write confirmed rows back per `references/plan_sync_rules.md` (§2–§5 updated in place + `## Revision History` entry + `updated` bump, then check the rows off). Tactical only: anything touching §1/§6, a parent plan, or a kill-criterion routes through the plan-level finding in point 5, never by writing it back into the plan.
4. Check `references/exec_rubric.md` and fix in-scope failures before reporting; list at most five remaining failures with concrete remedies.
5. If a result hits a root kill-criterion or invalidates the cheap MVP assumption, record a **Plan-level finding** in the log and recommend `$star-plan-reviser <slug>` (audit the evidence and revise the plan), `$star-plan-coach <slug>`, or `$star-plan-decomposer <slug>`. Do not edit the parent's strategy sections.

### Step 6: Report

Lead with the outcome. State what was verified and its evidence, where the `tasks/<plan-name>/` intermediate workspace and `wkdrs/<run>/` records/artifacts live, which commands await the user, which amendments were synced into the sub-plan, and any remaining risk. After a completed run, recommend `$star-code-reviewer <leaf>` to audit the implementation against conventions and the sub-plan before revising or moving on. Where commands await the user at the STOP line, add that once their outputs exist, `$star-expt-analyst <leaf>` scores the results against the §5 done-criterion and says what they mean. Keep the report under about 500 words.

## State & File Rules

- Treat `wkdrs/<run>/EXEC_LOG.md` as the execution source of truth. On reinvocation, skip `done` actions and resume from the first unfinished one. The write-back is idempotent: rows marked `synced` or checked off are never re-applied; unsynced pending rows are re-offered at finalize.
- `tasks/<plan-name>/` holds this plan's own tool scripts (durable) plus its disposable scratch, and this skill owns the scratch's lifecycle: created at Step 3, the scratch offered for deletion once at finalize when §5 is met — never the scripts (conventions §9). Generated artifacts and durable evidence never live there; never delete it unasked, and never touch another plan's `tasks/` directory.
- Edit `exec_status`, `exec_runs`, and `updated` in the sub-plan frontmatter freely; edit its §2–§5 **only** through the user-confirmed write-back procedure (`references/plan_sync_rules.md`), always in place and always paired with a `## Revision History` entry. Never rewrite §1 or §6 and never touch a parent plan — objective- or strategy-level divergence routes to `$star-plan-reviser` / `$star-plan-coach` / `$star-plan-decomposer`.
- Git: one commit per verified action, staging only the files that action touched, and only when checkpointing was approved (conventions §1).
- Legal action status: `pending` / `in_progress` / `done` / `blocked` / `skipped`.

## Dialogue Discipline

- In non-interactive `codex exec`, where `ask_user_question` is unavailable, fall back: present EXEC_PLAN as plain text and require an explicit plain-text approval before any side effect — still stop for confirmation before executing, still stop before heavy experiments, still confirm in plain text before any change is written back into the sub-plan.
- Match the user's dialogue language while preserving the plan body's frontmatter `language`; keep technical terms in English inside Chinese plans.
- Involve (conventions §7.7). Always asked here: the STOP line (Step 4), Step 3's checkpoint-commit question and divergence-row confirmation (it writes plan §2–§5), Step 5's pending-amendments batch, the scratch offer (it stops for confirmation before a deletion), and what becomes of a blocked step's edits (it stops for confirmation before a deletion too — `references/agent_dispatch_spec.md`). Set to `low`: Step 0's which-leaf choice (take the first ready leaf in dependency order; an absent or ambiguous target still asks, conventions §5.2) and Step 1's readiness fallback (take the recommendation: route back to the decomposer and stop). At `high`, confirm each action (Step 4) before executing it. Record the effective level and its source once in `EXEC_LOG.md`.
