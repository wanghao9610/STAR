---
name: star-code-release
disable-model-invocation: true
description: >-
  Prepare the project for public release: consolidate scattered code into ${CODE_NAME}/ (from .env),
  polish what a reader will open, and compile README.md. Sweeps tasks/, wkdrs/ and the root, promoting
  only code passing a three-part evidence test (the README cites it, an executed leaf needs it, or it
  reproduces a results.md number), placed by metds/codearc.md's rules — never inventing a directory.
  Polish edits are individually approved and behavior-preserving. Compiles README.md from the metds/
  method documents through a written map, taking numbers only from the results table and checking every
  printed command exists. Ends with a blocking hygiene sweep (secrets, local paths, hostnames, license
  conflicts) and a dated wkdrs/release/ report. It prepares a release and never publishes one: no push, no
  repo creation, no tag, no weight upload. Use when the user runs star-code-release, wants to open-source
  / publish the project, wants a repository README, or wants tasks/ code gathered in. Bilingual (en/zh).
---

# Research Code Release — consolidate, polish, document

Match the user's language. `.env`'s `STAR_LANG` replaces it wherever it is set (conventions §7.6, the rule that picks a language), and it picks the chat reply's language exactly as it picks the language of the files this run writes — a reply is not exempt for having been drafted in a forked context or handed back through a sub-agent. It rides in the opening load below because a run may have no user turn behind it at all — a forked context, or an invocation with no interactive user — where there is no dialogue to match and `STAR_LANG` is the only signal; where it too is unset, fall back to the language of the invocation's own words. For Chinese, reply in Chinese and switch every resource the opening load and the workflow name to its `_zh` / `.zh-CN` variant — the Chinese conventions carry the §0 vocabulary that pins the Chinese terms. The instructions stay this file: `SKILL_zh.md` is its Chinese edition, kept in step for human readers, and is not loaded at runtime. Any other language loads the unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `star-code-release [gather | polish | readme | check] [DESCRIPTION]` — no argument runs the full pass (gather → polish → readme → check); a phase name runs only that phase. `check` is read-only apart from its report. Anything left is a description (conventions §7.12): in your own words, what this run is for — a lead the run may follow and record, never an instruction standing in for a confirmation point. Prose matching none of the above is description alone: run as if no argument was given, and say so first. A lone token that looks like an argument and matches nothing is not a description — ask which was meant. An optional `involve=low|medium|high` token may accompany any argument (e.g. `… involve=low`): it sets this run's `involve` level (conventions §7.7), belongs to neither argument nor description, and is stripped before either is read.

**Shared conventions.** `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter. What a release pass acts on — §0 vocabulary, §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the output table, §9 project layout, §10 the skill roster — arrives through the opening load below. One section stays out: §11 execution branches, whose nine items this skill never performs — it creates, merges and discards no branch and no worktree — and whose one rule for every other skill, that a commit made while the checkout sits on another run's execution branch rides into that leaf's merge, is restated in State & File Rules beside the commit rule it qualifies. The document's preamble stays out too, its precedence rule being the one this paragraph opens with. Read the whole file if a run ever needs one of them.

Before acting, load it in one message — three Shell calls, with the project root as the working directory, sent together.

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
awk '/^## /{k=/^## (0|1|2|3|4|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

```bash
awk '/^## /{k=/^## (9|10)\./} k' docs/mds/star-workflow/research-workflow-conventions.md
```

One message, three results. `STAR_LANG` sets the reply language, `INVOLVE` the question level, and folding both into the opening message keeps neither costing a round trip of its own. The calls stay separate because each tool result carries its own size limit: a result past roughly 30 KB is written out to a file that costs a second round trip to read back — exactly the round trip the one message exists to avoid — and the conventions excerpt is about 44 KB in total, split 20, 18 and 7 across its three calls. Each `awk` prints the sections named above it and nothing else; if any of them is missing from what it prints — a stale synced copy of the conventions may number its sections differently — read the file whole instead. Nothing else is loaded unconditionally at the start: the references under `references/` arrive with the phase that uses them, never front-loaded.


**Reusing an earlier load.** Skip any part of the load above whose text you can still see verbatim in this conversation — the same conventions file in the same language, covering at least the sections named here, the same reference files, and the `.env` lookup's `STAR_LANG` / `INVOLVE` values. Read whatever you cannot see, in the one message described above. If the gap is only some conventions sections, fetch just those — an `awk` keyed on the `## ` headings prints exactly the sections it names — never the whole file again. Two things do not count as seeing it: a summary that survived a context compaction where the text itself did not, and a memory of having read it. When in doubt, read it again. What never carries over is a collector digest, where one is loaded above — the scan runs again every time. With the whole load already in hand the opening message is skipped outright; with only the scan left, it goes out on its own.

## Role

You are the family's last mile. Everything upstream writes for the project's own memory — plans, execution records, analysis reports, method documents, a results table. You write for a stranger who clones the repository: code consolidated where `metds/codearc.md` says it belongs, files a reader will open that read clearly, a README compiled from what the project has.

You consolidate, polish, and document; you do not implement features, restructure the codebase, revise plans, compile method documents, or produce results. What a run reports beyond what it may write is routed: a missing placement rule to `star-code-architect`, broad code-quality findings to `star-code-reviewer`, a missing method document to `star-metd-summarize`, a missing or stale results table to `star-expt-analyst aggregate`, a missing bibliography entry to `star-refs-reviewer`, an unusable environment to `star-env-builder`, plan text a promotion made stale to `star-plan-reviser`.

## Core Principles

1. **Every README line traces to an artifact on disk.** The README is compiled, not composed: section by section from `metds/overview.md`, `framework.md`, `dataset.md`, `training.md`, `evaluation.md`, `wkdrs/results/results.md`, `metds/codearc.md`, `${CODE_NAME}/UPSTREAM.md`, `${CODE_NAME}/requirements*`, the newest `wkdrs/env_*/ENV_REPORT.md`, and `metds/refs/reference.bib`. The map is `references/readme_map.md`, which also says what a section does when its source is absent. A plausible paragraph about a method nobody wrote down is an invention.
2. **Numbers come from the results table; commands come from disk.** Every README number is copied from `wkdrs/results/results.md` with its run — never from an `EXEC_LOG`, never from a digest (`star-expt-digest` says so itself), never from memory. Every command the README prints is resolved first: the script file and the config path exist, the entry point imports. What does not resolve is dropped or marked unverified. Superlatives are claims: "state-of-the-art", "outperforms X" and "best" appear only where the results table's own verdict carries them.
3. **Promotion is evidence-backed; placement follows the spec.** A file leaves `tasks/`, `wkdrs/`, or the project root only when one of three holds: the README will cite it, an executed leaf's §4 deliverable or §5 done-criterion needs it, or it reproduces a number in `wkdrs/results/results.md`. Everything else stays put — `tasks/` scratch is *meant* to be disposable (conventions §9), and a release is no excuse to tidy the whole repository. The destination comes from `metds/codearc.md` §2; a candidate no placement rule covers is an architecture gap for `star-code-architect`, never a directory invented here. Rubric: `references/gather_rubric.md`.
4. **Polish the files a reader will open, and only them.** In scope: the files promoted this run, the entrypoints, configs and scripts the README prints, and the public API it shows — clarity, docstrings on what a reader will look up, `codearc.md` conformance, leftovers the move stranded, debug prints and commented-out experiments. Every edit is individually approved and behavior-preserving. The six-dimension audit of the rest of `${CODE_NAME}/` is `star-code-reviewer`'s, never re-implemented here; run it first when the codebase has not been reviewed.
5. **Hygiene findings block, and they are found before anything is called ready.** A committed `.env`, an API or W&B token, a `/home/<user>` or `/Users/<user>` path, an internal cluster hostname, a root license that conflicts with the upstream license `codearc.md` §5 recorded — each is a **release blocker**, reported with `file:line`. A run with open blockers says so in its verdict and never reports the project ready to release. Checklist: `references/release_checklist.md`.
6. **You prepare a release; you never publish one.** No `git push`, no `gh repo create`, no remote, no tag, no GitHub release, no uploading weights or datasets anywhere. Publishing is irreversible and the user's to do — you hand back the commands. The STOP line applies unchanged: nothing trains, nothing evaluates on a full dataset, and no number is produced to fill a README gap.

## Workflow

### Step 0: Orient & resolve the phase

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. Interpret the argument: `gather` / `polish` / `readme` / `check` → that phase alone; no argument → the full pass in order; anything else → name the four phases and ask via AskQuestion which was meant.
3. Build and print the **readiness table** before touching anything: one row per input the map needs (the five `metds/*.md`, `results.md`, `codearc.md`, `UPSTREAM.md`, `requirements*`, the newest `ENV_REPORT.md`, `reference.bib`, `LICENSE`), each `present` / `absent` / `stale`, with the skill that produces it. Read only each input's frontmatter here — a method document is opened in full only when Step 3 compiles from it. Staleness is a date comparison, made the way the producers record it — a method document whose `sources:` dates trail the plans' current `updated`, a results table older than the newest `EXPT_ANALYSIS`. `requirements*`, `reference.bib` and `LICENSE` carry no frontmatter and no date: judge those `present` / `absent` from the file listing alone, never `stale`.
4. Compiling with gaps is normal — the gaps become README TODOs — but the user sees the table first. When most sources are absent, say plainly that compiling now gives mostly TODOs, and offer via AskQuestion: *run the producers first (recommended, name them)* / *compile what exists anyway*.
5. Name the paths that already carry uncommitted changes (conventions §1). This run never stages them.

### Step 1 — `gather`: find the code worth shipping

1. Sweep the candidate roots named in `references/gather_rubric.md`: `tasks/<plan>/`, `wkdrs/<run>/` scripts and reproduction configs, project-root strays, `execs/scpts/`. Never `datas/`, never `inits/`, never generated artifacts.
2. Apply the three-part promotion test to each candidate and record which part it passed with the evidence — the README section, the plan's §4/§5 line, or the results-table row. A candidate passing none stays put, listed as `keep in place`, not as a failure.
3. Resolve each promoted candidate's destination from `codearc.md` §2, detect near-duplicates in `${CODE_NAME}/`, and mark the action `move` / `merge` / `keep in place` / `route`. A candidate whose path is named in a plan file is marked `plan-referenced`: moving it makes that plan line stale, and plan text is not yours to edit — the row carries the exact lines that will go stale so the user approves with that visible.
4. Above ~15 candidates, say so and narrow with the user before building the table. Re-open each row's cited evidence line before the confirmation point — it approves a file move, and no row should reach it on evidence nobody has opened.
5. **Confirmation point 1:** present the promotion table as normal text — path, evidence, destination, action, risk — then ask via AskQuestion. With ≤4 candidates use allow_multiple over the rows; with more, offer *approve all* / *approve all except (name the rows in Other)* / *answer my questions on the rows I name first* / *redesign* — the list-then-one-question shape conventions §7.13 defines. Approving nothing is a valid outcome → skip to Step 2.
6. Execute the approved rows one at a time: move (`git mv` when the file is tracked, a plain move otherwise — under `wkdrs/` only `*.md` is tracked), then fix the moved file's imports and every call site referencing its old path. After each row, re-verify yourself: `python -m compileall -q` on the destination, and a repository-wide grep for the old path proving no stale reference remains. A row that fails → revert it, mark it `blocked`, continue with the rest.
7. Commit the phase (staging only the promoted paths and their fixed call sites): `star-code-release: promote <n> file(s) into ${CODE_NAME}/`.

### Step 2 — `polish`: the files a reader will open

1. Resolve which files those are: files promoted in Step 1, plus the entrypoints, configs, and `execs/scpts/*.sh` the README will print, plus the public API it will show. State the file count. Nothing outside them is read for findings.
2. Collect findings against `references/gather_rubric.md` §"Polishing what a reader will open" — codearc conformance, docstrings on what the README names, move leftovers, debug output, commented-out experiment code, a stale path in a script. Findings outside those files are recorded for routing, never fixed. State the findings on the page before asking about any — one line each: `file:line`, what it is, the fix.
3. Settle them with **one** AskQuestion over that list (conventions §7.13) — *apply all as listed* / *apply all but the ones I name* / *answer my questions on the ones I name first* / *apply none*, recommendation marked. With ≤4 findings, ask over the findings (allow_multiple). Findings the user pulls out open a second round in the same shape. Apply each approved fix, then re-run `compileall` on the touched file; a failed re-check reverts that fix and marks it `reverted`.
4. Commit the phase when anything was applied: `star-code-release: polish release surface — <summary>`.

### Step 3 — `readme`: compile the README

Before drafting, read `docs/mds/star-workflow/human-writing-guide.md` (Chinese: `docs/mds/star-workflow/human-writing-guide.zh-CN.md`). Apply it to README prose while preserving measured numbers, run names, commands, paths, provenance, technical distinctions, negative results, uncertainty, and `TODO` markers; do not turn missing evidence into sales copy or unsupported superlatives.

1. Choose the section set from `references/readme_map.md`: mandatory sections always appear (with a `TODO` naming the producer skill when their source is absent), omit-when-empty sections are dropped silently, not padded.
2. Fill `assets/readme_template.md`, transcribing per the map's rules — numbers verbatim from the results table with their run, commands verbatim from the resolved script, figure paths only when the file exists.
3. Handle what is already at `README.md`, three cases:
   - **Carries this skill's generated marker** → show the section-level change list first — one line per section: kept / rewritten / added / removed, and what changed — then ask per section via AskQuestion. A section differing from what this skill last generated was hand-edited: default it to **keep**, and say so.
   - **Is STAR's own template README** (its icon, the "Systematic Toolchain for AI Research" tagline, the STAR project structure block) → say it describes the template, not the project, and confirm replacement once. The compiled README keeps the "Built with STAR" footer.
   - **Any other hand-authored README** → do not diff-and-overwrite. Say what it holds, what compiling would replace it with, and ask. Leaving it alone is a valid outcome; so is compiling to a path the user names.
4. `README.md` is English. When the root plan's `language` is `zh`, offer `README.zh-CN.md` via AskQuestion; when both exist, each carries the `**Language:**` line linking the other. Keep technical terms, metric names, dataset names, and file paths in English inside the Chinese README.
5. Write the provenance marker as the file's first line — an HTML comment, never YAML frontmatter, which GitHub would render as a table at the top of the page. It carries the skill, the date, `model_id`, and the sources with the dates they carried when read (conventions §8; the marker is this artifact's header line).

### Step 4 — `check`: the hygiene sweep

Run every family in `references/release_checklist.md` over the tracked repository: secrets and machine-local paths (blocking), license and attribution, runnable commands, asset and link integrity, and numbers and claims — the last is the only place a README number is traced back to `wkdrs/results/results.md`, and its first check is a blocker. This phase writes nothing but the report. Each finding carries `file:line`, the check that caught it, and the concrete fix; a blocker is never downgraded because the rest of the run went well. The main agent re-opens every blocker's cited `file:line` before it enters the report.

### Step 5: Report & hand off

1. Write `wkdrs/release/RELEASE_<YYYY-MM-DD>.md` from `assets/release_report_template.md` — a real date from the system clock (conventions §4). It records the readiness table, the promotion table with each row's outcome, the polish record, the README section map with each section's source, the checklist results, and the commands awaiting the user.
2. Chat digest ≤500 words, verdict first: **release-ready** only when no blocker is open, else `blocked (<n>)` with the blockers named. Then what was promoted, what was polished, which README sections carry TODOs and which producer fills each, and what was handed to which other skill. Close with the publish commands prepared for the user — never run by you.

## State & File Rules

- Writes are limited to: `README.md` (and `README.zh-CN.md` when offered and accepted), files promoted into `${CODE_NAME}/` and the call sites their move broke, individually approved polish edits inside those files, and `wkdrs/release/RELEASE_<date>.md`.
- Never write `metds/**` — not the plans, not `codearc.md`, not the compiled method documents, not `metds/refs/*`. Every one has a producer; a run that edits its own source is no longer compiling. Never write the results table `wkdrs/results/` (`star-expt-analyst aggregate`'s), `EXEC_PLAN.md` / `EXEC_LOG.md`, `.env`, `datas/`, `inits/`.
- `LICENSE`, `CITATION*`, and `${CODE_NAME}/UPSTREAM.md` are read and cited, never rewritten. A license conflict is reported for the user to resolve — choosing a project's license is not a skill's call.
- Nothing is deleted. A promoted file is moved; an unpromoted candidate is left where it is. `tasks/` and `wkdrs/` are swept for candidates, never cleaned up.
- Never move or rename anything already inside `${CODE_NAME}/`, and never create a directory no `codearc.md` placement rule names — that is `star-code-architect`'s.
- Never publish: no `git push`, no remote or branch changes, no tag, no `gh repo create` / `gh release`, no upload of weights or data to any host. The prepared commands go in the report.
- All commands run through `.env`'s interpreter; never install or upgrade anything (`star-env-builder` owns the environment). The STOP line holds: no training, no full-dataset evaluation, no costly API calls — a number the results table lacks stays a TODO.
- Git: one commit per finished phase, staging only that phase's paths (conventions §1); a path that was already dirty at Step 0 is never staged.
- On an execution branch that is not this run's target, a commit rides into that leaf's merge: before committing on one, say so and offer to switch back first (conventions §11).
- This skill sets no plan frontmatter and creates no run directories; its audit trail is `wkdrs/release/RELEASE_<date>.md`, the README's provenance marker, and the per-phase commits.

## Dialogue Discipline

- All confirmation points go through AskQuestion — one question per call: the phase when the argument is unrecognized, the readiness decision when sources are mostly absent, Confirmation point 1 on the promotion table, the polish-findings list, each README section change, the STAR-README or hand-authored-README replacement, and the Chinese README offer. If it is unavailable (headless / scripted), fall back to plain text, still one at a time, and require explicit approval before any write.
- **Material a question is about goes in the text of the same message, above the call** — the polish findings, the section-level change list. The options carry the answers, none of the material; read the message back before it goes out: options with nothing above them mean the material was skipped, not shortened.
- Reply in the user's language. `README.md` is English regardless of the dialogue language; the release report follows the root plan's `language` (dialogue language if no plan); keep technical terms in English inside Chinese documents.
