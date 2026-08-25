# Research Workflow Skills Guide

**Language:** English | [简体中文](research-workflow-skills.zh-CN.md)

STAR's fifteen connected research workflow skills turn a vague research interest into a defensible topic backed by a landscape scan, a traceable plan, a related-work base with a verified bibliography, a codebase with a recorded architecture, a verified runtime, executable tasks, an implementation backed by verification records, code audited against the project's conventions, results audited against what the plan expected, progress digested over time, plans that absorb execution results, method documents compiled out of those plans, and finally a repository a stranger can clone:

```text
an already-started project
  → star-proj-adopt: bring it into STAR without disturbing it, and inventory what is already done

vague research interest
  → star-idea-storm: diverge, scan the landscape, and converge on a topic
  → star-plan-coach: create a top-level research plan
  → star-refs-reviewer: read the closest work and build a verified bibliography
  → star-code-architect: give the plan a place for the code to live and record the architecture
  → star-env-builder: build and verify the runtime environment
  → star-plan-decomposer: split it into execution sub-plans with dependencies
  → star-plan-executor: implement and verify one leaf sub-plan
  → star-code-reviewer: audit the implementation against conventions and the plan
  → star-expt-analyst: audit the run's results against what the plan expected
  → star-plan-reviser: review a plan against execution evidence and revise it
  → star-metd-summarize: once every leaf is executed and the plans finalized, compile them into method documents
  → star-code-release: consolidate the code and compile the project's README

  ⌾ star-expt-digest: reads across the loop regularly —
    what the programme did this period, and what moved
  ⌾ star-flow-status: reads all of the above at any point —
    where things stand, what follow-up is outstanding, and the one next action
```

The list reads as one pass, but the workflow is not linear: `star-proj-adopt` runs only when an existing project is adopted (never for one started from the template), `star-idea-storm` only while the topic is open (skip it when one is chosen), `star-code-architect` and `star-env-builder` only on the first pass; `star-plan-executor` through `star-plan-reviser` is a loop re-entered per leaf sub-plan, with `star-expt-digest` run regularly across it rather than inside it, `star-metd-summarize` only once the loop has closed — every leaf executed, the plans finalized — and `star-code-release` last, once the work is ready for someone else to read. `star-flow-status` names the next leaf each round, and the audits route what they find back into the plans:

![STAR research workflow: thirteen skills in the order they run in plus two that read across them, what each one writes, and how the per-leaf loop closes](../../srcs/star-research-workflow.png)

**Where to start.** Research runs in an order of its own: settle what you are asking, write it down as a plan and read the closest work while you position it, give the code and the runtime somewhere to live, split the plan into separately answerable questions, run the experiment, read what came back, take that back into the plan, write it up. Each stage below leaves something on disk for the next, which is what lets the work be picked up days later. Find the stage you are in, and read that skill's section first.

| Research stage | The skill that carries it | What it writes | What the next stage works from |
| --- | --- | --- | --- |
| Settle what you are asking | `star-idea-storm` | `metds/ideas/<slug>_idea.md` | A one-sentence question, the gap it sits in, and a first experiment that could kill it |
| Write the plan, reading the field as you position it | `star-plan-coach`, breaking out to `star-refs-reviewer` | `metds/plans/<digit>_<slug>_plan.md`; `metds/refs/`: one note per core paper, `reference.bib`, `refs_index.md` | Problem, positioning, method, experiments, risks and milestones, positioned against work read rather than recalled — plus the baselines the field expects, and the `finalized` date that lets the plan be split |
| Give the code and the runtime somewhere to live | `star-code-architect`, then `star-env-builder` | `${CODE_NAME}/` and `metds/codearc.md`; `wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md` | Modules a leaf can name by path, and an interpreter that has already imported them |
| Split it into separately answerable questions | `star-plan-decomposer` | one sub-plan per unit, flat under `metds/plans/` | One leaf per question, each with its own deliverables and one runnable done-criterion |
| Run the experiment | `star-plan-executor` | `wkdrs/<run>/EXEC_PLAN.md`, `EXEC_LOG.md`, and the run's own artifacts | Code, its light-validation evidence, and the training or evaluation command handed back for you to run |
| Check the code the numbers will rest on | `star-code-reviewer` | `wkdrs/<run>/CODE_REVIEW_<date>.md` | Findings by severity, caught before the compute is spent rather than after |
| Read what came back | `star-expt-analyst` | `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`; `wkdrs/results/results.md` in `aggregate` mode | Every done-criterion scored `met` / `not met` / `unmeasurable`, with the source behind each number |
| Take the result back into the plan | `star-plan-reviser` | the plan revised in place, plus `wkdrs/<run>/REVIEW_<date>.md` | A plan that matches the evidence, and a tree no longer recommending a direction the evidence closed |
| Write the whole thing up | `star-metd-summarize`, then `star-code-release` | `metds/overview.md`, `dataset.md`, `framework.md`, `training.md`, `evaluation.md`; `README.md` | The method in prose and the numbers in one table — what a paper's method and results sections are written from |

Two skills sit outside that order: `star-flow-status` reads the whole tree at any point and names the one next action; `star-expt-digest` says what the experiments did over a period and what moved since the last one. A project already months old enters at `star-proj-adopt`, which records what was built and run as evidence before joining the table at the plan.

Plan state lives in project files, so work continues across conversations and sessions.

Idea framing, plan sections, literature notes and synthesis, experiment digests, method documents, and release README prose all apply the shared [human-writing guide](human-writing-guide.md) at the point where narrative text is drafted. It removes formulaic patterns at paragraph scale while preserving the evidence record: facts, citations, numbers, dates, paths, commands, status values, uncertainty, and negative results do not move with the style pass.

## Contents

- [1. Invoking the skills](#1-invoking-the-skills)
- [2. Before you start](#2-before-you-start)
- [3. `star-proj-adopt`: adopt an in-progress project](#3-star-proj-adopt-adopt-an-in-progress-project)
- [4. `star-idea-storm`: converge on a research topic](#4-star-idea-storm-converge-on-a-research-topic)
- [5. `star-plan-coach`: write a research plan](#5-star-plan-coach-write-a-research-plan)
- [6. `star-refs-reviewer`: survey the related work](#6-star-refs-reviewer-survey-the-related-work)
- [7. `star-code-architect`: set up or organize the codebase](#7-star-code-architect-set-up-or-organize-the-codebase)
- [8. `star-env-builder`: build the runtime environment](#8-star-env-builder-build-the-runtime-environment)
- [9. `star-plan-decomposer`: create execution sub-plans](#9-star-plan-decomposer-create-execution-sub-plans)
- [10. `star-plan-executor`: execute one leaf plan](#10-star-plan-executor-execute-one-leaf-plan)
- [11. `star-code-reviewer`: review code against conventions and the plan](#11-star-code-reviewer-review-code-against-conventions-and-the-plan)
- [12. `star-expt-analyst`: analyze a run's results](#12-star-expt-analyst-analyze-a-runs-results)
- [13. `star-expt-digest`: summarize progress over a period](#13-star-expt-digest-summarize-progress-over-a-period)
- [14. `star-plan-reviser`: review and revise one plan](#14-star-plan-reviser-review-and-revise-one-plan)
- [15. `star-flow-status`: inspect the whole flow](#15-star-flow-status-inspect-the-whole-flow)
- [16. `star-metd-summarize`: compile the plans into method documents](#16-star-metd-summarize-compile-the-plans-into-method-documents)
- [17. `star-code-release`: prepare the repository for release](#17-star-code-release-prepare-the-repository-for-release)
- [18. End-to-end example](#18-end-to-end-example)
- [19. Frequently asked questions](#19-frequently-asked-questions)
- [20. Skill locations](#20-skill-locations)

## 1. Invoking the skills

This guide names a skill plainly, without a prefix, because each tool supplies its own: `/` in Claude Code, Cursor, Pi and Qwen Code, `$` in Codex, `/skill:` in Kimi Code and DSH.

```text
star-proj-adopt
star-idea-storm open-vocabulary perception
star-plan-coach open-vocabulary detection and segmentation
star-refs-reviewer open-vocab-det-seg
star-code-architect
star-env-builder
star-plan-decomposer 0_open-vocab-det-seg_plan.md
star-plan-executor 00
star-code-reviewer 00
star-expt-analyst 00
star-plan-reviser 00
star-flow-status
star-metd-summarize framework
star-code-release
```

Seven skills — `star-proj-adopt`, `star-idea-storm`, `star-plan-coach`, `star-code-architect`, `star-plan-decomposer`, `star-plan-reviser`, `star-code-release` — are slash-only: they run only when named explicitly, because each sits on a decision that belongs to the researcher ([conventions §10](research-workflow-conventions.md)). Each harness enforces it, rather than convention — `disable-model-invocation: true` in the Claude, Cursor, DSH, Kimi, Pi and Qwen Code manifests, `allow_implicit_invocation: false` in Codex's `.agents/skills/<name>/agents/openai.yaml`. Describing one in prose (“Break this research plan into executable sub-plans.”) will not start it: the agent answers from general knowledge, producing plan-shaped files with none of the `parent:` / `children:` / `traces_to` frontmatter the rest of the workflow reads. The agent may pick the other eight up when the task plainly matches and the target is unambiguous — naming one explicitly still works, and is how you say which you meant.

When a skill needs a target plan, `PLAN_NAME` accepts three forms:

| Form | Example | Best used when |
| --- | --- | --- |
| Slug | `open-vocab-det-seg` | The name is unique |
| Numeric prefix | `01` | The prefix is unique in the plan tree |
| Full filename | `01_mvp-verify_plan.md` | The most explicit form; recommended when roots or names overlap |

Multiple root plans may currently start with `0_`. If a match is ambiguous, use the slug or full filename.

Any invocation also accepts an optional `involve=low|medium|high` token setting how much this run asks before deciding — e.g. `star-plan-executor 00 involve=low`. `low` takes the recommended option on judgment calls (and logs each), `high` confirms step by step; it overrides `INVOLVE` in `.env` for that run, and telling a running skill "ask me less" changes it mid-run. Mandatory confirmation points — the STOP line, every deletion and overwrite, any ambiguity about what you meant — always ask, at every level; the commit offer is a judgment call, so `low` takes it unasked and names the commits afterward. Full rule: [conventions §7.7](research-workflow-conventions.md).

Every skill also takes an optional description — free text after the argument, in your own words, what this run is for: `star-plan-reviser 01 this one is finished, 02 replaces it`. It is a lead, not a command: it can route a run down one of that skill's own paths and supply words the run records — the example both drops the plan and becomes the reason written into it — but never replaces a confirmation point, never settles an ambiguous plan name, never authorizes anything on the STOP line. A description-routed run says which path it took before it writes, so a misreading costs one line rather than one wrong edit. Where a skill's first argument is already free text — `star-idea-storm`, `star-plan-coach`, `star-refs-reviewer` — that argument is the description. Full rule: [conventions §7.12](research-workflow-conventions.md).

## 2. Before you start

Which stage in the table above you enter at is decided by three facts about the work in front of you, not by the workflow:

- **Is the question settled?** Still open — an interest, a hunch, three directions you cannot choose between — start at `star-idea-storm`: it diverges, scans the directions you keep against the literature, converges before anything becomes a plan. Already decided and sayable in one sentence, start at `star-plan-coach`. Decided a while ago and not read against since, run `star-refs-reviewer survey <topic>` first, so the plan's gap is written against the field, not from memory.
- **Is the repository new, or has the project been running for months?** Real code, months of commits, results already in hand — that is adopted, not restarted. `star-proj-adopt` records what was built, run and concluded as evidence, and the plan is written afterwards, over work that already exists.
- **Is there code to start from, and does anything run yet?** `star-code-architect` starts the codebase from a scored reference implementation, or organizes the code already there, and records the architecture the later steps follow; `star-env-builder` turns that into an interpreter that has demonstrably imported the project. Both are first-pass steps, before the first leaf executes.

Whichever way you come in, the setup is the same:

- Use these skills from the root of a STAR project.
- Keep all research plans under `metds/plans/`.
- Before setting up the codebase or executing code, create a local `.env` and set `CODE_NAME`, plus either `PYTHON_HOME` alone or `CONDA_HOME` and `ENV_NAME` together.
- Put reusable code under `${CODE_NAME}/`, data under `datas/`, model weights under `inits/`, and generated results under `wkdrs/`.
- Both English and Chinese are supported. A skill follows the conversation language — or `STAR_LANG` from `.env` when that is set (conventions §7.6) — while an existing plan keeps the body language its frontmatter `language` field declares.

- What every skill does the same way — git, the STOP line, `.env` runtime, real dates, plan-name resolution, delegation, dialogue — is written once in [Research Workflow Skill Conventions](research-workflow-conventions.md). Read it to know what the workflow will and will not do to your repository.

You do not need prepared data, weights, or runnable code to draft or decompose a plan; those inputs are checked during execution.

Every artifact a skill writes records which model produced it, so a later comparison across models has something to key on: `model_id` for that write, and — on artifacts written across several sessions — an append-only `model_trail`, one entry per session, which `star-expt-digest ledger` rolls into `wkdrs/digests/MODEL_LEDGER.md`. The value is what the runtime reported at write time: self-reported, not verified, so read it as evidence of provenance rather than proof. Full rule: [conventions §8](research-workflow-conventions.md); per-runtime fallbacks, for a session whose runtime named no model, are in [`model_id_spec.md`](model_id_spec.md).

## 3. `star-proj-adopt`: adopt an in-progress project

### When to use it

- The project already exists — real code, a working environment, months of commits, results in hand — and it did not start from the STAR template.
- Data, weights, and outputs live in directories STAR knows nothing about, and you do not want to move them.
- You want what is built, run, and concluded recorded as evidence rather than retyped from memory.
- The plan tree is written but reads as 0%, the leaves it describes having been finished months ago.

### How to invoke it

A project that never had the template has no `execs/` and no skills to invoke, so install the skeleton from upstream first, at the repository root:

```text
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o /tmp/star-update.sh
bash /tmp/star-update.sh --adopt
```

`--adopt` installs into the current working directory, which must be a git repository root, and never overwrites an existing file: every such path is left alone and reported (`bash execs/update.sh --help` describes the rest). Then:

```text
star-proj-adopt              # auto-select the phase
star-proj-adopt survey       # inspect the repository and land the setup
star-proj-adopt backfill     # make the plan tree reflect finished work
```

With no argument the phase is detected: no `metds/adopt.md` yet → `survey`; an adoption record plus a decomposed plan tree (≥1 sub-plan carrying `parent:`) → `backfill`. Re-running `survey` on an adopted project re-inspects and updates the record, never starts over.

### What it does

Phase `survey`, before the plan tree exists:

1. Surveys the repository **read-only** across six areas — the source directory, the runtime in use, where data / weights / outputs currently live, the launch entrypoints, the existing tests, and the shape of the git history — and reports the mapping as one block, a confidence on every line;
2. **Confirmation point 1:** you confirm the mapping, one question at a time, only for what the survey could not settle. Nothing is written until the user answers;
3. Puts the mechanical setup in place: `.env` from `.env.example`, symlinks at `datas/` / `inits/` / `wkdrs/` that *reach* the existing trees instead of relocating them, one `execs/scpts/<name>.sh` per entrypoint calling the project's existing command unchanged;
4. Builds a work inventory — one row per identifiable unit of finished or in-flight work: what it is, its state (`built` / `run` / `concluded` / `abandoned`), and the paths, commits, scripts or log lines that evidence it;
5. **Confirmation point 2:** you pick which of the prior runs found on disk are recorded. Each chosen run is symlinked to `wkdrs/<run>/` and given a reconstructed `EXEC_LOG.md` — labelled as reconstructed, with no step table, there having been no steps to record. The rest stay in the inventory as evidence, and the report says how many were left out;
6. Writes `metds/adopt.md`, then routes on: `star-code-architect` for the architecture spec (its organize path surveys the existing code, which adoption deliberately does not duplicate), `star-plan-coach` for the research plan (it seeds from the work inventory), `star-plan-decomposer` for the leaves, finally `star-proj-adopt backfill`.

Phase `backfill`, once the leaves exist:

1. Matches inventory rows to leaves on evidence overlap — a shared path, script, or module, never name similarity alone — and reports both misfits: inventory items no leaf covers, and leaves nothing in the inventory reaches;
2. **Confirmation point 3:** you confirm leaf by leaf. An unconfirmed leaf is left exactly as it is;
3. Writes `exec_status` and, where that row's run was recorded, `exec_runs` on the confirmed leaves (updating that reconstructed log's `source_plan:` to the leaf in the same pass), appends a dated backfill record to `metds/adopt.md`, stamps its `backfilled:` date, and hands off to `star-flow-status` for the adopted project's first honest picture.

### Main output

```text
metds/adopt.md
```

The record holds the confirmed mapping, the symlink and wrapper results, the work inventory with its evidence, the recorded runs, one dated entry per backfill pass.

### What it never touches

Nothing moves, nothing is renamed, nothing already written is overwritten — the whole skill turns on that constraint. `${CODE_NAME}/` and everything under it, the project's own launchers, configs and CI are read, never edited; a path it would write that already exists becomes a question, not a resolution; a symlink is never created over a non-empty real directory. On plan files its only exception is the two frontmatter fields above, on leaves you confirmed individually — plan bodies, `status`, `finalized`, `children`, `depends_on` are never its to write. Adoption invents no research strategy either: the inventory describes what the repository shows; why the work was done, what claim it supports, and what would have killed it are left for `star-plan-coach` to ask you. A plan tree fabricated from a git log is worse than none.

### Practical guidance

- Run it before anything else on an existing project, and skip `star-idea-storm` — the code that exists chose the topic.
- An unknown reported as unknown is the point of this skill; a confidently wrong `CODE_NAME` costs you every downstream skill.
- Record the runs whose numbers you would still quote. The rest belong in the inventory as evidence, not `wkdrs/`.
- Run `backfill` even when it covers only two leaves. A tree reading 0% while a third of the work is done is a tree nobody trusts.

See the complete definition in [`star-proj-adopt/SKILL.md`](../../../.agents/skills/star-proj-adopt/SKILL.md).

## 4. `star-idea-storm`: converge on a research topic

### When to use it

- You have an interest area, a hunch, or a frustration — but no committed research topic.
- You are torn between several directions and want them compared on evidence rather than mood.
- You want to know how crowded a direction is, and who is closest, before investing in it.
- A parked direction may have revived — new evidence arrived and the decision deserves a re-run.

### How to invoke it

Start a new storm from a seed:

```text
star-idea-storm open-vocabulary perception
```

Resume (or reopen) an existing exploration:

```text
star-idea-storm open-vocab-perception
star-idea-storm
```

An idea name (slug or filename under `metds/ideas/`) resumes that exploration; no argument resumes the unfinished one, or asks for a seed.

### What it does

The skill discusses one question at a time and moves through five stages — diverge before converge:

1. Seed and constraints: what drives the interest, and the compute / data / time / venue box the topic must fit;
2. Diverge: 3–5 genuinely distinct candidate directions (different problem, bet, or setting), of which you keep 2–4;
3. Landscape scan: per kept direction, an abstract-level scan — 8–15 papers with venue, year, citations, and record URL, how crowded the area is, the 3 closest works, and the apparent gap. Every named paper is transcribed from a record fetched during the run and cached under `wkdrs/ideas_<date>/raw/` — nothing from memory, and Google Scholar is never scraped;
4. Converge: each scanned direction scored on six dimensions (novelty, impact, feasibility, crowdedness/scoop-risk, personal fit, evaluability) with a Pursue / Refine / Park verdict — advice, not a ruling: you decide, and overruled verdicts are recorded with their reason;
5. Frame: the winner becomes a topic statement — a one-sentence research question, the gap naming the closest scanned works, why now, a first validation experiment with an explicit kill-condition. After your confirmation the file is `finalized`.

The scan reads abstracts by default and says so; naming a direction deepens its top-3 to intro level, and the depth is recorded. Parked directions keep their scan evidence and a note on what would make revisiting them worthwhile.

### Main output

```text
metds/ideas/<slug>_idea.md
```

For example:

```text
metds/ideas/open-vocab-perception_idea.md
```

The idea file holds the seed and constraints, all candidate directions, the per-direction scan tables, the scored comparison and decision, the topic statement, and the parked directions. Once `finalized`, it seeds the plan: `star-plan-coach <slug>` pre-drafts its Problem stage from the topic statement, and `star-refs-reviewer` falls back to it when no plan or method notes exist.

### Practical guidance

- One vague sentence is enough to start; the skill asks before it widens.
- Keep directions that differ in kind, not in wording — the scan is most useful when the candidates would be scooped by different papers.
- The scan prices a direction; it does not veto it. A crowded field with a real angle can still be the right call, and the file records that choice with its reason.
- This is topic selection, not the survey: expect abstracts and a map, not per-paper analyses. The deep read on the winner belongs to `star-refs-reviewer`.

See the complete definition in [`star-idea-storm/SKILL.md`](../../../.agents/skills/star-idea-storm/SKILL.md).

## 5. `star-plan-coach`: write a research plan

### When to use it

- You have an early idea but not how to turn it into a complete research direction.
- You want to write or improve a research plan, proposal, or thesis proposal.
- You want to resume a partially written plan.
- You need to strengthen the problem, related work, method, experiments, or risk analysis.

### How to invoke it

Start a new plan:

```text
star-plan-coach open-vocabulary detection and segmentation
```

Seed a new plan from a finalized idea file:

```text
star-plan-coach open-vocab-perception
```

An argument matching `metds/ideas/*_idea.md` by slug or filename seeds the plan from that file: the plan reuses the idea's slug, and the Problem stage opens with a draft built from its topic statement — confirmed and sharpened rather than asked from scratch.

Resume an existing plan:

```text
star-plan-coach
```

Reopen one section of a finished plan:

```text
star-plan-coach open-vocab-det-seg related_work
```

The section key is one of `problem` / `related_work` / `method` / `experiments` / `risks` / `milestones`. This is the way back into a `finalized` plan when something outside it moved — a closer paper `star-refs-reviewer` found, a result that changed the positioning, a reviewer's objection. The section is coached alone, the whole plan re-checked against the rubric, and `finalized` re-dated.

With no topic, the skill scans `metds/plans/*_plan.md`; finding unfinished plans, it asks whether to continue one or create a new plan.

### What it does

The skill discusses one question at a time and moves through six stages:

1. Problem definition and motivation;
2. Related work and positioning;
3. Core method;
4. Experiments and validation;
5. Risks and fallbacks;
6. Milestones and deliverables.

At the end of each stage, the skill turns the discussion into structured prose; once confirmed, it writes the section immediately and updates its status. You can ask to skip a section, leave `[TBD]` items, or have the AI draft one for later confirmation.

### Main output

```text
metds/plans/<digit>_<slug>_plan.md
```

For example:

```text
metds/plans/0_open-vocab-det-seg_plan.md
```

The plan contains six research sections and their statuses. Once all are complete, the skill runs a quality check and adds a `finalized` date after you approve the plan.

### Practical guidance

- One or two sentences about the research topic are enough to begin; you do not need a complete proposal first.
- If you are unsure about an experiment or metric, say so: the skill offers two or three concrete candidates.
- Do not decompose the plan before its key sections are confirmed, or downstream sub-plans fill with `[TBD]` items.
- Arriving without `star-idea-storm` and without recent reading? Run `star-refs-reviewer survey <topic>` first, so §1's gap is written against a map of the field rather than from memory.

See the complete definition in [`star-plan-coach/SKILL.md`](../../../.agents/skills/star-plan-coach/SKILL.md).

## 6. `star-refs-reviewer`: survey the related work

### When to use it

- The plan's Related Work section needs the closest works and their limits, read rather than recalled.
- You are heading toward a paper and need a `reference.bib` you can trust in a submission.
- You want the baselines and benchmarks the field expects before sizing the experiments.
- A new paper appeared and you want it analyzed and folded into the existing base.
- You want a map of a whole field — possibly before any plan exists — rather than positioning for one method.

### How to invoke it

```text
star-refs-reviewer                        # read the method from metds/, run the full pass
star-refs-reviewer open-vocab-det-seg     # scope the search to one plan
star-refs-reviewer open-vocabulary segmentation   # a free-text topic
star-refs-reviewer 2103.00020             # append one paper by arXiv id, DOI, or URL
star-refs-reviewer add 2103.00020, 2304.02643, "Attention Is All You Need"   # append several at once — ids, DOIs, URLs, titles mixed
star-refs-reviewer verify                 # re-fetch every entry and diff it against the file
star-refs-reviewer organize               # re-classify the existing bib, offline
star-refs-reviewer score                  # refresh citation/star metrics, rebuild the impact-score table
star-refs-reviewer synthesize             # compile the notes into metds/refs/related_work.md
star-refs-reviewer survey <topic>         # map a field into metds/refs/<slug>_survey.md
```

With no argument the skill looks for the method in `metds/*.md`, falls back to the root plan under `metds/plans/`, then asks you for a topic. Once `metds/refs/` exists, runs are incremental: gaps get filled, verified entries left alone. `survey` resolves its own trailing text the same way — a plan name, free text, or with neither the same fallback chain. `add` splits its list on newlines and commas — quoted text is a title, resolved to a fetched record before anything is read: a clean single match proceeds, several candidates get asked about, an unfindable one goes to the manual-check list rather than a guess. A list of nothing but ids and URLs works without the keyword; a bare title without `add` is a topic.

### What it does

1. Extracts a search profile from the method — task, mechanism, setting, named datasets and baselines, the claim it wants to make — and states it before searching;
2. Runs 5–8 queries across web search and the Semantic Scholar / DBLP / arXiv endpoints, brings about 15 ranked candidates to you, and reads only the 5–10 you keep;
3. Reads each confirmed paper (abstract, intro, method and the main results table at minimum) into an analysis note, written to disk immediately;
4. Expands the pool past 50 through the core papers' reference lists, the work citing them, and gap-filling queries, preferring published versions to preprints;
5. Fetches an authoritative record per paper (DBLP → Crossref → Semantic Scholar → arXiv), caches it under `wkdrs/refs_<date>/raw/`, and transcribes it — a paper with no fetchable record is named in the bib's `%% Needs manual check` block instead of guessed at;
6. Classifies everything into 3–8 categories derived from what was collected, writes `reference.bib` grouped by category with a `% src:` provenance line above every entry, and logs every entry's source in the index;
7. Scores every entry it can reach — citations per year, venue tier, stars and freshness of the paper's own repo, composed by fixed weights into a 0–10 impact score whose sub-signals and fetch dates land in the index — closeness still decides what is core, the score emphasis;
8. Re-fetches five entries at random and diffs them field by field before finishing.

In `survey` mode the same search machinery feeds a different artifact: the pool is kept rather than cut to 15, read in three tiers (8–12 papers deeply, 15–25 at abstract level, the rest from their records — relevance and impact score tier them together), organized under a taxonomy whose division axis is declared in a sentence, written as a standalone field survey where every claim cites a source fetched during the run. One question precedes the reading — profile, taxonomy axis, tiered list — and `involve=low` answers it by its recommendation, so a survey can run unattended end to end. It touches neither `reference.bib` nor `refs_index.md`; promoting a paper it surfaced is one append run later.

### Main outputs

```text
metds/refs/<ABBREV>.md        # one analysis note per core paper (CLIP.md, DETR.md, …)
metds/refs/reference.bib      # ≥50 entries, grouped by category, % src: per entry, keys Year_Method_FirstAuthor
metds/refs/refs_index.md      # core-paper table, categories, provenance, impact scores, needs-manual-check
metds/refs/related_work.md    # related-work narrative compiled from the notes (synthesize mode)
metds/refs/<slug>_survey.md   # standalone field survey, read in tiers (survey mode)
```

Each note carries a TL;DR, the problem, the method, the results, and — the reason it exists — a *Relation to This Project* section: shared ground, where it differs, what is borrowable, what it lets you claim.

### The fabrication boundary

A bib field is legal only if it appears in a record fetched during the run. Nothing is written from memory, no field "corrected", no missing page range inferred; a paper whose record cannot be fetched is listed for manual check rather than guessed. Every entry's source URL and fetch date go into `refs_index.md`, so any field can be re-checked later — what `star-refs-reviewer verify` does. The impact scores obey the same boundary: citations per year, venue tier and repo stars are fetched, dated metrics composed by fixed arithmetic — never impressions — and `star-refs-reviewer score` re-fetches them once they drift.

Google Scholar is deliberately not a source: it has no API, gates automated queries behind CAPTCHAs, and its exported bibtex is itself machine-generated — often missing pages, abbreviating venues, preferring the preprint over the published record. The skill fetches instead from the databases that bibtex is generated from, which is automatable and closer to the source. Read Scholar yourself if you like; the skill never scrapes it.

### Practical guidance

- Two moments call for it: at the coach's §2 (related work and positioning), before that section is written — the break-out the coach recommends itself — and again once §3 (core method) is clear, before decomposition, where the search profile is richest and the sub-plans still need their baselines.
- Prefer a reported shortfall to padding: 43 entries you can defend beat 50 you cannot.
- The *Relation to This Project* section is what makes a note worth more than the paper's abstract — read it before writing the plan's positioning.
- The impact score sets emphasis, never membership: the closest paper stays core with zero stars, and related-work prose leads with the high scorers a reviewer expects. Outside CS/AI, retune the venue tiers and bins shipped with the skill.

See the complete definition in [`star-refs-reviewer/SKILL.md`](../../../.agents/skills/star-refs-reviewer/SKILL.md).

## 7. `star-code-architect`: set up or organize the codebase

### When to use it

- The plan (or its sub-plans) is ready, but `${CODE_NAME}/` is empty and execution has nowhere to go.
- You want a GitHub reference implementation as the starting codebase, renamed to `CODE_NAME` and tracked for provenance.
- The codebase exists but has grown disorganized, and you want it surveyed, selectively migrated, its architecture recorded.
- You want an architecture spec that later coding — by any agent — must follow.

### How to invoke it

```text
star-code-architect
star-code-architect https://github.com/<owner>/<repo>
star-code-architect open-vocab-det-seg
```

With no argument, the skill resolves the root plan and inspects `${CODE_NAME}/` itself. A GitHub URL skips the search and uses that repository; a plan name chooses which plan drives the search.

### What it does

When `${CODE_NAME}/` is missing or empty (set up):

1. Extracts a search profile from the plan: task domain, method keywords, named baselines, framework constraints;
2. Searches GitHub and scores candidates on plan fit, completeness, license, activity, code quality, environment match;
3. **Confirmation point 1:** you pick the repository from the scored shortlist, with license implications stated;
4. Clones it, strips git history, records provenance in `${CODE_NAME}/UPSTREAM.md`, keeps the upstream LICENSE, and conservatively rebrands the package to `CODE_NAME` — registry strings and checkpoint-coupled names stay untouched, listed as names left unchanged on purpose.

When code already exists (organize): surveys it read-only, concern by concern, into a repo map.

Both paths then design a target architecture with a numbered migration table — the current layout is the baseline, so migrations stay minimal. **Confirmation point 2:** you approve migration items individually. Approved ones run as disjoint groups, verified and committed per group; a failed group has its paths restored and is marked blocked.

### Main outputs

```text
${CODE_NAME}/                        # working, renamed, provenance-tracked codebase
${CODE_NAME}/UPSTREAM.md             # source URL, commit, license
metds/codearc.md                     # authoritative architecture spec
AGENTS.md                            # ≤10-line Code Architecture summary + pointer
.cursor/rules/code-codearc.mdc       # always-on pointer for Cursor
```

The architecture spec records directory responsibilities, placement rules, naming conventions, the plan-component map, the migration record, and the names a rename left unchanged on purpose. Agents read it before writing code, so implementation follows one recorded structure instead of each session improvising its own.

### The STOP line

Environment builds involving CUDA compilation, downloads over ~1 GB, full test suites, and anything that trains are prepared as exact commands and handed to you — never launched autonomously. The full build belongs to `star-env-builder`.

### Practical guidance

- Run it once between decomposition and the first execution; re-run it to record new placement rules or execute the next round of approved migrations.
- Read the license column at Confirmation point 1 carefully — it also constrains how you can release your own code later.
- Keep migrations small. The upstream layout survived real training runs; wholesale restructuring of unfamiliar research code rarely does.

See the complete definition in [`star-code-architect/SKILL.md`](../../../.agents/skills/star-code-architect/SKILL.md).

## 8. `star-env-builder`: build the runtime environment

### When to use it

- `${CODE_NAME}/` has code, but there is no usable conda env or venv yet.
- The environment broke or dependencies changed, and you want a rebuild with the old one kept as a dated backup.
- Requirements files are missing and should be resolved from packaging metadata or from the code itself.
- You want an evidence-backed check that the installed environment really runs the project.

### How to invoke it

```text
star-env-builder
star-env-builder my-env
star-env-builder add wandb einops    # install into the existing env and record it
```

With no argument, the environment name is `CODE_NAME` from `.env`. A valid `CONDA_HOME` there selects the conda backend; otherwise the skill creates `.venv` in the project root (the name argument then does not apply).

### What it does

1. Detects `.env`, the GPU/driver (the CUDA ceiling), conda, and uv;
2. If the target environment exists, asks whether to **back it up** (rename to `<name>_<YYYYMMDD>` with the real run date — never deleted), **verify & repair in place**, or **abort**;
3. Resolves dependencies first-signal-wins: existing `${CODE_NAME}/requirements*` → `pyproject.toml` / `setup.py` / `environment.yml` → an import scan of the code. Results land in a two-tier layout: `requirements.txt` referencing `requirements/framework|runtime|optional.txt`, conda-only items in `requirements/conda.txt`;
4. **Confirmation point:** you approve the install plan — backend, python version, per-category packages, the torch↔CUDA wheel match, download sizes, every flagged uncertainty;
5. Installs in the uv > pip > conda order (conda only for system-isolation items such as `cudatoolkit` or `ffmpeg`), respecting any configured mirrors;
6. Runs the three-layer runnable check — imports, framework/GPU check, project entrypoint — with the main agent recording evidence for each.

### Main outputs

```text
$CONDA_HOME/envs/<ENV_NAME>/  (or .venv/)    # the working environment
${CODE_NAME}/requirements*                   # only when the layout was missing (committed)
wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md    # identity, install results, runnable-check matrix
wkdrs/env_<ENV_NAME>_<date>/freeze.txt       # exact version list
```

The report records the absolute interpreter path (`ENV_PY`) every later command should use — the skills never rely on `source activate`.

### The STOP line

Installs approved at the confirmation point run autonomously, including large framework wheels. The skill never runs `sudo` or system package managers, never compiles CUDA extensions from source (flash-attn-style builds are prepared as exact commands for you), never downloads more than ~10 GB, never deletes an environment.

### Practical guidance

- Run it once after `star-code-architect` puts the codebase in place, before the first `star-plan-executor` run.
- Re-running it is safe: choose *verify & repair in place* to fix a broken environment without rebuilding, or *backup & rebuild* to start clean.
- On a CUDA mismatch the skill stops and presents concrete options instead of guessing — have your target torch/CUDA combination in mind.

See the complete definition in [`star-env-builder/SKILL.md`](../../../.agents/skills/star-env-builder/SKILL.md).

## 9. `star-plan-decomposer`: create execution sub-plans

### When to use it

- The root plan already explains why and what to do, and you now need the how.
- You want to turn the method, milestones, or experiment design into executable tasks.
- An existing sub-plan is still too large and needs another level of decomposition.

### How to invoke it

```text
star-plan-decomposer open-vocab-det-seg
star-plan-decomposer 0
star-plan-decomposer 0_open-vocab-det-seg_plan.md
```

With no argument, or an ambiguous match, the skill lists candidate plans for selection.

### What it does

The skill first checks whether the parent plan is ready, then confirms two decisions in order:

1. **Decomposition axis:** phase/milestone, component/module, or experiment/evidence;
2. **Sub-plan list:** one card per unit expanding now — objective, steps, deliverables, done-criterion — and one line per unit kept in outline, plus dependencies and execution order, all shown in the reply before the question is put.

After confirmation, the skill by default expands only the next runnable unit(s) into sub-plan files; later units stay outline lines in the parent plan and are expanded, by re-invoking the skill on the parent, as execution reaches them — the outline checked against the newest results first. Each expanded sub-plan contains:

- Objective and non-goals;
- Inputs and upstream dependencies;
- An actionable, ordered task breakdown;
- Deliverables with explicit paths;
- A verifiable done-criterion;
- Local risks and fallbacks.

### Files and dependency structure

Sub-plans and their parent stay flat under `metds/plans/`; numeric prefixes encode depth:

```text
metds/plans/
├── 0_open-vocab-det-seg_plan.md
├── 00_baseline-impl_plan.md
├── 01_mvp-verify_plan.md
├── 02_core-method_plan.md
│   ├── 020_desc-generation_plan.md
│   └── 021_set-matching_plan.md
└── 03_final-rets_plan.md
```

The indentation above represents the logical tree; all files still live in one directory. Each deeper level appends one digit to the prefix. A node may have at most ten direct children; larger task sets decompose across two levels.

A sub-plan's frontmatter `parent` field is the authoritative parent link; `depends_on` defines execution order. The skill also maintains `children` and a `## Sub-plans` index in the parent plan. An outline unit lives only in that index — no file, no prefix — so `children` and `depends_on` list expanded units alone.

To decompose a sub-plan still too big to run:

```text
star-plan-decomposer 01
```

### Practical guidance

- If the parent method and milestones remain vague, return to `star-plan-coach` first.
- Every sub-plan needs one check that clearly distinguishes success from failure. “Investigate” or “try to optimize” is not concrete enough.
- Do not manually renumber existing prefixes; that can break deeper plans and dependency references.
- A dataset the root §4 names but `datas/` does not hold gets its own **data-readiness leaf** — acquisition in §3, an integrity check (manifest, file count, checksum) as the §5 done-criterion, every consumer depending on it. The acquisition command crosses the STOP line, so it comes back to you to run. Without that leaf, execution stops at a missing input no plan owns.

See the complete definition in [`star-plan-decomposer/SKILL.md`](../../../.agents/skills/star-plan-decomposer/SKILL.md).

## 10. `star-plan-executor`: execute one leaf plan

### When to use it

- A sub-plan has a concrete task breakdown and done-criterion, ready for implementation.
- You want to resume an interrupted execution.
- You want a plan turned into code, light validation, and an auditable execution record.

### How to invoke it

```text
star-plan-executor 01
star-plan-executor mvp-verify
star-plan-executor 01_mvp-verify_plan.md
```

Only a **leaf plan** is executable. If the target still has `children`, the skill asks you to pick one of its leaves or recommends further decomposition.

### Readiness checks

The skill first verifies that:

- Section 3 contains concrete tasks;
- Section 5 defines a runnable done-criterion;
- The leaf is still one unit of work — one done-criterion, one kind of work, at most one crossing of the STOP line;
- Every upstream plan in `depends_on` is complete;
- Required data, weights, and code modules exist;
- The project paths and Conda environment in `.env` are usable (a missing environment is built by `star-env-builder`).

If a hard dependency is missing, the skill reports the exact blocker rather than fabricating an input or skipping the dependency.

A leaf can pass every other check and still be too big for one run — split weeks ago, or written by hand. The skill then previews how it would divide (2–5 units, each with a one-line objective and the done-criterion it would own) and recommends `star-plan-decomposer <leaf>` first, carrying the sketch as the description. The preview writes nothing: the decomposer still picks its own axis and confirms its own list. Executing as it stands stays an option, its cost stated — every STOP-line crossing stops and resumes the whole run, one blocked step holds up everything behind it, a failure re-runs the whole leaf. A resumed run is never asked, because splitting mid-run would leave its records on a node no executor revisits.

### What it does

1. Reads the real code and builds a current-state-versus-plan gap list;
2. Refines the sub-plan into an `EXEC_PLAN` whose steps bind files, commands, artifacts, and checks;
3. Recommends an execution branch (`<run>`, [conventions §11](research-workflow-conventions.md)) when the plan modifies existing code, approved with the plan itself — the base branch keeps working code until the reviewed changes merge back at an explicit confirmation point;
4. Makes only the changes the current step requires;
5. Runs the narrowest light validation and records evidence in the log;
6. Sets the execution status to `done` once the sub-plan's done-criterion is satisfied.

Ordinary in-scope implementation and light validation proceed under the active tool's permission model. The skill stops for direction when a choice would materially change the scope.

### The STOP line

The skill never starts these on its own:

- Long-running or multi-GPU training and fine-tuning;
- Full-dataset evaluation;
- Large batches of usage-priced API calls;
- Operations that may overwrite valuable artifacts;
- Work whose duration or cost cannot be bounded.

Instead it prepares the exact command, records it under “Awaiting user” in the execution log, and stops — then starts `star-code-reviewer <leaf>` itself, named above that command: a defect caught before the compute costs a review, caught after it costs the compute and the re-run too. The command stays yours to run; the review is not, and only an exploratory leaf whose command is cheap may skip it — which you are asked before it starts. Blocker or major findings go back through `star-plan-executor`, which reopens the affected steps, fixes and verifies them, then hands the command back. After you run it, invoke the same plan again; the skill resumes from the log and verifies the result instead of starting over.

### Main outputs

The default run name is `<prefix>_<slug>`:

```text
wkdrs/01_mvp-verify/
├── EXEC_PLAN.md
├── EXEC_LOG.md
└── ...                     # Other artifacts generated by this run
```

- `EXEC_PLAN.md` records actions, files, commands, artifacts, checks, the STOP line, and any divergences from the sub-plan;
- `EXEC_LOG.md` records step status, verification evidence, blockers, commands awaiting the user, each heavy run's expected and actual cost, and pending amendments;
- The plan file receives the lightweight `exec_status`, `exec_runs`, and `updated` fields — plus, after your confirmation, material deviations written back into its §2–§5 (see below).

Invoked again on the same plan, the skill treats `EXEC_LOG.md` as the source of truth, skips completed steps, and resumes from the first unfinished action.

When the run executed on an execution branch, all of that — code, run records, the plan's own status — lives on `<run>` until the leaf is done and reviewed; invoking the plan again then reaches the merge confirmation point: a squash merge onto the base branch by default, conflicts named and handed to you, the branch's deletion asked separately. Discarding instead copies `wkdrs/<run>/*.md` back to the base branch first, so a negative result keeps its evidence; `star-flow-status` lists unmerged execution branches, so none of this waits invisibly.

### Writing the changes back into the plan

Execution rarely matches the written plan exactly. When the difference is material at the plan's own granularity — a step added, dropped or replaced; a dependency that turned out wrong; a changed deliverable path; an adjusted done-criterion — the skill records it as an ADDED / MODIFIED / REMOVED delta and confirms it with you: deviations found while planning with the executable plan itself, those emerging during execution batch-confirmed once at finalization. Confirmed deltas go back into the sub-plan — the affected §2–§5 passages updated in place, a `## Revision History` entry recording the date, run, change and reason — so the plan you reread later matches what ran. A fourth type, ENRICHED, covers a value the plan left open that execution settled — a learning rate, the backbone, the reproduction command — but only where a method document would cite it: the plans are what `star-metd-summarize` compiles from, so a value left in the run log alone becomes a permanent TODO in `metds/training.md`. Objective- or plan-level divergence is never written back this way; it routes to `star-plan-reviser` / `star-plan-coach` / `star-plan-decomposer`.

See the complete definition in [`star-plan-executor/SKILL.md`](../../../.agents/skills/star-plan-executor/SKILL.md).

## 11. `star-code-reviewer`: review code against conventions and the plan

### When to use it

- A leaf finished and you want the new code audited before building on it.
- The codebase has grown and you want a convention audit (docstrings, naming, simplicity, hardcoded paths) written to a file.
- You want to check whether a plan's §3 tasks are really implemented in code, beyond what the execution log claims.
- You just changed some files and want a quick review of the diff alone.

### How to invoke it

```text
star-code-reviewer                        # everything under ${CODE_NAME}/
star-code-reviewer 00                     # the code that plan touches + plan conformance
star-code-reviewer ${CODE_NAME}/models    # one path
star-code-reviewer diff                   # uncommitted changes only
star-code-reviewer HEAD~3..               # a git range
```

A plan argument accepts the usual slug / numeric prefix / filename forms; a `wkdrs/<run>/` path back-resolves to its plan.

### What it does

1. Resolves the scope and loads the review rules: the project guidelines, `metds/codearc.md` when present, and — in plan mode — the plan's §2–§5 plus its execution log;
2. Gathers cheap static evidence through the `.env` environment (`compileall` always; ruff/flake8 only if already installed — it installs no tools);
3. Collects findings against a six-dimension rubric: docstrings & comments, naming, simplicity, STAR project conventions (hardcoded paths, layout, placement rules), high-confidence suspicious correctness patterns, and in plan mode plan conformance;
4. Re-verifies every blocker/major finding against the code before reporting; unconfirmed suspicions are listed separately, never counted;
5. Writes the report under `wkdrs/` and gives a short digest with routing: feature gaps → `star-plan-executor`, plan-text divergence → `star-plan-reviser`, restructuring → `star-code-architect`;
6. Runs a fix pass of mechanical, behavior-preserving fixes only (docstrings, scope-internal renames, unused imports, project-introduced dead code): `minor` and `nit` ones are applied unasked and named as they go in, `blocker` and `major` ones go on the page as one list settled in a single question, every fix that deletes code is asked on its own, each fix re-verified after application.

### Main outputs

```text
wkdrs/<run>/CODE_REVIEW_<date>.md         # plan mode with a run
wkdrs/reviews/code_<scope>_<date>.md      # other modes
```

The report records the scope and evidence base, a verdict, findings by severity (blocker / major / minor / nit) each with file:line, the violated rule and a concrete fix, the plan-conformance scorecard, the fix record.

### The fix boundary

The fix pass never changes behavior: no feature completion, no signature changes visible outside the scope, no file moves, no edits to the names a rename left unchanged on purpose. Plan files are never edited — what the review learns about the plan routes to `star-plan-reviser`. Nothing beyond `minor` and `nit` is applied unasked; `involve=high` puts even those to you one at a time.

### Practical guidance

- Run it after a leaf completes, before `star-plan-reviser` — the code audit gives the plan review harder evidence.
- `diff` mode is the cheapest habit: review what you just wrote while it is uncommitted. A run that executed on an execution branch is reviewed as its branch diff against the base (conventions §11) — the merge confirmation point waits on the verdict.
- A finding you disagree with is simply skipped in the fix pass; the report keeps the record either way, and a minor fix applied unasked is recorded there too — `git diff` shows it before anything is committed.

See the complete definition in [`star-code-reviewer/SKILL.md`](../../../.agents/skills/star-code-reviewer/SKILL.md).

## 12. `star-expt-analyst`: analyze a run's results

### When to use it

- You ran the training or evaluation command the executor handed back, and want to know what the results mean.
- You want to know whether a run really met its done-criteria, beyond what its log claims.
- A run finished but you are not sure it can be trusted — the numbers look wrong, or too good.
- You want the training logs read for you: crashes, NaN, OOM, divergence, overfitting.
- You re-ran a plan as a variant and want the runs side by side.

### How to invoke it

```text
star-expt-analyst 01                             # the plan's current run, via its exec_runs
star-expt-analyst mvp-verify
star-expt-analyst wkdrs/01_mvp-verify/           # a run directory
star-expt-analyst                                # list the runs on disk and pick one
star-expt-analyst watch 01                       # health read of a possibly still-running run
```

A plan argument accepts the usual slug / numeric prefix / filename forms; a `wkdrs/<run>/` path back-resolves to its plan. `watch` (same argument forms) is a chat-only health read for a run that may still be executing — log health and liveness, no verdict, no files — for while a long training job the STOP line handed back is still going.

### What it does

1. Resolves the run and loads the expectations: the sub-plan's §4 deliverables and §5 done-criteria, the root's §4 metrics and §5 kill-criteria, the run's `EXEC_PLAN.md` / `EXEC_LOG.md`;
2. Inventories the §4 deliverables against disk with light integrity checks, and corroborates every step the log claims `done` against the artifact it names — including which STOP-line commands you ran;
3. Scans the logs for health signals: crashes and OOM, NaN/Inf, diverging or flat loss, train-val divergence — big logs are grepped and read head-and-tail, never loaded whole;
4. Extracts the metrics the criteria name from the most authoritative source available and scores each criterion `met` / `not met` / `unmeasurable` — naming the source and split behind every number;
5. Interprets the result against the claim the plan `traces_to`: root kill-criteria, leakage checks before a suspiciously strong number is accepted, the run's limits (seeds, split size, what it does not show);
6. Renders loss and metric curves when matplotlib is already installed, and compares sibling runs of the same plan where they exist;
7. Writes the report under `wkdrs/<run>/` and gives a short digest with routing.

### Main outputs

```text
wkdrs/<run>/EXPT_ANALYSIS_<date>.md   # the analysis report
wkdrs/<run>/analysis/*.png            # curves, when matplotlib is available (with the script that made them)
wkdrs/results/results.md              # aggregate mode only: the cross-run results table
                                      # (wkdrs/results/results_<slug>.md when scoped to a subtree)
```

### The results table (`aggregate`)

`star-expt-analyst aggregate [PLAN_NAME]` answers what a single run cannot: *what does the whole experiment programme show?* It collects every leaf's newest analysis report, **re-opens each number at the source that report cites** before letting it in, and compiles `wkdrs/results/results.md` — `wkdrs/results/results_<slug>.md` when scoped to a subtree, so a scoped run never overwrites the project results table. One table per claim and per ablation, taken from the root's §4 claim→experiment map, not from the plan tree; every number carries its run, source, and verdict. Runs verdicted `invalid` or `inconclusive`, and numbers that fail re-verification, move to an excluded section naming them and why; a `not met` run stays in its table. The table reports numbers, never explains them: *why* a variant won needs a controlled comparison this skill does not run. With `metds/evaluation.md`, which defines the protocol and carries no scores, it is the pair a paper's results section is written from.

The report records the scope and evidence base, a run verdict, the done-criteria scorecard, the artifact inventory and completion, log health, metrics with their sources, any cross-run comparison, the interpretation, and the routing.

### The read boundary

This skill is **read-only apart from its own report**. It never edits plan files, never sets `exec_status`, never touches `EXEC_PLAN.md` / `EXEC_LOG.md` — when a done-criterion is met, it recommends `star-plan-executor`, which owns finalization. It never re-runs an experiment to fill a missing metric: that metric is reported `unmeasurable` and the command comes back to you. The executor's STOP line applies here too.

### Practical guidance

- The natural moment is right after you run a STOP-line command: the analyst says what came back, then hands the plan to `star-plan-executor` to finalize it.
- The run verdict is deliberately blunt. `inconclusive` means the evidence is not there — usually a STOP-line command never run. `invalid` means the numbers exist but cannot be trusted, and a re-run is cheaper than an interpretation.
- A negative result that hits a root kill-criterion is the most valuable thing this skill can find: route it to `star-plan-reviser` while the evidence is fresh.

See the complete definition in [`star-expt-analyst/SKILL.md`](../../../.agents/skills/star-expt-analyst/SKILL.md).

## 13. `star-expt-digest`: summarize progress over a period

### When to use it

- It is Friday, or a round of experiments just closed, and you want one page on what they did this week.
- You are back after two weeks and need to know what happened while you were away.
- You are writing a progress report or preparing for a supervisor meeting.
- You want everything a plan family has produced — the parent's question and every descendant's answers — in one place.
- You want to know what *changed* since you last looked, not just where things stand now.

### How to invoke it

```text
star-expt-digest                          # since the previous digest — the default
star-expt-digest 7d                       # the last seven days
star-expt-digest 2026-07-01               # since that date
star-expt-digest 01                       # a plan family: the node, its ancestors, all its leaves
star-expt-digest core-method
star-expt-digest all                      # the whole history; re-seeds the series
```

With no argument the skill reads the newest digest's `covers.through` as the last covered date and covers everything after it, so a regular cadence produces a series with no gaps and no double-counting. A plan argument takes the usual slug / numeric prefix / filename forms.

### What it does

1. Resolves the period and states it before reading anything, so a wrong window is caught early — and reports an empty period as empty rather than widening it;
2. Collects the in-scope runs and dates each by its analysis report, else by its `EXEC_LOG`'s last dated entry — never by file mtime, which moves for a checkout or a backup;
3. Reads each **report-backed** run's newest `EXPT_ANALYSIS_<date>.md` for its verdict, scorecard, and headline metrics, carrying over the source and split the report recorded;
4. Reads each **provisional** run's `EXEC_LOG.md` only — status, steps, plan-level findings, and a number only if the log names one with its file;
5. Derives what moved by diffing against the previous digest's `sources:`: new runs, changed verdicts, runs provisional last time and analyzed now;
6. Notes which plans were created, revised, decomposed, or finalized in the window, and lists the gaps — unanalyzed runs, unexecuted leaves, awaiting STOP-line commands, a stale results table;
7. Writes the dated digest and gives a short chat summary with routing.

### Main output

```text
wkdrs/digests/EXPT_DIGEST_<date>.md   # the period's digest
```

### Two tiers, and why they never mix

A run with an analysis report is **report-backed**: its numbers are quoted from that report with their provenance. One without is **provisional**: its log is read raw for a rough line, tagged `provisional (unverified)`, kept in its own table. The wall between them is strict — a provisional number is never scored against a done-criterion, never used to compute a movement, never quoted as a result, never allowed into `wkdrs/results/results.md`. That wall is what lets the tier exist: a week's work becomes visible without an unverified number contradicting the results table.

### How it differs from the neighbouring skills

Three skills read across runs, and they answer different questions:

| Question | Skill | Axis |
|---|---|---|
| Did *this run* meet its plan? | `star-expt-analyst <plan>` | one run, verified |
| What are the final numbers, by claim? | `star-expt-analyst aggregate` | claim, re-verified at source |
| Where does everything stand now? | `star-flow-status` | current state, no memory |
| What happened lately, and what did we learn? | `star-expt-digest` | time, report-level |

The digest is **report-level, not re-verified**: unlike `aggregate`, it copies a number with its provenance rather than re-opening the source to confirm it. That cost difference is why a digest can run weekly and an aggregate cannot. It also means a digest is never the file you quote a number into a paper from — `wkdrs/results/results.md` is, and every digest says so on its face.

### What it may write

This skill is **read-only apart from its own digest**. It never edits plans, `exec_status`, `EXEC_LOG.md`, an analysis report, or the results table, and never runs anything to fill a gap — every gap is a listed line with the command that closes it. It never says *why* a variant won either: like the results table, it reports the direction of a change and routes the interpretation.

### Practical guidance

- Run it regularly — weekly is natural. Each digest's "what moved" section is only as good as the previous digest it diffs against.
- A digest full of provisional rows is a signal, not a failure: runs are finishing faster than they are analyzed. Clear it with `star-expt-analyst` on the named runs.
- Use plan mode before a milestone review, when you want a family's whole story rather than a date range.
- Under `wkdrs/` everything is git-ignored **except `*.md`**, so the digest series can enter the repository history — but no skill commits it for you: this one is read-only. Digests regenerate from the analysis reports, so losing an uncommitted one is recoverable.

See the complete definition in [`star-expt-digest/SKILL.md`](../../../.agents/skills/star-expt-digest/SKILL.md).

## 14. `star-plan-reviser`: review and revise one plan

### When to use it

- A leaf finished (or stalled) and you want what it did versus what it promised before moving on.
- Execution recorded a plan-level finding or hit a kill-criterion, and the plan should absorb the result.
- A plan drifted from reality — extra work happened, assumptions changed — and its text should catch up.
- You want an evidence-backed completion assessment written down, not chat impressions.
- A direction is being given up, and the plan tree should stop counting and recommending it.

### How to invoke it

```text
star-plan-reviser 01
star-plan-reviser mvp-verify
star-plan-reviser 0_open-vocab-det-seg_plan.md
star-plan-reviser 01 this one is finished, 02 replaces it   # gives it up, no review pass
star-plan-reviser 01 bring this direction back              # clears the drop
```

Any node works: a leaf is audited against its own run; a root or internal node against its children's summary and the plan-level findings recorded in descendants' logs.

### What it does

1. Reads the plan and scopes the evidence: `wkdrs/<run>/EXEC_PLAN.md` and `EXEC_LOG.md`, every §4 deliverable on disk, the named code modules — for internal nodes, children frontmatter and executed descendants' logs;
2. Collects that evidence read-only and scores completion claim by claim (`met` / `partial` / `unmet` / `unverifiable`) — a log's self-reported `done` is never trusted without the artifact behind it;
3. Writes a seven-part review report (intent recap, what happened, completion scorecard, divergences, blockers and leftovers, knock-on effects, revision candidates) under `wkdrs/`;
4. Puts every revision candidate on the page and settles the list in one question — adopt all as listed, all but the ones you name, the ones you name answered first, or none;
5. Applies approved edits to the plan file in place, appends a `## Revision History` entry, updates `updated`, and offers to reset a leaf's `exec_status` when its done-criterion changed;
6. Ends with the follow-up action: re-decompose, re-execute, or a coaching session.

Adopting nothing is a valid outcome: the review report it wrote is a deliverable on its own.

### The revision boundary

One session revises one target file (plus the parent's index line when the target's objective changed). Structural changes — adding or removing sub-plans, redrawing the dependency graph — route to `star-plan-decomposer`; research-question or method pivots to `star-plan-coach`. Prefixes are never renumbered, versioned copies never created, `EXEC_PLAN.md` / `EXEC_LOG.md` never modified.

### Dropping a plan

A direction you gave up on is marked, never deleted. Saying so in the invocation — `star-plan-reviser 01 this direction is finished` — is the short path: it skips the audit, because a drop records a decision you have already made, and asks once, showing what goes dark before it writes. There is no keyword to remember; your own words become the reason on the record. The reviser writes `dropped: <date> — <one-line reason>` on that node, marks the parent's index line `— dropped <date>`, records what ended the direction in the `## Revision History`, and moves the subtree's files aside, names unchanged — plan files to `metds/plans/dropped/`, run dirs to `wkdrs/dropped/`, `tasks/<plan-name>/` to `tasks/dropped/`, launch scripts to `execs/scpts/dropped/` — so the live tree stays readable. Every skill reads the field as inherited by the whole subtree, so one line takes that node and everything under it out of the counts, the follow-up checks and the next action: `star-flow-status` renders them `⊗` and leaves them out of its three numbers, `star-plan-executor` refuses to run them, `star-plan-decomposer` refuses to split them, `star-metd-summarize` compiles nothing from them. Nothing is deleted and no pointer rewritten — a failed direction is evidence: every skill resolves the moved files from their `dropped/` locations, the results tables keep their rows, and the parent keeps the link, so what was tried is still readable from it. Undropping is clearing the field and moving everything back. Two things a drop does not settle: a leaf still depending on the dropped node (its dependency can never be met, so the status report flags it for you to redraw), and an unmerged execution branch or live worktree underneath it, still on disk and still flagged.

### Main outputs

```text
wkdrs/<run>/REVIEW_<date>.md          # review report (wkdrs/reviews/ when the plan has no run)
metds/plans/<prefix>_<slug>_plan.md   # revised in place, with a Revision History entry
```

### Practical guidance

- Run it after a leaf completes or blocks, before starting the next — revision is cheapest while the evidence is fresh.
- Revising a parent bumps its `updated`, so `star-flow-status` flags its children as stale; that is the intended signal to re-decompose them.
- For a quick progress overview use `star-flow-status`; the reviser is for depth on one plan, with write access.

See the complete definition in [`star-plan-reviser/SKILL.md`](../../../.agents/skills/star-plan-reviser/SKILL.md).

## 15. `star-flow-status`: inspect the whole flow

### When to use it

- You want to know how far the overall research has got.
- You are unsure which sub-plan to decompose or execute next.
- You want the follow-up still outstanding on finished work — a run never reviewed, results never analyzed, method documents older than the plans they were compiled from.
- You want to inspect dependencies, blockers, commands awaiting the user, or stale plans.
- You need a quick context refresh at the start of a new session.

### How to invoke it

Inspect the whole flow:

```text
star-flow-status
```

Inspect one plan subtree — the tree, the three counts, the follow-up checks and the next action all narrow to it:

```text
star-flow-status open-vocab-det-seg
star-flow-status 01
```

### What it reports

- A plan tree annotated with status — every node in scope on its own line, whatever the tree's size;
- Top-level plan section completeness, decomposition coverage, leaf execution progress;
- Each leaf's dependencies, logged step progress, blockers, or commands awaiting the user;
- Follow-up checks: finished work whose follow-up is missing or out of date — a done leaf with no code review or experiment analysis, a reviewed run whose log has since moved on, a results table or method document older than its sources, a digest series fallen behind the analysis reports, a finalized idea that never became a plan. Only triggered checks are printed; work still in progress owes no follow-up and stays silent;
- Exactly one recommended next action, by a fixed priority order — an awaiting-user command first, then outstanding follow-up on finished work, then the next runnable leaf, then a finalized idea with no plan — with its reason;
- Drift such as a child older than its parent, dangling links, invalid dependencies, or orphaned runs;
- An unrecognized-files line counting report-shaped files that match no known artifact pattern, so a producer skill's renamed output is noticed rather than silently dropping out of the follow-up checks.

This skill is **strictly read-only**. It scans the artifacts listed in §8 of the conventions — `metds/ideas/`, `metds/plans/`, `metds/refs/`, the compiled `metds/*.md`, the logs and reports under `wkdrs/` (run dirs, plus `wkdrs/reviews/`, `wkdrs/env_<name>_<date>/`, `wkdrs/digests/`, `wkdrs/results/`) — creating or modifying nothing. Being the most-run skill in the flow, its whole input — the conventions excerpts, its spec, the digest from one read-only scan script (`scripts/scan.sh` in its own directory) — arrives in a single opening message instead of one read per file; the script only gathers, so every rule it feeds stays in the skill.

See the complete definition in [`star-flow-status/SKILL.md`](../../../.agents/skills/star-flow-status/SKILL.md).

## 16. `star-metd-summarize`: compile the plans into method documents

### When to use it

- Every experiment is finished and the plans are finalized — the method is determined — and you want it as prose a reader can follow.
- You are starting a paper's method section and want the material assembled from what the plans already say.
- You want to see, in one place, where the method is still unwritten — every gap named with the plan section that should fill it.
- A collaborator needs the method without reading the whole plan tree.

### How to invoke it

Compile one document:

```text
star-metd-summarize framework
```

Compile all five:

```text
star-metd-summarize
```

`OPT` is one of `overview`, `dataset`, `framework`, `training`, `evaluation`. With no argument the skill compiles all five in dependency order (`dataset` → `framework` → `training` → `evaluation` → `overview`, which links the other four and goes last).

### What it does

1. Checks readiness: unless every top-level plan carries `finalized:` and every leaf is `exec_status: done`, it stops before compiling anything, names what is open, and routes it — a draft compile is an explicit choice it asks for, never a default;
2. Rebuilds the plan tree from each plan's `parent:`, exactly as the status skill does;
3. Extracts what each document needs through a written map — the root's §1–§3 and §6 for the overview, §4 data choices plus every leaf's `datas/` inputs for the dataset, the §3 technical route plus modeling leaves and their `${CODE_NAME}/` paths for the framework, §3 strategy plus `inits/` and hyperparameters for training, §4 benchmarks, baselines, metrics and ablation design plus §5 kill-criteria for evaluation;
4. Merges the passages along the method's axis rather than the plan's, resolving conflicts leaf-over-parent and newer-over-older, printing ⚠ with both sources when neither dominates;
5. Marks anything sourced from an unexecuted leaf — possible only in a draft compile — as not yet verified;
6. Turns every template section no plan covers into a `TODO` naming the plan and section that should carry it.

### Main outputs

| Document | Contents |
| --- | --- |
| `metds/overview.md` | Problem, gap, core idea, the component table, contributions as falsifiable claims, milestones |
| `metds/dataset.md` | Dataset inventory, per-dataset detail, preprocessing, constructed data, statistics, dataset→experiment map |
| `metds/framework.md` | Architecture as one data path, per-component detail with code locations, design decisions, difference from prior work, module map |
| `metds/training.md` | Stage pipeline, per-stage recipe, hyperparameter table, practical notes, reproduction commands |
| `metds/evaluation.md` | Protocol overview, benchmark detail with meaningful margins, baselines, ablation design, evaluation commands |

Each document records in its frontmatter the plans it was compiled from and the `updated` date each carried — how the next run detects a stale document.

### The fabrication boundary

Plans are the only source. The skill reads no code, logs, `wkdrs/`, or chat history, and never fills an unstated value with a plausible default — an unstated learning rate stays `TBD` and becomes a gap, because a plausible default here is a wrong number in a paper. Result numbers never enter these documents either: `evaluation.md` defines the protocol, while what a run scored stays in `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`. Execution detail missing from a document is fixed by `star-plan-executor` writing it back into the plan, not by a wider read.

### Practical guidance

- Compile once the loop has closed — every leaf executed, the plans finalized. A premature run stops at the readiness check and hands back what is open: while the method is moving, the route is `star-plan-executor` and `star-plan-coach`, not a draft document. Run it as soon as the confirmation point opens, though — the gap list is most useful *before* the writing deadline, while there is still time to answer it.
- Treat these documents as generated. To change one, change the plan it came from and recompile — hand edits are overwritten on the next run, though a file the skill did not generate is never overwritten without asking first.
- A regeneration whose sections are all unchanged writes nothing, so re-running costs only the reading.

See the complete definition in [`star-metd-summarize/SKILL.md`](../../../.agents/skills/star-metd-summarize/SKILL.md).

## 17. `star-code-release`: prepare the repository for release

### When to use it

- The work is done and the repository has to be readable by someone who is not you — a reviewer, a collaborator, the public.
- Useful code is scattered across `tasks/` and `wkdrs/` and should reach the codebase before anyone clones it.
- The root `README.md` still describes the STAR template rather than your project.
- You are about to open-source and want to know what would leak: a committed `.env`, a token, a `/home/<you>/` path baked into a config.

### How to invoke it

```text
star-code-release              # the full pass: gather → polish → readme → check
star-code-release gather       # only consolidate the scattered code
star-code-release polish       # only the pass over the files a reader will open
star-code-release readme       # only compile README.md
star-code-release check        # only the hygiene sweep — read-only apart from its report
```

### What it does

1. Prints a **readiness table** first: which of the compile's inputs exist and which are stale, each with the skill that produces it. Compiling with gaps is allowed — they become README TODOs — but you see the table first;
2. Sweeps `tasks/`, `wkdrs/` scripts and configs, and root strays, promoting only what passes a three-part evidence test — the README will cite it, an executed leaf's §4 deliverable or §5 done-criterion needs it, or it reproduces a number in `wkdrs/results/results.md`. Destinations come from `metds/codearc.md` §2; a candidate no placement rule covers is reported as an architecture gap, never given an invented directory. **Confirmation point 1:** you approve the promotion table row by row, each row's risk and any plan line it would make stale shown;
3. Polishes only the files a reader will open — the promoted files, the entrypoints, configs and scripts the README prints, the public API it shows. Each edit is individually approved and behavior-preserving;
4. Compiles `README.md` section by section through a written map: header and abstract from `metds/overview.md`, method from `metds/framework.md`, installation from `requirements*` and the newest `ENV_REPORT.md`, data preparation from `metds/dataset.md`, training and evaluation from `metds/training.md` and `metds/evaluation.md`, results and model zoo from `wkdrs/results/results.md`, repository structure from `metds/codearc.md`, citation from `reference.bib`, acknowledgement from `UPSTREAM.md`;
5. Ends with a hygiene sweep whose findings block: secrets and machine-local paths, license and attribution, whether every command it printed resolves, whether every link and image it wrote points at a file that exists, and whether every number it printed traces to a row of `wkdrs/results/results.md`.

### Main outputs

```text
README.md                              # the compiled project README (README.zh-CN.md when offered)
wkdrs/release/RELEASE_<date>.md        # readiness, promotions, polish record, section map, checklist
```

The README opens with an HTML-comment provenance marker — not frontmatter, which GitHub would render as a table — recording the date, the model, and each source with the date it carried when read. That marker is how the next run detects both a stale README and a section you edited by hand, which it keeps.

### The compile boundary

Every section traces to an artifact. **Numbers come only from `wkdrs/results/results.md`** — never from an execution log, a digest, or memory — and a number the results table excluded as invalid or inconclusive does not appear at all. **Every command is resolved before it is printed**: the script exists, the config path exists, the entry point imports; what does not resolve is dropped or marked unverified. Superlatives are claims, so "state-of-the-art" appears only where the results table's own verdict carries it. A section no artifact covers becomes a `TODO` naming the skill that fills it — the gap list doubles as the to-do list, as for `star-metd-summarize`.

The skill also never writes `metds/` at all. Its inputs belong to their producers, and a release run that edited its own sources would no longer be compiling.

### The publish boundary

It prepares a release; it never publishes one. No `git push`, no remote or branch change, no tag, no `gh repo create`, no `gh release`, no upload of weights or data anywhere. The publish commands wait in the report under *Awaiting user*, each with a note saying what it makes irreversible. Publishing is one of the few genuinely irreversible acts in the workflow, and it stays yours.

### Practical guidance

- Run `check` early and often — long before you intend to release. A `/home/<you>/` path found in month two costs a `sed`; found the day before submission it costs a scramble.
- Run the producers first when the readiness table is mostly red. A README compiled from four missing method documents is a list of TODOs: honest but not useful.
- Most of `tasks/` should come back `keep in place`. That is the promotion test working, not failing — scratch is meant to be disposable.
- Re-run `readme` whenever the results table or the method documents move. Hand edits to a section survive regeneration; the marker is what makes that possible.

See the complete definition in [`star-code-release/SKILL.md`](../../../.agents/skills/star-code-release/SKILL.md).

## 18. End-to-end example

One topic, from a sentence of interest to numbers a paper can quote, in the order it happens. Each step names what the work needs at that point, and the invocation that meets it.

A project being adopted starts at `star-proj-adopt` instead of Step 0 and continues identically from Step 1, closing the loop with `star-proj-adopt backfill` once Step 4 has produced the leaves.

### Step 0: converge on a topic (only when none is chosen yet)

```text
star-idea-storm reliable open-vocabulary perception, but I have not settled on a question
```

The storm clarifies the seed and constraints, diverges, scans, scores, and frames the winner into `metds/ideas/open-vocab-perception_idea.md` with a topic statement and a first validation experiment. Already have a topic? Skip to Step 1 — or pass the finalized idea to the coach: `star-plan-coach open-vocab-perception`. A topic settled a while ago and not read against since is worth one `star-refs-reviewer survey <topic>` before the coach: §1's gap is a claim about what the field cannot do, and §1 also feeds the later literature pass's search profile — written from memory, it bounds the very search meant to check it.

### Step 1: turn an idea into a plan — with the literature interleaved

```text
star-plan-coach I want to study more reliable text-description generation for open-vocabulary detection and segmentation
```

Work §1 Problem with the coach. Then, before writing §2, break out and read the field:

```text
star-refs-reviewer open-vocab-det-seg
```

This writes per-paper analyses and a verified `reference.bib` under `metds/refs/`. Now resume the coach — `star-plan-coach open-vocab-det-seg related_work` reopens just that section — and write the positioning from what was **read** rather than recalled, citing the citekeys the survey produced. The remaining sections follow; the finalized plan is:

```text
metds/plans/0_open-vocab-det-seg_plan.md
```

Interleaving matters: §2 positioning and the §1 gap are claims about what the field cannot do. Written before the survey, they are written from memory — and the closest paper turns up afterwards.

### Step 2: give the method a place for the code to live (first run only)

```text
star-code-architect
```

After Confirmation point 1 (pick the scored reference repository) and Confirmation point 2 (approve the migration table), `${CODE_NAME}/` holds the renamed, provenance-tracked codebase and `metds/codearc.md` records the architecture every later step follows. This runs off the **root plan**, so it needs no sub-plans yet.

### Step 3: build the runtime environment (first run only)

```text
star-env-builder
```

After the install-plan confirmation point, the environment is created, dependencies install in the uv > pip > conda order, and the three-layer runnable check writes its evidence to `wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md`. That check is the point of the step: the first leaf should fail on the research question, not on a missing wheel.

### Step 4: split it into execution units

```text
star-plan-decomposer open-vocab-det-seg
```

After confirming milestone-based decomposition, the skill may produce:

```text
00_baseline-impl_plan.md
01_mvp-verify_plan.md
02_core-method_plan.md
03_final-rets_plan.md
```

Decomposing **after** Steps 2–3 is what lets each leaf's §2 name real modules under `${CODE_NAME}/` and a runtime that exists, instead of guessed paths. Decomposing first also works — the executor routes you back — but the leaves come out vaguer.

### Step 5: identify the next task

```text
star-flow-status open-vocab-det-seg
```

The status read picks the leaf: among those whose `depends_on` upstreams are complete, it names the one whose evidence is still missing, so the order comes off the dependency graph rather than off memory. If it recommends `00_baseline-impl`, run:

```text
star-plan-executor 00_baseline-impl_plan.md
```

### Step 6: read what came back, then resume

If the log contains a training command that the user must run:

1. Run the command recorded in `wkdrs/00_baseline-impl/EXEC_LOG.md`;
2. While it runs, `star-expt-analyst watch 00` reports log health without scoring anything;
3. Confirm that its artifacts were written to the recorded paths;
4. `star-expt-analyst 00` scores the run against the leaf's done-criterion and says what the numbers mean — the step deciding whether the direction held;
5. Invoke `star-plan-executor 00` again;
6. The skill reads the existing log and resumes at done-criterion verification.

### Step 7: repeat — the light path or the full path

After each leaf, `star-flow-status` gives the single next recommendation. A result that contradicts the plan goes back into the plan text through `star-plan-reviser` before the next leaf starts, so the tree stops recommending a direction the evidence has closed. How much of the loop each leaf needs depends on what it is for; see [How much of the loop does each leaf need?](#how-much-of-the-loop-does-each-leaf-need).

### Step 8: compile the method for the paper

Once the loop has closed — every leaf executed, every top-level plan finalized, the plans having absorbed what execution taught them:

```text
star-metd-summarize
```

This compiles `metds/overview.md`, `dataset.md`, `framework.md`, `training.md`, and `evaluation.md` from the plan tree, under the readiness check and the gap-to-`TODO` rule §16 describes. The commonest reason that confirmation point stays shut is a writing or submission leaf: it cannot be executed until the method documents exist, and the documents wait on it. Keep write-up out of the plan tree, or mark that leaf `skipped` before compiling. Recompile if the plans move afterwards; a document whose sources have not changed is left untouched.

### Step 9: prepare the repository for release

Once the method documents and `wkdrs/results/results.md` are current:

```text
star-code-release
```

The scattered code lands in `${CODE_NAME}/` where `metds/codearc.md` says it belongs, the files a reader will open are polished, and `README.md` is compiled from Step 8's documents plus the results table — every number traced to a run, every printed command resolved. The hygiene sweep reports what would leak; the publish commands come back to you.

## 19. Frequently asked questions

### Which skill should I use first?

| Current situation | Use |
| --- | --- |
| Your project already exists and did not start from the STAR template | `star-proj-adopt` |
| You have only a vague interest and no committed topic yet | `star-idea-storm` |
| You have an idea (or a finalized idea file) and the plan is still unwritten | `star-plan-coach` |
| The method is clear but not the closest work, the baselines, or how to cite them | `star-refs-reviewer` |
| The plan is ready but `${CODE_NAME}/` is empty, or the codebase needs organizing | `star-code-architect` |
| The codebase exists but there is no usable runtime environment | `star-env-builder` |
| The method has a place for the code to live and you need executable tasks | `star-plan-decomposer` |
| You have a concrete leaf task and need code plus verification | `star-plan-executor` |
| The implementation is in place and you want it audited against conventions and the plan | `star-code-reviewer` |
| A run produced results and you want what they mean and whether they met the plan | `star-expt-analyst` |
| A plan was (partly) executed and its text should absorb the results | `star-plan-reviser` |
| You do not know the current status or next action | `star-flow-status` |
| Every experiment is finished, the plans finalized, and you want the method written out for a reader or a paper | `star-metd-summarize` |
| The work is done and the repository has to be readable — and publishable — by someone else | `star-code-release` |

### How much of the loop does each leaf need?

Two paths. Choose per leaf, not per project.

**The light path — `star-flow-status` → `star-plan-executor` → `star-expt-analyst`.** For an exploratory leaf: a probe, a feasibility check, an MVP whose only job is to say whether the direction is worth pursuing. The executor's step checks plus the analyst's done-criteria scorecard are enough. Skip the code review and the plan revision — the code is scaffolding you may throw away, and the plan text has not been contradicted, only tested.

**The full path — `star-flow-status` → `star-plan-executor` → `star-code-reviewer` → (STOP line: you run the command, `star-expt-analyst watch <leaf>` while it runs) → `star-expt-analyst` → `star-plan-reviser`.** For a leaf whose numbers will be quoted in the paper, whose code later leaves build on, or whose result changes the top-level plan. Here the review earns its keep: it catches the bug before it costs GPU-hours and before a wrong number reaches a table; the reviser folds what the run taught back into the plan the method documents compile from.

Two rules cut across both:

- **A result that contradicts the plan promotes a light leaf to the full path.** A root kill-criterion hit, or a refuted MVP assumption, is a plan-level finding — route it to `star-plan-reviser` whichever path you started on.
- **`star-metd-summarize` compiles from plans, not runs.** A value an exploratory leaf settled that a method document will cite still needs the executor to write it back into the plan, or it never reaches the paper.

When in doubt, ask what happens if the leaf's result is wrong. If the answer is "I lose an afternoon", take the light path. If it is "a number in the paper is wrong", take the full one.

### Why will the executor not run the plan I selected?

Usually: the target is not a leaf, an entry in `depends_on` is unfinished, the task breakdown or done-criterion still holds too many `[TBD]` items, or the `.env` environment itself is unusable — `star-env-builder` rebuilds it. `star-flow-status` first usually reveals the exact reason.

### Why was a training command recorded instead of executed?

Full training, full-dataset evaluation, and high-cost calls cross the STOP line. The skill makes the command and output paths reproducible; when to spend those resources stays the user's decision.

### I have been away for two weeks — how do I pick the work back up?

Nothing depends on the conversation still being open: each stage records its progress in a file, `star-flow-status` reads those records and says which stage you stopped in, and invoking that stage's skill again picks up from what it wrote.

- The idea storm resumes from stage statuses in the idea-file frontmatter, and a `finalized` idea reopens through its converge stage;
- The coach resumes from section statuses in the plan frontmatter;
- The refs reviewer resumes from `metds/refs/`: existing notes and verified `reference.bib` entries are the baseline, and a re-run fills only the gaps;
- The decomposer resumes from parent-child links and existing sub-plans;
- The executor resumes from the `EXEC_LOG.md` referenced by the last `exec_runs` entry;
- The env builder resumes via *verify & repair in place* from the latest `wkdrs/env_*/ENV_REPORT.md`;
- The code reviewer's reports stay under `wkdrs/` (the run directory or `wkdrs/reviews/`), and applied fixes live in git;
- The experiment analyst's reports stay under `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`, alongside any figures it rendered;
- The reviser's report stays under `wkdrs/`, and every applied change is recorded in the plan's `## Revision History`;
- The method summarizer needs no memory: it recompiles from the plans, and each document's `sources:` frontmatter records which plans it came from and how fresh they were;
- The status skill can reconstruct the global state read-only at any time.


### Which parts can run unattended?

Two different questions; this section answers only the second. **Who may start a skill** is the roster ([conventions §10](research-workflow-conventions.md)): seven are slash-only, the agent may pick up the other eight — including one a finished run names as the next action. **How far a run then gets before it needs you** follows, and is the same either way: a skill the agent started stops exactly where one you typed would. Confirmation points do not relax in headless or scripted runs — a skill that reaches a question waits rather than assuming a yes. In practice:

- **Safe on a timer**: `star-flow-status` (read-only, asks nothing); `star-expt-analyst <leaf | run-dir>` with an explicit target, and `star-expt-analyst watch <leaf>` (chat-only); a `star-metd-summarize` recompile — an unready tree stops at its readiness check, documents whose sources have not moved are left untouched, a substantive overwrite stops at its change-list question instead.
- **Runs until its confirmation point**: `star-refs-reviewer` stops at the mandatory core-set confirmation, its `verify` on any mismatch until the diff is confirmed, its `survey` at one judgment call (profile, taxonomy axis, tiered reading list) that `involve=low` takes on its recommendation — leaving only the overwrite of an existing survey file to stop for; `star-expt-analyst aggregate` stops at the change-list question once `wkdrs/results/results.md` exists; `star-code-release check` is read-only apart from its report, so it is safe on a timer, while its other three phases stop at their confirmation points.
- **Needs you at the wheel once it is running**: `star-idea-storm`, `star-plan-coach`, `star-plan-decomposer`, `star-code-architect`, `star-env-builder`, `star-plan-executor`, `star-code-reviewer`, `star-plan-reviser`, `star-code-release` (its gather, polish and readme phases) — their questions and confirmation points are the design; scripting a "yes" past them defeats the audit trail they protect. Three — the environment builder, the executor, the code reviewer — the agent may nonetheless start on its own: starting a run is not finishing one unattended.

The involve level (conventions §7.7–7.8) moves these boundaries, never past a confirmation point. With `INVOLVE=low` in `.env` — or `involve=low` on one invocation — a skill stops asking its judgment calls: it takes the option it would have marked recommended and logs the choice. Runs stretch further before needing you: `star-plan-decomposer`'s axis and sub-plan-list confirmations go quiet, and `star-plan-executor`, pointed at a parent, starts the first ready leaf itself. What never goes quiet: the STOP line, deletions and overwrites, writing changes back into plans, the confirmation points, genuinely open questions — `low` lengthens the unattended span, it does not make any skill fully unattended. The commit offer is no longer among them: at `low` a run commits what it wrote and names those commits in its reply (§1.5). `high` runs the other way: judgment calls a skill would batch into one confirmation point, or take on its own between them, are asked one at a time.

A practical unattended pattern: run the STOP-line training command, keep `star-expt-analyst watch <leaf>` on a timer while it trains, and leave scoring and revision for when you are back.

### What is deliberately outside STAR?

STAR defines the process, the file locations and the verification records; it brings no model stack, tracker, or writing tool. Three boundaries are deliberate:

- **Hyperparameter sweeps and experiment tracking.** A sweep is a plan decision (`star-plan-decomposer` scopes it, the STOP line hands the command back); which sweeper and tracker you run it through is yours. Point them at `wkdrs/<run>/` and the workflow keeps working.
- **Choosing what to care about.** `star-idea-storm` starts from a seed interest you bring — it diverges, scans and converges, but picks no field for you, and `star-plan-coach` sharpens the topic that comes out. Which problems deserve your years is upstream of STAR.
- **Paper writing.** STAR stops at the material. The handoff is `metds/overview.md`, `dataset.md`, `framework.md`, `training.md`, `evaluation.md` (the method), `metds/refs/reference.bib` (the citations), `metds/refs/related_work.md` (the related-work narrative, once synthesized), and `wkdrs/results/results.md` (the numbers, with the run behind each one). Any writing tool takes it from there.

Each could have been a skill. They are not, because the answer would have had to guess your stack, your field, or your voice — and the workflow is more useful when it does not.

### Can I edit plan files manually?

Yes, but keep the frontmatter consistent with the body, especially `parent`, `children`, `depends_on`, `status`, `exec_status`, `exec_runs`, `finalized`. `finalized` is the one three skills wait on — the decomposer will not take an unfinalized top-level plan, the architect warns, `star-metd-summarize` refuses to compile — and only `star-plan-coach` sets it. After changing a parent plan, run `star-flow-status` for drift before deciding whether to decompose it again.

## 20. Skill locations

`.agents/skills/` is the single authored source: tool-neutral, prefix-free, and also the shared root required by the `AGENTS.md` convention. Six generated harness trees adapt that source to their native invocation and control mechanisms; harness-only behavior lives in explicit adapter rules or anchored overrides. At runtime, read the generated copy owned by your tool when one exists. Do not mix tool-specific invocation or control instructions across these roots:

Every skill directory has the same shape in all seven roots: `SKILL.md` is the runtime entry point and English definition; `SKILL_zh.md` is the human-readable Chinese edition kept in step with it. At runtime the entry point stays `SKILL.md` — Chinese dialogue replies in Chinese and switches to the `*_zh.md` / `.zh-CN` resources — and where the two conflict, `SKILL.md` wins. This guide's invocation examples carry no prefix (§1), and its "complete definition" links point into the authored `.agents/skills/` source. Read the copy your own tool owns — the row below names it — where an adapter changes tool mechanics.

| Tool | Runtime directory | Invocation form |
| --- | --- | --- |
| Any `AGENTS.md` agent | `.agents/skills/` | each tool's own |
| Claude | `.claude/skills/` | `/star-*` |
| Cursor | `.cursor/skills/` | `/star-*` |
| DSH | `.dsh/skills/` | `/skill:star-*` |
| Kimi | `.kimi-code/skills/` | `/skill:star-*` |
| Pi | `.pi/skills/` | `/star-*` |
| Qwen Code | `.qwen/skills/` | `/star-*` |

The fifteen skill directory names are:

```text
star-proj-adopt
star-idea-storm
star-plan-coach
star-refs-reviewer
star-code-architect
star-env-builder
star-plan-decomposer
star-plan-executor
star-code-reviewer
star-expt-analyst
star-expt-digest
star-plan-reviser
star-flow-status
star-metd-summarize
star-code-release
```
