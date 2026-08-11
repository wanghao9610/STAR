# Status Spec — how to read the flow and pick what's next

Everything here is derived by reading files. Write nothing.

The plan tree has ordering semantics, so it gets a graph walk. The follow-up checks are thin by design — presence and freshness only. The priority order picks the one recommendation across both; the unrecognized-files line is the check that catches a renamed output.

## Scope — what a `PLAN_NAME` narrows

Resolution follows conventions §5, with one difference: this skill never asks, so §5.2's question has to be settled on the page.

- A numeric prefix matches the digits before the first `_` **exactly**: `1` resolves `1_<slug>_plan.md` and never `10_…`. Two roots that share a slug are separated by exactly this, so a prefix matching one file resolves even where the slug alone would not.
- An argument matching **more than one** plan file renders every match, each under its own root line, and the reply's first line names the ambiguity and gives the unambiguous command per match.
- An argument matching **none** renders no tree: list the nearest candidates (prefix + slug + one-line state) and stop there.

Once resolved, the scope governs the whole reply: the tree renders that subtree only, the three summary counts are computed over it, the coverage rows check only its artifacts, and the next action is picked within it. Plans outside it are read — `parent:` does not resolve without them — and then set aside. Two things stay project-wide and say so where they are defined: the unrecognized-files line, and a drift flag that has to name a parent outside the subtree. A `PLAN_NAME` naming a dropped node (below) resolves and renders like any other: what that field withdraws is the recommendations, never an explicit look.

## What to read per file

Each `metds/plans/<prefix>_<slug>_plan.md` frontmatter may carry:

- Top-level plans (from the coach): `status:` map over the six sections, optional `finalized:`, `updated:`, and (once decomposed) `children:` + a `## Sub-plans` body index.
- Sub-plans (from the decomposer): `parent:`, `prefix:`, `traces_to:`, `depends_on:`, a `status:` map over the six execution sections, `updated:`.
- Executed leaves (from the executor): `exec_status:` (`pending`/`in_progress`/`done`/`blocked`/`abandoned`) — `done` and `abandoned` are both **terminal**: a leaf in either needs nothing further and does not hold a downstream readiness check shut. A leaf carrying `skipped`, a value no skill sets any more, reads as terminal too — that is the only place it is still recognised. `abandoned` records a direction killed by its own kill-criterion; the reason belongs in the plan's `## Revision History`, so the negative result survives and `exec_runs:` — an append-only list of `wkdrs/<run>/` dirs, newest last, whose **last entry is the current run**; earlier entries are re-runs (a second seed, a fixed bug) and stay for the record. A plan written before this field carries a single `exec_run:`; read it as a one-item list — the executor migrates it on its next write.
- Any node, once `star-plan-reviser` has dropped it: `dropped: <YYYY-MM-DD> — <one-line reason>` — the direction was given up. **It is inherited, never copied downward**: a node counts as dropped when it carries the field *or any ancestor does*, so the decision is written once, on the node where it was made, and a child added under a dropped node later is dropped with it. The full account is that plan's `## Revision History`; the parent keeps its `children:` entry and its `## Sub-plans` line, with a `— dropped <date>` marker on that line.

For a leaf with `exec_runs`, also read the current run's `wkdrs/<run>/EXEC_LOG.md`: the step-status table (count `done` / total, note any `blocked`), the "Awaiting user (STOP line)" list, and any "Plan-level finding" in Notes. Under `--slim` a table of more than six rows arrives already counted — `[tally] 8 data rows | c3: done×7, blocked×1` is that count and that note in one line, and a column given as `N distinct` holds step names or dates, never statuses. Un-ticked checkboxes and plan-level findings are printed verbatim whatever the table did, so nothing the STOP-line rules or Step 3 need is ever behind a count. The log frontmatter's `branch:` / `merged:` ride the same read (conventions §11).

The scan call also lists execution branches (conventions §11). One matching a leaf whose run dir is absent from this checkout is a run in flight on that branch: the base branch is canonical (§11.3), so the leaf's frontmatter here correctly reads not-done — render the leaf with the branch named rather than as merely pending, and read branch-side state only where a row below needs it, through read-only `git show <run>:wkdrs/<run>/EXEC_LOG.md` (§1's read-only list covers `show`). The worktree listing reads the same way (§11.7–9): a tree whose path ends in a run's name is that run's home — name it beside the branch when rendering the leaf — and a tree matching no leaf and no run record is not ours to mention.

For the follow-up checks, read the other registered artifacts by presence and by the one date field each carries — never their full bodies. Conventions §8 is the registry; the coverage table below names the exact field per row.

## Node classification

- **root** — `parent:` absent (a coach plan). Prefix is 1 digit.
- **internal** — has a non-empty `children:` list (it was decomposed further).
- **leaf** — `children:` empty or absent. Only leaves are executable.

Rebuild parent→child links from `parent:` (authoritative), not prefixes. Within a parent, order children topologically by `depends_on`; if that is missing or ambiguous, fall back to ascending prefix.

## Status symbol legend (one per node)

- `✔` done — strategy node `finalized:` set; leaf `exec_status: done`.
- `✖` killed — leaf `exec_status: abandoned`: the direction was run and its own kill-criterion closed it. Terminal like `✔`, and paired with it on purpose — reached versus killed is what a reader takes from the tree at a glance, so it is not left to the state text (`exec abandoned`) or to the count line (`1 abandoned`), which say it again.
- `◐` in progress — some sections `done`/`in_progress`, or all six `done` with `finalized:` unset (the rubric has not been run), or leaf `exec_status: in_progress` (show `k/n` steps if a log exists).
- `○` pending — nothing started (`exec_status` absent/`pending`, or all sections `pending`).
- `⊘` blocked — leaf `exec_status: blocked`, or a leaf whose `depends_on` is unmet.
- `⏸` awaiting user — leaf whose EXEC_LOG has un-checked "Awaiting user" STOP-line commands.
- `⚠` needs attention — **too big to run**, in either of two ways: a sub-plan leaf whose own §3 Task Breakdown / §5 Done-Criteria are largely `[TBD]` or `【待定】` (both markers count — a Chinese plan writes the second, and the scan counts them together), **or** a top-level plan carrying `finalized:` with no `children:` — never decomposed, so it counts as a leaf (conventions §5.4) and the executor will reject it. This is the only definition; tier-3 eligibility follows it regardless of the status symbol the lifecycle rule renders → suggest `$star-plan-decomposer`.
- `⊗` dropped — the node carries `dropped:`, or an ancestor does. The node carrying it reads `dropped <date> — <reason>`; everything below it reads `dropped with <that node's prefix>`.

**One status symbol per node, and lifecycle wins.** A node that qualifies for both a lifecycle status symbol and `⚠` gets the lifecycle one: a finalized-then-edited root is `✔`, a done leaf with no run is `✔`. Drift belongs in the drift section, which is where the reader goes for it — never let a drift flag overwrite the state the node is actually in, or the tree stops meaning what it says. `⏸` and a terminal `exec_status` can both fit one leaf — a run left an un-ticked STOP command behind and the leaf was closed afterwards. Terminal wins, for the reason a lifecycle status symbol beats `⚠`: the leaf renders its terminal symbol (`✔`, or `✖` where the direction was killed) and the command that is still on record goes to the drift section. `⏸` is for a leaf whose `exec_status` has not reached a terminal state.

**`⊗` outranks every status symbol above it, `⚠` included.** A node given up on has no progress anyone acts on, so it renders `⊗` whatever its sections and its `exec_status` say — with that state kept in parentheses on the same line (`dropped with 04 (exec done)`), because what the subtree reached before it was dropped is the whole reason for keeping the record. No tier of the priority order picks a dropped node up either, `⚠`'s decomposition route included: a direction given up is not a backlog. What a drop does **not** withdraw is anything still on disk — an unmerged execution branch, a live worktree, an un-ticked STOP command each keep their drift flag below.

Show, per leaf line, its `depends_on`, (if executing) `k/n` steps, and — when the current run records an execution branch — its merge state: `<run> unmerged`, or `merged` once the log says so; append `(wt)` when the run also records a live `worktree:`. Example:

```
0_open-vocab-det-seg            ◐  strategy 6/6 done, decomposed (5 children)
├ 00_baseline-impl              ✔  exec done                        deps: —
├ 01_mvp-verify                 ✔  exec done                        deps: 00
├ 02_core-method                ◐  exec in-progress 2/5 steps        deps: 01
│ ├ 020_desc-generation         ✔  exec done                        deps: —
│ ├ 021_set-matching            ◐  exec in-progress 2/4             deps: 020
│ ├ 022_det-seg-heads           ○  exec pending                     deps: 020, 021
│ └ 023_contrastive-head        ✖  exec abandoned                   deps: 020
├ 03_final-rets                 ⏸  awaiting user (1 STOP cmd)        deps: 02
└ 04_alt-matcher                ⊗  dropped 2026-08-11 — superseded by 02
  └ 040_hungarian-baseline      ⊗  dropped with 04 (exec done)      deps: —
```

The root above is `◐`, not `✔`, because its `finalized:` is unset — six `done` sections alone do not close a strategy node, the rubric still has to be run. A strategy node's status symbol reports **its own** state, never its subtree's: a finalized root over a half-executed subtree is still `✔`, and the summary counts are what tell you the subtree is unfinished. `04` is the node the drop was written on; `040` carries no field of its own and reads dropped because its ancestor is — which is why the field is never copied downward. `023` is terminal for a different reason: it ran, its own kill-criterion closed it, and like the dropped pair it leaves the execution count's denominator rather than holding that ratio under 100% for good.

Tree size does not change the rule. A project with sixty nodes prints sixty lines; what may shrink is the state text on a line — `◐ 2/5` is a complete line — never the set of lines. A subtree replaced by a sentence ("8 leaves, all done") loses which leaf is which, and two runs summarising the same subtree differently produce a report the reader cannot check against the files.

## Summary counts (three numbers)

All three are computed over the scope whenever a `PLAN_NAME` narrowed the run (see Scope above), never over the project.

**A dropped node and its subtree sit outside all three, denominators included** — that is what lets a programme which gave one branch up still read as complete. Report them under the counts as one line instead: `dropped: 2 nodes under 04 — outside the counts above`.

1. **Strategy completeness** — across top-level plans (root/internal that came from the coach): sections `done` / (6 × number of top-level plans). Note any not `finalized:`.
2. **Decomposition coverage** — internal nodes (decomposed) vs leaves flagged `⚠` too big to run (as defined above).
3. **Execution progress** — leaves `exec_status: done` / total leaves; and summed EXEC_LOG steps `done` / total across leaves that have a run. A leaf that will never run counts out of the denominator rather than holding the ratio under 100% for good: `abandoned` leaves it exactly as a dropped leaf does, and both are named beside the number (`2 dropped, 1 abandoned`) so they stay visible.

## Follow-up checks (what finished work still needs)

Each row fires **only when every condition in it holds**. Anything else is silence — in particular, a run that is still executing has nothing outstanding, and a leaf that is not `done` leaves nothing outstanding downstream. **No row fires on a dropped node or on anything under it**: a direction given up owes nothing. Rows 8 and 13 read "every leaf" over live leaves only — a dropped leaf is not an unfinished one. Report a triggered row as one line: what is outstanding, on which node or run, and the command that closes it. Scope: when `PLAN_NAME` was given, check only artifacts belonging to that subtree (and the runs reachable from its leaves' `exec_runs`).

| # | Signal | Fires when (all must hold) | Route |
|---|---|---|---|
| 1 | Idea not planned | a `metds/ideas/<slug>_idea.md` has `finalized:` **and** no root plan matches that slug **and** no root plan's §1 body names that idea file | `$star-plan-coach <slug>` |
| 2 | Refs missing | at least one root plan exists **and** `metds/refs/refs_index.md` does not exist | `$star-refs-reviewer` |
| 3 | Code review missing | a leaf is `exec_status: done` **and** its current run dir exists **and** that dir holds no `CODE_REVIEW_<date>.md` | `$star-code-reviewer <leaf>` |
| 4 | Code review stale | the run's newest `CODE_REVIEW_<date>.md` exists **and** its date is older than the newest date that run's `EXEC_LOG.md` carries | `$star-code-reviewer <leaf>` |
| 5 | Analysis missing | a leaf is `exec_status: done` **and** its current run dir exists **and** that dir holds no `EXPT_ANALYSIS_<date>.md` | `$star-expt-analyst <leaf>` |
| 6 | Results table stale | ≥2 leaves have an `EXPT_ANALYSIS_<date>.md` **and** no results table covering the scope is current — i.e. neither `wkdrs/results/results.md` nor (when scoped to `PLAN_NAME`) `wkdrs/results/results_<slug>.md` exists with a `generated:` at least as new as the newest of those report dates | `$star-expt-analyst aggregate` |
| 7 | Method docs stale | a compiled `metds/*.md` (one carrying `type:` + `generated:` + `sources:`) lists a plan in `sources:` whose recorded `updated` is older than that plan's current `updated` | `$star-metd-summarize` |
| 8 | Method docs missing | every leaf is terminal (`done` / `abandoned`) **and** every top-level plan carries `finalized:` **and** no `metds/*.md` carries `type:` + `generated:` | `$star-metd-summarize` |
| 9 | Adoption not backfilled | `metds/adopt.md` exists **and** its `backfilled:` is absent or `—` **and** ≥1 sub-plan carrying `parent:` exists | `$star-proj-adopt backfill` |
| 10 | Digest stale | `wkdrs/digests/` holds ≥1 `EXPT_DIGEST_<date>.md` **and** ≥1 run in scope has an `EXPT_ANALYSIS_<date>.md` dated after the newest **series** digest's `covers.through` | `$star-expt-digest` |
| 11 | Codebase missing | ≥1 executable leaf exists **and** `metds/codearc.md` does not exist | `$star-code-architect` |
| 12 | Runtime missing | ≥1 executable leaf exists **and** no `wkdrs/env_*/ENV_REPORT.md` exists | `$star-env-builder` |
| 13 | Release missing | every leaf is terminal (`done` / `abandoned`) **and** a compiled `metds/*.md` carries `type:` + `generated:` **and** `wkdrs/release/` holds no `RELEASE_<date>.md` | `$star-code-release` |
| 14 | Merge outstanding | a leaf's current run records `branch:` with `merged:` still `pending` **and** the leaf is `exec_status: done` on that branch **and** the run's newest `CODE_REVIEW_<date>.md` exists with no blocker/major finding its log leaves unsettled | `$star-plan-executor <leaf>` (reaches the merge confirmation point — conventions §11) |

Six rows are easy to get wrong:

- **Row 4 reads the log's own dates, never file mtimes.** The scan's per-run `[dates seen]` line collects every date in the log — the frontmatter `updated:`, each `model_trail` entry, any date in the step table — so the newest of them is when that run last moved, which is exactly what a review's date has to be compared against. A step-table date column is optional and is not what this row depends on. An mtime is never consulted: it moves for a checkout or a backup.
- **Row 7 is an exact reconciliation, not an mtime guess.** `$star-metd-summarize` records, per source plan, the `updated` value that plan carried when it was read. Compare that recorded value against the plan's current `updated` — never file mtimes, which move for unrelated reasons (a checkout, a formatter).
- **Row 8 waits for the whole tree.** The summarizer compiles a determined method — its own readiness check stops while any leaf is unexecuted or any top-level plan is unfinalized — so the follow-up checks recommend it only once every leaf is `done` and every top-level plan carries `finalized:`, however many leaves finished earlier.
- **Row 10 fires only for a project that already keeps digests.** Unlike rows 2, 7, and 8, an absent artifact does not trigger it: a digest is a working aid, not a deliverable the research must produce, and a project that has never run `$star-expt-digest` does not have one outstanding. The row therefore asks whether an *existing* series has fallen behind the analysis reports. "Newest series digest" means the newest whose `mode` is `incremental`, `window`, or `all` — `plan`-mode digests are retrospective reads and carry a `covers.through` that must not be mistaken for a resume point, exactly as the skill's own `scope_spec.md` defines the last covered date.
- **Row 14 reads wherever the records are.** On the branch checkout they are in the working tree; from the base checkout, the execution-branch listing is the trigger and read-only `git show` the reader. Its review condition is the branch-side `CODE_REVIEW_<date>.md`; when none exists, row 3 fires on the branch-side state instead and outranks it within the tier anyway. A run housed in a worktree keeps its working files in that tree, but its committed records answer the same `git show` from here; the merge itself proceeds through the executor, which resumes inside the tree (§11.8).
- **Row 1 is the weakest signal here.** `$star-plan-coach` notes its seed as prose in the plan's §1 ("Seeded from `metds/ideas/<slug>_idea.md`"), not as a frontmatter field, so detection is a slug match plus a body grep for the idea's filename. An idea-seeded plan that was later renamed will read as un-planned. When row 1 is the only thing firing, say the check is heuristic.

## Next action (the one recommendation)

Walk the priority order top-down and take the **first** tier that yields a candidate. Everything else outstanding stays in the follow-up checks and is not repeated here.

1. **Awaiting user** — a leaf `⏸` with un-checked STOP-line commands. Name the command; the user is the only one who can clear it, so nothing below matters until they do. One thing goes ahead of the command itself: when that run dir holds no `CODE_REVIEW_<date>.md`, recommend `$star-code-reviewer <leaf>` first and print the awaiting command directly under it — a defect costs least to find before the compute, and row 3 cannot cover this because the leaf is not `done` yet. The two have different owners: the review is one of the eight and is what runs (below), while the awaiting command is printed and stays the user's.
2. **Outstanding follow-up on finished work** — a triggered coverage row on work that is already done, taken in order of how fast it compounds: backfill (row 9) → review (rows 3, 4) → merge (row 14) → analysis (row 5) → aggregate (row 6) → summarize (rows 7, 8) → refs (row 2) → digest (row 10). Row 9 leads because it is the one that hides the others: until an adopted project's finished leaves carry `exec_status: done`, rows 3 and 5 cannot fire on them at all, and tier 3 will happily recommend executing a leaf whose work is already sitting on disk. Merge (row 14) follows review immediately: an unmerged branch blocks every dependent leaf (conventions §11.3) and keeps its records invisible from the base checkout — two costs that grow with every leaf executed around it. Every coverage row except row 1 is reachable here; row 1 is tier 4 because starting a new topic is not an outstanding follow-up. Digest comes last of all, and is the one item on this list that costs nothing to defer: every digest is recompiled from analysis reports that stay on disk, and the series stays gapless however long the gap between runs — so a late digest loses no information, while every other row on this list gets more expensive the longer it waits. Refs comes second-to-last despite being early in the flow: a missing survey costs positioning at write-up time, while unreviewed code costs every leaf built on top of it — so "go read the literature" must never outrank "the run you just finished was never reviewed". Outstanding follow-up outranks progress because it compounds: every further leaf executed on unreviewed code, or quoted from a stale results table, widens what has to be redone. The next leaf, by contrast, does not expire.
3. **Next runnable leaf** — the **earliest leaf in execution order** satisfying all of: `exec_status` is not terminal (`done` / `abandoned`) and not `blocked`; neither it nor any ancestor of it is dropped; every prefix in its `depends_on` resolves to a sibling whose `exec_status` is `done`; it is not `⚠` too big to run (if it is, recommend decomposing it first instead); and no live execution branch matches it — such a leaf is in flight on that branch (row 14 or plain resume owns it), not runnable fresh, and the reason line says so. "Execution order" = the topological order from `depends_on`, tie-broken by ascending prefix, walked depth-first so a decomposed node's own leaves come before its later siblings. Output `→ next: $star-plan-executor <prefix or slug>`.
4. **Finalized idea with no plan** — coverage row 1. Only reached when the tree is fully done and nothing is outstanding; that is exactly when starting the next topic is the right move.

Give a one-line reason with the command. Each named command is judged on its own, tier 1's pair included: where a command names one of the eight skills the agent may start (conventions §10) and its target is settled, it is what runs next rather than only what is printed — taken up after this run ends, since this skill starts nothing itself — while a STOP-line command beside it is printed and waits for the user. If no tier yields anything, say which of these it is: nothing is outstanding and every leaf is closed — the programme is finished, so route to `$star-code-release`, or `$star-idea-storm` for the next topic; an unmet dependency (name it); a leaf too big to run, needing decomposition; or an empty `metds/plans/` (route to `$star-plan-coach`, or `$star-idea-storm` when there are no ideas either). A scope in which every node is dropped is its own answer: say that nothing in it is live, and name the nearest live scope if one exists.

## Drift / consistency flags (report, never fix)

- **Possible stale sub-plan** — a child whose `updated` is older than its parent's `updated` (parent changed after decomposition). Suggest `$star-plan-decomposer <parent>` to reconcile.
- **Dangling link** — a `children:` entry with no matching file, or a plan file whose `parent:` names a file that isn't there, or that its parent's `## Sub-plans` index omits.
- **Bad dependency** — a `depends_on` prefix that doesn't resolve to an existing sibling, or a cycle in the dependency graph.
- **Orphaned run** — an `exec_runs` entry pointing at a `wkdrs/<run>/` dir that doesn't exist, or an EXEC_LOG whose `source_plan` doesn't match the leaf.
- **Done with no run** — a leaf `exec_status: done` carrying no `exec_runs` (or whose run dir is gone). Coverage rows 3 and 5 require a run dir, so such a leaf silently leaves nothing outstanding downstream; flag it here instead, since a leaf marked done by hand is either a bookkeeping slip or a run that was deleted.
- **Terminal with an open STOP command** — a leaf in a terminal `exec_status` whose current run still carries an un-ticked "Awaiting user" command. Either it was run and never ticked, or the leaf was closed with it outstanding. The legend renders that leaf `✔` or `✖`, so this row is the only place the reader learns the command is still on record, and the priority order's awaiting-user tier deliberately no longer picks it up.
- **Finalized then edited** — a strategy node whose `updated` is newer than its `finalized:`. The rubric was run, then the plan changed; the `✔` is no longer backed by a rubric pass. Suggest `$star-plan-coach <slug>` to re-close it.
- **Branch left behind** — a listed branch no leaf matches but some run's `branch:` record names (the listing matches by name shape, so a branch neither a leaf nor a run record claims is not ours — leave it alone); one whose log already carries `merged:` while the branch still exists (deletion declined or deferred — flag only); or a leaf whose current run records `branch:` when no such branch exists (deleted under the run — the executor treats that as a blocker).
- **Worktree left behind** — a listed tree whose run's log already carries `merged:` (removal declined or deferred — flag only); a run's records naming `worktree:` when no such tree exists (deleted under the run — the executor treats it as a blocker); or a listed tree neither a leaf nor a run record claims — not ours, leave it alone (§11.9).

- **A live leaf depending on a dropped node** — a `depends_on` prefix resolving to a node that is dropped. That dependency can never be met, so the leaf would read `⊘` blocked for good while the priority order walks silently past it. Name both, and route the edge to `$star-plan-decomposer <parent>` — or the dependent to `$star-plan-reviser <leaf>`, if it should be dropped too.
- **Dropped with work still on disk** — a dropped node whose current run records an unmerged `branch:`, a live `worktree:`, or an un-ticked "Awaiting user" command. The drop withdrew the recommendations, not the resources: those still exist and still cost something to leave. The merge is no longer the answer — the records are rescued and the branch discarded through `$star-plan-executor` (conventions §11.6).

Keep this section short and omit it entirely when nothing is flagged.

## Unrecognized-files line (the check that catches a renamed output)

The follow-up checks match artifacts by name. If a producer skill changes what it writes, the checks would quietly stop firing that row — a silent under-report nobody notices. This line flips that failure into a visible one. Count only **report-shaped** files, so that run artifacts (checkpoints, figures, raw logs) never enter:

- a `*.md` directly inside a `wkdrs/<run>/` dir whose name is not `EXEC_PLAN.md`, `EXEC_LOG.md`, `CODE_REVIEW_<date>.md`, `EXPT_ANALYSIS_<date>.md`, or `REVIEW_<date>.md`;
- a `*.md` directly inside one of the four registered non-run `wkdrs/` dirs, under a name §8 does not register there: in `wkdrs/reviews/` (the shared no-run fallback) the registered names are `code_<scope>_<date>.md` and `<prefix>_<slug>_<date>.md` (numeric prefix); in a `wkdrs/env_<name>_<date>/` dir the registered name is `ENV_REPORT.md`; in `wkdrs/digests/` the registered names are `EXPT_DIGEST_<date>.md` and `MODEL_LEDGER.md`; in `wkdrs/results/` the registered names are `results.md` and `results_<slug>.md`. Any other `wkdrs/` subdir is audited as a run dir under the previous bullet;
- a top-level `metds/*.md` whose stem is not one of `overview`, `framework`, `dataset`, `training`, `evaluation`, `codearc`, `adopt`, **and** which carries any of `type:`, `generated:`, or `sources:`. Those three together are the compiled-document fingerprint: keying on all three rather than on `type:` alone means a producer that renames its output *and* drops `type:` is still caught, while a hand-authored note in `metds/` — which carries none of them — stays silent.

Do not descend into subdirectories (`analysis/`, `raw/`, `refs/`) — those are the producers' own working space and are not registered. Report one line: `⚠ N unrecognized report file(s)` plus up to three paths. Omit the line entirely when N is 0. This is a naming mismatch, not a verdict on the files: it means the registry in conventions §8 and what is on disk have diverged, and one of them needs updating.
