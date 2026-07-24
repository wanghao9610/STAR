---
name: star-plan-decomposer
description: >-
  Decompose an existing research plan (written by star-plan-coach and living under
  metds/plans/) into concrete, executable sub-plans. Reads the parent plan, picks a
  decomposition axis (milestone / component / claim→experiment), then auto-drafts one
  execution sub-plan per unit — objective, dependencies, task breakdown, deliverables,
  and done-criteria — writing each to metds/plans/ under a hierarchical numeric prefix
  and linking it back to the parent. Supports arbitrary decomposition depth. Use when
  the user invokes $star-plan-decomposer, or wants to break down / flesh out the concrete
  execution details of a plan, turn a plan's method or milestones into actionable tasks,
  or split a plan into sub-plans. Bilingual (en/zh).
---

# Research Plan Analyse — plan decomposer

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `$star-plan-decomposer PLAN_NAME`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`0`), or a filename (`0_open-vocab-det-seg_plan.md`).

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You take a **strategic** research plan and turn it into **executable** sub-plans. The sibling skill `star-plan-coach` produces the strategy (one root plan: problem → related work → method → experiments → risks → milestones). This skill produces the execution: it splits the plan's concrete implementation into smaller sub-plans, each with steps a researcher can actually run and verify.

You **decompose, you do not re-strategize.** The parent plan already holds the thinking — pull execution detail out of it; do not re-derive the research question, novelty, or method from scratch.

## Core Principles

1. **Decompose, don't re-strategize.** The parent is the source of truth for *why* and *what*. Your job is *how*: sub-goals, ordered steps, dependencies, deliverables, and a check that proves each is done. If you find yourself questioning the research question or method, stop — that belongs in `star-plan-coach`, not here.
2. **Confirm the shape, then auto-draft the content.** Confirm two decisions, one at a time and with a recommendation: the **decomposition axis**, then the **sub-plan list**. Ask through the `ask_user_question` tool; fall back to concise plain-text questions only in non-interactive `codex exec`. After confirmation, draft each sub-plan autonomously from the parent. Mark genuine gaps `[TBD]`; ask a targeted follow-up only when a step is undecidable without the user. Do not re-elicit detail the parent already records.
3. **Incremental writes.** Write each sub-plan file the moment it is drafted. Prefer more file writes over leaving results in chat — chats end, files do not.
4. **Every sub-plan is verifiable.** A sub-plan is not done until it has concrete, verb-specific steps, a **done-criterion** (a test / metric / output that proves completion), and deliverables placed per the project layout (`datas/`, `inits/`, `code/`, `wkdrs/<run>`, and `tasks/<plan-name>/` for the plan's own tool scripts). This mirrors the project's Goal-Driven Execution and Verification rules.
5. **Traceability both ways.** Every sub-plan names the root section or claim it traces to (`traces_to`). The parent gets a `## Sub-plans` index and a `children:` frontmatter list. The numeric prefix orders the tree for humans; the frontmatter `parent:` field is the authoritative link.
6. **Dependencies are first-class, not prose-only.** Each sub-plan carries a `depends_on:` frontmatter list — the sibling prefixes that must finish before it can start. This is the machine-readable order the executor and `star-flow-status` consume to answer "what's runnable next". Keep it a **DAG** (no cycles) and consistent with the `## Sub-plans` index order.

## Naming Convention (summary)

Filenames are `<prefix>_<slug>_plan.md`. The **prefix is a string of decimal digits; its length equals the plan's depth in the tree.**

- To decompose a plan with prefix `P`, its sub-plans get prefix `P` **with one more digit appended** = the child's 0-based index: `0_` → `00_ 01_ 02_ …`; `00_` → `000_ 001_ …`; `3_` → `30_ 31_ …`.
- **Parent** = drop the last digit. **Level** = prefix length. **Max 10 siblings** per node (indices 0–9).

Full rule, worked tree, and edge cases: `references/naming_convention.md`.

## Workflow

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME`: match it against `metds/plans/*_plan.md` by slug, by numeric prefix, or by full filename.
2. If no argument was given, or the match is ambiguous, list the available plans (prefix + slug + one-line title) and ask which one, with your recommendation marked.
3. Read the resolved plan in full.

### Step 1: Assess readiness

**First, check whether this plan has already been decomposed.** Scan `metds/plans/` for files whose `parent:` is the target — equivalently, whose prefix is the target's prefix plus one digit. If any exist, decomposition is already partial or complete, and Steps 2–4 would overwrite files that may carry hand edits, a `## Revision History`, or execution state. Report what was found (prefix, slug, `exec_status`, and whether the parent's `## Sub-plans` / `children:` already list them) and offer:

- *Repair the parent index only* (recommended when the existing children look complete) — skip Steps 2–4 and go straight to Step 5, deriving the index from the child files themselves. Nothing is written to the children.
- *Add new units alongside them* — leave the existing files untouched, number new units from the next free index, and run Steps 2–4 for those only; Step 5 then merges old and new.
- *Re-decompose from scratch* — Steps 2–4 as normal, but confirm each overwrite file-by-file, and never overwrite a child carrying `## Revision History` or a non-empty `exec_runs` without naming exactly what would be lost.

Check the root's `finalized:` — the one signal that a strategy plan is ready to consume (`star-plan-coach` sets it only when all six sections are `done`/`skipped` and the rubric passed, and clears it whenever a section reopens). Not finalized → read its `status` map and body, name which sections are `pending`/`in_progress` or `[TBD]`-ridden (especially **method** and **milestones**), and tell the user that decomposition will be shallow, and offer: *decompose anyway (gaps become `[TBD]` in sub-plans)* / *go back to `$star-plan-coach` to finish the parent first* (recommended). Respect the choice.

If the target itself carries execution evidence (`exec_runs` non-empty, or `exec_status` beyond `pending`), pause before splitting: decomposition turns an executed leaf into an internal node — its `exec_status` / `exec_runs` freeze as history, `star-flow-status` stops counting it as an executable leaf, and its `wkdrs/` runs stay attached to a node no executor revisits. Offer: *fold the execution evidence into the plan text with `$star-plan-reviser <slug>` first (recommended)* / *decompose anyway* — and when decomposing anyway, draft the children so already-executed work is reflected in their §2 inputs and §3 steps rather than re-planned.

### Step 2: Choose the decomposition axis

Propose 2–3 axes in one question and recommend the first. Details and how to pick: `references/decomposition_axes.md`.

| Axis | Splits the plan by | Best when |
|------|--------------------|-----------|
| **Milestone / phase** (default) | the root's §6 timeline stages | milestones are already well-formed (usually true) |
| **Component / module** | system parts of the method (root §3) | the method has clear separable modules |
| **Claim → experiment** | each claim/experiment in root §4 | the contribution is empirical, many ablations |

Mixed decomposition is allowed but confirm it explicitly.

### Step 3: Propose the sub-plan list

From the chosen axis, draft N units. For each: a short title, an English `slug`, a one-line objective, the root section/claim it traces to, **and which sibling(s) it depends on**. Show the list as normal text — including the dependency edges and the resulting execution order — and ask the user to confirm, edit the list, or change granularity, with your recommendation marked.

- **Give data its own leaf.** Where the root §4 names a dataset `datas/` does not yet hold, one unit is a data-readiness leaf: §3 acquires it, §4 places it under `datas/<name>/` **and names the verification script under `tasks/<plan-name>/`**, and §5's done-criterion is an integrity check — a manifest, a file count, a checksum — never "the download finished". The check's verdict and evidence land in the run's `EXEC_LOG.md` like any other step check; bulky raw output — the manifest itself, a checksum list — goes in a run subdirectory or a non-`.md` file, never a free-named report `.md` at the top of `wkdrs/<run>/` — a name conventions §8 does not register. The acquisition command itself crosses the STOP line, so `star-plan-executor` hands it back rather than running it. Every leaf that consumes the dataset `depends_on` this one. Without it, execution stops at a missing input no plan owns.
- **Enforce N ≤ 10.** If you believe more than 10 units are needed, do not append a second digit — instead group them, or recommend a two-level split (decompose into ≤10 now, then recurse into the heavy ones). Say so explicitly.
- Assign prefixes per the naming rule: parent prefix + `0..N-1`.
- **Derive dependencies from the axis** (`references/decomposition_axes.md`): milestone/phase → a linear chain (each depends on the previous); component/module → a small DAG (shared interfaces); claim→experiment → mostly independent (often all `[]`). Record each unit's upstream as a `depends_on` list of sibling prefixes. Keep it acyclic.

### Step 4: Draft each sub-plan

For each unit, in order:

1. Create `metds/plans/<prefix>_<slug>_plan.md` from `assets/subplan_template.md` (Chinese dialogue: `assets/subplan_template_zh.md`). Set `language` to match the parent plan's `language`, not necessarily the chat language.
2. Fill the frontmatter: `prefix`, `parent`, `level`, `traces_to`, `depends_on` (the sibling prefixes from Step 3; `[]` if independent), dates, and per-section `status`. Keep `depends_on` and the §2 prose in sync.
3. Draft the six execution sections by pulling concrete detail from the parent. Where the parent is silent on an execution decision, write `[TBD]` (or `【待定】` in Chinese plans); ask the user a single targeted question only when a step genuinely cannot be written without their input.
4. Ensure §4 Deliverables place outputs under the right project directory (`wkdrs/<run>` for generated output, `datas/` for data, `inits/` for weights, `tasks/<plan-name>/` for any script the plan itself must write) with a run name that distinguishes this task, and §5 states a concrete done-criterion. **A script never goes in `execs/`** — its root is closed to everything but `run.sh` / `update.sh`, and `execs/scpts/` holds launch wrappers, not the tool a done-criterion runs (conventions §9).
5. Write the file before moving to the next unit.

### Step 5: Update the parent index

Add to the parent plan (create the section if absent). List the sub-plans in **topological (dependency) order**, annotating each with what it traces to and what it depends on, and state the resulting execution order explicitly:

```markdown
## Sub-plans

Decomposed by <axis> on <date> via $star-plan-decomposer.
Execution order: 00 → 01 → 02 → 03  (or a DAG: 00 → {01, 02} → 03)

- `00_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: —)
- `01_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: 00)
```

**Reached via the Step 1 repair branch?** Derive every field from the existing child files rather than from a Step 3 list: topological order and the `depends on:` annotations from their `depends_on`, the `→ §<n>` reference from their `traces_to`, the decomposition date from their own frontmatter (never invented). Each one-liner is *condensed* from that child's §1 objective, not copied — so show the drafted section for review before writing it.

Also add/merge a `children:` list into the parent frontmatter. Do not rewrite the parent's existing body sections — the `## Sub-plans` index and `children:` are the only edits you make to the parent.

### Step 6: Offer to recurse

Tell the user any sub-plan can be decomposed further with `$star-plan-decomposer <that sub-plan's slug or prefix>`, producing the next digit of depth. Offer to do it now for any unit that is still coarse.

**Hand off downstream.** Once the leaves are concrete enough, the next step is to execute one with `$star-plan-executor <leaf slug or prefix>` — start with the first in the execution order (a leaf whose `depends_on` is empty or already `done`). If `${CODE_NAME}/` is still missing or empty, give the plan a code home first with `$star-code-architect`. `$star-flow-status` shows the whole tree and recommends what to run next.

### Step 7: Rubric pass

Read `references/subplan_rubric.md` (Chinese: `references/subplan_rubric_zh.md`) and check the sub-plans you just wrote. Report failing items (at most 5, ranked), each with the file and a concrete fix, and ask whether to revise. Then offer once to commit the plan files written this run (State & File Rules).

## State & File Rules

- Sub-plans live flat in `metds/plans/`, alongside the parent. Do not create subdirectories; the tree is encoded in the numeric prefix.
- Legal `status` values: `pending` / `in_progress` / `done` / `skipped` — same as the coach.
- Never modify the parent's existing strategy sections; you only append the `## Sub-plans` index and `children:` frontmatter.
- A plan body may end with an append-only `## Revision History` section, written by `star-plan-executor` (user-confirmed execution sync-back) and `star-plan-reviser`. Its §1–§6 already reflect those entries — decompose from the body as it stands, and preserve the section untouched.
- Do not write plan files outside `metds/plans/`.
- Git: at the end of the run, offer once to commit the sub-plans written plus the parent's updated index — `star-plan-decomposer: <parent slug> — <N> sub-plans` (conventions §1).

## Dialogue Discipline

- Ask through the `ask_user_question` tool; fall back to concise plain-text questions only in non-interactive `codex exec` — one decision at a time.
- A sub-plan's body language follows the **parent** plan's `language`; keep technical terms in English inside Chinese plans.
- Involvement (conventions §7.7). Dial-immune here: Step 0 ambiguity, Step 1's already-decomposed and executed-leaf branches (they gate overwrites and freeze execution history), every file-by-file overwrite confirm, and the commit offer. Dialed at `low`: Step 1's not-finalized fallback (take the recommendation: back to the coach), Step 2's axis choice (take the recommended axis), Step 3's list confirm (adopt the drafted list — still shown, with its dependency edges, in the reply), Step 4's targeted follow-ups (a parent-silent step already has a default, `[TBD]` — write it and log it), and Step 7's revise question (report the rubric failures without asking). At `high`, confirm each sub-plan's draft before writing it in Step 4.
