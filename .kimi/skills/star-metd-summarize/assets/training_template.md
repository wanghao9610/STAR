---
type: training
language: en
generated: <YYYY-MM-DD>
model_id: <model id, copied verbatim from what your runtime states this session — your Kimi session reports it where available; "unrecorded" only if the session names none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
sources:
  - plan: <prefix>_<slug>_plan.md
    updated: <YYYY-MM-DD>
---

<!-- Compiled by star-metd-summarize from metds/plans/. Hand edits are overwritten on the next
     run — to change this document, change the plan it came from. -->

# Training

## 1. Training Pipeline

<!-- The stages end to end (e.g. pretrain → align → finetune), in the order the leaves' depends_on
     gives. One row per stage; depth is §2. Single-stage training says so in one line rather than
     dressing itself up as a pipeline. -->

| Stage | Data | Initialized from | Trains | Produces |
|---|---|---|---|---|
| <1. name> | <dataset> | `inits/<…>` | <which parameters> | `wkdrs/<run>/<…>` |

## 2. Stage Detail

<!-- One subsection per stage, from the training leaves' §3 steps and §2 inits/ inputs, with the
     compute the root §4 budgets. -->

### 2.1 <Stage>

**Objective.** <the loss(es) and what they push toward>
**Trainable / frozen.** <which parameters move, which are held>
**Optimizer & schedule.** <optimizer, LR schedule, warmup, epochs or steps>
**Compute budget.** <GPUs × hours, as the plan states it>

## 3. Hyperparameters

<!-- What a reproducer needs. Only values a plan states; a value no plan fixes stays `TBD` and is
     reported as a gap — a plausible default filled in here becomes a wrong number in a paper. -->

| Parameter | Stage | Value | Source |
|---|---|---|---|
| learning rate | <stage> | <value> | `<plan> §<n>` |

## 4. Practical Notes

<!-- What the plans record about making training actually work: stability measures, known failure
     modes with the early signal to watch, memory or throughput measures, checkpoint policy. From
     the training leaves' §6 local risks. Write "None recorded" rather than inventing advice. -->

## 5. Reproduction

<!-- Per stage: the entry point, the config, and the launch command through the project's conda
     env (via execs/run.sh where the plans use one), plus where outputs land under wkdrs/. Commands
     as the plans record them — this document is read, never executed. -->
