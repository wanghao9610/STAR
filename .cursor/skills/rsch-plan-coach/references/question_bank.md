# Stage-by-Stage Question Bank (Specialized for CS Research Plans)

How to use: when entering a stage, read only that stage's section. Core questions open the stage (pick 2-3, not all of them); follow-ups probe the weak spots in the user's answers; "When stuck" gives that stage's rescue strategy. Questions are ammunition, not a checklist — use them selectively based on what the user says; do not march through every item.

---

## Stage 1: Problem Definition & Motivation (problem)

**Core questions**
- State your research question in one sentence. If it takes two sentences, it probably needs to be split.
- Why is this problem worth doing now? What made it infeasible two years ago?
- If the research succeeds, what changes in the field? Who will cite you?
- Are you filling a gap or changing understanding? The two differ in both value and how they are written up.

**Follow-ups**
- What exactly do you mean by "X"? Can you give a concrete input/output example?
- Where exactly do existing methods fall short on this problem: quality, efficiency, generalization, cost — or are they fundamentally unable to do it?
- Is this a whether question, a how-much question, or a why/how question?
- Does your question already contain its expected answer? If so, is it a question or a hypothesis?

**When stuck**: use the funnel strategy — rewrite the user's broad topic into 2-3 candidate research questions at different granularities (from open-ended to precise) and let the user pick or modify one.

---

## Stage 2: Related Work & Positioning (related_work)

**Core questions**
- What are the 3-5 works closest to your idea? Summarize what each one does in a sentence.
- If your research is a conversation, who are you responding to? Are you supporting or challenging the field's mainstream narrative?
- What is the one thing these works collectively cannot do? — that sentence is your positioning.

**Follow-ups**
- Is there an important paper you actually disagree with? Why?
- Have you deliberately searched for literature that contradicts your view?
- Which paper is a reviewer most likely to point at and say "hasn't this been done already"? How will you respond?

**When stuck**: if the user's literature coverage is thin, don't spin — give 2-3 search keyword combinations for them to look up, or suggest running the deep-research skill for a literature survey first; mark this section `in_progress`, move on to later stages, and come back to it.

---

## Stage 3: Core Method (method)

**Core questions**
- What is your key insight? One sentence, avoiding vague verbs like "combine", "fuse", or "incorporate".
- Why should this method work? What is the intuition, theoretical grounding, or preliminary observation?
- Where exactly is the novelty: new problem, new method, new analysis, or new application? Name the type explicitly.

**Follow-ups**
- Is there a simpler method that could also answer your question? Why not use it? (Reviewers will ask.)
- What is the biggest weakness of your method?
- If you removed the most complex component of your method, what would happen?
- What assumptions are you relying on? Which one is the most fragile?

**When stuck**: offer 2-3 technical routes at different risk levels (conservative improvement / moderate / aggressive), stating each one's expected payoff and failure risk, and let the user choose or combine.

---

## Stage 4: Experiments & Validation Design (experiments)

**Core questions**
- List every claim your plan will make. Which experiment supports each one? (Build a claim → experiment table.)
- Which datasets and baselines, and why those rather than stronger or more recent ones?
- What is the primary metric? How large an improvement counts as "meaningful" rather than noise?

**Follow-ups**
- How will the ablations be designed? Can they attribute the gains to your core contribution rather than engineering and tuning?
- Is your compute and time budget enough to run all the experiments? Which experiment is the most expensive? Is it worth it?
- What experimental result would make you abandon or substantially revise the method? (This answer also belongs to Stage 5.)

**When stuck**: this is the stage best suited to offering options — based on the user's task type, directly present 2-3 common evaluation setups for that direction (datasets + metrics + representative baselines) and let the user pick one to fine-tune.

---

## Stage 5: Risks & Fallbacks (risks)

**Core questions**
- What is the single most likely point of failure in the whole plan?
- If the core assumption doesn't hold, what is Plan B?
- Is there a cheap experiment that tells you early whether this will die? Do it first.

**Follow-ups**
- Of the external conditions you depend on (data availability, open-source code, compute, collaborators), which is the least controllable?
- In the worst case, what can this project still produce? Negative results, benchmarks, and analytical conclusions are deliverables too.

**When stuck**: run a pre-mortem for the user — "Assume the project failed a year from now; what was the most likely cause of death?" List 3 candidate causes and have the user rank them.

---

## Stage 6: Milestones & Deliverables (milestones)

**Core questions**
- What is the smallest experiment (MVP) that validates feasibility? How soon can it produce a result?
- What is the target venue and submission date? Work the milestones backward from the deadline.
- What is the completion criterion for each milestone? It must be verifiable ("get X running and reach Z on Y", not "explore X").

**Follow-ups**
- Which parts can run in parallel? Where is the critical path?
- What resources are needed (compute / data / annotation / collaborators)? What is still missing, and by when must it be in place?

**When stuck**: scaffold a default timeline in four segments — "minimal validation → core method working → full experiments → writing and submission" — and let the user fill in dates and adjust.
