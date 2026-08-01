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
  - [Model-id provenance hooks](#model-id-provenance-hooks)
  - [Pre-approve the status collector](#pre-approve-the-status-collector)
- [Research workflow](#research-workflow)
  - [Model selection](#model-selection)
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
├── .claude/hooks/          # Model-id provenance hook for Claude
├── .codex/hooks/           # Model-id provenance hook for Codex
├── .cursor/hooks/          # Model-id provenance hook for Cursor
├── .kimi-code/hooks/       # Model-id provenance hook for Kimi Code (see Per-tool setup)
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

### Model-id provenance hooks

If you drive STAR with **Kimi Code**, run this once per machine so skills record the real `model_id` instead of `unrecorded`:

```bash
bash .kimi-code/hooks/install.sh
```

It registers the provenance hook in your global `~/.kimi-code/config.toml`, backing that file up first; running it twice changes nothing, and one run covers every STAR project. Codex, Claude, and Cursor ship their hook already registered, so skip this step there. On Codex, though, registered is not yet running: a project hook fires only once the project is trusted and the hook approved. Run `/hooks` in the Codex CLI to approve it, and again whenever the hook changes. Until you do, `model_id` reads `unrecorded` in every report, and nothing points out the gap. See [`.kimi-code/hooks.example.toml`](.kimi-code/hooks.example.toml) for the manual route and details.

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

## Updating STAR skills and workflow guides

After creating a project from STAR, you can sync later STAR skill and research workflow guide releases without changing project code, experiment configuration, or Git remotes:

```bash
bash execs/update.sh
```

By default, the command updates these paths from STAR's `main` branch:

- `AGENTS.md` and `.cursor/rules/` — the shared agent instructions and the Cursor rule that copies their body; your own edits to them are replaced
- `.agents/skills/`, `.claude/skills/`, `.cursor/skills/`, `.kimi-code/skills/`
- `.claude/hooks/`, `.codex/hooks/`, `.cursor/hooks/`, `.kimi-code/hooks/`, and `.kimi-code/hooks.example.toml` — the model-id provenance hooks
- `docs/mds/star-workflow/`, and `docs/srcs/` — the workflow documentation, and the icon and workflow diagram STAR's own pages use

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

- **[v0.1.7](https://github.com/wanghao9610/STAR/tree/v0.1.7)** (2026-08-01) — The Kimi skill tree regains the mechanisms its port had flattened to prose — AskUserQuestion structured questions, plan-mode approval via `EnterPlanMode`/`ExitPlanMode`, and `Agent` subagent dispatch — with subagent types mapped to Kimi's `explore`/`coder` and `multiSelect` renamed to Kimi's `multi_select`. The legitimate adaptations stay: `/skill:` invocation, `AGENTS.md` references, Kimi model-id wording, and the `kimi -p` fallback.
- **[v0.1.6](https://github.com/wanghao9610/STAR/tree/v0.1.6)** (2026-07-30) — `star-flow-status` splits its opening load into two commands sent together — the conventions excerpts, whose size is fixed, and the collector's digest, which grows with the project's history. The two shared one result-size limit, so on a project with history the pair overran it and both were spilled to a file; split, the excerpts always arrive and only the digest can still spill.
- **[v0.1.5](https://github.com/wanghao9610/STAR/tree/v0.1.5)** (2026-07-30) — Four more skills — `star-plan-decomposer`, `star-plan-executor`, `star-plan-reviser`, `star-metd-summarize` — read the plan tree through the shared read-only collector instead of opening each plan. A second skill in the same conversation may reuse the opening load it can still see, the collector's digest excepted. `star-plan-decomposer` renames its three decomposition axes to phase, component, and experiment, each named for the unit that level holds. It recommends the experiment axis only once the code runs end to end; that axis holds experiment groups, with the individual claims one digit deeper.
<details>
<summary>Earlier releases</summary>

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
