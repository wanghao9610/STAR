# Research Workflow Skills Guide

**Language:** English | [简体中文](research-workflow-skills.zh-CN.md)

STAR provides four connected research workflow skills that turn a research idea into a traceable plan, executable tasks, and an implementation backed by verification records:

```text
research idea
  → rsch-plan-coach: create a strategic research plan
  → rsch-plan-decomposer: split it into execution sub-plans with dependencies
  → rsch-plan-executor: implement and verify one leaf sub-plan
  → rsch-plan-status: inspect overall progress and the next action at any time
```

The skills persist plan state in project files, so work can continue across conversations and sessions without relying on chat history for context.

## 1. Invoking the skills

This guide uses Codex syntax, where a skill is invoked with `$skill-name`:

```text
$rsch-plan-coach open-vocabulary detection and segmentation
$rsch-plan-decomposer 0_open-vocab-det-seg_plan.md
$rsch-plan-executor 00
$rsch-plan-status
```

In Claude and Cursor, use `/skill-name` instead:

```text
/rsch-plan-coach open-vocabulary detection and segmentation
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
- Before executing code, create a local `.env` and set `CODE_NAME`, `CONDA_HOME`, and `PYTHON_HOME` correctly.
- Put reusable code under `${CODE_NAME}/`, data under `datas/`, model weights under `inits/`, and generated results under `wkdrs/`.
- Both English and Chinese are supported. A skill follows the conversation language, while an existing plan continues to use the body language declared by its frontmatter `language` field.

You do not need prepared data, weights, or runnable code merely to draft or decompose a plan. Those inputs are checked during execution.

## 3. `$rsch-plan-coach`: write a research plan

### When to use it

- You have an early idea but do not yet know how to turn it into a complete research direction.
- You want to write or improve a research plan, proposal, or thesis proposal.
- You want to resume a partially written plan.
- You need to strengthen the problem, related work, method, experiments, or risk analysis.

### How to invoke it

Start a new plan:

```text
$rsch-plan-coach open-vocabulary detection and segmentation
```

Resume an existing plan:

```text
$rsch-plan-coach
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

See the complete definition in [`rsch-plan-coach/SKILL.md`](../../../.agents/skills/rsch-plan-coach/SKILL.md).

## 4. `$rsch-plan-decomposer`: create execution sub-plans

### When to use it

- The root plan already explains why and what to do, and you now need to define how to do it.
- You want to turn the method, milestones, or experiment design into executable tasks.
- An existing sub-plan is still too large and needs another level of decomposition.

### How to invoke it

```text
$rsch-plan-decomposer open-vocab-det-seg
$rsch-plan-decomposer 0
$rsch-plan-decomposer 0_open-vocab-det-seg_plan.md
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
$rsch-plan-decomposer 01
```

### Practical guidance

- If the parent method and milestones remain vague, return to `$rsch-plan-coach` first.
- Every sub-plan should have one check that clearly distinguishes success from failure. “Investigate” or “try to optimize” is not yet concrete enough.
- Do not manually renumber existing prefixes; that can break deeper plans and dependency references.

See the complete definition in [`rsch-plan-decomposer/SKILL.md`](../../../.agents/skills/rsch-plan-decomposer/SKILL.md).

## 5. `$rsch-plan-executor`: execute one leaf plan

### When to use it

- A sub-plan has a concrete task breakdown and done-criterion and is ready for implementation.
- You want to resume an interrupted execution.
- You want to turn a plan into code, light validation, and an auditable execution record.

### How to invoke it

```text
$rsch-plan-executor 00
$rsch-plan-executor mvp-3way-ablation
$rsch-plan-executor 00_mvp-3way-ablation_plan.md
```

Only a **leaf plan** is executable. If the target still has `children`, the skill asks you to choose one of its leaves or recommends further decomposition.

### Readiness checks

The skill first verifies that:

- Section 3 contains concrete tasks;
- Section 5 defines a runnable done-criterion;
- Every upstream plan in `depends_on` is complete;
- Required data, weights, and code modules exist;
- The project paths and Conda environment in `.env` are usable.

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

- `EXEC_PLAN.md` records actions, files, commands, artifacts, checks, and the STOP line;
- `EXEC_LOG.md` records step status, verification evidence, blockers, and commands awaiting the user;
- The plan file receives only the lightweight `exec_status`, `exec_run`, and `updated` fields.

When the same plan is invoked again, the skill treats `EXEC_LOG.md` as the source of truth, skips completed steps, and resumes from the first unfinished action.

See the complete definition in [`rsch-plan-executor/SKILL.md`](../../../.agents/skills/rsch-plan-executor/SKILL.md).

## 6. `$rsch-plan-status`: inspect the plan tree

### When to use it

- You want to know how far the overall research plan has progressed.
- You are unsure which sub-plan should be decomposed or executed next.
- You want to inspect dependencies, blockers, commands awaiting the user, or stale plans.
- You need a quick context refresh at the beginning of a new session.

### How to invoke it

Inspect all plans:

```text
$rsch-plan-status
```

Inspect one plan subtree:

```text
$rsch-plan-status open-vocab-det-seg
$rsch-plan-status 01
```

### What it reports

- A plan tree annotated with status;
- Strategy-section completeness, decomposition coverage, and leaf execution progress;
- Each leaf's dependencies, logged step progress, blockers, or commands awaiting the user;
- Exactly one recommended next runnable leaf, with a reason;
- Drift such as a child older than its parent, dangling links, invalid dependencies, or orphaned runs.

This skill is **strictly read-only**. It scans `metds/plans/` and `wkdrs/<run>/EXEC_LOG.md` without creating or modifying any file.

See the complete definition in [`rsch-plan-status/SKILL.md`](../../../.agents/skills/rsch-plan-status/SKILL.md).

## 7. End-to-end example

The following sequence illustrates a typical workflow.

### Step 1: turn an idea into a plan

```text
$rsch-plan-coach I want to study more reliable text-description generation for open-vocabulary detection and segmentation
```

After the staged discussion, this may produce:

```text
metds/plans/0_open-vocab-det-seg_plan.md
```

### Step 2: split it into execution units

```text
$rsch-plan-decomposer open-vocab-det-seg
```

After confirming milestone-based decomposition, the skill may produce:

```text
00_mvp-3way-ablation_plan.md
01_core-method-pipeline_plan.md
02_full-experiments_plan.md
03_writing-submission_plan.md
```

### Step 3: identify the next task

```text
$rsch-plan-status open-vocab-det-seg
```

If the report recommends `00_mvp-3way-ablation`, run:

```text
$rsch-plan-executor 00_mvp-3way-ablation_plan.md
```

### Step 4: resume after the STOP line

If the log contains a training command that the user must run:

1. Run the command recorded in `wkdrs/00_mvp-3way-ablation/EXEC_LOG.md`;
2. Confirm that its artifacts were written to the recorded paths;
3. Invoke `$rsch-plan-executor 00` again;
4. The skill reads the existing log and resumes at done-criterion verification.

### Step 5: repeat

After each leaf is complete, run:

```text
$rsch-plan-status
```

Follow its single next-step recommendation until all leaves are complete. If a result invalidates a key assumption in the parent plan, return to `$rsch-plan-coach` to revise the strategy or use `$rsch-plan-decomposer` to adjust the execution structure.

## 8. Frequently asked questions

### Which skill should I use first?

| Current situation | Use |
| --- | --- |
| You only have an idea and the research question is still unclear | `$rsch-plan-coach` |
| You have a strategic plan and need executable tasks | `$rsch-plan-decomposer` |
| You have a concrete leaf task and need code plus verification | `$rsch-plan-executor` |
| You do not know the current status or next action | `$rsch-plan-status` |

### Why will the executor not run the plan I selected?

The usual causes are that the target is not a leaf, an entry in `depends_on` is unfinished, or the task breakdown/done-criterion still contains too many `[TBD]` items. Running `$rsch-plan-status` first usually reveals the exact reason.

### Why was a training command recorded instead of executed?

Full training, full-dataset evaluation, and high-cost calls cross the STOP line. The skill makes the command and output paths reproducible, while leaving the decision about when to consume those resources to the user.

### How do I continue across sessions?

- The coach resumes from section statuses in the plan frontmatter;
- The decomposer resumes from parent-child links and existing sub-plans;
- The executor resumes from the `EXEC_LOG.md` referenced by `exec_run`;
- The status skill can reconstruct the global state read-only at any time.

### Can I edit plan files manually?

Yes, but keep the frontmatter consistent with the body, especially `parent`, `children`, `depends_on`, `status`, `exec_status`, and `exec_run`. After changing a parent plan, run `$rsch-plan-status` to check for drift before deciding whether to decompose it again.

## 9. Skill locations

Each tool has an adapted, authoritative copy of the skills. Do not mix tool-specific invocation or control instructions across these roots:

| Tool | Authoritative directory | Invocation form |
| --- | --- | --- |
| Codex | `.agents/skills/` | `$rsch-plan-*` |
| Claude | `.claude/skills/` | `/rsch-plan-*` |
| Cursor | `.cursor/skills/` | `/rsch-plan-*` |

The four skill directory names are:

```text
rsch-plan-coach
rsch-plan-decomposer
rsch-plan-executor
rsch-plan-status
```
