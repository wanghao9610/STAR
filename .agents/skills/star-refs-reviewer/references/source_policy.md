# Source Policy — where bib records come from, and what may be changed

Every field in `reference.bib` traces to a record fetched during this run. This file fixes where records may come from, in what order, how a record is matched to a paper, and the closed list of edits allowed afterwards. Read it before the first fetch.

## The one hard rule

A bib field is legal only if it appears in a machine-fetched record from a source below. Never write a field from model memory. Never "correct" a field the record got wrong. Never fill a missing field by inference — not the year, not the pages, not the publisher. A paper whose record cannot be fetched **does not enter `reference.bib`**; it goes to the index's Needs-manual-check list. An entry that is 90% transcribed and 10% remembered is a fabricated entry.

Google Scholar is not a source here: it has no API, blocks automated queries behind CAPTCHAs, and its exported bibtex is itself machine-generated — frequently missing pages, using abbreviated venue strings, and preferring the preprint over the published record. A human may read it; this skill never scrapes it. The databases below are what a Scholar bibtex is generated *from*, so they are both fetchable and closer to the source.

## Search order

Per paper, stop at the first source that yields a matching record:

1. **DBLP** — authoritative for CS venues.
   - search: `https://dblp.org/search/publ/api?q=<query>&format=json&h=10`
   - bibtex: `https://dblp.org/rec/<key>.bib?param=1` (condensed form; `param=0` emits crossref-style entries — do not use)
   - When both a CoRR (arXiv) record and a conference/journal record exist for one title, take the published one.
2. **Crossref** — DOI-backed; journals and many proceedings.
   - `https://api.crossref.org/works/<doi>`, or `https://api.crossref.org/works?query.bibliographic=<title>&rows=5`
   - bibtex via content negotiation: `curl -LH "Accept: application/x-bibtex" https://doi.org/<doi>`
3. **Semantic Scholar** — best for coverage, reference lists, and citation counts. Use its `externalIds` (DOI, DBLP) to hop **back up** to sources 1–2 rather than treating it as a bib source.
   - search: `https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&fields=title,year,venue,authors,externalIds,citationCount`
   - references: `https://api.semanticscholar.org/graph/v1/paper/<id>/references?fields=title,year,venue,externalIds,citationCount&limit=100`
   - citations: same shape with `/citations`
4. **arXiv** — only for work with no published version.
   - `http://export.arxiv.org/api/query?id_list=<id>` (Atom)
   - becomes `@misc` with `eprint`, `archivePrefix = {arXiv}`, `primaryClass`, `year`

Cache every fetched payload under `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>` **before** using it. The cache is the audit trail and the resume point for a re-run.

## Matching a record to the paper

A record matches only when all three agree:

- **title** — case- and punctuation-insensitive, subtitle included;
- **first-author surname**;
- **year** — ±1, to absorb the arXiv-to-proceedings gap.

One or two fields agreeing is not a match — near-duplicate titles across a workshop paper, its extension, and a survey are common. Ambiguous → do not guess: list the candidates with their URLs in Needs-manual-check.

## Resolving a title

`add` may name a paper by title alone, so the title is all there is to match on. Resolution uses the search endpoints above (DBLP search, Crossref `query.bibliographic`, Semantic Scholar search) and the matching rule's normalization: case- and punctuation-insensitive. The input resolves when exactly one paper's record title equals it — the full title, or the main title before a subtitle's colon. Several distinct papers matching (a workshop paper and its extension are the classic pair), or best hits that only nearly match → ask, one direct question listing each candidate's title, venue, year, and URL; found nowhere → Needs-manual-check. A resolved title is from then on just a paper: its record goes through the search order, the three-field matching rule, and published-over-preprint like any other.

## Published over preprint

Prefer the published record whenever one exists; the arXiv id survives only if the fetched record already carries it. arXiv-only work is legitimate and included — marked `preprint` (‡) in the index, typed `@misc`.

## Citekey

`<Year>_<Method>_<FirstAuthorSurname>` — e.g. `2021_CLIP_Radford`, `2023_SAM_Kirillov`.

- **Year** — the year of the record being cited (the published year when the published record won).
- **Method** — the paper's own abbreviation, as the paper writes it (`CLIP`, `DETR`, `SAM`). None → coin a compact CamelCase handle from the title (`MaskDistill`) and mark it coined (†) in the index.
- **FirstAuthorSurname** — ASCII, no diacritics, no spaces: `Müller` → `Mueller`, `van den Berg` → `vandenBerg`.
- Collision → append a lowercase letter (`2021_CLIP_Radforda`). Keys are unique across the file.

The citekey is the only field you author. Everything else is transcribed.

## Normalization — the closed list

Permitted, and nothing beyond:

- Replace the source's key with the citekey.
- Drop noise fields: `bibsource`, `biburl`, `timestamp`, `abstract`, `keywords`, `url` when it merely restates the DOI, `month` when the venue already fixes it.
- Brace-protect capitals BibTeX would lowercase: `{CLIP}`, `{ImageNet}`, `{T}ransformer`. This changes rendering, not content.
- Expand a venue abbreviation **using the name already present in the fetched record**: DBLP's `booktitle` normally spells out `IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR)`, so writing that is transcription. Inventing a full name the record never contained is not.

Not permitted: adding pages, editors, publishers, volumes, DOIs, or a year the record lacks; "fixing" author initials or name order; merging fields from two records for one paper (pick one record; the index says which).

## Entry types and fields

- `@inproceedings` — proceedings: `author`, `title`, `booktitle`, `year`, plus `pages` / `publisher` when present.
- `@article` — journal: `author`, `title`, `journal`, `year`, plus `volume` / `number` / `pages` when present.
- `@misc` — arXiv-only: `author`, `title`, `year`, `eprint`, `archivePrefix`, `primaryClass`.
- `@book`, `@incollection` — as the record states.

AI-conference templates (NeurIPS / CVPR / ICML / ICLR / ACL) render author, title, booktitle/journal, year, pages, volume, publisher. Keep those when the record has them; do not pad the rest.

## Impact metrics — score inputs, never bib fields

The impact score (`references/refs_rubric.md`, Impact score) is computed from three metrics. None enters `reference.bib`; they live in the index with their fetch dates.

- **Citation counts** ride the Semantic Scholar calls already listed — `citationCount` is in the search, `/references`, and `/citations` field lists, so the full pass pays nothing extra. `score` mode refreshes the whole bib in one call: `POST https://api.semanticscholar.org/graph/v1/paper/batch?fields=citationCount,year,externalIds`, up to 500 ids in the body (`{"ids": ["DOI:…", "ARXIV:…", …]}`), the ids taken from the provenance the index already holds. An entry the batch cannot resolve keeps its old value and date.
- **Venue tier** is offline: the fetched record's venue field against `references/venue_tiers.md`.
- **Stars and last push** — `https://api.github.com/repos/<owner>/<repo>` → `stargazers_count`, `pushed_at`. Cache the response as `<citekey>.github.json` before use. Unauthenticated GitHub allows **60 requests/hour** — the binding cap, still several times the ≤15 repos a run should need (core papers, survey deep tier); serialize ~1/s like every host. A 403/429 here usually *is* the hourly cap: back off once, then record the failure and mark the component unfetched — a partial score per the rubric, never a retry loop, never a number from memory.

**Official repos only.** A repo qualifies only when the paper's own page names it: the arXiv abs page, the project page, or the paper's PDF/HTML itself. Discovery order: the paper page Step 3 reads anyway → the arXiv abs page → the paper's Hugging Face papers page (`https://huggingface.co/papers/<arxiv-id>`). Papers with Code shut down in July 2025 — do not fetch it. A repo surfaced any other way (code search, a citing repo's README) is logged `unofficial` in the index and never scored.

## Rate limits and failure

- Serialize per host: ~1 request/second to DBLP and Semantic Scholar, ~3/second to Crossref (add a `mailto` for its polite pool). The budget belongs to the whole session against each host; it is not one budget per agent (conventions §6.9). A step that fans out splits it and writes each share as a number.
- Paper pages fetched at Step 3 — arXiv abs/HTML, ACL Anthology, CVF open access, project pages — follow the same polite default as any other page fetch: ~1 request/second, and ~1 per 3 seconds to arXiv, which asks for that. Step 3 fetches one page per paper, so this only constrains the step when it fans out.
- HTTP 429 / 503 → exponential backoff (2s, 4s, 8s), at most 3 retries, then move on and record the failure. A rate limit is never a reason to fill the gap from memory.
- A source returning nothing is logged as "not found in `<source>`" — that is a fetch outcome, not evidence the paper does not exist.

## Self-audit before finishing

1. Every citekey in `reference.bib` has a cached payload in the run dir **and** a provenance row in `refs_index.md`.
2. Re-fetch 5 entries at random; diff field-by-field against the file. Any mismatch → correct the file to match the source, then re-check that entry's whole batch.
3. Parse the file with `bibtexparser` through the `.env` conda env **if it is already installed** (never install it — that is `$star-env-builder`'s job); otherwise check brace balance and key uniqueness mechanically.
4. No entry has an empty required field; no key appears twice.
