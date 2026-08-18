# Decomposition Axes

An axis is *how* you slice the parent plan into sub-plans. Pick one (mixing is allowed but confirm it). Offer the axes via ask_user_question with the recommendation first. Read the parent plan in full, plus the root's §3 (method), §4 (experiments), and §6 (milestones) — the sections the axes below slice; the parent scopes which part of them this level covers.

## One level, one kind

The children of one node are **peers**: the same kind of unit, at a comparable size. A level names the categories; the items inside a category live one digit deeper. An axis decides *which* categories — it never licenses putting a category and one of its own members side by side.

Test the drafted list before showing it (Step 3): can one unit be described as *an instance of* what another unit names? `02_ablation-budget-alloc` beside `03_main-expts` fails it — one ablation next to the whole body of headline runs. Group the instances and recurse:

```
02_ablation-expts                   the level lists the category
 ├ 020_ablation-budget-alloc        its members, one digit deeper
 └ 021_ablation-evict-policy
```

Size is the other half of the test: a unit worth a week does not sit beside one worth an afternoon. A level that fails either half spends the 10-sibling cap on units that were never peers and buries the structure the prefix exists to encode — the tree stops saying anything about scale.

Different provenance is fine: two units drawn from different axes can still be peers (see Mixed decomposition). Different granularity is not.

## The three axes

### 1. Phase / milestone  — default recommendation

Split along the root's §6 timeline stages. Each milestone becomes one sub-plan.

- **Use when** the root's milestones are already well-formed (they usually are — the coach front-loads the cheap ones, a baseline implementation and the smallest experiment that validates feasibility, and backs the rest out from the deadline).
- **Gives** a temporally ordered chain of sub-plans; dependencies are mostly linear (each phase hands off to the next).
- **Example** (`0_open-vocab-det-seg`): `00_baseline-impl` → `01_mvp-verify` → `02_core-method` → `03_final-rets`.

### 2. Component / module

Split along the separable parts of the method in the root's §3. Each system module becomes one sub-plan.

- **Use when** the method decomposes into modules that can be built and tested somewhat independently.
- **Gives** sub-plans that can run in parallel; dependencies form a small graph (shared interfaces), not a line.
- **Example** (`02_core-method`): `020_desc-generation` (LLM dynamic description generation), `021_set-matching` (multi-description set matching), `022_det-seg-heads` (shared detection + segmentation heads).

### 3. Experiment / evidence

Split along the root's §4. **A level lists experiment groups; the individual claims sit one digit under them.**

- **Use when** the contribution is mostly empirical, with several claims and ablations that each need their own harness.
- **Gives** a handful of groups — data readiness, baseline implementation, ablation experiments, main results — each a body of work with its own done-criterion. Recursing a group yields one leaf per claim, so the paper's claims still map one-to-one onto leaves, a level below the group; auditing "every claim has an experiment" reads that level.
- **Example** (`0_kv-cache-compress` — the root of a different project from the phase example above, so the prefix digits repeat across the two; the `parent:` frontmatter, never the digits, is what links a child to its parent): `00_data-prep` (LongBench and the PG-19 test split under `datas/`, done when an integrity check passes), `01_baseline-expts` (implement the compared methods and run their baseline numbers), `02_ablation-expts`, `03_main-expts` (the headline runs, under the config the ablations settle — claim 3: more context at equal memory); recursing `02` gives `020_ablation-budget-alloc` (claim 1: a per-layer cache budget beats a uniform one) and `021_ablation-evict-policy` (claim 2: eviction by attention mass beats a recency window).
- **Not** one ablation beside `03_main-expts` — that is the mixed level "One level, one kind" rules out.

## How to choose

- **Default to phase** unless the root's milestones are weak or the user asks otherwise — it matches how the plan is already structured and gives the clearest execution order.
- Prefer **component** when the system still has to be built and its modules can progress in parallel.
- Prefer **experiment / evidence** when the code already runs end to end and the open risk is empirical (does each claim hold?) — if it does not run yet, this axis has nowhere to put the building work.
- **The phase axis and the evidence axis are usually parent and child, not rivals.** For an empirical root the §6 milestones are derived from the §4 experiments, so both axes read the same content — the phase axis orders it by time (a chain), the evidence axis orders it by evidence type (a wide DAG). Choosing the phase axis here does not give up the evidence view: it returns one level down, as the recursion of the experiment-heavy phase. What only the phase axis can hold is the building work; what only the evidence axis promotes to a top-level leaf of its own is data readiness. Decide on those two, not on which unit list reads better.
- **Depth over breadth:** it is fine — often better — to decompose by phase at level 2, then recurse into the heavy phase at level 3 — by component when it is "core method", by experiment / evidence when it is "full experiments". Don't try to capture everything in a single flat level; where the extra breadth is several instances of one category, One level, one kind makes recursing mandatory rather than merely better.

- **A pilot leaf is a legitimate unit when the method is not settled yet.** All three axes assume it is; early research often is not — you run two or three small experiments to find out whether the direction has anything in it, and no claim table can be written yet. Such a unit is an ordinary leaf, except that its §5 is written as "what to look at → which decision each outcome triggers (continue / change the approach / drop it)", with that decision and its evidence written into EXEC_LOG at the end. Its numbers stay provisional and out of the results table, so it cannot promote an unverified guess into a claim — which is exactly what early work must avoid. Once the pilot settles the direction, decompose the real experiments along one of the three axes above.

## Sizing each sub-plan

- Aim for **3–7 sub-plans** per decomposition; ≤10 is a hard cap (naming rule). Fewer than 3 usually means the parent didn't need decomposing yet; more than 7 usually means instances were listed where categories belong — group them and recurse (One level, one kind).
- Each sub-plan should own **one coherent, independently checkable chunk** — something with its own done-criterion. If a unit has no clear "done" test, it's either too vague or belongs merged into a sibling.
- Name explicit **non-goals** so adjacent sub-plans don't overlap; the union of sub-plans should cover the parent's execution without double-owning any piece.

## Dependencies each axis implies

Record dependencies as each sub-plan's `depends_on` frontmatter list (sibling prefixes that must finish first) and render the resulting order in the parent's `## Sub-plans` index. The axis suggests the default shape:

- **Phase / milestone → a linear chain.** Each phase hands off to the next: `01 depends_on ["00"]`, `02 depends_on ["01"]`, … The execution order is a straight line.
- **Component / module → a small DAG.** Modules that share an interface depend on whoever produces it; independent modules have `depends_on: []` and can run in parallel. E.g. `022_det-seg-heads depends_on ["020", "021"]` if it consumes both the descriptions and the matcher.
- **Experiment / evidence → a wide DAG of groups, independent leaves inside each.** The data-readiness leaf is upstream of every group that consumes it; the baseline implementation and the ablation experiments run in parallel from it; the main results depend on the ablations whenever they run under the config those settle. Inside a group, each claim's harness usually stands alone (`depends_on: []`); add an edge only when one experiment literally reuses another's output.

Keep the graph **acyclic**. If two units seem to depend on each other, they are one unit — merge them, or split the shared piece into a third upstream sub-plan they both depend on.

## Mixed decomposition

Mixing axes is allowed (confirm it explicitly). The common shape is **phase at this level, then recurse the heavy phase by component** — but you can also mix within one level when milestones and claims don't align cleanly. When you mix, say which unit came from which axis, and still give every unit a `depends_on` list. Mixing changes where a unit came from, never how big it is — the level still holds peers (One level, one kind).

- **Worked example** (`0_open-vocab-det-seg`, mixed at level 2):
  - `00_baseline-impl` — from the **phase** axis (implement the compared method end to end before building on it); `depends_on: []`
  - `01_mvp-verify` — from the **evidence** axis (validate the core claim cheaply first), and a peer of the units beside it because it is a phase of work rather than one of `03`'s ablations: its §1 non-goals hand every ablation beyond this cheap three-way check to `03`; `depends_on: ["00"]`
  - `02_core-method` — from the **phase** axis (build the full method); `depends_on: ["01"]`
  - `03_final-rets` — from the **phase** axis (all remaining claims/ablations); `depends_on: ["02"]`
  - Then recurse `02` by **component** into `020/021/022` (see the component example above).
  - Execution order: `00 → 01 → 02 → 03`, with `02` expanding into its own component DAG.
