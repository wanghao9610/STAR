---
name: star-plan-decomposer
disable-model-invocation: true
argument-hint: "[PLAN_NAME] [DESCRIPTION] [involve=high]"
allowed-tools:
  - Bash(grep:*)
  - Bash(echo:*)
  - Bash(ls:*)
  - Bash(find:*)
  - Bash(wc:*)
  - Bash(head:*)
  - Bash(tail:*)
  - Bash(awk:*)
  - Bash(sed -n:*)
  - Bash(date:*)
  - Bash(git status:*)
  - Bash(git add:*)
  - Bash(git commit:*)
  - Bash(bash .claude/skillsstar-plan-decomposer/scripts/scan.sh)
  - Bash(bash .claude/skillsstar-plan-decomposer/scripts/scan.sh:*)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh)
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/scan.sh:*)
  - Edit(metds/plans/**)
  - Write(metds/plans/**)
description: >-
  Decompose an existing research plan (written by star-plan-coach and living under
  metds/plans/) into concrete, executable sub-plans. Reads the parent plan, picks a
  decomposition axis (phase / component / evidence), confirms the unit list, then by default
  expands only the next runnable unit(s) into full sub-plans — objective, dependencies, task
  breakdown, deliverables, and done-criteria — written to metds/plans/ under a numeric prefix
  and linked back to the parent, while later units stay outline lines in the parent's index;
  re-invoking it on the parent expands the next unit as execution reaches it, checking the
  outline against the newest results first. A sub-plan can be decomposed again, to any depth. Use when
  the user runs star-plan-decomposer, or wants to break down / flesh out the concrete
  execution details of a plan, turn a plan's method or milestones into actionable tasks,
  split a plan into sub-plans, or expand the next outlined unit. Bilingual (en/zh).
---

# Research Plan Analyse — plan decomposer

Match the user's language. `.env`'s `STAR_LANG` replaces it wherever it is set (conventions §7.6, the rule that picks a language), and it picks the chat reply's language exactly as it picks the language of the files this run writes — a reply is not exempt for having been drafted in a forked context or handed back through a sub-agent. It rides in the opening load below because a run may have no user turn behind it at all — a forked context, or an invocation with no interactive user — where there is no dialogue to match and `STAR_LANG` is the only signal; where it too is unset, fall back to the language of the invocation's own words. For Chinese, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Any other language loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `star-plan-decomposer PLAN_NAME [DESCRIPTION]`, where `PLAN_NAME` is a slug (`open-vocab-det-seg`), a numeric prefix (`0`), or a filename (`0_open-vocab-det-seg_plan.md`). Anything after the plan name is a description (conventions §7.12): in your own words, what this run is for — a lead the run may follow and record, never an instruction standing in for a confirmation point, and never the plan name itself: text resolving to no plan leaves the target still to be asked for. An optional `involve=low|medium|high` token may accompany `PLAN_NAME` (e.g. `… involve=low`): it sets this run's `involve` level (conventions §7.7), belongs to neither, and is stripped before either is read.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What decomposing acts on — §0 vocabulary, §1 git, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §7 dialogue, §8 the output table, §9 project layout, §10 the skill roster — arrives through the opening load below. Three sections stay out: §2 the STOP line (it runs nothing itself — its tool allowlist carries no interpreter and no installer, and the one crossing it must know about, a dataset acquisition the executor hands back, is stated where Step 3 drafts a data leaf), §6 delegation (no step dispatches, and its allowlist carries no delegation tool at all), and §11 execution branches, whose nine items this skill never performs — it creates, merges and discards no branch and no worktree — and whose one rule for every other skill, that a commit made while the checkout sits on another run's execution branch rides into that leaf's merge, is restated in State & File Rules beside the commit rule it qualifies. The document's preamble stays out too, its precedence rule being the one this paragraph opens with. Read the whole file if a run ever needs one of them.

Before acting, load it in one message — four Bash calls, with the project root as the working directory, sent together.

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
awk '/^## /{k=/^## (0|1|3|4|5)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (9|10)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
bash <this skill's directory>/scripts/scan.sh --slim
```

One message, four results. `STAR_LANG` sets the reply language, `INVOLVE` the question level, and folding both into the opening message keeps neither costing a round trip of its own. The calls stay separate because each tool result carries its own size limit: a result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid — and the conventions excerpt is about 40 KB in total, split 12, 20 and 8 across its three calls. Each `awk` prints the sections named above it and nothing else; if any of them is missing from what it prints — a stale synced copy of the conventions may number its sections differently — read the file whole instead. The fourth call is the shared collector, and its digest is what Steps 0 and 1 resolve against: every plan's frontmatter — `parent:`, `children:`, `depends_on`, `finalized:`, `exec_status`, `exec_runs` — its `## Sub-plans` index and its placeholder counts, plus every run log's frontmatter and a depth-1 listing of `metds/` and `wkdrs/`. It gathers, it never judges: no tree, no readiness verdict, no ordering. Read what it prints as raw file content, exactly as if you had opened each plan yourself. `--slim` is what keeps the result under the size limit on a project with history; if it is written out anyway, re-run that line on its own. If the script is missing or fails, fall back to reading `metds/plans/*_plan.md` directly, and say in your reply that the scan fell back. Every `references/` and `assets/` file waits until the step that names it.


**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the `.env` lookup's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

You take a **strategic** research plan and turn its concrete implementation into smaller **executable** sub-plans, each with steps a researcher can run and verify. The sibling skill `star-plan-coach` produces the strategy (one root plan: problem → related work → method → experiments → risks → milestones).

You **decompose, you do not re-strategize.** Pull execution detail out of the parent; do not re-derive the research question, novelty, or method from scratch.

## Core Principles

1. **Decompose, don't re-strategize.** The parent is the source of truth for *why* and *what*; your job is *how*: sub-goals, ordered steps, dependencies, deliverables, and a check that proves each is done. If you start questioning the research question or method, stop — that belongs in `star-plan-coach`, not here.
2. **Confirm the shape with its content in view, then auto-draft the rest.** Two decisions are confirmed, one at a time and each with a recommendation: the **decomposition axis**, then the **sub-plan list** — one card per expanding unit (objective, steps, deliverables, done-criterion) and one line per outline unit, never a bare row of titles — with the expansion scope marked: which unit(s) become files now, the rest staying outline lines (Principle 7). Both are asked through the question tool; the axis fits its options and the list does not, so the cards go in that same message's text, above the call (Dialogue Discipline). Then draft each expanding sub-plan autonomously from the parent, marking genuine gaps `[TBD]`; ask a targeted follow-up **only** when a step is undecidable without the user.
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

### Step 0: Resolve the target plan

1. Interpret `PLAN_NAME`: match it against the plans the opening load's digest lists, by slug, numeric prefix, or full filename — no directory listing of your own, the digest is the listing.
2. With no argument, or an ambiguous match, list the available plans (prefix + slug + one-line title) and ask which one via AskUserQuestion, with your recommendation marked.
3. Read the resolved plan in full.

### Step 1: Assess readiness

**A dropped node is not decomposed.** If the target or any ancestor carries `dropped:`, name the node the drop was written on and stop: splitting a given-up direction writes files nothing will ever count. Reviving it starts by clearing that field through `star-plan-reviser`.

**First, check whether this plan has already been decomposed.** The digest carries every plan's `parent:`; find the files whose `parent:` is the target — equivalently, its prefix plus one digit. If any exist, decomposition is already partial or complete, and Steps 2–4 would overwrite files that may carry hand edits, a `## Revision History`, or execution state. Report what was found (prefix, slug, `exec_status`, and whether the parent's `## Sub-plans` / `children:` already list them) and offer via AskUserQuestion:

- *Expand the next outline unit* (recommended when the parent's `## Sub-plans` still holds outline lines) — the lazy default's re-entry. First hold the outline against the newest execution evidence the digest carries (`exec_status`, run logs): where a result moved the arrangement, propose the amendment — reworded, reordered, added or removed outline lines, an edit to the parent's index only — and confirm it before expanding. Then run Steps 3–5 scoped to the earliest outline unit whose predecessors in the index order are all terminal (`done` / `abandoned`): a one-card list confirm, the next free index (`references/naming_convention.md`, item 5), one file, and its line moved from outline to a real index entry. The description may name a different unit to expand; a unit whose predecessor is still unexecuted is named as early, not refused.
- *Repair the parent index only* (recommended when the existing children look complete) — skip to Step 5, deriving the index from the child files themselves. Nothing is written to the children.
- *Add new units alongside them* — leave the existing files untouched, number new units from the next free index, and run Steps 2–4 for those only; Step 5 merges old and new.
- *Re-decompose from scratch* — Steps 2–4 as normal, but confirm each overwrite file-by-file, and never overwrite a child carrying `## Revision History` or a non-empty `exec_runs` without naming exactly what would be lost.

Check the root's `finalized:`, the one signal that a top-level plan is ready to consume (`star-plan-coach` sets it only when all six sections are `done`/`skipped` and the rubric passed, and clears it whenever a section reopens). Not finalized → read its `status` map and body, name which sections are `pending`/`in_progress` or `[TBD]`-ridden (especially **method** and **milestones**), tell the user decomposition will be shallow, and offer via AskUserQuestion: *decompose anyway (gaps become `[TBD]` in sub-plans)* / *go back to `star-plan-coach` to finish the parent first* (recommended). Respect the choice.

If the target itself carries execution evidence (`exec_runs` non-empty, or `exec_status` beyond `pending`), pause before splitting: decomposition turns an executed leaf into an internal node — `exec_status` / `exec_runs` freeze as history, `star-flow-status` stops counting it as an executable leaf, and its `wkdrs/` runs stay attached to a node no executor revisits. Offer via AskUserQuestion: *fold the execution evidence into the plan text with `star-plan-reviser <slug>` first (recommended)* / *decompose anyway* — when decomposing anyway, draft the children so already-executed work is reflected in their §2 inputs and §3 steps rather than re-planned.

### Step 2: Choose the decomposition axis

Propose 2–3 axes via AskUserQuestion (one question, recommend the first). Details and how to pick: `references/decomposition_axes.md`. Each axis option states what it commits to, not just its name (conventions §7.3): the shape of the split, the dependency pattern (linear chain / small DAG / mostly independent), and that changing the axis after Step 4 re-runs the split over files that may already carry hand edits. What separates them is whether the system still has to be built: the evidence axis has no slot for building work, and the evidence view returns one level down as the recursion of the experiment-heavy phase.

| Axis | Splits the plan by | Best when |
|------|--------------------|-----------|
| **Phase / milestone** (default) | the root's §6 timeline stages | the system still has to be built, and the milestones are already well-formed (usually true) |
| **Component / module** | system parts of the method (root §3) | the system still has to be built, and the method has separable modules that can progress in parallel |
| **Experiment / evidence** | root §4, as experiment groups (data readiness / baseline implementation / ablation experiments / main results) — claims recurse a level deeper | the code already runs end to end; the only open risk is whether each claim holds |

Mixed decomposition is allowed but confirm it explicitly.

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

Four lines an expanding unit, one line an outline unit: this is the sketch Step 4 expands into the six sections, not a draft of them. Then confirm through the question tool — *looks good* / *edit the list* / *change granularity*, with your recommendation marked — as the last thing that message does, the cards and outline lines above it in that same message's text, the options carrying only the three answers; confirming adopts the expansion scope with the list. Read the message back before it goes out: options with nothing above them mean the cards were skipped rather than shortened, which is how a run has ended before.

- **Give data its own leaf.** Where the root §4 names a dataset `datas/` does not yet hold, one unit is a data-readiness leaf: §3 acquires it, §4 places it under `datas/<name>/` **and names the verification script under `tasks/<plan-name>/`**, and §5's done-criterion is an integrity check — a manifest, a file count, a checksum — never "the download finished". Its verdict and evidence go into the run's `EXEC_LOG.md` like any other step check; bulky raw output — the manifest, a checksum list — goes in a run subdirectory or a non-`.md` file, never a free-named report `.md` at the top of `wkdrs/<run>/`, a name conventions §8 does not list. The acquisition command crosses the STOP line, so `star-plan-executor` hands it back rather than running it. Every leaf consuming the dataset `depends_on` this one; without it, execution stops at a missing input no plan owns.
- **Siblings are peers.** Every unit at this level is the same kind of thing at a comparable size; an individual item never sits beside the category that would contain it (one ablation beside `02_ablation-expts`) — group the instances and recurse into the group instead. Run that test over the drafted list before showing it; worked example in `references/decomposition_axes.md` ("One level, one kind").
- **Enforce N ≤ 10.** If more than 10 units seem needed, do not append a second digit — group them, or recommend a two-level split (decompose into ≤10 now, then recurse into the heavy ones). Say so explicitly.
- Assign a prefix only to a unit expanding now: the next free index under the parent, in expansion order (`references/naming_convention.md`, item 5). An outline unit takes its prefix when it expands, so the digits record when units became files while the intended order lives in the index.
- **Derive dependencies from the axis** (`references/decomposition_axes.md`): phase/milestone → a linear chain (each depends on the previous); component/module → a small DAG (shared interfaces); experiment/evidence → a wide DAG of groups (the data-readiness leaf upstream of the rest), the leaves inside one group mostly independent. Record each expanding unit's upstream as a `depends_on` list of sibling prefixes — outline units enter as prose order only, never as prefixes (conventions §5.5). Keep it acyclic.
- **"Change granularity" is a direction, not an instruction — ask which one via AskUserQuestion, then act on it.** *Coarser*: merge units sharing a category or a dependency until each is again one independently checkable chunk, reassign prefixes and dependencies, and show the list again; if that takes it below 3 units, say the parent did not need decomposing yet and ask whether to stop here or keep the list as it stands, rather than merging down to two (`references/decomposition_axes.md`, "Sizing each sub-plan"). *Finer*: **this level does not change** — a finer unit is one digit deeper, never one more peer: adding siblings here breaks "One level, one kind" and spends the 10-sibling cap on units that were never peers. Ask which unit(s) are too coarse, keep the list as drafted, and carry them to Step 6, which recurses into them this run instead of only offering to. Either direction keeps the axis chosen in Step 2; changing it is that question, not this one.

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

- If AskUserQuestion is unavailable (headless/scripted), fall back to plain-text questions — still one at a time. **Where the material a question is about does not fit in its options** — the sub-plan list, a sub-plan draft, the drafted parent index, the rubric failures — it goes in the text of the same message, above the call, and the options carry only the answers. Either way the two travel together with nothing between them: a message that reaches the user as bare options has lost the material, not condensed it.
- A sub-plan's body language follows the **parent** plan's `language`; keep technical terms in English inside Chinese plans.
- Involve (conventions §7.7). Always asked here: Step 0 ambiguity, Step 1's already-decomposed and executed-leaf branches (they stop to confirm before an overwrite and freeze execution history), and every file-by-file overwrite confirm. Set to `low`: Step 1's not-finalized fallback (take the recommendation: back to the coach), Step 1's outline-amend proposal inside the expand branch (adopt what the evidence supports and log it — the branch choice itself stays asked), Step 2's axis choice (take the recommended axis), Step 3's list confirm (adopt the drafted list and its expansion scope — the cards, outline lines and dependency edges are still shown in full in the reply), Step 4's targeted follow-ups (a parent-silent step already has a default, `[TBD]` — write it and log it), and Step 7's revise question (report the rubric failures without asking). At `high`, confirm each sub-plan's draft before writing it in Step 4.
