---
type: results
language: en
generated: <YYYY-MM-DD>
scope: <the subtree these numbers come from, or "whole forest">
sources:
  - run: <prefix>_<slug>
    report: EXPT_ANALYSIS_<YYYY-MM-DD>.md
    verdict: <met|partially met|not met|inconclusive|invalid>
---

# Results

<!-- Written by /star-expt-analyst aggregate. Every number below was re-opened at its source before
     it entered (references/aggregate_spec.md), and carries where it came from. The protocol these
     numbers were measured under is metds/evaluation.md — this file is scores only. Treat it as
     generated: to change a number, fix or re-run the run and recompile, never edit it here. -->

## 1. Summary

<!-- Three or four sentences: what the programme measured, how many runs entered the tables, how many
     were excluded and why, and what root §4 still calls for that nobody has measured. State what the
     tables show — no interpretation beyond it. -->

## 2. Main Results

<!-- One table per claim / benchmark from the root §4 claim→experiment map. The caption is what root
     §4 says this claim tests, in its words — not a conclusion drawn here. -->

### <claim / benchmark>

<!-- Caption: what root §4 says this tests. -->

| Run | Variant / setting | <metric> | Split | Verdict | Source |
|---|---|---|---|---|---|
| `<prefix>_<slug>` | <…> | <value> | test | met / not met | `<path:line or key>` @ EXPT_ANALYSIS_<date> |

## 3. Ablations

<!-- One table per ablation in the root §4 ablation design; the rows are its variants. The design says
     what varies — never write why a variant won (aggregate_spec.md: never attribute a delta). -->

### <ablation name>

<!-- Caption: what root §4 says this ablation isolates. -->

| Run | Variant | <metric> | Split | Verdict | Source |
|---|---|---|---|---|---|
| `<prefix>_<slug>` | <…> | <value> | val | met | `<path:line or key>` @ EXPT_ANALYSIS_<date> |

## 4. Other Runs

<!-- Runs root §4 maps to no claim and no ablation. Listed with their headline number, never dropped.
     Write "None" if every run mapped. -->

## 5. Excluded

<!-- Runs kept out of the tables above: report verdict `invalid` or `inconclusive`, or a number that
     failed re-verification (report says X, source now says Y). One row each with the reason — a
     reader must be able to see and count what was left out. Write "None" if nothing was excluded. -->

| Run | Verdict | Why excluded | Next step |
|---|---|---|---|
| `<prefix>_<slug>` | invalid | <…> | `/star-expt-analyst <slug>` |

## 6. Not Yet Measured

<!-- What root §4 calls for that no run has produced: the claim/benchmark, the plan that should
     produce it, and its state (never executed / STOP-line command still awaiting the user). This is
     the gap list a results section is still missing. Write "None" if the design is fully covered. -->

- <claim / benchmark> — `<prefix>_<slug>_plan.md`; <state> → `/star-plan-executor <slug>`
