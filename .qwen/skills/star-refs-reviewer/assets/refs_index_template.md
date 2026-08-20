# Reference Index — <topic> (<YYYY-MM-DD>)

<!-- Written by /star-refs-reviewer (model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none — docs/mds/star-workflow/model_id_spec.md>). This file is the audit trail for reference.bib: every entry's
     origin is recorded here, so any field in the bib can be re-checked against the record it came
     from. An entry with no row here is not allowed to exist. -->

## 1. Scope

<!-- Which method source drove the search (metds/<file>.md, a plan under metds/plans/, or a topic the
     user gave) and the profile extracted from it. The queries that were run. The run cache holding
     the raw records: wkdrs/refs_<date>/raw/. Mode: full | append | verify | organize. -->

## 2. Core Papers

| Citekey | Note | Venue | Why it is core | Depth | Score | Model |
| --- | --- | --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | [CLIP.md](CLIP.md) | <ICML 2021> | <one clause> | full | <9.6> | <model id> |

## 3. Categories

| Category | Entries | Scope |
| --- | --- | --- |
| <specific name> | <n> | <one line> |
| **Total** | **<n>** | |

## 4. Provenance

<!-- One row per reference.bib entry — 100% coverage, no exceptions. "Source" is the record the
     fields were transcribed from. Mark coined abbreviations (†) and preprint-only entries (‡).
     The record URL and fetch date here are what that entry's `% src:` line in reference.bib says. -->

| Citekey | Source | Record URL | Fetched |
| --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | DBLP | <https://dblp.org/rec/conf/icml/...bib> | <YYYY-MM-DD> |

## 5. Impact Scores

<!-- One row per entry, the arithmetic and bins from references/refs_rubric.md (Impact score):
     sub-signals with their fetch dates, then the weighted total. `*` marks a partial total (a
     component unfetched, weights renormalized); `new` marks papers ≤18 months old. Stars only for
     a repo the paper's own page names — an unofficial repo is noted here, never scored. Metrics
     drift: the dates say how fresh, and /star-refs-reviewer score rebuilds this table. -->

| Citekey | Cites/yr (fetched) | Venue tier | Stars (repo, fetched) | Score |
| --- | --- | --- | --- | --- |
| `<2021_CLIP_Radford>` | <6100 (YYYY-MM-DD)> | <10> | <30.1k (openai/CLIP, YYYY-MM-DD)> | <9.6> |

## 6. Needs Manual Check

<!-- Papers no authoritative record could be found for; ambiguous matches (list the candidates and
     their URLs); records whose fields look wrong but were transcribed anyway rather than silently
     corrected. Each with what to check and where. Write "none" when clean — never omit the
     section. This is the detailed side: reference.bib's `%% Needs manual check` block carries one
     line per paper pointing here. -->

## 7. Self-Audit

<!-- Which entries were re-fetched and diffed (≥5, at random; all of them in verify mode), the
     result, the parse / brace / uniqueness check, the 3 impact scores recomputed from their logged
     sub-signals, and any entry corrected as a consequence. -->

## 8. Next Actions

<!-- Gaps worth another pass (a thin category, a sub-topic not covered). Routing: sharpening the
     positioning → /star-plan-coach §2 Related Work & Positioning; one new paper later →
     /star-refs-reviewer <arxiv-id>; re-checking the bib → /star-refs-reviewer verify; refreshing
     drifted citation and star metrics → /star-refs-reviewer score. -->
