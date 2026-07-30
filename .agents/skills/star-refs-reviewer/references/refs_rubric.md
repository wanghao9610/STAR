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
- **The method is reconstructible.** A reader who has not opened the paper can say what it does and why it should work. Only the formulas the method depends on, symbols defined.
- **Relation-to-this-project is the point.** Generic summaries are free on the internet; the note earns its place through §5 — shared ground, where it differs, what is borrowable, and what it lets this project claim. A §5 that would fit any project has failed.
- **Honest about what was read.** Abstract, intro, method, and the main results table at minimum. If only the abstract and intro were reachable, `depth:` says so — a shallow note that admits it is useful, one that pretends is not.
- **Claims are the paper's, not yours.** Report numbers as reported (metric + dataset + split). Never extrapolate, never compare across incomparable settings, mark anything uncertain `[unverified]`.

## Note collector contract

What a read-only subagent returns when Step 3's reading fans out. `assets/ref_analysis_template.md` is the *file's* shape, not a delegate's return format: it asks for `read_on`, and for `model_id` / `model_trail`, which belong to the session that writes the file (conventions §8), and for `category`, which is derived at Step 6 from the whole collected pool and cannot exist yet, and for §7's follow-ups, which are citekeys already in `reference.bib` — a file Step 5 has not yet built. A collector that fills those writes a record that is provably false.

One paper each. The return:

- `note_body` — the template's §1, §2, §3, §4 and §6, filled. **§5 and §7 are left empty**: §5 needs the project's method context and is the reason the note exists; §7 wants citekeys from a `reference.bib` that does not exist until Step 5.
- `title` / `venue` / `year` — exactly as the paper's own page states them.
- `links` — paper / code / project, or `none found`.
- `depth` — what it actually read.
- `depth_evidence` — `{sections_reached: [...], results_table: <the caption plus one row, verbatim>}`, or `none reachable`.
- `relation_material` — `[{claim, where}]`: raw material for §5, never §5 itself.
- `cited_works` — what this paper's related-work section cites, harvested while the paper was already open.

and nothing else: no frontmatter provenance, no `category`, no `read_on`, no §5. The main agent writes every file.

## Survey collector contract

What a read-only subagent returns when Step 10.4's reading fans out. One paper each. The return:

- `facts` — `[{claim, where}]`: what the paper does, states, or reports, each tied to the section or table it came from.
- `title` / `venue` / `year` — exactly as the paper's own page states them.
- `links` — paper / code / project, or `none found`.
- `depth` — what it actually read, in the note vocabulary (`method-and-results` / `abstract-and-intro`).
- `depth_evidence` — `{sections_reached: [...], results_table: <the caption plus one row, verbatim>}`, or `none reachable`.
- `failures` — `[{host, error, retries}]`.

and nothing else: no branch assignment (the taxonomy is settled by the main agent against the whole pool), no drafted prose, no frontmatter fields. The main agent writes the file.

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

## The survey document (survey mode)

`<slug>_survey.md` is graded on:

- **The taxonomy is derived and declared.** 3–8 branches under one division axis stated in a sentence, the axis that was rejected named beside it; the category rules above apply unchanged. Start from the schemes of 1–3 existing surveys of the topic where they exist — adapt, never adopt wholesale. Two levels at most; every paper sits on exactly one branch, and a paper spanning branches meets the others in the comparison table, not twice in prose.
- **Branches are synthesis, not lists.** Each branch section says what its papers share and where they diverge — never a paper-by-paper sequence of summaries.
- **Tiers are the evidence ceiling.** Deep-tier papers (`method-and-results` or better) are the only comparison-table rows and the only sources of reproduced numbers; abstract-tier papers may be placed on a branch and characterized in a clause; record-tier papers are named from their records' facts, never characterized. The frontmatter's per-tier counts are honest counts.
- **A table column earns its place** three ways at once: it discriminates (values actually differ across rows), it is fillable from fetched sources for every row (`—` where not), and it answers a choice the reader faces. A column that repeats the branch grouping, or holds free-text summaries, is prose in a cage.
- **Every claim is grounded.** An inline `[@key]` on every non-obvious claim, resolvable in the annotated references; a number carries its dataset and metric; what no cached source supports is cut or marked as the survey's own inference.
- **The count ledger is present**: found → deduplicated → screened → tiered, with what was excluded and why.
- **It is honestly a survey.** Below ~30 papers, or with no deep tier, or organized around positioning one project rather than mapping a field, the document is a related-work note — that is `synthesize`'s artifact, and the run says so instead of padding.

## Chat digest

Under ~500 words: the method source, notes written, entry count and categories with counts, the self-audit result, what needs manual attention, and the next skill. Counts are honest — a shortfall is reported as a shortfall. A survey run's digest follows Step 10.8 instead.
