# Decomposition Axes

An axis is *how* you slice the parent plan into sub-plans. Pick one (mixing is allowed but confirm it). Offer the axes in one question with the recommendation first. Read the parent plan in full, plus the root's §3 (method), §4 (experiments), and §6 (milestones) — the sections the axes below slice; the parent scopes which part of them this level covers.

## The three axes

### 1. Milestone / phase  — default recommendation

Split along the root's §6 timeline stages. Each milestone becomes one sub-plan.

- **Use when** the root's milestones are already well-formed (they usually are — the coach makes the first milestone a cheap MVP and backs the rest out from the deadline).
- **Gives** a temporally ordered chain of sub-plans; dependencies are mostly linear (each phase hands off to the next).
- **Example** (`0_open-vocab-det-seg`): `00_mvp-3way-ablation` → `01_core-method-pipeline` → `02_full-experiments` → `03_writing-submission`.

### 2. Component / module

Split along the separable parts of the method in the root's §3. Each system module becomes one sub-plan.

- **Use when** the method decomposes into modules that can be built and tested somewhat independently.
- **Gives** sub-plans that can run in parallel; dependencies form a small graph (shared interfaces), not a line.
- **Example** (`01_core-method-pipeline`): `010_desc-generation` (LLM dynamic description generation), `011_set-matching` (multi-description set matching), `012_det-seg-heads` (shared detection + segmentation heads).

### 3. Claim → experiment

Split along the root's §4: each claim and its matching experiment/ablation becomes one sub-plan.

- **Use when** the contribution is mostly empirical, with several claims and ablations that each need their own harness.
- **Gives** sub-plans in one-to-one correspondence with the paper's claims — easy to audit "every claim has an experiment".
- **Example**: `00_ablation-dynamic-vs-static` (claim 1: image-conditioned dynamic beats static templates), `01_ablation-desc-count` (claim 2: set matching lowers variance), `02_main-lvis-tail` (claim 3: gains on LVIS rare classes).

## How to choose

- **Default to milestone** unless the root's milestones are weak or the user asks otherwise — it matches how the plan is already structured and gives the clearest execution order.
- Prefer **component** when the user's next real work is *building the system* and modules can progress in parallel.
- Prefer **claim → experiment** when the user's next real work is *running experiments* and the risk is empirical (does each claim hold?).
- **Depth over breadth:** it is fine — often better — to decompose by milestone at level 2, then recurse into the heavy milestone (usually "core method") by component at level 3. Don't try to capture everything in a single flat level.

## Sizing each sub-plan

- Aim for **3–7 sub-plans** per decomposition; ≤10 is a hard cap (naming rule). Fewer than 3 usually means the parent didn't need decomposing yet; more than 7 usually means two levels are hiding in one.
- Each sub-plan should own **one coherent, independently checkable chunk** — something with its own done-criterion. If a unit has no clear "done" test, it's either too vague or belongs merged into a sibling.
- Name explicit **non-goals** so adjacent sub-plans don't overlap; the union of sub-plans should cover the parent's execution without double-owning any piece.

## Dependencies each axis implies

Record dependencies as each sub-plan's `depends_on` frontmatter list (sibling prefixes that must finish first) and render the resulting order in the parent's `## Sub-plans` index. The axis suggests the default shape:

- **Milestone / phase → a linear chain.** Each phase hands off to the next: `01 depends_on ["00"]`, `02 depends_on ["01"]`, … The execution order is a straight line.
- **Component / module → a small DAG.** Modules that share an interface depend on whoever produces it; independent modules have `depends_on: []` and can run in parallel. E.g. `012_det-seg-heads depends_on ["010", "011"]` if it consumes both the descriptions and the matcher.
- **Claim → experiment → mostly independent.** Each claim's harness usually stands alone (`depends_on: []`); add an edge only when one experiment literally reuses another's output (e.g. a main run that needs the ablation's chosen config).

Keep the graph **acyclic**. If two units seem to depend on each other, they are one unit — merge them, or split the shared piece into a third upstream sub-plan they both depend on.

## Mixed decomposition

Mixing axes is allowed (confirm it explicitly). The common shape is **milestone at this level, then recurse the heavy milestone by component** — but you can also mix within one level when milestones and claims don't align cleanly. When you mix, say which unit came from which axis, and still give every unit a `depends_on` list.

- **Worked example** (`0_open-vocab-det-seg`, mixed at level 2):
  - `00_mvp-3way-ablation` — from the **claim** axis (validate the core claim cheaply first); `depends_on: []`
  - `01_core-method-pipeline` — from the **milestone** axis (build the full method); `depends_on: ["00"]`
  - `02_full-experiments` — from the **milestone** axis (all remaining claims/ablations); `depends_on: ["01"]`
  - `03_writing-submission` — from the **milestone** axis; `depends_on: ["02"]`
  - Then recurse `01` by **component** into `010/011/012` (see the component example above).
  - Execution order: `00 → 01 → 02 → 03`, with `01` expanding into its own component DAG.
