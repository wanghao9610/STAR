# Execution Branch Rules

The operating procedure behind conventions §11. Step 4 decides and creates; Step 5 commits onto the branch; Step 7 ends the branch — merge or discard. Every git command here is the executor's to run, except where a line hands it to the user.

## When to recommend one

From Step 2's gap list: any action that **modifies** a file that already exists and is tracked under `${CODE_NAME}/` → recommend `branch: exec/<run>`. Only needs-creating entries, or writes confined to `tasks/<plan-name>/` and `wkdrs/<run>/` → `branch: none`. An empty codebase never branches. Diff size, entrypoint reach, and how many other plans touch the same files sharpen the recommendation's wording; they never replace the rule. The user settles it at Step 4 — either direction is valid — and the answer lands in EXEC_PLAN's `branch:`.

## Creation (Step 4, on approval)

1. Record the checkout's current branch and short SHA as `base:` (`git rev-parse --abbrev-ref HEAD`, `git rev-parse --short HEAD`). Never assume `main`.
2. The precondition was stated at the confirmation point: nothing is running from this checkout — a live job re-reads switched files mid-run. A busy checkout means executing later, or the user preparing a `git worktree` and invoking the executor inside it.
3. `git switch -c exec/<run>`. Pre-run uncommitted changes carry over untouched; they stay named as pre-existing and are never staged (conventions §1.4).
4. Choosing the branch chooses per-step checkpoint commits with it: a branch with nothing committed has nothing to merge, so a commit-less branch run does not exist.

## Commits on the branch (Step 5)

Each verified step's commit stages the step's files **plus the run-record updates that step caused** — the `EXEC_LOG.md` row, `EXEC_PLAN.md` sync marks, the sub-plan's frontmatter — message prefix per conventions §1.2. A record left uncommitted does not merge, and worse: an uncommitted edit to a file both branches carry rides along on a later `git switch` instead of staying with the branch.

## Resume (Step 7)

- A branch `exec/<prefix>_<slug>*` matching the leaf is the run in flight, even when the base checkout shows the leaf unexecuted — the base branch is canonical (conventions §11.3), so "not done on base" plus "branch exists" reads as: resume on the branch.
- Before switching, `git status`: unrelated uncommitted changes are named, and the switch waits for the user's answer — they commit or stash their own work, or say the paths cannot collide. Never stash for them.
- A recorded `branch:` that no longer exists is a blocker to report; never re-create it silently.

## The merge confirmation point (Step 7)

Reached when every step is `done`, the §5 done-criterion is verified, and the newest `CODE_REVIEW_<date>.md` holds no unsettled blocker/major finding — with no review yet, the Step 8 report has already started one; the user may waive it, and the waiver is recorded in the log. Then ask, at every involve level, with consequences per option:

1. **Merge (recommended).** Commit any run records still loose on the branch first. If the base branch moved past `base:`, merge it *into* the execution branch — never rebase (conventions §1.3) — re-run the leaf's light checks there, and on conflict stop: name the conflicted files; resolution is the user's to direct. Then `git switch <base>` and `git merge --squash exec/<run>`, one commit, message `star-plan-executor: <run> — merge (squash), <N> steps, review <report-file>`; use `--no-ff` instead when the user wants the step commits kept on the base branch. After the merge: re-run the leaf's light checks on the base branch (§2-legal only), set `merged:` in the run's records, and ask the deletion question — keep or delete `exec/<run>`, a deletion like any other.
2. **Not yet.** The branch stays; `star-flow-status` keeps naming the merge as this leaf's outstanding follow-up. Nothing else changes.
3. **Discard.** On the base branch, `git checkout exec/<run> -- wkdrs/<run>/` and commit those records together with the sub-plan's run entry and the verdict that ended it (`exec_status: abandoned`, or back to `pending` for a re-run — the user picks). Only then offer the branch's deletion, asked at every level. The records reach the base branch; the code does not.

## What the other skills see

While `exec/<run>` is checked out, every skill acts on it: the reviewer's fix commits, the analyst's report, the reviser's edits to **this** leaf's plan land on the branch and merge with it. A skill about to commit anything unrelated to this run says so and offers to switch back first (conventions §11). `execs/update.sh` runs on the base branch, never here.
