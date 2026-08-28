---
name: star-auto
description: Drive the STAR workflow toward the goal an explicitly invoked $star-auto request states, starting each next skill itself under that invocation's grant. Do not use unless the user typed $star-auto.
---

# Drive the workflow toward a goal

Read `.agents/commands/star-auto.md` from the current project root and follow it as the authoritative procedure.
When `.env` sets `STAR_LANG=zh`, or it is unset and the conversation is in Chinese, use `.agents/commands/star-auto.zh-CN.md` for the user-facing wording while keeping the English file's decisions.

Adapt only its invocation spelling for Codex:

- `$star-auto <goal> [stop=<stop line>] [involve=<level>]` is this command.
- `$star-<name> <argument>` is the spelling where the shared file writes `/star-<name> <argument>`.

For an unmarked skill, load and follow that `star-*` skill from the current project's available skills. For a skill marked † in the roster, dispatch a subagent that reads that skill's `SKILL.md` from the project's skill root in full and follows it, as the shared file says.

If `.agents/commands/star-auto.md` is missing, report that the project does not contain the STAR auto procedure instead of guessing from the plugin package.
