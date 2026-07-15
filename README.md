<div align="center">
  <img src="docs/assets/star-project-icon.png" alt="STAR project icon" width="128">
  <h1>STAR</h1>
  <p><strong>Structured Toolkit for AI Research</strong></p>
  <p><em>A reusable project template for reproducible and well-structured AI research.</em></p>
  <p><strong>English</strong> · <a href="README.zh-CN.md">简体中文</a></p>
</div>

STAR provides a lightweight starting point for artificial intelligence research projects. It keeps source code, datasets, model weights, experiment outputs, and methodology notes in predictable locations, while offering a single experiment entrypoint and shared instructions for both researchers and AI coding agents.

The template is intentionally framework-agnostic: bring your own model stack, dependency manager, and experiment tracker.

## What STAR provides

- **A consistent project layout** for code, data, weights, outputs, and research notes.
- **A portable runtime boundary**: machine-specific paths live in a local `.env` file rather than in scripts.
- **A single experiment entrypoint** through `execs/run.sh`.
- **AI-friendly project guidance** shared across Codex, Claude, and Cursor.
- **A plan-to-execution workflow** for drafting, decomposing, executing, and tracking research plans.
- **Safe defaults for large artifacts**: local data, weights, outputs, and environment settings are excluded from version control.

## Project structure

```text
STAR/
├── code/                   # Core project source code (configured by CODE_NAME)
├── docs/                   # Project documentation
├── datas/                  # Datasets and data-related files
├── inits/                  # Model weights, checkpoints, and initialization files
├── wkdrs/                  # Generated outputs and run-specific artifacts
├── metds/
│   └── plans/              # Research plans and executable sub-plans
├── execs/
│   ├── run.sh              # Main experiment launcher
│   ├── update-star.sh      # Sync upstream STAR skills and documentation
│   └── scpts/              # Experiment-specific shell scripts
├── .agents/skills/         # Research workflow skills for Codex
├── .claude/skills/         # Research workflow skills for Claude
├── .cursor/rules/          # Always-on project rules for Cursor
├── .vscode/                # Editor and debugging defaults
├── .env.example            # Portable environment configuration template
├── AGENTS.md               # Shared instructions for AI coding agents
└── README.md
```

Use `docs/` for project-facing documentation such as setup guides, usage guides, and design references. Keep research plans, methodology notes, and research design records under `metds/`.

The abbreviated directory names are deliberate:

| Directory | Meaning | Contents |
| --- | --- | --- |
| `datas/` | Data | Raw, processed, or generated datasets |
| `inits/` | Initializations | Pretrained weights and checkpoints |
| `metds/` | Methodologies | Research plans, design notes, and methodology records |
| `execs/` | Executions | Launchers and experiment scripts |
| `scpts/` | Scripts | Individual runnable experiment definitions |
| `wkdrs/` | Work directories | Logs, metrics, predictions, and other generated outputs |

## Quick start

### 1. Create a project from the template

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

### 2. Configure the local runtime

Copy the environment template:

```bash
cp .env.example .env
```

Then edit `.env`:

```dotenv
CODE_NAME=YOUR_CODE_NAME
CONDA_HOME=/path/to/conda
PYTHON_HOME=/path/to/conda/envs/your-env
```

- `CODE_NAME` is the source directory relative to the project root.
- `CONDA_HOME` is the root of the local Conda installation.
- `PYTHON_HOME` may be either the environment directory or its Python executable.

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
ROOT_DIR  CODE_DIR  DATA_DIR  INIT_DIR
WORK_DIR  SCPT_DIR
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

STAR includes four complementary skills that turn a research idea into an auditable execution process:

| Skill | Purpose | Main output |
| --- | --- | --- |
| `$rsch-plan-coach` | Clarify a research idea through staged questions | `metds/plans/0_<topic>_plan.md` |
| `$rsch-plan-decomposer` | Split a strategic plan into verifiable sub-plans | `metds/plans/<prefix>_<task>_plan.md` |
| `$rsch-plan-executor` | Implement and lightly validate one executable leaf plan | Code plus `wkdrs/<run>/EXEC_PLAN.md` and `EXEC_LOG.md` |
| `$rsch-plan-status` | Report plan-tree progress and the next runnable task | Read-only status summary |

A typical flow is:

```text
research idea
    → research plan
    → executable sub-plans
    → implementation and validation
    → status and next action
```

These skills preserve decisions and progress in project files instead of relying on chat history. English and Chinese research workflows are both supported.

See [`docs/research-workflow-skills.md`](docs/research-workflow-skills.md) for invocation details, a complete example, generated files, and troubleshooting guidance.

## Updating STAR skills and documentation

After creating a project from STAR, you can sync later STAR skill and documentation releases without changing project code, experiment configuration, or Git remotes:

```bash
bash execs/update-star.sh
```

By default, the command updates these directories from STAR's `main` branch:

- `.agents/skills/`
- `.claude/skills/`
- `.cursor/skills/`
- `docs/`

To pin the update to a tag or branch, pass it as an argument:

```bash
bash execs/update-star.sh TAG_OR_BRANCH
```

Files at matching paths are overwritten and new upstream files are added. Project-specific files that exist only in these directories are preserved. To avoid deleting custom content, files removed upstream are not removed locally. The update does not modify other directories, the current branch, Git remotes, or the staging area. Commit current work before updating, then review and commit the result with `git status` and `git diff`.

## Project conventions

1. Keep reusable implementation in `${CODE_NAME}/`.
2. Keep data in `datas/`, weights in `inits/`, and generated artifacts in `wkdrs/`.
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

Keep the structure only where it remains useful—the template should support the research, not constrain it.

## License

This template is released under the [MIT License](LICENCE).
