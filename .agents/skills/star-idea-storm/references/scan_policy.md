# Scan Policy — where landscape evidence comes from, and how deep it goes

The light sibling of the bibliography's source policy: that one builds a verified `reference.bib` for a chosen method; this one answers "how crowded, who is closest, what gap" for 2–4 candidate directions, at abstract depth, in minutes per direction. It produces no bibtex, no per-paper notes, and writes nothing under `metds/refs/**` — when the topic is chosen, the deep survey (`star-refs-reviewer`) builds those on the winner, starting from these scan tables.

## The hard rule (inherited from the family)

Every paper named in dialogue or in the idea file is transcribed from a record fetched during this run — title, venue, year, citation count from the record, the record's URL logged next to the row. Memory may propose queries and synonyms; only fetched records enter the file. Never "fix" what a record says, never fill a field it lacks. A paper search cannot find is evidence only that it was not found — say so if it matters, and never paraphrase a remembered paper as if scanned. No authenticated scraping, no CAPTCHA circumvention. Google Scholar is not a source (no API, CAPTCHA-gated); the endpoints below are what it indexes anyway.

## Sources — breadth over a fixed search order

Unlike the bibliography's first-match-wins search order, scanning wants disagreement: run at least two sources per direction — how crowded an area looks from a single index is an artifact of that index.

1. **Semantic Scholar search** — primary for how crowded an area is and for citation signal:
   - `https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&fields=title,year,venue,abstract,citationCount,externalIds&limit=20`
   - add `&year=<from>-` for the recency query (e.g. the last 18 months).
2. **arXiv API** — primary for trajectory and the newest work:
   - `http://export.arxiv.org/api/query?search_query=all:<terms>&sortBy=submittedDate&sortOrder=descending&max_results=20` (Atom)
3. **DBLP search** — venue confirmation for what the other two reported:
   - `https://dblp.org/search/publ/api?q=<query>&format=json&h=20`
4. **Web search** — surveys, workshop pages, blog posts that name the field's vocabulary. A paper a web result mentions still enters the file only through a record from sources 1–3; a useful non-paper page (a survey blog, a leaderboard) may be cited in the note on how crowded the area is, with its URL, marked `web context`.

## Queries

2–3 per direction: the task phrasing, the mechanism phrasing, and the "X for Y" phrasing papers title themselves with — plus one recency query (submissions in the last 18 months) for the trajectory read. Steal vocabulary from the first round's results to sharpen the second; the field's own words out-search yours. But one of the 2–3 must use terminology the direction does **not** use — an adjacent field's name for the same mechanism, the older name for the task, or the benchmark's name instead of the task's — and the §3 block records which alternate terms were tried. Building every query from the direction's own vocabulary is right for reading how crowded an area is and exactly wrong for catching a scoop: the paper that answers your question first uses words you did not think to use.

## What is recorded, per direction

- **The scan table** — 8–15 papers, deduplicated by title (preprint vs published: keep the published record when both appear): title / venue / year / citations / one clause of relevance / record URL.
- **The note on how crowded the area is** — results-per-year trend, the venues involved, named groups where evident, whether a survey newer than ~18 months exists, benchmark saturation if visible. Web-context links allowed here, marked as such.
- **The 3 closest works** — one line each: what it does, and what its own abstract does not claim.
- **The apparent gap** — phrased as what none of the scanned works do. At abstract depth the honest verb is "the abstracts suggest".
- **The depth line** — `abstracts`, `abstracts+intros`, or `skipped`.

## Return format per scan collector

When Stage 3's scanning fans out, the main agent builds each collector's briefing — a collector never builds its own. It carries: the direction's slug and one-line question; the 2–3 queries and the recency query already constructed; the run's date, for the cache prefix (a collector never calls its own clock); the resolved output language; and its own share of the per-host rate budget, as a number — with 3 concurrent collectors, 1 request per 3s to Semantic Scholar and DBLP, 1 per 9s to arXiv. That budget is per host, not per agent: three collectors each honouring it separately triple the real rate against every host.

The return: `direction`, `rows` (8–15, deduped, each with its `record_url` and the cache path it wrote), `recency`, `web_context`, `surprises`, `failures: [{host, error, retries}]`, `queries_run` — and nothing else. Prohibitions, verbatim: never fill a field the record does not carry; never deepen (deepening is a main-agent trigger, or the `depth:` line becomes a lie); never score the direction and never characterize the field. Records are cached under this run's own prefix, scoped to the collector's own direction slug (conventions §6.4), and nothing else is written.

The main agent adds one bounded duty: per direction, re-open one cached record and confirm two of its rows verbatim.

## Depth — default shallow, deepen on trigger

Default reading is title + abstract. Deepen only when (a) the user names a direction, or (b) a gap claim decides between finalist directions. Deepening means: the direction's top-3 closest works, intro and first paragraph of related work, from the paper's own page (arXiv abs/HTML, ACL Anthology, CVF open access, or the project page) — then record `abstracts+intros` in that direction's depth line. Never deepen silently, never claim more than the depth line admits.

## Caching, rate limits, failure

- Cache every fetched record under `wkdrs/ideas_<date>/raw/<direction-slug>.<source>.<ext>` **before** using it — the cache is the audit trail and the resume point.
- Serialize per host: ~1 request/second to Semantic Scholar and DBLP; ~1 per 3 seconds to arXiv. The budget belongs to the whole session against each host; it is not one budget per agent (conventions §6.9) — if this session already ran a skill that fetches, part of it is spent. HTTP 429 / 503 → exponential backoff (2s, 4s, 8s), at most 3 retries, then record the failure and move on. A rate limit is never a reason to fill the gap from memory.
- A direction whose searches all fail is reported as "scan failed: <hosts and errors>" — never padded, never silently replaced by recall.
