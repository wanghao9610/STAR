# Gather Rubric — promotion, placement, and polishing what a reader will open

How a candidate file is found, judged, placed, and verified, and what the polish pass may touch afterwards. The bar is deliberately high: release time invites tidying the whole repository, and a promotion nobody can justify is churn that costs a reviewer their trust in the diff.

## Where to look

**Swept:**

- `tasks/<plan-name>/` — the plan-owned tool scripts (conventions §9 calls them durable) and the scratch beside them. Most real candidates live here.
- `wkdrs/<run>/` — **scripts and reproduction configs only**: the plotting script an analysis wrote, the config that reproduces a headline run. Usually untracked, since `wkdrs/**` is git-ignored except `*.md` — exactly why they are worth promoting.
- The project root — stray `.py` / `.sh` files that never found a home.
- `execs/scpts/*.sh` — read for *reference* (the README prints these) and checked for hardcoded paths. Launchers stay in `execs/` (conventions §9) and are never promoted into `${CODE_NAME}/`.

**Never swept:** `datas/`, `inits/`, `metds/`, `.git/`, `docs/`, generated artifacts (checkpoints, logs, predictions, figures, `.csv`/`.json` outputs), anything already inside `${CODE_NAME}/`, and any file over ~1 MB (an artifact wearing a source extension).

## The promotion test

A candidate is promoted only if it passes **at least one** part, with the passing evidence on its row:

- **A. The README will cite it.** A section from `references/readme_map.md` prints its path or the command that runs it — a data-prep script (§7), an eval entry point (§11), a demo (§9).
- **B. An executed leaf needs it.** The file is named by a leaf's §4 deliverables or is the machinery its §5 done-criterion runs, that leaf's `exec_status` is `done`, and neither it nor any ancestor is dropped. Evidence is the plan file and line.
- **C. It reproduces a number in the results table.** Running it produced a row in `wkdrs/results/results.md` — the config of a run the results table cites, the script that computed a reported metric. Evidence is the results-table row.

Passing none → **keep in place**. Say so on the row and move on — the expected outcome for most of `tasks/`, not a finding.

Two disqualifiers override a pass:

- **Contains a secret or a machine-local path** → not promoted in that state. It becomes a `release_checklist.md` blocker first; promotion can follow once the user has cleaned it.
- **Duplicates working code already in `${CODE_NAME}/`** → `merge` or `keep in place`, never a second copy. See below.

## Placement

1. The destination comes from `metds/codearc.md` §2 placement rules, matched on what the file *is* — a data-pipeline script, a model component, a config, a tool, a test.
2. Where §2 has no rule for this kind of file, check §4's plan-component map for the component it implements.
3. Still unresolved → the row's action is `route`, not a guessed path. Creating a directory `codearc.md` does not name is `/skill:star-code-architect`'s decision; a release run that invents `${CODE_NAME}/utils/` quietly amends the architecture spec without a confirmation point.
4. No `codearc.md` at all → every row is `route`, and the whole gather phase reports the architecture spec as the blocker. Compiling the README can still proceed.

## Duplicate detection

Before promoting, compare against `${CODE_NAME}/`: same or near-identical function/class names, the same file name in a plausible directory, an obviously copied body. On a hit:

- The existing code is newer or equivalent → `keep in place`, and note the candidate is superseded.
- The candidate is materially better (fixes a bug, handles a case the existing one drops) → `merge`: the row states which existing file receives the change and what changes; the merge is an edit to that file, not a new one.
- Genuinely different despite the resemblance → `move`, and the row says how they differ, so two similar files do not surprise a reviewer.

## The decision record format

One entry per candidate, in sweep order:

```yaml
- path: <path from project root>
  kind: <tool script | config | data pipeline | model component | analysis | test | other>
  passes: A | B | C | none
  evidence: <the README section, the plan file:line, or the results-table row>
  destination: <path under ${CODE_NAME}/, or "—">
  action: move | merge | keep in place | route
  plan_referenced: <plan file:line whose text goes stale if this moves, or "no">
  risk: <one line — importers to fix, a config path that changes, nothing>
```

`plan_referenced` is not a veto but a consequence the user approves with open eyes. Plan text is not this skill's to edit, so every such row lands in the report's routing block for `/skill:star-plan-reviser`.

## Verification per row

After each approved row, the main agent re-runs the checks itself — never a self-reported pass:

1. `python -m compileall -q <destination>` through the `.env` interpreter.
2. `grep -rn "<old path>" --include="*.py" --include="*.sh" --include="*.md" .` over the repository — any remaining hit is a call site still to fix, or the row is not done.
3. For a `merge`, the receiving file compiles and its existing importers still resolve.

A row still failing after the fix attempt is reverted (`git checkout` for tracked paths, move back otherwise), marked `blocked` in the report with the failure text, and the run continues with the remaining rows.

## Polishing what a reader will open

Applies to: the files promoted this run, the entrypoints / configs / `execs/scpts/*.sh` the README prints, and the public API the README shows. Nothing else — the six-dimension audit of `${CODE_NAME}/` belongs to `/skill:star-code-reviewer`, and a finding outside them is recorded for routing, not fixed.

What counts as a finding here:

- **Move leftovers** — an import the move stranded, a path constant pointing at the old location, a docstring describing the file's former home.
- **Scratch that survived promotion** — commented-out experiment variants, `print()` debugging, a hardcoded `if True:` switch, an unused `sys.path.append`.
- **`codearc.md` conformance** — the file's name and placement match §2's rules and §3's naming conventions; a name on the do-not-rename list (§7) is flagged, never renamed.
- **Documentation of what the README names** — every symbol, script flag, or config key a reader will look up has a docstring or comment saying what it does. A file the README never mentions is out of scope, even in the same directory.
- **Reader-facing clarity** — a function doing several jobs that the README presents as one step, a name that contradicts what the README calls it. The fix is the smaller change: usually the docstring, sometimes the name, never a redesign.

Ineligible, always: behavior changes, signatures used outside these files, files outside them, names on the do-not-rename list, and upstream-inherited code (AGENTS.md §3 — report it, do not touch it).
