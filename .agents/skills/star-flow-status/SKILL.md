---
name: star-flow-status
description: >-
  Show research status: the plan tree, progress, and what to work on or execute next. Read-only
  overview of the whole flow — scans every metds/plans/*_plan.md, rebuilds the decomposition tree from
  parent/prefix, reads each node's section status, children, depends_on, and exec_status (plus each
  run's EXEC_LOG.md for step-level progress), then renders the tree with status, progress counts, the
  single next action, and any staleness. Also checks the surrounding stages — ideas, refs, code
  reviews, experiment analyses, method documents — for finished work whose follow-up is missing or out
  of date. Never writes. Use when the user invokes $star-flow-status, when a run names it as the next
  action, or asks what still needs doing, how far a plan or its sub-plans have gotten, or to see the
  plan tree. Bilingual (en/zh).
---

# Research Flow Status — read-only overview

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `$star-flow-status [PLAN_NAME] [DESCRIPTION]` — with no argument, report the whole flow; with a slug / numeric prefix / filename, scope both the tree and the coverage checks to that plan's subtree. An `involve=<level>` token is stripped from the invocation before `PLAN_NAME` is resolved (conventions §7.7); it changes nothing else here — this skill asks no questions. Anything left after `PLAN_NAME` is a description (conventions §7.12): in your own words, what this run is for. Prose that resolves to no plan is description alone, not a missing target — report the whole flow, and say so in the reply's first line. A lone token that looks like a plan name and matches none is not a description: name it as unmatched in that same line, since this skill never asks. A description can steer what the report looks at hardest; it drops nothing the report owes.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What a read-only reporter acts on — §0 vocabulary, §5 plan-name resolution (only when there is a `PLAN_NAME` to resolve), §7's reporting rules (its preamble and items 1, 4, 5, 6, 11, 12; the question machinery in items 2–3 and 7–10 governs skills that ask, and this one never asks), §9 project layout, and §10 the skill roster (this one is among the eight the agent may start unnamed; §10 is what bounds such a run) — arrives through Step 1's one load message. §8 (the output table) is the registry the coverage checks audit against, cited but not loaded: the spec restates every filename and state field those checks read, and the rest of §8 — `model_id` / `model_trail` — governs producers, which this skill is not. §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates and §6 delegation govern skills that commit, run, or write; this one does none of that. Of §11's execution branches it needs only the listing Step 1's scan call carries and the reading rules the spec restates — the section itself stays with the skills that branch. Read the whole file if you ever need one of them.

**Reusing an earlier load.** A second STAR skill in the same conversation does not pay for this twice. Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the probe's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again — a wasted read costs one message, a wrong assumption costs the run. What never carries over is a collector digest, where one is loaded above: it is a snapshot of files a skill run may have written to since, so the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

You give the researcher a single, honest picture of where the whole flow stands — the plan tree in depth, the stages around it in outline — and one clear recommendation for what to do next. You are the map, not the driver: the coach sets strategy, the decomposer splits it, the executor does the work, the audits judge it — you only **read and report**.

## Core Principles

1. **Strictly read-only.** Never create, edit, or delete any file — not plans, logs, or frontmatter. No `update_plan`, no `request_user_input`. If the user wants to act on what you show, point them at the right skill (`$star-proj-adopt`, `$star-idea-storm`, `$star-plan-coach`, `$star-refs-reviewer`, `$star-code-architect`, `$star-env-builder`, `$star-plan-decomposer`, `$star-plan-executor`, `$star-code-reviewer`, `$star-expt-analyst`, `$star-expt-digest`, `$star-plan-reviser`, `$star-metd-summarize`, `$star-code-release`).
2. **Files are the only source of truth.** Everything you report comes from the artifacts registered in §8 of the conventions: `metds/ideas/`, `metds/plans/`, `metds/refs/`, the compiled `metds/*.md`, and the logs and reports under `wkdrs/` (run dirs, plus `wkdrs/reviews/`, `wkdrs/env_<name>_<date>/`, `wkdrs/digests/`, and `wkdrs/results/`). Never infer progress from chat memory. If a field is missing, say "unknown" rather than guessing.
3. **`parent:` is authoritative; prefix only hints.** Rebuild the tree from each file's `parent:` frontmatter, not from digits alone (two unrelated roots can both be `0_`). Use `depends_on` for ordering within a level.
4. **Only the plan tree earns a graph walk; the follow-up checks are thin.** The plan tree carries ordering semantics (`parent`, `depends_on`, `exec_status`); every other stage is checked as presence-and-freshness against the registry — never invent an ordering for artifacts that have none.
5. **Silence is the default for coverage.** A coverage signal fires only when its trigger in `references/status_spec.md` is fully met. Work in progress is never an outstanding follow-up: a run that is still executing needs nothing yet. A check that flags healthy states teaches the reader to skip it, which is worse than not having it.
6. **One recommendation, chosen by priority order.** End with a single next action picked by the priority order in the spec, with its reason — not a menu. Everything else outstanding stays in the coverage list. If nothing qualifies, say what's blocking.

## Workflow

Follow `references/status_spec.md` (Chinese: `references/status_spec_zh.md`) for the exact rules — Step 1's message loads it; the shape is:

**One scan, then reason.** Step 1 collects everything this skill reads — the conventions sections, the spec, and the file digest — in a single message, and Steps 2–9 work from what it returned. Do not re-open a file it already covered. Only two things earn a second read: a plan section you must quote rather than count, and a file the digest lists as present but whose contents it did not print. This is the most-run skill in the flow, and extra round trips are what make it slow — a per-file read loop, or the load itself spread over separate messages; neither buys anything that one message does not already hold.

### Step 1: Scan
Load everything in one message — two shell calls, both with the project root as the working directory, plus a read of the spec issued alongside them. First call, the conventions excerpts:

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
git branch --list '[0-9]*_*' 2>/dev/null   # execution branches — runs whose work is not on the base branch yet
git worktree list --porcelain 2>/dev/null   # worktrees — where housed runs live (conventions §11.7)
sed -n '/^## 0\./,/^## 1\./p; /^## 5\./,/^## 6\./p' docs/mds/star-workflow/research-workflow-conventions.md
awk '/^## 7\./{s=1;n=0} /^## 8\./{s=0} s{if($0~/^[0-9]+\. /)n=int($0); if(n==0||n==1||n==4||n==5||n==6||n==11||n==12)print}' docs/mds/star-workflow/research-workflow-conventions.md
awk '/^## 9\./{k=1} /^## 11\./{k=0} k' docs/mds/star-workflow/research-workflow-conventions.md
```

Second call, the digest:

```bash
bash <this skill's directory>/scripts/scan.sh --slim
```

One message, three results: the conventions excerpts and the collector's digest from the two shell calls, and the spec — `<this skill's directory>/references/status_spec.md` — from a separate file read sent in the same message. Several tool calls in one message cost one round trip between them, not one each; only a second message costs another. That is why the two commands stay separate instead of being joined: each tool result has its own size limit, and a shell result past roughly 30 KB is spilled to a file that costs a round trip to read back — exactly the round trip the one message exists to avoid. Joined, the excerpts and the digest share one limit, and on a project with history the pair overruns it and both are lost; separate, the excerpts are a fixed size and always arrive, and only the digest — the one part that grows with the history — can ever spill. Keep the spec out of both commands for the same reason: it is another whole file, big enough to crowd either result toward the spill line. If this harness has no file-reading tool of its own, put `cat <this skill's directory>/references/status_spec.md` back as a fifth line of the first command and accept the spill. With no `PLAN_NAME` argument drop the `'/^## 5\./,/^## 6\./p'` range — §5 exists to resolve one. The awk selects §7 by item number (the preamble plus items 1, 4, 5, 6, 11, 12); if it prints nothing — a stale synced copy of the conventions may number differently — load the whole section with `sed -n '/^## 7\./,/^## 8\./p'` instead. The last awk prints §9 and §10 and stops at the `## 11.` heading: §11, the execution branches, is deliberately not loaded — the `git branch` and `git worktree` lines above carry the live listings, and the spec restates how an execution branch and its worktree read — and a section appended after it still does not ride in unread. Every path the digest prints is relative to the project root. The digest part is: every plan's frontmatter, its `## Sub-plans` index and its §3/§5 placeholder counts (`[TBD]` and `【待定】` together); every run log's frontmatter, its body counted per heading, and the dates it carries; the frontmatter of every registered artifact outside a run directory; and a depth-1 listing of `metds/` and `wkdrs/`. Together with the spec and the conventions sections, that is the whole input for Steps 2–9.

`--slim` is what keeps this affordable once a project has history: it collapses the two parts of the digest that grow with the history rather than with the plan tree, and on a 40-run project it cuts the digest by about a third. A step table of more than six rows arrives as its header row, `[tally] N data rows`, and a value histogram per column — read `c3: done×7, blocked×1` as the step counts Step 3 needs, and a column given as `N distinct` is a step name or a date, never a status. Six rows or fewer arrive unchanged. Un-ticked checkboxes and plan-level findings are never summarised, so an awaiting-user leaf still shows its exact command. An artifact inside a run directory prints no frontmatter, because LISTING already carries its name and the date in it — which is all the follow-up checks read — and the count of those left out is printed. Drop `--slim` only to read one run's steps line by line, and pair that with `--runs <that run>`.

`--slim` makes this rarely necessary, but on a very long history you can narrow further, and only when the question is scoped to a subtree: `--runs <dirs>` keeps the per-run body and dates line to those runs. Every run's frontmatter still prints, and PLANS, LISTING and DIRS stay project-wide — the subtree needs every plan's `parent:` before it can be resolved at all, and the unrecognized-files line counts across the whole project. A run outside the scope is named as omitted, never dropped silently.

The script gathers, it never judges — it knows nothing about status symbols, coverage rows, the priority order, or which filenames the registry expects, so every rule stays in this file and in `references/status_spec.md`. Read what it prints as raw file content, exactly as if you had opened each file yourself. If it is missing or fails, fall back to reading the files directly, and say in your reply that the scan fell back. If you cannot resolve this skill's own directory, any copy in the repository will do — every `scripts/scan.sh` is byte-identical and CI enforces that: `bash "$(find . -path '*/skills/*/scripts/scan.sh' | head -1)"`.

If `PLAN_NAME` was given, resolve it and keep only the resolved node and its descendants — every step below reports that subtree and nothing else. The scan is always project-wide: scoping a subtree needs every plan's `parent:` first, so a plan outside the subtree is read to resolve the tree and then dropped, never rendered. The resolution rules, including what an ambiguous name does here where there is no question to fall back on, are in the spec's Scope section.

### Step 2: Build the tree
Link children to parents via `parent:` over **every** plan the scan returned — resolving a parent needs all of them. Order siblings by `depends_on` (topological), falling back to prefix order. Mark each node **root / internal / leaf** (leaf = empty or absent `children:`). Then, if `PLAN_NAME` was given, drop everything outside the resolved node's subtree: Steps 4–7 see only what is left.

### Step 3: Read per-node state
- **Strategy nodes** (root/internal): the coach `status:` map — how many of the six sections are `done` / `in_progress` / `pending` / `skipped`; whether `finalized:` is set; whether it has been decomposed (`children:` present).
- **Leaves**: `exec_status` (default `pending` if absent) and `exec_runs` (the last entry is the current run; earlier ones are re-runs worth naming when there are any). The digest carries every `wkdrs/<run>/EXEC_LOG.md`; take step-level progress from the current run's block (steps done / total, any `blocked`, any "Awaiting user" STOP-line commands, any recorded **Plan-level finding**), and its frontmatter's `branch:` / `merged:` / `worktree:` with it — the spec says how an unmerged execution branch and a housed run render and when the merge becomes the outstanding follow-up.
- **Any node**: `dropped:` — carried by this node, or inherited from any ancestor. It renders `⊗` and takes the node and its whole subtree out of the counts, the follow-up checks and the next action; the spec's legend has the exact rules.

### Step 4: Render the tree
One line per node — **every node in scope, no exceptions** — indented by level, each with a status symbol and a short state (see the spec for the status symbol legend). Show `depends_on` on leaves and flag blocked / awaiting-user leaves. A large tree shortens the state text on a line, never drops the line: collapsing a subtree into a sentence is the one thing this step must not do, because Step 5's counts are already the short version and the tree is the only place the reader sees which node is which.

### Step 5: Summary counts
Report three numbers **over the scope**: strategy completeness (sections done across the top-level plans in scope), decomposition coverage (leaves vs nodes still too big to run), and execution progress (leaves `done` / total, and steps done / total from logs). When a `PLAN_NAME` narrowed the run, say so in one clause, so the numbers are not read as the project's. Dropped nodes and their subtrees are outside all three, denominators included — report them as one line beneath the counts.

### Step 6: Follow-up checks
Walk the coverage table in the spec over the scoped artifacts, using the digest's listing for presence and filename dates and its artifact frontmatter for state fields — idea not planned, refs missing, code review missing or stale, experiment analysis missing, results table stale, method documents missing or stale. Report only the triggered rows, one line each, naming the skill that closes it. Omit the whole section when nothing fires.

### Step 7: Next action
Pick the single next action by priority order: an awaiting-user STOP command — preceded by `$star-code-reviewer <leaf>` when that run holds no review yet — then an outstanding follow-up on finished work, then the next runnable leaf, then a finalized idea with no plan. Give the one-line reason and the exact command. Judge each named command on its own, the review-above-awaiting-command pair included: one that names one of the eight the agent may start (conventions §10) with a settled target is picked up after this run ends rather than left for the user to type, while a STOP command beside it stays printed and the user's. This skill starts nothing itself. If nothing qualifies, name the blocker.

### Step 8: Staleness / drift check
Flag, without fixing: any leaf whose parent's `updated` is newer than the leaf's `updated` (parent may have changed since decomposition → suggest re-running `$star-plan-decomposer`); any `children:` entry with no matching file, or plan file not listed in its parent's `## Sub-plans`; any `depends_on` prefix that doesn't resolve to a sibling, or that resolves to a dropped node — a dependency that can never be met; and any dropped node whose run still holds an unmerged branch, a live worktree, or an un-ticked STOP command.

### Step 9: Unrecognized-files line
Over the digest's listing, count report-shaped files matching no pattern in the registry (spec's unrecognized-files rules). Report one line with the count and up to three example paths. Omit entirely when the count is zero. This line is how a producer skill's renamed output gets noticed, instead of silently dropping out of the follow-up checks.

## Output & Dialogue Discipline

- Order: tree → summary counts → follow-up checks → the single next action → drift flags → unrecognized-files line. Omit the coverage, drift, and unrecognized-files sections when they are empty. This report claims conventions §7.1's enumeration exception instead of a word budget: how long it runs is set by the tree it has to show, and sixty nodes in scope means sixty lines. Shape is what bounds it instead — one line per node, one clause per count, one line per triggered check, one command and one reason for the next action, one line per drift flag. Prose between the sections is what to cut; a line the reader needs is not.
- Reply in the user's language; the tree/labels follow the chat language even though plan and report bodies may be `zh`.
- Since you write nothing, there is no confirmation point — but for the same reason, never state or imply that you changed anything.
