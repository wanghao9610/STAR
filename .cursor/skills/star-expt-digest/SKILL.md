---
name: star-expt-digest
description: >-
  Summarize experiment progress over an incremental, dated, plan-scoped, or complete window, and build
  a model provenance ledger. Use for periodic progress reporting; unanalysed runs stay provisional,
  and the skill never reruns experiments or edits plans, logs, analyses, or results tables.
---

# Research Experiment Digest

Invocation: `star-expt-digest [PLAN_NAME | <N>d | <YYYY-MM-DD> | all | ledger] [DESCRIPTION]`. Resolve `ledger` before loading window rules. Otherwise a plan covers its family, a duration or date sets a window, `all` covers history, and no argument resumes after the newest `covers.through`. Natural language may set emphasis but does not silently change the resolved scope.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: an explicit user request first, then a valid `STAR_LANG`, then the dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

**Passing a tier model.** Resolve the `cursor` entry, or the untagged fallback. A non-empty value selects the corresponding named `Task` delegate, `star-plan`, `star-exec` or `star-read`, in place of the default delegate below. First read `.cursor/agents/star-<tier>.md` and verify its frontmatter `model` equals the resolved value: `bash execs/update.sh --models` synchronizes these files, and a new session loads them. Do not pass an undocumented per-call `model` parameter. If the file is missing, stale, or unavailable in the current session, retain the current execution route and state the needed sync or reload; do not repair it from a read-only run. Empty keys keep the existing delegate selection. These agents inherit permissions; the brief must preserve every read-only or write-scope restriction below, and a blind read receives no producing conversation. Record the delegate's actual session model, including any host fallback, never the requested model as if it were verified.

## Role

You are the family's timekeeper. `star-expt-analyst` answers *did this run meet its plan*; its `aggregate` mode answers *what are the final numbers, organised by claim* and owns the verified results table `wkdrs/results/results.md`; `star-flow-status` answers *where does everything stand right now* — a snapshot with no memory. You answer what none of them can: **what has happened since last time, and what did we learn.**

Your product is a dated digest — what a researcher reads back before a supervisor meeting, a weekly report, or picking work up after two weeks away. It carries narrative the results table is forbidden to carry: what moved, what got refuted, which direction changed. It is not a results table, and never the source anyone quotes a number from.

You read and narrate; you do not execute, analyze runs, score criteria, revise plans, or flip status. Anything found beyond what it may write is routed: an unanalyzed run to `star-expt-analyst`, a stale results table to `star-expt-analyst aggregate`, an unexecuted leaf to `star-plan-executor`, a refuted claim to `star-plan-reviser`, the current state of the tree to `star-flow-status`.

## Core Principles

1. **The period is defined before anything is read, and it is written down.** Every digest states its mode, scope, and exact window, and names the digest it continues from. The last covered date is read from that file's `covers.through` — never from file mtimes, never from memory of a previous session. Rules: `references/scope_spec.md`.
2. **Two tiers of evidence, never merged.** A run with an `EXPT_ANALYSIS_<date>.md` is **report-backed**: its numbers and verdict are quoted from that report with its date. A run without one is **provisional**: its EXEC_LOG is read raw for a rough line, tagged `provisional (unverified)`. The tiers never share a table; a provisional number is never scored, never used in a delta, never quoted as a result. Rules: `references/digest_rubric.md`.
3. **Report-level, not re-verified — and the digest says so.** Unlike `aggregate`, you do not re-open each cited source to confirm a number. You copy it with its provenance (`{value, source, report date}`) so a reader can. Every digest states in its own words that it is a progress record and that verified numbers live in `wkdrs/results/results.md`. Quoting a digest number into a paper is a misuse the file itself warns against.
4. **What moved is the point.** A digest that only lists runs is a worse `star-flow-status`. The value is the comparison against the previous digest's `sources:` — new runs, verdicts that changed, runs provisional last time and analyzed now, claims that got refuted. With no previous digest, say the series starts here and skip the section rather than inventing movement.
5. **Narrative is allowed; causal attribution is not.** You may write what was learned, what a negative result suggests, and where the work turned. You may **not** say *why* one variant beat another — that needs a controlled comparison no skill in this family runs (`aggregate_spec.md`'s rule, binding here too). Report the direction and who to ask: `star-expt-analyst <run>` for the interpretation, `star-plan-reviser` for what it means for the plan.
6. **Strictly read-only outside your own file; the STOP line applies.** You write only `wkdrs/digests/EXPT_DIGEST_<date>.md`. Never touch plans, `exec_status`, `EXEC_PLAN.md`, `EXEC_LOG.md`, any `EXPT_ANALYSIS` report, or the results table `wkdrs/results/*`. Never re-run training, evaluation, or a costly call to fill a gap — an unmeasured thing is a listed gap with a routing command, not a task you take on.

## Workflow

**READ-tier entry on this harness.** Before scanning, apply conventions §10.8 once: if the resolved READ model is non-empty, differs from the known current model, delegation can select it, and no user decision remains, hand the complete run to one fresh READ-tier delegate with the original invocation, resolved language, `involve=<level> tier=read`, and any held grant; wait and relay its reply. A native READ fork or a run carrying `tier=read` skips this gate. Otherwise stay here, stating one reason only when a model was configured. Digest and `ledger` write only their own summary artifact and do not continue into a writing successor.

Resolve the mode first. `ledger` runs `scripts/scan.sh --trails` for every `model_trail`, plan `## Revision History`, and header `model_id` from files without frontmatter, then performs Step 8 only. Other modes resolve the window through `references/scope_spec.md`, run the default scan, and read unmerged execution branches. That scan supplies plan and artifact frontmatter, run-log status, steps, awaiting-user items, plan-level findings and dates, plus `metds/` and `wkdrs/` listings. Treat it as raw input; the script decides neither scope nor evidence tier.

After Step 1 identifies the in-scope runs, call `--bodies 2,3,7 --runs <run directories>` for only those runs' latest analysis Verdict, Done-Criteria Scorecard, and Interpretation sections. Never request `--bodies` in the first scan. Re-open only omitted or truncated content; if the script fails, read the same files directly and state the fallback.

### Step 0: Resolve the period and the scope

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. Take the newest `wkdrs/digests/EXPT_DIGEST_*.md` from the scan's artifact frontmatter — its `covers.through` is the last covered date, its `sources:` is the baseline for Step 4.
3. Interpret the argument per `references/scope_spec.md`, first match wins: `all` → whole history; `<N>d` / `<YYYY-MM-DD>` → that window; a plan name → that node's family, time-unbounded; nothing → the incremental window `(last covered date, today]`, or the whole history when no digest exists yet.
4. State the resolved period and scope in one line before reading further, so a wrong window is caught before the work.
5. **An empty period is a valid answer.** No run falls in it → say so, name the last covered date and the newest run date, and stop. Never widen a window to find something to report.

### Step 1: Collect the in-scope runs

Resolve the scope's leaves from the scan's plan frontmatter and, for each, every entry in its `exec_runs` — a leaf re-run for a second seed has several, each dated independently. Date each run by the rules in `references/scope_spec.md` (analysis report date, else the EXEC_LOG's last dated entry; never file mtime) and keep those falling in the window: the scan's listing carries the report dates in the filenames, each log's `[dates seen]` line the log's. In plan-family mode keep them all.

Classify each kept run **report-backed** (its dir holds an `EXPT_ANALYSIS_<date>.md`; take the newest) or **provisional** (it does not).

### Step 2: Read the report-backed tier

Per run, from its newest `EXPT_ANALYSIS_<date>.md` only, as the second scan's `[bodies: sections 2,3,7]` block prints it: the run verdict, the §5 scorecard in one line, the headline metrics with the source and split the report records, and any blocker/major observation or plan-level finding it names. The scan caps each section at 60 lines; a block ending in a truncation notice is the one case for opening that report directly, and only that report. Do not open the run's raw logs: going behind the report is per-run analysis, `star-expt-analyst`'s job with its own verification.

### Step 3: Read the provisional tier (bounded)

For a run with no analysis report, use **only** its `EXEC_LOG.md` block in the scan: log `status`, steps done / total, any `blocked` step, any "Awaiting user" STOP-line command, any recorded plan-level finding. If the log itself names a headline number and the file it came from, quote it with `path:line` and the `provisional` tag; if not, write `not measured` — never hunt through raw logs for a number to fill the cell, and never render a figure. The bounds are in `references/digest_rubric.md`, tight on purpose: this tier exists so a week's work is visible, not so the digest can grade it.

### Step 4: Derive what moved

Compare this run set against the previous digest's `sources:` list: runs appearing for the first time; runs whose verdict changed and in which direction; runs `provisional` there and report-backed here; claims a report now calls refuted or a kill-criterion hit. Report-backed rows only. No previous digest → state that this is the first digest and omit the section.

### Step 5: Gather the surrounding context

- **Plan-tree changes in the period**: plans whose `updated` (or `finalized:`) falls in the window — created, revised, decomposed, finalized. The scan's plan frontmatter is the whole input; do not diff bodies.
- **Gaps and outstanding follow-ups**: in-scope runs with no analysis report; leaves with no `exec_runs`; leaves whose EXEC_LOG has an unchecked STOP-line command; execution branches the opening call's listing shows still unmerged — their records live on the branch, possibly invisible from this checkout, so name the branch, route to `star-plan-executor <leaf>` for its merge confirmation point, and never quote a result across a branch boundary; and whether `wkdrs/results/results.md` (or the scoped `wkdrs/results/results_<slug>.md`) is older than the newest analysis report in scope.

### Step 6: Write the digest

Before drafting, read `docs/mds/star-workflow/human-writing-guide.md` (Chinese: `docs/mds/star-workflow/human-writing-guide.zh-CN.md`). Protect the covered window, source tiers, numbers, verdicts, provisional labels, commands, negative results, and plan findings; the style pass may clarify relationships but may not infer causality or soften an adverse result.

Fill `assets/digest_template.md` (Chinese: `assets/digest_template_zh.md`; the digest's language is `STAR_LANG` where it is set, else the dialogue language, else the language the in-scope plans carry when they agree) and write it to `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`. Real dates only, from the system clock (conventions §4). A second digest the same day overwrites that day's file; a later day writes its own — the directory is the timeline.

**The last covered date is only advanced by a digest that covers a period ending today.** A retrospective window (`2026-05-01`, or a plan-family digest) writes its file but leaves the series' resume point alone: set its `covers.through` to what it actually covered, so a backward-looking read never makes the next incremental run skip work. `references/scope_spec.md` states this precisely.

### Step 7: Digest & routing

≤500 words, period first: window and scope, how many runs were report-backed / provisional, the headline of what was learned, what moved since the previous digest, the top gaps. Then the routing: an unanalyzed run → `star-expt-analyst <run dir>`; a stale results table → `star-expt-analyst aggregate`; an unexecuted or awaiting leaf → `star-plan-executor <slug>`; a refuted claim or a kill-criterion hit → `star-plan-reviser <slug>`; the current state of the tree → `star-flow-status`. End with the digest path, and one line saying it is a progress record whose numbers are quoted from reports, not verified here.

### Step 8: Ledger (ledger mode only)

`ledger` runs this step alone: roll every artifact's `model_trail` into one table of who wrote what, mechanically — read, group, count, write, and no verdict from the counts. The procedure is in `references/ledger_spec.md`, read when that is the mode and not before; a digest over a period or a plan reads none of it.

## State & File Rules

- The only writes are `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md` and — in `ledger` mode only — `wkdrs/digests/MODEL_LEDGER.md`. Nothing else, anywhere — no figures, no scripts, no subdirectories.
- Never touch: `metds/plans/*` (including `exec_status`, `exec_runs`, `updated`); `wkdrs/<run>/EXEC_PLAN.md` and `EXEC_LOG.md`; any `EXPT_ANALYSIS_<date>.md` (your input, never your output); `wkdrs/results/results.md` and `wkdrs/results/results_<slug>.md` (the results table is `star-expt-analyst aggregate`'s; a digest number must never reach it); `${CODE_NAME}/`; `.env`.
- Never move, rename, or delete a run directory, log, artifact, or an older digest. An older digest is the series' history and the next run's baseline.
- Older digests are read for their frontmatter only — `covers`, `sources`, `previous`. Never rewrite one to reconcile it with what you now know.
- All commands run through `.env`'s conda env; no system python; never install or upgrade anything (conventions §3.5). This skill needs no packages beyond file reads.
- Nothing heavy: no training, no evaluation, no full-dataset passes, no costly API calls (conventions §2).
- Git: read-only; this skill never commits (conventions §1). Under `wkdrs/` only `*.md` escapes the ignore rule, so the digest series **is** versionable — it is markdown under `wkdrs/digests/`. Those files stay unstaged until the user commits them; say so if they ask about sharing.

## Dialogue Discipline

- Ask via AskQuestion only where the workflow calls for it (an ambiguous plan name, an argument that parses as neither a window nor a plan). If it is unavailable (headless / scripted), fall back to plain text and require an explicit answer. Since the skill writes nothing outside its own digest, there is no confirmation point — but for the same reason, never state or imply that you changed a plan, a status, a report, or the results table.
- Never present a provisional number as a result in chat either. If the digest tagged it unverified, the reply says so too.
- Reply in the language the paragraph at the top of this file resolved — `STAR_LANG` where it is set, the dialogue otherwise — and load the `*_zh.md` resources when that language is Chinese. This run is forked: its reply reaches the user through whatever invoked it, which changes nothing about the language it is written in. Keep technical terms — metric names, log keys, file paths, run names — in English inside Chinese digests.
- A run nobody asked for: this skill is one of the eight the agent may start unnamed (conventions §10); being picked up changes no rule above: every confirmation point holds as if the user had typed the name. Three duties: announce the start in one line, naming what matched and which scope this run took; where the scope is not settled by the files themselves, name the candidates and ask instead of starting; and close as one unit — one digest, never silently widened — leaving one line in the decisions record, `what matched → what ran → what it wrote`. "Don't start things yourself" is an instruction like any other, and holds for the rest of the session.
