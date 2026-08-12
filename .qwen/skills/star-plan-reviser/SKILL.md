---
name: star-plan-reviser
disable-model-invocation: true
argument-hint: "[PLAN_NAME] [DESCRIPTION] [involve=high]"
description: >-
  Review one research plan (any node under metds/plans/) against its execution evidence, then
  revise it in place with per-item user approval. Dispatches read-only subagents to inspect
  wkdrs/<run>/ execution logs and artifacts (a summary of the children for internal nodes), scores
  completion claim-by-claim against files on disk, writes a seven-part review report to wkdrs/,
  goes through revision candidates one question at a time, edits the plan file directly and appends a
  Revision History entry — routing structural re-shaping to star-plan-decomposer and strategy
  pivots to star-plan-coach. Use when the user runs /star-plan-reviser, or wants to review /
  audit / revise a plan after (partial) execution, check what a plan actually did versus what
  it promised, fold execution results back into the plan, or drop a plan and its subtree
  as a direction given up. Bilingual (en/zh).
---

# Research Plan Reviser — evidence-based review & revision

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/star-plan-reviser PLAN_NAME [DESCRIPTION]`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`01`), or a filename (`01_mvp-verify_plan.md`). With no argument, list candidates and ask — prefer nodes with execution evidence or flagged drift. Anything after the plan name is a description (conventions §7.12): what this session is for, in your own words. One that gives the direction up — "this one is finished, 02 replaces it" — takes the drop path, the Workflow's last section, instead of the review, and its own words become the reason written into the plan; one that asks for a dropped node back clears the field. There are no keywords: a description that says neither runs the review, and so does no description at all. An optional `involve=low|medium|high` token may accompany any argument (e.g. `… involve=low`): it sets the `involve` level for this run (conventions §7.7), is part of neither the argument nor the description, and is stripped before either is read.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. Before acting, load it together with both of this skill's reference files in one message: three `read_file` calls — the conventions file, `<this skill's directory>/references/review_spec.md`, and `<this skill's directory>/references/revision_rules.md`, each whole file as its own call — plus one `run_shell_command` call in the same message, with the project root as the working directory, carrying only:

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
bash <this skill's directory>/scripts/scan.sh --slim
```

One message, four results: the conventions — §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout — plus `references/review_spec.md` (evidence sources, collector contracts, the report's section definitions) and `references/revision_rules.md` (the authority table, the routing boundaries, the Revision History entry format), each from its own `read_file`, and the `run_shell_command` call's two lines, which are the steps only `run_shell_command` can do: the `.env` lookup, and the shared collector. The collector's digest is what Step 0 resolves against and what Step 1 scopes from — every plan's frontmatter (`parent:`, `children:`, `depends_on`, `status`, `exec_status`, `exec_runs`, `updated`), its `## Sub-plans` index, and every run log's frontmatter — so neither the target's siblings nor the children of an internal node are opened one at a time. It gathers, it never judges: no tree, no verdict, no ordering; read what it prints as raw file content, exactly as if you had opened each plan yourself. `--slim` keeps the result clear of the spill line on a project with history; if it spills anyway, re-run that line on its own. If the script is missing or fails, fall back to reading `metds/plans/*_plan.md` directly and say in your reply that the scan fell back. Keep the three files out of the command: each tool result has its own size limit, and a `run_shell_command` result past roughly 30 KB is spilled to a file that costs a second round trip to read back — the conventions file alone is already past that limit, so `cat`-ing all three into one result would spill every time, exactly the round trip the one message exists to avoid. Both references govern the session from the first evidence step to the last edit, which is why they arrive here rather than mid-workflow; wherever later text cites either one, its content is already in hand from this message — do not re-open it. The report template under `assets/` stays out of the message: which variant to fill follows the plan's `language`, known only once Step 0 has resolved the target plan.

**Reusing an earlier load.** A second STAR skill in the same conversation does not pay for this twice. Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the probe's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again — a wasted read costs one message, a wrong assumption costs the run. What never carries over is a collector digest, where one is loaded above: it is a snapshot of files a skill run may have written to since, so the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

You close the loop the other skills leave open: `star-plan-coach` writes strategy, `star-plan-decomposer` splits it, `star-plan-executor` executes leaves and leaves evidence behind (`wkdrs/<run>/EXEC_LOG.md`, artifacts) — and explicitly hands "the result contradicts the plan" back to the user. You take **one plan node**, audit its intent against that evidence, and — with the user deciding every change — **revise the plan file in place**. `star-flow-status` is the shallow read-only dashboard over the whole tree; you are the deep single-plan audit that is allowed to write.

You revise text; you do not re-run experiments, re-decompose subtrees, or re-derive strategy from scratch.

## Core Principles

1. **Evidence before opinion.** Every review claim carries an evidence pointer (file path, log line, command output). A log's self-reported `done` is not completion — corroborate it against artifacts on disk, re-running cheap checks where pivotal; never launch heavy experiments (the executor's STOP line applies to you too). This applies the project's Verification rule (AGENTS.md §11) to the plan itself. Rules: `references/review_spec.md`.
2. **Collect wide, judge in the main agent.** Evidence gathering is delegated to parallel **read-only `agent` subagents** (`subagent_type: Explore`) (execution log / artifacts / code state), each returning the structured collector contract in `references/review_spec.md`. Collectors never write and never propose revisions; synthesis and judgment stay in the main agent.
3. **The user owns every change.** Findings become numbered revision candidates. Each is adopted / adjusted / skipped via `ask_user_question`, one candidate per call, with your recommendation marked — never bundle-approve, never edit unasked.
4. **Revise in place, leave a trail.** Approved edits go into the original `<prefix>_<slug>_plan.md`; never fork `_v2` copies (a duplicate prefix breaks the tree that status/decomposer/executor parse). Each session appends one `## Revision History` entry (date, per-change one-liners with evidence, report path) and bumps `updated`; older versions live in git.
5. **Stay inside the family's write discipline.** Never renumber prefixes; never touch `EXEC_PLAN.md` / `EXEC_LOG.md` (the executor's); structural re-shaping (add/remove sub-plans, redraw the dependency graph) routes to `/star-plan-decomposer`; research-question or method pivots route to `/star-plan-coach`. Boundaries: `references/revision_rules.md`.
6. **Knock-on effects.** A revision can invalidate work built on the old text. Point out reverse `depends_on` edges and derived children *before* asking for changes (report §6); sync the parent's `## Sub-plans` one-liner when the objective line changes; let the bumped `updated` show staleness in `/star-flow-status`.

## Workflow

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME` (slug / numeric prefix / full filename) against the plans the opening load's digest lists — the digest is the listing; read the resolved plan in full.
2. If no argument was given or the match is ambiguous, list candidates (prefix + slug + one-line state) and ask via `ask_user_question` — prefer nodes with execution evidence (`exec_runs` non-empty) or known drift.
3. Classify the node: **leaf** (audit its own run) vs **root/internal** (audit strategy sections + a summary of the children). This sets the evidence set for Step 1.

### Step 1: Scope the evidence

- **Leaf**: its current run's dir (the last `exec_runs` entry — `EXEC_PLAN.md`, `EXEC_LOG.md`), every §4 deliverable path, and the §2-named inputs (`datas/`, `inits/`) and code modules (`${CODE_NAME}/`, resolved from `.env`).
- **Root/internal**: children frontmatter (`status`, `exec_status`, `updated`, `depends_on`) — already in the digest, so take it from there — executed descendants' logs (notably **Plan-level finding** notes and kill-criteria hits), plus this node's own §1–§6 assumptions.
- State plainly what evidence exists. If nothing was executed anywhere, say the review will be **document-only**: completion cannot be scored; the report's intent / divergence / candidate sections still apply, informed by what the user knows that the plan does not.

### Step 2: Collect evidence (read-only subagents)

**Small evidence set** — one run, ≤ ~5 steps, ≤ ~3 deliverable paths, and no code modules named in §2–§3 — is usually simplest to read in the main agent itself: `EXEC_PLAN.md`, `EXEC_LOG.md`, and a stat per deliverable. Three collectors at that size is the case conventions §6.1 rules out.

Larger than that: dispatch parallel read-only `agent` subagents (`subagent_type: Explore`) per the collector contracts in `references/review_spec.md` — typically a **log reader** (step statuses, claimed checks, "Awaiting user" commands, plan-level findings), an **artifact inspector** (each §4 deliverable: exists / size / mtime / cheap sanity), and, when §2–§3 name code, a **code inspector** (are the promised modules present and consistent with what the log claims changed?).

Cross-check disagreements in the main agent — log says `done` but the artifact is missing → the claim is **unverifiable**, not met. Re-run pivotal cheap checks yourself; never anything heavy.

A collector's `suspect` or `inconsistent` is a lead, not a finding. Before it becomes a numbered revision candidate — Step 4 asks the user about each one, and the answers rewrite the plan file — the main agent opens the cited path itself and confirms the finding still holds (conventions §6.6); the candidate then carries that `path[:line]` as its evidence. What does not hold up is dropped, or demoted to a §5 note that changes nothing.

### Step 3: Synthesize and persist the review report

Fill `assets/review_report_template.md` (Chinese plans: `assets/review_report_template_zh.md`; the report follows the plan's `language`), seven sections: ① intent recap ② what actually happened ③ completion scorecard (per §3 task plus the §5 done-criterion: `met` / `partial` / `unmet` / `unverifiable`, each with evidence) ④ divergences ⑤ blockers & leftovers ⑥ knock-on effects ⑦ revision candidates, each graded **local / structural / strategic**.

Write it to `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md` (real date, never invented). If the plan has no run, use `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`. In chat, give a ≤500-word digest: verdict, top divergences, and the candidate list as one-liners.

### Step 4: Revision Q&A (one candidate at a time)

1. Walk the candidates in report order, one `ask_user_question` per candidate: *adopt as proposed* / *adopt with changes* / *skip* — recommendation marked; the built-in "Other" field lets the user answer freely. For **structural** or **strategic** candidates the options are *route to `/star-plan-decomposer` or `/star-plan-coach`* (recommended) vs *bounded text edit here anyway*. Keep the running record as you go (conventions §7.8) — one line per candidate as it settles, `candidate → adopted / adjusted / skipped → what changed in the file` — and anchor the next candidate on it in one clause whenever it interacts with one already decided (§7.10). A per-candidate walk is the longest question series in the workflow; without that record the user approves edit 9 with no view of edits 1–8.
2. After the list, ask once whether anything else should change. User-added items become candidates too (evidence: "user directive").
3. If nothing is adopted, skip to Step 7 — a pure review is a valid outcome; the persisted report is the deliverable.

### Step 5: Apply the approved edits

For each adopted candidate, in file order:

1. Draft the new section text from the evidence and the user's answer; show a concise before → after summary; write the file. Match the plan's `language`; keep technical terms in English inside Chinese plans.
2. Keep the section-`status` map honest: an edit that introduces `[TBD]` / `【待定】` flips that section to `in_progress`; a confirmed rewrite stays `done`.

After the last edit: bump `updated`; if the §5 done-criterion or §3 tasks materially changed on a leaf whose `exec_status` is `done` or `blocked`, offer to reset it to `pending` (`exec_runs` keeps the history either way); if an adopted candidate changed a `finalized` plan's §1, §2, §3, or §6 — the problem, the positioning, the method, or the milestones — ask once whether to clear `finalized:` (a §4/§5 tactical edit such as tightening a kill-criterion leaves it), since `star-code-architect` reads that field to decide whether the plan can drive a search and re-finalizing is `star-plan-coach <slug> <section>`; if an adopted candidate drops this node, write `dropped:` here and the `— dropped <date>` marker on the parent's index line, and nothing else — the subtree follows by inheritance; then append the `## Revision History` entry per `references/revision_rules.md`.

### Step 6: Consistency pass

- If the plan's title or one-line objective changed, update the parent's matching `## Sub-plans` line — the only edit allowed outside the target file.
- Re-check that `children:` entries and `depends_on` prefixes still resolve; **flag** dangling references for `/star-plan-decomposer` — do not repair silently. (Editing the target's own `depends_on` list is allowed as an approved candidate; redrawing edges across siblings is not.)
- If the target is a parent and the revision touched content its children were derived from, name the affected children and recommend re-decomposition.

### Step 7: Report & handoff

≤500 words: the evidence base (what was read and verified), the completion verdict, changes applied per section, candidates skipped, knock-on effects to watch. End with the next command: `/star-plan-decomposer <slug>` (structure changed / children stale), `/star-plan-coach <slug>` (strategy pivot), `/star-plan-executor <leaf>` (re-run a revised leaf), `/star-code-reviewer <leaf>` (audit the implementation's code), `/star-flow-status` (see the whole tree). If nothing was edited, say so plainly — the report file remains. If edits were applied, offer once to commit them (State & File Rules).

### Dropping a plan, and taking one back

A drop records a decision you have already made, so this path does not audit the plan: Step 0 resolves the target as always, the four steps below replace Steps 1–6, and Step 7 reports as always. Nothing here writes a review report. The description is what routes a run here (conventions §7.12), so say in one line which path this run took before reading anything — a misread description then costs that line rather than an edit.

1. **Read what goes dark**, from the opening digest alone — no collectors, no run bodies: every descendant of the target with its `exec_status`, the follow-ups their runs were owed (a review, an analysis), any unmerged `branch:`, live `worktree:` or un-ticked STOP command underneath, and any live leaf whose `depends_on` names the target or one of its descendants.
2. **Show that list and ask once** — one line per descendant, one line per loose end — confirming the drop and its one-line reason in the same question — the reason is the description's own words where it carried them, and asked for where it did not. This is a mandatory confirmation point (conventions §7.7): asked at every involve level, `low` included, and never bundled with anything else. No reason, no drop.
3. **Write the three places** `references/revision_rules.md` names — `dropped: <date> — <reason>` on the target, the `— dropped <date>` marker on the parent's `## Sub-plans` line, one `## Revision History` entry — and bump `updated`. No descendant is edited: they go dark by inheritance.
4. **Report** what went dark and what the drop did not settle — dependency edges now pointing at a dropped node, and any branch, worktree or STOP command still on disk — then the commit offer, as Step 7.

Taking a node back is the same walk with the field cleared instead of written — a description asking for it is what routes there — and one check before the question: no ancestor may be dropped, or inheritance keeps the node dark and the cleared field reads as a bug. Its Revision History entry says why the direction is live again.

A drop that comes up *during* a full review is not this mode — it is a Step 4 candidate, approved like any other, writing the same three places.

## State & File Rules

- Review reports live under `wkdrs/` (the plan's run dir, else `wkdrs/reviews/`); never under `metds/plans/`.
- You may edit only: the target plan's body and frontmatter (`updated`, section `status` map, `depends_on`, `exec_status`, `dropped:` — the last three only as user-approved candidates), plus the parent's `## Sub-plans` one-liner when the objective changed or its drop marker goes on. Everything else is read-only: `EXEC_PLAN.md` / `EXEC_LOG.md`, sibling and child plan bodies, prefixes (never renumber), plan files (never delete or fork).
- Every write must trace to an individually approved candidate; `## Revision History` is append-only.
- Git: when edits were applied, offer once at Step 7 to commit the target plan (plus the parent when its `## Sub-plans` line changed) — `star-plan-reviser: <slug> — <n> changes` (conventions §1). Core Principle 4's "older versions live in git" depends on these commits.
- Legal section `status`: `pending` / `in_progress` / `done` / `skipped`; legal `exec_status`: `pending` / `in_progress` / `done` / `blocked` / `abandoned` — same as the family. Setting `abandoned` is a revision candidate like any other: it needs the user's explicit approval, and the reason goes in the Revision History entry. `dropped:` is a date-plus-reason line written on this node alone — every skill reads it as inherited by the whole subtree — and it is set or cleared only through the drop rule in `references/revision_rules.md`.

## Dialogue Discipline

- If `ask_user_question` is unavailable (headless / scripted), fall back to plain-text questions — still one candidate at a time, still explicit approval before any write.
- Reply in the user's language; load `*_zh.md` resources for Chinese dialogue. The plan body and the review report follow the plan's frontmatter `language`; keep technical terms in English inside Chinese plans.
