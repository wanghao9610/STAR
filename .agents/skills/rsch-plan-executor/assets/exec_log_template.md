---
run: <prefix>_<slug>
source_plan: <prefix>_<slug>_plan.md
updated: <YYYY-MM-DD>
status: in_progress   # in_progress / blocked / done
---

# Execution Log — <prefix>_<slug>

Source of truth for this run's progress. A fresh session should be able to resume from this file
alone: skip `done` steps, continue from the first unfinished one.

## Step status

<!-- One row per EXEC_PLAN action. `check result` is filled by the MAIN LOOP re-running or
     independently inspecting the bound check, not by a delegate's self-report. Legal status: pending / in_progress / done / blocked /
     skipped. -->

| # | Step | status | artifact (wkdrs/<run>/…) | check result | note |
|---|------|--------|---------------------------|--------------|------|
| 1 | <…> | pending | | | |
| 2 | <…> | pending | | | |

## Awaiting user (STOP line)

<!-- Commands the user must run (heavy experiments). Move a step here instead of running it when it
     crosses the STOP line. Each item: the exact conda command, what it produces, and what output to
     bring back for done-criterion verification. -->

- [ ] `<conda command>` → produces `wkdrs/<run>/…`; bring back <metric/output> for the done-criterion.

## Notes / decisions

<!-- Anything a resuming session needs: assumptions made, deviations from EXEC_PLAN, blockers hit
     and how they were resolved. If a result hit a parent §5 kill-criterion, record it here as a
     **Strategy signal** and note the recommended feedback path ($rsch-plan-coach or
     $rsch-plan-decomposer) — the executor never edits the parent plan itself. -->
