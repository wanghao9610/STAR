---
name: star-auto
description: Drive the STAR workflow toward the goal an explicitly invoked /star-auto request states, starting each next skill itself under that invocation's grant. Do not use unless the user typed /star-auto.
disableModelInvocation: true
---

# Drive the workflow toward a goal

Read `.agents/commands/star-auto.md` from the current project root and follow it as the authoritative procedure.
When `.env` sets `STAR_LANG=zh`, or it is unset and the conversation is in Chinese, use `.agents/commands/star-auto.zh-CN.md` for the user-facing wording while keeping the English file's decisions.

Adapt its invocation spelling and model routing for Kimi Code:

- `/star-auto` (shorthand for `/skill:star-auto`) `<goal> [stop=<stop line>] [involve=<level>]` is this command.
- `/skill:star-<name> <argument>` is the spelling where the shared file writes `/star-<name> <argument>`.

For every run this command starts, resolve its tier and any mode exception under conventions §10.8, then resolve the `kimi` entry of that tier key or its untagged fallback. When the resolved value is non-empty and the current `Agent` or `AgentSwarm` schema exposes `model`, dispatch the whole selected skill on that alias only if the configured secondary-model pool accepts it; apply this to unmarked and `†` skills alike. The brief is self-contained: the Kimi-owned skill path to read in full, the original invocation, resolved `tier=<name>` and `involve=<level>`, `auto=unattended` when present, and the language resolved from `STAR_LANG` or the dialogue. It inherits every confirmation, STOP-line, sandbox, and approval boundary from the shared procedure; model routing authorizes nothing more. Do not pass the parent model-resolver command; the delegate records its own actual session model.

With an empty value, no selectable pool, no `model` field, a forced pool choice, an unavailable alias, or a rejected dispatch that has not started work, retain the original route: start an unmarked skill with the Skill tool and follow the Kimi-owned copy from the current project's available skills; for a skill marked †, dispatch the subagent the shared file requires. When a non-empty key cannot route, state one reason and do not edit the user's Kimi configuration.

If `.agents/commands/star-auto.md` is missing, report that the project does not contain the STAR auto procedure instead of guessing from the plugin package.
