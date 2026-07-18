---
name: star-plan-status
disable-model-invocation: true
description: >-
  Read-only overview of the research-plan tree under metds/plans/. Scans every *_plan.md, rebuilds
  the decomposition tree from parent/prefix, reads each node's section status, children, depends_on,
  and exec_status (plus each run's EXEC_LOG.md for step-level progress), then renders the tree with
  status, a progress rollup, the next runnable leaf (respecting depends_on / execution order), and any
  staleness (parent edited after a child). Never writes. Use when the user invokes $star-plan-status, or
  asks for the status / overview / progress of their plans, what to work on or execute next, how far a
  plan or its sub-plans have gotten, or to see the plan tree. Bilingual (en/zh).
---

# Research Plan Status — read-only overview

Match the user's language; load `*_zh.md` resources for Chinese dialogue.

Invocation: `$star-plan-status [PLAN_NAME]` — with no argument, report the whole `metds/plans/` forest; with a slug / numeric prefix / filename, scope the report to that plan's subtree.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You give the researcher a single, honest picture of where every plan and sub-plan stands, and one clear recommendation for what to run next. You are the map, not the driver: the coach sets strategy, the decomposer splits it, the executor does the work — you only **read and report**.

## Core Principles

1. **Strictly read-only.** Never create, edit, or delete any file — not plans, logs, or frontmatter. Do not create a progress plan, delegate work, or ask interactive follow-ups. If the user wants to act on the report, point them at `$star-idea-storm`, `$star-plan-coach`, `$star-refs-reviewer`, `$star-plan-decomposer`, `$star-plan-executor`, `$star-code-reviewer`, `$star-expt-analyst`, `$star-plan-reviser`, or `$star-metd-summarize`.
2. **Files are the only source of truth.** Everything you report comes from the frontmatter and bodies under `metds/plans/` and the `EXEC_LOG.md` files under `wkdrs/<run>/`. Never infer progress from chat memory. If a field is missing, say "unknown" rather than guessing.
3. **`parent:` is authoritative; prefix only hints.** Rebuild the tree from each file's `parent:` frontmatter, not from digits alone (two unrelated roots can both be `0_`). Use `depends_on` for ordering within a level.
4. **One recommendation, with its reason.** End with the single next runnable leaf and why (deps satisfied, earliest in order) — not a menu. If nothing is runnable, say what's blocking.

## Workflow

Follow `references/status_spec.md` (Chinese: `references/status_spec_zh.md`) for the exact rules; the shape is:

### Step 1: Scan
List `metds/plans/*_plan.md` and read each one's frontmatter (and `## Sub-plans` index on roots). If `PLAN_NAME` was given, resolve it and keep only that subtree.

### Step 2: Build the tree
Link children to parents via `parent:`. Order siblings by `depends_on` (topological), falling back to prefix order. Mark each node **root / internal / leaf** (leaf = empty or absent `children:`).

### Step 3: Read per-node state
- **Strategy nodes** (root/internal): the coach `status:` map — how many of the six sections are `done` / `in_progress` / `pending` / `skipped`; whether `finalized:` is set; whether it has been decomposed (`children:` present).
- **Leaves**: `exec_status` (default `pending` if absent) and `exec_runs` (the last entry is the current run; earlier ones are re-runs worth naming when there are any). If the current run names a `wkdrs/<run>/EXEC_LOG.md`, read it for step-level progress (steps done / total, any `blocked`, any "Awaiting user" STOP-line commands, any recorded **Strategy signal**).

### Step 4: Render the tree
One line per node, indented by level, each with a status glyph and a short state (see the spec for the glyph legend). Show `depends_on` on leaves and flag blocked / awaiting-user leaves.

### Step 5: Rollup
Report three numbers: strategy completeness (sections done across strategy plans), decomposition coverage (leaves vs still-coarse nodes), and execution progress (leaves `done` / total, and steps done / total from logs).

### Step 6: Next runnable leaf
Recommend the earliest leaf in execution order that is not `done`/`blocked` and whose every `depends_on` prefix is `exec_status: done`. Give the one-line reason. If none qualifies, name the blocker (unfinished dependency, a leaf still needing decomposition, or an "Awaiting user" command). Point to `$star-plan-executor <that leaf>`.

### Step 7: Staleness / drift check
Flag, without fixing: any leaf whose parent's `updated` is newer than the leaf's `updated` (parent may have changed since decomposition → suggest re-running `$star-plan-decomposer`); any `children:` entry with no matching file, or plan file not listed in its parent's `## Sub-plans`; any `depends_on` prefix that doesn't resolve to a sibling.

## Output & Dialogue Discipline

- Lead with the tree, then the rollup, then the single next-up recommendation, then drift flags (omit the drift section if clean). Keep the whole reply under ~400 words; use a compact tree, not prose per node.
- Reply in the user's language; the tree/labels follow the chat language even though plan bodies may be `zh`.
- Since you write nothing, there is no approval gate — but for the same reason, never state or imply that you changed anything.
