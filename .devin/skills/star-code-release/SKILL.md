---
name: star-code-release
description: >-
  Prepare a repository for open-source release by gathering evidence-backed code, polishing public
  files, compiling README.md from verified artifacts, and checking secrets, paths, licenses, and
  commands. Use for release readiness or README work; it never publishes, pushes, tags, or uploads.
triggers:
  - user
---

Read `.agents/skills/star-code-release/SKILL.md` from the project root in full and follow it as this skill; its `references/`, `scripts/` and `assets/` paths are relative to `.agents/skills/star-code-release/`.

This copy exists so that Devin starts `star-code-release` only when the user types `/star-code-release`: the skill is marked † in the conventions §10 roster, and the shared manifest it shadows carries no field that keeps Devin from starting it on its own. Pass the invocation through unchanged.
