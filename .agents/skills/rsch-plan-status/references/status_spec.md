# Status Spec — how to read the tree and pick what's next

Everything here is derived by reading files. Write nothing.

## What to read per file

Each `metds/plans/<prefix>_<slug>_plan.md` frontmatter may carry:

- Strategy plans (from the coach): `status:` map over the six sections, optional `finalized:`, `updated:`, and (once decomposed) `children:` + a `## Sub-plans` body index.
- Sub-plans (from the decomposer): `parent:`, `prefix:`, `level:`, `traces_to:`, `depends_on:`, a `status:` map over the six execution sections, `updated:`.
- Executed leaves (from the executor): `exec_status:` (`pending`/`in_progress`/`done`/`blocked`) and `exec_run:` (a `wkdrs/<run>/` dir).

For a leaf with `exec_run`, also read `wkdrs/<run>/EXEC_LOG.md`: the step-status table (count `done` / total, note any `blocked`), the "Awaiting user (STOP line)" list, and any "Strategy signal" in Notes.

## Node classification

- **root** — `parent:` absent (a coach plan). Prefix is 1 digit.
- **internal** — has a non-empty `children:` list (it was decomposed further).
- **leaf** — `children:` empty or absent. Only leaves are executable.

Rebuild parent→child links from `parent:` (authoritative), not prefixes. Within a parent, order children topologically by `depends_on`; if that is missing or ambiguous, fall back to ascending prefix.

## Glyph legend (one per node)

- `✔` done — strategy node `finalized:` set, or all six sections `done`; leaf `exec_status: done`.
- `◐` in progress — some sections `done`/`in_progress`, or leaf `exec_status: in_progress` (show `k/n` steps if a log exists).
- `○` pending — nothing started (`exec_status` absent/`pending`, or all sections `pending`).
- `⊘` blocked — leaf `exec_status: blocked`, or a leaf whose `depends_on` is unmet.
- `⏸` awaiting user — leaf whose EXEC_LOG has un-checked "Awaiting user" STOP-line commands.
- `⚠` needs attention — a coarse leaf that looks too big to execute (its own §3/§5 are largely `[TBD]`) → suggest `$rsch-plan-decomposer`; or a drift flag (see below).

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

## Rollup (three numbers)

1. **Strategy completeness** — across strategy plans (root/internal that came from the coach): sections `done` / (6 × number of strategy plans). Note any not `finalized:`.
2. **Decomposition coverage** — internal nodes (decomposed) vs leaves flagged `⚠` coarse (a `done`-strategy node that was never decomposed, or a leaf whose §3/§5 are mostly `[TBD]`).
3. **Execution progress** — leaves `exec_status: done` / total leaves; and summed EXEC_LOG steps `done` / total across leaves that have a run.

## Next runnable leaf (the one recommendation)

Pick the **earliest leaf in execution order** satisfying all of:

- `exec_status` is not `done` and not `blocked`;
- every prefix in its `depends_on` resolves to a sibling whose `exec_status` is `done`;
- it is not `⚠` coarse (if it is, recommend decomposing it first instead).

"Execution order" = the topological order from `depends_on`, tie-broken by ascending prefix, walked depth-first so a decomposed node's own leaves come before its later siblings. Output: `→ next: $rsch-plan-executor <prefix or slug>` + a one-line reason. If nothing qualifies, state the blocker: an unmet dependency (name it), a coarse leaf needing decomposition, or a leaf `⏸` awaiting a user STOP-line command (name the command).

## Drift / consistency flags (report, never fix)

- **Possible stale sub-plan** — a child whose `updated` is older than its parent's `updated` (parent changed after decomposition). Suggest `$rsch-plan-decomposer <parent>` to reconcile.
- **Dangling link** — a `children:` entry with no matching file, or a plan file whose `parent:` names a file that isn't there, or that its parent's `## Sub-plans` index omits.
- **Bad dependency** — a `depends_on` prefix that doesn't resolve to an existing sibling, or a cycle in the dependency graph.
- **Orphaned run** — an `exec_run` pointing at a `wkdrs/<run>/` dir that doesn't exist, or an EXEC_LOG whose `source_plan` doesn't match the leaf.

Keep this section short and omit it entirely when nothing is flagged.
