# Research Plan Quality Checklist

Check each item during the final quality pass. Rank failing items by importance and report at most 5 to the user, each with a concrete improvement suggestion and the section it belongs to.

1. **The research question fits in one sentence** and is verifiable/falsifiable — after reading it, you know exactly what "success" looks like.
2. **The gap is "the field cannot do this", not "I haven't done this yet"** — a blank space is not motivation by itself; the plan must say why this gap is worth filling.
3. **The related-work positioning can answer "hasn't this been done already?"** — with an explicit point of differentiation from the closest work.
4. **The method section argues why it should work** — at least one of intuition, theory, or preliminary evidence; the novelty type (new problem / new method / new analysis / new application) is explicit.
5. **Every claim has a matching experiment** — claims and experiments correspond one-to-one; no claim without experimental support, and no experiment serving no claim.
6. **Metrics and the "meaningful improvement" threshold are explicit** — not "improves performance" but "must beat Y by at least Z on X to be convincing".
7. **The ablation design attributes gains to the core contribution** — ruling out "won by tuning / data / compute" explanations.
8. **There are kill criteria and a Plan B** — the plan states which experimental results would refute the direction, and where to pivot when that happens.
9. **The first milestone is a cheap minimal validation experiment** — the riskiest assumption gets tested first, not last.
10. **The timeline matches the resources** — the compute/data/staffing budget can support the experimental plan; the critical path is clear.
11. **Verbs are concrete throughout** — no "combine, explore, look into"-style phrasing whose completion cannot be verified.
