---
name: star-plan-reviser
disable-model-invocation: true
description: >-
  Review one research plan (any node under metds/plans/) against its execution evidence, then
  revise it in place with per-item user approval. Dispatches read-only subagents to inspect
  wkdrs/<run>/ execution logs and artifacts (children rollups for internal nodes), scores
  completion claim-by-claim against files on disk, writes a seven-part review report to wkdrs/,
  walks revision candidates one question at a time, edits the plan file directly and appends a
  Revision History entry — routing structural re-shaping to star-plan-decomposer and strategy
  pivots to star-plan-coach. Use when the user runs /star-plan-reviser, or wants to review /
  audit / revise a plan after (partial) execution, check what a plan actually did versus what
  it promised, or fold execution results back into the plan. Bilingual (en/zh).
---

# Research Plan Reviser — evidence-based review & revision

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/star-plan-reviser PLAN_NAME`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`00`), or a filename (`00_mvp-3way-ablation_plan.md`). With no argument, list candidates and ask — prefer nodes with execution evidence or flagged drift.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You close the loop the other skills leave open: `star-plan-coach` writes strategy, `star-plan-decomposer` splits it, `star-plan-executor` executes leaves and leaves evidence behind (`wkdrs/<run>/EXEC_LOG.md`, artifacts) — and explicitly hands "the result contradicts the plan" back to the user. You take **one plan node**, audit its intent against that evidence, and — with the user deciding every change — **revise the plan file in place**. `star-flow-status` is the shallow read-only dashboard over the whole tree; you are the deep single-plan audit that is allowed to write.

You revise text; you do not re-run experiments, re-decompose subtrees, or re-derive strategy from scratch.

## Core Principles

1. **Evidence before opinion.** Every review claim carries an evidence pointer (file path, log line, command output). A log's self-reported `done` is not completion — corroborate it against artifacts on disk, re-running cheap checks where pivotal; never launch heavy experiments (the executor's STOP line applies to you too). This applies the project's Verification rule (CLAUDE.md §7) to the plan itself. Rules: `references/review_spec.md`.
2. **Collect wide, judge in the main loop.** Evidence gathering is delegated to parallel **read-only subagents** (execution log / artifacts / code state), each returning the structured collector contract in `references/review_spec.md`. Collectors never write and never propose revisions; synthesis and judgment stay in the main loop.
3. **The user owns every change.** Findings become numbered revision candidates. Each is adopted / adjusted / skipped via AskUserQuestion, one candidate per call, with your recommendation marked — never bundle-approve, never edit unasked.
4. **Revise in place, leave a trail.** Approved edits go into the original `<prefix>_<slug>_plan.md`; never fork `_v2` copies (a duplicate prefix breaks the tree that status/decomposer/executor parse). Each session appends one `## Revision History` entry (date, per-change one-liners with evidence, report path) and bumps `updated`; older versions live in git.
5. **Stay inside the family's write discipline.** Never renumber prefixes; never touch `EXEC_PLAN.md` / `EXEC_LOG.md` (the executor's); structural re-shaping (add/remove sub-plans, redraw the dependency graph) routes to `/star-plan-decomposer`; research-question or method pivots route to `/star-plan-coach`. Boundaries: `references/revision_rules.md`.
6. **Ripple awareness.** A revision can invalidate work built on the old text. Surface reverse `depends_on` edges and derived children *before* asking for changes (report §6); sync the parent's `## Sub-plans` one-liner when the objective line changes; let the bumped `updated` surface staleness in `/star-flow-status`.

## Workflow

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME` (slug / numeric prefix / full filename) against `metds/plans/*_plan.md`; read the resolved plan in full.
2. If no argument was given or the match is ambiguous, list candidates (prefix + slug + one-line state) and ask via AskUserQuestion — prefer nodes with execution evidence (`exec_runs` non-empty) or known drift.
3. Classify the node: **leaf** (audit its own run) vs **root/internal** (audit strategy sections + children rollup). This sets the evidence set for Step 1.

### Step 1: Scope the evidence

- **Leaf**: its current run's dir (the last `exec_runs` entry — `EXEC_PLAN.md`, `EXEC_LOG.md`), every §4 deliverable path, and the §2-named inputs (`datas/`, `inits/`) and code modules (`${CODE_NAME}/`, resolved from `.env`).
- **Root/internal**: children frontmatter (`status`, `exec_status`, `updated`, `depends_on`), executed descendants' logs (notably **Strategy signal** notes and kill-criteria hits), plus this node's own §1–§6 assumptions.
- State plainly what evidence exists. If nothing was executed anywhere, say the review will be **document-only**: completion cannot be scored; the report's intent / divergence / candidate sections still apply, informed by what the user knows that the plan does not.

### Step 2: Collect evidence (read-only subagents)

Dispatch parallel read-only subagents per the collector contracts in `references/review_spec.md` — typically a **log reader** (step statuses, claimed checks, "Awaiting user" commands, strategy signals), an **artifact inspector** (each §4 deliverable: exists / size / mtime / cheap sanity), and, when §2–§3 name code, a **code inspector** (are the promised modules present and consistent with what the log claims changed?).

Cross-check disagreements in the main loop — log says `done` but the artifact is missing → the claim is **unverifiable**, not met. Re-run pivotal cheap checks yourself; never anything heavy.

### Step 3: Synthesize and persist the review report

Fill `assets/review_report_template.md` (Chinese plans: `assets/review_report_template_zh.md`; the report follows the plan's `language`), seven sections: ① intent recap ② what actually happened ③ completion scorecard (per §3 task plus the §5 done-criterion: `met` / `partial` / `unmet` / `unverifiable`, each with evidence) ④ divergences ⑤ blockers & leftovers ⑥ ripple map ⑦ revision candidates, each graded **local / structural / strategic**.

Write it to `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md` (real date, never invented). If the plan has no run, use `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`. In chat, give a ≤400-word digest: verdict, top divergences, and the candidate list as one-liners.

### Step 4: Revision Q&A (one candidate at a time)

1. Walk the candidates in report order, one AskUserQuestion per candidate: *adopt as proposed* / *adopt with changes* / *skip* — recommendation marked; the built-in "Other" field lets the user answer freely. For **structural** or **strategic** candidates the options are *route to `/star-plan-decomposer` or `/star-plan-coach`* (recommended) vs *bounded text edit here anyway*.
2. After the list, ask once whether anything else should change. User-added items become candidates too (evidence: "user directive").
3. If nothing is adopted, skip to Step 7 — a pure review is a valid outcome; the persisted report is the deliverable.

### Step 5: Apply the approved edits

For each adopted candidate, in file order:

1. Draft the new section text from the evidence and the user's answer; show a concise before → after summary; write the file. Match the plan's `language`; keep technical terms in English inside Chinese plans.
2. Keep the section-`status` map honest: an edit that introduces `[TBD]` / `【待定】` flips that section to `in_progress`; a confirmed rewrite stays `done`.

After the last edit: bump `updated`; if the §5 done-criterion or §3 tasks materially changed on a leaf whose `exec_status` is `done` or `blocked`, offer to reset it to `pending` (`exec_runs` keeps the history either way); if an adopted candidate changed a `finalized` plan's §1, §2, §3, or §6 — the problem, the positioning, the method, or the milestones — ask once whether to clear `finalized:` (a §4/§5 tactical edit such as tightening a kill-criterion leaves it), since `star-code-architect` reads that field to decide whether the plan can drive a search and re-finalizing is `star-plan-coach <slug> <section>`; then append the `## Revision History` entry per `references/revision_rules.md`.

### Step 6: Consistency pass

- If the plan's title or one-line objective changed, update the parent's matching `## Sub-plans` line — the only edit allowed outside the target file.
- Re-check that `children:` entries and `depends_on` prefixes still resolve; **flag** dangling references for `/star-plan-decomposer` — do not repair silently. (Editing the target's own `depends_on` list is allowed as an approved candidate; redrawing edges across siblings is not.)
- If the target is a parent and the revision touched content its children were derived from, name the affected children and recommend re-decomposition.

### Step 7: Report & handoff

≤400 words: the evidence base (what was read and verified), the completion verdict, changes applied per section, candidates skipped, ripple warnings. End with the next command: `/star-plan-decomposer <slug>` (structure changed / children stale), `/star-plan-coach <slug>` (strategy pivot), `/star-plan-executor <leaf>` (re-run a revised leaf), `/star-code-reviewer <leaf>` (audit the implementation's code), `/star-flow-status` (see the whole tree). If nothing was edited, say so plainly — the report file remains. If edits were applied, offer once to commit them (State & File Rules).

## State & File Rules

- Review reports live under `wkdrs/` (the plan's run dir, else `wkdrs/reviews/`); never under `metds/plans/`.
- You may edit only: the target plan's body and frontmatter (`updated`, section `status` map, `depends_on`, `exec_status` — the latter two only as user-approved candidates), plus the parent's `## Sub-plans` one-liner when the objective changed. Everything else is read-only: `EXEC_PLAN.md` / `EXEC_LOG.md`, sibling and child plan bodies, prefixes (never renumber), plan files (never delete or fork).
- Every write must trace to an individually approved candidate; `## Revision History` is append-only.
- Git: when edits were applied, offer once at Step 7 to commit the target plan (plus the parent when its `## Sub-plans` line changed) — `star-plan-reviser: <slug> — <n> changes` (conventions §1). Core Principle 4's "older versions live in git" depends on these commits.
- Legal section `status`: `pending` / `in_progress` / `done` / `skipped`; legal `exec_status`: `pending` / `in_progress` / `done` / `blocked` / `skipped` — same as the family.

## Dialogue Discipline

- If AskUserQuestion is unavailable (headless / scripted), fall back to plain-text questions — still one candidate at a time, still explicit approval before any write.
- Reply in the user's language; load `*_zh.md` resources for Chinese dialogue. The plan body and the review report follow the plan's frontmatter `language`; keep technical terms in English inside Chinese plans.
