---
name: star-plan-decomposer
description: >-
  Decompose a finalized research plan into dependency-aware, executable sub-plans with concrete tasks,
  deliverables, and done criteria, expanding only the next runnable units by default. Use when a plan
  needs smaller work units or its next outlined unit expanded.
triggers:
  - user
---

Read `.agents/skills/star-plan-decomposer/SKILL.md` from the project root in full and follow it as this skill; its `references/`, `scripts/` and `assets/` paths are relative to `.agents/skills/star-plan-decomposer/`.

This copy exists so that Devin starts `star-plan-decomposer` only when the user types `/star-plan-decomposer`: the skill is marked † in the conventions §10 roster, and the shared manifest it shadows carries no field that keeps Devin from starting it on its own. Pass the invocation through unchanged.
