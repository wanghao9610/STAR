---
title: <Sub-topic> Executable Plan
run: <prefix>_<slug>                 # = the wkdrs/<run>/ directory name
source_plan: <prefix>_<slug>_plan.md # the leaf sub-plan under metds/plans/ this executes
task_dir: tasks/<prefix>_<slug>      # plan-specific execution-process intermediate files
code_name: <CODE_NAME>               # resolved from .env
created: <YYYY-MM-DD>
approved: <YYYY-MM-DD>               # date the user approved this via ExitPlanMode
done_criterion: "<the sub-plan §5 check this run must satisfy, with its threshold>"
model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
---

# <Sub-topic> Executable Plan

## Orientation (current state vs required)

<!-- The gap list from Step 2. For each area the plan touches, what exists in ${CODE_NAME}/ today
     vs what must be created/changed. State "greenfield" if ${CODE_NAME}/ is empty. Point at real
     paths, not guesses. -->

## Divergences from sub-plan

<!-- Material deltas between this EXEC_PLAN and the sub-plan's §2–§5 (references/plan_sync_rules.md):
     steps added/dropped/replaced/reordered, §2 deps wrong, §4 paths changed, §5 criterion adjusted,
     plus ENRICHED rows — values the sub-plan left unstated that a method document will cite, whose
     reason names that section. Other extra concreteness is NOT a divergence. Approving this plan
     approves syncing these rows back into the sub-plan; mark `synced` once written back. Write
     "None" if faithful. -->

| # | type | sub-plan says (§) | approved change | reason | synced |
|---|------|-------------------|-----------------|--------|--------|
| D1 | <ADDED/MODIFIED/REMOVED> | §3.<n> <…> | <…> | <…> | ☐ |
| D2 | ENRICHED | §3.<n> unstated | <the value execution settled> | cited by: training.md §3 | ☐ |

## Actions

<!-- Ordered. Each action binds a check. `run by` = `agent` (executes here) or `stop → user`
     (agent prepares the command, user runs it — see STOP line). Commands go through the .env conda
     env; artifacts land under wkdrs/<run>/. -->

| # | Action | Files / module (${CODE_NAME}/…) | Command (via conda) | Artifact (wkdrs/<run>/…) | Check | run by |
|---|--------|----------------------------------|----------------------|--------------------------|-------|--------|
| 1 | <create/modify …> | <path> | — | — | <import / smoke test> | agent |
| 2 | <…> | <path> | <cmd> | <path> | <what proves it> | agent |
| N | <heavy experiment> | — | <prepared cmd> | <path> | §5 done-criterion | stop → user |

## STOP line

<!-- Which actions cross the STOP line and why (long/multi-GPU training, full-dataset eval, costly
     API). For each: the exact command through the conda env (via execs/run.sh where one exists),
     what it produces and where, and what output the user should bring back so the done-criterion can
     be verified. A reusable launch script may be written to execs/scpts/<run>.sh (writing it is fine;
     running it stays with the user). -->

## Done-criterion

<!-- Restate the sub-plan §5 check that ends this run, with its threshold, tied back to the root's
     §4 metrics / §5 kill-criteria where relevant. This is what Step 6 verifies. -->
