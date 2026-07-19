<div align="center">
  <img src="docs/srcs/star-project-icon.png" alt="STAR project icon" width="128">
  <h1>STAR</h1>
  <p><strong>Structured Toolkit for AI Research</strong></p>
  <p><em>A reusable foundation for reproducible and well-structured AI research.</em></p>
</div>

**Language:** English | [简体中文](README.zh-CN.md)

STAR provides a lightweight starting point for artificial intelligence research projects. It keeps source code, datasets, model weights, experiment outputs, and methodology notes in predictable locations, while offering a single experiment entrypoint and shared instructions for both researchers and AI coding agents. Its built-in research workflow connects research ideas, plans, executable sub-plans, implementation and validation, and status tracking, while preserving key decisions, task dependencies, and validation records in project files for cross-session continuity and auditability.

STAR is intentionally framework-agnostic: the research workflow defines only the process, file locations, and validation records, so you can still bring your own model stack, dependency manager, and experiment tracker.

## What STAR provides

- **A consistent project layout** for code, data, weights, outputs, and research notes.
- **A portable runtime boundary**: machine-specific paths live in a local `.env` file rather than in scripts.
- **A single experiment entrypoint** through `execs/run.sh`.
- **A complete research lifecycle** through thirteen complementary skills for adopting an already-started project without disturbing it, converging a vague interest into a defensible research topic, drafting plans, surveying the related work into analysis notes and a verified bibliography, recursively decomposing them, bootstrapping the codebase from a reference implementation, building the runtime environment, executing leaf plans, reviewing code against conventions and plan promises, analyzing run results against what the plan expected, revising plans against execution evidence, summarizing global status, and compiling the matured plans into method documents.
- **A traceable, resumable research process** that stores plans under `metds/plans/`, plan-execution intermediates under `tasks/`, and generated run artifacts under `wkdrs/` instead of relying on chat history for context.
- **AI-friendly project guidance and research workflows** shared across Codex, Claude, and Cursor, with support for both English and Chinese.
- **Safe defaults for large artifacts**: local data, weights, outputs, and environment settings are excluded from version control.

See [Research workflow](#research-workflow) for the responsibilities, invocation patterns, and complete examples for all thirteen skills.

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
├── .cursor/rules/          # Always-on project rules for Cursor
├── .vscode/                # Editor and debugging defaults
├── .env.example            # Portable environment configuration example
├── AGENTS.md               # Shared instructions for AI coding agents
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

For example, executing `metds/plans/00_demo_plan.md` creates `tasks/00_demo/` for that plan's own tool scripts — a verification or indexing script its done-criterion runs — and its intermediate execution files; any generated experiment artifacts still go to the applicable `wkdrs/<run-name>/` directory.

## Quick start

### 1. Start a project with STAR

Use this repository as a GitHub template, or clone/copy it into a new project:

```bash
git clone https://github.com/wanghao9610/STAR
cd STAR
rm -rf .git
cd ..
mv STAR YOUR_PROJ_NAME
cd YOUR_PROJ_NAME
mv code YOUR_CODE_NAME  # Or copy or clone your existing codebase into YOUR_CODE_NAME.
git init
git add .
git commit -m "First commit."
```

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
run `/star-proj-adopt` inside that repository — it probes the layout, writes `.env`, reaches your
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

The launcher activates the configured Conda environment and exports these paths for experiment scripts:

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

Run names and output directories should distinguish tasks, experiments, or repetitions. Generated artifacts belong under `wkdrs/<run-name>/`.

## Research workflow

STAR includes thirteen complementary skills that turn a vague research interest into an auditable execution process:

<div align="center">
  <img src="docs/srcs/star-research-workflow.png" alt="STAR research workflow: twelve skills in the order they run in plus one that reads them all, what each one writes, and how the per-leaf loop closes" width="100%">
</div>

| Skill | Purpose | Main output |
| --- | --- | --- |
| `$star-proj-adopt` | Adopt an already-started project without disturbing it: probe the existing repository, wire `.env` and reach existing data / weights / output trees by symlink, wrap existing launch commands, record what is already built and run, then — once the plan tree exists — backfill the finished leaves | `metds/adopt.md`, plus `exec_status:` / `exec_runs:` on confirmed leaves |
| `$star-idea-storm` | Converge a vague interest into a defensible research topic: diverge into candidate directions, scan the landscape at abstract level with every named paper transcribed from a fetched record, score on six dimensions, and frame the winner with a first validation experiment | `metds/ideas/<slug>_idea.md` |
| `$star-plan-coach` | Clarify a research idea through staged questions | `metds/plans/<digit>_<topic>_plan.md` |
| `$star-refs-reviewer` | Survey the work related to the method: read the closest papers into analysis notes and build a classified bibliography whose every entry is transcribed from a fetched record | `metds/refs/<ABBREV>.md`, `metds/refs/reference.bib`, and `metds/refs/refs_index.md` |
| `$star-code-architect` | Bootstrap `${CODE_NAME}/` from a scored reference implementation, or organize existing code, and record the architecture | `${CODE_NAME}/` with `UPSTREAM.md`, plus `metds/codearc.md` |
| `$star-env-builder` | Build the conda env or venv from `.env`, resolve and install dependencies through a uv > pip > conda ladder, and smoke-verify the result; `add` installs new packages into the existing env and records them | Environment plus `wkdrs/env_<name>_<date>/ENV_REPORT.md` and `freeze.txt` |
| `$star-plan-decomposer` | Split a strategic plan into verifiable sub-plans | `metds/plans/<prefix>_<task>_plan.md` |
| `$star-plan-executor` | Implement and lightly validate one executable leaf plan | The plan's own tool scripts and intermediate working files under `tasks/<plan-name>/`; code plus `wkdrs/<run>/EXEC_PLAN.md`, `EXEC_LOG.md`, and generated artifacts; confirmed deviations synced back into the plan with a Revision History entry |
| `$star-code-reviewer` | Review code against project conventions and a plan's promised implementation, then apply approved mechanical fixes | `wkdrs/<run>/CODE_REVIEW_<date>.md` or `wkdrs/reviews/code_<scope>_<date>.md` |
| `$star-expt-analyst` | Audit what a run produced against what the plan expected: artifacts, log health, metrics scored against the done-criteria, and what the result means for the claim | `wkdrs/<run>/EXPT_ANALYSIS_<date>.md` plus `wkdrs/<run>/analysis/` figures; `metds/results.md` in `aggregate` mode |
| `$star-plan-reviser` | Review one plan against its execution evidence and revise it in place | `wkdrs/<run>/REVIEW_<date>.md` plus the plan revised with a Revision History entry |
| `$star-flow-status` | Report progress across the whole flow — the plan tree, plus finished work whose review, analysis, or write-up is missing or stale — and the single next action | Read-only status summary |
| `$star-metd-summarize` | Compile the plan tree into paper-ready method documents, marking what is not yet verified and turning what no plan covers into TODOs | `metds/overview.md`, `dataset.md`, `framework.md`, `training.md`, and `evaluation.md` |

### Model selection

Different stages benefit from different model strengths. For brainstorming and judging research directions, for drafting, decomposing, and revising research plans, for judging how related work positions the method, for interpreting what experiment results mean, and for compiling the plans into method write-ups, we recommend using Claude Fable5 Extra or ChatGPT5.6 Sol High with `$star-idea-storm`, `$star-plan-coach`, `$star-refs-reviewer`, `$star-plan-decomposer`, `$star-expt-analyst`, `$star-plan-reviser`, and `$star-metd-summarize`. For codebase bootstrapping, environment builds, plan execution, code review, and progress summaries, we recommend using Claude Opus4.8 Medium (Sonnet5 High), ChatGPT5.6 Sol Medium (Terra High), or Cursor Grok4.5 High with `$star-proj-adopt`, `$star-code-architect`, `$star-env-builder`, `$star-plan-executor`, `$star-code-reviewer`, and `$star-flow-status`. When resources permit, using the strongest available model across all thirteen workflows generally delivers the best overall results.

These skills preserve decisions and progress in project files instead of relying on chat history. English and Chinese research workflows are both supported.

See the [Research Workflow Skills Guide](docs/mds/star-workflow/research-workflow-skills.md) for invocation details, a complete example, generated files, and troubleshooting guidance.

## Updating STAR skills and workflow guides

After creating a project from STAR, you can sync later STAR skill and research workflow guide releases without changing project code, experiment configuration, or Git remotes:

```bash
bash execs/update.sh
```

By default, the command updates these directories from STAR's `main` branch:

- `.agents/skills/`
- `.claude/skills/`
- `.cursor/skills/`
- `docs/mds/star-workflow/`

To pin the update to a tag or branch, pass it as an argument:

```bash
bash execs/update.sh TAG_OR_BRANCH
```

To update one skill only, pass its directory name with `--skill`:

```bash
bash execs/update.sh --skill star-plan-coach
```

This updates the matching skill in all three tool-specific directories:

- `.agents/skills/star-plan-coach/`
- `.claude/skills/star-plan-coach/`
- `.cursor/skills/star-plan-coach/`

The workflow documentation under `docs/mds/star-workflow/` is not updated in single-skill mode. To update a skill from a specific tag or branch, combine the ref and option:

```bash
bash execs/update.sh TAG_OR_BRANCH --skill star-plan-coach
```

The general command form is `bash execs/update.sh [ref] [--skill NAME]`. If the named skill is invalid or is missing from any of the three upstream skill directories, the command stops without overwriting local files. Run `bash execs/update.sh --help` for the built-in usage summary.

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
- Update the copyright holder and year in `LICENCE`.

Keep only the structure that remains useful—STAR should support the research, not constrain it.

## License

STAR is released under the [MIT License](LICENCE).
