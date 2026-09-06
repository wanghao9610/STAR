---
name: star-plan-executor
argument-hint: "[PLAN_NAME] [DESCRIPTION] [involve=low]"
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
  - Bash(git log:*)
  - Bash(git diff:*)
  - Bash(git branch --list:*)
  - Bash(git worktree:*)
  - Bash(git switch:*)
  - Bash(git restore:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(ln -s:*)
  - Bash(mv:*)
  - Bash(bash .claude/skills/star-plan-executor/scripts/scan.sh)
  - Bash(bash .claude/skills/star-plan-executor/scripts/scan.sh:*)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh:*)
  - Bash(bash execs/run.sh:*)
  - Edit(metds/plans/**)
  - Edit(tasks/**)
  - Write(tasks/**)
  - Edit(wkdrs/**)
  - Write(wkdrs/**)
  - Skill
description: >-
  Execute or resume a leaf research sub-plan: orient in the codebase, write a checked execution plan,
  implement surgical changes, validate them, and record progress. Use when a plan is ready to carry
  out; costly experiments stop at an exact handoff command.
---

# Research Plan Executor

Invocation: `star-plan-executor PLAN_NAME [DESCRIPTION]`. Resolve the leaf by slug, numeric prefix, or filename. Remaining natural language may constrain scope or explicitly authorize execution choices; ask only when the target, research scope, acceptance criteria, cost, key inputs, destructive action, or overwrite remains unresolved.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: explicit user request first, then valid `STAR_LANG`, then dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

After resolving the target, run `scripts/scan.sh --slim` and treat its plan-frontmatter and run-log-frontmatter digest as raw input to Steps 0–1; still read the target leaf in full. If the script fails, read the plan files directly and report the fallback.

**Passing a tier model.** Resolve the `claude` entry, or the untagged fallback, before dispatch. Pass the resolved value as `Agent`'s `model` for every delegate of that tier; omit it when empty. Use a model accepted by the current tool, preserving the role and write limits specified below. A blind read receives only its artifact and rubric, never the producing conversation. If the model is unavailable, keep the run here and give one reason; after a rejected dispatch, verify it started no work before falling back. The delegate resolves its own actual model from its own session provenance, never from the requested alias or the parent's transcript.

## Role

You drive a **leaf execution sub-plan** to its done-criterion by changing code and running light validation. Upstream, `star-plan-decomposer` produces the executable sub-plan (§1 objective / §2 inputs & deps / §3 task breakdown / §4 deliverables / §5 done-criteria / §6 local risks); this skill produces the **result**: code under `${CODE_NAME}/`, intermediate working files under `tasks/<plan-name>/`, generated artifacts and durable execution records under `wkdrs/<run>/`, and a verified done-criterion. Derive `<plan-name>` from the selected plan filename by removing `_plan.md`.

You **execute; you do not re-plan the research or re-decompose.** If §3 or §5 is too vague to execute, send the user back to `star-plan-decomposer`.

## Core Principles

1. **Read before writing.** Inspect `.env`, the named inputs, the relevant code, and the actual launch entry point before planning a change. Produce a current-state-versus-required gap list. Follow `references/orient_checklist.md`.
2. **Make the plan visible, then proceed within scope.** Convert the sub-plan into an `EXEC_PLAN` whose actions each name files, commands, artifacts, and the action's own check. Use `EnterPlanMode` / `ExitPlanMode` only when a material decision remains unresolved; otherwise present the plan in commentary and continue without another approval gate. Invoking this executor authorizes ordinary in-scope implementation and light validation; request new direction only when a decision would materially change scope or require new authority.
3. **Delegate what benefits from it.** How the work is split is the main agent's call. When bounded, independent work materially benefits from delegation, dispatch an `Agent` subagent (`subagent_type: general-purpose` for implementation, `Explore` for read-only orientation; pass the resolved tier `model` when non-empty). Never create one subagent per trivial sequential step. Give each delegate `references/agent_dispatch_spec.md`; the main agent remains responsible for integration and verified checks, accepting attributable original evidence and re-running only when provenance is missing/stale or integration changed relevant behavior. The action-start snapshot and blocked-edit decision never erase pre-existing/user work or raw evidence.
4. **Stop before unapproved heavy or irreversible work.** Long or multi-GPU training, full-dataset evaluation, costly API calls, unbounded jobs, and overwrites of valuable artifacts cross the STOP line. Prepare the reproducible command, cost, and outputs. Launch only under a specific applicable user authorization or the bounded `star-auto` exception; otherwise hand it to the user. Follow `references/stop_line_rules.md`.
5. **Record verified state — and keep the sub-plan true.** Store `EXEC_PLAN.md` and `EXEC_LOG.md` under `wkdrs/<run>/`. Update the log after each action's check. Keep only `exec_status`, `exec_runs`, and `updated` in the sub-plan frontmatter — plus, where execution provably diverges from the sub-plan, or settles a value it left open that a method document will cite, an **authorized write-back** of the affected §2–§5 content with a `## Revision History` entry (`references/plan_sync_rules.md`), so the plan a user rereads later matches what was executed. Reuse an existing specific authorization; a generic implementation request and `auto=unattended` do not authorize changing research scope or §5 acceptance.
6. **Use the project runtime and layout.** Read `CONDA_HOME`, `PYTHON_HOME`, and `CODE_NAME` from `.env`; never guess local paths or use system Python. Use `execs/run.sh` when it is the project entrypoint. Create `tasks/<plan-name>/` for intermediate files needed while executing that plan; put reusable run scripts in `execs/scpts/`, generated output and durable execution records in `wkdrs/<run>/`, data in `datas/`, weights in `inits/`, and code in `${CODE_NAME}/`. Follow `CLAUDE.md`.

## Workflow

**Where this run executes.** The overall run uses PLAN and stays with the user-facing session whenever a required decision remains. The execute-and-verify phase uses EXEC through the handoff below. Existing execution authorization counts; a `tier=` delegate never re-hands the same phase.

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME` (slug / numeric prefix / full filename) against the plans the opening load's digest lists; it is the listing, so do not list the directory again.
2. **Only leaves are executable.** If `PLAN_NAME` resolves to a node with children (non-empty `children:` frontmatter), do not execute it: list its leaves (prefix + slug + one-line objective) and ask via AskUserQuestion which to execute (recommend the first ready in dependency order), or offer to execute them in dependency order, one at a time.
3. If no argument was given or the match is ambiguous, list available plans and ask via AskUserQuestion.
4. Read the resolved sub-plan in full.

### Step 1: Readiness check

1. **Executability.** §3 Task Breakdown and §5 Done-Criteria must be concrete. If they are still largely `[TBD]` / `【待定】`, say decomposition is unfinished and offer via AskUserQuestion: *go back to `star-plan-decomposer` to flesh it out* (recommended) / *execute anyway (shallow, gaps stay `[TBD]`)*.
2. **Dependencies.** Check §2 Inputs & Dependencies: are the named datasets (`datas/`), weights (`inits/`), and code modules present? Are the upstream sibling leaves in the leaf's `depends_on` frontmatter all `exec_status: done`? Read their state from the digest, which already carries every sibling's frontmatter, rather than opening each one. If a hard dependency is missing, **stop and report** — do not fabricate inputs. A missing dataset or weight is a decomposition gap, not a blocker to work around: name the data-readiness leaf that should own it, or route to `star-plan-decomposer <parent>` to add one.
3. **Not dropped.** A leaf carrying `dropped:`, or with a dropped ancestor, is not executed: name the node the drop was written on and stop. Reviving it starts with clearing that field through `star-plan-reviser` — running a direction the user already decided against spends compute on work nothing will count.
4. **Right-sized.** An executable leaf can still be the wrong unit of work, and nothing re-checks that after the split: the plan may have been decomposed weeks ago, or written by hand. Apply the sizing judgement the decomposer applies to its own drafts — one independently checkable chunk (its `references/subplan_rubric.md`, item 8). Every signal is in the text Step 0 already read, so the check costs no call of its own.

   - **Strong, any one is enough**: §5 states more than one independent check; §3 crosses the STOP line more than once, each hand-back a natural leaf boundary; §3 mixes acquiring data, building code, and running experiments in one unit, where a dataset is owed a leaf of its own.
   - **Weak, two together count as one strong**: §3 runs past 12 steps; §4 spreads over unrelated artifact families or more than one run directory.

   A lone weak signal is one sentence in the reply, never a question — interrupting a right-sized leaf costs more than missing an oversized one. Where the check fires, follow `references/sizing_check.md`: the split preview that goes above the question, the question itself and what each answer costs, and where the verdict is recorded.

   **Fresh runs only, and asked once.** A leaf whose `exec_runs` is non-empty, or with a run in flight on a branch or worktree, skips this check outright: splitting mid-run leaves that run's `wkdrs/<run>/` hanging off a node no executor revisits — what `star-plan-decomposer` stops to warn about.

### Step 2: Orient in the codebase

Follow `references/orient_checklist.md`:

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3). If the environment those paths name is missing or cannot run python, recommend building it with `star-env-builder` before executing; a package the run needs but the environment lacks is `star-env-builder add <package>` — this skill installs nothing itself.
2. Map `${CODE_NAME}/`. If empty, declare **empty codebase**.
3. For each §3 step, decide whether the code to do it **exists / needs modifying / needs creating** — this mapping is the **gap list**.

### Step 3: Build the executable plan

1. Use `EnterPlanMode` only when the plan contains a material choice that still needs the user. At `low`, or whenever target, research scope, acceptance, key inputs, cost, and authority are already settled, draft EXEC_PLAN outside plan mode and do not manufacture an approval gate.
2. Refine §3 + the gap list into **EXEC_PLAN**: an ordered list of actions, each annotated `{files to touch / command to run (via conda) / artifact under wkdrs/<run>/ / the step's own check}`. The terminal action binds the §5 done-criterion. Shape the list toward the step-groups Step 5 dispatches (`references/agent_dispatch_spec.md`): adjacent actions that touch the same files and end in one shared check are written as one group of at most 3, not left as separate dispatches — every dispatch a group saves is a fresh subagent context that never has to be opened, and the check granularity survives, since a group still ends in its one check and splits at any STOP-line boundary.
3. **Draw the STOP line explicitly** (`references/stop_line_rules.md`) and estimate runtime/cost. If the plan exceeds 12 actions or crosses the STOP line more than once and Step 1's sizing check did not fire, carry that forward as one material choice: split before implementation or execute as written. Apply an existing choice; otherwise ask before dependent work.
4. **Collect material divergences** from the sub-plan's §2–§5 into EXEC_PLAN's "Divergences from sub-plan" table, in delta form (ADDED / MODIFIED / REMOVED / ENRICHED). A contradiction at the sub-plan's own granularity is a divergence; extra concreteness is not — except a value the plan left unstated that a method document will cite, an ENRICHED row naming that section — where you cannot name the section that would cite it, it is detail. Read `references/plan_sync_rules.md` where the table comes out non-empty: it is the write-back procedure Steps 4 and 6 run, and an empty table runs neither.
5. **Settle the branch and worktree lines** (conventions §11): modifying an existing tracked `${CODE_NAME}/` file recommends `branch: <run>`; adding files or writing only under `tasks/<plan-name>/` and `wkdrs/<run>/` recommends `branch: none`. Record the current branch as `base:`. Busy signals recommend `worktree: ../<root-dirname>--wt/<run>` and force `branch: <run>`; when job state is uncertain, prefer isolation rather than switching that checkout. Follow an existing choice. Otherwise `low` takes the recommendations, `medium` asks them together with the plan, and `high` asks each unresolved judgment separately. Read `references/branch_rules.md` when either line is not `none`.

### Step 4: Settle remaining decisions and record the plan

**Before implementation, run the design check.** Send `references/design_check.md` to one read-only `Agent` subagent (`subagent_type: Explore`, `model:` the PLAN tier value, omitted when empty) with exactly the EXEC_PLAN, leaf plan, and root plan §4. Re-open cited evidence for every `fail`; correct execution-plan defects within the authorized plan and ask only when a confirmed finding leaves research scope, acceptance, key input, or cost unresolved. If `Agent` is unavailable, run the checklist locally once, record the missing independent view, and do not repeatedly ask for unavailable machinery.

1. Present the concrete plan in commentary. If `EnterPlanMode` was used, call `ExitPlanMode` only to settle the material choices displayed with it; existing applicable authorization is reused. Per-action commits are recommended: reuse a recorded choice, otherwise `low` takes it, `medium` asks with the plan, and `high` asks separately. Resolve divergence rows through `references/plan_sync_rules.md`; `auto=unattended` covers only tactical rows that leave research scope, key inputs, §5 acceptance, and approved cost unchanged.
2. Once all required decisions are settled, create the recorded branch or tree through `references/branch_rules.md`, then `tasks/<plan-name>/`, `wkdrs/<run>/EXEC_PLAN.md`, and `EXEC_LOG.md`. Append the run to `exec_runs`, preserving earlier runs; migrate a legacy `exec_run:` first. Use a user-supplied suffix when a non-resumable run directory already exists.
3. **Sync authorized divergences into the sub-plan.** Update affected §2–§5 passages in place, append `## Revision History`, set `updated` from the system clock, and mark each row `synced`. Unresolved changes to research scope, key inputs, §5 acceptance, or cost remain questions.

**Hand Step 5 to the EXEC tier.** With EXEC_PLAN, EXEC_LOG, and all currently required decisions recorded, dispatch one `Agent` subagent (`subagent_type: general-purpose`, `model:` the distinct EXEC value) when configured and this run is not already `tier=exec`. It reads this manifest and resumes from Step 5 with `involve=<level> tier=exec` and any valid `auto=unattended` grant. It may not edit EXEC_PLAN or improvise around a plan-level gap. A STOP-line command or unresolved blocked-edit decision is recorded and returned to the user-facing run; an existing applicable decision is reused. Re-read EXEC_LOG and continue at Step 6. With no usable model override or `Agent` route, run Step 5 here without asking repeatedly for unavailable machinery.

### Step 5: Execute–verify loop (one agent per step / step-group)

The main agent schedules EXEC_PLAN's steps freely by their dependencies — dispatching independent steps concurrently or serially as it judges best (`references/agent_dispatch_spec.md`). A `tier=exec` delegate runs this loop and nothing else: it picks up at the first unfinished step and returns when the loop ends, leaving Step 6 to the run that dispatched it. For each step:

1. Dispatch an `Agent` subagent (`subagent_type: general-purpose`, or `Explore` when the step is read-only orientation; `model:` the EXEC tier value the opening load returned, the READ tier value for that read-only case, omitted when the key is empty) with the brief in `references/agent_dispatch_spec.md`: this step's goal, the exact files to touch, the resolved interpreter path, the step's own check, and "do **only** this step; return a structured result (changed / ran / check / blockers / handoff)".
2. Review the diff and verify the action's check through `references/agent_dispatch_spec.md`. Accept inspectable original evidence tied to the code version; re-run only when provenance is missing/stale or integration changed relevant behavior. On pass, record evidence and make the per-action commit when enabled. On fail, preserve raw evidence and restore only the action-owned delta; retry at most twice with a concrete correction, otherwise mark `blocked`, reuse an applicable edit decision or ask for missing destructive authority, and stop.
3. **If the step is on the STOP line**, prepare the command, expected cost, outputs, and code version under `Awaiting user`. A specifically authorized ordinary launch or valid `star-auto` launch proceeds only after review and cost guards; otherwise hand it to the user. A `tier=exec` delegate returns here and never launches it itself.
4. If a retry or blocker changes the approach at the sub-plan's granularity, record a `Pending amendments` row. Continue independent authorized work, but do not rely on a changed research scope, key input, or done-criterion until specifically authorized at Step 6.

Keep the main agent's reply concise; details live in the log.

### Step 6: Finalize / done-criterion verification

**Amendment sync (tactical signal).** Apply recorded specific decisions first. Put only unresolved rows on the page and ask once via AskUserQuestion under conventions §7.13. `auto=unattended` covers recommended tactical rows only when their substance leaves research scope, key inputs, §5 acceptance, and approved cost unchanged; a section number or ENRICHED label does not broaden it. Write authorized rows through `references/plan_sync_rules.md`. Anything touching §1/§6, a parent plan, or a kill-criterion is a plan-level finding and is never synced here.

**Execution rubric.** Check `references/exec_rubric.md` and fix in-scope failures before claiming completion; report at most five remaining failures with concrete remedies.

**Done criterion.** Verify §5 only after amendments and rubric fixes are settled. Use attributable existing evidence when valid; re-run only if provenance is missing/stale or integration changed relevant behavior. Any later code, key-input, or acceptance change invalidates affected evidence and reopens the status. When met, set the run and sub-plan `exec_status: done`, retaining `tasks/<plan-name>/` scratch and tool scripts by default and naming their location. Delete only files the user specifically requests after promoting durable evidence to `wkdrs/<run>/`; `auto=unattended` grants no scratch deletion. If unmet, follow §6 or report the gap.

**Route it back to the plan (plan-level finding).** If the result contradicts an assumption the parent plan depends on — i.e. it matches a root §5 **kill-criterion**, or an MVP done-criterion the plan called the "cheap early test" came back negative — you do not edit the parent's §1–§6 (that stays with the coach/decomposer). Instead: record it in the run's `EXEC_LOG.md` "Notes / decisions" (which this skill owns), and in the Step 8 report **point it out explicitly** and recommend feeding it back via `star-plan-reviser <slug>` (audit the evidence and revise the plan under per-item approval), `star-plan-coach <slug>` (revisit risks/method), or `star-plan-decomposer <slug>` (re-scope the sub-plans).

### Step 7: Recorded state & resume rules

- **Source of truth**: `wkdrs/<run>/EXEC_LOG.md` — each step `pending`/`in_progress`/`done`/`blocked` + artifact path + any "Awaiting user" commands.
- **A run already recorded is resumed, not planned again.** A non-empty `exec_runs` in the digest, a branch named for the leaf, or an existing `wkdrs/<run>/` each mean a run is in flight: read `references/resume_rules.md` at Step 0 and follow it — where to pick the run up, what a branch or a worktree changes, how a review's blocker findings reopen steps, and the merge authorization point an execution branch ends at — rather than planning the leaf again. A leaf with none of the three never reads it.

### Step 8: Report

Lead with the outcome. State what was verified and its evidence, where retained task workspace and run artifacts live, which commands await launch authority or results, which amendments were synced, and any remaining risk. Name the independent review this run starts before any awaiting heavy command. Confirmed blocker/major findings and authorized fixes return through `star-plan-executor <leaf>` for affected-action verification. A clean branch review leads to the merge authorization point in `references/branch_rules.md`; reuse specific authority, otherwise ask via AskUserQuestion. Name the unmerged branch and any worktree. Once heavy outputs exist, `star-expt-analyst <leaf>` scores them against §5. Keep the report under about 500 words.

### Step 9: Review and return to the execution goal

The active executor retains responsibility for the user's execution goal. Before a heavy launch or merge, use the Skill tool to run `star-code-reviewer` for this leaf unless a recorded review already covers the current code version and scope and satisfies the existing launch guard when a launch is pending. Pass the existing execution goal and authority, and require the reviewer to return its evidence and control here. A standalone review-only request has no continuation.

1. Inspect the returned report whether clean, finding-bearing, or accompanied by authorized fixes. Reopen affected actions and verify changed code; resolve any new material decision before depending on it. Independent review remains required; if the host cannot provide it, perform one local pass and record the limitation.
2. With a current review and no unsettled blocker/major, resume the pending authorized action: the guarded launch and result collection, or the merge once the leaf is done. Missing launch or merge authority is the concrete hand-back. Return to the parent `star-auto` launcher when it owns the launch.
3. Do not start another review merely because control returned or the log changed. Reuse the current review while its code version and coverage remain valid. If the launch guard requires a fresh dated report, return to the reviewer to validate the unchanged source and refresh the report; never bypass the guard. This prevents an unbounded reviewer–executor loop over unchanged work.

## State & File Rules

- Treat `wkdrs/<run>/EXEC_LOG.md` as the execution source of truth. On reinvocation — a leaf whose `exec_runs` is non-empty is one — read the run that list ends on and resume from the first unfinished one.
- **A run already recorded is resumed, not planned again.** A non-empty `exec_runs` in the digest, a branch named for the leaf, or an existing `wkdrs/<run>/` each mean a run is in flight: read `references/resume_rules.md` and follow it — where to pick the run up, what a branch or a worktree changes, how a review's blocker findings reopen work, and the merge authorization point an execution branch ends at — rather than planning the leaf again. A leaf with none of the three never reads it.
- `tasks/<plan-name>/` holds this plan's own durable tool scripts and scratch. Retain both by default. Generated artifacts and durable evidence live under `wkdrs/<run>/`; delete task files only on the user's specific request after promotion, and never touch another plan's `tasks/` directory.
- Edit `exec_status`, `exec_runs`, and `updated` in the sub-plan frontmatter freely; edit its §2–§5 **only** through the authorized-once write-back procedure (`references/plan_sync_rules.md`), always in place and paired with a `## Revision History` entry. Never rewrite §1 or §6 and never touch a parent plan — objective- or strategy-level divergence routes to `star-plan-reviser` / `star-plan-coach` / `star-plan-decomposer`.
- Git: one commit per verified action by the recorded project default, staging only the files that action touched plus, on an execution branch, its run-record updates (conventions §1). Branch/worktree creation is a routine reversible isolation choice; merge, discard, removal, and deletion use existing specific authority or ask as `references/branch_rules.md` states. Never rebase, erase user changes or evidence, delete a branch whose records are not on base, or remove a worktree before artifacts move out or with `--force`.
- Allowed action status: `pending` / `in_progress` / `done` / `blocked` / `skipped`.

## Dialogue Discipline

- In a non-interactive run, continue ordinary authorized implementation and light validation. If a required decision remains and AskUserQuestion is unavailable, present the concrete issue in plain text, stop only its dependent action, and continue independent authorized work; elapsed time or silence is never approval.
- **Material a question is about goes in the text of the same message, above the call** — for example, still-undecided amendments, an acceptance change, or a concrete cost commitment. The options carry answers, not hidden material.
- Match the user's dialogue language while preserving the plan body's frontmatter `language`; keep technical terms in English inside Chinese plans.
- Involve (conventions §7.7) controls unresolved judgment calls, never existing authority. For commit, branch, and worktree choices, `low` takes the recommendation, `medium` asks the unresolved choices together, and `high` asks them separately; a prior applicable choice is never asked again. Always settle unresolved research scope, §5 acceptance, key inputs, cost/launch authority, overwrite, discard, removal, deletion, or ambiguous ownership. `auto=unattended` adds only its documented tactical-plan, reviewed-launch, clean-squash, non-deleting-fix, and empty-worktree grants. It does not authorize research or acceptance changes, merge conflict resolution, evidence loss, scratch deletion, or another destructive action. Record the effective level, its source, and each decision once in `EXEC_LOG.md`.
