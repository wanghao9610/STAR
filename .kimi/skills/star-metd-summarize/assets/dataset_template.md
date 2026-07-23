---
type: dataset
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

# Datasets

## 1. Dataset Inventory

<!-- Every dataset the method touches, one row each, from the root §4 choices and every leaf's
     §2 datas/ inputs. `Path` is the location the plans name under datas/; `Role` is what it is
     used for, not what it is. -->

| Dataset | Source | Split(s) used | Scale | Path (`datas/…`) | Role |
|---|---|---|---|---|---|
| <name> | <origin / license> | <train / val / test> | <#samples> | `datas/<…>` | <train / eval / ablation> |

## 2. Per-dataset Detail

<!-- One subsection per dataset whose row does not say enough: what it contributes, the
     annotation it carries, and what makes it the right choice here. Skip a dataset that is
     fully described by its row — a subsection restating the table is noise. -->

### 2.1 <Dataset>

**Why this dataset.** <the role it plays that another could not>
**What it provides.** <images / pairs / labels / annotations>
**Caveats.** <domain limits, bias, license constraints — only what the plans record>

## 3. Preprocessing

<!-- Raw → trainable, in order: resizing, tokenization, filtering, augmentation, format
     conversion. From the data leaves' §3 steps and the §4 artifacts they produce. Name the
     module under ${CODE_NAME}/ wherever a plan names one; a step with no owner is a gap. -->

## 4. Constructed Data

<!-- Only if the method builds its own data: the generation pipeline stage by stage, its inputs,
     the quality controls that decide what is kept, and where the artifact lands under datas/.
     Write "None — all datasets are used as published" when nothing is built. -->

## 5. Statistics

<!-- The numbers a reader needs to judge scale and balance: per-split counts, category
     distribution, resolution or length ranges. Only numbers the plans state. A number that
     would need a run to obtain is a gap here, not a task — it belongs to the run that measures
     it and its analysis report under wkdrs/. -->

## 6. Dataset → Experiment Map

<!-- Which dataset serves which claim or stage, so the training and evaluation protocols have a
     data grounding. From the root §4 claim→experiment table and the data leaves' traces_to. -->

| Dataset | Used for | Referenced in |
|---|---|---|
| <name> | <training stage / benchmark / ablation> | [training](training.md) §<n> |
