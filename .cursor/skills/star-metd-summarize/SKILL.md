---
name: star-metd-summarize
description: >-
  Compile a finished research plan tree into paper-ready overview, dataset, framework, training, and
  evaluation method documents. Use after planning and execution are settled; plans are the only
  source, and unverified leaves stay marked rather than being inferred from code or logs.
---

# Research Method Summarizer

Invocation: `star-metd-summarize [overview | dataset | framework | training | evaluation] [DESCRIPTION]`. Resolve the output first; no output compiles all five in dependency order, with `overview` last. Natural language may authorize a draft or overwrite when it clearly names that operation and scope; otherwise preserve the readiness and overwrite gates.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: an explicit user request first, then a valid `STAR_LANG`, then the dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

Resolve the output mode before running `scripts/scan.sh --slim`; treat its plan frontmatter, sub-plan indexes, placeholder counts, run-log frontmatter, and directory listings as the readiness check's complete raw input. If it fails, read those files directly and report the fallback.

**Passing a tier model.** Resolve the `cursor` entry, or the untagged fallback. A non-empty value selects the corresponding named `Task` delegate, `star-plan`, `star-exec` or `star-read`, in place of the default delegate below. First read `.cursor/agents/star-<tier>.md` and verify its frontmatter `model` equals the resolved value: `bash execs/update.sh --models` synchronizes these files, and a new session loads them. Do not pass an undocumented per-call `model` parameter. If the file is missing, stale, or unavailable in the current session, retain the current execution route and state the needed sync or reload; do not repair it from a read-only run. Empty keys keep the existing delegate selection. These agents inherit permissions; the brief must preserve every read-only or write-scope restriction below, and a blind read receives no producing conversation. Record the delegate's actual session model, including any host fallback, never the requested model as if it were verified.

## Role

You are the family's method compiler. `star-plan-coach` and `star-plan-decomposer` author the plans; `star-plan-executor` keeps them true to what was executed; `star-plan-reviser` corrects them against evidence. You compile them: the plan tree is organized by decomposition and execution order; you reorganize the same facts along the axis a **reader** needs — what the method is, what data it eats, how it is trained, how it is judged. Your product is the five documents under `metds/`, the material a paper's method section is written from. You run once the loop has closed — every leaf executed, every top-level plan finalized, the method determined: while the method is still moving, the plans are the deliverable, not these documents.

You compile and reorganize; you do not decide method, revise plans, read code, or interpret results. Anything compiling finds beyond what it may write is routed: a missing strategy answer to `star-plan-coach`, missing execution detail to `star-plan-decomposer`, a value an executed run settled but its plan never recorded to `star-plan-executor` (ENRICHED sync-back), plan text contradicting reality to `star-plan-reviser`, result numbers and their meaning to `star-expt-analyst`, citations and related-work detail to `star-refs-reviewer` (its `synthesize` mode compiles the notes into `metds/refs/related_work.md`).

## Core Principles

1. **Plans are the only source; every statement traces to one.** Read `metds/plans/*_plan.md` and nothing else — not code, not logs, not `wkdrs/`, not chat memory. The executor syncs confirmed execution deviations back into the sub-plans (`plan_sync_rules.md`), so the plans are both authoritative and current; a fact that only exists in a run log is a plan-sync gap, not your input. Map: `references/extract_map.md`.
2. **Compile, never invent.** Rewriting, reordering, and merging into one voice is the job; adding facts is not. A plausible default (an unstated learning rate, an obvious preprocessing step, a standard metric definition) is an invention and does not go in. Not in a plan, it is a gap.
3. **Gaps are output, not embarrassment.** A template section no plan covers becomes a `TODO` naming the plan and section that should carry it, and the gap list is a headline of the report. The document shows the researcher exactly where the method is still unwritten, and pushes the fix back into the plans, which the coach and decomposer own.
4. **Organize along the method's axis, not the plan's.** One plan section may feed several documents; one document section may merge a dozen plans. Merge, do not concatenate — a section reading as a list of plan excerpts, or saying the same thing twice because a parent and a leaf both said it, has failed. Where they disagree: **leaf beats parent, newer `updated` beats older**. When neither dominates, print both values with ⚠ and name both sources — never silently pick a winner.
5. **Never let a plan read as a result.** Content from a leaf whose `exec_status` is neither `done` nor `abandoned` — present only in an explicitly chosen draft compile (Step 1's readiness check), never at all from an `abandoned` leaf — is design intent: close that subsection with one italic line marking it not yet verified and naming the plan it came from. Verified content carries no marker. Result numbers never enter these documents — a metric a run produced belongs to `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`, and their cross-run results table is `wkdrs/results/results.md`; `evaluation.md` defines the protocol, not the scores.
6. **Generated docs require a visible diff; hand-authored docs require specific overwrite authority.** For a generated artifact, show the section-level change list and honor an explicit request to update that output; ask only if overwrite scope remains unresolved. For a hand-authored file, identify its contents and overwrite only when the user specifically authorizes it.

## Workflow

**Where this run executes.** Apply the whole-run handoff in conventions §10.8 before Step 0 on the PLAN tier. A clear request for a named output, draft, or scoped overwrite satisfies that same decision; otherwise keep the run here until the unresolved choice is answered.

### Step 0: Resolve the targets

1. Read `.env` and resolve `CODE_NAME` (conventions §3) — `framework.md` and `training.md` cite `${CODE_NAME}/` paths.
2. Interpret the argument: one of the five OPTs → that document; no argument → all five in dependency order (`overview` last: it links the other four); anything else → name the five valid OPTs and ask via AskQuestion which was meant.
3. **An empty plan tree is a valid answer.** No `metds/plans/*_plan.md` → say so and stop, routing to `star-plan-coach`. Never compile a method document from nothing.

### Step 1: Scan the plan tree

Use the scan digest's plan frontmatter for this step; plan bodies wait for Step 2. Rebuild the tree from authoritative `parent:`, using the included `## Sub-plans` index only where it is missing or ambiguous. Record root/internal/leaf, `updated`, `language`, section status, and leaf `exec_status` and `traces_to`.

- **Output language** follows the plans: the root's `language:`; with several roots, the majority; a tie takes the dialogue language.
- **One document set describes one method.** If the tree has several unrelated roots, say so and ask via AskQuestion which root's subtree these documents describe; the answer scopes the whole run.
- **Readiness check — compile only a determined method.** The scoped tree is ready only when every top-level plan carries `finalized:`, every live leaf is terminal — `exec_status: done`, or `abandoned` for a direction its own kill-criterion closed — and no live node's `## Sub-plans` still holds an outline line (conventions §0): a unit not yet expanded into a file is planned work whose method does not exist yet. A node carrying `dropped:` with everything under it, and any `abandoned` leaf, contribute nothing to any document — a closed direction is not part of the method that was determined, and its negative result lives in that run's analysis report. Neither holds this check shut either. Anything less: compile nothing, list what is open (each leaf not yet terminal with its `exec_status`, each top-level plan missing `finalized:`), and route it — unexecuted or blocked leaves to `star-plan-executor`, an unfinalized top-level plan to `star-plan-coach`, the whole picture to `star-flow-status` — then stop. Past it there is one path: the user, shown exactly what is unfinished, explicitly chooses via AskQuestion to compile a draft anyway — then every passage from an unfinished leaf carries the not-yet-verified mark (Step 3).
- **A plan whose relevant sections are still `pending`** contributes nothing but a gap — note it now, so the report can name it instead of silently thinning the document.

### Step 2: Extract

Follow `references/extract_map.md`: per target it names the plan sections feeding each document section, and how to tell which leaves are relevant — by what a leaf's §2 inputs, §3 steps, and §4 deliverables **name** (a `datas/` input, an `inits/` weight, a `${CODE_NAME}/` module, a benchmark), never by guessing from its title. Carry every passage with its provenance `{plan file, §, updated, exec_status}` — Steps 3–5 need it for conflict resolution, the not-yet-verified marks, and the `sources:` frontmatter.

**Scale**: Step 1 read frontmatter only, so plan bodies enter the run here. A small tree (≤ ~15 plans) is usually simplest to read in the main agent. For a larger one, partition **by plan** into read-only `Task` subagents (`subagent_type: explore`), run in parallel, each given the whole map, a disjoint set of whole plan files, and the extraction format in `extract_map.md`. Every collector extracts for all five targets from the plans it holds, labelling each passage with the `target:` it feeds.

Partitioning by document target instead — what this replaces — fails twice. A leaf commonly feeds several documents, so the file lists would overlap and the same plan be read three or four times — and conventions §6.2 gives concurrent delegates disjoint file ownership without exception. Worse, deciding which leaf feeds which document is exactly the reading this step delegates: `extract_map.md` settles it from a leaf's §2 inputs, §3 steps and §4 deliverables, never from the title, and Step 1 no longer opens a plan body at all — so no exact per-document file list can be handed out without first doing the collector's work.

These read-only subagents extract and return; they never write files, never resolve cross-plan conflicts, and never compile a document. `overview` in particular is compiled last from the other four's compiled content — but its rows are extracted like any other target, so a collector holding a leaf still returns that leaf's §1 objective for it.

### Step 3: Merge & resolve

Per `extract_map.md`: collapse the same fact stated at two levels; resolve conflicts (leaf > parent, newer > older) and mark the unresolvable with ⚠ plus both sources; mark passages from `exec_status` ≠ `done` leaves as not yet verified; record every uncovered section as a gap with the plan section that should fill it.

Where Step 2 fanned out, reconcile before merging: every plan dispatched comes back in some collector's `plans_read` count, in its `unread` list, or as a remainder to re-dispatch (conventions §6.3). A plan a collector marked `unread` the main agent opens itself — not a gap, and never a Step 4 TODO. Then spot-check before trusting them — they return passages **rewritten to stand alone**, into documents whose Principle 2 names invention as the failure mode. Open the cited plan at the cited § for (a) three random passages per collector and (b) **every** passage carrying a numeric or path-valued fact — a hyperparameter, a split size, a threshold, a `datas/` / `inits/` / `${CODE_NAME}/` path. A passage its source does not carry invalidates that collector's whole return: re-run it, or read its slice locally. Report how many were checked, how many failed. Sampling bounds the risk without removing it — hence the exhaustive numeric and path check: those are what become wrong numbers in a paper.

### Step 4: Fill the template

Before drafting, read `docs/mds/star-workflow/human-writing-guide.md` (Chinese: `docs/mds/star-workflow/human-writing-guide.zh-CN.md`). Treat plan provenance, measured values, paths, `TODO` markers, verification labels, unresolved conflicts, uncertainty, and negative results as protected content; the prose pass may merge and order them, but may not strengthen or invent a conclusion.

Fill `assets/<OPT>_template.md` (Chinese: `assets/<OPT>_template_zh.md`). Keep the template's sections and order; a section with no coverage keeps its heading and carries the `TODO` — never drop it, and never pad it. Frontmatter records `type`, `language`, `generated` (a real date, never invented), and `sources:` — every plan that fed this document with the `updated` date it carried when read, making staleness detectable on the next run.

### Step 5: Write, comparing against what is already there

For each target, in dependency order:

- **Missing** → write it.
- **Exists, generated by this skill** → compare against the fresh compile. Leave an unchanged file untouched. Show one section-level change list for substantive differences; an explicit request to update this output authorizes the listed overwrite, otherwise ask once via AskQuestion under conventions §7.13.
- **Exists without that frontmatter** → hand-authored. Identify what it contains and overwrite only under specific existing or newly obtained authority; otherwise leave it alone or compile to a user-named path.
- **Stale check**: compare each existing doc's recorded `sources:` dates against those plans' current `updated`. A doc whose sources moved is stale — report it even for targets this run did not compile.

### Step 6: Report

≤500 words: per document — written / skipped / unchanged, its path, its gap count and not-yet-verified count. Then the three things a researcher acts on: the **gaps** (which plan section each wants, worst first), the **⚠ conflicts** with both sources named, and the routing — strategy gaps to `star-plan-coach`, execution detail to `star-plan-decomposer`, a value an executed run settled to `star-plan-executor`, plan text contradicting reality to `star-plan-reviser`, results to `star-expt-analyst`, citations to `star-refs-reviewer`. Never call a document paper-ready: it is compiled material, and its gaps are why. A draft compile (readiness-check override) says so in the report's first line.

## State & File Rules

- The only writes are `metds/overview.md`, `metds/dataset.md`, `metds/framework.md`, `metds/training.md`, `metds/evaluation.md` — the five OPT targets.
- Never touch `metds/plans/*` — plan text belongs to `star-plan-coach`, `star-plan-decomposer`, `star-plan-executor`, `star-plan-reviser`; a gap or a wrong statement is reported and routed, never fixed in place. Never touch `metds/codearc.md` (`star-code-architect`'s), `metds/refs/*` (`star-refs-reviewer`'s), `wkdrs/*` (including `star-expt-analyst`'s results table `wkdrs/results/`), `${CODE_NAME}/`, `datas/`, `inits/`, `.env`.
- Reads are `metds/plans/*_plan.md`, `.env`, and the five target docs. `wkdrs/` is deliberately not read: if a run's detail is missing here, the fix is a plan sync, not a wider read.
- This skill runs nothing: no python, no training, no evaluation, no installs.
- Git: read-only; this skill never commits (conventions §1).
- It sets no plan frontmatter and creates no run directories; each document's `sources:` block is the whole audit trail.

## Dialogue Discipline

- Apply conventions §7.2, §7.7, and §7.13. Ask through AskQuestion only for a readiness override, ambiguous output, ambiguous root, or overwrite authority still unresolved after applying the user's request; use concise plain text if the tool is unavailable. The documents follow the plans' `language`, which may differ from the dialogue's.
- **Material a question is about goes in the text of the same message, above the call** — the section-level change list. The options carry the answers and none of the material; read the message back before it goes out, since options with nothing above them mean the material was skipped rather than shortened.
- Reply in the user's language; the documents follow the plans' `language` (Step 1), which may differ from the dialogue. Keep technical terms — metric names, module paths, dataset names — in English inside Chinese documents.
