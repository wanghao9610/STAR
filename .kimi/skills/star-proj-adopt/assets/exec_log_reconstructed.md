---
run: <run>
source_plan: (none — this run predates the plan tree)
reconstructed: <YYYY-MM-DD>
reconstructed_by: star-proj-adopt
updated: <YYYY-MM-DD>
status: done
model_id: <model id, copied verbatim from what your runtime states this session — your Kimi session reports it where available; "unrecorded" only if the session names none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
---

# Execution Log — <run> (reconstructed)

> **This is not an execution record.** It was reconstructed during project adoption on
> <YYYY-MM-DD> from artifacts already on disk, by `/skill:star-proj-adopt`. Nobody observed these steps
> running, and no step-level progress was recorded at the time. Read every line below as evidence
> found afterwards, not as something logged while it happened.

## What this run is

<!-- One or two lines, from the inventory row that selected this run. What it appears to have
     produced, in the repository's own vocabulary. -->

## Command

<!-- The invocation, only when it is recoverable verbatim from a script, a saved config, or a log
     header. Otherwise write exactly: "Not recoverable from the artifacts on disk." Never
     reconstruct a plausible command — a plausible command is a wrong command that looks right. -->

## Artifacts present

<!-- What is actually in the run directory now: checkpoints, metrics files, logs, figures. Paths
     relative to this file. Sizes or counts where they help. -->

## Metrics found

<!-- Numbers quoted verbatim from a log, a results file, or the README, each with the file it came
     from. Never computed, never rounded, never converted. Empty when none are visible. -->

| Metric | Value (verbatim) | Source |
|---|---|---|

## Not recorded

<!-- Kept deliberately, so no later reader mistakes absence for completeness: there is no step
     table, no per-step check result, and no STOP-line section, because there were no observed
     steps. What the run cost, how long it took, and whether it met any done-criterion are unknown
     unless a line above says otherwise. -->

No step table: this run was adopted, not executed. See `metds/adopt.md` §5.
