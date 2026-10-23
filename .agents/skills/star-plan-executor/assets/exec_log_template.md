---
run: <prefix>_<slug>
source_plan: <prefix>_<slug>_plan.md
task_dir: tasks/<prefix>_<slug>
updated: <YYYY-MM-DD>
status: in_progress   # in_progress / blocked / done
involve: <level (source)>   # effective level, conventions §7.7 — e.g. low (invocation); medium when never set
branch: <run name | none>   # execution branch (conventions §11); mirrors EXEC_PLAN
worktree: <absolute path | none>   # the tree housing this run (conventions §11.7–9); mirrors EXEC_PLAN; omit the line when none
merged: <pending | YYYY-MM-DD @<short-sha> | discarded YYYY-MM-DD>   # set at the merge/discard confirmation point; omit the line when branch is none
code_commit: <short-sha of ${CODE_NAME} when the first STOP-line command was handed back | unrecorded>   # what a metric from this run can be regenerated at; `unrecorded` when the tree was dirty or the sha was not taken
model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none — docs/mds/star-workflow/research-workflow-conventions.md §8>
model_trail:                    # append-only: one entry per write session, newest last, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
---

# Execution Log — <prefix>_<slug>

Source of truth for this run's progress. Keep intermediate working files in `tasks/<plan-name>/`;
keep this durable record and generated run artifacts in `wkdrs/<run>/`. A fresh session should be
able to resume from this file alone: skip `done` steps, continue from the first unfinished one.

## Step status

<!-- Use the existing note column to name each action's work unit, its pending final check or commit,
     and identify committed actions in the commit message. Record action results immediately, before committing.
     A failed later action preserves earlier verified, uncommitted changes and their evidence. -->

<!-- One row per EXEC_PLAN action. `check result` is filled by the main agent re-running or
     independently inspecting the action's own check, not by a delegate's self-report. `model` is the
     model the row's action ran on: the delegate's own reported id when its return carries one; for an
     action this session ran itself, this session's id; otherwise `unrecorded` — a model requested at
     dispatch is not a reported id (conventions §8). Allowed status: pending / in_progress / done /
     blocked / skipped. -->

| # | Step | status | model | artifact (wkdrs/<run>/…) | check result | note |
|---|------|--------|-------|---------------------------|--------------|------|
| 1 | <…> | pending | | | | |
| 2 | <…> | pending | | | | |

## Awaiting user (STOP line)

<!-- Commands the user must run (heavy experiments). Move a step here instead of running it when it
     crosses the STOP line. Each item: the exact command — `bash execs/scpts/<run>.sh`, the launch
     script the launch guard recognizes (references/stop_line_rules.md) — what it produces, and what
     output to bring back for done-criterion verification. Bind launch argv, code/review versions,
     attempt ID, PID, raw log and expected outputs through scripts/launch_state.sh; on return verify
     the matching exit and outputs, then acknowledge collection into this existing log before removing
     markers (references/resume_rules.md). The helper appends a star-launch-receipt with that identity,
     exit code and verification evidence; reuse it after interruption instead of collecting twice.
     Tick the item (`- [x]`) only after verified success and durable acknowledgment, naming its receipt
     and outputs. A nonzero exit is a failed result, not completion; legacy unknown provenance stays
     explicit and its evidence is retained. An un-ticked item still reads as awaiting successful output. -->

- [ ] `bash execs/scpts/<run>.sh` → produces `wkdrs/<run>/…`; bring back <metric/output> for the done-criterion.

## Cost

<!-- One row per command that crossed the STOP line. Expected comes from EXEC_PLAN's STOP-line
     section; actual is filled in when the user brings the run back. This is the only place the root
     plan's §4 compute budget is reconciled: the budget is written once, the actual accrues here.
     If the actual cannot be recovered, write `unrecorded` — an empty cell reads as free. -->

| Action | Expected | Actual | Basis |
|--------|----------|--------|-------|
| <#N heavy run> | <GPU×hours / calls and spend> | <same units, or `unrecorded`> | <log line / invoice / wall-clock> |

## Pending amendments (not yet synced to sub-plan)

<!-- Material deviations that emerged DURING execution, in the same delta form as EXEC_PLAN's
     "Divergences from sub-plan" (references/plan_sync_rules.md). Never interrupt the run for these;
     at finalize they are batch-confirmed with the user, and confirmed rows are synced into the
     sub-plan's §2–§5 + its `## Revision History`, then checked off here. -->

- [ ] <ADDED/MODIFIED/REMOVED> §3.<n>: "<old>" → "<new>" — reason: <…>
- [ ] ENRICHED §3.<n>: <what the plan left open> → <the value execution settled> — cited by: <document §>

## Notes / decisions

<!-- Only verified engineering-only work may record `analysis: not applicable`, with its concrete
     reason and check evidence, followed by an analysis-exemption binding from source_state.sh.
     If the actual run needs analysis, record `analysis: required` and clear the obsolete binding.
     This never waives code review, completion checks or launch authority. -->

<!-- Assign a run-scoped PF number when a finding is recorded; never reuse or retarget it. A changed claim gets a new id citing the old one. The reviser report owns the resolved/deferred decision (conventions §8); a later report date does not settle this entry. Omit the example when there is no finding. -->

- **Plan-level finding** `<run>:PF1` — <claim>; evidence: `<path[:line]>`.


<!-- Anything a resuming session needs: assumptions made, blockers hit and how they were resolved, and for a step left `blocked`, what became of its edits — restored, or kept by an explicit decision, with the paths named either way
     (material deviations from the sub-plan go under "Pending amendments" above, not here).
     If a result hit a root §5 kill-criterion, record it here as a
     **Plan-level finding** and note the recommended feedback path (star-plan-reviser first;
     star-plan-coach or star-plan-decomposer where the strategy or the split must change) — the
     executor never edits the parent plan itself. -->
