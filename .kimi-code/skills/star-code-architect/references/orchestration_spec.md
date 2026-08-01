# Orchestration Spec

How the main agent coordinates subagents for this skill. Sibling contract: the executor's `agent_dispatch_spec.md` — same philosophy, adapted to surveys and migrations. The main agent orchestrates, verifies, and commits; it does not edit code itself.

## Roles

- **The main agent (the architect)** — plans, asks the user at each confirmation point, partitions work, re-runs checks, commits checkpoints, rolls back failures.
- **Surveyors** — read-only `Agent` subagents (`subagent_type: explore`), one area each (`survey_spec.md`).
- **Migrators** — `Agent` subagents (`subagent_type: coder`), one per migration group, write access limited to their group's files.

## Partitioning migrations

1. Take only the items approved at confirmation point 2.
2. Group items so that **file ownership is disjoint**: no file may belong to two groups. Compute it rather than assume it — per candidate item, `grep -rln "<the module's dotted import path>" ${CODE_NAME}`; the union of those hits plus the item's moved files **is** that item's ownership set, and intersecting sets merge into one group. Use the dotted path, not a bare module name: over-merging costs parallelism, never correctness. Import-fix sites are exactly what a migrator discovers after dispatch, which is why this cannot wait until then — without it two parallel migrators can edit one file and per-group `git restore` stops working.
3. Groups with no mutual dependencies may run in parallel, **at most 3 at a time**; groups linked by import chains run serially, upstream first.
4. Precondition per group: its paths are clean in git (nothing unstaged/uncommitted touching them).

## Dispatch contract (migrator)

Give each migrator:

- **Scope** — the group's migration items verbatim, plus: "do **ONLY** these items; no opportunistic edits, no renames beyond the items, no style improvements" (AGENTS.md §3).
- **Files** — the explicit file list it owns (moves + import-fix sites).
- **Mechanics** — moves/renames plus the import/path fixes they force; nothing behavioral.
- **Runtime** — the absolute interpreter path the main agent already resolved, given verbatim; the migrator does not re-read `.env`. `python -m compileall -q` is always available (no deps needed). A missing package is a blocker it returns, never something it installs (conventions §3.5).
- **Boundary** — light validation only. A STOP-line item is **prepared and returned, never run**; never install or modify the environment (§3.5) — a missing package is a blocker it returns.
- **Return** (structured): `changed` — files, one line each; `ran` — commands + outcomes, or `none`; `check` — the group's bound check result, `pass`/`fail` + evidence; `blockers` — or `none`; `handoff` — any STOP-line command prepared for the user, or `none`.

## After a migrator returns

**Handoff present** → move the command into the migration record's awaiting-user area and stop for that item; do not run it.

The **main agent re-runs the verification itself** — never trust a self-reported `pass`:

1. `python -m compileall -q ${CODE_NAME}`; import sweep and quick tests when the env is usable.
2. **Pass** → commit `star-code-architect: migrate <ids> — <summary>`, staging only this skill's paths; update the migration record.
3. **Fail** → feed the failure back, bounded retry (≤2). Still failing → roll back the group's paths (`git restore` / `git checkout -- <paths>`), mark its items `blocked` in `codearc.md` §6 with the blocker, continue with other groups.

## STOP line (this skill's version)

Never run autonomously — prepare the exact command, record it in the report, and hand it to the user:

- Environment builds involving CUDA/C++ compilation (`pip install` of ops with extensions, `conda env create` with such deps).
- Downloads over ~1 GB (weights, datasets).
- Full test suites, benchmarks, or anything that trains.

Light pure-Python installs may run only with the user's explicit in-session consent. When in doubt, treat it as heavy.
