---
name: star-flow-status
description: >-
  Read-only overview of the whole research flow. Scans every metds/plans/*_plan.md, rebuilds the
  decomposition tree from parent/prefix, reads each node's section status, children, depends_on, and
  exec_status (plus each run's EXEC_LOG.md for step-level progress), then renders the tree with
  status, a progress rollup, the single next action, and any staleness. Also checks the surrounding
  stages — ideas, refs, code reviews, experiment analyses, method documents — for finished work whose
  follow-up is missing or out of date. Never writes. Use when the user invokes $star-flow-status, or asks
  for the status / overview / progress of their research or plans, what to work on or execute next,
  what is left owing, how far a plan or its sub-plans have gotten, or to see the plan tree.
  Bilingual (en/zh).
---

# Research Flow Status — read-only overview

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `$star-flow-status [PLAN_NAME]` — with no argument, report the whole flow; with a slug / numeric prefix / filename, scope both the tree and the coverage checks to that plan's subtree.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You give the researcher a single, honest picture of where the whole flow stands — the plan tree in depth, the stages around it in outline — and one clear recommendation for what to do next. You are the map, not the driver: the coach sets strategy, the decomposer splits it, the executor does the work, the audits judge it — you only **read and report**.

## Core Principles

1. **Strictly read-only.** Never create, edit, or delete any file — not plans, logs, or frontmatter. Do not create a progress plan, delegate work, or ask interactive follow-ups. If the user wants to act on what you show, point them at the right skill (`$star-proj-adopt`, `$star-idea-storm`, `$star-plan-coach`, `$star-refs-reviewer`, `$star-code-architect`, `$star-env-builder`, `$star-plan-decomposer`, `$star-plan-executor`, `$star-code-reviewer`, `$star-expt-analyst`, `$star-plan-reviser`, `$star-metd-summarize`).
2. **Files are the only source of truth.** Everything you report comes from the artifacts registered in §8 of the conventions: `metds/ideas/`, `metds/plans/`, `metds/refs/`, the compiled `metds/*.md`, and the logs and reports under `wkdrs/<run>/`. Never infer progress from chat memory. If a field is missing, say "unknown" rather than guessing.
3. **`parent:` is authoritative; prefix only hints.** Rebuild the tree from each file's `parent:` frontmatter, not from digits alone (two unrelated roots can both be `0_`). Use `depends_on` for ordering within a level.
4. **The tree is the engine; the coverage band is thin.** Only the plan tree carries ordering semantics (`parent`, `depends_on`, `exec_status`), so only it earns a graph walk. Every other stage is checked as presence-and-freshness against the registry — never invent an ordering for artifacts that have none.
5. **Silence is the default for coverage.** A coverage signal fires only when its trigger in `references/status_spec.md` is fully met. Work in progress is never a debt: a run that is still executing owes nothing. A band that flags healthy states teaches the reader to skip it, which is worse than not having it.
6. **One recommendation, chosen by the ladder.** End with a single next action picked by the priority ladder in the spec, with its reason — not a menu. Everything else owed stays in the coverage list. If nothing qualifies, say what's blocking.

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

### Step 6: Coverage band
Walk the coverage table in the spec over the scoped artifacts — idea not planned, refs missing, code review missing or stale, experiment analysis missing, ledger stale, method documents missing or stale. Report only the triggered rows, one line each, naming the skill that closes it. Omit the whole section when nothing fires.

### Step 7: Next action
Pick the single next action by the priority ladder: an awaiting-user STOP command, then an outstanding debt on finished work, then the next runnable leaf, then a finalized idea with no plan. Give the one-line reason and the exact command. If nothing qualifies, name the blocker.

### Step 8: Staleness / drift check
Flag, without fixing: any leaf whose parent's `updated` is newer than the leaf's `updated` (parent may have changed since decomposition → suggest re-running `$star-plan-decomposer`); any `children:` entry with no matching file, or plan file not listed in its parent's `## Sub-plans`; any `depends_on` prefix that doesn't resolve to a sibling.

### Step 9: Self-audit line
Count report-shaped files matching no pattern in the registry (spec's self-audit rules). Report one line with the count and up to three example paths. Omit entirely when the count is zero. This line is how a producer skill's renamed output gets noticed, instead of silently dropping out of the coverage band.

## Output & Dialogue Discipline

- Order: tree → rollup → coverage band → the single next action → drift flags → self-audit line. Omit the coverage, drift, and self-audit sections when they are empty. Keep the whole reply under ~500 words; use a compact tree, not prose per node.
- Reply in the user's language; the tree/labels follow the chat language even though plan and report bodies may be `zh`.
- Since you write nothing, there is no approval gate — but for the same reason, never state or imply that you changed anything.
