# Orchestration Spec

How this skill structures survey and migration work. Sibling spec: the executor's `agent_dispatch_spec.md` — same philosophy, adapted to surveys and migrations. Delegate a bounded area or group whenever collaboration tools are available and delegation materially helps; execute locally when they are not. When delegating, call `spawn_agent` with `agent_type: explorer` for a survey area or `agent_type: worker` for a migration group. The main agent always owns the confirmation points, verification, commits, and restoring what failed.

## Roles

- **Main agent (the architect)** — plans, asks the user at each confirmation point, partitions work, re-runs checks, commits each verified group, restores what failed.
- **Survey areas** — read-only (`survey_spec.md`); sequential locally, or delegated when bounded and independent.
- **Migration groups** — one unit of work each; writes limited to the group's files, whether executed locally or delegated.

## Partitioning migrations

1. Take only the items approved at confirmation point 2.
2. Group items so that **file ownership is disjoint**: no file may belong to two groups. Compute it rather than assume it — per candidate item, `grep -rln "<the module's dotted import path>" ${CODE_NAME}`; the union of those hits plus the item's moved files **is** that item's ownership set, and intersecting sets merge into one group. Use the dotted path, not a bare module name: over-merging costs parallelism, never correctness. Import-fix sites are exactly what a migrator discovers after dispatch, which is why this cannot wait until then — without it two parallel migrators can edit one file and per-group `git restore` stops working.
3. Order groups upstream-first along import chains. When delegation is available, independent groups may run concurrently; otherwise execute them one by one.
4. Precondition per group: its paths are clean in git (nothing unstaged/uncommitted touching them).

## Work brief (per migration group, local or delegated)

Each group's execution binds:

- **Scope** — the group's migration items verbatim, plus: "do **ONLY** these items; no opportunistic edits, no renames beyond the items, no style improvements" (AGENTS.md §3).
- **Files** — the explicit file list it owns (moves + import-fix sites).
- **Mechanics** — moves/renames plus the import/path fixes they force; nothing behavioral.
- **Runtime** — the absolute interpreter path the main agent already resolved, given verbatim; the migrator does not re-read `.env`. `python -m compileall -q` is always available (no deps needed). A missing package is a blocker it returns, never something it installs (conventions §3.5).
- **Boundary** — light validation only. A STOP-line item is **prepared and returned, never run**; never install or modify the environment (§3.5) — a missing package is a blocker it returns.
- **Return** (structured): `changed` — files, one line each; `ran` — commands + outcomes, or `none`; `check` — the group's bound check result, `pass`/`fail` + evidence; `blockers` — or `none`; `handoff` — any STOP-line command prepared for the user, or `none`.

## After a group completes

**Handoff present** → move the command into the migration record's awaiting-user area and stop for that item; do not run it.

The **main agent re-runs the verification itself** — never trust a self-reported `pass` (its own included: re-run the check fresh, not from memory):

1. `python -m compileall -q ${CODE_NAME}`; import sweep and quick tests when the env is usable.
2. **Pass** → commit `star-code-architect: migrate <ids> — <summary>`, staging only this skill's paths; update the migration record.
3. **Fail** → feed the failure back, bounded retry (≤2). Still failing → restore the group's paths (`git restore` / `git checkout -- <paths>`), mark its items `blocked` in `codearc.md` §6 with the blocker, continue with other groups.

## STOP line (this skill's version)

Never run autonomously — prepare the exact command, record it in the report, and hand it to the user:

- Environment builds involving CUDA/C++ compilation (`pip install` of ops with extensions, `conda env create` with such deps).
- Downloads over ~1 GB (weights, datasets).
- Full test suites, benchmarks, or anything that trains.

Light pure-Python installs may run only with the user's explicit in-session consent. When in doubt, treat it as heavy.
