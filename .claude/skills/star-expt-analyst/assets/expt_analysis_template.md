---
run: <prefix>_<slug>
source_plan: <prefix>_<slug>_plan.md
analyzed: <YYYY-MM-DD>
verdict: <met | partially met | not met | inconclusive | invalid>
---

# Experiment Analysis — <run> (<YYYY-MM-DD>)

<!-- Written by /star-expt-analyst. Read-only audit of what this run produced, scored against what
     the plan expected. Every number here was re-opened at its source before it was written down.
     Sections with nothing to say collapse to one line — never pad. -->

## 1. Scope & Evidence Base

<!-- The run dir and how it resolved (plan name → exec_run, or a path → its plan). Expectations
     loaded: sub-plan §4/§5, parent §4 metrics and §5 kill-criteria, EXEC_PLAN/EXEC_LOG — and which
     were absent. Files read (counts, not a listing). Sibling runs detected. Degradations: "no
     matplotlib — text-only", "tensorboard absent — TB metrics unread", "env unusable — reading
     only". -->

## 2. Verdict

<!-- 2–4 lines. The run verdict (met / partially met / not met / inconclusive / invalid) and why,
     then any blocker/major observations by number. Honest, not hedged: `inconclusive` and `invalid`
     are answers. No grade inflation, no alarmism. -->

## 3. Done-Criteria Scorecard

<!-- The headline. One row per yardstick: sub-plan §5 first, then parent §4 metrics, then any
     baseline the plan states. `threshold: none stated` → report the value, leave the verdict blank.
     Value as the source prints it — rounding that flips a verdict is an error, not a tidy-up. -->

| Criterion (as written) | Origin | Metric | Value | Split | Threshold | Verdict | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| <"…"> | §5 / parent §4 / baseline | <name> | <value> | train/val/test | <threshold or none stated> | met / not met / unmeasurable | <path:line or key> |

## 4. Artifacts & Completion

<!-- A: §4 deliverables vs disk, with the integrity result. B: EXEC_LOG's `done` claims corroborated
     against artifacts, and each "Awaiting user" STOP-line command as run / still pending. A `done`
     step with no artifact is a blocker. Close with the run's size on disk, and any unsynced
     "Pending amendments" or Strategy signal the log carries. -->

| Deliverable (§4) | On disk | Integrity | Note |
| --- | --- | --- | --- |
| <path> | present / missing / unexpected | <non-empty, parses, plausible size> | <…> |

## 5. Log Health

<!-- C: fatal / numeric / dynamics signals, each with `path:line` and the quoted evidence. Routine
     warning noise is not reported. If the logs are clean, say so in one line — a clean run is a
     finding worth stating. -->

## 6. Metrics & Comparison

<!-- The numbers behind §3, with the source tier each came from (results JSON > eval summary >
     TB event > log line) and any reporting caveat. -->

### Figures

<!-- Rendered only when matplotlib was already installed: relative links to wkdrs/<run>/analysis/*.png
     plus one line each on what the curve shows. Beside each figure is the script that made it, so it
     can be regenerated. Otherwise: "no figures — matplotlib not installed in the .env env". -->

### Cross-run comparison

<!-- Only when sibling runs of the same plan exist (same <prefix>_<slug> stem). Headline metrics
     only — the ones §5 names. State which direction the numbers moved; do NOT attribute the delta to
     a cause: naming why a variant won needs a controlled comparison this skill does not run.
     Omit the section entirely when this run is the only one. -->

| Run | <metric> | <metric> | Note |
| --- | --- | --- | --- |
| <this run> | <value> | <value> | <…> |
| <sibling> | <value> | <value> | <…> |

## 7. Interpretation

<!-- E: does the result support / refute / leave open the claim in `traces_to`? Any parent §5
     kill-criterion hit (state it prominently — a strategy signal is the plan working). The leakage
     and too-good checks that were run and what they showed. Then the limits, as limits: seeds,
     split size, variance, what this run does NOT show. -->

## 8. Recommendations & Routing

<!-- One owner per open item; this skill writes nothing but this report. Unfinished steps or a
     pending STOP-line command → /star-plan-executor <slug>; §5 met and needing finalization →
     /star-plan-executor <slug> (it owns exec_status); plan text no longer true →
     /star-plan-reviser <slug>; kill-criterion hit or claim refuted → /star-plan-reviser /
     /star-plan-coach / /star-plan-decomposer; a code defect the logs point at →
     /star-code-reviewer <slug>; a broken env → /star-env-builder. Metrics that need a new run:
     the exact command, ready to paste, never executed here. -->
