# Research Plan Quality Checklist

Check each item. For each, give the verdict, the quoted line (or the exact statement of what is absent), and, where the plan falls short, a concrete fix naming the section it belongs to. Which items reach the user, and in what order, is decided afterwards, once each `fail` is confirmed against the plan.

1. **The research question fits in one sentence** and is verifiable/falsifiable — after reading it, you know exactly what "success" looks like.
2. **The gap is "the field cannot do this", not "I haven't done this yet"** — a blank space is not motivation by itself; the plan must say why this gap is worth filling.
3. **The related-work positioning can answer "hasn't this been done already?"** — with an explicit point of differentiation from the closest work.
4. **The method section argues why it should work** — at least one of intuition, theory, or preliminary evidence; the novelty type (new problem / new method / new analysis / new application) is explicit.
5. **Every claim has a matching experiment** — claims and experiments correspond one-to-one: no claim without an experiment, no experiment without a claim.
6. **Metrics and the "meaningful improvement" threshold are explicit** — not "improves performance" but "must beat Y by at least Z on X to be convincing" — and §4 states how many seeds or repeats back each headline number and how variance is reported. Single-seed is acceptable while a milestone is still a pilot, §4 then saying which numbers it covers and what would end the exemption; a number §4 lists as a headline claim fails this item until it carries a seed count.
7. **The ablation design attributes gains to the core contribution** — ruling out "won by tuning / data / compute" explanations.
8. **There are kill criteria and a Plan B** — the plan states which experimental results would refute the direction, and where to pivot when that happens.
9. **The first milestone is a cheap minimal validation experiment** — the riskiest assumption gets tested first, not last.
10. **The timeline matches the resources** — the compute/data/staffing budget can support the experimental plan; the critical path is clear.
11. **Verbs are concrete throughout** — no "combine, explore, look into"-style phrasing whose completion cannot be verified.
