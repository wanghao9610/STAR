---
name: star
description: Route an explicitly invoked /star request to exactly one STAR research workflow skill. With no request, show the current research status. Do not use after a specific star-* skill has already been selected.
disableModelInvocation: true
---

# Route a STAR request

Read `.agents/commands/star.md` from the current project root and follow it as the authoritative routing roster.

Adapt only its invocation spelling for Kimi Code:

- `/star` (shorthand for `/skill:star`) is this generic router.
- `/skill:star-<name> <argument>` invokes the selected project skill where the roster writes `/star-<name> <argument>`.

Do not reproduce a selected skill's workflow from this router. For an unmarked skill, start it with the Skill tool and follow the Kimi-owned copy from the current project's available skills. For a skill marked `†`, request the confirmation required by the roster, show the exact `/skill:star-<name> <argument>` invocation, and wait.

If `.agents/commands/star.md` is missing, report that the project does not contain the STAR routing roster instead of guessing from the plugin package.
