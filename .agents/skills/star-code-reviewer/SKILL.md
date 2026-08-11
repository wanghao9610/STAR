---
name: star-code-reviewer
description: >-
  Review code quality, docstrings, and whether a plan's code matches what it promised. No argument
  reviews all of ${CODE_NAME}/; a PLAN_NAME (slug / prefix / filename) reviews that plan's files plus
  conformance (§3 tasks, §4 deliverables, §5 done-criterion); a path reviews that path; `diff` or a git
  range reviews changed files. Gathers static evidence through the .env env (installs no tools), scores
  findings on a six-dimension rubric (docstrings, naming, simplicity, conventions, correctness,
  conformance), re-verifies blocker/major findings before reporting, writes the report under wkdrs/,
  then offers a per-item-approved fix pass for mechanical, behavior-preserving issues — feature gaps
  route to star-plan-executor, divergence to star-plan-reviser, restructuring to star-code-architect.
  Use when the user invokes $star-code-reviewer or a run names it next. Supports bilingual
  English/Chinese work.
---

# Research Code Reviewer

Match the user's language. For Chinese dialogue, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Non-Chinese dialogue loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `$star-code-reviewer [PLAN_NAME | PATH | diff | GIT_RANGE]` — no argument reviews all of `${CODE_NAME}/`; a plan name (slug / numeric prefix / filename) reviews the code that plan touches plus its conformance; an existing file or directory reviews that path; `diff` reviews uncommitted changes and a git range (`HEAD~3..`, `main..feature`) reviews the files it changed.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. Before acting, load everything in one message: one file read for the conventions file, one file read for `<this skill's directory>/references/review_rubric.md`, and alongside them one shell call, with the project root as the working directory, carrying only:

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
```

One message, three results: the conventions — §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout — the six-dimension rubric with its finding contract, which Step 1's digest and Step 3's collection work from, and the `.env` line only the shell can answer. Keep the two files out of the command: a shell result past roughly 30 KB is spilled to a file that costs a second round trip to read back — the conventions file is past that limit on its own — while each file read arrives whole on its own budget. Later steps use the rubric as loaded here — no separate read; the report template and Step 1's project-side reads load at their own steps, not here. If this harness has no file-reading tool of its own, put `cat docs/mds/star-workflow/research-workflow-conventions.md` — and the other files named above — back into the shell call and accept the spill.

**Reusing an earlier load.** A second STAR skill in the same conversation does not pay for this twice. Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the probe's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again — a wasted read costs one message, a wrong assumption costs the run. What never carries over is a collector digest, where one is loaded above: it is a snapshot of files a skill run may have written to since, so the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

Serve as the family's code auditor. `$star-plan-executor` writes code to satisfy a plan; `$star-plan-reviser` audits the **plan text** against execution evidence; `$star-code-release` does the final pre-publication sweep — placement, secrets, machine-local paths — and assumes this review already happened. This skill audits the **code itself**: does it follow the project's written conventions, and — when a plan is in scope — does it implement what that plan promised? The product is a persisted, evidence-backed review report; optionally, individually approved mechanical fixes.

Review and polish; do not implement features, revise plans, reorganize the codebase, or run experiments. Route what the review reports beyond what it may write: feature gaps to `$star-plan-executor`, plan-text divergence to `$star-plan-reviser`, structural reorganization to `$star-code-architect`, a broken environment to `$star-env-builder`.

## Core Principles

1. **Review rules are written down; every finding cites one.** The rules come from AGENTS.md (esp. §2 simplicity, §3 surgical changes, §8 layout, §9 runtime), from `metds/codearc.md` when it exists (placement rules, naming conventions, the do-not-rename list), and — in plan mode — from the plan's §2–§5. Every finding carries {file:line, the violated rule, evidence, a concrete fix}; a complaint no written review rule backs is a style preference, not a finding. Rubric: `references/review_rubric.md`.
2. **Find wide, verify before reporting.** Collection always goes to read-only explorers — a context that has not been party to the code under review — called with `spawn_agent` and `agent_type: explorer`; the main agent sizes the fan-out. Every delegate follows the finding contract in `references/review_rubric.md`, never writes, and never grades the overall verdict. Re-read the cited code for every blocker/major finding before it enters the report; downgrade or drop what does not hold up. A review is judged by the precision of its findings, not their count — one wrong blocker costs the report its credibility.
3. **Conformance is scored against disk, never against logs.** In plan mode, §3 tasks map to code as `implemented` / `partial` / `missing` with pointers, §4 deliverables are checked on disk, and the §5 done-criterion is checked for supporting machinery — EXEC_LOG's claims are corroborated against actual code, never trusted (the reviser's discipline, applied to code).
4. **Static tools are evidence, not judges — and never installed.** `python -m compileall -q` always (zero dependencies); ruff/flake8 only if already present in the `.env` env. Tool output feeds findings; it does not replace reading the code. No usable env → the review degrades to reading-only, says so in the report, and recommends `$star-env-builder`. Never modify the environment.
5. **Fixes are mechanical, individually approved, behavior-preserving.** After the report, offer a fix pass covering only docstrings, scope-internal renames, unused imports, and dead code this project introduced. Each item is approved through one direct question at a time before it is applied — one finding (or one same-type batch) per question, recommendation marked — and re-verified after application. Never bundle-approve silently; never "improve" adjacent code (AGENTS.md §3).
6. **Read-only beyond the fix pass; the STOP line applies.** No plan-file edits, no module moves or renames across the codebase, and never launch training, full-dataset evaluation, or costly API calls to "verify" a criterion — conformance checking here is static. Names on codearc.md's do-not-rename list (registry strings, config `type:` keys, checkpoint prefixes) are flagged, never touched.

## Workflow

### Step 0: Resolve the scope

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. Interpret the argument, first match wins:
   - `diff` → files changed in the working tree vs HEAD (staged + unstaged + untracked source files); a git range (`HEAD~3..`, `main..feature`) → `git diff --name-only <range>`.
   - A plan name (slug / numeric prefix / filename against `metds/plans/*_plan.md`; a `metds/plans/` path counts) → **plan mode**.
   - An existing file or directory → **path mode**; a `wkdrs/<run>/` directory back-resolves to the plan whose `exec_runs` names it → plan mode.
   - No argument → all of `${CODE_NAME}/`.
   - Nothing matches → list the nearest plan and path candidates and ask one direct question.
3. Plan-mode scope is the union of: code modules named in §2, code paths among the §4 deliverables, and files `wkdrs/<run>/EXEC_LOG.md` records as changed. Name which source contributed which files; a §2/§4 path that does not exist is already a finding (dimension F), never a silent skip. When that log records an execution branch (`branch:` — conventions §11), the branch's own diff is the sharper code-side list: add the files of `git diff --name-only <base>...HEAD` to the union, and record the branch and its head commit in the report's scope line — the merge confirmation point waits on this review's verdict.
4. Trim to reviewable source: Python files get the full rubric; shell / YAML / config files in scope are checked for dimension D only (paths & runtime); `datas/`, `inits/`, `wkdrs/` artifacts and generated files are out of scope. State the final file count before reviewing; above ~50 files, run Step 2's whole-tree screen first — it is grep and `wc`, and needs no environment — then say so and offer to narrow (one sub-package, or diff mode) with one direct question. An offer that asks the user to guess a sub-package is a worse offer.

### Step 1: Load the review rules

Read AGENTS.md; `metds/codearc.md` if present (placement rules, naming conventions, plan-component map, §7 do-not-rename list); in plan mode the plan §1–§6 plus `EXEC_PLAN.md` / `EXEC_LOG.md`. Record which review rules are absent — without codearc.md, placement and naming checks fall back to PEP 8 plus the upstream style of the surrounding code (AGENTS.md §3). Then assemble the **review rule digest** defined in `references/review_rubric.md` (it arrived with the **Shared conventions** opening load — no separate read): the one block Step 3 hands to every collector verbatim.

### Step 2: Cheap static evidence

Through the `.env` conda env: run `python -m compileall -q` over the scope, always. If ruff (preferred) or flake8 is already installed in that env, run it on the scope and keep the output as evidence input. Never install or upgrade anything (that is `$star-env-builder`'s). Env unusable → skip the tools, mark the review **reading-only** in the report, recommend `$star-env-builder`.

**Whole-tree screen**, run over all of `${CODE_NAME}/` whatever the reviewed scope is, and whether or not the environment works — it needs only grep and `wc`, and a review that could not run its tools is exactly the one that needs these found. Two of the rubric's always-blocker classes become invisible the moment the scope narrows, and narrowing is the normal outcome:

- `grep -rnE` for machine-local path literals (`/Users/`, `/home/`, `C:\\`). Every hit is a candidate blocker (dimension D).
- A **presence** check per `codearc.md` §7 residual name: a count that has dropped to zero is the finding. §7 lists names that are supposed to still be there, so a grep for hits returns the places they correctly remain — the non-findings.
- `wc -l` across the tree, longest first, keeping the top ~20, to name dimension-C giant-file candidates. The other two probes stop at their hits; this one would list every file in the tree, which is why it is cut off at 20.

It is grep and `wc`, never a tree-wide linter run: a repo-wide `ruff check` is thousands of lines entering the report's own context, which is context inflation dressed as a screen. A screen hit is re-opened at its line by the main agent before it enters the report (Step 4), and one outside the reviewed files is filed with `found by screen, outside reading scope`.

### Step 3: Collect findings

- **Collection is always delegated, whatever the scope size.** By the time this command runs the main agent's context is not a neutral reader of this code: it has been discussing it, and where earlier turns of this conversation wrote or edited files now in scope it rereads its own code through the reasoning that produced it. An explorer's context saw neither, which is the point — so the main agent never collects findings itself, and the report's scope line records how many explorers ran and how the files were split between them, plus, when the session wrote files in scope, that the code was written in this session.
- **How many is the main agent's call**, sized to the work (conventions §6.2): read-only explorers, called with `spawn_agent` and `agent_type: explorer`, run in parallel, each given the rubric, the review rule digest built at Step 1 — the same block, verbatim, for all of them — and its exact file list, returning the structured finding contract in `references/review_rubric.md`. Read-only explorers never write, never review outside their file list, never grade the overall verdict. The number to size against: one explorer carries a scope up to the ~50 files where Step 0 already offers to narrow; past that, partition package by package, in groups of 10–15 files, so a 60-file tree goes to four or five explorers and not to sixty. Either side of that is the main agent's to take once it can say why — a package that hangs together and runs a little long stays whole rather than being cut to hit a group size.
- **Dispatch is automatic; no approval is asked for it.** Running this command is the request for these explorers — Step 3 is where this skill says it dispatches, whether the user typed its name or the agent picked the skill up on a task that plainly matched (conventions §10.2) — so a standing instruction conditioned on the user having asked is satisfied here. The involve level moves nothing either: at `high` the fan-out is announced with its partition before it goes out, never put to a question (conventions §6.8). Two things stop it, and no preference is among them: a standing instruction that bans delegation outright, or a host that offers no delegation at all. Then, and only then, ask once for this dispatch rather than falling back silently, because collection run inside the context being audited is not the independent read this step exists for (conventions §6.1; §6.7 — the second opinion a main agent cannot give itself). Declined or unavailable, the main agent fills the same contract locally, package by package, and the scope line records instead that no independent explorer read the code.
- **Plan mode adds dimension F** (kept with the main agent — it needs the plan context): the §3 task-to-code map, §4 deliverables on disk, §5 support, and the EXEC_LOG-vs-code cross-check.

### Step 4: Verify

Account for every file first: each file dispatched comes back either in a collector's `files_reviewed` count or in its `unknowns` list, and whatever is missing is re-dispatched together with the unknowns (conventions §6.3) — a file nobody could parse must not pass for a clean one. Then merge and dedup. For every blocker/major: re-open the cited file at the cited lines and confirm the issue is real and the rule applies, whatever `confidence` the collector attached — a `low` on a blocker is a reason to read it, not a reason to take it less seriously. Downgrade or drop what fails; a `low` finding the re-read cannot settle goes to Unconfirmed. Spot-check minors. Findings worth flagging but not confirmed go to the report's **Unconfirmed** list — never into the verdict counts.

### Step 5: Persist the report

Fill `assets/code_review_template.md` (Chinese: `assets/code_review_template_zh.md`; the report follows the plan's `language` in plan mode, else the dialogue language): scope & evidence base, verdict, findings by severity (`blocker` / `major` / `minor` / `nit`, numbered F1, F2, …), the plan-conformance scorecard (plan mode), good practices (≤3), next actions. Write to `wkdrs/<run>/CODE_REVIEW_<YYYY-MM-DD>.md` when plan mode has a run; else `wkdrs/reviews/code_<scope-slug>_<YYYY-MM-DD>.md` (`scope-slug` = plan prefix+slug, the path with `/`→`-`, `diff`, or `full`). Real dates only, never invented.

### Step 6: Digest in chat

Lead with the verdict, under about 500 words: files reviewed, counts per severity, top ≤10 findings as one-liners (`file:line — issue`), the conformance verdict (plan mode), which static tools ran. End with the routing for findings outside what this skill may write (`$star-plan-executor` / `$star-plan-reviser` / `$star-code-architect`), then offer the fix pass if mechanical findings exist — the user may also stop here; the persisted report is a complete deliverable on its own.

### Step 7: Optional fix pass (mechanical only)

1. **Eligible**: missing or incomplete docstrings; renames whose references all live inside the reviewed scope; unused imports; dead code this project introduced (upstream-inherited dead code is reported, never deleted — AGENTS.md §3); comment fixes the rubric flagged. **Ineligible**: anything touching behavior, signatures used outside the scope, files outside the scope, or names on the do-not-rename list.
2. Walk the eligible findings in report order, one direct question at a time — *apply as proposed* / *apply adjusted* / *skip*, recommendation marked, one finding per question. More than 4 same-type findings (e.g. 12 missing docstrings) may be batched into one question: *apply all* / *select which (name the numbers)* / *skip all*.
3. Apply each approved fix; after each touched file re-run `compileall` on it (plus ruff when available), and for renames grep the old symbol across `${CODE_NAME}/` to prove no stale references remain. A failed re-check → revert that fix, mark it `reverted`, continue.
4. Append the fix record to the report (`F<n> — applied / skipped / reverted`). If the working tree was clean at Step 0, ask one final question: commit the fixes (stage only the files this pass touched; message `star-code-reviewer: apply review fixes — <scope>`) or leave them uncommitted. With a dirty tree, leave them uncommitted and say so.
5. Close with what was applied, skipped, and routed, plus the report path.

## State & File Rules

- Reports live under `wkdrs/` (the plan's run dir, else `wkdrs/reviews/`); never under `metds/plans/`, never inside `${CODE_NAME}/`.
- The only code writes are individually approved fix-pass items inside the reviewed scope. Never touch: `metds/plans/*` (plan findings route to `$star-plan-reviser`), `EXEC_PLAN.md` / `EXEC_LOG.md`, `UPSTREAM.md`, `LICENSE` / `CITATION*`, `metds/codearc.md`, `.env`.
- Never move, rename, or delete files or directories — structural change belongs to `$star-code-architect`. Names on the do-not-rename list are flagged, never renamed.
- All commands run through `.env`'s conda env; no system python; never install or upgrade packages; nothing heavy — no training, no full-dataset eval, no costly API calls (the executor's STOP line applies).
- Git: read-only, plus the single optional fix commit staging only fix-pass files (conventions §1). On a run's execution branch that commit lands on the branch, ahead of its merge (conventions §11); this skill still never switches branches.
- This skill sets no plan frontmatter and creates no run directories; its audit trail is the report file plus the fix commit when one was made.

## Dialogue Discipline

- Ask fix-pass approvals one at a time and require an explicit answer before any write. The report follows the plan's frontmatter `language` in plan mode, else the dialogue language.
