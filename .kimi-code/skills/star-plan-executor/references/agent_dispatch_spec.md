# Agent Dispatch Contract

One subagent per step (or coherent step-group) in EXEC_PLAN. The main agent orchestrates and verifies; the agent does the edit/run for exactly one step. Keep agents narrow so failures localize and contexts stay short.

**A coherent step-group** is at most 3 EXEC_PLAN actions that touch the same files, are meaningless apart, and share one check. Anything else is separate steps. A group is dispatched once, checked once, and written to EXEC_LOG as one row per member action carrying the group id — a group that did not return leaves every member row un-done, so a resume never reads a half-finished group as finished. Split a group at any STOP-line boundary.

**Dispatch is serial.** Never run two implementing agents at once: they would race on the single `EXEC_LOG.md`, and "stage only the files that step touched" has no meaning with two writers. `star-code-architect`'s ≤3-in-parallel rule is for independent migration groups; an ordered plan is not one — do not import it.

**Before dispatch**, this step's files are clean in git. A path already dirty when the run started is named as pre-existing and excluded from every restore below: it is not this run's to revert.

## What to give the agent

- **Scope** — the one step's goal, verbatim from EXEC_PLAN, plus the step's own check. State: "do **ONLY** this step; do not proceed to later steps."
- **Write surface** — and nothing outside it: the exact files/modules to create or modify under `${CODE_NAME}/` (from the gap list); artifacts under `wkdrs/<run>/`; intermediate working files under `tasks/<plan-name>/`, never another plan's; and, for a STOP-line step only, the prepared launch script `execs/scpts/<run>.sh` — writing it is light, running it is not (`stop_line_rules.md`). Match existing code style and touch only what this step needs (AGENTS.md §3, surgical changes).
- **Runtime** — the absolute interpreter path the main agent already resolved, given verbatim. The agent does not re-read `.env`: its working directory may not be the project root. A missing package is a blocker it returns, never something it installs (conventions §3.5).
- **Boundary** — it may run **light validation only**. If its step is on the STOP line, it must **prepare the command and return it, NOT run it** (`stop_line_rules.md`).

## What the agent must return (structured)

- `changed` — files created/modified, one line each.
- `ran` — commands actually run + outcome, or `none`.
- `check` — the result of the step's own check: `pass` / `fail` + the evidence (test output, metric, artifact path).
- `blockers` — anything that stopped it, or `none`.
- `handoff` — any STOP-line command prepared for the user, or `none`.

## After the agent returns

The **main agent — not the agent — re-runs the step's own check** to confirm, then checkpoints to EXEC_LOG. Do not trust a self-reported `pass` without the evidence.

- **Pass** → mark the step `done` in EXEC_LOG with the artifact path + check result; update the sub-plan's `exec_status` / `updated`.
- **Fail** → record the failure in EXEC_LOG. Restore this step's files before retrying — minus anything named pre-existing — so the next attempt starts from a known tree. Restore to how the tree stood when this step was dispatched, not to `HEAD`: the gate may have declined per-step checkpoint commits, and then earlier verified steps are uncommitted too, so resetting to `HEAD` would erase work EXEC_LOG already records as `done`. A restore never touches files outside this step's own; retry at most twice, with the failure fed back into the next dispatch. Still failing → the step is `blocked`, and its half-finished edits may still be worth something: ask before restoring them (conventions §7.7 — it gates a deletion), record which way it went, name the paths either way, and stop with the log. No step ends leaving edits nobody has accounted for: a later step's commit stages "the files that step touched" and cannot tell them apart.
- **Handoff present** → move the command into EXEC_LOG "Awaiting user" and stop; do not run it.
