---
name: star-expt-digest
description: >-
  Summarize experiment progress since last time — the periodic digest a progress report is written
  from, in date order. No argument resumes from the last digest; a PLAN_NAME covers that node's whole
  family — ancestors for context, descendants for evidence; `<N>d` or a date covers a window; `all`
  covers everything. Collects each run's newest EXPT_ANALYSIS report, tabulates verdicts and headline
  metrics with provenance, derives what moved since then, gathers plan-level findings and kill-criteria
  hits, notes plans created or revised, lists gaps. A run with no analysis report is read raw for a
  provisional line only — never scored, never quoted as a result. Writes one dated digest to
  wkdrs/digests/. Read-only otherwise: never edits plans, exec_status, logs, or the results table, and
  never re-runs an experiment. Use when the user invokes star-expt-digest or a run names it next.
  Supports bilingual English/Chinese work.
---

# Research Experiment Digest

Match the user's language. `.env`'s `STAR_LANG` replaces it wherever it is set (conventions §7.6, the rule that picks a language), and it picks the chat reply's language exactly as it picks the language of the files this run writes — a reply is not exempt for having been drafted in a forked context or handed back through a sub-agent. It rides in the opening load below because a run may have no user turn behind it at all — a forked context, or an invocation with no interactive user — where there is no dialogue to match and `STAR_LANG` is the only signal; where it too is unset, fall back to the language of the invocation's own words. For Chinese, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Any other language loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `star-expt-digest [PLAN_NAME | <N>d | <YYYY-MM-DD> | all | ledger] [DESCRIPTION]` — no argument resumes from the newest digest's `covers.through`, covering everything after it; a plan name (slug / numeric prefix / filename) covers that node's family, time-unbounded; `7d` or `2026-07-01` sets an explicit window; `all` covers the whole history and restarts the series; `ledger` writes a different artifact — the combined table of which model wrote what at `wkdrs/digests/MODEL_LEDGER.md` (Step 8). Anything left is a description (conventions §7.12): in your own words, what this run is for. Prose naming no mode and resolving to no plan is description alone, not a missing argument — resume from `covers.through` as with no argument, and say so before writing anything. A lone token parsing as neither a window nor a plan is not a description; it stays the ambiguity this skill asks about. A description can steer what the digest highlights; it never widens or narrows the window the argument set.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What a digest acts on — §0 vocabulary (it defines the last covered date, plan-level findings, and the kill- and done-criteria this skill reports on), §3 `.env` runtime, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table — arrives through the opening load below. Six sections stay out, each because this skill's own files carry what it needs at the point of use: §1 git (it never commits — State & File Rules, with the `wkdrs/*.md` ignore nuance the user gets told about), §2 the STOP line (it runs nothing — Core Principle 6 and `references/digest_rubric.md` bound that, and an "Awaiting user" command is relayed from a log heading, never judged), §4 real dates (Step 6, and the scan prints the clock value itself), §9 project layout (State & File Rules enumerate what it may write more strictly than §9 states it), and §10 the skill roster (whether this run may start unasked is settled before this file opens; the duties such a run carries are restated in Dialogue Discipline) — and §11 execution branches (an unmerged branch is only ever a line in this skill's gaps: the listing in the opening call carries it, and a digest neither merges nor discards anything). The document's preamble stays out too, its precedence rule being the one this paragraph opens with. Read the whole file if a run ever needs one of them.

Before acting, load this skill's unconditional opening reads in one message — the opening load that later text points back at: three shell calls, with the project root as the working directory, plus a file read of `<this skill's directory>/references/scope_spec.md`, all sent together.

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
git branch --list '[0-9]*_*' 2>/dev/null   # execution branches with unmerged runs — the gaps line reads this listing
awk '/^## /{k=/^## (0|3|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
bash <this skill's directory>/scripts/scan.sh
```

One message, four results: the `.env` lookup and the first half of the conventions from the first call, the rest of them from the second, the collector's digest from the third (what it prints and why: the Workflow section), and the scope spec Step 0 interprets the argument by from its own file read. The three shell calls stay separate because each tool result carries its own size limit: a result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid — and the conventions excerpt is about 31 KB in total, split 13 and 18 across its two calls, where the whole of it in one result would now be past that line before the scan's digest took its share. Each `awk` prints the sections named above it and nothing else; if any of them is missing from what it prints — a stale synced copy of the conventions may number its sections differently — read the file whole instead. In `ledger` mode drop the scope-spec file read and run `bash <this skill's directory>/scripts/scan.sh --trails` instead — Step 8 resolves no window, so the scope spec goes unused there; the Workflow section says what `--trails` adds and drops. Everything else stays lazy: `references/digest_rubric.md` when Steps 2–3 apply the tier rules, the `assets/` templates when Step 6 or Step 8 writes, and the scan's second `--bodies` call only after Step 1 has named the in-scope runs — the Workflow section says why it cannot come earlier.

**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the `.env` lookup's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

Serve as the family's timekeeper. `star-expt-analyst` answers *did this run meet its plan*; its `aggregate` mode answers *what are the final numbers, organised by claim* and owns the verified results table `wkdrs/results/results.md`; `star-flow-status` answers *where does everything stand right now* — a snapshot with no memory. This skill answers what none of them can: **what has happened since last time, and what did we learn.**

The product is a dated digest — what a researcher reads back before a supervisor meeting, a weekly report, or picking work up after two weeks away. It carries narrative the results table is forbidden to carry: what moved, what got refuted, which direction changed. It is not a results table, and never the source anyone quotes a number from.

Read and narrate; do not execute, analyze runs, score criteria, revise plans, or flip status. Route anything found beyond what it may write: an unanalyzed run to `star-expt-analyst`, a stale results table to `star-expt-analyst aggregate`, an unexecuted leaf to `star-plan-executor`, a refuted claim to `star-plan-reviser`, the current state of the tree to `star-flow-status`.

## Core Principles

1. **The period is defined before anything is read, and it is written down.** Every digest states its mode, scope, and exact window, and names the digest it continues from. The last covered date is read from that file's `covers.through` — never from file mtimes, never from memory of a previous session. Rules: `references/scope_spec.md`.
2. **Two tiers of evidence, never merged.** A run with an `EXPT_ANALYSIS_<date>.md` is **report-backed**: its numbers and verdict are quoted from that report with its date. A run without one is **provisional**: its EXEC_LOG is read raw for a rough line, tagged `provisional (unverified)`. The tiers never share a table; a provisional number is never scored, never used in a delta, never quoted as a result. Rules: `references/digest_rubric.md`.
3. **Report-level, not re-verified — and the digest says so.** Unlike `aggregate`, do not re-open each cited source to confirm a number. Copy it with its provenance (`{value, source, report date}`) so a reader can. Every digest states in its own words that it is a progress record and that verified numbers live in `wkdrs/results/results.md`. Quoting a digest number into a paper is a misuse the file itself warns against.
4. **What moved is the point.** A digest that only lists runs is a worse `star-flow-status`. The value is the comparison against the previous digest's `sources:` — new runs, verdicts that changed, runs provisional last time and analyzed now, claims that got refuted. With no previous digest, say the series starts here and skip the section rather than inventing movement.
5. **Narrative is allowed; causal attribution is not.** Write what was learned, what a negative result suggests, and where the work turned. Never say *why* one variant beat another — that needs a controlled comparison no skill in this family runs (`aggregate_spec.md`'s rule, binding here too). Report the direction and who to ask: `star-expt-analyst <run>` for the interpretation, `star-plan-reviser` for what it means for the plan.
6. **Strictly read-only outside this skill's own file; the STOP line applies.** Only `wkdrs/digests/EXPT_DIGEST_<date>.md` is written. Never touch plans, `exec_status`, `EXEC_PLAN.md`, `EXEC_LOG.md`, any `EXPT_ANALYSIS` report, or the results table `wkdrs/results/*`. Never re-run training, evaluation, or a costly call to fill a gap — an unmeasured thing is a listed gap with a routing command, not a task to take on.

## Workflow

**Scan first, then scan the window.** The collector `scripts/scan.sh` runs in the opening load (the **Shared conventions** paragraph) — do not run it again. In one call it prints what Steps 0, 1, 3 and 5 would otherwise open file by file: every plan's and every listed artifact's frontmatter; every run log's frontmatter, step table, awaiting-user checkboxes, plan-level findings and dates; and a depth-1 listing of `metds/` and `wkdrs/` with the dates in the filenames. In `ledger` mode the opening load runs `scripts/scan.sh --trails` instead: Step 8 needs every `model_trail` entry, each plan's `## Revision History`, and the header-line `model_id` of files carrying no frontmatter, none of which the default mode prints. That mode also drops what a provenance read has no use for — the sub-plans index, the placeholder counts, the per-run dates line and DIRS — and never caps the trail: a ledger with a hole is worse than a long one.

The script gathers, never judges: it knows nothing about windows, last covered dates, tiers, or which filenames the output table expects, so every rule stays in this file and in `references/scope_spec.md` (arrived with the opening load). Read what it prints as raw file content; do not re-open a file it already covered. Two things earn a second read: a passage you must quote rather than count, and a file the scan lists as present but does not print — an artifact carrying no frontmatter is listed, never dumped, so never covered.

**Step 2's report bodies come from a second call, after Step 1 has named the in-scope runs**: `--bodies 2,3,7 --runs <those run directories>` adds each report's Verdict, Done-Criteria Scorecard and Interpretation sections, for those runs only. Never pass `--bodies` on the first call: the window is not resolved until Step 0 and not applied until Step 1, so `--bodies` before then prints every report in the project's history — about 180 lines per run, in scope or not. Where every run is in the window, that costs nothing; on `star-expt-digest 7d` against a year of work it reads the whole year to report a week. Two calls is cheaper than either mistake. Those three numbers are this skill's rule, stated in `references/digest_rubric.md`, not the script's — the script prints the numbered sections it is handed, so a renumbered report is a one-line change in the rubric. If the script is missing or fails, read the files directly and say in your report that the scan fell back. If you cannot resolve this skill's own directory, any copy in the repository will do — every `scripts/scan.sh` is byte-identical and CI enforces that: `bash "$(find . -path '*/skills/*/scripts/scan.sh' | head -1)"`.

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
- Never touch: `metds/plans/*` (including `exec_status`, `exec_runs`, `updated`); `wkdrs/<run>/EXEC_PLAN.md` and `EXEC_LOG.md`; any `EXPT_ANALYSIS_<date>.md` (this skill's input, never its output); `wkdrs/results/results.md` and `wkdrs/results/results_<slug>.md` (the results table is `star-expt-analyst aggregate`'s; a digest number must never reach it); `${CODE_NAME}/`; `.env`.
- Never move, rename, or delete a run directory, log, artifact, or an older digest. An older digest is the series' history and the next run's baseline.
- Older digests are read for their frontmatter only — `covers`, `sources`, `previous`. Never rewrite one to reconcile it with what is now known.
- All commands run through `.env`'s conda env; no system python; never install or upgrade anything (conventions §3.5). This skill needs no packages beyond file reads.
- Nothing heavy: no training, no evaluation, no full-dataset passes, no costly API calls (conventions §2).
- Git: read-only; never commit (conventions §1). Under `wkdrs/` only `*.md` escapes the ignore rule, so the digest series **is** versionable — it is markdown under `wkdrs/digests/`. Those files stay unstaged until the user commits them; say so if they ask about sharing.

## Dialogue Discipline

- Ask one direct question at a time where the workflow calls for it (an ambiguous plan name, an argument that parses as neither a window nor a plan) and require an explicit answer. Since the skill writes nothing outside its own digest, there is no confirmation point — but for the same reason, never state or imply that a plan, a status, a report, or the results table was changed.
- Never present a provisional number as a result in chat either. If the digest tagged it unverified, the reply says so too. Keep technical terms — metric names, log keys, file paths, run names — in English inside Chinese digests.
- A run nobody asked for: this skill is one of the eight the agent may start unnamed (conventions §10); being picked up changes no rule above: every confirmation point holds as if the user had typed the name. Three duties: announce the start in one line, naming what matched and which scope this run took; where the scope is not settled by the files themselves, name the candidates and ask instead of starting; and close as one unit — one digest, never silently widened — leaving one line in the decisions record, `what matched → what ran → what it wrote`. "Don't start things yourself" is an instruction like any other, and holds for the rest of the session.
