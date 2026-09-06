---
name: star-plan-decomposer
disable-model-invocation: true
description: >-
  Decompose a finalized research plan into dependency-aware, executable sub-plans with concrete tasks,
  deliverables, and done criteria, expanding only the next runnable units by default. Use when a plan
  needs smaller work units or its next outlined unit expanded.
---

# Research Plan Analyse — plan decomposer

Invocation: `star-plan-decomposer PLAN_NAME [DESCRIPTION]`. Resolve the slug, numeric prefix, or filename before scanning. Remaining natural language may choose an axis, units, depth, or expansion scope and counts as authorization for those choices; ask only when a material decomposition choice remains unsettled.

**Shared conventions.** Resolve the invocation target and mode first. Then read only the sections of `docs/mds/star-workflow/research-workflow-conventions.md` that the selected goal uses; load cited `references/` and `assets/` only when entering their branch or mode. Read `.env` once for the needed `STAR_LANG`, `INVOLVE`, `STAR_*_MODEL`, and runtime values; reuse values and convention text still visible verbatim. Resolve language under conventions §7.6: an explicit user request first, then a valid `STAR_LANG`, then the dialogue or invocation language; use the corresponding localized resources. `SKILL_zh.md` is for human readers and is never loaded at runtime. Preserve an existing document's frontmatter language. Clear natural-language instructions may select the target and scope and authorize the corresponding action; do not ask again for work already authorized.

After resolving the target, run `scripts/scan.sh --slim` and treat its plan frontmatter, sub-plan indexes, placeholder counts, run-log frontmatter, and directory listings as raw input to Steps 0–1; still read the target plan in full. If it fails, read the plan files directly and report the fallback.

**Passing a tier model.** Resolve the `pi` entry, or the untagged fallback, using Pi's `provider/model` spelling. Pass it to `star_subagent` as `model` in single mode, or in each selected `tasks[]` / `chain[]` item. It overrides the named agent's model; an empty tier value omits the parameter and preserves inheritance. Use `star-auditor` for a blind read, `star-collector` for bounded collection, and `star-implementer` for execution actions. A whole skill or phase needs a general delegate: use `star-runner`, whose authority is that skill and the supplied brief. Every dispatch starts in a fresh process; preserve the scope and write limits below. If the installed extension has no `model` field or the model is unavailable, retain the current execution route and give one reason when the key is set. After a rejected dispatch, verify it started no work before falling back. The delegate records its actual session model, not the requested alias or the parent's resolver.

## Role

You take a **strategic** research plan and turn its concrete implementation into smaller **executable** sub-plans, each with steps a researcher can run and verify. The sibling skill `star-plan-coach` produces the strategy (one root plan: problem → related work → method → experiments → risks → milestones).

You **decompose, you do not re-strategize.** Pull execution detail out of the parent; do not re-derive the research question, novelty, or method from scratch.

## Core Principles

1. **Decompose, don't re-strategize.** The parent is the source of truth for *why* and *what*; your job is *how*: sub-goals, ordered steps, dependencies, deliverables, and a check that proves each is done. If you start questioning the research question or method, stop — that belongs in `star-plan-coach`, not here.
2. **Settle the shape with its content in view, then auto-draft the rest.** The material decisions are the decomposition axis and the visible sub-plan cards plus expansion scope. Apply choices already made in the request; otherwise ask via `star_questionnaire` one at a time with a recommendation under conventions §7.2 and §7.7. Then draft autonomously, marking genuine gaps `[TBD]`; ask only when a step cannot be specified without a key user input.
3. **Incremental writes.** Write each sub-plan file the moment it is drafted. Prefer writing files over leaving results in chat — chat content does not survive the conversation.
4. **Every sub-plan is verifiable.** It is not done until it has concrete, verb-specific steps, a **done-criterion** (a test / metric / output that proves completion), and deliverables placed per the project layout (`datas/`, `inits/`, `code/`, `wkdrs/<run>`, and `tasks/<plan-name>/` for the plan's own tool scripts). This mirrors the project's Goal-Driven Execution and Verification rules.
5. **Traceability both ways.** Every sub-plan names the root section or claim it traces to (`traces_to`). The parent gets a `## Sub-plans` index and a `children:` frontmatter list. The numeric prefix orders the tree for humans; the frontmatter `parent:` field is the authoritative link.
6. **Dependencies are a field, not prose only.** Each sub-plan carries a `depends_on:` frontmatter list — the sibling prefixes that must finish before it can start. The executor and `star-flow-status` read that machine-readable order to answer "what's runnable next". Keep it a **DAG** (no cycles) and consistent with the `## Sub-plans` index order. An outline unit has no prefix and never appears in it (conventions §5.5); a unit expanding later records the by-then-real prefixes of its upstream siblings.
7. **Outline first; a file when execution arrives.** Research overturns plans, and a unit fully drafted months early is a unit rewritten — so by default only the earliest runnable unit(s) expand into sub-plan files, and every later unit stays an **outline unit** (conventions §0): one line in the parent's `## Sub-plans` — title, one-line arrangement, rough order — no slug, no prefix, no file, costing one line to amend when results move it. Re-invoking this skill on the parent expands the next line as execution reaches it (Step 1), after checking the outline against the newest evidence. Expanding everything upfront stays available whenever the user asks for it.

## Naming Convention (summary)

Filenames are `<prefix>_<slug>_plan.md`. The **prefix is a string of decimal digits; its length equals the plan's depth in the tree.**

- To decompose a plan with prefix `P`, its sub-plans get prefix `P` **with one more digit appended** = the child's 0-based index: `0_` → `00_ 01_ 02_ …`; `00_` → `000_ 001_ …`; `3_` → `30_ 31_ …`.
- **Parent** = drop the last digit. **Level** = prefix length. **Max 10 siblings** per node (indices 0–9).

Full rule, worked tree, and edge cases: `references/naming_convention.md`.

## Workflow

**Where this run executes.** Apply the whole-run handoff in conventions §10.8 before Step 0 on the PLAN tier. A decomposition axis, unit list, or expansion scope already settled by the request is not asked again.

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME`: match it by slug, numeric prefix, or full filename against the scan digest's plan list.
2. With no argument, or an ambiguous match, list the available plans (prefix + slug + one-line title) and ask via `star_questionnaire` which one, with your recommendation marked.
3. Read the resolved plan in full.

### Step 1: Assess readiness

**A dropped node is not decomposed.** If the target or any ancestor carries `dropped:`, name the node the drop was written on and stop: splitting a given-up direction writes files nothing will ever count. Reviving it starts by clearing that field through `star-plan-reviser`.

**First, check whether this plan has already been decomposed.** The digest carries every plan's `parent:`; find the files whose `parent:` is the target — equivalently, its prefix plus one digit. If any exist, decomposition is already partial or complete, and Steps 2–4 would overwrite files that may carry hand edits, a `## Revision History`, or execution state. Report what was found (prefix, slug, `exec_status`, and whether the parent's `## Sub-plans` / `children:` already list them) and offer:

- *Expand the next outline unit* — compare it with current execution evidence. Apply a requested amendment directly; otherwise ask only when evidence requires changing the outline's content or order. Expand the earliest ready outline unit unless the description names another.
- *Repair the parent index only* (recommended when the existing children look complete) — skip to Step 5, deriving the index from the child files themselves. Nothing is written to the children.
- *Add new units alongside them* — leave the existing files untouched, number new units from the next free index, and run Steps 2–4 for those only; Step 5 merges old and new.
- *Re-decompose from scratch* — Steps 2–4 as normal. A specific request may authorize the identified overwrite set; otherwise ask over the visible files. Never overwrite a child carrying `## Revision History` or non-empty `exec_runs` without naming exactly what would be lost.

Check the root's `finalized:`, the one signal that a top-level plan is ready to consume (`star-plan-coach` sets it only when all six sections are `done`/`skipped` and the rubric passed, and clears it whenever a section reopens). Not finalized → read its `status` map and body, name which sections are `pending`/`in_progress` or `[TBD]`-ridden (especially **method** and **milestones**), tell the user decomposition will be shallow, and offer: *decompose anyway (gaps become `[TBD]` in sub-plans)* / *go back to `star-plan-coach` to finish the parent first* (recommended). Respect the choice.

If the target itself carries execution evidence (`exec_runs` non-empty, or `exec_status` beyond `pending`), pause before splitting: decomposition turns an executed leaf into an internal node — `exec_status` / `exec_runs` freeze as history, `star-flow-status` stops counting it as an executable leaf, and its `wkdrs/` runs stay attached to a node no executor revisits. Offer: *fold the execution evidence into the plan text with `star-plan-reviser <slug>` first (recommended)* / *decompose anyway* — when decomposing anyway, draft the children so already-executed work is reflected in their §2 inputs and §3 steps rather than re-planned.

### Step 2: Choose the decomposition axis

Propose 2–3 axes (one question, recommend the first). Details and how to pick: `references/decomposition_axes.md`. Each axis option states what it commits to, not just its name (conventions §7.3): the shape of the split, the dependency pattern (linear chain / small DAG / mostly independent), and that changing the axis after Step 4 re-runs the split over files that may already carry hand edits. What separates them is whether the system still has to be built: the evidence axis has no slot for building work, and the evidence view returns one level down as the recursion of the experiment-heavy phase.

| Axis | Splits the plan by | Best when |
|------|--------------------|-----------|
| **Phase / milestone** (default) | the root's §6 timeline stages | the system still has to be built, and the milestones are already well-formed (usually true) |
| **Component / module** | system parts of the method (root §3) | the system still has to be built, and the method has separable modules that can progress in parallel |
| **Experiment / evidence** | root §4, as experiment groups (data readiness / baseline implementation / ablation experiments / main results) — claims recurse a level deeper | the code already runs end to end; the only open risk is whether each claim holds |

Mixed decomposition is allowed when the request clearly chooses it; otherwise present its consequences and ask because it changes the plan's organizing axis.

### Step 3: Propose the sub-plan list

Open with the anchor (conventions §7.10): the axis just chosen and what it yields here — "phase axis → 4 units, a linear chain". Draft N units from it and mark the expansion scope (Principle 7): by default the earliest runnable unit(s) — no upstream sibling in the drafted order, or upstream already terminal — expand now, and every later unit is an outline unit; the user's description may widen that, up to expanding everything. An expanding unit gets a short title, an English `slug`, a one-line objective, the root section/claim it traces to, **and which sibling(s) it depends on**; an outline unit gets a title and a one-line arrangement — what it roughly does and where it sits in the order — no slug, no prefix, its detail deliberately left for the expansion that will see the results before it. **Show the whole list as normal text before the question**: the dependency edges and the resulting execution order first, then one card per expanding unit and one line per outline unit — a unit goes wrong far more often in what it does than in what it is called, and an objection after Step 4 costs N rewritten files.

```markdown
**10_data-readiness** (→ root §4; depends on: —)
- Objective: land LVIS under `datas/`, with a re-runnable integrity check
- Steps: ① acquire and unpack ② build the manifest ③ check file count and md5 ④ record the verdict in `EXEC_LOG.md`
- Deliverables: `datas/lvis/`, `tasks/<plan-name>/verify_lvis.py`
- Done when: the manifest has 1203 rows and every md5 matches

- (outline) baseline implementation — reproduce the comparison floor on LVIS; after data readiness
- (outline) ablation experiments — isolate each component's gain; after the baseline
```

Four lines an expanding unit, one line an outline unit: this is the sketch Step 4 expands. If the request has not already settled the list and expansion scope, show the cards and ask once via `star_questionnaire` under conventions §7.13; otherwise record the existing choice and continue.

- **Give data its own leaf.** Where the root §4 names a dataset `datas/` does not yet hold, one unit is a data-readiness leaf: §3 acquires it, §4 places it under `datas/<name>/` **and names the verification script under `tasks/<plan-name>/`**, and §5's done-criterion is an integrity check — a manifest, a file count, a checksum — never "the download finished". Its verdict and evidence go into the run's `EXEC_LOG.md` like any other step check; bulky raw output — the manifest, a checksum list — goes in a run subdirectory or a non-`.md` file, never a free-named report `.md` at the top of `wkdrs/<run>/`, a name conventions §8 does not list. The acquisition command crosses the STOP line, so `star-plan-executor` hands it back rather than running it. Every leaf consuming the dataset `depends_on` this one; without it, execution stops at a missing input no plan owns.
- **Siblings are peers.** Every unit at this level is the same kind of thing at a comparable size; an individual item never sits beside the category that would contain it (one ablation beside `02_ablation-expts`) — group the instances and recurse into the group instead. Run that test over the drafted list before showing it; worked example in `references/decomposition_axes.md` ("One level, one kind").
- **Enforce N ≤ 10.** If more than 10 units seem needed, do not append a second digit — group them, or recommend a two-level split (decompose into ≤10 now, then recurse into the heavy ones). Say so explicitly.
- Assign a prefix only to a unit expanding now: the next free index under the parent, in expansion order (`references/naming_convention.md`, item 5). An outline unit takes its prefix when it expands, so the digits record when units became files while the intended order lives in the index.
- **Derive dependencies from the axis** (`references/decomposition_axes.md`): phase/milestone → a linear chain (each depends on the previous); component/module → a small DAG (shared interfaces); experiment/evidence → a wide DAG of groups (the data-readiness leaf upstream of the rest), the leaves inside one group mostly independent. Record each expanding unit's upstream as a `depends_on` list of sibling prefixes — outline units enter as prose order only, never as prefixes (conventions §5.5). Keep it acyclic.
- **"Change granularity" is a direction, not an instruction — ask which one, then act on it.** *Coarser*: merge units sharing a category or a dependency until each is again one independently checkable chunk, reassign prefixes and dependencies, and show the list again; if that takes it below 3 units, say the parent did not need decomposing yet and ask whether to stop here or keep the list as it stands, rather than merging down to two (`references/decomposition_axes.md`, "Sizing each sub-plan"). *Finer*: **this level does not change** — a finer unit is one digit deeper, never one more peer: adding siblings here breaks "One level, one kind" and spends the 10-sibling cap on units that were never peers. Ask which unit(s) are too coarse, keep the list as drafted, and carry them to Step 6, which recurses into them this run instead of only offering to. Either direction keeps the axis chosen in Step 2; changing it is that question, not this one.

### Step 4: Draft each sub-plan

For each unit expanding now, in order — an outline unit writes no file, Step 5 records its line:

1. Create `metds/plans/<prefix>_<slug>_plan.md` from `assets/subplan_template.md` (Chinese dialogue: `assets/subplan_template_zh.md`). Set `language` to the parent plan's `language`, not necessarily the chat language.
2. Fill the frontmatter: `prefix`, `parent`, `level`, `traces_to`, `depends_on` (the sibling prefixes from Step 3; `[]` if independent), dates, and per-section `status`. Keep `depends_on` and the §2 prose in sync.
3. Draft the six execution sections by expanding this unit's Step 3 card — its steps, deliverables and done-criterion are the confirmed skeleton: keep them, and say so where drafting forces one to change — and by pulling the remaining detail from the parent. Where the parent is silent on an execution decision, write `[TBD]` (or `【待定】` in Chinese plans); ask the user a single targeted question only when a step genuinely cannot be written without their input.
4. Ensure §4 Deliverables place outputs under the right project directory (`wkdrs/<run>` for generated output, `datas/` for data, `inits/` for weights, `tasks/<plan-name>/` for any script the plan itself must write) with a run name that distinguishes this task, and §5 states a concrete done-criterion. **A script never goes in `execs/`** — its root is closed to everything but `run.sh` / `update.sh`, and `execs/scpts/` holds launch wrappers, not the tool a done-criterion runs (conventions §9).
5. Write the file before moving to the next unit.

### Step 5: Update the parent index

Add to the parent plan (create the section if absent). List every unit in **the intended execution order** — expanded sub-plans as file entries annotated with what they trace to and depend on, outline units as their one-line form, marked `- (outline)` (`- （概要）` in a Chinese plan; conventions §0) — and state the execution order and the expansion count explicitly:

```markdown
## Sub-plans

Decomposed by <axis> on <date> via star-plan-decomposer. Expanded 2 of 4 units; outline lines expand as execution reaches them (star-plan-decomposer <parent slug>).
Execution order: 00 → 01 → ablation experiments → final results  (or a DAG: 00 → {01, ablation experiments} → final results)

- `00_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: —)
- `01_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: 00)
- (outline) ablation experiments — <one-line arrangement>; after 01
- (outline) final results — <one-line arrangement>; after the ablations
```

**Reached via the Step 1 repair branch?** Derive every field from the existing child files, not from a Step 3 list: topological order and the `depends on:` annotations from their `depends_on`, the `→ §<n>` reference from their `traces_to`, the decomposition date from their own frontmatter (never invented). Each one-liner is *condensed* from that child's §1 objective, not copied — so show the drafted section for review before writing it.

Also add/merge a `children:` list into the parent frontmatter — with the `## Sub-plans` index, the only edits you make to the parent. `children:` lists only the expanded files: an outline unit is not a child yet. A dropped child keeps both, with `— dropped <date>` on its index line, and its number is never recycled: the next unit takes the next free index (conventions §5.6) — its file sits under `metds/plans/dropped/`, where the scan still lists it, so read occupied prefixes across both directories. Close the boundary (conventions §7.10): 2–3 sentences on the axis chosen, the files written and the units left in outline, and the execution order that follows — plus the way back: `star-plan-decomposer <slug>` re-enters through Step 1's already-decomposed branch rather than overwriting — expanding the next outline unit while lines remain — and a unit still too big to run can be refined with `star-plan-decomposer <that unit's prefix>` (Step 6).

### Step 6: Offer to recurse

Tell the user any sub-plan can be decomposed further with `star-plan-decomposer <that sub-plan's slug or prefix>`, producing the next digit of depth — and that a unit still in outline expands with `star-plan-decomposer <the parent's slug or prefix>` when execution reaches it (Step 1's expand branch). Offer to recurse now for any expanded unit still too big to run. A unit named by the *finer* answer in Step 3 arrives here already decided — recurse into it rather than offering to.

**Hand off downstream.** Once the leaves are concrete enough, execute one with `star-plan-executor <leaf slug or prefix>` — start with the first in the execution order (a leaf whose `depends_on` is empty or already `done`). If `${CODE_NAME}/` is still missing or empty, give the code a place to live first with `star-code-architect`. `star-flow-status` shows the whole tree and recommends what to run next.

### Step 7: Rubric pass

Start with the computation rather than the judgement call: rebuild the `depends_on` graph from the files just written, check that it has no cycle, that no prefix in it points at an outline unit, and compare it against the parent's `## Sub-plans` index — every unit confirmed in Step 3 appears there exactly once, as a file entry or an outline line, never both and never neither. No drafting step checks those N+1 files against each other, so it is computed here, not assumed. **A cycle, or a file the parent's index does not list, is reported on its own — before the rubric list, and without taking one of its five slots** — a broken rule is not a judgement call and should not compete with a style item for a slot. Fix it, or say exactly what is wrong and stop; the commit offer below waits until the graph and the index agree. Then check the sub-plans you just wrote against `references/subplan_rubric.md` (Chinese: `references/subplan_rubric_zh.md`). Report failing items (at most 5, ranked), each with the file and a concrete fix, and ask whether to revise. Then offer once to commit the plan files written this run (State & File Rules).

## State & File Rules

- Sub-plans live flat in `metds/plans/`, alongside the parent. Do not create subdirectories; the tree is encoded in the numeric prefix.
- Legal `status` values: `pending` / `in_progress` / `done` / `skipped` — same as the coach.
- Never modify the parent's existing strategy sections; you only append or edit the `## Sub-plans` index and `children:` frontmatter.
- An outline unit lives only as its line in the parent's `## Sub-plans`: no file, no slug, no prefix, and it never appears in any `depends_on` (conventions §5.5). Expanding it assigns the next free index; before that, amending its line is an index edit here (Step 1's expand branch) or a local candidate in `star-plan-reviser`.
- A plan body may end with an append-only `## Revision History` section, written by `star-plan-executor` (the user-confirmed write-back of what execution changed) and `star-plan-reviser`. Its §1–§6 already reflect those entries — decompose from the body as it stands, and leave the section untouched.
- Do not write plan files outside `metds/plans/`.
- Git: at the end of the run, offer once to commit the sub-plans written plus the parent's updated index — `star-plan-decomposer: <parent slug> — <N> sub-plans` (conventions §1).
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).

## Dialogue Discipline

- Every question goes through `star_questionnaire` — still one at a time. **Where the material a question is about does not fit in its options** — the sub-plan list, a sub-plan draft, the drafted parent index, the rubric failures — it goes in the text of the same message, above the call, and the options carry only the answers. Either way the two travel together with nothing between them: a message that reaches the user as bare options has lost the material, not condensed it.
- A sub-plan's body language follows the **parent** plan's `language`; keep technical terms in English inside Chinese plans.
- Involve follows conventions §7.7. Ambiguous targets and overwrites that could discard execution history are asked only while unresolved; specific prior authorization satisfies them. At `low`, take recommended reversible choices and log them. At `high`, ask each remaining judgment call separately. Research scope, acceptance criteria, key inputs, and destructive overwrites remain material at every level.
