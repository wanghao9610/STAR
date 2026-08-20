# Experiment Analysis Rubric

How a run is examined, what gets recorded, and how the verdict is reached. Apply every dimension to every run: A and B say what exists, C whether the run is trustworthy, D scores it against the plan, E what it means, F who acts next. An observation must name its dimension, severity, source, and implication — a remark no file backs is an impression, not an observation.

§n below cites AGENTS.md's numbered project guidelines; §1–§6 of a *plan* are the sub-plan's own sections. Skill names appear bare (`star-plan-executor`); invoke them the way this tool invokes skills.

## Observation format (structured return)

One entry per observation, grouped by dimension:

```yaml
- dimension: A | B | C | D | E
  severity: blocker | major | minor | nit
  source: <path from project root, + line number or key>
  observation: <one sentence — what is true>
  evidence: <the quoted line, the number, or the `ls` fact>
  implication: <what it means for the run's verdict, one sentence>
```

## Metric row format

One entry per scored expectation — it fills the scorecard:

```yaml
- criterion: <the plan's own words, quoted>
  origin: sub-plan §5 | root §4 | root §5 kill-criterion | stated baseline
  metric: <name as the source prints it>
  value: <as the source prints it — do not round into a different verdict>
  split: train | val | test | unknown
  seeds: <n, or 1 — how many runs or repeats this value is over>
  spread: <std, min–max, or "— single run">
  threshold: <as the plan states it, or "none stated">
  verdict: met | not met | unmeasurable
  source: <path, + line number or JSON key>
  commit: <short-sha of ${CODE_NAME} the run executed at, from EXEC_LOG's `code_commit:` | unrecorded>
```

A collection pass returns exactly these two lists (plus `files_read: <n>`) and nothing else: no verdicts on the run, no interpretation, no files written. A dimension-C collector returns observations; it fills a metric row only where the metric's sole source is a line in a log on its own list, because D's source ladder compares across files and belongs to the agent holding all of them. It also returns one `config_echo` per log — `{source: <path>:<first–last line>, lines: <the verbatim config / argv / data-path block, ≤40 lines, kept to the data-path and split portion>}`, or `none` where the log has no echo. Quote it, never paraphrase and never judge: the main agent runs E's leakage and too-good checks against it, re-opening the cited range only on a hit. A `files_read` below the number of files the collector was given is the remainder still to collect (conventions §6.3).

## Severity levels (observations)

- **blocker** — the run's results cannot be trusted or used: the process died before producing them, an eval read the training split, a checkpoint is empty/corrupt, the metric quoted in the log is not in the file it cites, a §4 deliverable the done-criterion depends on is missing.
- **major** — materially changes the reading: a §5 criterion missed, NaN/Inf in training, loss diverged, train↓/val↑ divergence, a STOP-line command never run, an artifact written outside the layout rules (§8), a metric available only from a weaker source than the plan implies.
- **minor** — worth recording, does not move the verdict: a recoverable warning storm, a dataloader worker that died and restarted, an extra artifact nobody promised, a metric reported at lower precision than the threshold needs.
- **nit** — polish: an inconsistently named artifact, a log without timestamps. Report nits only for runs that already carry higher observations.

When severity is in doubt, grade down and say why in `implication`.

## Run verdict levels

Exactly one, for the report's headline:

- **met** — every §5 criterion was checked and met, and nothing blocker-level undermines them.
- **partially met** — some criteria met, some missed, all checked.
- **not met** — the criteria were checked and missed. A real, reportable result.
- **inconclusive** — the evidence to judge is not there: STOP-line commands never run, the run stopped early, the metric exists nowhere. Not a synonym for "not met" — say which evidence is missing and what would produce it.
- **invalid** — results exist but cannot be trusted: leakage, a crashed run marked done, a metric from the wrong split. Never soften this into "partially met"; an invalid run is re-run, not interpreted.

## A. Artifact inventory

- Every §4 deliverable, by its stated path: `present` / `missing` / `unexpected` (on disk, promised nowhere).
- Light integrity, per artifact type: file is non-empty; JSON/CSV parses and has the fields the plan names; a checkpoint is neither 0 bytes nor implausibly small for the architecture; an image opens; a directory holds roughly the expected count (e.g. one checkpoint per saved epoch).
- Layout conformance (§8): generated outputs under `wkdrs/<run>/`, data under `datas/`, weights under `inits/`; nothing generated left in `metds/` or inside the package.
- Record the run's real size on disk — a researcher deciding what to keep needs it.

Not an observation: routine debris a normal run leaves (`__pycache__/`, `events.out.tfevents.*`, `.lock`, editor swap files); artifacts an ordinary framework writes without being promised (a `config.yaml` snapshot, a `latest.ckpt` symlink).

## B. Completion cross-check

- Every EXEC_LOG step marked `done`: does the artifact it names exist, and does it match what the step claims to have produced? A `done` step whose artifact is absent is a **blocker** — the log is wrong about reality.
- Every "Awaiting user" STOP-line item: `run by the user` (the output it promised exists) or `still pending` (it does not). Never assume it ran because time passed.
- EXEC_LOG's frontmatter `status` vs its own step rows: a log saying `done` with `blocked` rows, or `in_progress` with every row `done`, is a minor observation.
- "Pending amendments" left unsynced, and any recorded **plan-level finding**: carry them into the report — the executor's own note that the plan and reality diverged.

The rule: the log is a claim, disk is the evidence. Corroborate in that direction, never the reverse.

## C. Log health

Scan every log the run wrote (`*.log`, stdout captures, framework logs under `wkdrs/<run>/`).

**Fatal signals** (blocker): a traceback; `CUDA out of memory`; `Killed` / OOM-killer; a non-zero exit recorded; NCCL / distributed timeouts that ended the run; a log truncated mid-epoch with no completion marker while the step claims `done`.

**Numeric signals** (major): `nan` / `inf` in loss or gradients; loss flat from the first step (nothing is learning); loss diverging; gradient-overflow spam that never recovers; a metric identical across every epoch (frozen weights, or evaluation never re-run).

**Dynamics signals** (major or minor, per severity of the gap): train loss falling while val loss rises (overfitting) — say from which epoch; a val metric that plateaued long before the run ended (wasted compute, or a learning-rate problem); a metric that peaked mid-run but was not checkpointed.

**Warnings worth reporting** (minor): dataloader workers dying and restarting; retried checkpoint-save failures; mixed-precision overflow warnings; a dataset silently smaller than the plan's §2 says.

Not an observation: deprecation warnings, tqdm/progress noise, framework banner spam, early stopping the plan called for.

### Reading big logs

Never load a multi-megabyte log whole. In order: grep the fatal and numeric patterns above; read the **head** (the config echo — what actually ran: the split, the seed, the data paths, and where leakage shows up); read the **tail** (the final summary and the metric); then sample the middle at epoch markers to reconstruct the trend. Quote line numbers from the real file so Step 4 can re-open them.

## D. Metrics vs expectations

- Extract each metric from the most authoritative source available, in this order — a ranking across sources, so the main agent holding all of them applies it, never a collector holding one file: a results JSON/CSV the run wrote > the eval log's final summary block > a TB event file (only if tensorboard is already installed) > the last matching line in a training log. Record which one it came from; a criterion that only survives at the weakest tier is a minor observation about the run's reporting.
- Score every review rule as a metric row: §5 done-criteria first, then root §4 metrics, then any baseline the plan states.
- **Split discipline**: name the split every number came from. If the plan states a threshold without one ("mAP ≥ 30"), report the number from the split the plan's §5 context implies, name the ambiguity, and never pick the flattering split.
- **No stated expectation** is a legitimate row: report the number, leave `threshold: none stated`, and do not grade it. An ungraded number is honest; a retrofitted threshold is not.
- **Unmeasurable** means the number is not on disk anywhere. Say what would produce it and hand that command back — never run it (§ the STOP line).
- Quote values as the source prints them. Rounding that flips a verdict (29.96 → "30, met") is a blocker-level reporting error.
- **A set of configurations is read as a whole grid**: where the run directory has `cells/`, start from `matrix.md`, check every cell has a number — a missing cell is blocked, not a bad result — then score against §5. Report the chosen cell only with the spread along the same axis; the best cell alone hides the selection. Cells repeated over seeds report median and range, never the best draw.
- **Cost reconciliation**: read EXEC_LOG's cost section beside the root plan's §4 compute budget in one line — what fraction of the budget the actual came to, and by how much it went over. Where the actual says `unrecorded`, say so plainly rather than skip the line: compute is the one thing this workflow spends that cannot be recovered. Where the root §4 claim→experiment map puts this run and a baseline run in the same table, print both runs' actual cost on that line, not this one alone, and flag an order-of-magnitude gap as a `major` observation. That is two recorded numbers set beside each other, not a cause assigned to a delta — inside the never-attribute rule, not against it.

## E. Interpretation

- **Against the claim**: the sub-plan's `traces_to` names the root claim or section this run serves. State plainly whether the result supports it, refutes it, or leaves it open — and for "open", what is still missing.
- **Kill-criteria**: check the result against the root's §5 kill-criteria and any MVP done-criterion the plan called a cheap early test. A hit is a **plan-level finding**: report it prominently, route it (F), and never soften it. A plan that kills a bad idea early is working.
- **Leakage and too-good checks** — run these before accepting a strong number: is the val/test split named in the training config's data paths? Is val ≈ train to an implausible degree? Does the number beat the published state of the art on a first run? Is the metric at or near its ceiling (1.000, 100%)? Was the checkpoint selected on the same split it is reported on? Is the evaluation benchmark plausibly inside the training corpus of the weights §2 names — and did §2 name that corpus at all? Any hit → the verdict is `invalid` until the user rules it out; an `unknown` corpus behind a first-run number that beats the published state of the art is a `major` observation, not a clean pass.
- **A pilot run is judged on the decision, not the number**: where the sub-plan's §5 is written as "what to look at → which decision each outcome triggers", the verdict is whether the decision was recorded and the evidence carries it. Its numbers stay provisional and never enter the results table — a pilot exists to settle what to do next, not to produce a result.
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
