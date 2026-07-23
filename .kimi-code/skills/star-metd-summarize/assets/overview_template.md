---
type: overview
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

# <Method / Project Name> — Overview

## 1. Problem & Motivation

<!-- Root §1: the research question in one sentence, why it matters now, and the gap nobody
     fills. Written for a reader who has never seen the plans and never will. -->

## 2. Limitations of Existing Work

<!-- Root §2: the closest lines of work and the specific shortcoming each leaves open, ending
     with this method's positioning ("none of them can do X"). Name works, not citation keys —
     the bibliography lives in metds/refs/. -->

## 3. Core Idea

<!-- Root §3: the key insight in one paragraph a reader could repeat back, then the technical
     route in a few sentences. This is what a paper's introduction is built from — keep
     implementation detail in framework.md. -->

## 4. Method at a Glance

<!-- What the method is made of. One row per component, from the leaves' §1 objectives, in the
     order a sample flows through them. This table is the map to the other four documents. -->

| Component | Role in the method | Detailed in |
|---|---|---|
| <name> | <one line> | [framework](framework.md) §<n> |

## 5. Contributions & Claims

<!-- Root §3 novelty claims + §4 claim→experiment mapping. Each contribution stated as a
     falsifiable claim, with the document that carries its evidence design. A claim no
     experiment tests is a gap worth naming. -->

| # | Claim | Validated by |
|---|---|---|
| C1 | <…> | [evaluation](evaluation.md) §<n> |

## 6. Status & Milestones

<!-- Root §6 milestones plus each leaf's exec_status: what is done, what is in flight, what is
     next. A few lines only — the plan tree's live progress view belongs to the status skill,
     not to a compiled document. -->
