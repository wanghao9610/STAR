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
  - Bash(bash .claude/skillsstar-plan-executor/scripts/scan.sh)
  - Bash(bash .claude/skillsstar-plan-executor/scripts/scan.sh:*)
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
  Execute a leaf sub-plan (from star-plan-decomposer, under metds/plans/) against the project code.
  Orients in the codebase (${CODE_NAME}/, from .env) to build a "current vs required" gap list, enters
  plan mode to turn the sub-plan's task breakdown into an executable plan, waits for approval through
  ExitPlanMode, then dispatches one subagent per step to modify code and run light validation — stopping
  before heavy experiments (long/multi-GPU training, costly API calls) and handing those commands back.
  Keeps intermediate files under tasks/<plan-name>/ and records execution state plus artifacts under
  wkdrs/<run>/ so runs resume across sessions. Writes user-confirmed deviations and values settled by
  execution back into the sub-plan, with a Revision History entry. Use when the user runs
  star-plan-executor, when a run names it as the next action, or wants to execute / implement / carry
  out / run a sub-plan, turn an execution plan into code and results, or start the work a plan describes.
  Bilingual (en/zh).
---

# Research Plan Executor — plan executor

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `star-plan-executor PLAN_NAME [DESCRIPTION]`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`00`), or a filename (`00_mvp-three-tier_plan.md`). Anything after the plan name is a description (conventions §7.12): in your own words, what this run is for — a lead the run may follow and may record, never an instruction that stands in for a confirmation point. It never settles the plan name itself: text that resolves to no plan leaves the target still to be asked for. An optional `involve=low|medium|high` token may accompany `PLAN_NAME` (e.g. `… involve=low`): it sets the `involve` level for this run (conventions §7.7), belongs to neither `PLAN_NAME` nor the description, and is stripped before either is read.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. Its read is this skill's whole opening load — one message, before acting: the conventions file arrives through its own `Read` call, never `cat`-ed into a Bash command — a Bash result past roughly 30 KB is written out to a file that costs a second round trip to read back, and the conventions file alone is past that limit — plus one Bash call in the same message, with the project root as the working directory, carrying two lines:

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
bash <this skill's directory>/scripts/scan.sh --slim
```

An executor commits, runs, and writes the sub-plan back, so every section applies (§1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout, §11 execution branches), and nothing else needs loading before Step 0. The `references/*.md` files this skill names are step-time material — load each where its step cites it, not up front. The `grep` is the §7.6/§7.7 lookup only — `STAR_LANG` sets the reply language, `INVOLVE` the question level — folded into the opening message so neither costs a round trip of its own; the full `.env` runtime (§3) is still resolved at its own step, Step 2. The second line is the shared collector, and its digest is what Steps 0 and 1 resolve against: every plan's frontmatter — `children:` for the leaf test, `depends_on` and the siblings' `exec_status` for the dependency check, `exec_runs` for a resume — plus every run log's frontmatter. The target sub-plan is still read in full at Step 0; what the digest replaces is opening its siblings one at a time. It gathers, it never judges: no tree, no readiness verdict, no ordering. Read what it prints as raw file content, exactly as if you had opened each plan yourself. `--slim` is what keeps the result under the size limit on a project with history; if it is written out anyway, re-run that line on its own. If the script is missing or fails, fall back to reading `metds/plans/*_plan.md` directly, and say in your reply that the scan fell back.

**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the `.env` lookup's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

You drive a **leaf execution sub-plan** to its done-criterion by changing code and running light validation. Upstream, `star-plan-decomposer` produces the executable sub-plan (§1 objective / §2 inputs & deps / §3 task breakdown / §4 deliverables / §5 done-criteria / §6 local risks); this skill produces the **result**: code under `${CODE_NAME}/`, intermediate working files under `tasks/<plan-name>/`, generated artifacts and durable execution records under `wkdrs/<run>/`, and a verified done-criterion. Derive `<plan-name>` from the selected plan filename by removing `_plan.md`.

You **execute; you do not re-plan the research or re-decompose.** If §3 or §5 is too vague to execute, send the user back to `star-plan-decomposer`.

## Core Principles

1. **Read before you write.** Before planning any change, orient in `${CODE_NAME}/`: read the modules/entrypoints the sub-plan's §2 names, and produce a "current state vs §3 requirements" gap list. Never assume code exists; `code/` may be an empty codebase (only `.gitkeep`), where the plan builds the structure from scratch — or, better, starts from a reference codebase first via `star-code-architect`. Reference: `references/orient_checklist.md`.
2. **Plan behind a confirmation point, execute behind an agent.** The executable plan (EXEC_PLAN) is produced in **plan mode** and approved via **`ExitPlanMode`** before anything is written or run. Execution goes to **subagents, one per step / step-group**: the main agent orchestrates and verifies, and never edits code or launches jobs itself. Reference: `references/agent_dispatch_spec.md`.
3. **Stop before heavy experiments.** Agents write code and run **light validation only** (runnable checks, small-scale / no-finetune checks like an MVP done-criterion). Before any long/multi-GPU training run or costly API call, **stop**: write the prepared command into EXEC_LOG's "Awaiting user" area and hand it back. Rules: `references/stop_line_rules.md`.
4. **Files are the source of truth; record every step — and keep the sub-plan true.** Execution state lives in `wkdrs/<run>/` (`EXEC_PLAN.md` + `EXEC_LOG.md`), intermediate working files in `tasks/<plan-name>/`. Update the log after each verified step. The sub-plan gets a lightweight `exec_status` + `exec_runs` pointer — plus, where execution provably diverges from it, or settles a value it left open that a method document will cite, a **user-confirmed write-back** of the affected §2–§5 content and a `## Revision History` entry (`references/plan_sync_rules.md`), so the plan a user rereads later matches what was executed.
5. **Every step ends in a check; the run ends in the done-criterion.** Verify each step narrowly before dispatching the next; the run finishes on the sub-plan's §5 done-criterion. Reuse the project's `/verify` and `/run` skills where useful. This is Goal-Driven Execution (CLAUDE.md §4) and Verification (§11), executed.
6. **Use the project runtime and launch entry point.** Invoke run commands through the project's run entrypoint `execs/run.sh` where one exists. Create `tasks/<plan-name>/` for this plan's intermediate files, and put reusable launch scripts, including prepared STOP-line commands, under `execs/scpts/<run>.sh`.

## Workflow

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME` (slug / numeric prefix / full filename) against the plans the opening load's digest lists; it is the listing, so do not list the directory again.
2. **Only leaves are executable.** If `PLAN_NAME` resolves to a node with children (non-empty `children:` frontmatter), do not execute it: list its leaves (prefix + slug + one-line objective) and ask via AskUserQuestion which to execute (recommend the first ready in dependency order), or offer to execute them in dependency order, one at a time.
3. If no argument was given or the match is ambiguous, list available plans and ask.
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

### Step 3: Enter plan mode → produce the executable plan

1. `EnterPlanMode`.
2. Refine §3 + the gap list into **EXEC_PLAN**: an ordered list of actions, each annotated `{files to touch / command to run (via conda) / artifact under wkdrs/<run>/ / the step's own check}`. The terminal action binds the §5 done-criterion. Shape the list toward the step-groups Step 5 dispatches (`references/agent_dispatch_spec.md`): adjacent actions that touch the same files and end in one shared check are written as one group of at most 3, not left as separate dispatches — every dispatch a group saves is a fresh subagent context that never has to be opened, and the check granularity survives, since a group still ends in its one check and splits at any STOP-line boundary.
3. **Draw the STOP line explicitly** (`references/stop_line_rules.md`): mark which actions the agent executes vs which are "prepare command, hand to user" (heavy experiments). **The finished plan is the second reading of the leaf's size**: if it runs past 12 actions or crosses the STOP line more than once and Step 1's sizing check did not fire, carry that to Step 4's confirmation point as one more option — *go back and split it first*, ending the run before anything is written — rather than as a question of its own.
4. **Collect material divergences** from the sub-plan's §2–§5 into EXEC_PLAN's "Divergences from sub-plan" table, in delta form (ADDED / MODIFIED / REMOVED / ENRICHED). A contradiction at the sub-plan's own granularity is a divergence; extra concreteness is not — except a value the plan left unstated that a method document will cite, an ENRICHED row naming that section — where you cannot name the section that would cite it, it is detail. Read `references/plan_sync_rules.md` where the table comes out non-empty: it is the write-back procedure Steps 4 and 6 run, and an empty table runs neither.
5. **Settle the branch and worktree lines** (conventions §11): if any EXEC_PLAN action modifies a pre-existing tracked file under `${CODE_NAME}/`, the plan carries `branch: <run>` and recommends executing on it; a plan that only adds new files, or writes only `tasks/<plan-name>/` and `wkdrs/<run>/`, carries `branch: none`. Record the branch the checkout is on as `base:`, whatever its name. The worktree line answers whether this checkout is free right now (§11.7): any busy signal (HEAD on another run's execution branch; uncommitted changes on paths another run's records claim; handed-back commands whose results are not collected — a possible live job, asked about, never checked by a command; or the user naming parallel work) → `worktree: ../<root-dirname>--wt/<run>`, which forces `branch: <run>` even where the gap list said none (§11.8); no signal → `worktree: none`. The signals are the ones just named; what follows from them — the two questions, the creation, the per-step commits, the resume, the merge — is `references/branch_rules.md`, read where either line comes out other than `none` and left unread where both are `none`.

### Step 4: Confirmation point — the user approves (`ExitPlanMode`)

**Before the call, run the design check.** Send `references/design_check.md` out for a blind read: one read-only `Agent` subagent (`subagent_type: Explore`) briefed with exactly three files — the EXEC_PLAN just written, the leaf sub-plan, and the root plan read at its §4 alone, the only root section the checklist admits as evidence (name the checklist's `_zh` twin when the plan's frontmatter says `language: zh`; the delegate never picks) — and the scope "ONLY these three files, and of the root plan only its §4. Do not rank, do not decide, do not run anything." It returns, per item: `item`, `verdict: pass | fail | unclear`, `evidence`, `fix`. The main agent re-opens the cited line for every `fail` it means to raise — an absence `fail` quotes nothing, so for those it re-reads the section the item belongs to — then puts at most five findings on the page **above** the call, one line each; a `fail` it cannot confirm is dropped. The check reports; this confirmation point decides, and nothing here stops the run. Where no delegate is available the main agent runs the checklist itself (conventions §6.1).

1. `ExitPlanMode` presenting EXEC_PLAN + the changes it will make: files to be written, commands to be run, where the STOP line falls, rough cost/runtime — and the divergence table, stated as "approving this plan also syncs these back into the sub-plan". Ask at the same confirmation point whether each verified step gets its own commit (recommended), naming any path that already carries uncommitted changes — those are never staged. Say what saying no costs: if a later step has to be restored, the only record of where each step started is the one this run keeps itself (`references/agent_dispatch_spec.md`). Where Step 3 set `branch: <run>` or `worktree: <path>`, those two questions ride this same confirmation point, worded as `references/branch_rules.md` states (conventions §11, §11.7).
2. On approval — an approved branch or tree is created first, by `references/branch_rules.md`'s "Creation", and everything below is born on it — then create `tasks/<plan-name>/` for intermediate working files. Persist `wkdrs/<run>/EXEC_PLAN.md` from `assets/exec_plan_template.md` and initialize `wkdrs/<run>/EXEC_LOG.md` from `assets/exec_log_template.md`. **Run name = `<prefix>_<slug>`**; append a user-supplied suffix (`_v2`, a date) to distinguish re-runs — never invent timestamps. **Append** the run to the sub-plan's `exec_runs` rather than replacing it: that history lets `star-expt-analyst aggregate` see every run of this leaf, not only the last. A plan still carrying a single `exec_run:` is migrated here to `exec_runs: [<that run>]` before the new entry is appended.
3. **Sync divergences into the sub-plan.** If the divergence table is non-empty, the approval just given covers it: update the affected §2–§5 passages in place, append a `## Revision History` entry, bump `updated`, and mark each row `synced` (`references/plan_sync_rules.md`).

### Step 5: Execute–verify loop (one agent per step / step-group)

For each step in EXEC_PLAN, in order:

1. Dispatch an `Agent` subagent (`subagent_type: general-purpose`, or `Explore` with `model: sonnet` when the step is read-only orientation) with the brief in `references/agent_dispatch_spec.md`: this step's goal, the exact files to touch, the resolved interpreter path, the step's own check, and "do **only** this step; return a structured result (changed / ran / check / blockers / handoff)".
2. When it returns, **the main agent re-runs the step's own check** (never trust a self-reported pass without evidence). Pass → record it in `EXEC_LOG.md`, update the sub-plan's lightweight status, and — when the confirmation point approved per-step commits — commit this step's files; on an execution branch that commit also stages the run-record updates this step caused, because only commits merge (conventions §11.2). Fail → the main agent's own re-run is the evidence: read the `file:line` the failure names, and open the agent's full diff only when deciding `blocked`, or when the failure looks like a sub-plan-granularity problem (item 4). Restore this step's files before retrying; bounded retry (≤2) with the failure fed back; still failing → mark the step `blocked`, settle what happens to its edits (`agent_dispatch_spec.md`), and stop with the log.
3. **If the step is on the STOP line** (heavy experiment) → do **not** dispatch it; write the prepared command into EXEC_LOG's "Awaiting user" area, add a row to the "Cost" section with its expected cost (GPUs × hours, or call count and spend), and stop, handing it to the user. When the user returns with the result, fill the actual into that row — the only place the root plan's §4 compute budget is reconciled; where the actual cannot be recovered write `unrecorded`, never blank.
4. If a retry or blocker changes the approach at the sub-plan's granularity (a step added/dropped/replaced, a deliverable path or done-criterion shifted), record a delta row under EXEC_LOG's "Pending amendments" and continue — these sync at Step 6, not mid-run.

Keep the main agent's reply concise; details live in the log.

### Step 6: Finalize / done-criterion verification

After all agent steps are `done`, verify the sub-plan's §5 done-criterion (reuse `/verify`, `/run` where useful). Met → set the sub-plan's `exec_status: done`, then offer once to delete the plan's `tasks/<plan-name>/` **scratch** — promote anything worth keeping into `wkdrs/<run>/` first, and record the choice in `EXEC_LOG.md`; keeping it is a fine answer. **The offer never covers the plan's own tool scripts** (conventions §9): list them by name as retained, and delete one only if the user names it. Not met → follow the sub-plan's §6 local fallback, or report the gap. Then run `references/exec_rubric.md` and report failing items (≤5, ranked, each with a concrete fix).

**Amendment sync (tactical signal).** If EXEC_LOG's "Pending amendments" is non-empty, put the batch on the page first — one numbered row per amendment: which section it changes, from what to what, and why — then ask via **one** AskUserQuestion (*sync all / sync all but the rows I name / answer my questions on the rows I name first / skip*, recommendation marked — conventions §7.13) and write confirmed rows back per `references/plan_sync_rules.md` (§2–§5 updated in place + `## Revision History` entry + `updated` bump, then check the rows off). Tactical only: anything touching §1/§6, a parent plan, or a kill-criterion is a plan-level finding — routed back to the plan below, never synced.

**Route it back to the plan (plan-level finding).** If the result contradicts an assumption the parent plan depends on — i.e. it matches a root §5 **kill-criterion**, or an MVP done-criterion the plan called the "cheap early test" came back negative — you do not edit the parent's §1–§6 (that stays with the coach/decomposer). Instead: record it in the run's `EXEC_LOG.md` "Notes / decisions" (which this skill owns), and in the Step 8 report **point it out explicitly** and recommend feeding it back via `star-plan-reviser <slug>` (audit the evidence and revise the plan under per-item approval), `star-plan-coach <slug>` (revisit risks/method), or `star-plan-decomposer <slug>` (re-scope the sub-plans).

### Step 7: Recorded state & resume rules

- **Source of truth**: `wkdrs/<run>/EXEC_LOG.md` — each step `pending`/`in_progress`/`done`/`blocked` + artifact path + any "Awaiting user" commands.
- **A run already recorded is resumed, not planned again.** A non-empty `exec_runs` in the digest, a branch named for the leaf, or an existing `wkdrs/<run>/` each mean a run is in flight: read `references/resume_rules.md` at Step 0 and follow it — where to pick the run up, what a branch or a worktree changes, how a review's blocker findings reopen steps, and the merge confirmation point an execution branch ends at — rather than planning the leaf again. A leaf with none of the three never reads it.

### Step 8: Report

What was verified (with evidence), where artifacts live, which commands were handed back to the user, which amendments were synced into the sub-plan, and remaining risks. If Step 6 reported a plan-level finding (a root kill-criterion hit), state it and name the feedback path (`star-plan-reviser` / `star-plan-coach` / `star-plan-decomposer`). Name the review Step 9 is about to start, and where commands were handed back at the STOP line, name it above the awaiting command. Say where the review leads: confirmed blocker/major findings come back through `star-plan-executor <leaf>`, which reopens the affected steps and verifies them before the command is handed back again — and on an execution branch a clean review leads through it too: re-invoking this skill reaches the merge confirmation point (conventions §11). Name the run's branch and its unmerged state whenever one exists, and the run's worktree path whenever it lives in one — follow-on skills work inside that tree. Where commands were handed back at the STOP line, add that once their outputs exist, `star-expt-analyst <leaf>` scores the results against the §5 done-criterion and says what they mean. Keep it under ~500 words.

### Step 9: Start the review

**The report is not the end of the turn.** With its text out, start `star-code-reviewer` on this leaf in the same reply — the `Skill` tool, `star-code-reviewer` as the skill and the leaf as its argument, the way Step 5 dispatches an `Agent` — to audit the implementation against the conventions and the sub-plan. It is one of the eight skills the agent may start and its target is settled, so it runs rather than prints: a command printed to the agent itself is a handoff to nobody (conventions §10.6). This is the run's last action in either ending — after a completed run, before revising or moving on; and before the user runs a command handed back at the STOP line.

1. **An awaiting STOP-line command changes nothing about this.** It stays printed and the user's (conventions §2); standing next to a command only the user may clear does not make the review one of those. Where a run ends with both, starting the review is what makes the report's order real, and what it found is handed back with the command.
2. **One narrow exception, asked once.** An exploratory leaf whose handed-back command is cheap may skip the review and run that command instead — offer it rather than deciding it, with the review recommended, and ask before the review starts. Nothing else on this step is a question: a review costs less than any run it might save.

## State & File Rules

- Intermediate working files live under `tasks/<plan-name>/`; execution state and generated artifacts live under `wkdrs/<run>/`. Never write execution logs into `metds/plans/` — the sub-plan gets only `exec_status` + `exec_runs` + `updated`. `tasks/<plan-name>/` holds this plan's own tool scripts (durable) plus its disposable scratch, whose lifecycle this skill owns: offer its deletion once at finalize when §5 is met, never the scripts (conventions §9). Generated artifacts and durable evidence never live there; never delete it unasked, and never touch another plan's `tasks/` directory.
- Code changes go under `${CODE_NAME}/`; data under `datas/`; weights under `inits/`; run scripts under `execs/scpts/` with `execs/run.sh` as the entrypoint (CLAUDE.md §8).
- Never launch heavy or irreversible jobs (long/multi-GPU training, full-dataset eval, costly API) autonomously; those cross the STOP line to the user.
- All run commands go through `.env`'s `CONDA_HOME` / `PYTHON_HOME`; never system python, never hardcoded local paths (CLAUDE.md §9).
- Edit the sub-plan's frontmatter (`exec_status`, `exec_runs`, `updated`) freely; edit its §2–§5 **only** through the user-confirmed write-back procedure (`references/plan_sync_rules.md`), always in place and always paired with a `## Revision History` entry. Never rewrite §1 or §6 and never touch a parent plan — objective- or strategy-level divergence goes back through `star-plan-coach` / `star-plan-decomposer` (route it back to the plan).
- Git: one commit per verified step, staging only the files that step touched — plus, on an execution branch, the run-record updates that step caused — and only when the confirmation point covered it; name pre-run dirty paths at the confirmation point (conventions §1). Branch create, merge, and discard happen only at their §11 confirmation points, and worktree create and remove likewise (`references/branch_rules.md`); never rebase an execution branch, never delete one whose records have not first been carried to the base branch, and never `git worktree remove` before the non-md artifacts are moved out — nor ever with `--force`.
- Allowed step status: `pending` / `in_progress` / `done` / `blocked` / `skipped`.

## Dialogue Discipline

- If AskUserQuestion or plan mode is unavailable (headless / scripted), fall back: present EXEC_PLAN as plain text and require an explicit plain-text approval before anything is written or run — still stop before heavy experiments, still confirm in plain text before any change is written back into the sub-plan.
- **Material a question is about goes in the text of the same message, above the call** — the pending-amendment batch, the EXEC_PLAN put up for approval. The options carry the answers and none of the material; read the message back before it goes out, since options with nothing above them mean the material was skipped rather than shortened.
- The sub-plan's body language follows its `language`; keep technical terms in English inside Chinese plans.
- Involve (conventions §7.7). Always asked here: the ExitPlanMode confirmation point (Step 4, including its commit, execution-branch, and worktree questions), the STOP line (Step 5), the merge confirmation point and a branch's or worktree's discard, removal, or deletion (Step 7 — conventions §11), amendment sync (Step 6 — it writes plan §2–§5), the scratch offer, and what becomes of a blocked step's edits (each stops for confirmation before a deletion — `references/agent_dispatch_spec.md`). Set to `low`: Step 0's which-leaf choice (take the first ready leaf in dependency order; a no-argument or ambiguous invocation still asks, conventions §5.2), Step 1's readiness fallback and its sizing check (take the recommendation: route back to the decomposer and stop), and Step 9's skip offer where an exploratory leaf's command is cheap (take the recommendation: start the review). Starting the review is not a question at any level — Step 9 states why. At `high`, confirm each step's dispatch (Step 5) before it goes to a subagent. Record the effective level and its source once in `EXEC_LOG.md`.
