# Research Workflow Skills Guide

**Language:** English | [简体中文](research-workflow-skills.zh-CN.md)

STAR provides eleven connected research workflow skills that turn a research idea into a traceable plan, a related-work base with a verified bibliography, a codebase with a recorded architecture, a verified runtime environment, executable tasks, an implementation backed by verification records, code audited against the project's conventions, results audited against what the plan expected, plans that absorb execution results, and method documents compiled back out of those plans:

```text
research idea
  → star-plan-coach: create a strategic research plan
  → star-refs-reviewer: read the closest work and build a verified bibliography
  → star-plan-decomposer: split it into execution sub-plans with dependencies
  → star-code-architect: give the plan a code home and record the architecture
  → star-env-builder: build and verify the runtime environment
  → star-plan-executor: implement and verify one leaf sub-plan
  → star-code-reviewer: audit the implementation against conventions and the plan
  → star-expt-analyst: audit the run's results against what the plan expected
  → star-plan-reviser: review a plan against execution evidence and revise it
  → star-metd-summarize: compile the matured plans into method documents
  → star-plan-status: inspect overall progress and the next action at any time
```

The skills persist plan state in project files, so work can continue across conversations and sessions without relying on chat history for context.

## 1. Invoking the skills

This guide uses Codex syntax, where a skill is invoked with `$skill-name`:

```text
$star-plan-coach open-vocabulary detection and segmentation
$star-refs-reviewer open-vocab-det-seg
$star-plan-decomposer 0_open-vocab-det-seg_plan.md
$star-code-architect
$star-env-builder
$star-plan-executor 00
$star-code-reviewer 00
$star-expt-analyst 00
$star-plan-reviser 00
$star-metd-summarize framework
$star-plan-status
```

In Claude and Cursor, use `/skill-name` instead:

```text
/star-plan-coach open-vocabulary detection and segmentation
```

You can also describe the task in natural language, such as “Break this research plan into executable sub-plans.” Naming the skill explicitly usually makes the intended workflow unambiguous.

When a skill needs a target plan, `PLAN_NAME` accepts three forms:

| Form | Example | Best used when |
| --- | --- | --- |
| Slug | `open-vocab-det-seg` | The name is unique |
| Numeric prefix | `00` | The prefix is unique in the plan tree |
| Full filename | `00_mvp-3way-ablation_plan.md` | The most explicit form; recommended when roots or names overlap |

Multiple root plans may currently start with `0_`. If a match is ambiguous, use the slug or full filename.

## 2. Before you start

- Use these skills from the root of a STAR project.
- Keep all research plans under `metds/plans/`.
- Before bootstrapping the codebase or executing code, create a local `.env` and set `CODE_NAME`, `CONDA_HOME`, and `PYTHON_HOME` correctly.
- Put reusable code under `${CODE_NAME}/`, data under `datas/`, model weights under `inits/`, and generated results under `wkdrs/`.
- Both English and Chinese are supported. A skill follows the conversation language, while an existing plan continues to use the body language declared by its frontmatter `language` field.

You do not need prepared data, weights, or runnable code merely to draft or decompose a plan. Those inputs are checked during execution.

## 3. `$star-plan-coach`: write a research plan

### When to use it

- You have an early idea but do not yet know how to turn it into a complete research direction.
- You want to write or improve a research plan, proposal, or thesis proposal.
- You want to resume a partially written plan.
- You need to strengthen the problem, related work, method, experiments, or risk analysis.

### How to invoke it

Start a new plan:

```text
$star-plan-coach open-vocabulary detection and segmentation
```

Resume an existing plan:

```text
$star-plan-coach
```

With no topic, the skill scans `metds/plans/*_plan.md`. If it finds unfinished plans, it asks whether to continue one of them or create a new plan.

### What it does

The skill discusses one question at a time and moves through six stages:

1. Problem definition and motivation;
2. Related work and positioning;
3. Core method;
4. Experiments and validation;
5. Risks and fallbacks;
6. Milestones and deliverables.

At the end of each stage, the skill turns the discussion into structured prose. Once confirmed, it writes the section immediately and updates its status. You can ask to skip a section, leave `[TBD]` items, or have the AI draft a section for later confirmation.

### Main output

```text
metds/plans/0_<slug>_plan.md
```

For example:

```text
metds/plans/0_open-vocab-det-seg_plan.md
```

The plan contains six research sections and their statuses. When all sections are complete, the skill runs a quality check and adds a `finalized` date after you approve the final plan.

### Practical guidance

- One or two sentences about the research topic are enough to begin; you do not need a complete proposal first.
- If you are unsure about an experiment or metric, say so. The skill will offer two or three concrete candidates.
- Avoid decomposing the plan before its key sections are confirmed, or downstream sub-plans may contain many `[TBD]` items.

See the complete definition in [`star-plan-coach/SKILL.md`](../../../.agents/skills/star-plan-coach/SKILL.md).

## 4. `$star-refs-reviewer`: survey the related work

### When to use it

- The plan's Related Work section needs the closest works and their limits, and you want them read rather than recalled.
- You are heading toward a paper and need a `reference.bib` you can trust in a submission.
- You want to know which baselines and benchmarks the field expects before sizing the experiments.
- A new paper landed and you want it analyzed and folded into the existing base.

### How to invoke it

```text
$star-refs-reviewer                        # read the method from metds/, run the full pass
$star-refs-reviewer open-vocab-det-seg     # scope the search to one plan
$star-refs-reviewer open-vocabulary segmentation   # a free-text topic
$star-refs-reviewer 2103.00020             # append one paper by arXiv id, DOI, or URL
$star-refs-reviewer verify                 # re-fetch every entry and diff it against the file
$star-refs-reviewer organize               # re-classify the existing bib, offline
```

With no argument the skill looks for the method in `metds/*.md`, falls back to the root plan under `metds/plans/`, and finally asks you for a topic. Once `metds/refs/` exists, runs are incremental: gaps get filled, verified entries are left alone.

### What it does

1. Extracts a search profile from the method — task, mechanism, setting, named datasets and baselines, the claim it wants to make — and states it before searching;
2. Runs 5–8 queries across web search and the Semantic Scholar / DBLP / arXiv endpoints, then brings about 15 ranked candidates to you and reads only the 5–10 you keep;
3. Reads each confirmed paper (abstract, intro, method, and the main results table at minimum) into an analysis note, written to disk immediately;
4. Expands the pool past 50 through the core papers' reference lists, the work citing them, and gap-filling queries, preferring published versions over preprints;
5. Fetches an authoritative record per paper (DBLP → Crossref → Semantic Scholar → arXiv), caches the raw payload under `wkdrs/refs_<date>/raw/`, and transcribes it;
6. Classifies everything into 3–8 categories derived from what was actually collected, writes `reference.bib` grouped by category, and logs every entry's source in the index;
7. Re-fetches five entries at random and diffs them field by field before finishing.

### Main outputs

```text
metds/refs/<ABBREV>.md        # one analysis note per core paper (CLIP.md, DETR.md, …)
metds/refs/reference.bib      # ≥50 entries, grouped by category, keys Year_Method_FirstAuthor
metds/refs/refs_index.md      # core-paper table, categories, provenance, needs-manual-check
```

Each note carries a TL;DR, the problem, the method, the results, and — the reason it exists — a *Relation to This Project* section: shared ground, where it differs, what is borrowable, and what it lets you claim.

### The fabrication boundary

A bib field is legal only if it appears in a record fetched during the run. Nothing is written from memory, no field is "corrected", no missing page range is inferred, and a paper whose record cannot be fetched is listed for manual check rather than guessed. Every entry's source URL and fetch date land in `refs_index.md`, so any field can be re-checked later — which is exactly what `$star-refs-reviewer verify` does.

Google Scholar is deliberately not a source: it has no API, gates automated queries behind CAPTCHAs, and its exported bibtex is itself machine-generated — often missing pages, abbreviating venues, and preferring the preprint over the published record. The skill fetches from the databases that bibtex is generated from instead, which is both automatable and closer to the source. Read Scholar yourself if you like; the skill never scrapes it.

### Practical guidance

- Run it once the coach's method section is clear and before decomposition, so the sub-plans already know their baselines.
- Prefer a reported shortfall to padding: 43 entries you can defend beat 50 you cannot.
- The *Relation to This Project* section is what makes a note worth more than the paper's own abstract — read it before writing the plan's positioning.

See the complete definition in [`star-refs-reviewer/SKILL.md`](../../../.agents/skills/star-refs-reviewer/SKILL.md).

## 5. `$star-plan-decomposer`: create execution sub-plans

### When to use it

- The root plan already explains why and what to do, and you now need to define how to do it.
- You want to turn the method, milestones, or experiment design into executable tasks.
- An existing sub-plan is still too large and needs another level of decomposition.

### How to invoke it

```text
$star-plan-decomposer open-vocab-det-seg
$star-plan-decomposer 0
$star-plan-decomposer 0_open-vocab-det-seg_plan.md
```

If no argument is given or the match is ambiguous, the skill lists candidate plans for selection.

### What it does

The skill first checks whether the parent plan is ready, then confirms two decisions in order:

1. **Decomposition axis:** milestone/phase, component/module, or claim→experiment;
2. **Sub-plan list:** the objective, granularity, dependencies, and execution order of each unit.

After confirmation, the skill generates a sub-plan for every unit. Each sub-plan contains:

- Objective and non-goals;
- Inputs and upstream dependencies;
- An actionable, ordered task breakdown;
- Deliverables with explicit paths;
- A verifiable done-criterion;
- Local risks and fallback options.

### Files and dependency structure

Sub-plans and their parent remain flat under `metds/plans/`; numeric prefixes encode depth:

```text
metds/plans/
├── 0_open-vocab-det-seg_plan.md
├── 00_mvp-3way-ablation_plan.md
├── 01_core-method-pipeline_plan.md
│   ├── 010_desc-generation_plan.md
│   └── 011_set-matching_plan.md
└── 02_full-experiments_plan.md
```

The indentation above represents the logical tree; all files still live in the same directory. Each deeper level appends one digit to the prefix. A node may have at most ten direct children; larger task sets should be decomposed across two levels.

The `parent` field in a sub-plan's frontmatter is the authoritative parent link, while `depends_on` defines execution order. The skill also maintains `children` and a `## Sub-plans` index in the parent plan.

To decompose a coarse sub-plan further:

```text
$star-plan-decomposer 01
```

### Practical guidance

- If the parent method and milestones remain vague, return to `$star-plan-coach` first.
- Every sub-plan should have one check that clearly distinguishes success from failure. “Investigate” or “try to optimize” is not yet concrete enough.
- Do not manually renumber existing prefixes; that can break deeper plans and dependency references.

See the complete definition in [`star-plan-decomposer/SKILL.md`](../../../.agents/skills/star-plan-decomposer/SKILL.md).

## 6. `$star-code-architect`: bootstrap or organize the codebase

### When to use it

- The plan (or its sub-plans) is ready, but `${CODE_NAME}/` is still empty and execution has nowhere to land.
- You want a reference implementation from GitHub as the starting codebase, renamed to `CODE_NAME` and tracked for provenance.
- The codebase already exists but has grown disorganized, and you want it surveyed, selectively migrated, and its architecture recorded.
- You want an architecture spec that later coding — by any agent — must follow.

### How to invoke it

```text
$star-code-architect
$star-code-architect https://github.com/<owner>/<repo>
$star-code-architect open-vocab-det-seg
```

With no argument, the skill resolves the root plan and inspects `${CODE_NAME}/` itself. A GitHub URL skips the search and uses that repository. A plan name chooses which plan drives the search.

### What it does

When `${CODE_NAME}/` is missing or empty (bootstrap):

1. Extracts a search profile from the plan: task domain, method keywords, named baselines, framework constraints;
2. Searches GitHub and scores candidates on plan fit, completeness, license, activity, code quality, and environment match;
3. **Gate 1:** you pick the repository from the scored shortlist, with license implications stated;
4. Clones it, strips git history, records provenance in `${CODE_NAME}/UPSTREAM.md`, keeps the upstream LICENSE, and conservatively rebrands the package to `CODE_NAME` — registry strings and checkpoint-coupled names are left untouched and listed as residuals.

When code already exists (organize): surveys it read-only, concern by concern, into a repo map.

Both paths then design a target architecture with a numbered migration table — the current layout is the baseline, so migrations stay minimal. **Gate 2:** you approve migration items individually. Approved migrations run as disjoint groups with verification and a git checkpoint per group; failed groups are rolled back and marked blocked.

### Main outputs

```text
${CODE_NAME}/                        # working, renamed, provenance-tracked codebase
${CODE_NAME}/UPSTREAM.md             # source URL, commit, license
metds/codearc.md                     # authoritative architecture spec
AGENTS.md                            # ≤10-line Code Architecture summary + pointer
.cursor/rules/code-codearc.mdc       # always-on pointer for Cursor
```

The architecture spec records directory responsibilities, placement rules, naming conventions, the plan-component map, the migration record, and rename residuals. Agents read it before writing code, so later implementation follows one recorded structure instead of each session improvising its own.

### The STOP line

Environment builds involving CUDA compilation, downloads over ~1 GB, full test suites, and anything that trains are prepared as exact commands and handed to you — never launched autonomously. The full environment build belongs to `$star-env-builder`.

### Practical guidance

- Run it once between decomposition and the first execution; re-run it later to record new placement rules or execute the next round of approved migrations.
- Read the license column at Gate 1 carefully — it also constrains how you can release your own code later.
- Keep migrations small. The upstream layout survived real training runs; wholesale restructuring of unfamiliar research code rarely does.

See the complete definition in [`star-code-architect/SKILL.md`](../../../.agents/skills/star-code-architect/SKILL.md).

## 7. `$star-env-builder`: build the runtime environment

### When to use it

- `${CODE_NAME}/` has code, but there is no usable conda env or venv yet.
- The environment broke or dependencies changed, and you want a rebuild with the old environment kept as a dated backup.
- Requirements files are missing and should be resolved from packaging metadata or from the code itself.
- You want an evidence-backed check that the installed environment actually runs the project.

### How to invoke it

```text
$star-env-builder
$star-env-builder my-env
```

With no argument, the environment name is `CODE_NAME` from `.env`. A valid `CONDA_HOME` in `.env` selects the conda backend; otherwise the skill creates `.venv` in the project root (the name argument then does not apply).

### What it does

1. Probes `.env`, the GPU/driver (the CUDA ceiling), conda, and uv;
2. If the target environment already exists, asks whether to **back it up** (rename to `<name>_<YYYYMMDD>` with the real run date — never deleted), **verify & repair in place**, or **abort**;
3. Resolves dependencies first-signal-wins: existing `${CODE_NAME}/requirements*` → `pyproject.toml` / `setup.py` / `environment.yml` → an import scan of the code. Generated results land in a two-tier layout: `requirements.txt` referencing `requirements/framework|runtime|optional.txt`, with conda-only items in `requirements/conda.txt`;
4. **Gate:** you approve the install plan — backend, python version, per-category packages, the torch↔CUDA wheel match, download sizes, and every flagged uncertainty;
5. Installs through the uv > pip > conda ladder (conda only for system-isolation items such as `cudatoolkit` or `ffmpeg`), respecting any configured mirrors;
6. Smoke-tests in three layers — imports, framework/GPU check, project entrypoint — with the main loop recording evidence for every check.

### Main outputs

```text
$CONDA_HOME/envs/<ENV_NAME>/  (or .venv/)    # the working environment
${CODE_NAME}/requirements*                   # only when the layout was missing (committed)
wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md    # identity, install results, smoke matrix
wkdrs/env_<ENV_NAME>_<date>/freeze.txt       # exact version snapshot
```

The report records the absolute interpreter path (`ENV_PY`) that every later command should use — the skills never rely on `source activate`.

### The STOP line

Gate-approved installs run autonomously, including large framework wheels. The skill never runs `sudo` or system package managers, never compiles CUDA extensions from source (flash-attn-style builds are prepared as exact commands for you), never downloads more than ~10 GB, and never deletes an environment.

### Practical guidance

- Run it once after `$star-code-architect` lands the codebase and before the first `$star-plan-executor` run.
- Re-running it later is safe: choose *verify & repair in place* to fix a broken environment without rebuilding, or *backup & rebuild* to start clean.
- On a CUDA mismatch the skill stops and presents concrete options instead of guessing — have your target torch/CUDA combination in mind.

See the complete definition in [`star-env-builder/SKILL.md`](../../../.agents/skills/star-env-builder/SKILL.md).

## 8. `$star-plan-executor`: execute one leaf plan

### When to use it

- A sub-plan has a concrete task breakdown and done-criterion and is ready for implementation.
- You want to resume an interrupted execution.
- You want to turn a plan into code, light validation, and an auditable execution record.

### How to invoke it

```text
$star-plan-executor 00
$star-plan-executor mvp-3way-ablation
$star-plan-executor 00_mvp-3way-ablation_plan.md
```

Only a **leaf plan** is executable. If the target still has `children`, the skill asks you to choose one of its leaves or recommends further decomposition.

### Readiness checks

The skill first verifies that:

- Section 3 contains concrete tasks;
- Section 5 defines a runnable done-criterion;
- Every upstream plan in `depends_on` is complete;
- Required data, weights, and code modules exist;
- The project paths and Conda environment in `.env` are usable (if the environment is missing, `$star-env-builder` builds it).

If a hard dependency is missing, the skill reports the exact blocker rather than fabricating an input or skipping the dependency.

### What it does

1. Reads the real code and builds a current-state-versus-plan gap list;
2. Refines the sub-plan into an `EXEC_PLAN` whose steps bind files, commands, artifacts, and checks;
3. Makes only the changes required for the current step;
4. Runs the narrowest light validation and records evidence in the log;
5. Sets the execution status to `done` after satisfying the sub-plan's done-criterion.

Ordinary in-scope implementation and light validation proceed under the active tool's permission model. The skill stops for direction when a choice would materially change the task scope.

### The STOP line

The skill does not automatically start:

- Long-running or multi-GPU training and fine-tuning;
- Full-dataset evaluation;
- Large batches of usage-priced API calls;
- Operations that may overwrite valuable artifacts;
- Work whose duration or cost cannot be bounded.

Instead, it prepares the exact command, records it under “Awaiting user” in the execution log, and stops. After you run the command, invoke the same plan again; the skill resumes from the log and verifies the result instead of starting over.

### Main outputs

The default run name is `<prefix>_<slug>`:

```text
wkdrs/00_mvp-3way-ablation/
├── EXEC_PLAN.md
├── EXEC_LOG.md
└── ...                     # Other artifacts generated by this run
```

- `EXEC_PLAN.md` records actions, files, commands, artifacts, checks, the STOP line, and any divergences from the sub-plan;
- `EXEC_LOG.md` records step status, verification evidence, blockers, commands awaiting the user, and pending amendments;
- The plan file receives the lightweight `exec_status`, `exec_run`, and `updated` fields — plus, after your confirmation, material deviations synced back into its §2–§5 (see below).

When the same plan is invoked again, the skill treats `EXEC_LOG.md` as the source of truth, skips completed steps, and resumes from the first unfinished action.

### Plan sync-back

Execution rarely matches the written plan exactly. When the difference is material at the plan's own granularity — a step added, dropped, or replaced; a dependency that turned out wrong; a changed deliverable path; an adjusted done-criterion — the skill records it as an ADDED / MODIFIED / REMOVED delta and confirms it with you: deviations found while planning are confirmed together with the executable plan itself, and deviations that emerge during execution are batch-confirmed once at finalization. Confirmed deltas are then written back into the sub-plan — the affected §2–§5 passages are updated in place and a `## Revision History` entry records the date, run, change, and reason — so the plan you reread later matches what was actually executed. Objective- or strategy-level divergence is never synced this way; it routes to `$star-plan-reviser` / `$star-plan-coach` / `$star-plan-decomposer`.

See the complete definition in [`star-plan-executor/SKILL.md`](../../../.agents/skills/star-plan-executor/SKILL.md).

## 9. `$star-code-reviewer`: review code against conventions and the plan

### When to use it

- A leaf finished and you want the new code audited before building on it.
- The codebase has grown and you want a convention audit (docstrings, naming, simplicity, hardcoded paths) with a persisted report.
- You want to check whether a plan's §3 tasks are actually implemented in code, beyond what the execution log claims.
- You just changed some files and want a quick review of only the diff.

### How to invoke it

```text
$star-code-reviewer                        # everything under ${CODE_NAME}/
$star-code-reviewer 00                     # the code that plan touches + plan conformance
$star-code-reviewer ${CODE_NAME}/models    # one path
$star-code-reviewer diff                   # uncommitted changes only
$star-code-reviewer HEAD~3..               # a git range
```

A plan argument accepts the usual slug / numeric prefix / filename forms; a `wkdrs/<run>/` path back-resolves to its plan.

### What it does

1. Resolves the scope and loads the yardsticks: the project guidelines, `metds/codearc.md` when present, and — in plan mode — the plan's §2–§5 plus its execution log;
2. Gathers cheap static evidence through the `.env` environment (`compileall` always; ruff/flake8 only if already installed — it never installs tools);
3. Collects findings against a six-dimension rubric: docstrings & comments, naming, simplicity, STAR project conventions (hardcoded paths, layout, placement rules), high-confidence correctness smells, and — in plan mode — plan conformance;
4. Re-verifies every blocker/major finding against the code before reporting; unconfirmed suspicions are listed separately and never counted;
5. Writes the report under `wkdrs/` and gives a short digest with routing: feature gaps → `$star-plan-executor`, plan-text divergence → `$star-plan-reviser`, structural reorganization → `$star-code-architect`;
6. Optionally walks a fix pass, one finding at a time: only mechanical, behavior-preserving fixes (docstrings, scope-internal renames, unused imports, project-introduced dead code), each re-verified after application.

### Main outputs

```text
wkdrs/<run>/CODE_REVIEW_<date>.md         # plan mode with a run
wkdrs/reviews/code_<scope>_<date>.md      # other modes
```

The report records the scope and evidence base, a verdict, findings by severity (blocker / major / minor / nit) each with file:line, the violated rule and a concrete fix, the plan-conformance scorecard, and the fix record.

### The fix boundary

The fix pass never changes behavior: no feature completion, no signature changes visible outside the scope, no file moves, no edits to names on the rename-residual list. Plan files are never edited — what the review learns about the plan routes to `$star-plan-reviser`.

### Practical guidance

- Run it after a leaf completes, before `$star-plan-reviser` — the code audit gives the plan review harder evidence.
- `diff` mode is the cheapest habit: review what you just wrote while it is still uncommitted.
- A finding you disagree with can simply be skipped in the fix pass; the report keeps the record either way.

See the complete definition in [`star-code-reviewer/SKILL.md`](../../../.agents/skills/star-code-reviewer/SKILL.md).

## 10. `$star-expt-analyst`: analyze a run's results

### When to use it

- You ran the training or evaluation command the executor handed back, and want to know what the results mean.
- You want to know whether a run actually met its done-criteria, beyond what its log claims.
- A run finished but you are not sure it can be trusted — the numbers look wrong, or they look too good.
- You want the training logs read for you: crashes, NaN, OOM, divergence, overfitting.
- You re-ran a plan as a variant and want the runs put side by side.

### How to invoke it

```text
$star-expt-analyst 00                             # the plan's run, via its exec_run
$star-expt-analyst mvp-3way-ablation
$star-expt-analyst wkdrs/00_mvp-3way-ablation/    # a run directory
$star-expt-analyst                                # list the runs on disk and pick one
```

A plan argument accepts the usual slug / numeric prefix / filename forms; a `wkdrs/<run>/` path back-resolves to its plan.

### What it does

1. Resolves the run and loads the expectations: the sub-plan's §4 deliverables and §5 done-criteria, the parent's §4 metrics and §5 kill-criteria, and the run's `EXEC_PLAN.md` / `EXEC_LOG.md`;
2. Inventories the §4 deliverables against disk with light integrity checks, and corroborates every step the log claims `done` against the artifact it names — including which STOP-line commands you actually ran;
3. Scans the logs for health signals: crashes and OOM, NaN/Inf, diverging or flat loss, train-val divergence — big logs are grepped and read head-and-tail, never loaded whole;
4. Extracts the metrics the criteria name from the most authoritative source available, and scores each criterion `met` / `not met` / `unmeasurable` — naming the source and the split behind every number;
5. Interprets the result against the claim the plan `traces_to`: parent kill-criteria, leakage checks before a suspiciously strong number is accepted, and the run's limits (seeds, split size, what it does not show);
6. Renders loss and metric curves when matplotlib is already installed, and compares sibling runs of the same plan when they exist;
7. Writes the report under `wkdrs/<run>/` and gives a short digest with routing.

### Main outputs

```text
wkdrs/<run>/EXPT_ANALYSIS_<date>.md   # the analysis report
wkdrs/<run>/analysis/*.png            # curves, when matplotlib is available (with the script that made them)
```

The report records the scope and evidence base, a run verdict, the done-criteria scorecard, the artifact inventory and completion, log health, metrics with their sources and any cross-run comparison, the interpretation, and the routing.

### The read boundary

This skill is **read-only apart from its own report**. It never edits plan files, never sets `exec_status`, and never touches `EXEC_PLAN.md` / `EXEC_LOG.md` — when a done-criterion is met, it recommends `$star-plan-executor`, which owns finalization. It never re-runs an experiment to fill in a missing metric: that metric is reported `unmeasurable` and the command comes back to you. The executor's STOP line applies here too.

### Practical guidance

- The natural moment is right after you run a STOP-line command: the analyst tells you what came back, then hands the plan to `$star-plan-executor` to finalize it.
- The run verdict is deliberately blunt. `inconclusive` means the evidence is not there — usually a STOP-line command that was never run. `invalid` means the numbers exist but cannot be trusted, and a re-run is cheaper than an interpretation.
- A negative result that hits a parent kill-criterion is the most valuable thing this skill can find: route it to `$star-plan-reviser` while the evidence is fresh.

See the complete definition in [`star-expt-analyst/SKILL.md`](../../../.agents/skills/star-expt-analyst/SKILL.md).

## 11. `$star-plan-reviser`: review and revise one plan

### When to use it

- A leaf finished (or stalled) and you want to know what it actually did versus what it promised before moving on.
- Execution recorded a strategy signal or hit a kill-criterion, and the plan should absorb the result.
- A plan drifted from reality — extra work happened, assumptions changed — and its text should catch up.
- You want an evidence-backed completion assessment written down, not just chat impressions.

### How to invoke it

```text
$star-plan-reviser 00
$star-plan-reviser mvp-3way-ablation
$star-plan-reviser 0_open-vocab-det-seg_plan.md
```

Any node works: a leaf is audited against its own run; a root or internal node is audited against its children rollup and the strategy signals recorded in descendants' logs.

### What it does

1. Reads the plan and scopes the evidence: `wkdrs/<run>/EXEC_PLAN.md` and `EXEC_LOG.md`, every §4 deliverable on disk, the named code modules — or, for internal nodes, children frontmatter and executed descendants' logs;
2. Collects the evidence read-only and scores completion claim by claim (`met` / `partial` / `unmet` / `unverifiable`) — a log's self-reported `done` is never trusted without the artifact behind it;
3. Writes a seven-part review report (intent recap, what actually happened, completion scorecard, divergences, blockers and leftovers, ripple map, revision candidates) under `wkdrs/`;
4. Walks the revision candidates one question at a time — adopt, adjust, or skip each;
5. Applies approved edits to the plan file in place, appends a `## Revision History` entry, updates `updated`, and offers to reset a leaf's `exec_status` when its done-criterion changed;
6. Ends with the follow-up action: re-decompose, re-execute, or a coaching session.

Adopting nothing is a valid outcome: the persisted review report is a deliverable on its own.

### The revision boundary

One session revises one target file (plus the parent's index line when the target's objective changed). Structural changes — adding or removing sub-plans, redrawing the dependency graph — are routed to `$star-plan-decomposer`; research-question or method pivots are routed to `$star-plan-coach`. Prefixes are never renumbered, versioned copies are never created, and `EXEC_PLAN.md` / `EXEC_LOG.md` are never modified.

### Main outputs

```text
wkdrs/<run>/REVIEW_<date>.md          # review report (wkdrs/reviews/ when the plan has no run)
metds/plans/<prefix>_<slug>_plan.md   # revised in place, with a Revision History entry
```

### Practical guidance

- Run it after a leaf completes or blocks, before starting the next leaf — revision is cheapest while the evidence is fresh.
- Revising a parent bumps its `updated`, so `$star-plan-status` will flag its children as stale; that is the intended signal to re-decompose the affected children.
- For a quick progress overview use `$star-plan-status`; the reviser is for depth on one plan, with write access.

See the complete definition in [`star-plan-reviser/SKILL.md`](../../../.agents/skills/star-plan-reviser/SKILL.md).

## 12. `$star-metd-summarize`: compile the plans into method documents

### When to use it

- The plans have matured and you want the method written out as prose a reader can follow.
- You are starting a paper's method section and want the material assembled from what the plans already say.
- You want to see, in one place, where the method is still unwritten — every gap named with the plan section that should fill it.
- A collaborator needs to understand the method without reading the whole plan tree.

### How to invoke it

Compile one document:

```text
$star-metd-summarize framework
```

Compile all five:

```text
$star-metd-summarize
```

`OPT` is one of `overview`, `dataset`, `framework`, `training`, `evaluation`. With no argument the skill compiles all five in dependency order (`dataset` → `framework` → `training` → `evaluation` → `overview`, which links the other four and so goes last).

### What it does

1. Rebuilds the plan tree from each plan's `parent:`, exactly as the status skill does;
2. Extracts what each document needs through a written map — the root's §1–§3 and §6 for the overview, §4 data choices plus every leaf's `datas/` inputs for the dataset document, the §3 technical route plus modeling leaves and their `${CODE_NAME}/` paths for the framework, §3 strategy plus `inits/` and hyperparameters for training, §4 benchmarks, baselines, metrics and ablation design plus §5 kill-criteria for evaluation;
3. Merges the passages along the method's axis rather than the plan's, resolving conflicts leaf-over-parent and newer-over-older, and printing ⚠ with both sources when neither dominates;
4. Marks anything sourced from a leaf that has not been executed as not yet verified;
5. Turns every template section no plan covers into a `TODO` naming the plan and section that should carry it.

### Main outputs

| Document | Contents |
| --- | --- |
| `metds/overview.md` | Problem, gap, core idea, the component table, contributions as falsifiable claims, milestones |
| `metds/dataset.md` | Dataset inventory, per-dataset detail, preprocessing, constructed data, statistics, dataset→experiment map |
| `metds/framework.md` | Architecture as one data path, per-component detail with code locations, design decisions, difference from prior work, module map |
| `metds/training.md` | Stage pipeline, per-stage recipe, hyperparameter table, practical notes, reproduction commands |
| `metds/evaluation.md` | Protocol overview, benchmark detail with meaningful margins, baselines, ablation design, evaluation commands |

Each document records in its frontmatter the plans it was compiled from and the `updated` date each carried, which is how the next run detects that a document has gone stale.

### The fabrication boundary

Plans are the only source. The skill does not read code, logs, `wkdrs/`, or chat history, and it never fills an unstated value with a plausible default — an unstated learning rate stays `TBD` and becomes a gap, because a plausible default here is a wrong number in a paper. Result numbers never enter these documents either: `evaluation.md` defines the protocol, while what a run actually scored stays in `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`. If execution detail is missing from a document, the fix is a plan sync by `$star-plan-executor`, not a wider read.

### Practical guidance

- Compile early and often. The gap list is most useful *before* the writing deadline, when there is still time to answer what it asks.
- Treat these documents as generated. To change one, change the plan it came from and recompile — hand edits are overwritten on the next run, though a file the skill did not generate is never overwritten without asking first.
- A regeneration whose sections are all unchanged writes nothing, so re-running it costs you only the reading.

See the complete definition in [`star-metd-summarize/SKILL.md`](../../../.agents/skills/star-metd-summarize/SKILL.md).

## 13. `$star-plan-status`: inspect the plan tree

### When to use it

- You want to know how far the overall research plan has progressed.
- You are unsure which sub-plan should be decomposed or executed next.
- You want to inspect dependencies, blockers, commands awaiting the user, or stale plans.
- You need a quick context refresh at the beginning of a new session.

### How to invoke it

Inspect all plans:

```text
$star-plan-status
```

Inspect one plan subtree:

```text
$star-plan-status open-vocab-det-seg
$star-plan-status 01
```

### What it reports

- A plan tree annotated with status;
- Strategy-section completeness, decomposition coverage, and leaf execution progress;
- Each leaf's dependencies, logged step progress, blockers, or commands awaiting the user;
- Exactly one recommended next runnable leaf, with a reason;
- Drift such as a child older than its parent, dangling links, invalid dependencies, or orphaned runs.

This skill is **strictly read-only**. It scans `metds/plans/` and `wkdrs/<run>/EXEC_LOG.md` without creating or modifying any file.

See the complete definition in [`star-plan-status/SKILL.md`](../../../.agents/skills/star-plan-status/SKILL.md).

## 14. End-to-end example

The following sequence illustrates a typical workflow.

### Step 1: turn an idea into a plan

```text
$star-plan-coach I want to study more reliable text-description generation for open-vocabulary detection and segmentation
```

After the staged discussion, this may produce:

```text
metds/plans/0_open-vocab-det-seg_plan.md
```

With the method section in place, `$star-refs-reviewer open-vocab-det-seg` reads the closest work into `metds/refs/` and builds the verified `reference.bib` the positioning and the baselines both draw on.

### Step 2: split it into execution units

```text
$star-plan-decomposer open-vocab-det-seg
```

After confirming milestone-based decomposition, the skill may produce:

```text
00_mvp-3way-ablation_plan.md
01_core-method-pipeline_plan.md
02_full-experiments_plan.md
03_writing-submission_plan.md
```

### Step 3: give the plan a code home (first run only)

```text
$star-code-architect
```

After Gate 1 (pick the scored reference repository) and Gate 2 (approve the migration table), `${CODE_NAME}/` holds the renamed, provenance-tracked codebase and `metds/codearc.md` records the architecture every later step follows.

### Step 4: build the runtime environment (first run only)

```text
$star-env-builder
```

After the install-plan gate, the environment is created, dependencies install through the uv > pip > conda ladder, and a three-layer smoke test writes its evidence to `wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md`.

### Step 5: identify the next task

```text
$star-plan-status open-vocab-det-seg
```

If the report recommends `00_mvp-3way-ablation`, run:

```text
$star-plan-executor 00_mvp-3way-ablation_plan.md
```

### Step 6: resume after the STOP line

If the log contains a training command that the user must run:

1. Run the command recorded in `wkdrs/00_mvp-3way-ablation/EXEC_LOG.md`;
2. Confirm that its artifacts were written to the recorded paths;
3. Invoke `$star-plan-executor 00` again;
4. The skill reads the existing log and resumes at done-criterion verification.

### Step 7: repeat

After each leaf is complete, run:

```text
$star-plan-status
```

Follow its single next-step recommendation until all leaves are complete. After a leaf completes, run `$star-code-reviewer <leaf>` to audit the new code before building on it. Once you have run the STOP-line commands and the results are on disk, run `$star-expt-analyst <leaf>` to score them against the plan's done-criteria and find out what they mean. Then — or when a result invalidates a key assumption — run `$star-plan-reviser` on the affected plan to fold the evidence back into its text; it routes structural changes to `$star-plan-decomposer` and strategy pivots to `$star-plan-coach`.

### Step 8: compile the method for the paper

Once the plans have absorbed what execution taught them:

```text
$star-metd-summarize
```

This compiles `metds/overview.md`, `dataset.md`, `framework.md`, `training.md`, and `evaluation.md` from the plan tree. Anything sourced from a leaf that has not been executed is marked not yet verified, and every uncovered section becomes a `TODO` naming the plan section that should fill it — so the gap list doubles as the to-do list for the plans. Recompile whenever the plans move; a document whose sources have not changed is left untouched.

## 15. Frequently asked questions

### Which skill should I use first?

| Current situation | Use |
| --- | --- |
| You only have an idea and the research question is still unclear | `$star-plan-coach` |
| The method is clear but you do not yet know the closest work, the baselines, or how to cite them | `$star-refs-reviewer` |
| You have a strategic plan and need executable tasks | `$star-plan-decomposer` |
| The plan is ready but `${CODE_NAME}/` is empty, or the codebase needs organizing | `$star-code-architect` |
| The codebase exists but there is no usable runtime environment | `$star-env-builder` |
| You have a concrete leaf task and need code plus verification | `$star-plan-executor` |
| The implementation landed and you want the code audited against conventions and the plan | `$star-code-reviewer` |
| A run produced results and you want to know what they mean and whether they met the plan | `$star-expt-analyst` |
| A plan was (partly) executed and its text should absorb the results | `$star-plan-reviser` |
| The plans have matured and you want the method written out for a reader or a paper | `$star-metd-summarize` |
| You do not know the current status or next action | `$star-plan-status` |

### Why will the executor not run the plan I selected?

The usual causes are that the target is not a leaf, an entry in `depends_on` is unfinished, the task breakdown/done-criterion still contains too many `[TBD]` items, or the `.env` environment itself is unusable — `$star-env-builder` rebuilds it. Running `$star-plan-status` first usually reveals the exact reason.

### Why was a training command recorded instead of executed?

Full training, full-dataset evaluation, and high-cost calls cross the STOP line. The skill makes the command and output paths reproducible, while leaving the decision about when to consume those resources to the user.

### How do I continue across sessions?

- The coach resumes from section statuses in the plan frontmatter;
- The refs reviewer resumes from `metds/refs/`: existing notes and verified `reference.bib` entries are the baseline, and a re-run only fills the gaps;
- The decomposer resumes from parent-child links and existing sub-plans;
- The executor resumes from the `EXEC_LOG.md` referenced by `exec_run`;
- The env builder resumes via *verify & repair in place* from the latest `wkdrs/env_*/ENV_REPORT.md`;
- The code reviewer's reports persist under `wkdrs/` (the run directory or `wkdrs/reviews/`), and applied fixes live in git;
- The experiment analyst's reports persist under `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`, alongside any figures it rendered;
- The reviser's report persists under `wkdrs/`, and every applied change is recorded in the plan's `## Revision History`;
- The method summarizer needs no memory of its own: it recompiles from the plans, and each document's `sources:` frontmatter records which plans it came from and how fresh they were;
- The status skill can reconstruct the global state read-only at any time.

### Can I edit plan files manually?

Yes, but keep the frontmatter consistent with the body, especially `parent`, `children`, `depends_on`, `status`, `exec_status`, and `exec_run`. After changing a parent plan, run `$star-plan-status` to check for drift before deciding whether to decompose it again.

## 16. Skill locations

Each tool has an adapted, authoritative copy of the skills. Do not mix tool-specific invocation or control instructions across these roots:

| Tool | Authoritative directory | Invocation form |
| --- | --- | --- |
| Codex | `.agents/skills/` | `$star-*` |
| Claude | `.claude/skills/` | `/star-*` |
| Cursor | `.cursor/skills/` | `/star-*` |

The eleven skill directory names are:

```text
star-plan-coach
star-refs-reviewer
star-plan-decomposer
star-code-architect
star-env-builder
star-plan-executor
star-code-reviewer
star-expt-analyst
star-plan-reviser
star-metd-summarize
star-plan-status
```
