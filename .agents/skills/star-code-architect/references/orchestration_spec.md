# Orchestration Spec

How this skill structures survey and migration work. Sibling contract: the executor's `agent_dispatch_spec.md` — same philosophy, adapted to surveys and migrations. Execute locally by default; delegate a bounded lane or group only when collaboration tools are available and delegation materially helps. The main agent always owns gates, verification, commits, and rollback.

## Roles

- **Main agent (the architect)** — plans, runs the gates, partitions work, re-runs checks, commits checkpoints, rolls back failures.
- **Survey lanes** — read-only (`survey_spec.md`); sequential locally, or delegated when bounded and independent.
- **Migration groups** — one unit of work each; writes limited to the group's files, whether executed locally or delegated.

## Partitioning migrations

1. Take only Gate-2-approved items.
2. Group items so that **file ownership is disjoint**: no file may belong to two groups (count both the moved files and every file whose imports the move touches). When two items contend for a file, merge them into one group.
3. Order groups upstream-first along import chains. When delegation is available, independent groups may run concurrently, **at most 3 at a time**; otherwise execute them one by one.
4. Precondition per group: its paths are clean in git (nothing unstaged/uncommitted touching them).

## Work contract (per migration group, local or delegated)

Each group's execution binds:

- **Scope** — the group's migration items verbatim, plus: "do **ONLY** these items; no opportunistic edits, no renames beyond the items, no style improvements" (AGENTS.md §3).
- **Files** — the explicit file list it owns (moves + import-fix sites).
- **Mechanics** — moves/renames plus the import/path fixes they force; nothing behavioral.
- **Runtime** — checks run through the `.env` conda env (`CONDA_HOME`/`PYTHON_HOME`); `python -m compileall -q` is always available (no deps needed).
- **Return** (structured): `changed` — files, one line each; `ran` — commands + outcomes, or `none`; `check` — the group's bound check result, `pass`/`fail` + evidence; `blockers` — or `none`.

## After a group completes

The **main agent re-runs the verification itself** — never trust a self-reported `pass` (its own included: re-run the check fresh, not from memory):

1. `python -m compileall -q ${CODE_NAME}`; import sweep and quick tests when the env is usable.
2. **Pass** → commit `star-code-architect: migrate <ids> — <summary>`, staging only this skill's paths; update the migration record.
3. **Fail** → feed the failure back, bounded retry (≤2). Still failing → roll back the group's paths (`git restore` / `git checkout -- <paths>`), mark its items `blocked` in `codearc.md` §6 with the blocker, continue with other groups.

## STOP line (this skill's version)

Never run autonomously — prepare the exact command, record it in the report, and hand it to the user:

- Environment builds involving CUDA/C++ compilation (`pip install` of ops with extensions, `conda env create` with such deps).
- Downloads over ~1 GB (weights, datasets).
- Full test suites, benchmarks, or anything that trains.

Light pure-Python installs may run only with the user's explicit in-session consent. When in doubt, treat it as heavy.
