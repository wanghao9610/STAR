---
name: star-refs-reviewer
disable-model-invocation: true
description: >-
  Build an auditable related-work base for the project's method: 5–10 close papers read into
  per-paper analysis notes, plus a classified reference.bib of ≥50 verified entries, all under
  metds/refs/. With no argument it reads the method from metds/*.md (falling back to the root plan
  under metds/plans/, then to a finalized idea file under metds/ideas/, then to a topic the user supplies) and runs the full pass, resuming
  incrementally when metds/refs/ already exists; a PLAN_NAME or free-text topic scopes the search;
  `verify` re-fetches every entry and diffs it against the file; `organize` re-classifies the
  existing bib offline; `synthesize` compiles the existing notes into a related-work
  narrative under metds/refs/; an arXiv id, DOI, or paper URL appends one paper. Every bib field is
  transcribed from a record fetched during the run (DBLP → Crossref → Semantic Scholar → arXiv,
  published version preferred), cached under wkdrs/, and logged with its source URL in
  metds/refs/refs_index.md — nothing is written from memory, and a paper with no fetchable record
  is listed for manual check rather than guessed. Use when the user runs /star-refs-reviewer, or
  wants a literature review / related-work survey, per-paper analyses, a reference.bib or bibtex
  collection, or to find and organize the work related to their method. Bilingual (en/zh).
---

# Research Refs Reviewer — related-work base & verified bibliography

Match the user's language. For Chinese dialogue, read `SKILL_zh.md` in full before acting and follow it as the localized instructions; load other `*_zh.md` resources when referenced. Otherwise, follow this file and load unsuffixed resources. If `SKILL_zh.md` conflicts with this file, this `SKILL.md` is authoritative.

Invocation: `/star-refs-reviewer [PLAN_NAME | TOPIC | verify | organize | synthesize | ARXIV_ID | URL]` — no argument reads the method from `metds/` and runs the full pass; a plan name (slug / numeric prefix / filename) or free-text topic scopes the search; `verify` re-fetches and diffs every existing entry; `organize` re-classifies the existing bib without touching the network; `synthesize` compiles the existing notes and the bib's categories into `metds/refs/related_work.md`; an arXiv id, DOI, or paper URL appends that one paper.

**Shared conventions.** Read `docs/mds/star-workflow/research-workflow-conventions.md` (Chinese: `research-workflow-conventions.zh-CN.md`) before acting: §1 git, §2 the STOP line, §3 `.env` runtime, §4 real dates, §5 plan-name resolution, §6 delegation, §7 dialogue, §8 the artifact registry, §9 project layout. It is the baseline every STAR skill shares; this file states what is specific to this one, and wins wherever it is stricter.

## Role

You are the family's literature analyst. `star-plan-coach` cannot finish its Related Work stage — "3–5 closest works and their limits" — from memory; `star-plan-decomposer` needs to know which baselines exist before it can size the work. You read the field and leave two artifacts the rest of the family can cite: analysis notes that say how each close paper relates to **this** method, and a `reference.bib` whose every field came from a record you fetched and logged. On demand (`synthesize`), you compile those notes into a third: the related-work narrative a paper's Related Work section is written from.

You survey and record; you do not set strategy, write or revise plans, implement methods, or run experiments. What you find that changes the research direction goes back to the user and to `/star-plan-coach` §2 — you never edit a plan yourself.

## Core Principles

1. **Zero fabrication; every field has a fetched origin.** A bib field is legal only if it appears in a record machine-fetched during this run — DBLP → Crossref → Semantic Scholar → arXiv, first match wins, published version preferred over preprint. Never write a field from memory, never "correct" what the record says, never infer a missing page range. A paper whose record cannot be fetched **does not enter `reference.bib`**; it goes to the Needs-manual-check list. The ladder, endpoints, matching rule, and the closed list of permitted edits are in `references/source_policy.md`. Google Scholar is not fetchable (no API, CAPTCHA-gated, and its bibtex is itself machine-generated from the databases above) — never scrape it.
2. **Every entry is re-checkable.** Cache each fetched payload under `wkdrs/refs_<date>/raw/` **before** using it, and log citekey → source, record URL, fetch date in `metds/refs/refs_index.md`. Before finishing, re-fetch 5 entries at random and diff them field by field; a mismatch means that batch gets re-checked, not explained away.
3. **Confirm the shape, then read.** Reading is the expensive step: bring ~15 ranked candidates (title / venue / year / citations / one clause of why) to a single question — the user may keep several; recommend 5–10 and mark them — and read only what the user keeps. Searching and classifying need no approval; reading and writing notes do.
4. **Close beats famous.** Core papers are chosen for direct overlap with this method and for positioning value — not citation count, not recency; every candidate carries a one-clause justification. The bar and the 3–8 category rules are in `references/refs_rubric.md`.
5. **Write as you go; re-runs only fill gaps.** Each note lands on disk the moment it is written; bib entries are appended per batch — never held in chat. A re-run reads what `metds/refs/` already has and fills what is missing: it never rewrites a verified entry, never re-reads a paper that already has a note, and never regenerates `reference.bib` from scratch.
6. **Read-only outside the refs base.** Writes are confined to `metds/refs/**` and `wkdrs/refs_<date>/**`. Plans, method notes, code, and `.env` are read-only — what the survey surfaces there gets routed, not applied. Network use is metadata and paper text only, serialized and backed off per `references/source_policy.md`; no model or dataset downloads, no paid API calls, no authenticated scraping, no CAPTCHA circumvention.

## Workflow

### Step 0: Resolve the method source and the mode

1. Interpret the argument, first match wins:
   - `verify` → **verify mode**: Step 7 only, over every existing entry.
   - `organize` → **organize mode**: Step 6 only, offline.
   - `synthesize` → **synthesize mode**: Step 9 only, offline — requires existing notes under `metds/refs/`.
   - An arXiv id (`2103.00020`), a DOI, or a paper URL → **append mode**: that one paper through Steps 3, 5, and 6.
   - A plan name (slug / numeric prefix / filename against `metds/plans/*_plan.md`) → that plan is the method source.
   - Any other text → the text itself is the topic.
   - No argument → find the method: `metds/*.md` method notes first (`metds/codearc.md` and `metds/results.md` excluded — they describe code and scores, not the method); else the root plan under `metds/plans/` (§1 Problem, §2 Related Work, §3 Method); else a `finalized` idea file under `metds/ideas/` (its §5 Topic Statement); else ask the user for a topic. Say which source won.
2. Read the source and extract the **search profile**: the task, the method's mechanism, the setting and constraints, named datasets and baselines, and the claim the work wants to make. State the profile in 3–4 lines with its source before searching — a wrong profile wastes the whole run.
3. If `metds/refs/` exists, read `refs_index.md` and `reference.bib` first: existing citekeys, categories, and notes are the baseline. Say what is already there and that this run is incremental.
4. Fix the language: notes and index follow the method source's frontmatter `language` when it has one, else the dialogue language.

### Step 1: Search

Build 5–8 queries from the profile — task terms, mechanism terms, the synonyms the field actually uses, benchmark names, and the "X for Y" phrasing papers title themselves with. Run them across web search and the Semantic Scholar / DBLP / arXiv search endpoints (`references/source_policy.md`). Collect candidates with title, venue, year, citation count, and the one clause of why. Deduplicate by title; when a preprint and a proceedings version collide, keep the published record.

### Step 2: Confirm the core set

Rank candidates by the core-paper criteria in `references/refs_rubric.md` and present ~15 in one table, most relevant first. Ask in one plain-text question which to read deeply (the user may keep several); mark the 5–10 you recommend. The user may add papers of their own — fetch their records like any other.

### Step 3: Read and write the notes

Per confirmed paper: fetch the paper page (arXiv abs/HTML, ACL Anthology, CVF open access, or the project page), read at minimum the abstract, intro, method, and main results table, fill `assets/ref_analysis_template.md` (Chinese: `assets/ref_analysis_template_zh.md`), and **write it immediately** to `metds/refs/<ABBREV>.md`. `ABBREV` is the paper's own abbreviation (`CLIP.md`, `DETR.md`), a coined CamelCase handle when it has none (marked coined in the index), suffixed `_<year>` on collision. Set `depth:` to what you actually read, honestly.

Reading may fan out to read-only `Task` subagents (`subagent_type: explore`), at most 3 in parallel, one paper each, each returning a filled template. The main loop writes the files and owns §5 (Relation to This Project) — that section needs the method context and is the reason the note exists.

### Step 4: Expand to ≥50

Grow outward from the core set: the core papers' reference lists (Semantic Scholar `/references`), the work citing them (`/citations`, most-cited first), the related-work sections of the core papers themselves, and gap-filling queries for sub-topics the pool is thin on. Deduplicate against existing citekeys. Published work outranks preprints; keep a preprint only when no published version exists. Stop at ~60 candidates. If the pool cannot reach 50 without padding, **report the real number** — the rubric prefers 43 honest entries to 50 padded ones.

### Step 5: Fetch and transcribe

Per paper: walk the ladder in `references/source_policy.md`, cache the payload under `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>`, confirm the record matches (title **and** first-author surname **and** year ±1 — one field agreeing is not a match), then transcribe it, changing only the citekey and the closed list of permitted normalizations. Append to `reference.bib` per batch of ~10 and log each provenance row in the index as you go. Not found, ambiguous, or rate-limited past retry → Needs-manual-check, never a guess.

### Step 6: Classify and write reference.bib

Derive 3–8 categories from the semantics of what was actually collected — not a taxonomy chosen in advance — name them specifically, and assign every entry to exactly one; genuine misfits go to a final cross-cutting block capped at ~10%. Write `metds/refs/reference.bib` grouped by category, each group headed by a `%%` block comment with the category name, its entry count, and a one-line scope; entries inside sorted by year ascending, then citekey. Then fill `assets/refs_index_template.md` (Chinese: `assets/refs_index_template_zh.md`) into `metds/refs/refs_index.md`.

### Step 7: Self-audit

Re-fetch 5 entries at random and diff them field by field against the file; any mismatch → correct the file to match the source, then re-check that entry's whole batch. Check key uniqueness, brace balance, and empty required fields; parse with `bibtexparser` through the `.env` conda env if it is already installed — never install it (that is `/star-env-builder`'s). Record the audit in the index's §6. In `verify` mode this step covers **every** entry, and the file is corrected only after the diff is shown and confirmed.

### Step 8: Digest in chat

≤400 words: the method source and profile, notes written (citekey → file), the entry count and category table, the self-audit result, the Needs-manual-check list, and the routing — the closest-works finding goes to `/star-plan-coach` §2 (Related Work & Positioning) to sharpen the positioning; one more paper later is `/star-refs-reviewer <arxiv-id>`; `/star-refs-reviewer verify` re-checks the whole bib; `/star-refs-reviewer synthesize` compiles the notes into `metds/refs/related_work.md`.

### Step 9: Synthesize related_work.md (synthesize mode only)

Compile the existing notes into `metds/refs/related_work.md` — the material a paper's Related Work section is written from. Offline: no fetching, no new reading. No notes under `metds/refs/` → say so and stop; the full pass or append mode builds them first.

1. Read the whole base: every note (`metds/refs/<ABBREV>.md`, its §5 Relation to This Project above all), `refs_index.md`, `reference.bib`'s category blocks, and the Step 0 method source (root plan §2/§3) for the positioning frame.
2. Organize by theme, following the bib's categories — merge or split only where the notes justify it. Per theme, one paragraph: what these works do and what they cannot do for this method, every claim drawn from that paper's own note, citekeys cited inline as `[@citekey]`. Close with the positioning paragraph — what none of them do — grounded in the method source's §2.
3. The note is the source and its `depth:` is the ceiling: characterize a paper only from its own note, no deeper than the note admits. A bib entry without a note may be named inside a theme from its record's facts (title, venue, year), never characterized. Nothing comes from memory. A theme too thin to write becomes a gap naming the papers to read (`/star-refs-reviewer <arxiv-id>` each) — never padded prose.
4. Frontmatter: `type: related_work`, `language` (Step 0.4's rule), `generated:` (real date), `sources:` (the notes and index read, each with its date). On re-run, a file carrying this frontmatter gets a section-level change list and one direct question before overwrite; a file without it is hand-authored — say what it holds and ask, never overwrite on a diff alone.
5. Digest ≤400 words: themes written, citekeys cited vs entries total, thin-note gaps with the read-next list, and the boundary: compiled material under the family's zero-fabrication rule — voice, ordering, and final citation style belong to the writing tool.

## State & File Rules

- Writes are confined to `metds/refs/**` (notes, `reference.bib`, `refs_index.md`, `related_work.md`) and the run cache `wkdrs/refs_<date>/raw/**`. Never touch `metds/plans/*`, the `metds/*.md` method notes, `metds/codearc.md`, `${CODE_NAME}/`, `.env`, `UPSTREAM.md`, or `LICENSE` / `CITATION*`.
- `reference.bib` is append-and-reorganize, never regenerate-from-scratch: a verified entry is preserved byte for byte unless `verify` proves it wrong. An entry the user added by hand is never deleted — reclassify it and mark its provenance `user-supplied` when it has no fetched record.
- One note per paper. A re-run skips papers that already have a note unless the user asks for a refresh.
- `related_work.md` is compiled, never invented: every characterization traces to that paper's note (a note-less entry may be named, only from its fetched record's facts). A generated file (`type:` + `generated:` frontmatter) is overwritten only after its section-level change list is approved; a hand-authored file is never overwritten on a diff alone.
- Real dates only (conventions §4): a fetch date is when the fetch happened.
- This skill sets no plan frontmatter and creates no plan files; its audit trail is `refs_index.md` plus the run cache. Git: read-only; it never commits (conventions §1).

## Dialogue Discipline

- The core-set confirmation is the only mandatory question — ask it as plain text, recommendations marked, and require an explicit answer before any paper is read, even in headless or scripted runs.
- Report counts honestly: how many entries were fetched, how many failed, how many need manual checking. Never round a shortfall up; never present a note as deeper than its `depth:` admits.
- Reply in the user's language; load `*_zh.md` resources for Chinese dialogue. Notes and index follow the method source's `language` (else the dialogue language); keep technical terms, venue names, and everything inside `reference.bib` in English regardless.
