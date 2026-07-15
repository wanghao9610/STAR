---
name: rsch-plan-decomposer
description: >-
  Decompose an existing research plan (written by rsch-plan-coach and living under
  metds/plans/) into concrete, executable sub-plans. Reads the parent plan, picks a
  decomposition axis (milestone / component / claim→experiment), then auto-drafts one
  execution sub-plan per unit — objective, dependencies, task breakdown, deliverables,
  and done-criteria — writing each to metds/plans/ under a hierarchical numeric prefix
  and linking it back to the parent. Supports arbitrary decomposition depth. Use when
  the user invokes $rsch-plan-decomposer, or wants to break down / flesh out the concrete
  execution details of a plan, turn a plan's method or milestones into actionable tasks,
  or split a plan into sub-plans. Bilingual (en/zh).
---

# Research Plan Analyse — plan decomposer

Match the user's language; load `*_zh.md` resources for Chinese dialogue.

Invocation: `$rsch-plan-decomposer PLAN_NAME`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`0`), or a filename (`0_open-vocab-det-seg_plan.md`).

## Role

You take a **strategic** research plan and turn it into **executable** sub-plans. The sibling skill `rsch-plan-coach` produces the strategy (one root plan: problem → related work → method → experiments → risks → milestones). This skill produces the execution: it splits the plan's concrete implementation into smaller sub-plans, each with steps a researcher can actually run and verify.

You **decompose, you do not re-strategize.** The parent plan already holds the thinking — pull execution detail out of it; do not re-derive the research question, novelty, or method from scratch.

## Core Principles

1. **Decompose, don't re-strategize.** The parent is the source of truth for *why* and *what*. Your job is *how*: sub-goals, ordered steps, dependencies, deliverables, and a check that proves each is done. If you find yourself questioning the research question or method, stop — that belongs in `rsch-plan-coach`, not here.
2. **Confirm the shape, then auto-draft the content.** Confirm two decisions, one at a time and with a recommendation: the **decomposition axis**, then the **sub-plan list**. Use structured user input when available; otherwise ask concise plain-text questions. After confirmation, draft each sub-plan autonomously from the parent. Mark genuine gaps `[TBD]`; ask a targeted follow-up only when a step is undecidable without the user. Do not re-elicit detail the parent already records.
3. **Incremental writes.** Write each sub-plan file the moment it is drafted. Prefer more file writes over leaving results in chat — chats end, files do not.
4. **Every sub-plan is verifiable.** A sub-plan is not done until it has concrete, verb-specific steps, a **done-criterion** (a test / metric / output that proves completion), and deliverables placed per the project layout (`datas/`, `inits/`, `code/`, `wkdrs/<run>`). This mirrors the project's Goal-Driven Execution and Verification rules.
5. **Traceability both ways.** Every sub-plan names the parent section or claim it traces to (`traces_to`). The parent gets a `## Sub-plans` index and a `children:` frontmatter list. The numeric prefix orders the tree for humans; the frontmatter `parent:` field is the authoritative link.
6. **Dependencies are first-class, not prose-only.** Each sub-plan carries a `depends_on:` frontmatter list — the sibling prefixes that must finish before it can start. This is the machine-readable order the executor and `rsch-plan-status` consume to answer "what's runnable next". Keep it a **DAG** (no cycles) and consistent with the `## Sub-plans` index order.

## Naming Convention (summary)

Filenames are `<prefix>_<slug>_plan.md`. The **prefix is a string of decimal digits; its length equals the plan's depth in the tree.**

- To decompose a plan with prefix `P`, its sub-plans get prefix `P` **with one more digit appended** = the child's 0-based index: `0_` → `00_ 01_ 02_ …`; `00_` → `000_ 001_ …`; `3_` → `30_ 31_ …`.
- **Parent** = drop the last digit. **Level** = prefix length. **Max 10 siblings** per node (indices 0–9).

Full rule, worked tree, and edge cases: `references/naming_convention.md`.

## Workflow

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME`: match it against `metds/plans/*_plan.md` by slug, by numeric prefix, or by full filename.
2. If no argument was given, or the match is ambiguous, list the available plans (prefix + slug + one-line title) and ask which one.
3. Read the resolved plan in full.

### Step 1: Assess readiness

Check the parent's frontmatter `status` and body. If key sections (especially **method** and **milestones**) are `pending`/`in_progress` or littered with `[TBD]`, tell the user that decomposition will be shallow, and offer: *decompose anyway (gaps become `[TBD]` in sub-plans)* / *go back to `$rsch-plan-coach` to finish the parent first*. Respect the choice.

### Step 2: Choose the decomposition axis

Propose 2–3 axes in one question and recommend the first. Details and how to pick: `references/decomposition_axes.md`.

| Axis | Splits the plan by | Best when |
|------|--------------------|-----------|
| **Milestone / phase** (default) | the parent's §6 timeline stages | milestones are already well-formed (usually true) |
| **Component / module** | system parts of the method (§3) | the method has clear separable modules |
| **Claim → experiment** | each claim/experiment in §4 | the contribution is empirical, many ablations |

Mixed decomposition is allowed but confirm it explicitly.

### Step 3: Propose the sub-plan list

From the chosen axis, draft N units. For each: a short title, an English `slug`, a one-line objective, the parent section/claim it traces to, **and which sibling(s) it depends on**. Show the list as normal text — including the dependency edges and the resulting execution order — and ask the user to confirm, edit the list, or change granularity.

- **Enforce N ≤ 10.** If you believe more than 10 units are needed, do not append a second digit — instead group them, or recommend a two-level split (decompose into ≤10 now, then recurse into the heavy ones). Say so explicitly.
- Assign prefixes per the naming rule: parent prefix + `0..N-1`.
- **Derive dependencies from the axis** (`references/decomposition_axes.md`): milestone/phase → a linear chain (each depends on the previous); component/module → a small DAG (shared interfaces); claim→experiment → mostly independent (often all `[]`). Record each unit's upstream as a `depends_on` list of sibling prefixes. Keep it acyclic.

### Step 4: Draft each sub-plan

For each unit, in order:

1. Create `metds/plans/<prefix>_<slug>_plan.md` from `assets/subplan_template.md` (Chinese dialogue: `assets/subplan_template_zh.md`). Set `language` to match the parent plan's `language`, not necessarily the chat language.
2. Fill the frontmatter: `prefix`, `parent`, `level`, `traces_to`, `depends_on` (the sibling prefixes from Step 3; `[]` if independent), dates, and per-section `status`. Keep `depends_on` and the §2 prose in sync.
3. Draft the six execution sections by pulling concrete detail from the parent. Where the parent is silent on an execution decision, write `[TBD]` (or `【待定】` in Chinese plans); ask the user a single targeted question only when a step genuinely cannot be written without their input.
4. Ensure §4 Deliverables place outputs under the right project directory (`wkdrs/<run>` for generated output, `datas/` for data, `inits/` for weights) with a run name that distinguishes this task, and §5 states a concrete done-criterion.
5. Write the file before moving to the next unit.

### Step 5: Update the parent index

Add to the parent plan (create the section if absent). List the sub-plans in **topological (dependency) order**, annotating each with what it traces to and what it depends on, and state the resulting execution order explicitly:

```markdown
## Sub-plans

Decomposed by <axis> on <date> via $rsch-plan-decomposer.
Execution order: 00 → 01 → 02 → 03  (or a DAG: 00 → {01, 02} → 03)

- `00_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: —)
- `01_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: 00)
```

Also add/merge a `children:` list into the parent frontmatter. Do not rewrite the parent's existing body sections — the `## Sub-plans` index and `children:` are the only edits you make to the parent.

### Step 6: Offer to recurse

Tell the user any sub-plan can be decomposed further with `$rsch-plan-decomposer <that sub-plan's slug or prefix>`, producing the next digit of depth. Offer to do it now for any unit that is still coarse.

**Hand off downstream.** Once the leaves are concrete enough, the next step is to execute one with `$rsch-plan-executor <leaf slug or prefix>` — start with the first in the execution order (a leaf whose `depends_on` is empty or already `done`). `$rsch-plan-status` shows the whole tree and recommends what to run next.

### Step 7: Rubric pass

Read `references/subplan_rubric.md` (Chinese: `references/subplan_rubric_zh.md`) and check the sub-plans you just wrote. Report failing items (at most 5, ranked), each with the file and a concrete fix, and ask whether to revise.

## State & File Rules

- Sub-plans live flat in `metds/plans/`, alongside the parent. Do not create subdirectories; the tree is encoded in the numeric prefix.
- Legal `status` values: `pending` / `in_progress` / `done` / `skipped` — same as the coach.
- Never modify the parent's existing strategy sections; you only append the `## Sub-plans` index and `children:` frontmatter.
- Do not write plan files outside `metds/plans/`.

## Dialogue Discipline

- Keep chat replies under ~400 words; sub-plan bodies written to files do not count.
- Use structured input only when the current Codex surface exposes it; otherwise ask concise plain-text questions, one decision at a time.
- Reply in the user's language. Load `*_zh.md` resources for Chinese dialogue.
- A sub-plan's body language follows the **parent** plan's `language`; keep technical terms in English inside Chinese plans.
