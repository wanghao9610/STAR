# Aggregate mode — the cross-run results table

Per-run analysis answers *did this run meet its plan*. Aggregate answers *what does the whole experiment programme show, and where did each number come from* — compiling every run's verified numbers into one results table, `wkdrs/results/results.md`: the material a paper's results section is written from, and the counterpart to `metds/evaluation.md`, which defines the protocol they were measured under.

This file defines scope, the destination, the trust model, the axis, what the results table never does, exclusion, and the write rules.

## Scope

`aggregate` with no plan name covers all plan trees; with a plan name, that node's subtree. Collect every leaf under the scope, then **every run in its `exec_runs`** — a leaf re-run for a second seed or a fixed bug has several, and the results table shows them all, not only the last. Per run, first match wins:

- the newest `wkdrs/<run>/EXPT_ANALYSIS_<date>.md` in it → an aggregatable run, one table row;
- a run directory with no analysis report → **gap**: list it and route to `star-expt-analyst <run dir>`. Do not read its logs here — aggregate reads reports, not raw runs;
- a leaf with no `exec_runs` at all → never executed; list it as a gap and route to `star-plan-executor <slug>`.

A scope where no leaf has a report is a valid answer: say so and stop. Never compile a results table from nothing.

## The destination follows the scope

**The scope decides the filename, because a results table that silently replaces a wider one is how a results section loses rows.**

- **All plan trees** (`aggregate`, no plan name) → `wkdrs/results/results.md`. The project results table.
- **Scoped** (`aggregate PLAN_NAME`) → `wkdrs/results/results_<slug>.md`, `<slug>` being the scoped node's slug — `wkdrs/results/results_core-method.md`. One file per subtree anyone aggregates.

Neither ever writes to the other's path. A scoped run must never overwrite `wkdrs/results/results.md`: it holds fewer runs by construction, so overwriting deletes every row outside the subtree and leaves a file that still looks complete. The `scope:` frontmatter records what the file covers; the filename is what stops the overwrite.

A scoped results table is a **view, not a fork**. Regenerated from the same reports under the same trust model, it never carries a number the project results table would not. When both exist and disagree, the project results table is authoritative and the scoped one stale — recompile it rather than reconcile by hand.

## Trust model: re-verify from source, never transitively

An EXPT_ANALYSIS report is **verified**: every number in it was re-opened at its cited source before it entered (Core Principle 2). That is not a licence to copy it — the run may have moved on since, and a number in the results table is the one quoted into a paper.

For every number that will enter `results.md`:

1. Read it from the report's metric table with its recorded source (`path:line` or key) and split.
2. **Re-open that source** and confirm it still says what the report says.
3. Agrees → the number enters, carrying `{run, source, report date}`.
4. Disagrees, or the source is gone → the number does **not** enter. Put the run in §5 Excluded with both values and the reason, and recommend re-running `star-expt-analyst <slug>` to refresh the report.

Never read a metric out of a raw log no report covers: that is per-run analysis, and belongs in a per-run pass with its own dimension-D verification — not here.

## Scale

A programme of ≤ ~6 reports is usually simplest to read in the main agent. Above that, partition the **report paths** across read-only collection passes, run one at a time, each given its exact list and this return format:

```yaml
- run: <slug>
  report: <path to the EXPT_ANALYSIS it read>
  report_verdict: <the report's own verdict, verbatim>
  verdict_reason: <the report's own one-line reason for that verdict, verbatim>
  metric_rows: [<the report's metric table rows, verbatim, each keeping its source, split, seeds, spread and commit>]
  absent: [<criteria the report scores unmeasurable, or names as missing>]
  protocol_note: <the report's protocol caveat, verbatim, or none>
reports_read: <n>
```

and nothing else. This is safe because of the trust model above, not the collector: re-verification targets the **cited source**, never the report, so nothing a collector transcribed is what a number is finally read from. `protocol_note` travels verbatim per report and is never merged — merging protocols is exactly what "never combine numbers measured under different protocols" forbids. A collector never re-opens a source, never groups by claim, never excludes a run, and never writes. A `reports_read` below the number of reports it was given is the remainder still to collect (conventions §6.3).

## The claim axis, not the run axis

The plan tree is organised by decomposition; a reader needs the numbers organised by **what they show**. Group from the root's §4:

- the **claim → experiment map** gives one table per claim / benchmark;
- the **ablation design** gives one table per ablation, its rows being the variants;
- a run the design maps to neither goes to a final "Other runs" block — listed, never dropped silently.

Rows are the runs §4 assigns to the table, in the order §4 gives (else by prefix). One row per run, not per report. Under an ablation table, one line reads `varied: <the fields the plans say differ between these arms>` — taken from root §4's ablation design and the arms' own §2/§3, and `varied: not stated in the plans` where they do not, which is itself the finding. Under every table, one line reads `N runs scored on <split> for this claim` — fifteen attempts at a threshold is a different claim from one, and a reader should not have to count the rows to learn which they are looking at.

## What the results table never does

- **Never attribute a delta to a cause.** A table shows variant → number. Why a variant won needs a controlled comparison this skill does not run (Core Principle 5). What root §4 says a variant *tests* is the caption; a conclusion drawn here is not.
- **Never combine numbers measured under different protocols.** A different split, metric definition, or eval entry point means a different table — or one table with `⚠` and both protocols named. A silently merged column is a wrong paper table.
- **Never compute a baseline delta nobody measured.** A baseline number the plans state is a row; an unmeasured one is `not measured`, not an inferred gap.
- **Never restate the protocol.** How a benchmark is run belongs to `metds/evaluation.md`; the results table cites it and shows scores.

## Excluded runs

A run whose report verdict is `invalid` or `inconclusive`, or whose number failed re-verification, does **not** appear in a results table. It goes to §5 Excluded with its verdict and one line of why — that reason comes back with the verdict in the collector's return, so excluding a run costs no second reading of the report. Excluding a run silently is how a results table starts lying: a reader must be able to see what was left out and count it.

A **`not met` run is not excluded** — a negative result is a result. It belongs in its table with its verdict shown.

## Frontmatter format

```yaml
---
type: results
language: <en|zh>
generated: <YYYY-MM-DD>          # a real date; never invented
scope: <the subtree these numbers come from, or "all plan trees">
sources:                          # every run that fed this results table
  - run: <prefix>_<slug>
    report: EXPT_ANALYSIS_<YYYY-MM-DD>.md
    verdict: <met|partially met|not met|inconclusive|invalid>
---
```

`type: results` + `generated:` mark the file compiled and therefore safe to regenerate. `sources:` is the staleness check: a run whose newest report post-dates the one recorded here means the results table is stale.

## Write rules

Applied to the destination the scope selected above — never to the other one.

- **Missing** → write it.
- **Exists with `type: results`** → confirm its `scope:` matches the scope being compiled. It does → compare against the freshly compiled content, show the change list (one line per table: `added` / `rewritten` / `removed` / `unchanged`, and what moved), and ask to overwrite or skip. Every table `unchanged` → write nothing; leave the file and its `generated` date alone. It does **not** match — a wider scope than this one — → stop and say so rather than narrow it; that is the overwrite the filename rule exists to prevent.
- **Exists without that frontmatter** → hand-authored. Say what it holds and what compiling would replace it with, and ask. Leaving it alone is a valid outcome; so is compiling to a path the user names.
