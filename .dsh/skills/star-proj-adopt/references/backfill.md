# Phase `backfill`

Read where the phase resolves to `backfill` — the argument named it, or Step 0 auto-selected it from an adoption record plus a decomposed plan tree. A `survey` run never reads this file. Section 7 of `adopt_spec.md` moved here with the phase: the matching rules are below, not there.

## Step B1: Match inventory to leaves

Read `metds/adopt.md` and every leaf in `metds/plans/` (conventions §5.4). A small tree (≤ ~8 leaves) is usually simplest to read in the main agent; larger, partition the leaves into disjoint read-only collectors returning, per leaf, `{leaf, deliverable_paths, step_paths, done_criterion (quoted verbatim), exec_status, overlap, weak}` — the matching rule uses only those, never the whole plan body. The main agent re-reads §5 in full for every leaf it proposes as `done`, and keeps the many-to-many rule and the confirmation point. Propose a mapping table: inventory item → leaf → the state it argues for (`done` / `in_progress`) → the evidence. Report both misfits honestly — inventory items no leaf covers (work the plan tree forgot), and leaves nothing in the inventory reaches (genuinely new work, the normal case and not a problem).

## Step B2: Confirmation point 3 — per-leaf confirmation

The user confirms leaf by leaf via ask_user_question — one question over the numbered rows when there are several (*confirm all* / *confirm some (say the numbers)* / *confirm none*), one question each at four or fewer. An unconfirmed leaf is left exactly as it is. A leaf marked `done` with no recorded run is allowed, and noted: `/skill:star-flow-status` will flag it as done-with-no-run, the honest state.

## Step B3: Write, record, report

On confirmed leaves only, set `exec_status:` and, where a run was recorded in S5, `exec_runs:` — frontmatter fields only, nothing else in the file (Principle 6). On a confirmed match whose run was recorded, also set that reconstructed `EXEC_LOG.md`'s `source_plan:` to the leaf's filename — the user just confirmed that correspondence, and a log left saying `(none)` trips the status skill's orphaned-run flag on every adopted run. Append a dated backfill record to `metds/adopt.md` naming every leaf touched and its evidence, and set frontmatter `backfilled:` to today's date — even with no leaf confirmed, the phase ran and the record says so. The status skill's coverage row reads that field; unset, it keeps firing on a healthy project. Report, then route to `/skill:star-flow-status` for the first honest picture of the adopted project.

## The matching rules

A leaf is matched to an inventory row only on **evidence overlap**: the leaf's §4 deliverable paths or §3 steps name a path, script, or module that appears in the row's `evidence` or `run_dir`. Name similarity alone is not a match — propose it as `weak` and let the user decide.

State proposed per matched leaf:

| Inventory `state` | Proposed leaf `exec_status` |
|---|---|
| `concluded` | `done` |
| `run` | `done` when the leaf's §5 done-criterion is visibly met by the evidence; otherwise `in_progress` |
| `built` | `in_progress` |
| `abandoned` | no proposal — report it and let the user decide |

`exec_runs` is set only when that row's run was recorded in Confirmation point 2; a `done` leaf with no recorded run keeps `exec_status` alone and is flagged in the report as one `/skill:star-flow-status` will list under done-with-no-run. On a confirmed match whose run was recorded, the same pass updates the reconstructed log's `source_plan:` to the leaf's filename — the confirmation is precisely that correspondence.

Never propose `blocked`, never write `depends_on`, never reorder anything. When one inventory row matches several leaves, or several rows match one leaf, present it as-is and ask — a many-to-many match usually means the decomposition and the history disagree: information, not an error to smooth over.
