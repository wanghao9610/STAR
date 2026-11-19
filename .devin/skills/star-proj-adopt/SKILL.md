---
name: star-proj-adopt
description: >-
  Adopt an existing project into STAR by surveying it, mapping files and historical work, adding
  minimal workflow scaffolding, then backfilling confirmed progress into a later plan tree. Use for
  repositories that did not start from STAR; preserve existing data and code.
triggers:
  - user
---

Read `.agents/skills/star-proj-adopt/SKILL.md` from the project root in full and follow it as this skill; its `references/`, `scripts/` and `assets/` paths are relative to `.agents/skills/star-proj-adopt/`.

This copy exists so that Devin starts `star-proj-adopt` only when the user types `/star-proj-adopt`: the skill is marked † in the conventions §10 roster, and the shared manifest it shadows carries no field that keeps Devin from starting it on its own. Pass the invocation through unchanged.
