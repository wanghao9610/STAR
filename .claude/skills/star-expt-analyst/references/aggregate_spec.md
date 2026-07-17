# Aggregate mode — the cross-run results ledger

Per-run analysis answers *did this run meet its plan*. Aggregate answers *what does the whole experiment programme show, and where did each number come from* — compiling every run's verified numbers into one ledger, `metds/results.md`: the material a paper's results section is written from, and the counterpart to `metds/evaluation.md`, which defines the protocol these numbers were measured under.

This file defines scope, the trust model, the axis, what the ledger never does, exclusion, and the write gate.

## Scope

`aggregate` with no plan name covers the whole forest; with a plan name, that node's subtree. Collect every leaf under the scope, then **every run in its `exec_runs`** — a leaf re-run for a second seed or a fixed bug has several, and the ledger shows what exists rather than only the last. Per run, first match wins:

- the newest `wkdrs/<run>/EXPT_ANALYSIS_<date>.md` in it → an aggregatable run, one table row;
- a run directory with no analysis report → **gap**: list it and route to `star-expt-analyst <run dir>`. Do not read its logs here — aggregate reads reports, not raw runs;
- a leaf with no `exec_runs` at all → never executed; list it as a gap and route to `star-plan-executor <slug>`.

A scope where no leaf has a report is a valid answer: say so and stop. Never compile a ledger from nothing.

## Trust model: re-verify from source, never transitively

An EXPT_ANALYSIS report is a **verified** artifact — every number in it was re-opened at its cited source before it entered (Core Principle 2). That is not a licence to copy it: the run may have moved on since the report was written, and a ledger number is the one that gets quoted into a paper.

For every number that will enter `results.md`:

1. Read it from the report's metric table with its recorded source (`path:line` or key) and split.
2. **Re-open that source** and confirm it still says what the report says.
3. Agrees → the number enters, carrying `{run, source, report date}`.
4. Disagrees, or the source is gone → the number does **not** enter. Put the run in §5 Excluded with both values and the reason, and recommend re-running `star-expt-analyst <slug>` to refresh that report.

Never read a metric out of a raw log no report covers. That is per-run analysis, and it belongs in a per-run pass with its own dimension-D verification — not here.

## The claim axis, not the run axis

The plan tree is organised by decomposition; a reader needs the numbers organised by **what they show**. Group from the root's §4:

- the **claim → experiment map** gives one table per claim / benchmark;
- the **ablation design** gives one table per ablation, its rows being the variants;
- a run the design maps to neither goes to a final "Other runs" block — listed, never dropped silently.

Rows within a table are the runs §4 assigns to it, in the order §4 gives (else by prefix). One row per run, not per report.

## What the ledger never does

- **Never attribute a delta to a cause.** A table shows variant → number. Saying *why* a variant won needs a controlled comparison this skill does not run (Core Principle 5). What root §4 says a variant *tests* is the caption; a conclusion drawn here is not.
- **Never combine numbers measured under different protocols.** A different split, metric definition, or eval entry point means a different table — or one table with `⚠` and both protocols named. A silently merged column is a wrong paper table.
- **Never compute a baseline delta nobody measured.** A baseline number the plans state is a row; an unmeasured one is `not measured`, not an inferred gap.
- **Never restate the protocol.** How a benchmark is run belongs to `metds/evaluation.md`; the ledger cites it and shows scores.

## Excluded runs

A run whose report verdict is `invalid` or `inconclusive`, or whose number failed re-verification, does **not** appear in a results table. It goes to §5 Excluded with its verdict and one line of why. Excluding a run silently is how a results table starts lying: a reader must be able to see what was left out and count it.

A **`not met` run is not excluded** — a negative result is a result. It belongs in its table with its verdict shown.

## Frontmatter contract

```yaml
---
type: results
language: <en|zh>
generated: <YYYY-MM-DD>          # a real date; never invented
scope: <the subtree these numbers come from, or "whole forest">
sources:                          # every run that fed this ledger
  - run: <prefix>_<slug>
    report: EXPT_ANALYSIS_<YYYY-MM-DD>.md
    verdict: <met|partially met|not met|inconclusive|invalid>
---
```

`type: results` + `generated:` are what mark the file compiled and therefore safe to regenerate. `sources:` is the staleness check: a run whose newest report is newer than the one recorded here means the ledger is stale.

## Write gate

- **Missing** → write it.
- **Exists with `type: results`** → compare against the freshly compiled content, show the change list (one line per table: `added` / `rewritten` / `removed` / `unchanged`, and what moved), and ask to overwrite or skip. Every table `unchanged` → write nothing; leave the file and its `generated` date alone.
- **Exists without that frontmatter** → hand-authored. Say what it holds and what compiling would replace it with, and ask. Leaving it alone is a valid outcome; so is compiling to a path the user names.
