<div align="center">
  <img src="docs/srcs/star-project-icon.png" alt="STAR project icon" width="128">
  <h1>STAR</h1>
  <p><strong>Systematic Toolchain for AI Research</strong></p>
  <p><em>A reusable foundation for reproducible and well-structured AI research.</em></p>
  <p><a href="https://wanghao9610.github.io/STAR/"><strong>Documentation site</strong></a></p>
</div>

**Language:** English | [简体中文](README.zh-CN.md)

STAR provides a lightweight starting point for artificial intelligence research projects. It keeps source code, datasets, model weights, experiment outputs, and methodology notes in predictable locations, and gives researchers and AI coding agents one experiment entrypoint and one shared set of instructions. Its built-in research workflow runs from research idea, to plan, to executable sub-plans, to implementation and validation, to status tracking. Along the way it writes key decisions, task dependencies, and validation records into project files, so the work survives across sessions and can be audited afterwards.

STAR is intentionally framework-agnostic: the research workflow defines only the process, file locations, and validation records, so you can still bring your own model stack, dependency manager, and experiment tracker.

Once the research is ready to be written up, [STAGE](https://github.com/wanghao9610/STAGE) (*Systematic Toolchain for Authoring, Guiding, and Editing*, [documentation site](https://wanghao9610.github.io/STAGE/)) is the writing-side companion: STAR runs the research and produces the method documents, results, and digests; STAGE imports them as read-only, fingerprinted evidence and writes the paper on top, so every number in the manuscript traces back to the run that produced it. The pairing is optional — STAR does not depend on it.

## Contents

- [Contents](#contents)
- [What STAR provides](#what-star-provides)
- [Project structure](#project-structure)
- [Quick start](#quick-start)
  - [1. Start a project with STAR](#1-start-a-project-with-star)
  - [1b. Or adopt a project that already exists](#1b-or-adopt-a-project-that-already-exists)
  - [2. Configure the local runtime](#2-configure-the-local-runtime)
  - [3. Add an experiment](#3-add-an-experiment)
  - [4. Run it](#4-run-it)
  - [5. Start the research workflow](#5-start-the-research-workflow)
- [Per-tool setup (optional)](#per-tool-setup-optional)
  - [Session hooks](#session-hooks)
  - [Pre-approve the status collector](#pre-approve-the-status-collector)
- [Research workflow](#research-workflow)
  - [Model selection](#model-selection)
- [Project memory](#project-memory)
- [Updating STAR skills and workflow guides](#updating-star-skills-and-workflow-guides)
- [Project conventions](#project-conventions)
- [Adapting STAR to a new project](#adapting-star-to-a-new-project)
- [Change log](#change-log)
- [Citation](#citation)
- [License](#license)

## What STAR provides

- **A consistent project layout** for code, data, weights, outputs, and research notes.
- **A portable runtime boundary**: machine-specific paths live in a local `.env` file rather than in scripts.
- **A single experiment entrypoint** through `execs/run.sh`.
- **A complete research lifecycle** through fifteen complementary skills, in the order they run: adopt an already-started project without disturbing it, converge a vague interest into a research topic, draft the plan, survey the related work, decompose the plan into leaves, bootstrap the codebase, build the runtime environment, execute each leaf, review the code, analyze what a run produced, digest recent progress, revise plans against execution evidence, report global status, compile the finished plans into method documents, and prepare the repository for release.
- **A traceable, resumable research process** that stores plans under `metds/plans/`, plan-execution intermediates under `tasks/`, and generated run artifacts under `wkdrs/` instead of relying on chat history for context.
- **A memory the project owns**: what a session learns that no plan or report holds — an environment quirk, a standing preference, a dead end — is recorded under `.star/memory/` and put in front of the next session by a hook, in whichever tool you drive STAR with.
- **AI-friendly project guidance and research workflows** shared across Codex, Claude, Kimi Code, and Cursor, with support for both English and Chinese.
- **Safe defaults for large artifacts**: local data, weights, outputs, and environment settings are excluded from version control.

See [Research workflow](#research-workflow) for what each of the fifteen skills is responsible for, what it writes, and how to invoke it in your tool. The [Research Workflow Skills Guide](docs/mds/star-workflow/research-workflow-skills.md) adds a worked end-to-end example, the generated files, and troubleshooting.

## Project structure

```text
STAR/
├── code/                   # Core project source code (configured by CODE_NAME)
├── docs/                   # Project documentation site
│   ├── index.html          # Documentation entrypoint for GitHub Pages
│   ├── htmls/              # HTML documentation pages
│   ├── mds/                # Markdown documentation grouped by topic
│   └── srcs/               # Documentation images and other static assets
├── datas/                  # Datasets and data-related files
├── inits/                  # Model weights, checkpoints, and initialization files
├── tasks/                  # Plan-specific execution-process intermediate files
├── wkdrs/                  # Generated outputs and run-specific artifacts
├── metds/
│   ├── ideas/              # Idea-storm topic explorations and finalized topic statements
│   ├── plans/              # Research plans and executable sub-plans
│   ├── refs/               # Related-work analyses and the verified reference.bib
│   └── overview.md …       # Method documents compiled from the plans
├── execs/
│   ├── run.sh              # Main experiment launcher
│   ├── update.sh           # Sync upstream STAR skills and workflow guides
│   └── scpts/              # Experiment-specific shell scripts
├── .agents/skills/         # Research workflow skills for Codex
├── .claude/skills/         # Research workflow skills for Claude
├── .cursor/skills/         # Research workflow skills for Cursor
├── .kimi-code/skills/      # Research workflow skills for Kimi Code
├── .claude/hooks/          # Session hooks for Claude: model-id provenance, project memory
├── .codex/hooks/           # Session hooks for Codex
├── .cursor/hooks/          # Session hooks for Cursor
├── .kimi-code/hooks/       # Session hooks for Kimi Code (see Per-tool setup)
├── .star/memory/           # Project memory: what earlier sessions learned (local/ is git-ignored)
├── .cursor/rules/          # Always-on project rules for Cursor
├── .vscode/                # Editor and debugging defaults
├── .github/                # STAR's own maintainer CI; delete it in your project
├── .env.example            # Portable environment configuration example
├── AGENTS.md               # Shared instructions for AI coding agents
├── CLAUDE.md               # Symlink to AGENTS.md, so Claude Code loads the same rules
└── README.md
```

Use `docs/htmls/` for HTML pages, `docs/mds/` for Markdown documentation grouped by topic, and `docs/srcs/` for images and other static assets. `docs/index.html` is the documentation entrypoint. Keep research plans, methodology notes, and research design records under `metds/`.

The abbreviated directory names are deliberate:

| Directory | Meaning | Contents |
| --- | --- | --- |
| `datas/` | Data | Raw, processed, or generated datasets |
| `inits/` | Initializations | Pretrained weights and checkpoints |
| `metds/` | Methodologies | Research plans, design notes, and methodology records |
| `execs/` | Executions | Launchers and experiment scripts |
| `scpts/` | Scripts | Individual runnable experiment definitions |
| `tasks/` | Tasks | Each plan's own tool scripts plus the intermediate files produced while executing it, grouped by plan name |
| `wkdrs/` | Work directories | Run logs, metrics, predictions, and other generated outputs |
| `mds/` | Markdowns | Markdown documentation, grouped by topic |
| `htmls/` | HTMLs | Rendered HTML documentation pages |
| `srcs/` | Static sources | Images and other static assets the docs embed |

For example, executing `metds/plans/00_demo_plan.md` creates `tasks/00_demo/`. That directory holds the plan's own tool scripts — a verification or indexing script its done-criterion runs — together with its intermediate execution files. Generated experiment artifacts still go to the applicable `wkdrs/<run-name>/` directory.

## Quick start

### 1. Start a project with STAR

Use this repository as a GitHub template, or clone/copy it into a new project:

```bash
git clone https://github.com/wanghao9610/STAR
cd STAR
rm -rf .git
rm -rf .github        # Upstream maintainer CI; it checks STAR's own skill mirrors.
cd ..
mv STAR YOUR_PROJ_NAME
cd YOUR_PROJ_NAME
mv code YOUR_CODE_NAME  # Or copy or clone your existing codebase into YOUR_CODE_NAME.
git init
git add .
git commit -m "First commit."
```

`.github/` holds the consistency check STAR uses to keep its four skill mirrors in step. It is for maintaining STAR itself, not for your project: left in place it runs on every push to your `main` and fails the first time you edit `AGENTS.md` or delete a tool directory you do not use. The adopt path in step 1b never installs it.

If `YOUR_CODE_NAME/` was cloned from another Git repository and its files should be included directly in this project, remove its nested Git metadata with `rm -rf YOUR_CODE_NAME/.git` before running `git add .`.

### 1b. Or adopt a project that already exists

If the project is already underway — real code, a working environment, months of commits, results
already in hand — install the skeleton into it instead of moving it into STAR. Run this at the root
of that repository:

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o /tmp/star-update.sh
bash /tmp/star-update.sh --adopt
```

Nothing that is already there is overwritten: every existing file is left alone and reported. Then
run `/star-proj-adopt` inside that repository. It probes the layout and writes `.env`, reaches your
existing data, weights, and output trees by symlink rather than moving them, wraps your existing
launch commands, and records what is already built and run. Steps 2–4 below then apply unchanged.

### 2. Configure the local runtime

Copy the example environment file:

```bash
cp .env.example .env
```

Then edit `.env`:

```dotenv
CODE_NAME=YOUR_CODE_NAME
ENV_NAME=your-env
CONDA_HOME=/path/to/conda
PYTHON_HOME=/path/to/conda/envs/your-env
```

- `CODE_NAME` is the source directory relative to the project root.
- `PYTHON_HOME` selects the runtime. It may be either the environment directory or its Python executable.
- `CONDA_HOME` is the root of the local Conda installation, `ENV_NAME` the environment name inside it.

`PYTHON_HOME` is authoritative, so there are two ways to configure the runtime:

- **Set `PYTHON_HOME`.** It is used as given, and `CONDA_HOME` / `ENV_NAME` may be left empty. Without `CONDA_HOME`, the interpreter runs directly instead of through `conda activate` — this is also how a plain `.venv` is used.
- **Leave `PYTHON_HOME` empty and set both `CONDA_HOME` and `ENV_NAME`.** `PYTHON_HOME` is then derived as `$CONDA_HOME/envs/$ENV_NAME`.

Setting neither is an error.

Optionally, add `INVOLVE=low|medium|high` to set how much the STAR skills ask before they decide. At `low` a skill takes the recommended option on judgment calls and logs that it did; `medium` (the default) asks as documented; `high` confirms each step. Safety gates — the STOP line, commits, deletions — are asked at every level. To change the level for a single run, add the same token when you call a skill: `$star-plan-executor 00 involve=low`. Full rule: [research workflow conventions](docs/mds/star-workflow/research-workflow-conventions.md#7-dialogue) §7.7.

A second optional key, `STAR_LANG=en|zh`, fixes one language for both the agents' replies and newly generated workflow documents (plans, reports). Left unset, both follow the conversation's language. An explicit request in the conversation wins either way, and existing documents keep the language declared in their frontmatter. Full rule: [research workflow conventions](docs/mds/star-workflow/research-workflow-conventions.md#7-dialogue) §7.6.

A third, `STAR_REPOSITORY`, names the repository `execs/update.sh` pulls later skill and workflow guide releases from. It ships pointing at STAR itself; change it only to update from a fork. See [Updating STAR skills and workflow guides](#updating-star-skills-and-workflow-guides).

The local `.env` file is ignored by Git, so machine-specific paths are not committed.

### 3. Add an experiment

Put reusable project code under the directory named by `CODE_NAME`, then add an experiment script under `execs/scpts/`. For example:

```bash
#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${WORK_DIR}/baseline"
mkdir -p "${RUN_DIR}"

python "${CODE_DIR}/train.py" \
    --data-dir "${DATA_DIR}" \
    --output-dir "${RUN_DIR}" \
    "$@"
```

The launcher resolves the interpreter from `.env` — activating Conda when `CONDA_HOME` is set, otherwise using `PYTHON_HOME` directly — and exports these paths for experiment scripts:

```text
ROOT_DIR  CODE_DIR  DATA_DIR  INIT_DIR WORK_DIR  SCPT_DIR
```

### 4. Run it

```bash
# Show available experiment scripts
bash execs/run.sh --list

# Run the default experiment: execs/scpts/00_exp.sh
bash execs/run.sh

# Run a named experiment and forward additional arguments
bash execs/run.sh 00_exp --config config.yaml
```

The stock `00_exp.sh` runs no science. It prints the interpreter the launcher resolved and the six exported paths, so a fresh checkout has one command that visibly succeeds and confirms `.env` is wired correctly. Replace it with your first real experiment when starting a project from STAR. Run names and output directories should distinguish tasks, experiments, or repetitions, and generated artifacts belong under `wkdrs/<run-name>/`.

### 5. Start the research workflow

The skeleton above stands on its own — the layout, `.env`, and `execs/run.sh` are useful without any of the skills. To pick up the workflow, start at whichever of these describes you, using your tool's prefix from [Research workflow](#research-workflow):

| Where you are | Start with |
| --- | --- |
| An interest, but no defined topic yet | `star-idea-storm <your interest>` |
| A topic in hand, ready to plan | `star-plan-coach <your topic>` |
| A project you just adopted with step 1b | `star-proj-adopt` |
| Returning to a project already under way | `star-flow-status` |

`star-flow-status` is the one to remember: it reads the plan tree and the reports on disk and names the single next action, so you never have to recall where you left off.

## Per-tool setup (optional)

Neither is needed to get started. Do them when the tool you drive STAR with needs them.

### Session hooks

Two hooks run at the start of a session: one records the model id skills write into every artifact, the other puts the [project memory](#project-memory) index in front of the agent.

If you drive STAR with **Kimi Code**, run this once per machine so both are registered, and skills record the real `model_id` instead of `unrecorded`:

```bash
bash .kimi-code/hooks/install.sh
```

It registers them in your global `~/.kimi-code/config.toml`, backing that file up first; running it twice changes nothing, one run covers every STAR project, and a machine set up before the memory hook existed gains just that one. Codex, Claude, and Cursor ship both hooks already registered, so skip this step there. On Codex, though, registered is not yet running: a project hook fires only once the project is trusted and the hook approved. Run `/hooks` in the Codex CLI to approve them, and again whenever a hook changes. Until you do, `model_id` reads `unrecorded` in every report and no memory reaches the session, with nothing pointing out the gap. A project adopted before one of these hooks existed keeps its own registration file — `execs/update.sh` never overwrites it, and names the hook missing from it instead. See [`.kimi-code/hooks.example.toml`](.kimi-code/hooks.example.toml) for the manual route and details.

### Pre-approve the status collector

Six skills open the same plans, run logs, and reports before doing anything else: `star-flow-status`, `star-expt-digest`, `star-plan-decomposer`, `star-plan-executor`, `star-plan-reviser` and `star-metd-summarize`. Rather than open those files one by one, each gathers them with a single read-only script — `scripts/scan.sh`, in that skill's own directory inside your tool's directory. That is a shell call, so your agent asks to approve it the first time it runs.

Claude Code needs nothing on a fresh install: `.claude/settings.json` ships allow rules for exactly those six scripts and nothing else. A project adopted earlier keeps its own `settings.json` — `execs/update.sh` installs that file only when it is missing, and never overwrites it — so add the rules there yourself:

```json
"permissions": {
  "allow": [
    "Bash(bash .claude/skills/star-flow-status/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-expt-digest/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-decomposer/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-executor/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-plan-reviser/scripts/scan.sh:*)",
    "Bash(bash .claude/skills/star-metd-summarize/scripts/scan.sh:*)"
  ]
}
```

Elsewhere, approve it once when asked, or pre-approve it in the tool:

| Tool | Where to pre-approve |
|---|---|
| Codex | its approval-policy / sandbox setting (global config, not per project) |
| Cursor | its command allowlist, in the app's settings |
| Kimi Code | your global `~/.kimi-code/config.toml` — Kimi Code does not read project-level config |

The script only reads. It globs `metds/` and `wkdrs/`, prints frontmatter and file listings, and writes nothing anywhere.

## Research workflow

STAR includes fifteen complementary skills that turn a vague research interest into an auditable execution process.

**How to invoke them.** The prefix is tool-specific, and the table below uses the Codex form:

| Tool | Invocation | Example |
| --- | --- | --- |
| Codex | `$star-<name>` | `$star-plan-coach open-vocabulary detection` |
| Claude Code | `/star-<name>` | `/star-plan-coach open-vocabulary detection` |
| Cursor | `/star-<name>` | `/star-plan-coach open-vocabulary detection` |
| Kimi Code | `/skill:star-<name>` | `/skill:star-plan-coach open-vocabulary detection` |

Every skill must be named explicitly. All four tools disable implicit invocation, so describing the task in prose does not start a skill.

<div align="center">
  <img src="docs/srcs/star-research-workflow.png" alt="STAR research workflow: thirteen skills in the order they run in plus two that read across them, what each one writes, and how the per-leaf loop closes" width="100%">
</div>

| Skill | Purpose | Main output |
| --- | --- | --- |
| `$star-proj-adopt` | Adopt an already-started project without disturbing it: probe the existing repository, wire `.env`, reach existing data / weights / output trees by symlink, wrap existing launch commands, and record what is already built and run. Once the plan tree exists, backfill the leaves that are already finished | `metds/adopt.md`, plus `exec_status:` / `exec_runs:` on confirmed leaves |
| `$star-idea-storm` | Converge a vague interest into a defensible research topic: diverge into candidate directions, scan the landscape at abstract level, score on six dimensions, and frame the winner with a first validation experiment. Every paper it names is transcribed from a fetched record | `metds/ideas/<slug>_idea.md` |
| `$star-plan-coach` | Clarify a research idea through staged questions | `metds/plans/<digit>_<topic>_plan.md` |
| `$star-refs-reviewer` | Survey the work related to the method: read the closest papers into analysis notes, and build a classified bibliography whose entries are each transcribed from a fetched record. `survey` reads a whole field in tiers and writes a standalone survey of it | `metds/refs/<ABBREV>.md`, `metds/refs/reference.bib`, `metds/refs/refs_index.md`, and `metds/refs/<slug>_survey.md` |
| `$star-code-architect` | Bootstrap `${CODE_NAME}/` from a scored reference implementation, or organize existing code, and record the architecture | `${CODE_NAME}/` with `UPSTREAM.md`, plus `metds/codearc.md` |
| `$star-env-builder` | Build the conda env or venv from `.env`, resolve and install dependencies in the uv > pip > conda install order, and smoke-verify the result. `add` installs new packages into the existing env and records them | Environment plus `wkdrs/env_<name>_<date>/ENV_REPORT.md` and `freeze.txt` |
| `$star-plan-decomposer` | Split a top-level plan into verifiable sub-plans | `metds/plans/<prefix>_<task>_plan.md` |
| `$star-plan-executor` | Implement and lightly validate one executable leaf plan | The plan's own tool scripts and intermediate working files under `tasks/<plan-name>/`; code plus `wkdrs/<run>/EXEC_PLAN.md`, `EXEC_LOG.md`, and generated artifacts; confirmed deviations synced back into the plan with a Revision History entry |
| `$star-code-reviewer` | Review code against project conventions and a plan's promised implementation, then apply approved mechanical fixes | `wkdrs/<run>/CODE_REVIEW_<date>.md` or `wkdrs/reviews/code_<scope>_<date>.md` |
| `$star-expt-analyst` | Audit what a run produced against what the plan expected: artifacts, log health, metrics scored against the done-criteria, and what the result means for the claim | `wkdrs/<run>/EXPT_ANALYSIS_<date>.md` plus `wkdrs/<run>/analysis/` figures; `wkdrs/results/results.md` (or `wkdrs/results/results_<slug>.md` when scoped) in `aggregate` mode |
| `$star-expt-digest` | Summarize recent progress on the time axis: resume from the previous digest, or cover an explicit window or a whole plan family. Tabulate each run's verdict and headline metrics from its analysis report, derive what moved since last time, and list the gaps | `wkdrs/digests/EXPT_DIGEST_<date>.md` |
| `$star-plan-reviser` | Review one plan against its execution evidence and revise it in place | `wkdrs/<run>/REVIEW_<date>.md` plus the plan revised with a Revision History entry |
| `$star-flow-status` | Report progress across the whole flow — the plan tree, plus finished work whose review, analysis, or write-up is missing or stale — and the single next action | Read-only status summary |
| `$star-metd-summarize` | Once every experiment is finished and the plans are finalized, compile the plan tree into paper-ready method documents, turning what no plan covers into TODOs | `metds/overview.md`, `dataset.md`, `framework.md`, `training.md`, and `evaluation.md` |
| `$star-code-release` | Prepare the repository for release: promote scattered code into `${CODE_NAME}/` by the recorded placement rules, polish the files a reader will open, compile the README from the method documents and the results table, and sweep for secrets, machine-local paths, and commands that do not resolve | `README.md` plus `wkdrs/release/RELEASE_<date>.md` |

### Model selection

Different stages benefit from different model strengths. Model names are as of 2026-07 and will age; a parenthesis marks an equally good alternative at that tier.

| Stage | Skills | Recommended |
|---|---|---|
| **Judgment and writing** — research directions, plans, how related work positions the method, what results mean, method write-ups | `$star-idea-storm`, `$star-plan-coach`, `$star-refs-reviewer`, `$star-plan-decomposer`, `$star-expt-analyst`, `$star-plan-reviser`, `$star-metd-summarize` | Claude Fable5 Extra, ChatGPT5.6 Sol High, or Kimi K3 |
| **Building and running** — codebase, environment, plan execution, code review, progress digests, status, release | `$star-proj-adopt`, `$star-code-architect`, `$star-env-builder`, `$star-plan-executor`, `$star-code-reviewer`, `$star-expt-digest`, `$star-flow-status`, `$star-code-release` | Claude Opus4.8 Medium (Sonnet5 High), ChatGPT5.6 Sol Medium (Terra High), Cursor Grok4.5 High, or Kimi K3 |

When resources permit, using the strongest available model across all fifteen skills generally delivers the best overall results.

These skills preserve decisions and progress in project files instead of relying on chat history. English and Chinese research workflows are both supported.

See the [Research Workflow Skills Guide](docs/mds/star-workflow/research-workflow-skills.md) for invocation details, a complete example, generated files, and troubleshooting guidance. The rules every skill shares — git, the STOP line, the `.env` runtime, dates, delegation, and dialogue discipline — are in the [Research Workflow Skill Conventions](docs/mds/star-workflow/research-workflow-conventions.md).

## Project memory

What a session learns that no plan, log, or report owns — a build that only works after a module load, a standing preference of yours, an experiment not worth repeating — is recorded in the project at `.star/memory/`, not in whichever tool you happened to be driving. One file per fact, one line per fact in `.star/memory/MEMORY.md`, and a session hook puts that index in front of the agent at the start of every session, in all four tools.

Two rules keep it from becoming a second, competing source of truth:

- **A fact is recorded there only when no file in the project already owns it.** Results belong to their run's `EXEC_LOG.md`, decisions about the research to their plan, papers to `metds/refs/`. Memory holds the residue.
- **Where a memory disagrees with a file in the repository, the file wins**, and the memory is corrected or dropped.

Facts that hold only on this machine go to `.star/memory/local/`, which git ignores the way it ignores `.env`. Nothing is recorded without your say-so: the agent offers, you decide — and `INVOLVE=low` in `.env` turns that into record-and-tell. The four kinds of memory, the file format, and how one is retired are in [Project Memory](docs/mds/star-workflow/memory_spec.md).

## Updating STAR skills and workflow guides

After creating a project from STAR, you can sync later STAR skill and research workflow guide releases without changing project code, experiment configuration, or Git remotes:

```bash
bash execs/update.sh
```

By default, the command updates these paths from STAR's `main` branch:

- `.cursor/rules/skill-roots.mdc` — which skill root each tool owns, and which copy Cursor must follow
- `.agents/skills/`, `.claude/skills/`, `.cursor/skills/`, `.kimi-code/skills/`
- `.claude/hooks/`, `.codex/hooks/`, `.cursor/hooks/`, `.kimi-code/hooks/`, and `.kimi-code/hooks.example.toml` — the model-id provenance hooks
- `docs/mds/star-workflow/`, and `docs/srcs/` — the workflow documentation, and the icon and workflow diagram STAR's own pages use
- `execs/run.sh` — the stock experiment launcher; your own edits to it are replaced, while the experiment scripts it launches, under `execs/scpts/`, are yours and are never touched

The agent instructions are the project's own: `AGENTS.md` and `.cursor/rules/agent-instructions.mdc`, which carries its body, are not in that list. They follow the same rule as the hook registration configs below — installed only when missing, and never overwritten unless you pass `--force`. A project that has written its own keeps them; one that has none gets upstream's.

The repository it pulls from is `STAR_REPOSITORY`, resolved in that order: the environment, then `.env`, then the default `https://github.com/wanghao9610/STAR.git`. Set it in `.env` to track a fork permanently, or prefix a single command — `STAR_REPOSITORY=… bash execs/update.sh` — to override it once.

Hook registration configs — `.claude/settings.json`, `.codex/hooks.json`, and `.cursor/hooks.json` — are installed only when missing, and never overwritten unless you pass `--force`. When a kept config does not register the STAR hook, the command prints a note. Projects created before hooks joined the update set should refresh the updater itself once, since `execs/update.sh` never overwrites itself:

```bash
curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o execs/update.sh
```

The general form is `bash execs/update.sh [--diff] [ref] [--skill NAME] [--force]`:

- `--diff` previews an update without changing a file, and exits `2` when one is available, `0` when everything already matches, `1` on error — so a script can tell an available update from a failed check.
- A `ref` pins the update to a tag or branch.
- `--skill NAME` updates that one skill across all four tool directories, and leaves the workflow documentation and the hooks alone. An invalid name, or one missing from any of the four upstream skill directories, stops the command without overwriting anything.
- `--force` updates the same paths with both refusals lifted: uncommitted changes under them are overwritten instead of stopping the command, and the hook registration configs are overwritten instead of kept. It widens nothing — a file upstream does not have is still left alone, so your own skills and documents under those directories stay.

`bash execs/update.sh --help` carries the full usage summary, so it stays correct when the flags change.

Files at matching paths are overwritten and new upstream files are added. Project-specific files that exist only in the updated directories are preserved. To avoid deleting custom content, files removed upstream are not removed locally. The update does not modify other directories, the current branch, Git remotes, or the staging area. Commit current work before updating, then review and commit the result with `git status` and `git diff`.

## Project conventions

1. Keep reusable implementation in `${CODE_NAME}/`.
2. Keep data in `datas/`, weights in `inits/`, plan-execution intermediates in a plan-named subdirectory under `tasks/`, and generated artifacts in `wkdrs/`.
3. Keep research plans and methodology notes in `metds/`; plan files belong in `metds/plans/`.
4. Use `execs/run.sh` as the main entrypoint and place experiment scripts in `execs/scpts/`.
5. Read runtime paths from `.env`; do not hardcode machine-specific paths.
6. Give each run a distinct output directory and record the command, configuration, and verification evidence needed to reproduce it.
7. Make small, goal-driven changes and verify them with the narrowest relevant check before broadening validation.

The full collaboration and implementation guidelines are defined in [`AGENTS.md`](AGENTS.md).

## Adapting STAR to a new project

When starting a new research repository from STAR:

- Replace the title and description with the new research project identity.
- Set `CODE_NAME` and rename `code/` if a different source package name is preferred.
- Add the project's dependency specification and lock file.
- Replace `execs/scpts/00_exp.sh` with the first meaningful experiment.
- Document how datasets and pretrained weights are obtained; do not commit large artifacts directly.
- Define the expected outputs, metrics, and reproduction commands for the project.
- Update the copyright holder and year in `LICENSE`.
- Replace `docs/htmls/star.html`, `docs/htmls/star_zh.html` and `docs/srcs/` — they are STAR's own landing pages and images, not your project's. `docs/index.html` and `docs/index_zh.html` are symlinks that serve those pages at the site root. The two pages link to each other by absolute path (`/STAR/index_zh.html`), so rewrite that `/STAR` prefix to your own repository name, or the language switch will break. Leave `docs/mds/star-workflow/` alone; `execs/update.sh` keeps it current.
- Delete the tool directories you will not use. Each of `.agents/` (Codex), `.claude/`, `.cursor/` and `.kimi-code/` is a self-contained copy of the same fifteen skills, ~150 files each; keep the one your agent reads and `rm -rf` the rest.

Keep only the structure that remains useful—STAR should support the research, not constrain it. The skeleton stands alone: the directory layout, `.env` and `execs/run.sh` work with no skills installed at all, so removing every tool directory is a supported way to use STAR.

## Change log

Highlights by release, newest first. Each release is a git tag, so `bash execs/update.sh v0.1.0` pins an update to that version.

- **[v0.1.13](https://github.com/wanghao9610/STAR/tree/v0.1.13)** (2026-08-04) — Every reference entry carries an impact score. `star-refs-reviewer` composes citations per year, venue tier, and code adoption — stars and freshness of the repo the paper's own page names — into a 0–10 total by fixed weights and log-stepped bins, from metrics fetched and dated during the run: never an impression, and never a `reference.bib` field. The sub-signals land in the index's new impact-scores table, where every total recomputes from what is logged; a component that could not be fetched renormalizes away under a `*`, and a paper under 18 months carries `new` instead of a verdict. The score decides emphasis, not membership — "close beats famous" still picks the core set: the candidate table shows the score beside a ranking that stays relevance-first, `synthesize` leads each theme with the high scorers and answers the top-scored ones in the positioning paragraph, and survey tiering alone weighs it into selection, because a field map owes its landmarks a place. Venue tiers ship as an editable lookup, calibrated for CS/AI and meant to be retuned elsewhere; stars respect GitHub's unauthenticated 60-requests/hour cap, and with Papers with Code gone (July 2025) repo discovery runs paper page → arXiv → Hugging Face papers. A new `score` mode re-fetches the whole bib's metrics in one Semantic Scholar batch call plus one GitHub call per known repo, so an existing base adopts the feature — or catches up after drift — with one command. The same release stops the updater from ever overwriting agent instructions: `AGENTS.md` and the Cursor rule that mirrors it are installed when missing, kept once written, and replaced only by `--force`.
- **[v0.1.12](https://github.com/wanghao9610/STAR/tree/v0.1.12)** (2026-08-03) — A project keeps its own memory. What a session learns that no plan, log, or report owns — an environment quirk learned by failing, a standing preference, a judgment that outlived the run that produced it, a dead end worth not repeating — is recorded under `.star/memory/`, one file per fact with a one-line index beside them, instead of inside whichever tool was driving. A second session hook, shipped for all four tools alongside the model-id one, puts that index in front of the agent at the start of every session; an `env` entry whose last confirmation is over 180 days old is marked stale where the session sees it, and the other three kinds are not aged, because a dead end stays dead and a flag that fires on healthy entries teaches the reader to skip it. `AGENTS.md` gains §10, which carries the whole write rule: record only what no file in the project already owns, offer rather than assume, and let the repository's own files win wherever a memory disagrees with them. It lands beside Project Layout and Project Runtime, so Verification moves from §10 to §11 and every citation of it across the four skill trees moves with it — a project with its own docs citing `AGENTS.md §10` should re-point them. Facts true only of one machine go to `.star/memory/local/`, git-ignored the way `.env` is. The format and the retirement rules are [`memory_spec.md`](docs/mds/star-workflow/memory_spec.md). No new skill: recall costs nothing beyond the hook, and recording is a file write that rule already governs. A project adopted before either hook existed keeps its own registration file, which the updater still never overwrites — it now names the hook missing from it rather than only the model-id one.
- **[v0.1.11](https://github.com/wanghao9610/STAR/tree/v0.1.11)** (2026-08-03) — The project points at its writing-side companion, [STAGE](https://github.com/wanghao9610/STAGE). The landing page's subtitle read "Research, by design" — a phrase whose everyday sense is "this is deliberate, not a defect", and whose one informative word the badge directly above it already carried. It becomes "Every STAGE needs a STAR", the counterpart to the subtitle STAGE's own page carries. The Chinese page takes the same English line rather than a translation, because the wordplay does not survive one, which is how STAGE's Chinese page already treats its own. The closing call to action gains a "Pair it with STAGE" button and the footer a STAGE link, symmetric with the two links STAGE has always kept to STAR, all four pointing at the repositories. Both READMEs now open on the division of labor: STAR runs the research and produces the method documents, results, and digests; STAGE imports them as read-only, fingerprinted evidence and writes the paper on top, so a number in the manuscript traces back to the run that produced it. The pairing stays optional in both directions.
<details>
<summary>Earlier releases</summary>

- **[v0.1.10](https://github.com/wanghao9610/STAR/tree/v0.1.10)** (2026-08-02) — The "change granularity" answer in `star-plan-decomposer`'s sub-plan-list confirmation gains defined behavior: it is a direction, asked first. *Coarser* merges units that share a category or a dependency and shows the list again — and when merging would leave fewer than 3, the skill says the parent did not need decomposing yet and asks whether to stop, rather than merging down to two. *Finer* never adds a sibling: a finer unit is one digit deeper, so the level stays as drafted and the units named as too coarse carry to the recursion step, which decomposes them in the same run instead of only offering to. Either direction keeps the axis already chosen. The same release makes the updater's upstream configurable: `execs/update.sh` resolves `STAR_REPOSITORY` from the environment, then `.env`, then its built-in default, so tracking a fork is one line in `.env` and overriding it for a single command is a variable in front of it. `.env.example` ships the key at the public default. The update set also gains `execs/run.sh`, so a project picks up later fixes to the experiment launcher the way it picks up skills; the experiment scripts under `execs/scpts/` remain the project's own and are never touched.
- **[v0.1.9](https://github.com/wanghao9610/STAR/tree/v0.1.9)** (2026-08-02) — The code review moves ahead of the STOP-line command. When `star-plan-executor` stops for a heavy run, its report now names `star-code-reviewer` above the command it hands back: a defect caught before the compute costs a review, the same defect caught after costs the compute and the re-run too. An exploratory leaf whose cheap command is its own test may still skip it. The loop back closes as well — a `CODE_REVIEW_<date>.md` whose blocker or major findings the log does not record as settled reopens the steps they land in, so a review finding no longer falls into the gap between "skip `done` steps on re-invoke" and the awaiting command. `star-flow-status` recommends the review in the same order, and the review rubric scores a deliverable only the un-run command can produce as `pending` rather than absent, so reviewing before the compute stops manufacturing findings nobody can act on.
- **[v0.1.8](https://github.com/wanghao9610/STAR/tree/v0.1.8)** (2026-08-01) — Every skill tree is checked against its own harness's published tool list and the `SKILL.md` spec, instead of against how the other trees are written. The Cursor tree regains structured questions — `AskQuestion` wherever Claude asks through `AskUserQuestion` — and three trees stop naming tools their harness has never had: `Shell` for Cursor and Kimi where Claude has `Bash`, `ReadFile` for Kimi, and `shell`, `request_user_input` and `update_plan` for Codex. Codex has no file-reading tool at all, so its loads say so and `cat` the files into the shell call. Its selective delegation is executable too: bounded read-only work calls `spawn_agent` with `agent_type: explorer`, implementation uses `worker`, and local execution remains the default because subagent workflows cost more tokens. Descriptions now fit the spec's 1024-character limit in all four trees, and the checks enforce both that character limit and each harness's delegation vocabulary.
- **[v0.1.7](https://github.com/wanghao9610/STAR/tree/v0.1.7)** (2026-08-01) — The Kimi skill tree regains the mechanisms its port had flattened to prose — AskUserQuestion structured questions, plan-mode approval via `EnterPlanMode`/`ExitPlanMode`, and `Agent` subagent dispatch — with subagent types mapped to Kimi's `explore`/`coder` and `multiSelect` renamed to Kimi's `multi_select`. The legitimate adaptations stay: `/skill:` invocation, `AGENTS.md` references, Kimi model-id wording, and the `kimi -p` fallback.
- **[v0.1.6](https://github.com/wanghao9610/STAR/tree/v0.1.6)** (2026-07-30) — `star-flow-status` splits its opening load into two commands sent together — the conventions excerpts, whose size is fixed, and the collector's digest, which grows with the project's history. The two shared one result-size limit, so on a project with history the pair overran it and both were spilled to a file; split, the excerpts always arrive and only the digest can still spill.
- **[v0.1.5](https://github.com/wanghao9610/STAR/tree/v0.1.5)** (2026-07-30) — Four more skills — `star-plan-decomposer`, `star-plan-executor`, `star-plan-reviser`, `star-metd-summarize` — read the plan tree through the shared read-only collector instead of opening each plan. A second skill in the same conversation may reuse the opening load it can still see, the collector's digest excepted. `star-plan-decomposer` renames its three decomposition axes to phase, component, and experiment, each named for the unit that level holds. It recommends the experiment axis only once the code runs end to end; that axis holds experiment groups, with the individual claims one digit deeper.
- **[v0.1.4](https://github.com/wanghao9610/STAR/tree/v0.1.4)** (2026-07-29) — Every skill opens with a single load message, and `SKILL_zh.md` is no longer read at runtime — it stays a full mirror for human readers. Two skills load only the conventions sections they act on.

- **[v0.1.3](https://github.com/wanghao9610/STAR/tree/v0.1.3)** (2026-07-29) — `star-refs-reviewer` gains a `survey` mode, which writes a standalone field survey to `metds/refs/`, and an `add` form that takes several papers in one call.
- **[v0.1.2](https://github.com/wanghao9610/STAR/tree/v0.1.2)** (2026-07-28) — One wording rule, in `AGENTS.md` §7 and conventions §7.11: write the action, not its name. All fifteen skills are audited against it.
- **[v0.1.1](https://github.com/wanghao9610/STAR/tree/v0.1.1)** (2026-07-27) — `star-flow-status` scans the plan tree once and `star-expt-digest` reads the same scan. Adds `STAR_LANG` to pin the language of replies and generated documents; `execs/update.sh` gains `AGENTS.md` sync and `--force`; the provenance hooks read the model id at the moment a skill records it.
- **[v0.1.0](https://github.com/wanghao9610/STAR/tree/v0.1.0)** (2026-07-24) — First official release: fifteen bilingual research workflow skills for Codex, Claude, Cursor, and Kimi, model-id provenance hooks, an `INVOLVE=low|medium|high` dial (default `medium`) setting how much the skills ask before deciding, and an updater with hook sync and `--diff` preview.
- **2026-07-15** — Initial STAR release.

</details>

## Citation

If you find STAR useful in your research, please cite:

```bibtex
@misc{star2026,
  title = {{STAR}: Systematic Toolchain for AI Research},
  author = {Hao Wang},
  howpublished = {\url{https://github.com/wanghao9610/STAR}},
  year = {2026}
}
```

## License

STAR is released under the [MIT License](LICENSE).
