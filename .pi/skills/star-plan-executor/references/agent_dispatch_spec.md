# Agent Dispatch Contract (Pi — filled locally)

One contract per step (or coherent step-group) in EXEC_PLAN. Pi ships no sub-agents, so conventions §6.1 governs the whole of this file: the contract still gets written out, and this agent then fills it itself, one step at a time, against the return format below. Writing it out is not ceremony — it is the only thing keeping a step from widening once there is nobody to hand a scope to. Keep each step narrow so failures localize and the context stays short.

**A coherent step-group** is at most 3 EXEC_PLAN actions that touch the same files, are meaningless apart, and share one check. Anything else is separate steps. A group is taken once, checked once, and written to EXEC_LOG as one row per member action carrying the group id — a group that did not finish leaves every member row un-done, so a resume never reads a half-finished group as finished. Split a group at any STOP-line boundary.

**Steps are serial.** Never leave two steps in flight: they would race on the single `EXEC_LOG.md`, and "stage only the files that step touched" has no meaning with two writers. Nothing here overlaps steps, and with no delegation there is no parallel rule anywhere in STAR to import — `star-code-architect`'s migration groups run in sequence on this host too.

**Before a step starts**, its files are clean in git. A path already dirty when the run started is named as pre-existing and excluded from every restore below: it is not this run's to revert.

## What to give the agent

With no delegate to hand them to, these are the terms you write down and then hold yourself to for the length of the step:

- **Scope** — the one step's goal, verbatim from EXEC_PLAN, plus the step's own check. State: "do **ONLY** this step; do not proceed to later steps."
- **Write surface** — and nothing outside it: the exact files/modules to create or modify under `${CODE_NAME}/` (from the gap list); artifacts under `wkdrs/<run>/`; intermediate working files under `tasks/<plan-name>/`, never another plan's; and, for a STOP-line step only, the prepared launch script `execs/scpts/<run>.sh` — writing it is light, running it is not (`stop_line_rules.md`). Match existing code style and touch only what this step needs (AGENTS.md §3, surgical changes).
- **Runtime** — the absolute interpreter path resolved at Step 2, used verbatim. Do not re-read `.env` per step: the working directory may not be the project root. A missing package is a blocker it returns, never something it installs (conventions §3.5).
- **Boundary** — a step may run **light validation only**. A step on the STOP line **prepares the command and hands it back, and does not run it** (`stop_line_rules.md`).

## What the agent must return (stated in the log)

- `changed` — files created/modified, one line each.
- `ran` — commands actually run + outcome, or `none`.
- `check` — the result of the step's own check: `pass` / `fail` + the evidence (test output, metric, artifact path).
- `blockers` — anything that stopped it, or `none`.
- `handoff` — any STOP-line command prepared for the user, or `none`.

## After the agent returns

**Run the step's own check as its own command**, read its output, then checkpoint to EXEC_LOG. Nothing counts as `pass` on the strength of having written the code — the check's output is the evidence, and with no delegate to distrust the temptation is simply to skip it.

- **Pass** → mark the step `done` in EXEC_LOG with the artifact path + check result; update the sub-plan's `exec_status` / `updated`.
- **Fail** → record the failure in EXEC_LOG. Restore this step's files before retrying — minus anything named pre-existing — so the next attempt starts from a known tree. Restore to how the tree stood when this step started, not to `HEAD`: the confirmation point may have declined per-step checkpoint commits, and then earlier verified steps are uncommitted too, so resetting to `HEAD` would erase work EXEC_LOG already records as `done`. A restore never touches files outside this step's own; retry at most twice, carrying the failure into the next attempt. Still failing → the step is `blocked`, and its half-finished edits may still be worth something: ask before restoring them (conventions §7.7 — it stops for confirmation before a deletion), record which way it went, name the paths either way, and stop with the log. No step ends leaving edits nobody has accounted for: a later step's commit stages "the files that step touched" and cannot tell them apart.
- **Handoff present** → move the command into EXEC_LOG "Awaiting user" and stop; do not run it.
