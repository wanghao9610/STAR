# Research Workflow Skill Conventions

**Language:** English | [简体中文](research-workflow-conventions.zh-CN.md)

The rules every STAR research workflow skill follows. The twelve skills — `star-idea-storm`, `star-plan-coach`, `star-refs-reviewer`, `star-code-architect`, `star-env-builder`, `star-plan-decomposer`, `star-plan-executor`, `star-code-reviewer`, `star-expt-analyst`, `star-plan-reviser`, `star-flow-status`, `star-metd-summarize` — each carry their own workflow, write boundary, and rubric. What they share lives here, once.

**Precedence.** This file is the **baseline**. A skill's `SKILL.md` may be **stricter** — a narrower write boundary, a lower threshold, an extra gate, a rule that it never commits at all — and the stricter rule wins. A skill never loosens what this file sets. Where a `SKILL.md` carries a one-line summary of a rule below, that line is the binding reminder and this file is the full rule.

This file is a contract for the skills and a description for the reader: it is what the workflow will and will not do to your repository.

## 1. Git

**Skills that never commit** — git usage is read-only (`status` / `diff` / `log`): `star-flow-status`, `star-refs-reviewer`, `star-expt-analyst`, `star-metd-summarize`.

**Skills that may commit**, and what each may stage:

| Skill | Commits | Stages |
| --- | --- | --- |
| `star-idea-storm` | offered once when the session ends | the idea file this session created or edited |
| `star-plan-coach` | offered once when the session ends | the plan files this session created or edited |
| `star-plan-decomposer` | offered once at the end of the run | the sub-plans written plus the parent's updated index |
| `star-plan-reviser` | offered once at Step 7, when edits were applied | the target plan, plus the parent when its `## Sub-plans` line changed |
| `star-code-architect` | one per landed phase or verified migration group | `${CODE_NAME}/` and the spec files it owns |
| `star-env-builder` | at most one per run | `${CODE_NAME}/requirements*` only |
| `star-plan-executor` | one per verified action, only when the gate approved checkpointing | the files that action touched |
| `star-code-reviewer` | one optional commit after the fix pass | only the files the fix pass touched |

**Universal rules:**

1. **Stage only what this run created or edited.** Never `git add -A`, never `git add .`. In a research repository a blanket add sweeps in checkpoints, datasets, and scratch.
2. **The message prefix is the skill's own name**: `star-plan-executor: <run> step 2 — <summary>`, `star-plan-coach: <slug> — <milestone>`. One skill, one namespace in the log.
3. **No pushes, no history rewrites** (`rebase`, `amend`, `reset --hard`), **no branch switches, no tag creation.** The user owns the branch and the remote.
4. **A path that already carried uncommitted changes when the run started is never staged.** Name those paths when asking, so the user can commit or stash them first — a skill's commit must never bundle work it did not do.
5. **Never commit silently.** Every commit is either covered by a gate the user approved or offered as its own question. Declining is always a valid answer.
6. **Never force-add an ignored path.** `.env`, `datas/`, `inits/`, and `wkdrs/` are git-ignored by default; they stay out of history. (`tasks/` is currently tracked — see `AGENTS.md` §5.)

**Why it matters.** `star-plan-reviser` tells users that "older versions live in git"; that is only true if the plan writers actually offer the commits. And a single stray `git add -A` in a project holding `inits/` and `wkdrs/` is the difference between a 40 KB diff and a 40 GB one.

## 2. The STOP line

Skills may write code and run **light validation**. Anything **heavy, costly, or irreversible** crosses the STOP line: prepare the exact command, hand it to the user, and stop. Never launch it autonomously — no matter how confident the skill is, and no matter that a gate approved the surrounding work.

**Light — a skill may run it:**

- Unit and smoke tests, import checks, `python -m compileall`, a forward pass on a tiny batch.
- Small-scale, **no-finetune** inference on a small subset — e.g. an MVP done-criterion: "no training, small subset, swap the text input and compare".
- Dry runs, config validation, shape/dtype checks, a few-step overfit sanity run.
- Anything that finishes in **minutes on modest resources** and writes only where the skill's write boundary allows.

**Crosses the STOP line — hand it to the user:**

- **Long or multi-GPU training or fine-tuning** — any full training run.
- **Full-dataset evaluation** that takes hours or significant compute.
- **Costly API calls** — large-volume LLM/VLM inference billed per call.
- **`sudo` or a system package manager** (apt, brew), driver or CUDA-toolkit system installs, and **CUDA source compilation** (flash-attn-style builds).
- **Deleting any environment**, and overwriting artifacts the user may want to keep.
- Anything whose cost or runtime **cannot be bounded**. When unsure, it is STOP.

Download-size thresholds are **skill-specific** — `star-env-builder` runs framework-scale downloads once its install plan is approved; `star-code-architect` hands anything over ~1 GB back. Each skill states its own; this list is what crosses regardless.

**How to hand off.** Give the user the exact command, invoked through the `.env` environment (§3) and the project's run surface (`execs/run.sh`) where one exists; say what it produces and where; say what output to bring back so the criterion can be verified. Writing the command into a runnable script is light; running it is not.

## 3. `.env` and the project runtime

The operational form of `AGENTS.md` §6.

1. **`.env` at the project root is the only source** of `CODE_NAME`, `ENV_NAME`, `CONDA_HOME`, and `PYTHON_HOME`. Never guess a local path, never hardcode one, never read them from memory of another project.
2. **`PYTHON_HOME` is authoritative.** Set → use it as given; `CONDA_HOME` and `ENV_NAME` may be empty, and the interpreter then runs directly rather than through conda. Empty → derive it as `$CONDA_HOME/envs/$ENV_NAME`, which requires both to be set. Neither → a blocker to report, not a value to invent.
3. **Missing `.env`** → create it from `.env.example`, ask the user to fill the machine-specific values, and stop until they do. Never invent a value to keep going.
4. **The shell is stateless.** `source activate` does not survive to the next command. Resolve the interpreter once to an absolute path — `$PYTHON_HOME/bin/python`, from §3.2 — and run every command through it. Never system python.
5. **Only `star-env-builder` creates, repairs, or modifies an environment.** No other skill installs or upgrades anything, ever. A tool that is absent (ruff, matplotlib, bibtexparser, pandas) is a **degraded check**: run without it, say so in the report, and route to `star-env-builder`. Installing it to finish your own check is out of bounds.
6. An environment that cannot run python is a **blocker to report**, not a problem to work around.

## 4. Real dates

1. **Every date written into a file comes from the system clock at run time** (`date +%Y-%m-%d`). Never recall a date, never infer one from context, never copy the one in a template or an example.
2. A **fetch date** is the day the fetch happened. A **report date** is the day the report was written. A **backup stamp** is the day the backup was made.
3. A dated file re-generated **the same day** overwrites that day's file; **on a later day** it writes its own. This is what makes a run directory readable as a timeline.

## 5. Plan-name resolution

1. **`PLAN_NAME` matches `metds/plans/*_plan.md`** by slug (`open-vocab-det-seg`), by numeric prefix (`00`), or by full filename; a `metds/plans/…` path counts.
2. **Absent or ambiguous → list the nearest candidates** (prefix + slug + one-line state) and ask one direct question. Never guess which plan was meant.
3. **`parent:` is authoritative; the prefix only hints.** Rebuild the tree from each file's `parent:` frontmatter. The numeric prefix orders and hints the tree for humans — and in projects created before roots took the smallest free digit, two unrelated roots can share a digit.
4. **A leaf is a plan with empty or absent `children:`.** Only leaves are executable.
5. **`depends_on` holds sibling prefixes** and is the machine-readable execution order the executor and `star-flow-status` consume. It stays acyclic and consistent with the parent's `## Sub-plans` index.
6. **Never renumber a prefix.** Every deeper prefix and every `parent:` / `traces_to` reference is built on it.

## 6. Delegation

1. **Execute locally by default.** Delegate only work that is bounded, independent, and materially helped by delegation. Never create one delegate per trivial sequential step.
2. **A delegate is given** its exact file list, the rubric or contract it must return, and its scope stated verbatim ("ONLY these items"). Concurrent delegates hold **disjoint file ownership**.
3. **The main agent owns integration and judgment.** It re-runs every check itself and never trusts a self-reported pass. A delegate never grades the overall verdict.
4. **A collector delegate** — the common case, reading logs, papers, packages, or plans — reads and returns a filled contract. It writes no files and reads nothing outside its list.
5. **Only `star-plan-executor` dispatches an implementing delegate** that may change files; that contract is its own `references/agent_dispatch_spec.md`.

## 7. Dialogue

The tool-neutral half. **How** to ask — AskUserQuestion, Codex's structured user-input tool, or plain text — is platform-specific and stays in each `SKILL.md`.

1. **Keep each chat reply under about 400 words.** Files written to disk do not count. Detail belongs in the artifact; the reply is the digest.
2. **Ask one question at a time and wait for an explicit answer** before acting on it. Never bundle-approve, never assume a yes. **This holds in headless and scripted runs**: a skill that reaches a gate stops and waits rather than proceeding — see the guide's "Which parts can run unattended?".
3. **Every question carries 2–4 concrete options with the recommendation marked**, and the user may always answer freely outside them. Genuinely open questions (an initial research topic) may be asked without options.
4. **Report honestly.** Never round a shortfall up. Never present a check as run when it was skipped or degraded. Never state or imply that a file, a status, or a plan was changed when it was not.
5. **Lead with the outcome**, then the evidence, then the routing to the next skill.
6. **Reply in the user's dialogue language.** A document's body language follows its own frontmatter `language` (or its source's), **not** the chat's — a Chinese conversation about an English plan still writes English into that plan. Inside Chinese documents keep technical terms, metric names, venue names, file paths, and everything inside `reference.bib` in English.

## 8. The artifact registry

Every skill's durable output, in one table. `star-flow-status` reads this as the contract for its coverage checks: a stage is "covered" when the artifact below exists and its state field is current. Keep the table honest — a skill that changes what it writes updates this row in the same commit, or the status skill silently stops checking that stage.

| Stage | Producer | Path | State field |
|---|---|---|---|
| Idea | `star-idea-storm` | `metds/ideas/<slug>_idea.md` | `finalized:` |
| Refs | `star-refs-reviewer` | `metds/refs/refs_index.md`, `<ABBREV>.md`, `reference.bib`, `related_work.md` | index presence |
| Codebase | `star-code-architect` | `metds/codearc.md` | presence |
| Env | `star-env-builder` | `wkdrs/env_<name>_<date>/ENV_REPORT.md`, `freeze.txt` | date in dir name |
| Plan | `star-plan-coach`, `star-plan-decomposer`, `star-plan-reviser` | `metds/plans/<prefix>_<slug>_plan.md` | `status:`, `finalized:`, `updated:` |
| Run | `star-plan-executor` | `wkdrs/<run>/EXEC_PLAN.md`, `EXEC_LOG.md` | plan `exec_status:`, `exec_runs:` |
| Code review | `star-code-reviewer` | `wkdrs/<run>/CODE_REVIEW_<date>.md`, else `wkdrs/reviews/code_<scope>_<date>.md` | date in filename |
| Analysis | `star-expt-analyst` | `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`, `wkdrs/<run>/analysis/` | date in filename |
| Ledger | `star-expt-analyst aggregate` | `metds/results.md` | `generated:` |
| Method docs | `star-metd-summarize` | `metds/{overview,framework,dataset,training,evaluation}.md` | `generated:`, `sources:` |

Two properties of this table matter more than its contents:

1. **`sources:` on a compiled document records each source plan's `updated` as it was when read.** That is what makes staleness detectable by exact comparison rather than by file mtime, which moves for unrelated reasons.
2. **Nothing enforces this table.** `star-flow-status` ends its report with a count of report-shaped files matching no row here, which turns a drifted convention into a visible line rather than a silent under-report.
