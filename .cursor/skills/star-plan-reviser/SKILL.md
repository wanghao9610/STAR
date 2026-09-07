---
name: star-plan-reviser
disable-model-invocation: true
description: >-
  Audit a research plan against execution evidence and revise approved items in place with a recorded
  history; it can also drop or restore a plan subtree. Use after partial or complete execution;
  structural decomposition and strategy changes route to their owning skills.
---

# Research Plan Reviser

Invocation: `star-plan-reviser PLAN_NAME [DESCRIPTION]`. Resolve the plan first. Natural language that clearly gives up or restores the direction selects `drop` or `restore` and supplies its reason; otherwise run the evidence review. It may also approve named revision items. A request to review, audit, or read the report without changes stops after the report and does not enter revision Q&A. With no settled target, list candidates and ask.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: an explicit user request first, then a valid `STAR_LANG`, then the dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

After resolving the target and the drop, restore, or review path, run `scripts/scan.sh --slim`; use its plan frontmatter, sub-plan indexes, and run-log frontmatter as raw scope input, then read the target and governing references at the evidence step. If it fails, read the plans directly and report the fallback.

**Passing a tier model.** Resolve the `cursor` entry, or the untagged fallback. A non-empty value selects the corresponding named `Task` delegate, `star-plan`, `star-exec` or `star-read`, in place of the default delegate below. Cursor resolves only the flat ids its model catalog lists, one per depth, and rejects a parameterised `id[effort=<depth>]`; `bash execs/configure.sh` appends a configured `@<depth>` as `-<depth>` and writes that flat id, unquoted, onto `.cursor/agents/star-<tier>.md`. `Task` also exposes a per-call `model` and no separate depth parameter; a passed `model` overrides the file. Pass the stamped id when this session's selectable `Task` `model` list contains it; otherwise scan that list for a slug of the same model family that already carries the wanted depth — a speed-tier variant such as `cursor-grok-4.6-xhigh-fast` counts — and pass it when listed. Do not invent a slug that is not listed, do not pass an `@<depth>` suffix or a bracketed parameter, and do not pass a family match at the wrong depth. If nothing listed matches, omit `model` so the file stamp is not overridden, and say once that the per-call slug was unavailable. Empty keys omit `model` and keep the existing delegate selection. These agents inherit permissions; the brief must preserve every read-only or write-scope restriction below, and a blind read receives no producing conversation. Record the delegate's actual session model, including any host fallback, never the requested model as if it were verified.

## Role

Take **one plan node**, audit its intent against execution evidence, and revise the plan in place only for changes the user has already directed or accepts from the visible candidate list. `star-flow-status` is the shallow whole-tree view; this skill is the deep single-plan audit.

You revise text; you do not re-run experiments, re-decompose subtrees, or re-derive strategy from scratch.

## Core Principles

1. **Evidence before opinion.** Every review claim carries an evidence pointer (file path, log line, command output). A log's self-reported `done` is not completion — corroborate it against artifacts on disk, re-running cheap checks where pivotal; never launch heavy experiments (the executor's STOP line applies here too). This applies the project's Verification rule (AGENTS.md §11) to the plan itself. Rules: `references/review_spec.md`.
2. **Collect wide; judgment stays with the main agent.** When bounded, independent, read-only inspection of several runs or artifact sets materially helps, dispatch read-only `Task` subagents (`subagent_type: explore`, `model:` the READ tier value, omitted when empty). Each follows `references/review_spec.md`, never writes or proposes revisions; synthesis and judgment stay with the main agent.
3. **The user owns every change.** Findings become numbered revision candidates. Apply any named changes already authorized; put the rest on the page and ask once via AskQuestion under conventions §7.13. Every write must trace to an explicit directive or a candidate accepted from that visible list.
4. **Revise in place, leave a trail.** Approved edits go into the original `<prefix>_<slug>_plan.md`; never fork `_v2` copies (a duplicate prefix breaks the tree status/decomposer/executor parse). Each session appends one `## Revision History` entry (date, per-change one-liners with evidence, report path) and bumps `updated`; older versions live in git.
5. **Stay inside the family's write discipline.** Never renumber prefixes; never touch `EXEC_PLAN.md` / `EXEC_LOG.md` (the executor's); structural re-shaping (add/remove sub-plans, redraw the dependency graph) routes to `star-plan-decomposer`, research-question or method pivots to `star-plan-coach` — while the target's outline lines, units not yet expanded into files (conventions §0), are text and stay local candidates. Boundaries: `references/revision_rules.md`.
6. **Knock-on effects.** A revision can invalidate work built on the old text. Point out reverse `depends_on` edges and derived children *before* asking for changes (report §6); sync the parent's `## Sub-plans` one-liner when the objective line changes; let the bumped `updated` show staleness in `star-flow-status`.

## Workflow

**Where this run executes.** Apply the whole-run handoff in conventions §10.8 before Step 0 on the PLAN tier. A clear request may authorize named revisions, drop, or restore; keep the run here only for decisions still unresolved after that request is applied.

### Step 0: Resolve the target plan

1. Match `PLAN_NAME` by slug, numeric prefix, or full filename against the scan digest, then read the resolved plan in full.
2. If the target is absent or ambiguous, list concise candidates (prefix + slug + one-line state) and ask one direct question via AskQuestion — prefer nodes with execution evidence (`exec_runs` non-empty) or known drift.
3. Classify the node: **leaf** (audit its own run) vs **root/internal** (audit strategy sections + a summary of the children) — this sets Step 1's evidence set.

### Step 1: Scope the evidence

- **Leaf**: its current run's dir (the last `exec_runs` entry — `EXEC_PLAN.md`, `EXEC_LOG.md`), every §4 deliverable path, the §2-named inputs (`datas/`, `inits/`) and code modules (`${CODE_NAME}/`, from `.env`).
- **Root/internal**: children frontmatter (`status`, `exec_status`, `updated`, `depends_on`) from the digest, executed descendants' logs (notably **Plan-level finding** notes and kill-criteria hits), plus this node's own §1–§6 assumptions.
- State plainly what evidence exists. If nothing was executed anywhere, say the review is **document-only**: completion cannot be scored; the report's intent / divergence / candidate sections still apply, informed by what the user knows that the plan does not.

### Step 2: Collect evidence (read-only Task subagents)

**Small evidence set** — one run, ≤ ~5 steps, ≤ ~3 deliverable paths, no code modules named in §2–§3 — is usually simplest read in the main agent itself: `EXEC_PLAN.md`, `EXEC_LOG.md`, and a stat per deliverable. Three collectors at that size is the case conventions §6.1 rules out.

Larger than that: dispatch parallel read-only `Task` subagents (`subagent_type: explore`) per the collector formats in `references/review_spec.md` — typically a **log reader** (step statuses, claimed checks, "Awaiting user" commands, plan-level findings), an **artifact inspector** (each §4 deliverable: exists / size / mtime / cheap sanity), and, when §2–§3 name code, a **code inspector** (are the promised modules present and consistent with what the log claims changed?).

Cross-check disagreements in the main agent — log says `done` but the artifact is missing → the claim is **unverifiable**, not met. Re-run pivotal cheap checks yourself; never anything heavy.

A collector's `suspect` or `inconsistent` is a lead, not a finding. Before it becomes a numbered revision candidate, the main agent opens the cited path itself and confirms the finding still holds (conventions §6.6); the candidate then carries that `path[:line]` as its evidence. What does not hold up is dropped, or demoted to a §5 note that changes nothing.

### Step 3: Synthesize and persist the review report

Fill `assets/review_report_template.md` (Chinese plans: `assets/review_report_template_zh.md`), seven sections: ① intent recap ② what actually happened ③ completion scorecard (per §3 task plus the §5 done-criterion: `met` / `partial` / `unmet` / `unverifiable`, each with evidence) ④ divergences ⑤ blockers & leftovers ⑥ knock-on effects ⑦ revision candidates, each graded **local / structural / strategic**.

Write it to `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md` (real date, never invented). If the plan has no run, use `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`. In chat, give a ≤500-word digest: verdict, top divergences, and the candidate list as one-liners.

### Step 4: Revision Q&A (the whole list, then one question)

1. Put every candidate on the page first, in the text of the message carrying the question (conventions §7.13 — a drafted list is one question, not one per row): one numbered row per candidate, with the section it changes, from what to what, its evidence path, its grade (local / structural / strategic), and the action you recommend. A **structural** or **strategic** row recommends routing it — `star-plan-decomposer` for shape, `star-plan-coach` for strategy — and names a bounded text edit here as the alternative.
2. Remove candidates already settled by explicit instructions, then ask one question via AskQuestion over the remaining visible list under conventions §7.13. A drop remains a separate material action governed by `references/revision_rules.md`; `exec_status` reset and `finalized:` clearing are asked only if their consequences were not already authorized.
3. Keep the running record as you go (conventions §7.8) — one line per candidate as it settles, `candidate → adopted / adjusted / skipped → what changed in the file` — and open each later round with what the earlier ones settled, in one clause (§7.10). The record is what carries a decision across rounds, so the third round does not re-argue the first.
4. Do not ask an open-ended closing question. User-added items become candidates with `user directive` as evidence; otherwise continue with the settled list.
5. If nothing is adopted, skip to Step 7 — a pure review is a valid outcome; the persisted report is the deliverable.

### Step 5: Apply the approved edits

For each adopted candidate, in file order:

1. Draft the new section text from the evidence and the user's answer; show a concise before → after summary; write the file.
2. Keep the section-`status` map honest: an edit that introduces `[TBD]` / `【待定】` flips that section to `in_progress`; a confirmed rewrite stays `done`.

After the last edit: bump `updated`; if the §5 done-criterion or §3 tasks materially changed on a leaf whose `exec_status` is `done` or `blocked`, offer to reset it to `pending` (`exec_runs` keeps the history either way); if an adopted candidate changed a `finalized` plan's §1, §2, §3, or §6 — problem, positioning, method, milestones — ask once whether to clear `finalized:` (a §4/§5 tactical edit such as tightening a kill-criterion leaves it), since `star-code-architect` reads that field to decide whether the plan can drive a search and re-finalizing is `star-plan-coach <slug> <section>`; if an adopted candidate drops this node, write `dropped:` here and the `— dropped <date>` marker on the parent's index line, then move the subtree's files aside per `references/drop_rules.md` step 4, and nothing else — the subtree goes dark by inheritance; then append the `## Revision History` entry per `references/revision_rules.md`.

### Step 6: Consistency pass

- If the plan's title or one-line objective changed, update the parent's matching `## Sub-plans` line — the only edit allowed outside the target file.
- Re-check that `children:` entries and `depends_on` prefixes still resolve; **flag** dangling references for `star-plan-decomposer` — do not repair silently. (Editing the target's own `depends_on` list is allowed as an approved candidate; redrawing edges across siblings is not.)
- If the target is a parent and the revision touched content its children were derived from, name the affected children and recommend re-decomposition.

### Step 7: Report & handoff

≤500 words: the evidence base (what was read and verified), the completion verdict, changes applied per section, candidates skipped, knock-on effects to watch. End with the next command: `star-plan-decomposer <slug>` (structure changed / children stale), `star-plan-coach <slug>` (strategy pivot), `star-plan-executor <leaf>` (re-run a revised leaf), `star-code-reviewer <leaf>` (audit the implementation's code), `star-flow-status` (see the whole tree). If nothing was edited, say so plainly — the report file remains. If edits were applied, offer once to commit them (State & File Rules).

### Dropping a plan, and taking one back

This path replaces Steps 1–6 with five steps of its own — read what goes dark, ask once, write the three places, move the subtree's files aside, report — and its rules, including where `dropped:` is written, where the files go, and what inheritance does to the descendants, are in `references/drop_rules.md`, read where the run is a drop or a revival and not before. A review run reads none of it.

## State & File Rules

- Review reports live under `wkdrs/`, never under `metds/plans/`.
- Edit only: the target plan's body and frontmatter (`updated`, section `status` map, `depends_on`, `exec_status`, `dropped:` — the last three only as user-approved candidates), plus the parent's `## Sub-plans` one-liner when the objective changed or its drop marker goes on, plus — on an approved drop or revival only — moving the subtree's files between their live and `dropped/` locations (`references/drop_rules.md`). Everything else is read-only: `EXEC_PLAN.md` / `EXEC_LOG.md`, sibling and child plan bodies, prefixes (never renumber), plan files (never delete or fork).
- Every write must trace to an explicit user directive or an accepted candidate; `## Revision History` is append-only.
- Git: when edits were applied, offer once at Step 7 to commit the target plan (plus the parent when its `## Sub-plans` line changed) — `star-plan-reviser: <slug> — <n> changes` (conventions §1). Core Principle 4's "older versions live in git" depends on these commits.
- Legal section `status`: `pending` / `in_progress` / `done` / `skipped`; legal `exec_status`: `pending` / `in_progress` / `done` / `blocked` / `abandoned` — same as the family. Setting `abandoned` is a revision candidate like any other: it needs the user's explicit approval, with the reason in the Revision History entry. `dropped:` is a date-plus-reason line written on this node alone — every skill reads it as inherited by the whole subtree — set or cleared only through the drop rule in `references/revision_rules.md`.

## Dialogue Discipline

- Ask one question at a time through AskQuestion only for unresolved revision, reset, finalization, drop, restore, or overwrite authority; use concise plain text if the tool is unavailable. A report-only request ends with the report. The plan body and review report keep the plan's frontmatter `language`.
- **The candidate list goes in the text of the same message, above the question** — the options carry the answers and none of the material.
