# Experiment Analysis Rubric

How a run is examined, what gets recorded, and how the verdict is reached. Apply every dimension to every run: A and B say what exists, C says whether the run is trustworthy, D scores it against the plan, E says what it means, F says who acts next. An observation must name its dimension, severity, source, and implication — a remark no file backs is an impression, not an observation.

The project guidelines cited as §n below are AGENTS.md's numbered sections; §1–§6 of a *plan* are the sub-plan's own sections. Skill names appear bare (`star-plan-executor`); invoke them the way this tool invokes skills.

## Observation contract (structured return)

One entry per observation, grouped by dimension:

```yaml
- dimension: A | B | C | D | E
  severity: blocker | major | minor | nit
  source: <path from project root, + line number or key>
  observation: <one sentence — what is true>
  evidence: <the quoted line, the number, or the `ls` fact>
  implication: <what it means for the run's verdict, one sentence>
```

## Metric row contract

One entry per scored expectation — this is what fills the scorecard:

```yaml
- criterion: <the plan's own words, quoted>
  origin: sub-plan §5 | root §4 | root §5 kill-criterion | stated baseline
  metric: <name as the source prints it>
  value: <as the source prints it — do not round into a different verdict>
  split: train | val | test | unknown
  threshold: <as the plan states it, or "none stated">
  verdict: met | not met | unmeasurable
  source: <path, + line number or JSON key>
```

Collectors return exactly these two lists (plus `files_read: <n>`) and nothing else: no verdicts on the run, no interpretation, no files written.

## Severity ladder (observations)

- **blocker** — the run's results cannot be trusted or used: the process died before producing them, an eval read the training split, a checkpoint is empty/corrupt, the metric quoted in the log is not in the file it cites, a §4 deliverable the done-criterion depends on is missing.
- **major** — materially changes the reading: a §5 criterion missed, NaN/Inf in training, loss diverged, train↓/val↑ divergence, a STOP-line command never run, an artifact written outside the layout rules (§5), a metric available only from a weaker source than the plan implies.
- **minor** — worth recording, does not move the verdict: a recoverable warning storm, a dataloader worker that died and restarted, an extra artifact nobody promised, a metric reported at lower precision than the threshold needs.
- **nit** — polish: an inconsistently named artifact, a log without timestamps. Report nits only for runs that already carry higher observations.

When severity is in doubt, grade down and say why in `implication`.

## Run verdict ladder

Exactly one, for the report's headline:

- **met** — every §5 criterion was checked and met, and nothing blocker-level undermines them.
- **partially met** — some criteria met, some missed, all checked.
- **not met** — the criteria were checked and missed. A real, reportable result.
- **inconclusive** — the evidence to judge is not there: STOP-line commands never run, the run stopped early, the metric exists nowhere. Not a synonym for "not met" — say which evidence is missing and what would produce it.
- **invalid** — results exist but cannot be trusted: leakage, a crashed run marked done, a metric from the wrong split. Never soften this into "partially met"; an invalid run is re-run, not interpreted.

## A. Artifact inventory

- Every §4 deliverable, by its stated path: `present` / `missing` / `unexpected` (on disk, promised nowhere).
- Light integrity, per artifact type: file is non-empty; JSON/CSV parses and has the fields the plan names; a checkpoint is neither 0 bytes nor implausibly small for the architecture; an image opens; a directory holds roughly the expected count (e.g. one checkpoint per saved epoch).
- Layout conformance (§5): generated outputs under `wkdrs/<run>/`, data under `datas/`, weights under `inits/`; nothing generated left in `metds/` or inside the package.
- Record the run's real size on disk — a researcher deciding what to keep needs it.

Not an observation: the routine debris a normal run leaves (`__pycache__/`, `events.out.tfevents.*`, `.lock`, editor swap files); artifacts an ordinary framework writes without being promised (a `config.yaml` snapshot, a `latest.ckpt` symlink).

## B. Completion cross-check

- Every EXEC_LOG step marked `done`: does the artifact it names exist, and is it consistent with what the step claims to have produced? A `done` step whose artifact is absent is a **blocker** — the log is wrong about reality.
- Every "Awaiting user" STOP-line item: `run by the user` (the output it promised exists) or `still pending` (it does not). Never assume it ran because time passed.
- EXEC_LOG's frontmatter `status` vs its own step rows: a log saying `done` with `blocked` rows, or `in_progress` with every row `done`, is an inconsistency worth a minor observation.
- "Pending amendments" left unsynced, and any recorded **Strategy signal**: carry them into the report — they are the executor's own note that the plan and reality diverged.

The rule: the log is a claim, disk is the evidence. Corroborate in that direction, never the reverse.

## C. Log health

Scan every log the run wrote (`*.log`, stdout captures, framework logs under `wkdrs/<run>/`).

**Fatal signals** (blocker): a traceback; `CUDA out of memory`; `Killed` / OOM-killer; a non-zero exit recorded; NCCL / distributed timeouts that ended the run; a log truncated mid-epoch with no completion marker while the step claims `done`.

**Numeric signals** (major): `nan` / `inf` in loss or gradients; loss flat from the first step (nothing is learning); loss diverging; gradient-overflow spam that never recovers; a metric identical across every epoch (frozen weights, or evaluation never re-run).

**Dynamics signals** (major or minor, per severity of the gap): train loss falling while val loss rises (overfitting) — say from which epoch; a val metric that plateaued long before the run ended (wasted compute, or a learning-rate problem); a metric that peaked mid-run and was not the one checkpointed.

**Warnings worth surfacing** (minor): dataloader workers dying and restarting; checkpoint-save failures that were retried; mixed-precision overflow warnings; a dataset silently smaller than the plan's §2 says.

Not an observation: deprecation warnings, tqdm/progress noise, framework banner spam, expected early stopping that the plan called for.

### Reading big logs

Never load a multi-megabyte log whole. In order: grep the fatal and numeric patterns above; read the **head** (the config echo — it records what actually ran, including the split, the seed, and the data paths, and it is where leakage shows up); read the **tail** (the final summary and the metric); then sample the middle at epoch markers to reconstruct the trend. Quote line numbers from the real file so Step 4 can re-open them.

## D. Metrics vs expectations

- Extract each metric from the most authoritative source available, in this order: a results JSON/CSV the run wrote > the eval log's final summary block > a TB event file (only if tensorboard is already installed) > the last matching line in a training log. Record which one it came from; a criterion that only survives at the weakest tier is a minor observation about the run's reporting.
- Score every yardstick as a metric row: §5 done-criteria first, then root §4 metrics, then any baseline the plan states.
- **Split discipline**: name the split every number came from. If the plan states a threshold without one ("mAP ≥ 30"), report the number from the split the plan's §5 context implies, name the ambiguity, and never pick the flattering split.
- **No stated expectation** is a legitimate row: report the number, leave `threshold: none stated`, and do not grade it. An ungraded number is honest; a retrofitted threshold is not.
- **Unmeasurable** means the number is not on disk anywhere. Say what would produce it and hand that command back — never run it (§ the STOP line).
- Quote values as the source prints them. Rounding that flips a verdict (29.96 → "30, met") is a blocker-level reporting error.

## E. Interpretation

- **Against the claim**: the sub-plan's `traces_to` names the root claim or section this run serves. State plainly whether the result supports it, refutes it, or leaves it open — and for "open", what is still missing.
- **Kill-criteria**: check the result against the root's §5 kill-criteria and against any MVP done-criterion the plan called a cheap early test. A hit is a **strategy signal**: report it prominently, route it (F), and never soften it. A plan that kills a bad idea early is working.
- **Leakage and too-good checks** — run these before accepting a strong number: is the val/test split named in the training config's data paths? Is val ≈ train to an implausible degree? Does the number beat the published state of the art on a first run? Is the metric at or near its ceiling (1.000, 100%)? Was the checkpoint selected on the same split it is reported on? Any hit → the verdict is `invalid` until the user rules it out.
- **Limits, stated as limits**: one seed is not significance; a subset is not the benchmark; a metric with no baseline is not an improvement; a single run's gap smaller than the framework's known variance is not a result. Write what the run does *not* show.

## F. Routing

Map each unresolved item to exactly one owner; the analyst itself writes nothing but the report.

| What the analysis found | Route to |
| --- | --- |
| Steps unfinished, a step `blocked`, or a STOP-line command still pending | `star-plan-executor` (resume the run) |
| §5 criteria met — the run needs its final verification and `exec_status` | `star-plan-executor` (it owns finalization; the analyst never flips status) |
| The plan text no longer describes what was actually done or produced | `star-plan-reviser` (evidence-based revision, per-item approved) |
| A root kill-criterion hit, or the `traces_to` claim refuted | `star-plan-reviser` (revise from evidence) → `star-plan-coach` (revisit method and risks) → `star-plan-decomposer` (re-scope the sub-plans) |
| The logs point at a code defect (a bug, a wrong path, a mis-wired metric) | `star-code-reviewer` (scoped to this plan) |
| Import errors, missing CUDA, a package the run needed | `star-env-builder` |
| A metric that only a new run can produce | The user — a prepared command, never executed here |
