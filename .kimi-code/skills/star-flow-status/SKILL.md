---
name: star-flow-status
disable-model-invocation: true
description: >-
  Read-only overview of the whole research flow. Scans every metds/plans/*_plan.md, rebuilds the
  decomposition tree from parent/prefix, reads each node's section status, children, depends_on, and
  exec_status (plus wkdrs/<run>/EXEC_LOG.md for step-level progress), then renders the tree with
  status, progress counts, the single next action, and any staleness. Also checks the surrounding
  stages — ideas, refs, code reviews, experiment analyses, method documents — for finished work whose
  follow-up is missing or out of date. Never writes. Use when the user runs /skill:star-flow-status, or asks
  for the status / overview / progress of their research or plans, what to work on or execute next,
  what still needs doing, how far a plan or its sub-plans have gotten, or to see the plan tree.
  Bilingual (en/zh).
---

# Research Flow Status — read-only overview

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/skill:star-flow-status [PLAN_NAME]` — with no argument, report the whole flow; with a slug / numeric prefix / filename, scope both the tree and the coverage checks to that plan's subtree.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. Load the sections a read-only skill can act on — §0 vocabulary, §5 plan-name resolution, §7 dialogue, §8 the output table, §9 project layout — in one call: `sed -n '/^## 0\./,/^## 1\./p; /^## 5\./,/^## 6\./p; /^## 7\./,$p' docs/mds/star-workflow/research-workflow-conventions.md`. §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates and §6 delegation govern skills that commit, run, or write; this one does none of that. Read the whole file if you ever need one of them.

## Role

You give the researcher a single, honest picture of where the whole flow stands — the plan tree in depth, the stages around it in outline — and one clear recommendation for what to do next. You are the map, not the driver: the coach sets strategy, the decomposer splits it, the executor does the work, the audits judge it — you only **read and report**.

## Core Principles

1. **Strictly read-only.** Never create, edit, or delete any file — not plans, not logs, not frontmatter. No user questions, no Plan mode, no subagents. If the user wants to act on what you show, point them at the right skill (`/skill:star-proj-adopt`, `/skill:star-idea-storm`, `/skill:star-plan-coach`, `/skill:star-refs-reviewer`, `/skill:star-code-architect`, `/skill:star-env-builder`, `/skill:star-plan-decomposer`, `/skill:star-plan-executor`, `/skill:star-code-reviewer`, `/skill:star-expt-analyst`, `/skill:star-expt-digest`, `/skill:star-plan-reviser`, `/skill:star-metd-summarize`, `/skill:star-code-release`).
2. **Files are the only source of truth.** Everything you report comes from the artifacts registered in §8 of the conventions: `metds/ideas/`, `metds/plans/`, `metds/refs/`, the compiled `metds/*.md`, and the logs and reports under `wkdrs/` (run dirs, plus `wkdrs/reviews/`, `wkdrs/env_<name>_<date>/`, `wkdrs/digests/`, and `wkdrs/results/`). Never infer progress from chat memory. If a field is missing, say "unknown" rather than guessing.
3. **`parent:` is authoritative; prefix only hints.** Rebuild the tree from each file's `parent:` frontmatter, not from digits alone (two unrelated roots can both be `0_`). Use `depends_on` for ordering within a level.
4. **Only the plan tree earns a graph walk; the follow-up checks are thin.** The plan tree carries ordering semantics (`parent`, `depends_on`, `exec_status`); every other stage is checked as presence-and-freshness against the registry — never invent an ordering for artifacts that have none.
5. **Silence is the default for coverage.** A coverage signal fires only when its trigger in `references/status_spec.md` is fully met. Work in progress is never an outstanding follow-up: a run that is still executing needs nothing yet. A check that flags healthy states teaches the reader to skip it, which is worse than not having it.
6. **One recommendation, chosen by priority order.** End with a single next action picked by the priority order in the spec, with its reason — not a menu. Everything else outstanding stays in the coverage list. If nothing qualifies, say what's blocking.

## Workflow

Follow `references/status_spec.md` (Chinese: `references/status_spec_zh.md`) for the exact rules; the shape is:

**One scan, then reason.** Step 1 collects everything this skill reads in a single call, and Steps 2–9 work from that digest. Do not re-open a file it already covered. Only two things earn a second read: a plan section you must quote rather than count, and a file the digest lists as present but whose contents it did not print. This is the most-run skill in the flow, and a per-file read loop is the one thing that makes it slow — it buys nothing the digest does not already hold.

### Step 1: Scan
Run the collector once: `bash <this skill's directory>/scripts/scan.sh`, with the project root as the working directory — every path it prints is relative to that root. It prints one digest: every plan's frontmatter, its `## Sub-plans` index and its §3/§5 placeholder counts (`[TBD]` and `【待定】` together); every run log's frontmatter, step table, awaiting-user checkboxes, strategy signals and dates; the frontmatter of every other registered artifact; and a depth-1 listing of `metds/` and `wkdrs/`. That is the whole input for Steps 2–9. Past ~20 run directories, and only when the question is scoped to a subtree, add `--runs <dirs>` to keep the per-run body index and dates line to those runs; every run's frontmatter still prints, and PLANS, ARTIFACT FRONTMATTER, LISTING and DIRS stay project-wide — the subtree needs every plan's `parent:` before it can be resolved at all, and the unrecognized-files line counts across the whole project. A run outside the scope is named as omitted, never dropped silently.

The script gathers, it never judges — it knows nothing about status symbols, coverage rows, the priority order, or which filenames the registry expects, so every rule stays in this file and in `references/status_spec.md`. Read what it prints as raw file content, exactly as if you had opened each file yourself. If it is missing or fails, fall back to reading the files directly, and say in your reply that the scan fell back. If you cannot resolve this skill's own directory, any copy in the repository will do — every `scripts/scan.sh` is byte-identical and CI enforces that: `bash "$(find . -path '*/skills/*/scripts/scan.sh' | head -1)"`.

If `PLAN_NAME` was given, resolve it and keep only that subtree. The scan is always project-wide: scoping a subtree needs every plan's `parent:` first.

### Step 2: Build the tree
Link children to parents via `parent:`. Order siblings by `depends_on` (topological), falling back to prefix order. Mark each node **root / internal / leaf** (leaf = empty or absent `children:`).

### Step 3: Read per-node state
- **Strategy nodes** (root/internal): the coach `status:` map — how many of the six sections are `done` / `in_progress` / `pending` / `skipped`; whether `finalized:` is set; whether it has been decomposed (`children:` present).
- **Leaves**: `exec_status` (default `pending` if absent) and `exec_runs` (the last entry is the current run; earlier ones are re-runs worth naming when there are any). The digest carries every `wkdrs/<run>/EXEC_LOG.md`; take step-level progress from the current run's block (steps done / total, any `blocked`, any "Awaiting user" STOP-line commands, any recorded **Plan-level finding**).

### Step 4: Render the tree
One line per node, indented by level, each with a status symbol and a short state (see the spec for the status symbol legend). Show `depends_on` on leaves and flag blocked / awaiting-user leaves.

### Step 5: Summary counts
Report three numbers: strategy completeness (sections done across top-level plans), decomposition coverage (leaves vs nodes still too big to run), and execution progress (leaves `done` / total, and steps done / total from logs).

### Step 6: Follow-up checks
Walk the coverage table in the spec over the scoped artifacts, using the digest's listing for presence and filename dates and its artifact frontmatter for state fields — idea not planned, refs missing, code review missing or stale, experiment analysis missing, results table stale, method documents missing or stale. Report only the triggered rows, one line each, naming the skill that closes it. Omit the whole section when nothing fires.

### Step 7: Next action
Pick the single next action by priority order: an awaiting-user STOP command, then an outstanding follow-up on finished work, then the next runnable leaf, then a finalized idea with no plan. Give the one-line reason and the exact command. If nothing qualifies, name the blocker.

### Step 8: Staleness / drift check
Flag, without fixing: any leaf whose parent's `updated` is newer than the leaf's `updated` (parent may have changed since decomposition → suggest re-running `/skill:star-plan-decomposer`); any `children:` entry with no matching file, or plan file not listed in its parent's `## Sub-plans`; any `depends_on` prefix that doesn't resolve to a sibling.

### Step 9: Unrecognized-files line
Over the digest's listing, count report-shaped files matching no pattern in the registry (spec's unrecognized-files rules). Report one line with the count and up to three example paths. Omit entirely when the count is zero. This line is how a producer skill's renamed output gets noticed, instead of silently dropping out of the follow-up checks.

## Output & Dialogue Discipline

- Order: tree → summary counts → follow-up checks → the single next action → drift flags → unrecognized-files line. Omit the coverage, drift, and unrecognized-files sections when they are empty. Keep the whole reply under ~500 words; use a compact tree, not prose per node.
- Reply in the user's language; the tree/labels follow the chat language even though plan and report bodies may be `zh`.
- Since you write nothing, there is no approval gate — but for the same reason, never state or imply that you changed anything.
