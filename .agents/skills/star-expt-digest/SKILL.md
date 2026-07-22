---
name: star-expt-digest
description: >-
  Summarize what the experiment programme has done lately, on the time axis. No argument resumes
  from the previous digest's watermark and covers everything since; a PLAN_NAME covers that node's
  whole family — ancestors for claim context, every descendant for evidence — unbounded in time;
  `<N>d` or a date covers a window; `all` re-seeds from the beginning. Collects each in-scope run's
  newest EXPT_ANALYSIS report, tabulates verdicts and headline metrics with their provenance,
  derives what moved since the previous digest (new runs, changed verdicts, newly analyzed runs),
  gathers strategy signals and kill-criteria hits, notes which plans were created or revised in the
  period, and lists the gaps. A run with no analysis report is read raw for a provisional line only,
  tagged unverified in its own table, never scored and never quoted as a result. Writes one dated
  digest to wkdrs/digests/. Read-only otherwise: never edits plans, exec_status, logs, or the
  results ledger, and never re-runs an experiment. Use when the user invokes $star-expt-digest or
  asks Codex for a weekly / periodic summary of experiment progress, what happened since last time,
  what a plan family has produced so far, or material for a progress report. Supports bilingual
  English/Chinese work.
---

# Research Experiment Digest

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `$star-expt-digest [PLAN_NAME | <N>d | <YYYY-MM-DD> | all | ledger]` — no argument resumes from the newest digest's `covers.through` and covers everything after it; a plan name (slug / numeric prefix / filename) covers that node's family with no time bound; `7d` or `2026-07-01` sets an explicit window; `all` covers the whole history and re-seeds the series; `ledger` writes a different artifact entirely — the cross-artifact model-provenance rollup at `wkdrs/digests/MODEL_LEDGER.md` (Step 8).

**Shared conventions.** Read `docs/mds$star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

Serve as the family's timekeeper. `star-expt-analyst` answers *did this run meet its plan*; its `aggregate` mode answers *what are the final numbers, organised by claim* and owns the verified ledger `metds/results.md`; `star-flow-status` answers *where does everything stand right now*, as a snapshot with no memory. This skill answers the question none of them can: **what has happened since last time, and what did we learn.**

The product is a dated digest — the entry a researcher reads back before a supervisor meeting, a weekly report, or picking work up after two weeks away. It carries narrative the ledger is forbidden to carry: what moved, what got refuted, which direction changed. It is not a results table, and it never becomes the source anyone quotes a number from.

Read and narrate; do not execute, analyze runs, score criteria, revise plans, or flip status. Route what the digest surfaces beyond the write boundary: an unanalyzed run to `$star-expt-analyst`, a stale ledger to `$star-expt-analyst aggregate`, an unexecuted leaf to `$star-plan-executor`, a refuted claim to `$star-plan-reviser`, the current state of the tree to `$star-flow-status`.

## Core Principles

1. **The period is defined before anything is read, and it is written down.** Every digest states its mode, its scope, and the exact window it covers, and names the digest it continues from. The watermark is read from that file's `covers.through`, never from file mtimes and never from memory of a previous session. Rules: `references/scope_spec.md`.
2. **Two tiers of evidence, never merged.** A run with an `EXPT_ANALYSIS_<date>.md` is **report-backed**: its numbers and verdict are quoted from that report with its date. A run without one is **provisional**: its EXEC_LOG is read raw for a rough line, tagged `provisional (unverified)`, and kept in its own table. The tiers never share a table, and a provisional number is never scored, never used in a delta, and never quoted as a result. Rules: `references/digest_rubric.md`.
3. **Report-level, not re-verified — and the digest says so.** Unlike `aggregate`, do not re-open each cited source to confirm a number. Copy it with its provenance (`{value, source, report date}`) so a reader can. Every digest states in its own words that it is a progress record, and that `metds/results.md` is where verified numbers live. A number quoted into a paper from a digest is a misuse the file itself warns against.
4. **What moved is the point.** A digest that only lists runs is a worse `star-flow-status`. The value is the comparison against the previous digest's `sources:` — runs that are new, verdicts that changed, runs that were provisional last time and are analyzed now, claims that got refuted. When there is no previous digest, say the series starts here and skip the section rather than inventing movement.
5. **Narrative is allowed; causal attribution is not.** Write what was learned, what a negative result suggests, and where the work turned. Never say *why* one variant beat another — that needs a controlled comparison no skill in this family runs (`aggregate_spec.md`'s rule, and it binds here too). Report the direction and who to ask: `$star-expt-analyst <run>` for the interpretation, `$star-plan-reviser` for what it means for the plan.
6. **Strictly read-only outside this skill's own file; the STOP line applies.** The only thing written is `wkdrs/digests/EXPT_DIGEST_<date>.md`. Never touch plans, `exec_status`, `EXEC_PLAN.md`, `EXEC_LOG.md`, any `EXPT_ANALYSIS` report, or `metds/results*.md`. Never re-run training, evaluation, or a costly call to fill a gap — an unmeasured thing is a listed gap with a routing command, not a task to take on.

## Workflow

### Step 0: Resolve the period and the scope

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. List `wkdrs/digests/EXPT_DIGEST_*.md` and read the newest one's frontmatter — its `covers.through` is the watermark, its `sources:` is the baseline for Step 4.
3. Interpret the argument per `references/scope_spec.md`, first match wins: `all` → whole history; `<N>d` / `<YYYY-MM-DD>` → that window; a plan name → that node's family, time-unbounded; nothing → the incremental window `(watermark, today]`, or the whole history when no digest exists yet.
4. State the resolved period and scope in one line before reading further, so a wrong window is caught before the work.
5. **An empty period is a valid answer.** No run falls in it → say so, name the watermark and the newest run date, and stop. Never widen a window to find something to report.

### Step 1: Collect the in-scope runs

Resolve the scope's leaves and, for each, every entry in its `exec_runs` — a leaf re-run for a second seed has several, and all of them are dated independently. Date each run by the rules in `references/scope_spec.md` (analysis report date, else the EXEC_LOG's last dated entry; never file mtime) and keep those falling in the window. In plan-family mode keep them all.

Classify each kept run **report-backed** (its dir holds an `EXPT_ANALYSIS_<date>.md`; take the newest) or **provisional** (it does not).

### Step 2: Read the report-backed tier

Per run, from its newest `EXPT_ANALYSIS_<date>.md` only: the run verdict, the §5 scorecard in one line, the headline metrics with the source and split the report records, and any blocker/major observation or strategy signal it names. Do not open the run's raw logs — the report is the interface, and going behind it is per-run analysis, which is `$star-expt-analyst`'s job with its own verification.

### Step 3: Read the provisional tier (bounded)

For a run with no analysis report, read **only** its `EXEC_LOG.md`: log `status`, steps done / total, any `blocked` step, any "Awaiting user" STOP-line command, any recorded Strategy signal. If the log itself names a headline number and the file it came from, quote it with `path:line` and the `provisional` tag; if it does not, write `not measured` — never go hunting through raw logs for a number to fill the cell, and never render a figure. The bounds are in `references/digest_rubric.md`, and they are tight on purpose: this tier exists so a week's work is visible, not so the digest can grade it.

### Step 4: Derive what moved

Compare this run set against the previous digest's `sources:` list: runs appearing for the first time; runs whose verdict changed and in which direction; runs that were `provisional` there and are report-backed here; claims a report now calls refuted or a kill-criterion hit. Report-backed rows only. No previous digest → state that this is the first digest and omit the section.

### Step 5: Gather the surrounding context

- **Plan-tree changes in the period**: plans whose `updated` (or `finalized:`) falls in the window — created, revised, decomposed, finalized. Frontmatter only; do not diff bodies.
- **Gaps and debts**: in-scope runs with no analysis report; leaves with no `exec_runs`; leaves whose EXEC_LOG has an unchecked STOP-line command; and whether `metds/results.md` (or the scoped `metds/results_<slug>.md`) is older than the newest analysis report in scope.

### Step 6: Write the digest

Fill `assets/digest_template.md` (Chinese: `assets/digest_template_zh.md`; the digest follows the dialogue language, or the language the in-scope plans carry when they agree) and write it to `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`. Real dates only, from the system clock (conventions §4). A second digest on the same day overwrites that day's file; on a later day it writes its own — the directory is the timeline.

**The watermark is only advanced by a digest that covers a period ending today.** A retrospective window (`2026-05-01`, or a plan-family digest) writes its file but leaves the series' resume point alone: set its `covers.through` to what it actually covered, and do not let a backward-looking read make the next incremental run skip work. `references/scope_spec.md` states this precisely.

### Step 7: Digest & routing

≤400 words, period first: the window and scope, how many runs were report-backed / provisional, the headline of what was learned, what moved since the previous digest, and the top gaps. Then the routing: an unanalyzed run → `$star-expt-analyst <run dir>`; a stale ledger → `$star-expt-analyst aggregate`; an unexecuted or awaiting leaf → `$star-plan-executor <slug>`; a refuted claim or a kill-criterion hit → `$star-plan-reviser <slug>`; the current state of the tree → `$star-flow-status`. End with the digest path, and one line saying it is a progress record whose numbers are quoted from reports, not verified here.

### Step 8: Ledger (ledger mode only)

Roll every artifact's `model_trail` into one table — the cross-artifact view of **who wrote what**, which no single artifact can show. Mechanical, not interpretive: read, group, count, write.

1. Walk the artifacts registered in conventions §8 that exist on disk. Read **frontmatter only** — `model_id`, `model_trail`, and the file's own date field. Never read a body to infer authorship.
2. Every row is copied from a trail entry. An artifact with no `model_trail` is a **gap**, listed in §5 with why it has none (written before the field existed, or a skill that skipped it) — never assumed single-model, and never back-filled by guessing.
3. Where an artifact carries finer per-event attribution than its trail — a plan's `## Revision History`, an `EXEC_LOG` step table's `model` column, `refs_index`'s `Model` column — prefer it: it says which *step* or *entry* a model wrote, not just which session.
4. Fill `assets/model_ledger_template.md` (Chinese: `assets/model_ledger_template_zh.md`) into `wkdrs/digests/MODEL_LEDGER.md`. Same date rule as the digest: same day overwrites, a later day writes its own.

**Counts are not a verdict.** Report write events per model and stop there. A model with more events did more writes, which is not "did better" — the ledger has no quality signal in it, and saying otherwise from these numbers is the same error as attributing a metric delta to a cause. Trails are self-reported (conventions §8), so the ledger inherits that limit and says so on its face.
## State Rules

- The only writes are `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md` and — in `ledger` mode only — `wkdrs/digests/MODEL_LEDGER.md`. Nothing else, anywhere — no figures, no scripts, no subdirectories.
- Never touch: `metds/plans/*` (including `exec_status`, `exec_runs`, `updated`); `wkdrs/<run>/EXEC_PLAN.md` and `EXEC_LOG.md`; any `EXPT_ANALYSIS_<date>.md` (they are this skill's input, never its output); `metds/results.md` and `metds/results_<slug>.md` (the ledger is `$star-expt-analyst aggregate`'s, and a digest number must never reach it); `${CODE_NAME}/`; `.env`.
- Never move, rename, or delete a run directory, log, artifact, or an older digest. An older digest is the series' history and the next run's baseline.
- Older digests are read for their frontmatter only — `covers`, `sources`, `previous`. Never rewrite one to reconcile it with what is now known.
- All commands run through `.env`'s conda env; no system python; never install or upgrade anything (conventions §3.5). This skill needs no packages beyond file reads.
- Nothing heavy: no training, no evaluation, no full-dataset passes, no costly API calls (conventions §2).
- Git: read-only; never commit (conventions §1). `wkdrs/` is git-ignored, so the digest series lives on disk only — say so once if the user asks about sharing it.
- Ask one direct question at a time where the workflow calls for it (an ambiguous plan name, an argument that parses as neither a window nor a plan) and require an explicit answer. Since the skill writes nothing outside its own digest, there is no approval gate — but for the same reason, never state or imply that a plan, a status, a report, or the ledger was changed.
- Never present a provisional number as a result in chat either. If the digest tagged it unverified, the reply says so too. Keep technical terms — metric names, log keys, file paths, run names — in English inside Chinese digests.
