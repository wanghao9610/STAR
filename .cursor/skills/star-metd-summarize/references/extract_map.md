# Extraction map — plan sections → method documents

Plan sections cited as §n are the two plan templates: **strategy plans** (roots and internal nodes) carry §1 problem & motivation, §2 related work & positioning, §3 core method, §4 experiments & validation design, §5 risks & fallbacks, §6 milestones & deliverables; **execution sub-plans** (leaves) carry §1 objective & scope, §2 inputs & dependencies, §3 task breakdown, §4 deliverables & outputs, §5 verification & done-criteria, §6 local risks & fallback. Project guidelines cited as §n are AGENTS.md's numbered sections.

## Relevance: which leaves feed which document

Classify a leaf by what its §2 inputs, §3 steps, and §4 deliverables **name** — never by guessing from its title:

| Signal in the leaf | Feeds |
|---|---|
| a `datas/` path; a step that downloads, filters, annotates, converts, or generates data | dataset |
| a `${CODE_NAME}/` module; a component, architecture, or loss described in §3 | framework |
| an `inits/` weight; a training entry point, optimizer, schedule, or hyperparameter | training |
| a benchmark, metric, baseline, evaluation entry point, or ablation variant | evaluation |
| its §1 objective — always: every leaf is one component of the method | overview |

One leaf commonly feeds several documents (a leaf that builds a dataset and trains on it feeds both). A leaf naming none of these signals feeds overview only. Strategy nodes feed by section, per the map below.

## Map per document

Read every row as *source → the document section it fills*. A source that does not exist is a gap, not a silent skip.

### overview.md

| Document section | Sources |
|---|---|
| 1. Problem & Motivation | root §1 |
| 2. Limitations of Existing Work | root §2 (the shortcomings and the positioning; named works only — citations live in `metds/refs/`) |
| 3. Core Idea | root §3 (key insight + technical route; leave implementation detail to framework) |
| 4. Method at a Glance | every leaf's §1 objective, one row each; internal nodes' §3 where they group components |
| 5. Contributions & Claims | root §3 novelty claims + §4 claim→experiment mapping |
| 6. Status & Milestones | root §6 + each leaf's `exec_status` (a few lines only — progress detail is the status skill's) |

### dataset.md

| Document section | Sources |
|---|---|
| 1. Dataset Inventory | root §4 dataset choices + every leaf's §2 `datas/` inputs |
| 2. Per-dataset Detail | root §4 rationale + the §1/§3 of leaves that name the dataset |
| 3. Preprocessing | data-relevant leaves' §3 steps + the §4 deliverables they produce |
| 4. Constructed Data | data-building leaves' §1 objective, §3 pipeline, §4 artifact, §5 quality check |
| 5. Statistics | only numbers the plans state (root §4, leaves' §2/§4); a number that needs a run is a gap, not a TODO for a rerun |
| 6. Dataset → Experiment Map | root §4 claim→experiment table + `traces_to` on data leaves |

### framework.md

| Document section | Sources |
|---|---|
| 1. Architecture Overview | root §3 technical route |
| 2. Components | modeling leaves' §1 objective, §3 steps, §4 deliverables + the `${CODE_NAME}/` paths their §2/§4 name |
| 3. Design Decisions | root §3 "why it should work" + leaves' §6 local risks where a risk explains a choice; root §5 Plan B where it names a rejected alternative |
| 4. Difference from Prior Work | root §2 positioning + §3 novelty type |
| 5. Module Map | each modeling leaf's `${CODE_NAME}/` paths + the leaf that owns them |

### training.md

| Document section | Sources |
|---|---|
| 1. Training Pipeline | root §3 training strategy + training leaves' §1/§2 (stage order follows `depends_on`, then prefix) |
| 2. Stage Detail | training leaves' §3 steps + §2 `inits/` initialization + root §4 compute budget |
| 3. Hyperparameters | any value a plan states (leaves' §3, root §4); a value no plan fixes stays `TBD` and is listed as a gap — never fill it with a plausible default. A value an executed leaf settled belongs in its §3 via the executor's ENRICHED sync-back |
| 4. Practical Notes | training leaves' §6 local risks (failure modes, early signals, fallbacks) |
| 5. Reproduction | training leaves' §3/§4 entry points and commands as the plans record them |

### evaluation.md

| Document section | Sources |
|---|---|
| 1. Protocol Overview | root §4 (tasks, benchmarks, metrics, baselines) |
| 2. Benchmark Detail | root §4 metrics and meaningful margins + eval leaves' §5 done-criteria thresholds |
| 3. Baselines | root §4 baselines + eval leaves' §2 where they name a baseline's weights or source |
| 4. Ablations | root §4 ablation design + root §5 kill-criteria (the "refutes it if" column) |
| 5. Running the Evaluation | eval leaves' §3/§4 entry points, commands, and output locations |

**Scores never enter evaluation.md.** It defines the protocol; what a run measured lives in that run's analysis report under `wkdrs/<run>/`, and the cross-run ledger of those numbers is `wkdrs/results/results.md` (`star-expt-analyst aggregate`).

## Merge & conflict rules

1. **Dedupe across levels.** The same fact stated by a parent and its leaf is one fact, written once, in the leaf's more specific words.
2. **Merge, do not concatenate.** Sections are written in one voice, with no per-plan seams and no "as plan 01 says". A section that reads as a list of excerpts has failed.
3. **Conflicts: leaf beats parent; newer `updated` beats older.** Leaves are more specific and receive the executor's sync-back from what was actually run.
4. **Unresolvable conflicts are printed, not decided.** When two sources of equal standing disagree (two leaves, same level, different learning rate), write both values inline, prefix ⚠, and name both plans and sections. Never silently pick a winner; never average.
5. **Provenance travels with every passage** — `{plan, §, updated, exec_status}` — from extraction through to the `sources:` block.

## Gaps

A document section with no source coverage keeps its heading and carries a single line:

```
TODO — not covered by any plan; add to <plan file> §<n>.
```

Name the plan that *should* carry it (the root for strategy, the owning leaf for execution detail), not a generic "some plan". Same line, with the missing field named, for a single unstated value inside an otherwise-covered section (`TBD` in a hyperparameter row, an unstated split). Gaps are reported, never papered over with a plausible default.

## Not-yet-verified marks

A passage from a leaf whose `exec_status` is not `done` is design intent. Close the subsection carrying it with one italic line:

```
*⚠ Not yet verified — from `<plan file>` §<n> (exec_status: <pending|in_progress|blocked>).*
```

One line per subsection, not per sentence; content from `done` leaves and from strategy nodes carries no mark. Where a subsection mixes both, mark it and name only the unverified sources.

## Frontmatter contract

Every generated document opens with:

```yaml
---
type: <overview|dataset|framework|training|evaluation>
language: <en|zh>
generated: <YYYY-MM-DD>          # a real date; never invented
sources:                          # every plan that fed this document, with the updated it carried when read
  - plan: <prefix>_<slug>_plan.md
    updated: <YYYY-MM-DD>
---
```

`type:` + `generated:` are what mark a file as compiled and therefore safe to regenerate; a file without them is hand-authored. `sources:` is the staleness check: a recorded `updated` older than that plan's current `updated` means the document is stale.

## Extraction contract (structured return)

Collectors return exactly these two lists plus `plans_read: <n>`, and nothing else:

```yaml
passages:
  - target_section: "3. Preprocessing"
    content: "<the fact, rewritten to stand alone — no 'this plan says'>"
    source: {plan: "00_data-pipeline_plan.md", section: "§3.2", updated: "2026-07-15", exec_status: "done"}
gaps:
  - target_section: "5. Statistics"
    wanted: "per-split counts"
    suggest: "00_data-pipeline_plan.md §4"
plans_read: 7
```

Collectors extract only. They never write files, never resolve conflicts across plans (return both passages; resolution is the main agent's), never invent a fact absent from the plans, and never compile overview — it needs the other four documents' compiled content.

## Change list (the diff gate)

When regenerating an existing compiled document, report one line per section before writing:

| Section | Change | What moved |
|---|---|---|
| 3. Preprocessing | rewritten | tokenization step added from `01_..._plan.md` §3.4 |
| 5. Statistics | unchanged | — |

`added` / `rewritten` / `removed` / `unchanged`. A run where every section is `unchanged` writes nothing at all — leave the file, and its `generated` date, alone. A `removed` row always names why the source went away (a plan section deleted, a leaf re-scoped); a removal nobody asked for is the signal that a plan lost content, which is worth reporting even when the overwrite is approved.
