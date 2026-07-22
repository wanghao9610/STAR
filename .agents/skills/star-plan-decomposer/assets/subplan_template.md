---
title: <Sub-topic> Execution Plan
slug: <slug>
language: en
prefix: "<prefix>"           # e.g. "00" — parent prefix + this unit's 0-based index
parent: <parent-filename>    # e.g. 0_open-vocab-det-seg_plan.md (authoritative link)
level: <n>                   # = length of prefix (root = 1)
traces_to: "<root section/claim this executes, e.g. §6 milestone 1 (MVP); §4 claim 1>"
depends_on: []               # sibling prefixes that must finish first, e.g. ["00", "01"]; [] = independent
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none>
status:
  objective: in_progress
  deps: pending
  steps: pending
  deliverables: pending
  verification: pending
  risks: pending
---

# <Sub-topic> Execution Plan

## 1. Objective & Scope

<!-- What this sub-plan delivers, in one or two sentences, traced to the root claim/section
     it serves. State explicit non-goals: what is deliberately left to sibling sub-plans or
     later depth. This sub-plan should own exactly one coherent chunk of the parent's execution. -->

## 2. Inputs & Dependencies

<!-- Concrete prerequisites, each pointing at a project location:
     - Data: which datasets/splits, under datas/
     - Weights: which pretrained/base models, under inits/
     - Code: which modules/entrypoints, under code/
     - Upstream sub-plans that must finish first (by prefix), and what artifact they hand over.
       Mirror those prefixes in the frontmatter `depends_on` list (the machine-readable order). -->

## 3. Task Breakdown

<!-- Ordered, verb-concrete steps a researcher can execute and check off. No "explore/combine/
     look into"-style verbs whose completion can't be verified. Each step should be small enough
     that its completion is unambiguous. Number them. -->

## 4. Deliverables & Outputs

<!-- The concrete artifacts this sub-plan produces and exactly where they live:
     generated outputs under wkdrs/<run-name>/… with a run name that distinguishes this task/
     experiment; datasets under datas/; weights under inits/; any script this plan must write itself
     under tasks/<plan-name>/ (never execs/ — its root is closed). Name the files/dirs, not just
     "results". -->

## 5. Verification / Done-Criteria

<!-- The single check that proves this sub-plan is done: a test that passes, a metric that clears
     a threshold, a specific output that exists and looks right. Tie thresholds back to the root's
     §4 metrics / §5 kill-criteria where relevant. If it can't be checked, it isn't a done-criterion. -->

## 6. Local Risks & Fallback

<!-- Risks specific to executing THIS sub-task (not the research-level risks — those live in the
     root §5). What could make this step fail or stall, an early signal to watch, and the local
     fallback. Note any tie to the root's kill-criteria. -->
