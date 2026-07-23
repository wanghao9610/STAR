# Idea Rubric — scoring directions, issuing verdicts, gating the topic statement

Three parts. Part A scores each scanned direction on six dimensions; Part B turns scores into a verdict; Part C is the gate the topic statement must pass before `finalized:` is set. Judgments are **High / Medium / Low with a clause of evidence** — never a bare grade. Evidence means a Stage-1 constraint or scanned papers; a judgment that cites neither is an opinion and does not belong in the file.

## Part A: the six dimensions

Score each scanned direction, one line per dimension:

1. **Novelty** — distance from the scanned closest works. High: no scanned work targets the direction's one-line question. Medium: scanned works circle it but each abstract leaves the core untouched. Low: a scanned work answers it modulo engineering. A skipped scan caps this line at "per the user's knowledge, unverified by scan".
2. **Impact** — who changes behavior if it works. High: a field re-plans around the result. Medium: a sub-community adopts it. Low: a leaderboard moves. Judge against the direction's own community, honestly sized — "High within a workshop" is Medium.
3. **Feasibility** — against Stage 1's compute, data, time, and skills, not against a lab in the abstract. Name the single highest-risk assumption and say whether its first test fits the constraints. Low is not shameful; unstated is.
4. **Crowdedness / scoop risk** — from the scan: publication rate and trajectory, big-group presence, benchmark saturation. A same-question preprint from the last 6 months is an imminent-scoop flag, stated as such. Crowded is not disqualifying — it prices the speed and the angle required.
5. **Personal fit** — from Stage 1's strengths and stated energy. High: an edge others lack (data, infrastructure, skill, position) plus appetite. Medium: sound interest, no particular edge. Low: neither edge nor energy — say so plainly; the rubric is not a mirror for enthusiasm.
6. **Evaluability** — can success be measured. High: an accepted benchmark or a metric definable today. Medium: a measurable proxy that must first be built. Low: "we would know it when we see it". A Low here on a chosen direction becomes the first deliverable: build the eval.

## Part B: the verdict

One verdict per direction, with a one-line reason:

- **Pursue** — no dimension fatally Low; novelty and fit at least Medium; the first validation experiment is statable now.
- **Refine** — one specific, fixable weakness: a question too broad, a gap unverified, an eval missing. Name the fix. A refined direction is rescored once; a direction that needs refining twice is a Park wearing makeup.
- **Park** — a fatal Low (already answered by a scanned work; infeasible under the stated constraints; no energy), or dominated by a Pursue direction on every dimension. A parked direction keeps its scan evidence and gets a revive-when line: the concrete change that would reopen it.

The verdict is advice. The user decides; a choice against the verdict is recorded with its reason and then respected. No dimension is averaged into a total — six honest lines beat one blended number.

## Part C: the topic-statement gate

Before `finalized:` is set, all of these hold:

1. The research question fits one sentence without "and".
2. The gap statement names at least 2 scanned works and what none of them do; if the scan was skipped, it says "per the user's knowledge, unverified by scan" in so many words.
3. Why-now names what changed — a model, a dataset, a result, a price — not just "this is important".
4. The first validation experiment is statable, sized to roughly a week within the Stage-1 constraints, and its kill-condition is explicit: the result that abandons the topic.
5. Scan depth is recorded per direction — abstracts / abstracts+intros / skipped — and nothing in the statement claims deeper reading than the record shows.
6. Every paper named in the file carries venue, year, and the URL of its fetched record.

Failing items are listed for the user (at most 5, ranked by importance) and either fixed or explicitly accepted. An accepted failure is written into the file next to the item it concerns — the plan inherits open issues, not surprises.
