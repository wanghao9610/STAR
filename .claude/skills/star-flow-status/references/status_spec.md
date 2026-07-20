# Status Spec — how to read the flow and pick what's next

Everything here is derived by reading files. Write nothing.

The plan tree is the deep engine: it has ordering semantics, so it gets a graph walk. The coverage band is thin by design — presence and freshness only. The ladder picks the one recommendation across both; the self-audit line is the registry's fuse.

## What to read per file

Each `metds/plans/<prefix>_<slug>_plan.md` frontmatter may carry:

- Strategy plans (from the coach): `status:` map over the six sections, optional `finalized:`, `updated:`, and (once decomposed) `children:` + a `## Sub-plans` body index.
- Sub-plans (from the decomposer): `parent:`, `prefix:`, `level:`, `traces_to:`, `depends_on:`, a `status:` map over the six execution sections, `updated:`.
- Executed leaves (from the executor): `exec_status:` (`pending`/`in_progress`/`done`/`blocked`) and `exec_runs:` — an append-only list of `wkdrs/<run>/` dirs, newest last, whose **last entry is the current run**; earlier entries are re-runs (a second seed, a fixed bug) and stay for the record. A plan written before this field carries a single `exec_run:`; read it as a one-item list — the executor migrates it on its next write.

For a leaf with `exec_runs`, also read the current run's `wkdrs/<run>/EXEC_LOG.md`: the step-status table (count `done` / total, note any `blocked`), the "Awaiting user (STOP line)" list, and any "Strategy signal" in Notes.

For the coverage band, read the other registered artifacts by presence and by the one date field each carries — never their full bodies. Conventions §8 is the registry; the coverage table below names the exact field per row.

## Node classification

- **root** — `parent:` absent (a coach plan). Prefix is 1 digit.
- **internal** — has a non-empty `children:` list (it was decomposed further).
- **leaf** — `children:` empty or absent. Only leaves are executable.

Rebuild parent→child links from `parent:` (authoritative), not prefixes. Within a parent, order children topologically by `depends_on`; if that is missing or ambiguous, fall back to ascending prefix.

## Glyph legend (one per node)

- `✔` done — strategy node `finalized:` set; leaf `exec_status: done`.
- `◐` in progress — some sections `done`/`in_progress`, or all six `done` with `finalized:` unset (the rubric has not been run), or leaf `exec_status: in_progress` (show `k/n` steps if a log exists).
- `○` pending — nothing started (`exec_status` absent/`pending`, or all sections `pending`).
- `⊘` blocked — leaf `exec_status: blocked`, or a leaf whose `depends_on` is unmet.
- `⏸` awaiting user — leaf whose EXEC_LOG has un-checked "Awaiting user" STOP-line commands.
- `⚠` needs attention — a coarse leaf that looks too big to execute (its own §3/§5 are largely `[TBD]`) → suggest `/star-plan-decomposer`.

**One glyph per node, and lifecycle wins.** A node that qualifies for both a lifecycle glyph and `⚠` gets the lifecycle one: a finalized-then-edited root is `✔`, a done leaf with no run is `✔`. Drift belongs in the drift section, which is where the reader goes for it — never let a drift flag overwrite the state the node is actually in, or the tree stops meaning what it says.

Show, per leaf line, its `depends_on` and (if executing) `k/n` steps. Example:

```
0_open-vocab-det-seg            ◐  strategy 6/6 done, decomposed (4 children)
├ 00_mvp-3way-ablation          ✔  exec done                        deps: —
├ 01_core-method-pipeline       ◐  exec in-progress 2/5 steps        deps: 00
│ ├ 010_desc-generation         ✔  exec done                        deps: —
│ ├ 011_set-matching            ◐  exec in-progress 2/4             deps: 010
│ └ 012_det-seg-heads           ○  exec pending                     deps: 010, 011
├ 02_full-experiments           ⏸  awaiting user (1 STOP cmd)        deps: 01
└ 03_writing-submission         ○  exec pending                     deps: 02
```

The root above is `◐`, not `✔`, because its `finalized:` is unset — six `done` sections alone do not close a strategy node, the rubric still has to be run. A strategy node's glyph reports **its own** state, never its subtree's: a finalized root over a half-executed subtree is still `✔`, and the rollup is what tells you the subtree is unfinished.

## Rollup (three numbers)

1. **Strategy completeness** — across strategy plans (root/internal that came from the coach): sections `done` / (6 × number of strategy plans). Note any not `finalized:`.
2. **Decomposition coverage** — internal nodes (decomposed) vs leaves flagged `⚠` coarse (a `done`-strategy node that was never decomposed, or a leaf whose §3/§5 are mostly `[TBD]`).
3. **Execution progress** — leaves `exec_status: done` / total leaves; and summed EXEC_LOG steps `done` / total across leaves that have a run.

## Coverage band (the thin ring around the tree)

Each row fires **only when every condition in it holds**. Anything else is silence — in particular, a run that is still executing owes nothing, and a leaf that is not `done` owes nothing downstream. Report a triggered row as one line: what is owed, on which node or run, and the command that closes it. Scope: when `PLAN_NAME` was given, check only artifacts belonging to that subtree (and the runs reachable from its leaves' `exec_runs`).

| # | Signal | Fires when (all must hold) | Route |
|---|---|---|---|
| 1 | Idea not planned | a `metds/ideas/<slug>_idea.md` has `finalized:` **and** no root plan matches that slug **and** no root plan's §1 body names that idea file | `/star-plan-coach <slug>` |
| 2 | Refs missing | at least one root plan exists **and** `metds/refs/refs_index.md` does not exist | `/star-refs-reviewer` |
| 3 | Code review missing | a leaf is `exec_status: done` **and** its current run dir exists **and** that dir holds no `CODE_REVIEW_<date>.md` | `/star-code-reviewer <leaf>` |
| 4 | Code review stale | the run's newest `CODE_REVIEW_<date>.md` exists **and** its date is older than the last dated entry in that run's `EXEC_LOG.md` | `/star-code-reviewer <leaf>` |
| 5 | Analysis missing | a leaf is `exec_status: done` **and** its current run dir exists **and** that dir holds no `EXPT_ANALYSIS_<date>.md` | `/star-expt-analyst <leaf>` |
| 6 | Ledger stale | ≥2 leaves have an `EXPT_ANALYSIS_<date>.md` **and** (`metds/results.md` is absent **or** its `generated:` is older than the newest of those report dates) | `/star-expt-analyst aggregate` |
| 7 | Method docs stale | a compiled `metds/*.md` (one carrying `type:` + `generated:` + `sources:`) lists a plan in `sources:` whose recorded `updated` is older than that plan's current `updated` | `/star-metd-summarize` |
| 8 | Method docs missing | ≥1 leaf is `exec_status: done` **and** no `metds/*.md` carries `type:` + `generated:` | `/star-metd-summarize` |
| 9 | Adoption not backfilled | `metds/adopt.md` exists **and** its `backfilled:` is absent or `—` **and** ≥1 sub-plan carrying `parent:` exists | `/star-proj-adopt backfill` |

Three rows are easy to get wrong:

- **Row 4 needs dates in the log, and is silent without them.** The EXEC_LOG step table is not required to carry a date column. When the log has no dated entry to compare against, row 4 is unevaluable — report nothing rather than guessing from file mtimes. Row 3 already covers the case that matters most (no review at all).
- **Row 7 is an exact reconciliation, not an mtime guess.** `/star-metd-summarize` records, per source plan, the `updated` value that plan carried when it was read. Compare that recorded value against the plan's current `updated` — never file mtimes, which move for unrelated reasons (a checkout, a formatter).
- **Row 1 is the weakest signal here.** `/star-plan-coach` notes its seed as prose in the plan's §1 ("Seeded from `metds/ideas/<slug>_idea.md`"), not as a frontmatter field, so detection is a slug match plus a body grep for the idea's filename. An idea-seeded plan that was later renamed will read as un-planned. When row 1 is the only thing firing, say the check is heuristic.

## Next action (the one recommendation)

Walk the ladder top-down and take the **first** tier that yields a candidate. Everything else owed stays in the coverage band and is not repeated here.

1. **Awaiting user** — a leaf `⏸` with un-checked STOP-line commands. Name the command; the user is the only one who can clear it, so nothing below matters until they do.
2. **Debt on finished work** — a triggered coverage row on work that is already done, taken in order of how fast the debt compounds: backfill (row 9) → review (rows 3, 4) → analysis (row 5) → aggregate (row 6) → summarize (rows 7, 8) → refs (row 2). Row 9 leads because it is the debt that hides the others: until an adopted project's finished leaves carry `exec_status: done`, rows 3 and 5 cannot fire on them at all, and tier 3 will happily recommend executing a leaf whose work is already sitting on disk. Every coverage row except row 1 is reachable here; row 1 is tier 4 because starting a new topic is not a debt. Refs comes last despite being early in the flow: a missing survey costs positioning at write-up time, while unreviewed code costs every leaf built on top of it — so "go read the literature" must never outrank "the run you just finished was never reviewed". Debt outranks progress because it compounds: every further leaf executed on unreviewed code, or quoted from a stale ledger, widens what has to be redone. The next leaf, by contrast, does not expire.
3. **Next runnable leaf** — the **earliest leaf in execution order** satisfying all of: `exec_status` is not `done` and not `blocked`; every prefix in its `depends_on` resolves to a sibling whose `exec_status` is `done`; it is not `⚠` coarse (if it is, recommend decomposing it first instead). "Execution order" = the topological order from `depends_on`, tie-broken by ascending prefix, walked depth-first so a decomposed node's own leaves come before its later siblings. Output `→ next: /star-plan-executor <prefix or slug>`.
4. **Finalized idea with no plan** — coverage row 1. Only reached when the tree is fully done and nothing is owed; that is exactly when starting the next topic is the right move.

Give a one-line reason with the command. If no tier yields anything, state the blocker: an unmet dependency (name it), a coarse leaf needing decomposition, or an empty `metds/plans/` (route to `/star-plan-coach`, or `/star-idea-storm` when there are no ideas either).

## Drift / consistency flags (report, never fix)

- **Possible stale sub-plan** — a child whose `updated` is older than its parent's `updated` (parent changed after decomposition). Suggest `/star-plan-decomposer <parent>` to reconcile.
- **Dangling link** — a `children:` entry with no matching file, or a plan file whose `parent:` names a file that isn't there, or that its parent's `## Sub-plans` index omits.
- **Bad dependency** — a `depends_on` prefix that doesn't resolve to an existing sibling, or a cycle in the dependency graph.
- **Orphaned run** — an `exec_runs` entry pointing at a `wkdrs/<run>/` dir that doesn't exist, or an EXEC_LOG whose `source_plan` doesn't match the leaf.
- **Done with no run** — a leaf `exec_status: done` carrying no `exec_runs` (or whose run dir is gone). Coverage rows 3 and 5 require a run dir, so such a leaf silently owes nothing downstream; flag it here instead, since a leaf marked done by hand is either a bookkeeping slip or a run that was deleted.
- **Finalized then edited** — a strategy node whose `updated` is newer than its `finalized:`. The rubric was run, then the plan changed; the `✔` is no longer backed by a rubric pass. Suggest `/star-plan-coach <slug>` to re-close it.

Keep this section short and omit it entirely when nothing is flagged.

## Self-audit line (the registry's fuse)

The coverage band matches artifacts by name. If a producer skill changes what it writes, the band would quietly stop firing that row — a silent under-report nobody notices. This line flips that failure into a visible one. Count only **report-shaped** files, so that run artifacts (checkpoints, figures, raw logs) never enter:

- a `*.md` directly inside a `wkdrs/<run>/` dir whose name is not `EXEC_PLAN.md`, `EXEC_LOG.md`, `CODE_REVIEW_<date>.md`, `EXPT_ANALYSIS_<date>.md`, or `REVIEW_<date>.md`;
- a `*.md` directly inside one of the two registered non-run `wkdrs/` dirs, under a name §8 does not register there: in `wkdrs/reviews/` (the shared no-run fallback) the registered names are `code_<scope>_<date>.md` and `<prefix>_<slug>_<date>.md` (numeric prefix); in a `wkdrs/env_<name>_<date>/` dir the registered name is `ENV_REPORT.md`. Any other `wkdrs/` subdir is audited as a run dir under the previous bullet;
- a top-level `metds/*.md` whose stem is not one of `overview`, `framework`, `dataset`, `training`, `evaluation`, `codearc`, `results`, `adopt`, **and** which carries any of `type:`, `generated:`, or `sources:`. Those three together are the compiled-document fingerprint: keying on all three rather than on `type:` alone means a producer that renames its output *and* drops `type:` is still caught, while a hand-authored note in `metds/` — which carries none of them — stays silent.

Do not descend into subdirectories (`analysis/`, `raw/`, `refs/`) — those are the producers' own working space and are not registered. Report one line: `⚠ N unrecognized report file(s)` plus up to three paths. Omit the line entirely when N is 0. This is a naming mismatch, not a verdict on the files: it means the registry in conventions §8 and what is on disk have diverged, and one of them needs updating.
