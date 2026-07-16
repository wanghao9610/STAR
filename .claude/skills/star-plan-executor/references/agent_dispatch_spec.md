# Agent Dispatch Contract

One subagent per step (or coherent step-group) in EXEC_PLAN. The main loop orchestrates and verifies; the agent does the edit/run for exactly one step. Keep agents narrow so failures localize and contexts stay short.

## What to give the agent

- **Scope** — the one step's goal, verbatim from EXEC_PLAN, plus its bound check. State: "do **ONLY** this step; do not proceed to later steps."
- **Files** — the exact files/modules to create or modify under `${CODE_NAME}/` (from the gap list). Tell it to match existing code style and touch only what this step needs (CLAUDE.md §3, surgical changes).
- **Runtime** — run through the `.env` conda env (`CONDA_HOME` / `PYTHON_HOME`); never system python, never hardcoded local paths (CLAUDE.md §6).
- **Boundary** — it may run **light validation only**. If its step is on the STOP line, it must **prepare the command and return it, NOT run it** (`stop_line_rules.md`).
- **Outputs** — where artifacts go (`wkdrs/<run>/…`).

## What the agent must return (structured)

- `changed` — files created/modified, one line each.
- `ran` — commands actually run + outcome, or `none`.
- `check` — the bound check's result: `pass` / `fail` + the evidence (test output, metric, artifact path).
- `blockers` — anything that stopped it, or `none`.
- `handoff` — any STOP-line command prepared for the user, or `none`.

## After the agent returns

The **main loop — not the agent — re-runs the bound check** to confirm, then checkpoints to EXEC_LOG. Do not trust a self-reported `pass` without the evidence.

- **Pass** → mark the step `done` in EXEC_LOG with the artifact path + check result; update the sub-plan's `exec_status` / `updated`.
- **Fail** → bounded retry (≤2) with the failure fed back into the next dispatch. Still failing → mark the step `blocked`, record the blocker, and stop with the log.
- **Handoff present** → move the command into EXEC_LOG "Awaiting user" and stop; do not run it.
