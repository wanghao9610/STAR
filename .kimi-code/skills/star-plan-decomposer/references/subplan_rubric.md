# Sub-plan Quality Checklist

Run this over each sub-plan you wrote. Rank failing items by importance and report at most 5 to the user, each naming the file and a concrete fix.

1. **The objective is one coherent chunk, traced to the root** — §1 says in one or two sentences what this sub-plan delivers, and `traces_to` names the exact root section/claim it serves. No sub-plan re-opens the research question or method (that's the root plan's job).

2. **Non-goals are explicit** — §1 says what is deliberately left to siblings or deeper depth, so adjacent sub-plans don't double-own the same work.

3. **Dependencies are concrete, located, and encoded** — §2 names actual datasets (`datas/`), weights (`inits/`), code (`code/`), and any upstream sub-plans (by prefix) that must finish first, with the artifact each hands over. No vague "the data" / "the model". The `depends_on` frontmatter list mirrors those upstream sibling prefixes, forms an acyclic graph, and is consistent with the order shown in the parent's `## Sub-plans` index.

4. **Every step is verb-concrete and checkable** — §3 has no "explore / combine / look into" verbs whose completion can't be verified; each numbered step is small enough that "done or not" is unambiguous.

5. **Deliverables have a name and a home** — §4 places outputs under the correct project directory (`wkdrs/<run>` for generated output, `datas/`, `inits/`, and `tasks/<plan-name>/` for the plan's own tool scripts — never `execs/`) with a run name that distinguishes this task/experiment; it names the artifacts, not just "results".

6. **There is a real done-criterion** — §5 states a single check that proves completion (a test that passes, a metric over a threshold, a specific output that exists), with the threshold tied back to the root's §4 metrics or §5 kill-criteria where relevant. If it can't be checked, it isn't done-criterion. A metric-based done-criterion also states the seed/repeat policy it is measured under (or explicitly accepts single-seed as an MVP smoke test) — `star-expt-analyst` scores exactly what is written.

7. **Local risks are execution-level, not research-level** — §6 covers what could make *this step* fail or stall (with an early signal and a local fallback), and does not just restate the root's research risks.

8. **The sub-plan is right-sized** — it owns one independently checkable chunk. Too big (no single done-criterion fits) → recommend recursing one level deeper. Too small (nothing to verify on its own) → recommend merging into a sibling.

9. **Coverage without overlap** — taken together, the sibling sub-plans cover the scope they decompose — the root §3/§4/§6 material the parent node owns — and no piece is owned by two of them.

10. **Frontmatter is consistent** — `prefix` matches the filename, `parent` is the exact parent filename, `level` equals the prefix length, and `language` matches the parent plan. The parent's `## Sub-plans` index and `children:` list include this file.
