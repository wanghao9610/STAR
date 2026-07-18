# Stage-by-Stage Question Bank (Specialized for Research Topic Selection)

How to use: when entering a stage, read only that stage's section. Core questions open the stage (pick 2–3, not all of them); follow-ups probe the weak spots in the user's answers; "When stuck" gives that stage's rescue strategy. Questions are ammunition, not a checklist — use them selectively based on what the user says; do not march through every item.

---

## Stage 1: Seed & Constraints (seed)

**Core questions**
- What drew you to this — a paper that annoyed you, a failure you keep hitting, a capability you wish existed? The origin usually points at the real question.
- What do you have to work with: how much compute for how long, what data you already hold, how many months until the deadline that matters?
- Which outcome would satisfy you: a top-venue paper, a working system, a thesis chapter, a demo that wins users? Different outcomes favor different topics.
- What are you unusually well positioned for that the average lab is not — an infrastructure, a dataset, a collaboration, a hard-won skill?

**Follow-ups**
- If a colleague said "this is already solved", what would you point at as still broken?
- Is the itch about a task (make X work), a phenomenon (why does Y happen), or a resource (use Z better)? The three storm differently.
- What would you refuse to work on even if it scored well? Constraints of taste are constraints — record them.
- Whose attention do you want: reviewers at one venue, one industry, one lab you admire?

**When stuck**: offer 2–3 readings of the seed at different granularities — a task reading, a mechanism reading, a setting reading — and let the user pick or edit one.

---

## Stage 2: Diverge (diverge)

**Generation moves** — use these to draft candidates; aim for directions that differ in problem, bet, or setting, not in wording:
- **Vary the problem**: keep the mechanism the user cares about, change what it is applied to.
- **Vary the bet**: same problem, a different hypothesis about what makes it tractable now.
- **Vary the setting**: same problem and bet, moved to the regime where it is hardest or most valuable — low-data, on-device, multilingual, long-context, safety-critical.
- **Invert**: find what breaks the current best methods and make the failure itself the topic.
- **Transfer**: name an adjacent field that solved a structurally similar problem; the analogue here is a candidate.
- **Obsolete**: ask what result would make the seed's whole area irrelevant; working toward that result may be the better topic.

**Core questions**
- Which of these would you still want to work on if you learned someone published it last month? Interest that survives scooping is signal.
- Which direction do you understand well enough to name its likely failure mode right now?
- If you could run only one experiment this month, which direction does it serve?

**Rules**: 3–5 candidates; each carries a one-line question, the bet, what would be new, and the nearest existing area; the user's own candidates enter the pool on equal terms.

**When stuck**: if the user cannot choose what to keep for scanning, keep the two they rank highest plus the one most distinct from both — distance protects the scan from answering the same question three times.

---

## Stage 3: Scan Probes (scan)

What the scan must answer per direction — the how (sources, limits, caching) lives in the scan policy:
- How many groups published on this in the last two years, and is the count rising or falling?
- What are the 3 closest works, and what does each one's own abstract explicitly not claim?
- Is there a survey newer than ~18 months? A surveyed field is mature — a different game, not a dead one.
- Which benchmark or dataset does everyone share, and does it look saturated?
- Is the apparent gap empty because nobody tried, or because attempts failed? Flag any paper that reads like a failed attempt; it is a priority intro-read if the direction becomes a finalist.

When the scan surprises — crowded where empty was expected, empty where crowded was expected, a same-question preprint in the last 6 months — surface it immediately, not at stage end.

---

## Stage 4: Converge (converge)

**Core questions**
- The rubric says direction A; your energy says B. Which wins? Plans die of boredom more often than of rebuttal — energy is evidence too.
- For the leading direction: what is the riskiest assumption, and what is the cheapest experiment that tests it?
- If this direction were parked today and revived in a year, what would need to still be true for it to remain open?
- Would you rather be second on the important question or first on the narrow one? There is no right answer; there is your answer.

**Merging**: when the user wants to merge two directions, ask which single question the merged direction answers. A merge without one question is two topics stapled together.

**When stuck**: rank by feasibility alone — constraints are facts, taste can follow. If nothing survives, park everything, revisit the seed, and rescan with one new direction; at most one such loop — needing a second means the seed itself has moved, so reopen Stage 1 honestly.

---

## Stage 5: Frame (frame)

Checks to apply while drafting — the formal gate lives in the rubric's Part C:
- Say the research question in one sentence with no "and". Two sentences are two topics.
- Name the 2–3 closest scanned works inside the gap statement. A gap that names no papers is a hope, not a gap.
- Why now: what changed — a model, a dataset, a proof, a price — that makes this tractable today and not two years ago?
- First validation: the cheapest experiment that could kill the topic, runnable in about a week within the Stage-1 constraints, with its kill-condition stated.
- Ask the user: what result would make you abandon this topic? The answer goes in the file; the plan's risks section will inherit it.
