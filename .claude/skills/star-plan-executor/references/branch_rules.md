# Execution Branch and Worktree Rules

The operating procedure behind conventions §11. Step 4 decides and creates; Step 5 commits onto the branch; Step 7 ends the branch — merge or discard — and the worktree that housed it. Every git command here is the executor's to run, except where a line hands it to the user.

## When to recommend a branch

From Step 2's gap list: any action that **modifies** an existing tracked file under `${CODE_NAME}/` → recommend `branch: <run>`. Only needs-creating entries, or writes confined to `tasks/<plan-name>/` and `wkdrs/<run>/` → `branch: none`. An empty codebase never branches. Diff size, entrypoint reach, and how many other plans touch the same files sharpen the wording, never replace the rule. The user settles it at Step 4 — either direction is valid — and the answer lands in EXEC_PLAN's `branch:`.

## When to recommend a worktree

The branch asks whether this run's history needs isolating (above); the worktree asks whether the invoking checkout is free right now (conventions §11.7). Check the signals while orienting in Step 2: HEAD sits on another run's execution branch; uncommitted changes sit on paths another run's records claim; an EXEC_LOG records handed-back commands whose results are not collected — a job may be running, which no command can check, so ask the user; or the user has named parallel work. Any signal → recommend `worktree: ../<root-dirname>--wt/<run>`; none → `worktree: none`. A run in a worktree always carries a branch, even where the gap list said `branch: none` — its commits need a home while the base branch stays checked out elsewhere (§11.8). Both lines are settled together at the Step 4 confirmation point.

## Creation (Step 4, on approval)

1. Record the checkout's current branch and short SHA as `base:` (`git rev-parse --abbrev-ref HEAD`, `git rev-parse --short HEAD`). Never assume `main`.
2. The precondition was stated at the confirmation point: nothing is running from this checkout — a live job re-reads switched files mid-run. A busy checkout is no longer a reason to wait: it is the signal that sends this run into a worktree instead.
3. Branch only: `git switch -c <run>`. Pre-run uncommitted changes carry over untouched; they stay named as pre-existing and are never staged (conventions §1.4).
4. Worktree: from the invoking checkout, `git worktree add <path> -b <run> <base>` — tree, branch, and fork point in one step, and no checkout switches. Pre-run uncommitted changes stay behind with their checkout; the tree starts out clean from `base:`.
5. Worktree: git creates only tracked files in it, so link the runtime in from the main checkout — `.env`, `datas/`, `inits/`, and `.star/memory/local/` where present, absolute-path symlinks — then re-run the §3 resolution against the tree's `.env` to prove the interpreter still resolves. Never link `wkdrs/` or `tasks/` (§11.8). Record the tree's absolute path as `worktree:` in EXEC_PLAN / EXEC_LOG frontmatter; from here, every part of this run — dispatches, checks, commits, records — happens inside the tree, and each dispatch brief names the tree root (`agent_dispatch_spec.md`).
6. Choosing the branch chooses per-step commits with it: a branch with nothing committed has nothing to merge.

## Commits on the branch (Step 5)

Each verified step's commit stages the step's files **plus the run-record updates that step caused** — the `EXEC_LOG.md` row, `EXEC_PLAN.md` sync marks, the sub-plan's frontmatter — message prefix per conventions §1.2. A record left uncommitted does not merge, and worse: an uncommitted edit to a file both branches carry rides along on a later `git switch` instead of staying with the branch.

## Resume (Step 7)

- A branch `<prefix>_<slug>*` matching the leaf is the run in flight, even when the base checkout shows the leaf unexecuted — the base branch is canonical (conventions §11.3). Resume on the branch.
- A run whose records carry `worktree:` lives there. Confirm the tree exists (`git worktree list`), then resume **inside it** — the invoking checkout never switches. A recorded tree gone from disk is a blocker to report: `git worktree prune` clears the stale metadata, and the tree is never silently rebuilt.
- Before switching, `git status`: unrelated uncommitted changes are named, and the switch waits for the user's answer — they commit or stash their own work, or say the paths cannot collide. Never stash for them.
- A recorded `branch:` that no longer exists is a blocker to report; never re-create it silently.

## The merge confirmation point (Step 7)

Reached when every step is `done`, the §5 done-criterion is verified, and the newest `CODE_REVIEW_<date>.md` holds no unsettled blocker/major finding — with no review yet, the Step 8 report has already started one; the user may waive it, and the waiver is recorded in the log. Then ask, at every involve level, with consequences per option:

1. **Merge (recommended).** Commit any run records still loose on the branch first. If the base branch moved past `base:`, merge it *into* the execution branch — never rebase (conventions §1.3) — re-run the leaf's light checks there, and on conflict stop: name the conflicted files; resolution is the user's to direct. The squash runs in whichever tree has `<base>` checked out — `git switch <base>` first on a branch-only run; on a worktree run the main checkout already stands there. Then `git merge --squash <run>`, one commit, message `star-plan-executor: <run> — merge (squash), <N> steps, review <report-file>`; use `--no-ff` instead when the user wants the step commits kept on the base branch. After the merge: re-run the leaf's light checks on the base branch (§2-legal only), set `merged:` in the run's records. On a worktree run, then settle the tree — its removal is a deletion asked at every level, because untracked files die with it: on yes, first move the non-md untracked artifacts under the tree's `wkdrs/<run>/` and `tasks/<plan-name>/` to the same paths in the main checkout, then `git worktree remove <path>` without `--force` — git refusing over stray files means something was missed; investigate, never override (§11.9). Last, the branch question — keep or delete `<run>`, a deletion like any other.
2. **Not yet.** The branch stays; `star-flow-status` keeps naming the merge as this leaf's outstanding follow-up. On a worktree run the tree stays with it. Nothing else changes.
3. **Discard.** On the base branch, `git checkout <run> -- wkdrs/<run>/` and commit those records together with the sub-plan's run entry and the verdict that ended it (`exec_status: abandoned`, or back to `pending` for a re-run — the user picks). On a worktree run, move the non-md artifacts out of the tree as above — a negative result's outputs are still evidence — then the tree's removal and the branch's deletion are each their own question, asked at every level. The records reach the base branch; the code does not.

## What the other skills see

While the execution branch `<run>` is checked out, every skill acts on it: the reviewer's fix commits, the analyst's report, the reviser's edits to **this** leaf's plan land on the branch and merge with it. A worktree run's home is its `worktree:` field — those skills work inside that tree, and the main checkout keeps the base branch checked out throughout. A skill about to commit anything unrelated to this run says so and offers to switch back first (conventions §11). `execs/update.sh` runs on the base branch, never here.
