---
name: star
description: Route an explicitly invoked $star request to exactly one STAR research workflow skill. With no request, show the current research status. Do not use after a specific star-* skill has already been selected.
---

# Route a STAR request

Read `.agents/commands/star.md` from the current project root and follow it as the authoritative routing roster.
When `.env` sets `STAR_LANG=zh`, or it is unset and the conversation is in Chinese, use `.agents/commands/star.zh-CN.md` for the user-facing wording while preserving the English roster's skill names and routing decisions.

Adapt only its invocation spelling for Codex:

- `$star` is this generic router.
- `$star-<name> <argument>` invokes the selected project skill where the roster writes `/star-<name> <argument>`.

Do not reproduce a selected skill's workflow from this router.
For an unmarked skill, load and follow that `star-*` skill from the current project's available skills.
For a skill marked `†`, request the confirmation required by the roster, show the exact `$star-<name> <argument>` invocation, and wait.

If `.agents/commands/star.md` is missing, report that the project does not contain the STAR routing roster instead of guessing from the plugin package.
