# Orchestration Spec

How the main loop coordinates subagents for this skill. Sibling contract: the executor's `agent_dispatch_spec.md` — same philosophy, adapted to surveys and migrations. The main loop orchestrates, verifies, and commits; it does not edit code itself.

## Roles

- **Main loop (the architect)** — plans, runs the gates, partitions work, re-runs checks, commits checkpoints, rolls back failures.
- **Surveyors** — read-only lanes (`survey_spec.md`).
- **Migrators** — one per migration group, write access limited to their group's files.

## Partitioning migrations

1. Take only Gate-2-approved items.
2. Group items so that **file ownership is disjoint**: no file may belong to two groups (count both the moved files and every file whose imports the move touches). When two items contend for a file, merge them into one group.
3. Groups with no mutual dependencies may run in parallel, **at most 3 at a time**; groups linked by import chains run serially, upstream first.
4. Precondition per group: its paths are clean in git (nothing unstaged/uncommitted touching them).

## Dispatch contract (migrator)

Give each migrator:

- **Scope** — the group's migration items verbatim, plus: "do **ONLY** these items; no opportunistic edits, no renames beyond the items, no style improvements" (CLAUDE.md §3).
- **Files** — the explicit file list it owns (moves + import-fix sites).
- **Mechanics** — moves/renames plus the import/path fixes they force; nothing behavioral.
- **Runtime** — checks run through the `.env` conda env (`CONDA_HOME`/`PYTHON_HOME`); `python -m compileall -q` is always available (no deps needed).
- **Return** (structured): `changed` — files, one line each; `ran` — commands + outcomes, or `none`; `check` — the group's bound check result, `pass`/`fail` + evidence; `blockers` — or `none`.

## After a migrator returns

The **main loop re-runs the verification itself** — never trust a self-reported `pass`:

1. `python -m compileall -q ${CODE_NAME}`; import sweep and quick tests when the env is usable.
2. **Pass** → commit `star-code-architect: migrate <ids> — <summary>`, staging only this skill's paths; update the migration record.
3. **Fail** → feed the failure back, bounded retry (≤2). Still failing → roll back the group's paths (`git restore` / `git checkout -- <paths>`), mark its items `blocked` in `codearc.md` §6 with the blocker, continue with other groups.

## STOP line (this skill's version)

Never run autonomously — prepare the exact command, record it in the report, and hand it to the user:

- Environment builds involving CUDA/C++ compilation (`pip install` of ops with extensions, `conda env create` with such deps).
- Downloads over ~1 GB (weights, datasets).
- Full test suites, benchmarks, or anything that trains.

Light pure-Python installs may run only with the user's explicit in-session consent. When in doubt, treat it as heavy.
