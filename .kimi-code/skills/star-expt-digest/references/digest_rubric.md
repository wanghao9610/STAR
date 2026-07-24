# Digest Rubric — the two tiers, what moved, and what a digest never does

The digest is a **progress record**, not a results table. `wkdrs/results/results.md` is the verified ledger; `metds/evaluation.md` is the protocol; this is the narrative of what happened between two dates. This file defines what may enter it, at what level of trust, and where the line is.

## The two tiers

Every run in scope lands in exactly one tier, and the tiers never share a table.

### Tier 1 — report-backed

The run holds an `EXPT_ANALYSIS_<date>.md`. Take the **newest**. From it, and from nothing else:

- the run verdict (`met` / `partially met` / `not met` / `inconclusive` / `invalid`);
- the §5 done-criteria scorecard, condensed to one line;
- the headline metrics, each carried over as `{value, source, split}` exactly as the report records them;
- any blocker or major observation, and any strategy signal or kill-criterion hit it names.

**Do not open the run's raw logs to supplement a report.** The report is the interface. Going behind it to "check" or to add a metric it omitted is per-run analysis, which is `/skill:star-expt-analyst`'s job and carries a verification pass this skill does not run. A report that looks wrong is routed (`/skill:star-expt-analyst <run dir>` to refresh it), not corrected here.

Numbers are copied **with provenance, not re-verified** (`SKILL.md` Core Principle 3). The digest records the source the report cited so a reader can check it; it does not check it itself. That is the whole cost difference between a digest and an `aggregate`, and it is why a digest can run weekly.

### Tier 2 — provisional

The run has a directory but no analysis report. It exists in the digest so a week's work is **visible**, not so it can be graded.

**Read only `EXEC_LOG.md`.** From it: the log `status`, steps done / total, any `blocked` step, any unchecked "Awaiting user" STOP-line command, any recorded Strategy signal. If the log itself names a headline number **and** the file it came from, quote it with `path:line`; otherwise the cell is `not measured`.

Hard bounds on this tier:

- **Never hunt for a number.** If the EXEC_LOG does not hand you one, the answer is `not measured`. Grepping the run's metrics files, parsing a results JSON, or reading a TB event file is analysis, and it is out of bounds here.
- **Never render a figure**, never run a parsing script, never compute a derived quantity (a mean over seeds, a delta, a percentage).
- **Never score a provisional run** against a §5 done-criterion. It has no verdict; the frontmatter records `verdict: —` and the table says `awaiting analysis`.
- **Every provisional value is tagged** `provisional (unverified)` in the table and carries its `path:line`.

A provisional row always carries its routing: `/skill:star-expt-analyst <run dir>`.

### The wall between the tiers

A provisional number may **never**:

1. appear in the report-backed table, or in a table that mixes the two;
2. be used to compute or claim a delta in "What Moved";
3. be quoted in the digest's headline, or in the chat reply, as a result or an outcome;
4. enter `wkdrs/results/results.md` or any scoped `wkdrs/results/results_<slug>.md` — a digest writes no ledger, and the ledger's own trust model re-verifies from source, which a provisional number by definition has not passed;
5. be described with a word that implies a judgment — `improved`, `beat`, `met`, `confirms`, `works`. The neutral verb is "reports": *the log reports 0.41 at `train.log:812` (provisional)*.

This wall is the reason the provisional tier is safe to have. Remove it and the digest becomes a second, unverified analyst producing numbers that contradict the ledger.

## What moved

Derived by diffing this digest's run set against the previous digest's `sources:` list. **Report-backed rows only** — a provisional run has no verdict to move.

| Movement | Fires when |
|---|---|
| New run | the run is absent from the previous `sources:` |
| Verdict changed | the same run appears in both with a different `verdict` |
| Newly analyzed | the run was `tier: provisional` there and is `report-backed` here |
| Report refreshed | same run, same tier, but a newer `report:` filename |

State the direction plainly (`not met → met`), name the run and both report dates, and stop there. **Why** it moved is not yours to say (Core Principle 5). A verdict that went `met → not met` is a finding worth leading with, and worth routing to `/skill:star-plan-reviser` — but the digest reports the change, not its cause.

No previous digest → the section is omitted, and §1 says the series starts here. An empty diff against a previous digest is written as "nothing moved", which is itself information: a period with runs but no movement means work happened and no verdict changed.

## What a digest never does

- **Never attributes a delta to a cause.** Inherited verbatim from `aggregate_spec.md`. A variant that won, won; naming the reason needs a controlled comparison no skill in this family runs.
- **Never scores a criterion.** The verdict is quoted from the analysis report or it is absent. The digest has no opinion on whether a done-criterion was met.
- **Never restates a protocol or a method.** How a benchmark is run is `metds/evaluation.md`; what the method is, `metds/overview.md`. The digest cites and moves on.
- **Never becomes the quotable source.** Every digest says, in its own header, that its numbers are copied from reports and that `wkdrs/results/results.md` is the verified ledger. A number quoted into a paper from a digest is a misuse the file warns against on its face.
- **Never fills a gap by running something.** An unexecuted leaf, an unanalyzed run, an awaiting STOP-line command: each is a listed gap with the command that closes it, handed back to the user (conventions §2).
- **Never reports an empty period as an achievement.** No runs in the window is written as "no runs in this period", with the newest run date and the watermark, and nothing else. Padding an empty digest with the state of the tree is `/skill:star-flow-status`'s output, not this one's.

## Writing the headline

Three to five sentences, and the hardest part of the file to get right. It answers *what did we learn in this period* using only report-backed evidence:

- Lead with the finding, not the activity. "The 3-way ablation refutes the shared-head hypothesis at `01_core-method`" beats "three runs completed this week."
- A negative result leads if it is the period's biggest fact. A kill-criterion hit always leads (`analysis_rubric.md`'s stance, carried here): it is the plan working.
- Name what is still unmeasured, in one clause. A period that produced numbers for two of five claims should say which three are still open.
- If every in-scope run is provisional, the headline says exactly that — *N runs completed, none analyzed yet* — and nothing about their numbers. That is the honest headline for the period, and it routes straight to `/skill:star-expt-analyst`.
