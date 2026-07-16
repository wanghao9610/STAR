# Selective Delegation Contract

Delegate only when Codex collaboration tools are available and the work is bounded, independent, and materially benefits from a separate context or parallel execution. Execute locally when a step is small, sequential, tightly coupled to current edits, or likely to cause overlapping file ownership. Do not create one subagent per trivial action.

## What to give a delegate

- **Scope** — one coherent goal from EXEC_PLAN plus its bound check. State: "Do only this scope; do not continue into later actions."
- **Files** — exact files/modules the delegate may create or modify. Assign non-overlapping ownership across concurrent delegates and require surgical changes that follow `AGENTS.md`.
- **Context** — the relevant raw plan section, gap-list facts, and existing interfaces. Do not leak an intended answer when the delegate is being used for independent validation.
- **Runtime** — use `.env`'s `CONDA_HOME` / `PYTHON_HOME`, never system Python or hardcoded local paths.
- **Boundary** — light validation only. For a STOP-line action, prepare the command and return it without running it.
- **Outputs** — exact artifact paths under `wkdrs/<run>/`.

## Required return shape

- `changed` — files created or modified, one line each.
- `ran` — commands actually run and their outcomes, or `none`.
- `check` — `pass` / `fail` plus evidence.
- `blockers` — unresolved blockers, or `none`.
- `handoff` — prepared STOP-line command, or `none`.

## Main-agent responsibility

The main agent reviews the diff, resolves integration issues, and re-runs or independently inspects the bound check before checkpointing EXEC_LOG. Never treat a delegate's self-reported pass as final evidence.

- Pass → mark the action `done` with artifact and check evidence.
- Fail → retry only when a concrete correction is available, at most twice; otherwise mark `blocked` and stop.
- Handoff → record the command under `Awaiting user` and stop without running it.
