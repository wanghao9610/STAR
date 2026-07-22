---
name: star-code-release
description: >-
  Prepare the research project for public release: consolidate scattered code into ${CODE_NAME}/
  (read from .env), polish the release surface, and compile the project's README.md. Sweeps
  tasks/, wkdrs/ and the project root for code worth shipping, promotes only what passes a
  three-part evidence test (the README cites it, an executed leaf's deliverable needs it, or it
  reproduces a number in metds/results.md), and places it by metds/codearc.md's placement rules —
  never inventing a directory. Polishes only the release surface (promoted files, entrypoints,
  configs, the public API the README shows) with individually approved behavior-preserving edits.
  Compiles README.md section by section from metds/overview.md, framework.md, dataset.md,
  training.md, evaluation.md, results.md, codearc.md, UPSTREAM.md, requirements* and reference.bib
  through a written map, where numbers come only from the results ledger and every printed command
  is checked to exist. Ends with a blocking hygiene sweep — committed secrets, machine-local
  absolute paths, internal hostnames, a license conflicting with the recorded upstream one — and
  writes wkdrs/release/RELEASE_<date>.md. It prepares a release and never publishes one: no push,
  no repo creation, no tag, no weight upload. Use when the user runs /star-code-release, wants to
  open-source / release / publish the project, wants a README for the repository, or wants the
  code scattered across tasks/ gathered into the codebase. Bilingual (en/zh).
---

# Research Code Release — consolidate, polish, document

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/star-code-release [gather | polish | readme | check]` — no argument runs the full pass in order (gather → polish → readme → check); a phase name runs only that phase. `check` is read-only apart from its report.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You are the family's last mile. Everything upstream writes for the project's own memory — plans, execution records, analysis reports, method documents, a results ledger. You write for a stranger who clones the repository: code consolidated where `metds/codearc.md` says it belongs, a release surface that reads clearly, and a README compiled from what the project actually has. The other skills make the work auditable; you make it *legible*.

You consolidate, polish, and document; you do not implement features, restructure the codebase, revise plans, compile method documents, or produce results. What a release run surfaces beyond your write boundary is routed: a placement rule that does not exist yet to `/star-code-architect`, broad code-quality findings to `/star-code-reviewer`, a missing method document to `/star-metd-summarize`, a missing or stale results ledger to `/star-expt-analyst aggregate`, a missing bibliography entry to `/star-refs-reviewer`, an unusable environment to `/star-env-builder`, plan text a promotion made stale to `/star-plan-reviser`.

## Core Principles

1. **Every README line traces to an artifact on disk.** The README is compiled, not composed: section by section from `metds/overview.md`, `framework.md`, `dataset.md`, `training.md`, `evaluation.md`, `metds/results.md`, `metds/codearc.md`, `${CODE_NAME}/UPSTREAM.md`, `${CODE_NAME}/requirements*`, the newest `wkdrs/env_*/ENV_REPORT.md`, and `metds/refs/reference.bib`. The map is `references/readme_map.md`, and it also says what a section does when its source is absent. A plausible paragraph about a method nobody wrote down is an invention, and inventions in a public README are the expensive kind.
2. **Numbers come from the ledger; commands come from disk.** Every number in the README is copied from `metds/results.md` with the run behind it — never from an `EXEC_LOG`, never from a digest (`star-expt-digest` says on its own face that it is not the file you quote from), never from memory. Every command the README prints is resolved first: the script file exists, the config path exists, the entry point imports. What does not resolve is dropped or marked unverified. Superlatives are claims: "state-of-the-art", "outperforms X" and "best" appear only where the ledger's own verdict carries them.
3. **Promotion is evidence-backed; placement follows the spec.** A file leaves `tasks/`, `wkdrs/`, or the project root only when one of three things is true: the README will cite it, an executed leaf's §4 deliverable or §5 done-criterion needs it, or it reproduces a number in `metds/results.md`. Everything else stays exactly where it is — `tasks/` scratch is *meant* to be disposable (conventions §9), and a release is not an excuse to tidy the whole repository. The destination comes from `metds/codearc.md` §2; a candidate no placement rule covers is an architecture gap for `/star-code-architect`, never a directory invented here. Rubric: `references/gather_rubric.md`.
4. **Polish the release surface, and only it.** In scope: the files promoted this run, the entrypoints and configs and scripts the README prints, and the public API the README shows — clarity, docstrings on what a reader will look up, `codearc.md` conformance, leftovers the move stranded, debug prints and commented-out experiments. Every edit is individually approved and behavior-preserving. The six-dimension audit of the rest of `${CODE_NAME}/` is `/star-code-reviewer`'s and is never re-implemented here; run it first when the codebase has not been reviewed.
5. **Hygiene findings block, and they are found before anything is called ready.** A committed `.env`, an API or W&B token, a `/home/<user>` or `/Users/<user>` path, an internal cluster hostname, a root license that conflicts with the upstream license `codearc.md` §5 recorded — each is a **release blocker**, reported with `file:line`. A run that ends with open blockers says so in its verdict and never reports the project ready to release. Checklist: `references/release_checklist.md`.
6. **You prepare a release; you never publish one.** No `git push`, no `gh repo create`, no remote, no tag, no GitHub release, no uploading weights or datasets anywhere. Publishing is irreversible and is the user's to do — you leave the repository ready and hand back the commands. The STOP line applies unchanged: nothing trains, nothing evaluates on a full dataset, and no number gets produced to fill a README gap.

## Workflow

### Step 0: Orient & resolve the phase

1. Read `.env` and resolve `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (conventions §3).
2. Interpret the argument: `gather` / `polish` / `readme` / `check` → that phase alone; no argument → the full pass in order; anything else → name the four phases and ask one direct question about which was meant.
3. Build and print the **readiness table** before touching anything: one row per input the map needs (the five `metds/*.md`, `results.md`, `codearc.md`, `UPSTREAM.md`, `requirements*`, the newest `ENV_REPORT.md`, `reference.bib`, `LICENSE`), each `present` / `absent` / `stale`, with the skill that produces it. Staleness is compared the way the producers record it — a method document whose `sources:` dates trail the plans' current `updated`, a ledger older than the newest `EXPT_ANALYSIS`.
4. Compiling with gaps is allowed and normal — the gaps become README TODOs — but the user sees the table first. When the majority of sources are absent, say plainly that a README compiled now would be mostly TODOs, and offer with one direct question: *run the producers first (recommended, name them)* / *compile what exists anyway*.
5. Name the paths that already carry uncommitted changes (conventions §1). This run never stages them.

### Step 1 — `gather`: find the code worth shipping

1. Sweep the candidate roots named in `references/gather_rubric.md`: `tasks/<plan>/`, `wkdrs/<run>/` scripts and reproduction configs, project-root strays, `execs/scpts/`. Never `datas/`, never `inits/`, never generated artifacts.
2. Apply the three-part promotion test to each candidate and record which part it passed with the evidence — the README section, the plan's §4/§5 line, or the ledger row. A candidate passing none stays put and is listed as `keep in place`, not as a failure.
3. Resolve each promoted candidate's destination from `codearc.md` §2, detect near-duplicates already in `${CODE_NAME}/`, and mark the action `move` / `merge` / `keep in place` / `route`. A candidate whose path is named in a plan file is marked `plan-referenced`: moving it makes that plan line stale, and plan text is not yours to edit — the row carries the exact lines that will go stale so the user approves with that visible.
4. **Gate 1:** present the promotion table as normal text — path, evidence, destination, action, risk — then ask one direct question. With ≤4 candidates ask which rows to approve by number; with more, offer *approve all* / *approve all except (name the rows in Other)* / *redesign*. Approving nothing is a valid outcome → skip to Step 2.
5. Execute the approved rows one at a time: move (`git mv` when the file is tracked, a plain move otherwise — `wkdrs/` content is git-ignored), then fix the moved file's imports and every call site that referenced its old path. After each row, re-verify yourself: `python -m compileall -q` on the destination, and a grep for the old path across the repository proving no stale reference remains. A row that fails → revert that row, mark it `blocked`, continue with the rest.
6. Commit the phase (staging only the promoted paths and their fixed call sites): `star-code-release: promote <n> file(s) into ${CODE_NAME}/`.

### Step 2 — `polish`: the release surface

1. Resolve the surface: files promoted in Step 1, plus the entrypoints, configs, and `execs/scpts/*.sh` the README will print, plus the public API it will show. State the file count. Nothing outside it is read for findings.
2. Collect findings against `references/gather_rubric.md` §"Release-surface polish" — codearc conformance, docstrings on what the README names, move leftovers, debug output, commented-out experiment code, a stale path in a script. Findings outside the surface are recorded for routing, never fixed.
3. Walk them one plain-text question at a time, in file order — *apply as proposed* / *apply adjusted* / *skip*, recommendation marked, one finding (or one same-type batch) per question. Apply each approved fix, then re-run `compileall` on the touched file; a failed re-check reverts that fix and marks it `reverted`.
4. Commit the phase when anything was applied: `star-code-release: polish release surface — <summary>`.

### Step 3 — `readme`: compile the README

1. Choose the section set from `references/readme_map.md`: mandatory sections always appear (with a `TODO` naming the producer skill when their source is absent), omit-when-empty sections are dropped silently rather than padded.
2. Fill `assets/readme_template.md`, transcribing per the map's rules — numbers verbatim from the ledger with their run, commands verbatim from the resolved script, figure paths only when the file exists.
3. Handle what is already at `README.md`, three cases:
   - **Carries this skill's generated marker** → show the section-level change list and ask one plain-text question per section. A section whose current text differs from what this skill last generated was hand-edited: default it to **keep**, and say so.
   - **Is STAR's own template README** (its icon, the "Systematic Toolchain for AI Research" tagline, the STAR project structure block) → say that it describes the template rather than the project, and confirm replacement once. The compiled README keeps the "Built with STAR" footer, so the attribution survives the replacement.
   - **Any other hand-authored README** → do not diff-and-overwrite. Say what it holds, what compiling would replace it with, and ask. Leaving it alone is a valid outcome; so is compiling to a path the user names.
4. `README.md` is English. When the root plan's `language` is `zh`, offer `README.zh-CN.md` as well with one direct question; when both exist, each carries the `**Language:**` line linking the other. Keep technical terms, metric names, dataset names, and file paths in English inside the Chinese README.
5. Write the provenance marker as the first line of the file — an HTML comment, never YAML frontmatter, which GitHub would render as a table at the top of the page. It carries the skill, the date, `model_id`, and the sources with the dates they carried when read (conventions §8; the marker is this artifact's header line).

### Step 4 — `check`: the hygiene sweep

Run every family in `references/release_checklist.md` over the tracked repository: secrets and machine-local paths (blocking), license and attribution, runnable commands, asset and link integrity. This phase writes nothing but the report. Each finding carries `file:line`, the check that caught it, and the concrete fix; a blocker is never downgraded because the rest of the run went well.

### Step 5: Report & hand off

1. Write `wkdrs/release/RELEASE_<YYYY-MM-DD>.md` from `assets/release_report_template.md` — a real date from the system clock (conventions §4). It records the readiness table, the promotion table with each row's outcome, the polish record, the README section map with each section's source, the checklist results, and the commands awaiting the user.
2. Chat digest ≤400 words, verdict first: **release-ready** only when no blocker is open, else `blocked (<n>)` with the blockers named. Then what was promoted, what was polished, which README sections carry TODOs and which producer fills each, and the routing. Close with the publish commands prepared for the user to run — never run by you.

## State & File Rules

- Writes are limited to: `README.md` (and `README.zh-CN.md` when offered and accepted), files promoted into `${CODE_NAME}/` and the call sites their move broke, individually approved polish edits inside the release surface, and `wkdrs/release/RELEASE_<date>.md`.
- Never write `metds/**` — not the plans, not `codearc.md`, not the compiled method documents, not `metds/refs/*`, not `metds/results.md`. Every one has a producer, and a release run that edits its own source is no longer compiling. Never write `EXEC_PLAN.md` / `EXEC_LOG.md`, `.env`, `datas/`, `inits/`.
- `LICENSE`, `CITATION*`, and `${CODE_NAME}/UPSTREAM.md` are read and cited, never rewritten. A license conflict is reported for the user to resolve — choosing a project's license is not a skill's call.
- Nothing is deleted. A promoted file is moved; a candidate that is not promoted is left exactly where it is. `tasks/` and `wkdrs/` are swept for candidates, never cleaned up.
- Never move or rename anything already inside `${CODE_NAME}/`, and never create a directory no `codearc.md` placement rule names — that is `/star-code-architect`'s.
- Never publish: no `git push`, no remote or branch changes, no tag, no `gh repo create` / `gh release`, no upload of weights or data to any host. The prepared commands go in the report.
- All commands run through `.env`'s interpreter; never install or upgrade anything (`/star-env-builder` owns the environment). The STOP line holds: no training, no full-dataset evaluation, no costly API calls — a number the ledger lacks stays a TODO.
- Git: one commit per landed phase, staging only that phase's paths (conventions §1); a path that was already dirty at Step 0 is never staged.
- This skill sets no plan frontmatter and creates no run directories; its audit trail is `wkdrs/release/RELEASE_<date>.md`, the README's provenance marker, and the per-phase commits.

## Dialogue Discipline

- Ask every gate as plain text, one question at a time: the phase when the argument is unrecognized, the readiness decision when sources are mostly absent, Gate 1 on the promotion table, each polish finding, each README section change, the STAR-README or hand-authored-README replacement, and the Chinese README offer. Require an explicit answer before any write — even in headless or scripted runs.
- Reply in the user's language. `README.md` is English regardless of the dialogue language; the release report follows the root plan's `language` (dialogue language if no plan); keep technical terms in English inside Chinese documents.
