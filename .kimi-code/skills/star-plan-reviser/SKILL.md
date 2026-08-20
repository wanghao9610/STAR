---
name: star-plan-reviser
disable-model-invocation: true
description: >-
  Review one research plan (any node under metds/plans/) against its execution evidence, then
  revise it in place with per-item user approval. Dispatches read-only subagents to inspect
  wkdrs/<run>/ execution logs and artifacts (a summary of the children for internal nodes), scores
  completion claim-by-claim against files on disk, writes a seven-part review report to wkdrs/,
  settles the revision candidates in one question over the whole list, edits the plan file directly and appends a
  Revision History entry — routing structural re-shaping to star-plan-decomposer and strategy
  pivots to star-plan-coach. Use when the user runs /skill:star-plan-reviser, or wants to review /
  audit / revise a plan after (partial) execution, check what a plan actually did versus what
  it promised, fold execution results back into the plan, or drop a plan and its subtree
  as a direction given up. Bilingual (en/zh).
---

# Research Plan Reviser — evidence-based review & revision

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/skill:star-plan-reviser PLAN_NAME [DESCRIPTION]`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`01`), or a filename (`01_mvp-verify_plan.md`). With no argument, list candidates and ask. Anything after the plan name is a description (conventions §7.12): what this session is for, in your own words. One giving the direction up — "this one is finished, 02 replaces it" — takes the drop path (the Workflow's last section) instead of the review, its own words becoming the reason written into the plan; one asking for a dropped node back clears the field. There are no keywords: a description that says neither runs the review, as does no description at all. An optional `involve=low|medium|high` token may accompany any argument (e.g. `… involve=low`): it sets this run's `involve` level (conventions §7.7) and is stripped before the argument and the description are read.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What a plan revision acts on — §0 vocabulary, §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §10 the skill roster, §11 execution branches — arrives through the opening load below. One section stays out: §9 the project layout — every path this skill reads or writes, its own State & File Rules already name. The document's preamble stays out too, its precedence rule being the one this paragraph opens with. Read the whole file if a run ever needs one of them.

Before acting, load it in one message — four Bash calls with the project root as the working directory, plus two `Read` calls, `<this skill's directory>/references/review_spec.md` and `<this skill's directory>/references/revision_rules.md`, each whole file as its own call — sent together.

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
awk '/^## /{k=/^## (0|1|2|3|4|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (10|11)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
bash <this skill's directory>/scripts/scan.sh --slim
```

One message, six results: the conventions from the first three Bash calls with the `.env` line riding the first, `references/review_spec.md` (evidence sources, collector formats, the report's section definitions) and `references/revision_rules.md` (the authority table, the routing boundaries, the Revision History entry format), each from its own `Read`, and the shared collector's digest from the last call. The calls stay separate because each tool result carries its own size limit: a result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid — and the conventions excerpt is about 49 KB in total, split 20, 18 and 12 across its three calls, while each `Read` result arrives whole on its own budget; the collector's call stays on its own because its digest is the one part that grows with the history — written out, it is re-run alone. Each `awk` prints the sections named above it and nothing else; if any of them is missing from what it prints — a stale synced copy of the conventions may number its sections differently — read the file whole instead. The collector's digest is what Step 0 resolves against and what Step 1 scopes from — every plan's frontmatter (`parent:`, `children:`, `depends_on`, `status`, `exec_status`, `exec_runs`, `updated`), its `## Sub-plans` index, and every run log's frontmatter — so neither the target's siblings nor the children of an internal node are opened one at a time. It gathers, it never judges: no tree, no verdict, no ordering; read what it prints as raw file content, exactly as if you had opened each plan yourself. `--slim` keeps it under the tool-result size limit on a project with history. If the script is missing or fails, fall back to reading `metds/plans/*_plan.md` directly and say in your reply that the scan fell back. Both references govern the session from the first evidence step to the last edit, which is why they arrive here rather than mid-workflow; wherever later text cites either one, its content is already in hand from this message — do not re-open it. The report template under `assets/` stays out of the message: which variant to fill follows the plan's `language`, known only once Step 0 has resolved the target plan.

**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the `.env` lookup's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

You close the loop the other skills leave open: `star-plan-coach` writes strategy, `star-plan-decomposer` splits it, `star-plan-executor` executes leaves, leaving evidence (`wkdrs/<run>/EXEC_LOG.md`, artifacts) — and explicitly hands "the result contradicts the plan" back to the user. You take **one plan node**, audit its intent against that evidence, and — with the user deciding every change — **revise the plan file in place**. `star-flow-status` is the shallow read-only dashboard over the whole tree; you are the deep single-plan audit allowed to write.

You revise text; you do not re-run experiments, re-decompose subtrees, or re-derive strategy from scratch.

## Core Principles

1. **Evidence before opinion.** Every review claim carries an evidence pointer (file path, log line, command output). A log's self-reported `done` is not completion — corroborate it against artifacts on disk, re-running cheap checks where pivotal; never launch heavy experiments (the executor's STOP line applies to you too). This applies the project's Verification rule (AGENTS.md §11) to the plan itself. Rules: `references/review_spec.md`.
2. **Collect wide, judge in the main agent.** Evidence gathering is delegated to parallel **read-only `Agent` subagents** (`subagent_type: explore`) (execution log / artifacts / code state), each returning the structured collector format in `references/review_spec.md`. Collectors never write and never propose revisions; synthesis and judgment stay in the main agent.
3. **The user owns every change.** Findings become numbered revision candidates. The whole list goes on the page, and **one** AskUserQuestion over it settles them — recommendation marked, with every candidate the user names coming back on its own (conventions §7.13). Never put a list up for approval that the user cannot see, never edit unasked.
4. **Revise in place, leave a trail.** Approved edits go into the original `<prefix>_<slug>_plan.md`; never fork `_v2` copies (a duplicate prefix breaks the tree status/decomposer/executor parse). Each session appends one `## Revision History` entry (date, per-change one-liners with evidence, report path) and bumps `updated`; older versions live in git.
5. **Stay inside the family's write discipline.** Never renumber prefixes; never touch `EXEC_PLAN.md` / `EXEC_LOG.md` (the executor's); structural re-shaping (add/remove sub-plans, redraw the dependency graph) routes to `/skill:star-plan-decomposer`, research-question or method pivots to `/skill:star-plan-coach`. Boundaries: `references/revision_rules.md`.
6. **Knock-on effects.** A revision can invalidate work built on the old text. Point out reverse `depends_on` edges and derived children *before* asking for changes (report §6); sync the parent's `## Sub-plans` one-liner when the objective line changes; let the bumped `updated` show staleness in `/skill:star-flow-status`.

## Workflow

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME` (slug / numeric prefix / full filename) against the plans the opening load's digest lists; read the resolved plan in full.
2. With no argument, or an ambiguous match, list candidates (prefix + slug + one-line state) and ask via AskUserQuestion — prefer nodes with execution evidence (`exec_runs` non-empty) or known drift.
3. Classify the node: **leaf** (audit its own run) vs **root/internal** (audit strategy sections + a summary of the children) — this sets Step 1's evidence set.

### Step 1: Scope the evidence

- **Leaf**: its current run's dir (the last `exec_runs` entry — `EXEC_PLAN.md`, `EXEC_LOG.md`), every §4 deliverable path, the §2-named inputs (`datas/`, `inits/`) and code modules (`${CODE_NAME}/`, from `.env`).
- **Root/internal**: children frontmatter (`status`, `exec_status`, `updated`, `depends_on`) from the digest, executed descendants' logs (notably **Plan-level finding** notes and kill-criteria hits), plus this node's own §1–§6 assumptions.
- State plainly what evidence exists. If nothing was executed anywhere, say the review is **document-only**: completion cannot be scored; the report's intent / divergence / candidate sections still apply, informed by what the user knows that the plan does not.

### Step 2: Collect evidence (read-only subagents)

**Small evidence set** — one run, ≤ ~5 steps, ≤ ~3 deliverable paths, no code modules named in §2–§3 — is usually simplest read in the main agent itself: `EXEC_PLAN.md`, `EXEC_LOG.md`, and a stat per deliverable. Three collectors at that size is the case conventions §6.1 rules out.

Larger than that: dispatch parallel read-only `Agent` subagents (`subagent_type: explore`) per the collector formats in `references/review_spec.md` — typically a **log reader** (step statuses, claimed checks, "Awaiting user" commands, plan-level findings), an **artifact inspector** (each §4 deliverable: exists / size / mtime / cheap sanity), and, when §2–§3 name code, a **code inspector** (are the promised modules present and consistent with what the log claims changed?).

Cross-check disagreements in the main agent — log says `done` but the artifact is missing → the claim is **unverifiable**, not met. Re-run pivotal cheap checks yourself; never anything heavy.

A collector's `suspect` or `inconsistent` is a lead, not a finding. Before it becomes a numbered revision candidate, the main agent opens the cited path itself and confirms the finding still holds (conventions §6.6); the candidate then carries that `path[:line]` as its evidence. What does not hold up is dropped, or demoted to a §5 note that changes nothing.

### Step 3: Synthesize and persist the review report

Fill `assets/review_report_template.md` (Chinese plans: `assets/review_report_template_zh.md`), seven sections: ① intent recap ② what actually happened ③ completion scorecard (per §3 task plus the §5 done-criterion: `met` / `partial` / `unmet` / `unverifiable`, each with evidence) ④ divergences ⑤ blockers & leftovers ⑥ knock-on effects ⑦ revision candidates, each graded **local / structural / strategic**.

Write it to `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md` (real date, never invented). If the plan has no run, use `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`. In chat, give a ≤500-word digest: verdict, top divergences, and the candidate list as one-liners.

### Step 4: Revision Q&A (the whole list, then one question)

1. Put every candidate on the page first, in the text of the message carrying the question (conventions §7.13 — a drafted list is one question, not one per row): one numbered row per candidate, with the section it changes, from what to what, its evidence path, its grade (local / structural / strategic), and the action you recommend. A **structural** or **strategic** row recommends routing it — `/skill:star-plan-decomposer` for shape, `/skill:star-plan-coach` for strategy — and names a bounded text edit here as the alternative.
2. Then **one** AskUserQuestion over that list: *adopt all as listed* / *adopt all but the ones I name* / *answer my questions on the ones I name first* / *adopt none* — recommendation marked, and the built-in "Other" field lets the user answer freely. With four candidates or fewer, ask over the candidates themselves (multi_select), not their numbers. Rows the user pulls out open a second round in the same shape, carrying the redraft or the answer they asked for; a round down to one candidate is asked as that one candidate. A candidate that drops this node is never a row on the list — `references/revision_rules.md` has it asked on its own — and Step 5's `exec_status` reset and `finalized:` clearing are questions of their own there, after the edits.
3. Keep the running record as you go (conventions §7.8) — one line per candidate as it settles, `candidate → adopted / adjusted / skipped → what changed in the file` — and open each later round with what the earlier ones settled, in one clause (§7.10). The record is what carries a decision across rounds, so the third round does not re-argue the first.
4. Once the list is settled, ask once whether anything else should change. User-added items become candidates too (evidence: "user directive").
5. If nothing is adopted, skip to Step 7 — a pure review is a valid outcome; the persisted report is the deliverable.

### Step 5: Apply the approved edits

For each adopted candidate, in file order:

1. Draft the new section text from the evidence and the user's answer; show a concise before → after summary; write the file.
2. Keep the section-`status` map honest: an edit that introduces `[TBD]` / `【待定】` flips that section to `in_progress`; a confirmed rewrite stays `done`.

After the last edit: bump `updated`; if the §5 done-criterion or §3 tasks materially changed on a leaf whose `exec_status` is `done` or `blocked`, offer to reset it to `pending` (`exec_runs` keeps the history either way); if an adopted candidate changed a `finalized` plan's §1, §2, §3, or §6 — problem, positioning, method, milestones — ask once whether to clear `finalized:` (a §4/§5 tactical edit such as tightening a kill-criterion leaves it), since `star-code-architect` reads that field to decide whether the plan can drive a search and re-finalizing is `star-plan-coach <slug> <section>`; if an adopted candidate drops this node, write `dropped:` here and the `— dropped <date>` marker on the parent's index line, and nothing else — the subtree follows by inheritance; then append the `## Revision History` entry per `references/revision_rules.md`.

### Step 6: Consistency pass

- If the plan's title or one-line objective changed, update the parent's matching `## Sub-plans` line — the only edit allowed outside the target file.
- Re-check that `children:` entries and `depends_on` prefixes still resolve; **flag** dangling references for `/skill:star-plan-decomposer` — do not repair silently. (Editing the target's own `depends_on` list is allowed as an approved candidate; redrawing edges across siblings is not.)
- If the target is a parent and the revision touched content its children were derived from, name the affected children and recommend re-decomposition.

### Step 7: Report & handoff

≤500 words: the evidence base (what was read and verified), the completion verdict, changes applied per section, candidates skipped, knock-on effects to watch. End with the next command: `/skill:star-plan-decomposer <slug>` (structure changed / children stale), `/skill:star-plan-coach <slug>` (strategy pivot), `/skill:star-plan-executor <leaf>` (re-run a revised leaf), `/skill:star-code-reviewer <leaf>` (audit the implementation's code), `/skill:star-flow-status` (see the whole tree). If nothing was edited, say so plainly — the report file remains. If edits were applied, offer once to commit them (State & File Rules).

### Dropping a plan, and taking one back

This path replaces Steps 1–6 with four steps of its own — read what goes dark, ask once, write the three places, report — and its rules, including where `dropped:` is written and what inheritance does to the descendants, are in `references/drop_rules.md`, read where the run is a drop or a revival and not before. A review run reads none of it.

## State & File Rules

- Review reports live under `wkdrs/`, never under `metds/plans/`.
- You may edit only: the target plan's body and frontmatter (`updated`, section `status` map, `depends_on`, `exec_status`, `dropped:` — the last three only as user-approved candidates), plus the parent's `## Sub-plans` one-liner when the objective changed or its drop marker goes on. Everything else is read-only: `EXEC_PLAN.md` / `EXEC_LOG.md`, sibling and child plan bodies, prefixes (never renumber), plan files (never delete or fork).
- Every write must trace to an individually approved candidate; `## Revision History` is append-only.
- Git: when edits were applied, offer once at Step 7 to commit the target plan (plus the parent when its `## Sub-plans` line changed) — `star-plan-reviser: <slug> — <n> changes` (conventions §1). Core Principle 4's "older versions live in git" depends on these commits.
- Legal section `status`: `pending` / `in_progress` / `done` / `skipped`; legal `exec_status`: `pending` / `in_progress` / `done` / `blocked` / `abandoned` — same as the family. Setting `abandoned` is a revision candidate like any other: it needs the user's explicit approval, with the reason in the Revision History entry. `dropped:` is a date-plus-reason line written on this node alone — every skill reads it as inherited by the whole subtree — set or cleared only through the drop rule in `references/revision_rules.md`.

## Dialogue Discipline

- If AskUserQuestion is unavailable (non-interactive `kimi -p`, no human to answer), fall back to plain-text questions — still the whole candidate list on the page before the one question that settles it, still explicit approval before any write.
- **The candidate list goes in the text of the same message, above the call** — the options carry the answers and none of the material.
- Reply in the user's language; load `*_zh.md` resources for Chinese dialogue. The plan body and the review report follow the plan's frontmatter `language`; keep technical terms in English inside Chinese plans.
