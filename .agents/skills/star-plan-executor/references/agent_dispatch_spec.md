# Selective Delegation Brief

Delegate whenever Codex collaboration tools are available and the work is bounded, independent, and materially benefits from a separate context or parallel execution. When delegating, call `spawn_agent` with `agent_type: worker`; use `agent_type: explorer` only for a read-only orientation scope. Execute locally when a step is small, sequential, tightly coupled to current edits, or likely to cause overlapping file ownership. Do not create one subagent per trivial action.

**A coherent scope** is at most 3 EXEC_PLAN actions that touch the same files, are meaningless apart, and share one check. Anything else is separate actions. A scope is delegated once, checked once, and written to EXEC_LOG as one row per member action carrying the scope id — a scope that did not return leaves every member row un-done, so a resume never reads a half-finished scope as finished. Split at any STOP-line boundary.

**Delegation here is serial.** Never run two file-writing delegates at once: they would race on the single `EXEC_LOG.md`, and "stage only the files that action touched" has no meaning with two writers. `star-code-architect`'s parallel migration groups are independent of one another; an ordered plan is not — do not import that rule.

**Before delegating**, this action's files are clean in git. A path already dirty when the run started is named as pre-existing and excluded from every restore below: it is not this run's to revert.

## What to give a delegate

- **Scope** — one coherent goal from EXEC_PLAN plus the action's own check. State: "Do only this scope; do not continue into later actions."
- **What it may write** — and nothing outside it: the exact files/modules the delegate may create or modify under `${CODE_NAME}/`; artifacts under `wkdrs/<run>/`; intermediate working files under `tasks/<plan-name>/`, never another plan's; and, for a STOP-line action only, the prepared launch script `execs/scpts/<run>.sh` — writing it is light, running it is not. Require surgical changes that follow `AGENTS.md`.
- **Context** — the relevant raw plan section, gap-list facts, and existing interfaces. Do not leak an intended answer when the delegate is being used for independent validation.
- **Runtime** — the absolute interpreter path already resolved by the main agent, given verbatim. The delegate does not re-read `.env`. A missing package is a blocker it returns, never something it installs (conventions §3.5).
- **Boundary** — light validation only. For a STOP-line action, prepare the command and return it without running it.

## Required return shape

- `changed` — files created or modified, one line each.
- `ran` — commands actually run and their outcomes, or `none`.
- `check` — `pass` / `fail` plus evidence.
- `blockers` — unresolved blockers, or `none`.
- `handoff` — prepared STOP-line command, or `none`.

## Main-agent responsibility

The main agent reviews the diff, resolves integration issues, and re-runs or independently inspects the action's own check before recording the result in EXEC_LOG. Never treat a delegate's self-reported pass as final evidence.

- Pass → mark the action `done` with artifact and check evidence.
- Fail → record the failure in EXEC_LOG, and restore this action's files before retrying — minus anything named pre-existing — so the next attempt starts from a known tree. Restore to how the tree stood when this action began, not to `HEAD`: per-action commits may have been declined, and then earlier verified actions are uncommitted too, so resetting to `HEAD` would erase work EXEC_LOG already records as `done`. A restore never touches files outside this action's own. Retry only when a concrete correction is available, at most twice. Otherwise the action is `blocked`, and its half-finished edits may still be worth something: ask before restoring them (conventions §7.7 — it stops for confirmation before a deletion), record which way it went, name the paths either way, and stop. No action ends leaving edits nobody has accounted for.
- Handoff → record the command under `Awaiting user` and stop without running it.
