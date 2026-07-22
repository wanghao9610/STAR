# Review — <prefix>_<slug> (<YYYY-MM-DD>)

<!-- Written by $star-plan-reviser (model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none>). Target: metds/plans/<file>; node type: leaf | internal | root;
     exec_runs: <run dirs, newest last, or none>. Every claim cites evidence (path[:line], command output, or a
     frontmatter field). Sections with nothing to say collapse to one line — never pad. -->

## 1. Intent Recap

<!-- The objective in 1–2 lines. Leaf: quote the §5 done-criterion verbatim.
     Root/internal: finalized state and the key claims/assumptions the plan rests on. -->

## 2. What Actually Happened

<!-- From the run log(s) and disk, not from memory: steps done / blocked / skipped; artifacts
     verified on disk; commands still under "Awaiting user". Root/internal: children rollup
     (per child: exec_status, steps done/total, notable signals). -->

## 3. Completion Scorecard

<!-- One row per §3 task plus a final row for the §5 done-criterion.
     Verdict: met / partial / unmet / unverifiable (see review_spec). Every row cites evidence. -->

| Item | Verdict | Evidence |
| --- | --- | --- |
| §3.1 <task> | <verdict> | <path[:line] / output snippet> |
| §5 done-criterion | <verdict> | <evidence> |

Overall: <n>/<m> tasks met; done-criterion: <verdict>.

## 4. Divergences

<!-- Plan said X, the run did Y; extra work not in the plan; assumptions the evidence contradicts;
     kill-criteria hits and Strategy signals quoted from the log. -->

## 5. Blockers & Leftovers

<!-- Blocked steps and why; remaining [TBD] / 【待定】; questions the run raised but did not answer. -->

## 6. Ripple Map

<!-- Reverse depends_on edges (siblings that list this node); children derived from it;
     which revision candidates below would invalidate what. -->

## 7. Revision Candidates

<!-- Numbered. Blast radius: local (this file) / structural (tree shape → $star-plan-decomposer) /
     strategic (direction → $star-plan-coach). Each candidate is decided by the user, one at a time;
     adopted changes land in the plan file and its Revision History, not here. -->

1. [<local|structural|strategic>] §<n> — <what to change>
   - Why: <evidence>
   - Proposed edit: <one-line sketch>
