# Plan Sync-back Rules — keep the sub-plan true to execution

When execution provably diverges from the sub-plan, the divergence is confirmed with the user and then **written back into the sub-plan** (`metds/plans/<prefix>_<slug>_plan.md`), so the plan a user rereads later matches what was actually executed. This file defines what qualifies, the delta form, the write-back procedure, and the boundary where sync-back must **not** be used.

## Material (sync) vs detail (don't)

EXEC_PLAN is *supposed* to be more concrete than the sub-plan — extra precision is **not** a divergence. Sync back only **material** deviations, judged at the sub-plan's own granularity:

- a §3 step is **added, dropped, replaced, or reordered**;
- a §2 input/dependency turns out **wrong or missing** (a different dataset / weights / module than named);
- a §4 deliverable **changes path or form**;
- the §5 done-criterion is **adjusted** (threshold, metric, or check).

Not material: finer sub-steps inside one §3 step; commands/paths the sub-plan left unspecified; implementation choices within a step's stated scope. When unsure, treat it as detail and leave the sub-plan alone.

## Delta form

One row per deviation, typed like OpenSpec deltas:

- **ADDED** — the sub-plan lacks it: `ADDED §3.5: "<new step>" — reason: <…>`
- **MODIFIED** — done differently than written: `MODIFIED §3.2: "<old>" → "<new>" — reason: <…>`
- **REMOVED** — written but will not be done: `REMOVED §3.4 — reason: <obsolete / covered by …>`

Rows found while planning go in EXEC_PLAN's "Divergences from sub-plan" table; rows that emerge during execution go in EXEC_LOG's "Pending amendments".

## Two sync points, both user-confirmed

1. **Approval gate.** Divergences known at planning time are part of the EXEC_PLAN the user approves — approving the plan approves syncing those rows. Write them back immediately after approval, before executing.
2. **Finalize.** Deviations that emerge mid-run accumulate under "Pending amendments" — never interrupt the run for them. At finalize, present the batch **once** (*sync all / select which / skip*) and write back only confirmed rows. If a run is abandoned or blocked, unsynced rows stay in the log and are re-offered at the next resume's finalize.

## Write-back procedure

For each confirmed row:

1. **Re-read the sub-plan first.** If its §2–§5 changed since the run started (user edit, re-decomposition), surface the conflict — do not overwrite blindly.
2. **Update the affected §2–§5 passages in place** to the confirmed content; the body must read as current truth, not as a patch.
3. **Append a `## Revision History` entry** — the same append-only section `star-plan-reviser` writes (create it at the end of the file if absent; never rewrite past entries). One `###` block per sync event, format-compatible with the reviser's:

   ```markdown
   ## Revision History

   ### <YYYY-MM-DD> — star-plan-executor (run: <prefix>_<slug>, approval gate | finalize)
   - MODIFIED §3.2: "<old>" → "<new>" — <reason>
   - ADDED §3.5: "<new step>" — <reason>
   ```

4. **Bump frontmatter `updated`**; touch nothing else in the frontmatter.
5. **Mark the row synced at its source** (the `synced` column in EXEC_PLAN / the checkbox in EXEC_LOG). Sync-back is idempotent: a marked row is never applied twice.

Dates come from the user/session context — never invent timestamps.

## Boundary: what never syncs

- **§1 Objective & Scope, §6 Local Risks** — an objective-level divergence means the task changed, not the tactics; that is re-decomposition (`star-plan-decomposer`), not sync-back.
- **Any parent plan** — parents belong to `star-plan-coach` / `star-plan-decomposer` (feedback reflux).
- **A §5 change that relaxes the criterion into conflict with the parent's §4 metrics / §5 kill-criteria** — that is a strategy signal: record it, surface it, route it through feedback reflux. Do not sync it.
- **Post-hoc audit and evidence-based revision** — scoring what a run actually achieved and revising a plan (including §1/§6) from that evidence is `star-plan-reviser`'s job; sync-back only keeps §2–§5 current with user-confirmed execution reality during a run.

A §5 sync-back must always quote old → new in the Revision History entry, so "what counts as done" never shifts silently.
