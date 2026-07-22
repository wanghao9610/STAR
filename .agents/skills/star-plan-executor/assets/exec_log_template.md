---
run: <prefix>_<slug>
source_plan: <prefix>_<slug>_plan.md
task_dir: tasks/<prefix>_<slug>
updated: <YYYY-MM-DD>
status: in_progress   # in_progress / blocked / done
model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
---

# Execution Log — <prefix>_<slug>

Source of truth for this run's progress. Keep intermediate working files in `tasks/<plan-name>/`;
keep this durable record and generated run artifacts in `wkdrs/<run>/`. A fresh session should be
able to resume from this file alone: skip `done` steps, continue from the first unfinished one.

## Step status

<!-- One row per EXEC_PLAN action. `check result` is filled by the MAIN LOOP re-running or
     independently inspecting the bound check, not by a delegate's self-report. Legal status: pending / in_progress / done / blocked /
     skipped. -->

| # | Step | status | model | artifact (wkdrs/<run>/…) | check result | note |
|---|------|--------|-------|---------------------------|--------------|------|
| 1 | <…> | pending | | | | |
| 2 | <…> | pending | | | | |

## Awaiting user (STOP line)

<!-- Commands the user must run (heavy experiments). Move a step here instead of running it when it
     crosses the STOP line. Each item: the exact conda command, what it produces, and what output to
     bring back for done-criterion verification. -->

- [ ] `<conda command>` → produces `wkdrs/<run>/…`; bring back <metric/output> for the done-criterion.

## Pending amendments (not yet synced to sub-plan)

<!-- Material deviations that emerged DURING execution, in the same delta form as EXEC_PLAN's
     "Divergences from sub-plan" (references/plan_sync_rules.md). Never interrupt the run for these;
     at finalize they are batch-confirmed with the user, and confirmed rows are synced into the
     sub-plan's §2–§5 + its `## Revision History`, then checked off here. -->

- [ ] <ADDED/MODIFIED/REMOVED> §3.<n>: "<old>" → "<new>" — reason: <…>
- [ ] ENRICHED §3.<n>: <what the plan left open> → <the value execution settled> — cited by: <document §>

## Notes / decisions

<!-- Anything a resuming session needs: assumptions made, blockers hit and how they were resolved
     (material deviations from the sub-plan go under "Pending amendments" above, not here).
     If a result hit a root §5 kill-criterion, record it here as a
     **Strategy signal** and note the recommended feedback path ($star-plan-coach or
     $star-plan-decomposer) — the executor never edits the parent plan itself. -->
