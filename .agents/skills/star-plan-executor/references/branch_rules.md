# Execution Branch and Worktree Rules

The operating procedure behind conventions §11. Step 3 decides and creates; Step 4 commits onto the branch; after Step 7's review, the resume path ends the branch — merge or discard — and the worktree that housed it. Every git command here is the executor's to run, except where a line hands it to the user.

An explicit, applicable decision already recorded in the dialogue or run records satisfies the corresponding authorization point; use and cite it instead of asking again. Authorization to implement does not by itself authorize a merge, discard, deletion, overwrite, or a choice between competing user or research intent. A valid `auto=unattended` token with effective `involve=low` is the limited `star-auto` grant; it authorizes only the guarded recommended paths explicitly named below.

## When to recommend a branch

From Step 2's gap list: any action that **modifies** an existing tracked file under `${CODE_NAME}/` → recommend `branch: <run>`. Only needs-creating entries, or writes confined to `tasks/<plan-name>/` and `wkdrs/<run>/` → `branch: none`. An empty codebase never branches. Diff size, entrypoint reach, and how many other plans touch the same files sharpen the wording, never replace the rule. At Step 3, follow any applicable choice the user already made. If none exists, `low` takes and logs the recommendation; `medium` asks it with the plan, and `high` asks it as its own unresolved judgment call. The answer lands in EXEC_PLAN's `branch:`.

Under unattended auto, the same recommendation is taken and logged under its limited grant.

## When to recommend a worktree

The branch asks whether this run's history needs isolating (above); the worktree asks whether the invoking checkout is free right now (conventions §11.7). Check the signals while orienting in Step 2: HEAD sits on another run's execution branch; uncommitted changes sit on paths another run's records claim; an EXEC_LOG records handed-back commands whose results are not collected — a job may be running, which no command can check; or the user has named parallel work. Any signal → recommend `worktree: ../<root-dirname>--wt/<run>`; none → `worktree: none`. A run in a worktree always carries a branch, even where the gap list said `branch: none` — its commits need a home while the base branch stays checked out elsewhere (§11.8). At Step 3, follow an applicable recorded choice; otherwise resolve the recommendation by involve level with the branch decision. An unresolved handed-back command is enough to recommend a worktree without probing or switching the possibly busy checkout.

Under unattended auto, the same guarded recommendation applies; it does not authorize touching the possibly busy checkout or staging its changes.

## The branch and worktree decisions in Step 3

Show both with the EXEC_PLAN material and record the source of each decision: a prior user choice, a `low`/unattended recommendation, or the answer requested at `medium`/`high`. At `medium` ask the two unresolved choices together; at `high` ask them separately. Never ask an already settled choice again.

Under unattended auto, show the same material and identify the limited grant as the decision source.

- **Branch**, where Step 3 set `branch: <run>` (conventions §11): name the base branch it forks from, that taking it takes the per-step commits with it — only commits merge — and its one precondition, that nothing is currently running from this checkout; declining executes on the base branch as before.
- **Worktree**, where Step 3 set `worktree: <path>` (§11.7): name the busy signal that recommends it, the path, the symlinks it will get (`.env`, `datas/`, `inits/`), and that the whole run — commits, records, follow-on skills — then lives in that tree while this checkout stays put; declining executes here, waiting on whatever made the checkout busy.

## Creation (Step 3, after the decisions are recorded)

1. Record the checkout's current branch and short SHA as `base:` (`git rev-parse --abbrev-ref HEAD`, `git rev-parse --short HEAD`). Never assume `main`.
2. Do not switch a checkout from which a job may be running — a live job can re-read switched files mid-run. A busy checkout is the signal that sends this run into a worktree instead.
3. Branch only: `git switch -c <run>`. Pre-run uncommitted changes carry over untouched; they stay named as pre-existing and are never staged (conventions §1.4).
4. Worktree: from the invoking checkout, `git worktree add <path> -b <run> <base>` — tree, branch, and fork point in one step, and no checkout switches. Pre-run uncommitted changes stay behind with their checkout; the tree starts out clean from `base:`.
5. Worktree: git creates only tracked files in it, so link the runtime in from the main checkout — `.env`, `datas/`, `inits/`, and `.star/memory/global/`, `.star/memory/local/` where present, absolute-path symlinks — then re-run the §3 resolution against the tree's `.env` to prove the interpreter still resolves. Never link `wkdrs/` or `tasks/` (§11.8). Record the tree's absolute path as `worktree:` in EXEC_PLAN / EXEC_LOG frontmatter; from here, every part of this run — delegations, checks, commits, records — happens inside the tree, and each delegate's dispatch brief names the tree root (`agent_dispatch_spec.md`).
6. Choosing the branch chooses per-action commits with it: a branch with nothing committed has nothing to merge.

Under unattended auto, the logged decision names the grant; a checkout with an unresolved job record is treated as busy and therefore is never switched.

## Commits on the branch (Step 4)

Each verified action's commit stages the action's files **plus the run-record updates that action caused** — the `EXEC_LOG.md` row, `EXEC_PLAN.md` sync marks, the sub-plan's frontmatter — message prefix per conventions §1.2. A record left uncommitted does not merge, and worse: an uncommitted edit to a file both branches carry rides along on a later `git switch` instead of staying with the branch.

## Resume (Step 0)

- A branch `<prefix>_<slug>*` matching the leaf is the run in flight, even when the base checkout shows the leaf unexecuted — the base branch is canonical (conventions §11.3). Resume on the branch.
- A run whose records carry `worktree:` lives there. Confirm the tree exists (`git worktree list`), then resume **inside it** — the invoking checkout never switches. A recorded tree gone from disk is a blocker to report: `git worktree prune` clears the stale metadata, and the tree is never silently rebuilt.
- Before switching, `git status`: unrelated uncommitted changes are named. Never stash, stage, overwrite, or discard them. Switch only when an existing applicable user decision says the paths cannot collide; otherwise ask how the user wants to protect their work.
- A recorded `branch:` that no longer exists is a blocker to report; never re-create it silently.

## The merge authorization point (after Step 7 review)

Reached when every action is `done`, the §5 done-criterion is verified, and the newest `CODE_REVIEW_<date>.md` holds no unsettled blocker/major finding — with no review yet, Step 6 has already started one and the merge waits for it. A specific applicable merge decision already given is used and cited without another question. Otherwise ask, at every involve level, with consequences per option:

1. **Merge (recommended).** Commit any run records still loose on the branch first. If the base branch moved past `base:`, merge it *into* the execution branch — never rebase (conventions §1.3) — and inspect the combined diff. With existing implementation/integration authorization, resolve a routine conflict when the intended combined result is unambiguous and the resolution is mechanical; then re-run the checks affected by the integration plus the leaf's light checks. A conflict that requires choosing between user changes, research approaches, goals, or acceptance criteria is reported with its files and asks for direction. The `auto=unattended` token alone never authorizes conflict resolution. The squash runs in whichever tree has `<base>` checked out — `git switch <base>` first on a branch-only run; on a worktree run the main checkout already stands there. Run `git merge --squash <run>` without committing yet; when the user selected retained step history, use `git merge --no-ff --no-commit <run>` instead. Apply the same conflict rule. Run the affected light checks on this integrated tree. Only after they pass, set `merged:` in the run records, add their provenance and verification evidence, and stage only those records with this run's integration changes. Create the merge commit with message `star-plan-executor: <run> — merge (squash), <N> steps, review <report-file>` (describe retained history accurately when selected). Confirm the commit contains the `merged:` records. If checks or the commit fail, leave `merged:` unset, retain the pending integration and all evidence, and report the failure; never report a completed merge or clean up the tree before the commit succeeds. On a worktree run, then settle the tree — its removal is a deletion and needs specific authorization because untracked files die with it: reuse an applicable authorization already given; otherwise ask. On authorization, first move the non-md untracked artifacts under the tree's `wkdrs/<run>/` and `tasks/<plan-name>/` to the same paths in the main checkout, preserve raw logs and evidence, inspect `git -C <path> status --porcelain`, then `git worktree remove <path>` without `--force` only when empty — git refusing over stray files means something was missed; investigate, never override (§11.9). Last, retain `<run>` unless the user separately authorized deleting it.
2. **Not yet.** The branch stays; `star-flow-status` keeps naming the merge as this leaf's outstanding follow-up. On a worktree run the tree stays with it. Nothing else changes.
3. **Discard.** This requires a specific applicable user authorization; use one already given without repeating the question, but never infer it from implementation or merge authorization. On the base branch, `git checkout <run> -- wkdrs/<run>/` and commit those records together with the sub-plan's run entry and the verdict that ended it (`exec_status: abandoned`, or back to `pending` for a re-run — the user picks). On a worktree run, move the non-md artifacts out of the tree as above — a negative result's outputs are still evidence — then authorize the tree's removal and the branch's deletion separately. The records and raw evidence reach the base branch; the code does not.

Unattended auto never waives review. Once the conditions hold, its limited grant takes option 1 without asking; use squash, never `--no-ff`; and stop on a moved base that cannot be merged cleanly, any conflict for which no separate explicit resolution authorization exists, or any failed check. For a worktree, the grant covers removal only after the named artifacts and raw evidence have moved, `git -C <path> status --porcelain` is empty, and removal needs no `--force`; otherwise retain it and report the exact paths or refusal. Retain the merged execution branch because deleting it after a squash requires force. This grant authorizes no discard, overwrite, expensive command, or choice about user or research intent.

## What the other skills see

While the execution branch `<run>` is checked out, every skill acts on it: the reviewer's fix commits, the analyst's report, the reviser's edits to **this** leaf's plan land on the branch and merge with it. A worktree run's home is its `worktree:` field — those skills work inside that tree, and the main checkout keeps the base branch checked out throughout. A skill about to commit anything unrelated to this run says so and offers to switch back first (conventions §11). `execs/update.sh` runs on the base branch, never here.
