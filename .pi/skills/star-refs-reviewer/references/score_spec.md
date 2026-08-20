# Step 11: Refresh the scores (score mode only)

Rebuild the index's §5 (impact scores) with fresh metrics. Nothing else changes: no reading, no new entries, no bib edits — citation counts and stars drift, and this mode is how the table catches up.

1. Read `refs_index.md` and `reference.bib`: the citekeys, §5's rows with their sub-signals, and every official repo already named in §5 or a note's `links`. No `metds/refs/` → say so and stop.
2. Re-fetch citation counts for the whole bib — Semantic Scholar's batch endpoint (`references/source_policy.md`) takes the entries' external ids in one call; an entry it cannot resolve keeps its old row and date. Re-fetch stars and last-push for the known official repos, serialized under the same per-host cap. No page is fetched to discover new repos — that is the full pass's and `add`'s work.
3. Recompute every score by the rubric's arithmetic, rewrite §5 with the new fetch dates, and update the score column in §2 (core papers). Cache every record under `wkdrs/refs_<date>/raw/` like any other fetch.
4. Digest ≤200 words: entries refreshed vs kept, the moves — any paper whose score crossed a whole point — and the failures, each keeping its old value and date, never a guess.
