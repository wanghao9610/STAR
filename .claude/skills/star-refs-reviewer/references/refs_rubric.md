# Refs Rubric — what a finished review must satisfy

Two products are graded: the per-paper analysis notes, and `reference.bib` with its index. Red lines are non-negotiable; the quality bar is what separates a literature base from a list of titles.

## Red lines (a violation invalidates the run)

1. Every bib field traces to a record fetched this run and cached in the run dir (`references/source_policy.md`). No remembered fields, no inferred fields, no "obviously right" fills.
2. Every citekey has a provenance row in `refs_index.md`: source, record URL, fetch date.
3. Every entry is reachable from the method's topic in one sentence. Padding with loosely related work to hit a number is worse than reporting 43 entries and saying so.
4. Every core paper has an analysis note; every note's citekey exists in `reference.bib`.
5. Nothing is written outside `metds/refs/**` and `wkdrs/refs_<date>/**`.

## Core-paper selection (5–10)

A paper earns a note by being **close**, not by being famous:

- **Direct overlap** — same task, or the same mechanism applied elsewhere. A 2019 paper doing exactly what this method does beats a 2024 survey that mentions it.
- **Positioning value** — the work this method must differentiate itself from; the one a reviewer will ask about.
- **Baseline or benchmark status** — what the experiments will compare against.
- **Recency** — a tie-break at equal relevance, never the primary axis.

Every candidate carries a one-clause justification. A candidate you cannot justify in one clause is not a core paper.

## Analysis notes

Each note (`assets/ref_analysis_template.md`) is graded on:

- **Concrete over vague.** "Contrastive loss over 400M image-text pairs" — not "leverages large-scale data". Numbers from the paper, named datasets, named baselines.
- **The method is reconstructible.** A reader who has not opened the paper can say what it does and why it should work. Load-bearing formulas only, symbols defined.
- **Relation-to-this-project is the point.** Generic summaries are free on the internet; the note earns its place through §5 — shared ground, where it differs, what is borrowable, and what it lets this project claim. A §5 that would fit any project has failed.
- **Honest about what was read.** Abstract, intro, method, and the main results table at minimum. If only the abstract and intro were reachable, `depth:` says so — a shallow note that admits it is useful, one that pretends is not.
- **Claims are the paper's, not yours.** Report numbers as reported (metric + dataset + split). Never extrapolate, never compare across incomparable settings, mark anything uncertain `[unverified]`.

## reference.bib organization

- **3–8 categories.** Fewer than 3 is not a classification; more than 8 fragments the field.
- Categories come from the semantics of what was actually collected — titles, tasks, mechanisms — not from a fixed taxonomy imposed in advance.
- Names are specific to this literature: `Open-vocabulary detection`, not `Related methods`.
- Each category gets a `%%` block header: name, entry count, one-line scope. Entries inside sorted by year ascending, then citekey.
- Every entry belongs to exactly one category. Genuine misfits go to a final `Other / cross-cutting` block, capped at ~10% of entries — more than that means the categories are wrong, not that the papers are.

## refs_index.md

- The provenance table covers 100% of entries.
- The category table's counts sum to the entry count.
- Needs-manual-check is present even when empty (say "none") — a missing section reads as "nothing failed".
- Coined abbreviations (†) and preprint-only entries (‡) are marked.

## Chat digest

Under ~400 words: the method source, notes written, entry count and categories with counts, the self-audit result, what needs manual attention, and the next skill. Counts are honest — a shortfall is reported as a shortfall.
