---
name: rsch-plan-executor
description: >-
  Execute a leaf research sub-plan from metds/plans/ against the project code. Orient in the
  codebase using .env, turn the sub-plan into a concrete checked execution plan, implement it with
  surgical changes, run light validation, checkpoint progress under a run-specific wkdrs directory, and stop before
  long or costly experiments by handing the exact command to the user. Use when the user invokes
  $rsch-plan-executor or asks Codex to execute, implement, carry out, or run a research sub-plan.
  Supports resume across sessions and bilingual English/Chinese work.
---

# Research Plan Executor

Match the user's language. Load `*_zh.md` resources for Chinese dialogue; otherwise load the unsuffixed resources.

Invocation: `$rsch-plan-executor PLAN_NAME`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`00`), or a filename (`00_mvp-three-tier_plan.md`).

## Role

Drive one **leaf execution sub-plan** to its done-criterion by changing code and running light validation. The upstream `$rsch-plan-decomposer` owns the sub-plan's strategy and task breakdown. This skill owns implementation results: code under `${CODE_NAME}/`, artifacts under `wkdrs/<run>/`, and verification evidence.

Execute; do not re-strategize or silently re-decompose. If §3 or §5 is too vague to execute, report the concrete gaps and route back to `$rsch-plan-decomposer`.

## Core Principles

1. **Read before writing.** Inspect `.env`, the named inputs, the relevant code, and the actual run surface before planning a change. Produce a current-state-versus-required gap list. Follow `references/orient_checklist.md`.
2. **Make the plan visible, then proceed within scope.** Convert the sub-plan into an `EXEC_PLAN` whose actions each name files, commands, artifacts, and a bound check. Use Codex's progress-plan mechanism when available and summarize the plan in commentary. Invoking this executor authorizes ordinary in-scope implementation and light validation; request new direction only when a decision would materially change scope or require new authority.
3. **Delegate selectively.** Execute locally by default. Delegate only bounded, independent work when collaboration tools are available and delegation materially helps. Never create one subagent per trivial sequential step. Give each delegate the narrow contract in `references/agent_dispatch_spec.md`; the main agent remains responsible for integration and re-running checks.
4. **Stop before heavy or irreversible work.** Long or multi-GPU training, full-dataset evaluation, costly API calls, unbounded jobs, and overwrites of valuable artifacts cross the STOP line. Prepare a reproducible command and hand it to the user; do not launch it. Follow `references/stop_line_rules.md`.
5. **Checkpoint verified state.** Store `EXEC_PLAN.md` and `EXEC_LOG.md` under `wkdrs/<run>/`. Update the log after each bound check. Keep only `exec_status`, `exec_run`, and `updated` in the sub-plan frontmatter.
6. **Use the project runtime and layout.** Read `CONDA_HOME`, `PYTHON_HOME`, and `CODE_NAME` from `.env`; never guess local paths or use system Python. Use `execs/run.sh` when it is the project entrypoint. Put reusable run scripts in `execs/scpts/`, generated output in `wkdrs/<run>/`, data in `datas/`, weights in `inits/`, and code in `${CODE_NAME}/`. Follow `AGENTS.md`.

## Workflow

### Step 0: Resolve the target

1. Match `PLAN_NAME` against `metds/plans/*_plan.md` by slug, numeric prefix, or full filename.
2. Only leaves are executable. If the target has non-empty `children:`, list its leaves and ask which one to execute, or offer to process them one at a time in dependency order.
3. If the target is absent or ambiguous, list concise candidates and ask one direct question.
4. Read the selected sub-plan in full.

### Step 1: Check readiness

1. Require concrete §3 Task Breakdown and §5 Done-Criteria. If they are mostly `[TBD]` / `【待定】`, report the missing decisions and ask whether to return to `$rsch-plan-decomposer` or continue with the remaining uncertainty explicitly recorded.
2. Verify named datasets, weights, code modules, and every `depends_on` sibling. If a hard dependency is missing or an upstream sibling is not `exec_status: done`, stop and report the exact blocker.
3. If the selected leaf already has `exec_run`, read that run's log and resume it. Otherwise use run name `<prefix>_<slug>`. If that directory already exists but is not a resumable run for this leaf, ask for a distinguishing suffix; never invent one.

### Step 2: Orient

Follow `references/orient_checklist.md`:

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, and `PYTHON_HOME`. If `.env` is missing, create it from `.env.example` only when the user has asked to execute and then stop for the machine-specific values; never guess them.
2. Map `${CODE_NAME}/` and declare greenfield when it contains no implementation.
3. Trace each §3 step to real files and classify it as exists / modify / create.
4. Identify the actual run and test entrypoints.

### Step 3: Build and checkpoint EXEC_PLAN

1. Refine §3 plus the gap list into ordered actions. Each action must bind `{files / command through project env / artifact / check}`; the final action binds the §5 done-criterion.
2. Mark the STOP line explicitly and estimate runtime/cost when known.
3. Show a concise plan and expected side effects in commentary. Pause only for a material scope choice or a STOP-line action that requires user execution.
4. Create `wkdrs/<run>/EXEC_PLAN.md` from the matching language template and initialize `EXEC_LOG.md`. Update the sub-plan frontmatter to `exec_status: in_progress` and set `exec_run`.

### Step 4: Execute and verify

For each unfinished action:

1. Choose local execution or selective delegation. When delegating, use `references/agent_dispatch_spec.md` and keep file ownership non-overlapping.
2. Make only the action's necessary changes and run its narrow bound check through the project environment.
3. Re-run or independently inspect the bound check in the main loop. On pass, checkpoint the evidence and artifact path. On fail, diagnose and retry at most twice when a concrete fix is available; otherwise mark the action `blocked` and stop.
4. If the action crosses the STOP line, prepare the exact command (and optionally `execs/scpts/<run>.sh`), record it under `Awaiting user`, and stop without running it.

### Step 5: Finalize

1. Run the sub-plan's §5 done-criterion and record the evidence in `EXEC_LOG.md`.
2. If met, set the run and sub-plan `exec_status: done`. If unmet, follow the local fallback in §6 or report the verified gap.
3. Check `references/exec_rubric.md` and fix in-scope failures before reporting; list at most five remaining failures with concrete remedies.
4. If a result hits a parent kill-criterion or invalidates the cheap MVP assumption, record a **Strategy signal** in the log and recommend `$rsch-plan-coach <slug>` or `$rsch-plan-decomposer <slug>`. Do not edit the parent's strategy sections.

### Step 6: Report

Lead with the outcome. State what was verified and its evidence, where artifacts and logs live, which commands await the user, and any remaining risk. Keep the report under about 400 words.

## State Rules

- Treat `wkdrs/<run>/EXEC_LOG.md` as the execution source of truth. On reinvocation, skip `done` actions and resume from the first unfinished one.
- Edit only `exec_status`, `exec_run`, and `updated` in the sub-plan frontmatter; never rewrite its §1–§6.
- Legal action status: `pending` / `in_progress` / `done` / `blocked` / `skipped`.
- Match the user's dialogue language while preserving the plan body's frontmatter `language`; keep technical terms in English inside Chinese plans.
