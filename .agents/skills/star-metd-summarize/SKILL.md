---
name: star-metd-summarize
disable-model-invocation: true
description: >-
  Compile the research-plan tree under metds/plans/ into paper-ready method documents under metds/.
  Invoked as $star-metd-summarize [OPT] where OPT is overview, dataset, framework, training, or
  evaluation; no argument compiles all five in dependency order (dataset → framework → training →
  evaluation → overview, which links the other four and so compiles last). Rebuilds the plan tree
  from parent:, then extracts what each document needs through a written map (overview ← root §1
  problem, §2 positioning, §3 idea, §6 milestones; dataset ← §4 data choices plus every leaf's §2
  datas/ inputs and data-building steps; framework ← §3 route plus modeling leaves and their
  ${CODE_NAME}/ paths; training ← §3 strategy, §4 budget, inits/ and hyperparameters; evaluation ←
  §4 benchmarks, baselines, metrics and ablation design plus §5 kill-criteria), merges the passages
  along the method's axis instead of the plan's, resolves conflicts leaf-over-parent and
  newer-over-older, marks content from unexecuted leaves as not yet verified, and turns uncovered
  template sections into TODOs naming the plan section to fill. Plans are the only source — never
  code, logs, wkdrs/ or chat; result numbers stay with star-expt-analyst. Writes only metds/<OPT>.md,
  and overwrites an existing generated doc only after a section-level change list is approved. Use
  when the user invokes $star-metd-summarize or asks Codex to summarize / consolidate research plans
  into a method write-up, produce overview, dataset, framework, training or evaluation
  documentation, or draft paper method material from the plans. Supports bilingual English/Chinese
  work.
---

# Research Method Summarizer

Match the user's language. Load `*_zh.md` resources for Chinese dialogue; otherwise load the unsuffixed resources.

Invocation: `$star-metd-summarize [OPT]` — `OPT` is one of `overview` / `dataset` / `framework` / `training` / `evaluation`, each compiling `metds/<OPT>.md`; no argument compiles all five in dependency order (`dataset` → `framework` → `training` → `evaluation` → `overview`).

## Role

Serve as the family's method compiler. `$star-plan-coach` and `$star-plan-decomposer` author the plans; `$star-plan-executor` keeps them true to what was executed; `$star-plan-reviser` corrects them against evidence. This skill compiles them: the plan tree is organized by decomposition and execution order, and it re-cuts the same facts along the axis a **reader** needs — what the method is, what data it eats, how it is trained, how it is judged. The product is the five documents under `metds/`, the material a paper's method section is written from.

Compile and reorganize; do not decide method, revise plans, read code, or interpret results. Route what compiling surfaces beyond the write boundary: a missing strategy answer to `$star-plan-coach`, missing execution detail to `$star-plan-decomposer`, plan text that no longer matches reality to `$star-plan-reviser`, result numbers and their meaning to `$star-expt-analyst`, citations and related-work detail to `$star-refs-reviewer`.

## Core Principles

1. **Plans are the only source; every statement traces to one.** Read `metds/plans/*_plan.md` and nothing else — not code, not logs, not `wkdrs/`, not chat memory. The executor syncs confirmed execution deviations back into the sub-plans (`plan_sync_rules.md`), so the plans are both authoritative and current; a fact that only exists in a run log is a plan-sync gap, not an input. Map: `references/extract_map.md`.
2. **Compile, never invent.** Rewriting, reordering, and merging into one voice is the job; adding facts is not. A plausible default (an unstated learning rate, an obvious preprocessing step, a standard metric definition) is an invention — it does not go in. If it is not in a plan, it is a gap.
3. **Gaps are output, not embarrassment.** A template section no plan covers becomes a `TODO` naming the plan and section that should carry it, and the gap list is a headline of the report. The document is a mirror: it shows the researcher exactly where the method is still unwritten, and pushes the fix back into the plans, which the coach and decomposer own.
4. **Organize along the method's axis, not the plan's.** One plan section may feed several documents; one document section may merge a dozen plans. Merge, do not concatenate — a section that reads as a list of plan excerpts, or that says the same thing twice because a parent and a leaf both said it, has failed. Where they disagree: **leaf beats parent, newer `updated` beats older**. When neither dominates, print both values with ⚠ and name both sources — never silently pick a winner.
5. **Never let a plan read as a result.** Content from a leaf whose `exec_status` is not `done` is design intent: close that subsection with one italic line marking it not yet verified, and name the plan it came from. Verified content carries no marker. Result numbers never enter these documents at all — a metric a run produced belongs to `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`; `evaluation.md` defines the protocol, not the scores.
6. **Generated docs are overwritten only with the diff on the table; hand-authored docs are not targets at all.** A doc carrying this skill's `type:` / `generated:` frontmatter is a compiled artifact: on re-run, show the section-level change list and get approval before writing. A doc without that frontmatter was written by a human — show what it holds and ask; never overwrite it on the strength of a diff.

## Workflow

### Step 0: Resolve the targets

1. Read `.env`; resolve `CODE_NAME` — `framework.md` and `training.md` cite `${CODE_NAME}/` paths. If `.env` is missing, create it from `.env.example` and ask the user to fill machine-specific values first (AGENTS.md §6).
2. Interpret the argument: one of the five OPTs → that document; no argument → all five in dependency order (`overview` last: it links the other four); anything else → name the five valid OPTs and ask one direct question about which was meant.
3. **An empty plan tree is a valid answer.** No `metds/plans/*_plan.md` → say so and stop, routing to `$star-plan-coach`. Never compile a method document from nothing.

### Step 1: Scan the plan tree

List `metds/plans/*_plan.md`; read each one's frontmatter and body. Rebuild the tree from `parent:` — authoritative; the numeric prefix only hints, since two unrelated roots can both be `0_` (`$star-plan-status`'s rule). Record per node: root / internal / leaf, `updated`, `language`, the `status:` map, and on leaves `exec_status` and `traces_to`.

- **Output language** follows the plans: the root's `language:`; with several roots, the majority; a tie takes the dialogue language.
- **One document set describes one method.** If the tree has several unrelated roots, say so and ask one direct question about which root's subtree these documents describe; the answer scopes the whole run.
- **A plan whose relevant sections are still `pending`** contributes nothing but a gap — note it now, so the report can name it instead of silently thinning the document.

### Step 2: Extract

Follow `references/extract_map.md`: for each target it names the plan sections that feed each document section, and how to tell which leaves are relevant — by what a leaf's §2 inputs, §3 steps, and §4 deliverables actually **name** (a `datas/` input, an `inits/` weight, a `${CODE_NAME}/` module, a benchmark), never by guessing from its title. A leaf may feed several documents. Carry every passage with its provenance `{plan file, §, updated, exec_status}` — Steps 3–5 need it for conflict resolution, the not-yet-verified marks, and the `sources:` frontmatter.

**Scale**: read a small tree (≤ ~15 plans) directly. For a larger one, delegate selectively — only when bounded, independent, read-only extraction of several document targets materially helps — partitioning **by document target**, each delegate given the map, its exact file list, and the extraction contract in `extract_map.md`. Collectors extract and return; they never write files, never resolve cross-plan conflicts, and never compile `overview` (it needs the other four documents' compiled content).

### Step 3: Merge & resolve

Per `extract_map.md`: dedupe the same fact stated at two levels; resolve conflicts (leaf > parent, newer > older) and mark the unresolvable with ⚠ plus both sources; mark passages from `exec_status` ≠ `done` leaves as not yet verified; record every uncovered section as a gap with the plan section that should fill it.

### Step 4: Fill the template

Fill `assets/<OPT>_template.md` (Chinese: `assets/<OPT>_template_zh.md`). Keep the template's sections and their order; a section with no coverage keeps its heading and carries the `TODO` — never drop it, and never pad it. Frontmatter records `type`, `language`, `generated` (a real date, never invented), and `sources:` — every plan that fed this document with the `updated` date it carried when read, which is what makes staleness detectable on the next run.

### Step 5: Write, with the diff gate

For each target, in dependency order:

- **Missing** → write it.
- **Exists, generated by this skill** (`type:` + `generated:` present) → compare against the freshly compiled content. No substantive change → leave the file untouched and say so; do not churn the `generated` date. Substantive change → show the section-level change list (one line per section: added / rewritten / removed / unchanged, and what changed) and ask one direct question — overwrite or skip — per document. When more than two documents differ, they may be batched into one question: which to overwrite (name the ones to write).
- **Exists without that frontmatter** → hand-authored. Do not diff-and-overwrite: say what the file contains, what compiling would replace it with, and ask. Leaving it alone is a valid outcome; so is compiling to a path the user names.
- **Stale check**: compare each existing doc's recorded `sources:` dates against those plans' current `updated`. A doc whose sources moved is stale — report it even for targets this run did not compile.

### Step 6: Report

Lead with what landed, under about 400 words: per document — written / skipped / unchanged, its path, its gap count and not-yet-verified count. Then the three things a researcher acts on: the **gaps** (which plan section each wants, worst first), the **⚠ conflicts** with both sources named, and the routing — strategy gaps to `$star-plan-coach`, execution detail to `$star-plan-decomposer`, plan text contradicting reality to `$star-plan-reviser`, results to `$star-expt-analyst`, citations to `$star-refs-reviewer`. Never call a document paper-ready; it is compiled material, and its gaps are the reason it is not.

## State Rules

- The only writes are `metds/overview.md`, `metds/dataset.md`, `metds/framework.md`, `metds/training.md`, `metds/evaluation.md` — the five OPT targets, nothing else, nowhere else.
- Never touch `metds/plans/*` — plan text belongs to `$star-plan-coach`, `$star-plan-decomposer`, `$star-plan-executor`, `$star-plan-reviser`; a gap or a wrong statement found while compiling is reported and routed, never fixed in place. Never touch `metds/codearc.md` (`$star-code-architect`'s), `metds/refs/*` (`$star-refs-reviewer`'s), `wkdrs/*`, `${CODE_NAME}/`, `datas/`, `inits/`, `.env`.
- Reads are `metds/plans/*_plan.md`, `.env`, and the five target docs. `wkdrs/` is deliberately not read: execution reality reaches these documents through the executor's sync-back into the plans, so if a run's detail is missing here, the fix is a plan sync, not a wider read.
- This skill runs nothing: no python, no training, no evaluation, no installs — there is no command whose output it needs.
- Git usage is read-only (`status` / `diff` / `log`); this skill never commits.
- It sets no plan frontmatter and creates no run directories; each document's `sources:` block is the whole audit trail.
- Keep chat replies under about 400 words (the compiled documents do not count). Ask one direct question at a time at the four gates — an unrecognized OPT, which root subtree (multi-root tree), each overwrite of a generated doc, and any hand-authored doc in the way — and require an explicit approval before overwriting any existing file, even in headless or scripted runs. Match the user's dialogue language; the documents follow the plans' `language` (Step 1), which may differ. Keep technical terms — metric names, module paths, dataset names — in English inside Chinese documents.
