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
- **AI-friendly project guidance and research workflows** shared across Codex, Claude, Kimi Code, Cursor, and Qwen Code, with support for both English and Chinese.
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
├── .qwen/skills/           # Research workflow skills for Qwen Code
├── .claude/hooks/          # Hooks for Claude: model-id provenance, project memory, involve gate
├── .codex/hooks/           # Hooks for Codex: model-id provenance, project memory, involve gate
├── .cursor/hooks/          # Session hooks for Cursor
├── .kimi-code/hooks/       # Session hooks for Kimi Code (see Per-tool setup)
├── .qwen/hooks/            # Hooks for Qwen Code: model-id provenance, project memory, involve gate
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

`.github/` holds the consistency check STAR uses to keep its five skill mirrors in step. It is for maintaining STAR itself, not for your project: left in place it runs on every push to your `main` and fails the first time you edit `AGENTS.md` or delete a tool directory you do not use. The adopt path in step 1b never installs it.

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

Optionally, add `INVOLVE=low|medium|high` to set how much the STAR skills ask before they decide. At `low` a skill takes the recommended option on judgment calls and logs that it did, and in Claude Code and Codex the permission prompt before each file edit is skipped; `medium` (the default) asks as documented; `high` confirms each step. Safety gates — the STOP line, commits, deletions — are asked at every level. To change the level for a single run, add the same token when you call a skill: `$star-plan-executor 00 involve=low`. Full rule: [research workflow conventions](docs/mds/star-workflow/research-workflow-conventions.md#7-dialogue) §7.7.

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

Two hooks run at the start of a session: one records the model id skills write into every artifact, the other puts the [project memory](#project-memory) index in front of the agent. Claude, Codex and Qwen Code carry a third hook that is not a session hook: while `.env` reads `INVOLVE=low` it answers the permission prompt before a file edit, and at every other level it does nothing. It ships registered in `.claude/settings.json`, `.codex/hooks.json` and `.qwen/settings.json` like the other two. Cursor and Kimi Code do not carry it: Cursor has no hook that fires before a file edit, and Kimi's `PermissionRequest` only observes the prompt it fires beside. All five carry a further hook, also not a session hook, and this one runs at every level: `star_commit_guard.sh` declines the git commands the [conventions](docs/mds/star-workflow/research-workflow-conventions.md) §1 forbids — blanket or forced staging, the history rewrites, and a commit whose staged files exceed 10 MB. Claude, Codex, Kimi Code and Qwen Code run it on `PreToolUse`; Cursor on `beforeShellExecution`, which is where a shell command is decided there. The matcher is the harness's own tool name — `Bash` for the first three, `run_shell_command` for Qwen Code, whose matcher reads the tool identifier rather than the display label. It is the floor under `INVOLVE=low` answering the commit offer itself: what it declines is yours to run.

If you drive STAR with **Kimi Code**, run this once per machine so both are registered, and skills record the real `model_id` instead of `unrecorded`:

```bash
bash .kimi-code/hooks/install.sh
```

It registers them in your global `~/.kimi-code/config.toml`, backing that file up first; running it twice changes nothing, one run covers every STAR project, and a machine set up before the memory hook existed gains just that one. Codex, Claude, Cursor and Qwen Code ship both hooks already registered, so skip this step there. On Codex, though, registered is not yet running: a project hook fires only once the project is trusted and the hook approved. Run `/hooks` in the Codex CLI to approve them, and again whenever a hook changes. Until you do, `model_id` reads `unrecorded` in every report and no memory reaches the session, with nothing pointing out the gap. On Qwen Code the same caveat applies only if you have turned folder trust on (`security.folderTrust.enabled`, off by default): an untrusted project runs no project-level hook, again with nothing pointing out the gap. Qwen Code also reads `QWEN.md` in preference to `AGENTS.md`, so if your project has one, STAR's instructions in `AGENTS.md` are not loaded — import them from `QWEN.md` with `@AGENTS.md` or delete the file. A project adopted before one of these hooks existed keeps its own registration file — `execs/update.sh` never overwrites it, and names the hook missing from it instead. See [`.kimi-code/hooks.example.toml`](.kimi-code/hooks.example.toml) for the manual route and details.

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
| Qwen Code | `permissions.allow` in `.qwen/settings.json`, which ships with the scan commands already listed |

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
| Qwen Code | `/star-<name>` | `/star-plan-coach open-vocabulary detection` |

Seven skills are slash-only — `star-proj-adopt`, `star-idea-storm`, `star-plan-coach`, `star-code-architect`, `star-plan-decomposer`, `star-plan-reviser`, `star-code-release`: they run only when named, because each sits on a decision that belongs to you. The agent may start the other eight itself when the task plainly matches and the target is unambiguous; naming any skill explicitly always works.

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

What a session learns that no plan, log, or report owns — a build that only works after a module load, a standing preference of yours, an experiment not worth repeating — is recorded in the project at `.star/memory/`, not in whichever tool you happened to be driving. One file per fact, one line per fact in `.star/memory/MEMORY.md`, and a session hook puts that index in front of the agent at the start of every session, in all five tools.

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
- `.agents/skills/`, `.claude/skills/`, `.cursor/skills/`, `.kimi-code/skills/`, `.qwen/skills/`
- `.claude/hooks/`, `.codex/hooks/`, `.cursor/hooks/`, `.kimi-code/hooks/`, `.qwen/hooks/`, and `.kimi-code/hooks.example.toml` — the model-id provenance, project memory, and involve-gate hooks
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
- `--skill NAME` updates that one skill across all five tool directories, and leaves the workflow documentation and the hooks alone. An invalid name, or one missing from any of the five upstream skill directories, stops the command without overwriting anything.
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
- Delete the tool directories you will not use. Each of `.agents/` (Codex), `.claude/`, `.cursor/`, `.kimi-code/` and `.qwen/` is a self-contained copy of the same fifteen skills, ~150 files each; keep the one your agent reads and `rm -rf` the rest.

Keep only the structure that remains useful—STAR should support the research, not constrain it. The skeleton stands alone: the directory layout, `.env` and `execs/run.sh` work with no skills installed at all, so removing every tool directory is a supported way to use STAR.

## Change log

Highlights by release, newest first. Each release is a git tag, so `bash execs/update.sh v0.1.0` pins an update to that version.

- **[v0.1.38](https://github.com/wanghao9610/STAR/tree/v0.1.38)** (2026-08-11) — The description [§7.12](docs/mds/star-workflow/research-workflow-conventions.md) defined now reaches the rest of the roster: eleven more skills take free text after their argument, and each says what it may do — steer where the run looks, supply words the run records — and what it may not, which is stand in for a confirmation point. Prose matching none of a skill's arguments is a description, so the run proceeds as if none was given and says so first, while a lone token that looks like an argument and matches nothing stays a question to ask rather than prose to read. The three whose first argument is already free text — `star-idea-storm`, `star-plan-coach`, `star-refs-reviewer` — need no change, because that argument is the description.
- **[v0.1.37](https://github.com/wanghao9610/STAR/tree/v0.1.37)** (2026-08-11) — Conventions [§7](docs/mds/star-workflow/research-workflow-conventions.md) gains item 12: `<skill> [TARGET] [DESCRIPTION] [involve=<level>]` is the shape the whole roster shares, and free text after the target is the user saying, in their own words, what the run is for. It is a lead and not a command — it may route a run and supply text that run then records, and it never stands in for a confirmation point, never settles a target §5.2 would have asked about, and never authorizes anything on the STOP line — with a description-routed run saying which path it took before it writes, so a misreading costs one line rather than one wrong edit. `star-plan-reviser` is the first to trade keywords for it: `drop` and `undrop` are gone, and "this one is finished, 02 replaces it" both takes the drop path and becomes the reason written into the plan.
- **[v0.1.36](https://github.com/wanghao9610/STAR/tree/v0.1.36)** (2026-08-11) — The two skills that load only the conventions sections they act on — `star-refs-reviewer` and `star-expt-digest` — now split that excerpt across two calls in one message, because the spill line is per tool result and one call carrying seven sections had come within ~10 bytes of the budget guarding it. Each call is now 12–17 KB with room to grow, and the load costs what it did before: calls sent in one message cost one round trip between them, not one each. Consistency check 20 follows — it reads every selector in a file rather than the first, sizes each on its own, and checks the prose, the citations and the quoted total against their union — and its budget goes back to the 28400 bytes it was before this session pushed against it.
<details>
<summary>Earlier releases</summary>

- **[v0.1.35](https://github.com/wanghao9610/STAR/tree/v0.1.35)** (2026-08-11) — A pass over the fifteen skills for redundancy found two things worth removing. `star-flow-status`'s "no word budget" had been loosening conventions [§7.1](docs/mds/star-workflow/research-workflow-conventions.md)'s ~500-word cap, which the precedence rule lets a skill tighten and never loosen, so the exception moves into §7.1 where it belongs — a reply whose length is set by what it must enumerate is bounded by shape instead — and the report cites it rather than declaring itself unbounded. `level:`, written into every sub-plan by the template, turned out to be read by nobody and equal to the length of the prefix, so it goes; what looked duplicated elsewhere is either text CI keeps identical across the five trees or a boundary already written down where it could be confused.
- **[v0.1.34](https://github.com/wanghao9610/STAR/tree/v0.1.34)** (2026-08-11) — Five leftovers the new drop field exposed. `exec_status: skipped` turned out to have no producer in any skill, so it stops being a legal value and is recognised only where a plan hand-wrote one, while `abandoned` — which had no status symbol of its own and no place in the method-doc gate — now has a symbol of its own, `✖`, carried by the status spec's example tree beside the dropped pair, counts out of the execution-progress denominator exactly as a dropped leaf does instead of holding that ratio under 100% for good, and clears `star-metd-summarize`'s readiness check without contributing a line to any document. The stale-code-review check compares against the newest date its `EXEC_LOG.md` carries — the scan's per-run dates line already collects every date in the file — rather than against a step-table date column the log template never had, which is why the spec had been admitting that row usually could not fire.
- **[v0.1.33](https://github.com/wanghao9610/STAR/tree/v0.1.33)** (2026-08-11) — A plan can now be given up on without being deleted: `star-plan-reviser <plan>` plus a description that gives the direction up writes `dropped: <date> — <reason>` on that node — a path that skips the audit, since a drop records a decision already made, and takes its reason from the words you used — and every skill reads the field as inherited by the whole subtree, so one line takes the node and its descendants out of the counts, the follow-up checks and the next action. `star-flow-status` renders them `⊗` with their pre-drop state in parentheses and outside its three numbers, `star-plan-executor` and `star-plan-decomposer` refuse to act on them, and `star-metd-summarize` compiles nothing from them — while the parent keeps its `children:` entry and its index line, marked `— dropped <date>`, so what was tried stays readable. What a drop does not hide is anything still on disk: a live leaf depending on a dropped node, an unmerged execution branch, or a worktree under it each still get a drift flag.
- **[v0.1.32](https://github.com/wanghao9610/STAR/tree/v0.1.32)** (2026-08-11) — `star-flow-status` now prints every node in scope on its own line, and the ~500-word reply budget that had been forcing a large tree into sentences like "8 leaves, all done" is gone: how long the report runs is set by the tree it has to show, and shape bounds the rest — one line per node, one clause per count, one line per triggered check. A `PLAN_NAME` argument now narrows what is rendered and not only what is checked, with the tree pruned to the resolved subtree in Step 2 and the three summary counts computed over it. Its spec gains a Scope section settling what an ambiguous name does in a skill that never asks: an exact numeric-prefix match separates two roots sharing a slug, several matches render every one of them, and no match lists the candidates and stops.
- **[v0.1.31](https://github.com/wanghao9610/STAR/tree/v0.1.31)** (2026-08-11) — The read-only collectors seven skills send out — `star-code-reviewer`, `star-expt-analyst`, `star-plan-reviser`, `star-proj-adopt`, `star-code-architect`, `star-idea-storm`, and the executor's orientation steps — now name `model: sonnet` in `.claude/`, the one tree whose harness takes the parameter: each transcribes into a closed return format, decides nothing, and has every line it cites reopened by the main agent before that line reaches a report or a confirmation point. Delegates whose judgment or writing is the product keep the session model — the executor's step agents, the architect's migrators, `star-refs-reviewer`'s per-paper notes, `star-plan-coach`'s blind rubric read. `star-code-reviewer` additionally stops collecting in the main agent at any scope, since a context that has been discussing the code is not a neutral reader of it, and sizes the fan-out instead: one collector up to ~50 files, shards of 10–15 past that.
- **[v0.1.30](https://github.com/wanghao9610/STAR/tree/v0.1.30)** (2026-08-10) — The seven skills that show material before asking about it — `star-plan-coach`, `star-idea-storm`, `star-plan-executor`, `star-code-release`, `star-metd-summarize`, `star-refs-reviewer`, `star-proj-adopt` — now carry that instruction where the question is asked as well as where the material is written, the material end being the phrasing v0.1.29 found insufficient in `star-plan-decomposer`. Each Dialogue Discipline gains one line naming that skill's own material — a rubric finding, a candidate table, an amendment batch — with the read-back it implies: options and nothing above them mean the material was skipped, not shortened. The rule stayed out of conventions [§7.3](docs/mds/star-workflow/research-workflow-conventions.md), where all fifteen skills would have inherited it, because `star-refs-reviewer`'s selective load of that document had 49 bytes of headroom left against its 28400-byte budget.
- **[v0.1.29](https://github.com/wanghao9610/STAR/tree/v0.1.29)** (2026-08-10) — `star-plan-decomposer` puts the sub-plan list back through the question tool, so its three answers are selectable again rather than typed, with the cards in the same message's text above the call. v0.1.28 had moved that whole confirmation into plain text on the theory that a client may drop text preceding a tool call in the same turn; a run since has shown the text above the axis question rendering fine, which leaves only the drafting skipping the cards, so the instruction now guards that where the call is made rather than where the cards are written. Dialogue Discipline follows: material too large for the options — a sub-plan draft, the drafted parent index, the rubric failures — goes above the call, never instead of it.
- **[v0.1.28](https://github.com/wanghao9610/STAR/tree/v0.1.28)** (2026-08-10) — A confirmation question no longer stands in for the material it asks about: the rubric findings in `star-plan-coach` and `star-idea-storm`, the pending amendments in `star-plan-executor`, and the change lists in `star-code-release` and `star-metd-summarize` are now written out line by line before anything is asked. Where the material never fitted in the options — ~15 ranked papers in `star-refs-reviewer`, an unbounded run or leaf list in `star-proj-adopt` — the rows are numbered, the recommendation is marked in the table, and the question asks over the numbers, since conventions [§7.3](docs/mds/star-workflow/research-workflow-conventions.md) caps a question at four. In `star-plan-decomposer` the sub-plan list and the question about it now leave as one message with no tool call between them — cards shown and then asked about through the question tool in the same turn had been reaching users as three options with nothing above them.
- **[v0.1.27](https://github.com/wanghao9610/STAR/tree/v0.1.27)** (2026-08-10) — `star-plan-decomposer` now puts the sub-plan list in front of you as one card per unit — objective, steps, deliverables, done-criterion — before it asks you to confirm it, where it used to show a row of titles whose content arrived only a step later. The cards are a sketch, not a draft: Step 4 still writes the six sections, expanding the card it was handed and naming any line drafting forces it to change. Involve is unmoved — `low` adopts the list unasked and still prints the cards in full, `high` additionally confirms each sub-plan's draft before it is written.
- **[v0.1.26](https://github.com/wanghao9610/STAR/tree/v0.1.26)** (2026-08-09) — A `star-refs-reviewer` analysis note may now carry up to three figures instead of one architecture figure, chosen by what the paper is: the method-as-a-whole figure keeps the first claim, while a dataset paper's construction pipeline, the plot an analysis paper's claim rests on, or a qualitative comparison earns its place only where the note's prose cannot carry it. Every figure kept now brings 2–4 sentences on what it shows and how to read it, written from the caption in full and the passages citing that figure by number — a figure that cannot be described from those is not kept, and a detail neither states is marked `[unverified]`. The note collector returns `referenced_at` beside each caption for exactly that, and captions are no longer trimmed at 200 characters.
- **[v0.1.25](https://github.com/wanghao9610/STAR/tree/v0.1.25)** (2026-08-08) — A fifth skill tree, `.qwen/`, brings the fifteen skills to Qwen Code: `/star-*` as in Claude and Cursor, with all four hooks registered in the project's own `.qwen/settings.json` — the involve gate among them, landing on a third harness because Qwen Code's `PreToolUse` answers with `permissionDecision: "allow"`. The port writes Qwen Code's tool identifiers (`run_shell_command`, `read_file`) rather than the display labels it also publishes, since its own bundled skills never write the labels, and check 23 now pins that choice per tree. `allowed-tools` is deliberately absent: Qwen Code's `allowedTools` grants session-scoped auto-approval instead of restricting, so carrying those blocks across would have widened what a skill may do rather than narrowing it.
- **[v0.1.24](https://github.com/wanghao9610/STAR/tree/v0.1.24)** (2026-08-08) — A run can now be housed in a `git worktree` the executor itself creates: the branch keeps isolating history, and the tree answers the orthogonal question of a busy checkout — HEAD on another run's branch, foreign uncommitted paths, handed-back commands still awaiting results — settled at the same approval confirmation point, with a housed run always carrying a branch (conventions [§11.7–9](docs/mds/star-workflow/research-workflow-conventions.md)). The tree lives at `../<root>--wt/<run>` with `.env`, `datas/`, and `inits/` symlinked in and its path recorded as `worktree:` in the run's records; the merge squashes in the main checkout with nothing switching, and removal moves the non-md artifacts out first — never `--force`, which `star_commit_guard.sh` now denies. `star-flow-status` lists worktrees beside execution branches and flags one left behind.
- **[v0.1.23](https://github.com/wanghao9610/STAR/tree/v0.1.23)** (2026-08-08) — `star-code-reviewer` stops letting the conversation that wrote the code collect the findings on it: when earlier turns of the session wrote or edited files now in scope, even a small scope hands collection to one fresh-context read-only collector carrying the whole file list, and the report's scope line records the delegation. An author rereads its own code through the reasoning that produced it; larger scopes already collected through fresh subagents, so this closes the small-scope (≤ ~20 files, the usual diff review) gap.
- **[v0.1.22](https://github.com/wanghao9610/STAR/tree/v0.1.22)** (2026-08-08) — The execution branch is named for its run, `<run>`, so the branch and its `wkdrs/<run>/` pair by name with no prefix to strip, and the listing every skill opens with becomes a glob over the run naming scheme. Separately `star-flow-status` and `star-expt-digest`, the only `context: fork` skills, read their argument from a `$ARGUMENTS` placeholder in their Invocation line: a fork sees no user turn, so the harness appends the typed value after the whole manifest, where `/star-flow-status 030` reproducibly missed it and reported the whole tree instead of that plan's subtree. An absent argument substitutes to empty in all three invocation paths, leaving no literal behind.
- **[v0.1.21](https://github.com/wanghao9610/STAR/tree/v0.1.21)** (2026-08-07) — Delegating stops being the exception: [§6](docs/mds/star-workflow/research-workflow-conventions.md) hands the call to the main agent, drops the flat "at most three run at once", and no longer reserves file-changing delegates to `star-plan-executor` and `star-code-architect`, while `star-flow-status` loses the roster's one outright ban on subagents. What is kept is everything that was never about caution — disjoint file ownership among concurrent delegates, the main agent re-running every check and owning every judgment, read-only delegates that write nothing, and the per-host request budget that is the real reason a fetch fan-out is bounded at all. Separately the Claude manifests gain `argument-hint` and turn-scoped `allowed-tools`, with `Write` granted beside `Edit` wherever a skill creates files instead of editing them; `allowed-tools` pre-approves and never restricts.
- **[v0.1.20](https://github.com/wanghao9610/STAR/tree/v0.1.20)** (2026-08-06) — A leaf that edits existing code can now run on its own branch, and the base branch stays canonical until the change earns its merge: conventions [§11](docs/mds/star-workflow/research-workflow-conventions.md) has the plan-approval confirmation point recommend `exec/<run>`, and choosing it chooses per-step checkpoint commits, because only commits merge. Until the merge everything the run wrote exists only on the branch, which reads from the base branch as a leaf simply not done yet, so a dependent leaf stays blocked with no new check written anywhere; the merge is a mandatory confirmation point, squash by default, and discarding commits the run records first so a dead end keeps its evidence. Around the executor, `star-code-reviewer` reviews a branch run as its `<base>...HEAD` diff, `star-expt-digest` names unmerged branches among its gaps, and `star_commit_guard.sh` gains arms for the spellings that break this in one keystroke.
- **[v0.1.19](https://github.com/wanghao9610/STAR/tree/v0.1.19)** (2026-08-06) — The Kimi tree stops naming two tools Kimi Code CLI does not have: thirty manifests called the file reader `ReadFile` and the terminal `Shell`, where that harness publishes `Read` and `Bash` — the same two words Claude uses — so forty-five of the forty-six changed lines come out byte-identical to their Claude counterparts. The rename it undoes came from [v0.1.8](https://github.com/wanghao9610/STAR/tree/v0.1.8), which swept `.kimi-code` in on suspicion rather than on Kimi's published list, the more expensive direction of that defect because it leaves behind a record saying the name was checked and nobody re-checks a checked name. Check 23 now pins, per tree, the file reader, the terminal and the `subagent_type` values each harness publishes, and `.cursor` was re-read and deliberately left alone, since Cursor documents capabilities rather than tool identifiers.
- **[v0.1.18](https://github.com/wanghao9610/STAR/tree/v0.1.18)** (2026-08-06) — A paper's architecture figure now lands in the note that reads it: `star-refs-reviewer`'s analysis note may carry one image in its Method section, identified from the captions and never from the numbering, and copied from the paper's own arXiv HTML rendering. Absence is a first-class answer whose two causes are told apart in one line — a paper that has no such figure, and one arXiv has not rendered — while a results plot promoted into the empty slot is graded a failure. What is fetched is written as fetched into `metds/refs/figs/`, with the figure number, the caption's first sentence, the image URL and the fetch date beneath it, so a figure copied out of the note can still be traced.
- **[v0.1.17](https://github.com/wanghao9610/STAR/tree/v0.1.17)** (2026-08-05) — The commit offer stops being a question you have to answer: [§7.7](docs/mds/star-workflow/research-workflow-conventions.md) no longer counts it among the mandatory confirmation points, so `medium` and `high` ask exactly as before while `low` takes it unasked, and either way the final reply names every commit made. What the confirmation actually guarded was never the commit but the staging beside it, so §1.4 gains the mechanism it always needed — a `git status` snapshot taken at the start of the run. A new hook in all four tool trees, `star_commit_guard.sh`, declines blanket or forced staging, the history rewrites §1.3 names, and any commit whose staged files exceed 10 MB.
- **[v0.1.16](https://github.com/wanghao9610/STAR/tree/v0.1.16)** (2026-08-05) — The involve gate reaches Codex: `.codex/hooks/star_involve_gate.sh` answers `PermissionRequest` — the event that fires just before the CLI waits on you — with an allow for `apply_patch` while `.env` reads `INVOLVE=low`. It is not the Claude block ported across, because Codex reports an edit as a patch envelope rather than a path field, so the paths come from its `*** Add File:` and `*** Update File:` headers and every one must sit inside the project and outside the dot-directories at its root. Two harnesses of four, by capability rather than by choice: Cursor has no hook that fires before a file edit at all, and Kimi Code's `PreToolUse` documents `deny` and no allow.
- **[v0.1.15](https://github.com/wanghao9610/STAR/tree/v0.1.15)** (2026-08-05) — `INVOLVE=low` now reaches the permission prompt, not only the questions a skill asks: `.claude/hooks/star_involve_gate.sh` answers `PreToolUse` for `Edit`, `Write` and `NotebookEdit` with an allow, while a path outside the project and every dot-directory at the project root keep their prompt and `Bash` stays out of the matcher entirely. It moves permission prompts and nothing else, which is [§7.7](docs/mds/star-workflow/research-workflow-conventions.md)'s own division carried down to the harness — the STOP line, commit offers, deletions and plan approval hold at `low` exactly as at `high`. The same release gives every `reference.bib` entry a `% src:` provenance line, puts a paper note's headline number on one self-contained line with its dataset, metric and setting, and teaches §10.6's pickup rule the mixed case.
- **[v0.1.14](https://github.com/wanghao9610/STAR/tree/v0.1.14)** (2026-08-04) — Eight of the fifteen skills may now start themselves: conventions [§10](docs/mds/star-workflow/research-workflow-conventions.md) rosters all fifteen and marks seven slash-only with †, because a decision reached on an agent's own initiative is a decision nobody made. Being picked up changes nothing about how the run then behaves — the STOP line, commit offers, deletions and overwrites, and every mandatory confirmation point hold exactly as when you type the name — and three rules bound it: an unresolved target is asked about rather than guessed, one skill per invocation, and a line in the decisions record. Permission alone moved nothing, since every contract still handed the reader a command, so §10.6 closes the gap: a run ending on one of the eight with a settled target runs it instead of printing it.
- **[v0.1.13](https://github.com/wanghao9610/STAR/tree/v0.1.13)** (2026-08-04) — Every reference entry carries an impact score: `star-refs-reviewer` composes citations per year, venue tier and code adoption into a 0–10 total by fixed weights, from metrics fetched and dated during the run — never an impression, and never a `reference.bib` field. The score decides emphasis, not membership, since "close beats famous" still picks the core set, and a new `score` mode re-fetches a whole bib's metrics in one batch so an existing base adopts the feature with one command. The same release stops the updater from ever overwriting `AGENTS.md` and the Cursor rule that mirrors it.
- **[v0.1.12](https://github.com/wanghao9610/STAR/tree/v0.1.12)** (2026-08-03) — A project keeps its own memory: what a session learns that no plan, log or report owns is recorded under `.star/memory/`, one file per fact with a one-line index beside them, and a second session hook puts that index in front of the agent at the start of every session. `AGENTS.md` gains §10 carrying the whole write rule — record only what no file in the project already owns, offer rather than assume, and let the repository win wherever a memory disagrees — which moves Verification to §11 and every citation of it across the four skill trees with it. The format and the retirement rules are [`memory_spec.md`](docs/mds/star-workflow/memory_spec.md), and facts true only of one machine go to `.star/memory/local/`, git-ignored the way `.env` is.
- **[v0.1.11](https://github.com/wanghao9610/STAR/tree/v0.1.11)** (2026-08-03) — The project points at its writing-side companion, [STAGE](https://github.com/wanghao9610/STAGE): the landing subtitle becomes "Every STAGE needs a STAR", the closing call to action gains a "Pair it with STAGE" button, and the footer a STAGE link, symmetric with the links STAGE has always kept to STAR. Both READMEs now open on the division of labor — STAR runs the research and produces the method documents, results and digests, while STAGE imports them as read-only, fingerprinted evidence and writes the paper on top, so a number in the manuscript traces back to the run that produced it. The pairing stays optional in both directions.
- **[v0.1.10](https://github.com/wanghao9610/STAR/tree/v0.1.10)** (2026-08-02) — The "change granularity" answer in `star-plan-decomposer`'s sub-plan-list confirmation gains defined behavior as a direction, asked first: *coarser* merges units sharing a category or a dependency and shows the list again, asking whether to stop rather than merging below three, while *finer* never adds a sibling and instead carries the units named too coarse into the recursion step. The updater's upstream becomes configurable, `execs/update.sh` resolving `STAR_REPOSITORY` from the environment, then `.env`, then its built-in default, so tracking a fork is one line. The update set also gains `execs/run.sh`, while the experiment scripts under `execs/scpts/` remain the project's own and are never touched.
- **[v0.1.9](https://github.com/wanghao9610/STAR/tree/v0.1.9)** (2026-08-02) — The code review moves ahead of the STOP-line command: when `star-plan-executor` stops for a heavy run, its report now names `star-code-reviewer` above the command it hands back, because a defect caught before the compute costs a review while the same defect caught after costs the compute and the re-run too. The loop back closes as well, a `CODE_REVIEW_<date>.md` whose blocker or major findings the log does not record as settled reopening the steps they land in. `star-flow-status` recommends the review in the same order, and the rubric scores a deliverable only the un-run command can produce as `pending` rather than absent.
- **[v0.1.8](https://github.com/wanghao9610/STAR/tree/v0.1.8)** (2026-08-01) — Every skill tree is checked against its own harness's published tool list and the `SKILL.md` spec, instead of against how the other trees are written: the Cursor tree regains structured questions through `AskQuestion`, and three trees stop naming tools their harness has never had. Codex has no file-reading tool at all, so its loads say so and `cat` the files into the shell call, and its selective delegation is executable — `spawn_agent` with `agent_type: explorer` for bounded read-only work, `worker` for implementation. Descriptions now fit the spec's 1024-character limit in all four trees, and the checks enforce both that limit and each harness's delegation vocabulary.
- **[v0.1.7](https://github.com/wanghao9610/STAR/tree/v0.1.7)** (2026-08-01) — The Kimi skill tree regains the mechanisms its port had flattened to prose — AskUserQuestion structured questions, plan-mode approval via `EnterPlanMode`/`ExitPlanMode`, and `Agent` subagent dispatch — with subagent types mapped to Kimi's `explore`/`coder` and `multiSelect` renamed to Kimi's `multi_select`. The legitimate adaptations stay: `/skill:` invocation, `AGENTS.md` references, Kimi model-id wording, and the `kimi -p` fallback.
- **[v0.1.6](https://github.com/wanghao9610/STAR/tree/v0.1.6)** (2026-07-30) — `star-flow-status` splits its opening load into two commands sent together — the conventions excerpts, whose size is fixed, and the collector's digest, which grows with the project's history. The two shared one result-size limit, so on a project with history the pair overran it and both were spilled to a file; split, the excerpts always arrive and only the digest can still spill.
- **[v0.1.5](https://github.com/wanghao9610/STAR/tree/v0.1.5)** (2026-07-30) — Four more skills — `star-plan-decomposer`, `star-plan-executor`, `star-plan-reviser`, `star-metd-summarize` — read the plan tree through the shared read-only collector instead of opening each plan, and a second skill in the same conversation may reuse the opening load it can still see, the collector's digest excepted. `star-plan-decomposer` renames its three decomposition axes to phase, component and experiment, each named for the unit that level holds. It recommends the experiment axis only once the code runs end to end, that axis holding experiment groups with the individual claims one digit deeper.
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
