# Agent Dispatch Brief (Pi — filled locally)

One `star_subagent` dispatch per step (or coherent step-group) in EXEC_PLAN. Use `agent: "star-implementer"` for a step that changes files, `agent: "star-collector"` for read-only orientation. The main agent orchestrates and verifies; the agent does the edit/run for exactly one step — narrow, so failures localize and contexts stay short.

**Within that preference the tier still follows the step.** A step that writes mechanically — filling a template, moving a file, renaming a symbol the plan already named, running a formatter, setting a value the plan states — asks little of judgment, and where a dispatch can pick how much to spend it takes the cheap end, because the step's own check catches a mistake and this is where the tier changes the bill and not the result. A step that writes or changes logic — where the plan says what to achieve rather than what to type — takes the default. A step that reads either way is logic: a cheap agent wrong about logic costs a retry and the main agent's re-check, dearer than the tier saved.

**A coherent step-group** is at most 3 EXEC_PLAN actions that touch the same files, are meaningless apart, and share one check. Anything else is separate steps. A group is taken once, checked once, and written to EXEC_LOG as one row per member action carrying the group id — a group that did not finish leaves every row un-done, so a resume never reads it as finished. Split a group at any STOP-line boundary.

**Step order and concurrency are the main agent's call.** Orchestrate freely from EXEC_PLAN's step order and dependencies: a step that consumes an earlier step's output starts after that step's check passes; independent steps may be in flight together or run one by one, whichever the main agent judges best — no fixed cap, no imposed order beyond the dependencies themselves. Concurrent steps never share a file (conventions §6.2), and `EXEC_LOG.md` has one writer — the main agent records, and commits, each step as it verifies that step's returned result — so "stage only the files that step touched" keeps its meaning at any concurrency.

**Before a step starts**, its files are clean in git. A path already dirty when the run started is named as pre-existing and excluded from every restore below: it is not this run's to revert.

## What to give the agent

These are the terms the dispatch states, and the delegate is held to for the length of the step:

- **Scope** — the one step's goal, verbatim from EXEC_PLAN, plus the step's own check. State: "do **ONLY** this step; do not proceed to later steps."
- **What it may write** — and nothing outside it: the exact files/modules to create or modify under `${CODE_NAME}/` (from the gap list); artifacts under `wkdrs/<run>/`; intermediate working files under `tasks/<plan-name>/`, never another plan's; and, for a STOP-line step only, the prepared launch script `execs/scpts/<run>.sh` — writing it is light, running it is not (`stop_line_rules.md`). Match existing code style and touch only what this step needs (AGENTS.md §3, surgical changes).
- **Runtime** — the absolute interpreter path resolved at Step 2, used verbatim. Do not re-read `.env` per step: the working directory may not be the project root. A missing package is a blocker it returns, never something it installs (conventions §3.5).
- **Boundary** — a step may run **light validation only**. A step on the STOP line **prepares the command and hands it back, and does not run it** (`stop_line_rules.md`).

## What the agent must return (stated in the log)

- `changed` — files created/modified, one line each.
- `ran` — commands actually run + outcome, or `none`.
- `check` — the result of the step's own check: `pass` / `fail` + the evidence (test output, metric, artifact path).
- `blockers` — anything that stopped it, or `none`.
- `handoff` — any STOP-line command prepared for the user, or `none`.

## After the agent returns

**Run the step's own check as its own command**, then record the result in EXEC_LOG. Nothing counts as `pass` on the strength of having written the code — the check's output is the evidence, and a delegate's self-reported pass is a claim like any other.

- **Pass** → mark the step `done` in EXEC_LOG with the artifact path + check result; update the sub-plan's `exec_status` / `updated`.
- **Fail** → record the failure in EXEC_LOG. Restore this step's files before retrying — minus anything named pre-existing. Restore to how the tree stood when this step started, not to `HEAD`: the confirmation point may have declined per-step commits, and then earlier verified steps are uncommitted too, so resetting to `HEAD` would erase work EXEC_LOG already records as `done`. A restore never touches files outside this step's own; retry at most twice, carrying the failure into the next attempt. Still failing → the step is `blocked`: ask before restoring its half-finished edits (conventions §7.7 — it stops for confirmation before a deletion), record which way it went, name the paths either way, and stop with the log. No step ends leaving edits nobody has accounted for: a later step's commit stages "the files that step touched" and cannot tell them apart.
- **Handoff present** → move the command into EXEC_LOG "Awaiting user" and stop; do not run it.
