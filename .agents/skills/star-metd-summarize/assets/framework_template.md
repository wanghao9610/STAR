---
type: framework
language: en
generated: <YYYY-MM-DD>
model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
sources:
  - plan: <prefix>_<slug>_plan.md
    updated: <YYYY-MM-DD>
---

<!-- Compiled by star-metd-summarize from metds/plans/. Hand edits are overwritten on the next
     run — to change this document, change the plan it came from. -->

# Framework

## 1. Architecture Overview

<!-- Root §3 technical route, as one data path: input → components in order → output. A reader
     should be able to trace a single sample through the whole method from this section alone.
     Keep any sketch small and textual; per-component depth is §2. -->

## 2. Components

<!-- One subsection per component, in the data-flow order of §1, from the modeling leaves' §1/§3
     and the ${CODE_NAME}/ paths their §2/§4 name. Include a formulation only where a plan states
     one — an equation invented to look rigorous is a fabrication. -->

### 2.1 <Component>

**Role.** <what it is for, one line>
**Input → Output.** <shapes / modalities>
**How it works.** <the mechanism as the plans describe it>
**Key formulation.** <equation or pseudocode — only if a plan states one; otherwise omit this line>
**Code.** `${CODE_NAME}/<path>`

## 3. Design Decisions

<!-- The choices that could have gone another way, with the reason the plans give. This is what a
     reviewer asks about first. A decision whose reason no plan records is a gap worth a TODO —
     say so rather than reconstructing a plausible rationale. -->

| # | Decision | Alternative considered | Why this one |
|---|---|---|---|
| D1 | <…> | <…> | <…> |

## 4. Difference from Prior Work

<!-- Root §2 positioning + §3 novelty type, for a reader who already knows the baselines. Be
     specific about what changes: "we add a module" is not a difference; what the module makes
     possible that the baseline cannot do is. -->

## 5. Module Map

<!-- Component ↔ code ↔ the plan that owns it, so the document stays navigable back to both.
     A component with no code path is design that is not built yet — leave the cell empty and
     let the section's not-yet-verified mark carry the fact. -->

| Component | Code (`${CODE_NAME}/…`) | Owning plan |
|---|---|---|
| <name> | `<path>` | `<prefix>_<slug>_plan.md` |
