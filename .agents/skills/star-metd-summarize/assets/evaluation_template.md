---
type: evaluation
language: en
generated: <YYYY-MM-DD>
sources:
  - plan: <prefix>_<slug>_plan.md
    updated: <YYYY-MM-DD>
---

<!-- Compiled by star-metd-summarize from metds/plans/. Hand edits are overwritten on the next
     run — to change this document, change the plan it came from. This document defines the
     protocol; what a run actually scored lives in wkdrs/<run>/EXPT_ANALYSIS_<date>.md. -->

# Evaluation

## 1. Protocol Overview

<!-- The whole evaluation surface in one table, from the root §4: which task, on which benchmark,
     by which metric, against which baselines. No scores — a number here would be a claim this
     document has no evidence for. -->

| Task | Benchmark | Split | Metric(s) | Baselines |
|---|---|---|---|---|
| <…> | <…> | <test> | <…> | <…> |

## 2. Benchmark Detail

<!-- One subsection per benchmark that needs more than its row, from the root §4 metrics and the
     eval leaves' §5 thresholds. The meaningful margin matters as much as the metric: without it,
     any delta can be spun as an improvement. -->

### 2.1 <Benchmark>

**Split & protocol.** <exact split, and the protocol variant where more than one exists>
**Metric.** <definition or implementation the plan names — only where it is not the standard one>
**Meaningful margin.** <the delta the plan calls a real improvement, and where that number is from>

## 3. Baselines

<!-- Each baseline, where its numbers will come from, and what makes the comparison fair. A
     quoted number's source must be named; "reproduced here" and "quoted from the paper" are not
     the same claim and a reader must be able to tell them apart. -->

| Baseline | Numbers from | Comparability notes |
|---|---|---|
| <name> | <reproduced here / quoted from `<work>`> | <same data / backbone / budget?> |

## 4. Ablations

<!-- The claim→ablation design, from the root §4 ablation design and §5 kill-criteria: for each
     claim, the variant that isolates it, and what result would support or refute it. The
     "refutes it if" column is written before any run — that is what makes it a test. -->

| # | Claim under test | Variant | Supports the claim if | Refutes it if |
|---|---|---|---|---|
| A1 | <…> | <…> | <…> | <…> (kill-criterion) |

## 5. Running the Evaluation

<!-- Per benchmark: the entry point, config, and command as the plans record them, plus where the
     outputs land under wkdrs/. Link a run's analysis report rather than copying its numbers —
     results and their interpretation belong to the experiment-analysis skill, and a number
     copied here is a number that will silently go stale. -->
