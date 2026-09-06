# Plan Write-back Rules — keep the sub-plan true to execution

When execution provably diverges from the sub-plan, the divergence is authorized by the user and then **written back into the sub-plan** (`metds/plans/<prefix>_<slug>_plan.md`), so the plan a user rereads later matches what ran. A specific, applicable instruction or decision already in the dialogue or run record is authorization; cite and reuse it rather than asking again. A generic request to implement the plan is not authorization to change its research goal, scope, or done-criterion. This file defines what qualifies, the delta form, the procedure, and where it must **not** be used.

## Material (sync) vs detail (don't)

EXEC_PLAN is *supposed* to be more concrete than the sub-plan — extra precision is **not** a divergence, with one exception (**ENRICHED**, below). Sync back only **material** deviations, judged at the sub-plan's own granularity:

- a §3 step is **added, dropped, replaced, or reordered**;
- a §2 input/dependency turns out **wrong or missing** (a different dataset / weights / module than named);
- a §4 deliverable **changes path or form**;
- the §5 done-criterion is **adjusted** (threshold, metric, or check);
- a value the sub-plan left unstated is **settled by execution** and a method document will cite it (**ENRICHED**, below).

Not material: finer sub-steps inside one §3 step; implementation choices, commands, and paths no method document cites. When unsure, treat it as detail.

## ENRICHED: values execution settled that a document will cite

The sub-plans are also the **source** the method documents compile from — `star-metd-summarize` reads plans and nothing else. A value the sub-plan left unstated, execution fixed, and a `metds/*.md` section would cite is therefore not detail: left unsynced it becomes a permanent `TBD` in that document.

In scope — the value must be one a document section cites, and the row must name that section:

| Value execution settled | Cited by |
|---|---|
| hyperparameters — lr, schedule, batch size, epochs | `training.md` §3 |
| the initialization / backbone actually used | `training.md` §2 |
| the reproduction entry point — the command and config a reader would rerun | `training.md` §5, `evaluation.md` §5 |
| key config a component's behaviour depends on | `framework.md` §2 |
| the split / preprocessing choice actually used | `dataset.md` §3 |
| the seed values actually run, where §5 states a seed or repeat policy | `training.md` §3 |

Out of scope: anything no document cites — internal flags, scratch paths, environment detail (EXEC_LOG and `freeze.txt` hold those) — and any value the plan already states (changing that is MODIFIED, not ENRICHED). **If you cannot name the document section that would cite it, it is detail.**

## Delta form

One row per deviation, typed like OpenSpec deltas:

- **ADDED** — the sub-plan lacks it: `ADDED §3.5: "<new step>" — reason: <…>`
- **MODIFIED** — done differently than written: `MODIFIED §3.2: "<old>" → "<new>" — reason: <…>`
- **REMOVED** — written but will not be done: `REMOVED §3.4 — reason: <obsolete / covered by …>`
- **ENRICHED** — the sub-plan was silent, execution settled it: `ENRICHED §3.2: lr unstated → 1e-4 — cited by: training.md §3`

Rows found while planning go in EXEC_PLAN's "Divergences from sub-plan" table; rows that emerge during execution go in EXEC_LOG's "Pending amendments".

## Two sync points, each authorized once

1. **Before execution.** Divergences known at planning time appear verbatim in EXEC_PLAN. If an existing user instruction already selects those exact changes, record its source and sync them without another question. Otherwise present them once for approval, then write back the approved rows before executing. A valid `auto=unattended` grant may take a recommended tactical row only when its substance leaves the research goal/scope, key inputs, §5 done-criterion, and approved cost unchanged; section number or an ENRICHED label never makes one of those changes routine.
2. **Finalize.** Deviations that emerge mid-run accumulate under "Pending amendments" — never interrupt the run for them. At finalize, first reuse any specific applicable decision already recorded; present the still-undecided batch **once** (*sync all / select which / skip*) and write back only authorized rows. If a run is abandoned or blocked, unsynced, undecided rows stay in the log and are offered at the next resume's finalize; a row already approved or skipped is never asked again.

## Write-back procedure

For each authorized row:

1. **Re-read the sub-plan first.** If its §2–§5 changed since the run started (user edit, re-decomposition), preserve that edit. Reconcile only non-overlapping or mechanically equivalent text when the intended combined result is unambiguous and the run already has implementation/integration authorization. If the texts compete or require a choice about user intent, research approach, scope, or acceptance, report the conflict and ask; never overwrite it blindly. The `auto=unattended` token alone is not conflict-resolution authorization.
2. **Update the affected §2–§5 passages in place** to the confirmed content; the body must read as current truth, not as a patch.
3. **Append a `## Revision History` entry** — the same append-only section `star-plan-reviser` writes (create it at the end of the file if absent; never rewrite past entries). One `###` block per sync event, format-compatible with the reviser's:

   ```markdown
   ## Revision History

   ### <YYYY-MM-DD> — star-plan-executor · <model_id> (run: <prefix>_<slug>, pre-execution | finalize)
   - MODIFIED §3.2: "<old>" → "<new>" — <reason>
   - ADDED §3.5: "<new step>" — <reason>
   - ENRICHED §3.3: lr unstated → 1e-4 — cited by: training.md §3
   ```

4. **Bump frontmatter `updated`**; touch nothing else in the frontmatter.
5. **Mark the row synced at its source** (the `synced` column in EXEC_PLAN / the checkbox in EXEC_LOG). A marked row is never applied twice.

Take the date from the system clock at write time (`date +%F`) and use that same value for the heading and frontmatter update; never infer or invent it from prose or model context.

## Boundary: what never syncs

- **§1 Objective & Scope, §6 Local Risks** — an objective-level divergence means the task changed, not the tactics; that is re-decomposition (`star-plan-decomposer`), not a write-back.
- **Any parent plan** — parents belong to `star-plan-coach` / `star-plan-decomposer` (route it back to the parent plan).
- **Any research scope, key-input, approved-cost, or §5 done-criterion change without the user's specific authorization** — implementation authority, a section number, ENRICHED, and `auto=unattended` do not make these changes routine. Where specifically authorized, record old → new in Revision History. If a §5 change conflicts with the root's §4 metrics / §5 kill-criteria, it is a plan-level finding: record it, report it, and route it back to the plan instead of syncing it.
- **A measured result** — an ENRICHED row carries a value execution *chose* (lr, backbone, split), never one it *measured*. Scores live in `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`; a plan that records its own result reads as design intent in every document compiled from it.
- **Post-hoc audit and evidence-based revision** — scoring what a run actually achieved and revising a plan (including §1/§6) from that evidence is `star-plan-reviser`'s job; the write-back only keeps §2–§5 current with authorized execution reality during a run.

A §5 write-back must always quote old → new in the Revision History entry, so "what counts as done" never shifts silently.
