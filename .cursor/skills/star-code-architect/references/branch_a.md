# Branch A — start from a reference implementation

Read where Step 0 chose this branch: `${CODE_NAME}/` is missing or holds only placeholders. A Branch B run — real code already under `${CODE_NAME}/` — never reads this file. An invocation carrying a GitHub URL enters at Step A4 with A1–A3 skipped.

## Step A1: Build the search profile

Extract from the plan: task domain, method keywords, framework and version constraints, baselines named in §2/§4, dataset and tooling needs. Show the profile as a short block before searching. Recipe: `references/repo_rubric.md`.

## Step A2: Search & shortlist

Prefer `gh search repos` / `gh api` (structured stars / license / pushed_at), plus web search for official implementations of the plan's baselines. Shortlist 5–10; skip archived and demo-only repos, and awesome-lists; prefer the origin repo over forks. If `gh` is unavailable or unauthenticated, fall back to web search. If nothing viable turns up, say so honestly and offer: refine the profile / start from a minimal from-scratch skeleton.

## Step A3: Score the shortlist

Score each candidate with the rubric (`references/repo_rubric.md`): plan fit 30, completeness 20, license 15, activity 15, code quality 10, environment match 10. Shallow-read each README (and setup files if needed) — do not clone yet.

## Step A4: Confirmation point 1 — the user picks the repo

Present the top 3–5 via AskQuestion, one option per candidate: one-line why-it-fits, license, stars, last update, main risk, the highest-scoring one first and marked as recommended. Always include an escape option ("none of these — refine the search / start from scratch"). If invoked with a URL, still show that repo's license, activity, and risks, and confirm before cloning.

## Step A5: Put the clone in place

1. Shallow-clone to a temporary directory; record URL, commit SHA, commit date, and license.
2. If the implementation is a monorepo subdirectory, confirm the sub-path with the user and take only it.
3. Remove `.git`; move the content into `${CODE_NAME}/`; keep upstream `LICENSE` and `CITATION*` files in place.
4. Write `${CODE_NAME}/UPSTREAM.md` from `assets/upstream_template.md`.
5. Commit the import (stage only `${CODE_NAME}/`): `star-code-architect: import <repo> @ <short-sha>`.

## Step A6: Conservative rebrand

Follow `references/rebrand_checklist.md`: top-level package directory, all imports, packaging metadata (`setup.py` / `pyproject.toml` name, packages, console entry points), README title and install snippets. After each rename: grep the old name to verify the count dropped as expected, then `python -m compileall -q ${CODE_NAME}` (needs no dependencies). Names on the do-not-touch list (registry strings, config `type:` keys, checkpoint `state_dict` prefixes, logger/wandb project names) go into the **do-not-rename table** for `codearc.md` §7. Commit: `star-code-architect: rebrand to <CODE_NAME>`.

## Step A7: Runtime check (STOP-line aware)

If a usable conda env from `.env` exists, run `python -c "import <package>"` through it. Environment creation and dependency installation are usually heavy: prepare the exact commands (`conda create …`, `pip install -r …`); run light pure-Python installs only with the user's explicit in-session consent; anything with CUDA compilation or downloads over ~1 GB always goes to the user (STOP line, `references/orchestration_spec.md`). Record what ran and what awaits the user. For the full build, hand off to `/star-env-builder` — it owns backend choice, dependency resolution, the tiered install, and the runnable check under its own install-plan confirmation point.

## Step A8: Survey the clone

Count the clone's `.py` files first. Under the light-mode threshold: complete Step C1's repo map with a single read-only pass (`references/survey_spec.md`) — the scoring pass already covered the broad structure, and the main agent may do this itself. Above it: run the Step B1 areas unchanged, or the three C1 actually needs (structure & dependencies, config system, train/eval entrypoints). A reference implementation is usually well past the threshold, and this pass is C1's only input for the architecture and the migration table.

