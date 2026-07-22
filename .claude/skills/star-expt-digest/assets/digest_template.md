---
type: digest
language: en
generated: <YYYY-MM-DD>
mode: <incremental|window|plan|all>
scope: <whole forest | family of <prefix>_<slug>>
covers:
  from: <YYYY-MM-DD or "—">
  through: <YYYY-MM-DD>
previous: <EXPT_DIGEST_<YYYY-MM-DD>.md or "—">
model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none>
sources:
  - run: <prefix>_<slug>
    report: <EXPT_ANALYSIS_<YYYY-MM-DD>.md or "none">
    tier: <report-backed|provisional>
    verdict: <met|partially met|not met|inconclusive|invalid|—>
---

# Experiment Digest — <period>

<!-- Written by /star-expt-digest. This is a PROGRESS RECORD, not a results table. Numbers in §3 are
     copied from EXPT_ANALYSIS reports with their provenance and were NOT re-verified here; numbers in
     §4 are provisional and unverified. The verified ledger a paper is written from is metds/results.md
     (/star-expt-analyst aggregate); the protocol those numbers were measured under is
     metds/evaluation.md. Never quote a number from this file into a paper. -->

## 1. Period & Scope

<!-- Two or three lines: the window and how it was set (resumed from the previous digest / explicit
     window / plan family), the scope, how many runs fell in it, and the report-backed vs provisional
     split. In plan mode, name the ancestors read for claim context. If there is no previous digest,
     say the series starts here. If the period is empty, say so with the newest run date and the
     watermark, write "None" under every section below, and stop. -->

## 2. Headline — what was learned

<!-- Three to five sentences, report-backed evidence only (references/digest_rubric.md, "Writing the
     headline"). Lead with the finding, not the activity. A kill-criterion hit always leads. Name in
     one clause what root §4 still calls for that nobody has measured. If every run is provisional,
     the headline says exactly that and nothing about their numbers. -->

## 3. Runs in Period — report-backed

<!-- One row per run holding an EXPT_ANALYSIS report; the verdict and numbers are quoted from it.
     "Source" is what the report recorded, carried over so a reader can check it. Write "None" if no
     in-scope run has been analyzed. -->

| Run | Plan | Verdict | Headline metric | Split | Source | Report |
|---|---|---|---|---|---|---|
| `<prefix>_<slug>` | `<prefix>_<slug>_plan.md` | met | <value> | test | `<path:line or key>` | EXPT_ANALYSIS_<date> |

## 4. Runs in Period — provisional (unverified)

<!-- Runs with a directory but no analysis report. EXEC_LOG only; a number appears here ONLY if the
     log itself names it and its file (references/digest_rubric.md, Tier 2). No verdict, no scoring,
     no figures. These numbers must not be quoted, compared, or entered into the ledger. Write "None"
     if every in-scope run has been analyzed. -->

| Run | Plan | Log status | Steps | Reported number (provisional) | Source | Next |
|---|---|---|---|---|---|---|
| `<prefix>_<slug>` | `<prefix>_<slug>_plan.md` | in_progress | 3/5 | <value> — provisional (unverified) | `<path:line>` | `/star-expt-analyst <run dir>` |

## 5. What Moved

<!-- Diff against the previous digest's sources: list. Report-backed rows only. State the direction;
     never the cause (references/digest_rubric.md). Omit this section entirely when there is no
     previous digest; write "Nothing moved" when the diff is empty. -->

| Run | Movement | From → To | Evidence |
|---|---|---|---|
| `<prefix>_<slug>` | verdict changed | not met → met | EXPT_ANALYSIS_<old> → EXPT_ANALYSIS_<new> |
| `<prefix>_<slug>` | newly analyzed | provisional → met | EXPT_ANALYSIS_<date> |

## 6. Signals & Findings

<!-- Kill-criteria hits, strategy signals recorded in EXEC_LOGs, claims a report calls refuted or
     unsupported, and blocker/major observations. One line each with its run and where it is written
     down, plus the routing. A kill-criterion hit is the plan working — say so plainly. Write "None"
     if nothing fired. -->

- <signal> — `<prefix>_<slug>`, <where it is recorded> → `/star-plan-reviser <slug>`

## 7. Plan-Tree Changes in Period

<!-- Plans whose `updated` or `finalized:` falls in the window: created, revised, decomposed,
     finalized. Frontmatter only — never diff bodies. Omit in plan mode if nothing changed. Write
     "None" if no plan changed. -->

- `<prefix>_<slug>_plan.md` — <created|revised|decomposed|finalized> <YYYY-MM-DD>

## 8. Gaps & Debts

<!-- What the period leaves owing: in-scope runs with no analysis report, leaves with no exec_runs,
     leaves with an unchecked "Awaiting user" STOP-line command, and a ledger older than the newest
     in-scope analysis report. One line each with the command that closes it. Write "None" if the
     period is clean. -->

- <what is owed> — `<prefix>_<slug>` → `<command>`

## 9. Next

<!-- The one or two things to do next, each with its exact command. Route, never act: an unanalyzed
     run to /star-expt-analyst, a stale ledger to /star-expt-analyst aggregate, an unexecuted or
     awaiting leaf to /star-plan-executor, a refuted claim to /star-plan-reviser, the current state of
     the whole tree to /star-flow-status. -->

- <action> → `<command>`
