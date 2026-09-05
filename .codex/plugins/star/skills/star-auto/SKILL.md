---
name: star-auto
description: Drive the STAR workflow toward the goal an explicitly invoked $star-auto request states, starting each next skill itself under that invocation's grant. Do not use unless the user typed $star-auto.
---

# Drive the workflow toward a goal

Read `.agents/commands/star-auto.md` from the current project root and follow it as the authoritative procedure.
When `.env` sets `STAR_LANG=zh`, or it is unset and the conversation is in Chinese, use `.agents/commands/star-auto.zh-CN.md` for the user-facing wording while keeping the English file's decisions.

Adapt its invocation spelling and model routing for Codex:

- `$star-auto <goal> [stop=<stop line>] [involve=<level>]` is this command.
- `$star-<name> <argument>` is the spelling where the shared file writes `/star-<name> <argument>`.

For every run that this command starts, resolve its tier and any mode exception under conventions §10.8. Read the corresponding `STAR_PLAN_MODEL`, `STAR_EXEC_MODEL`, or `STAR_READ_MODEL` value once with the opening `.env` load. In a comma-separated value, take `codex:<model>` first, otherwise an untagged model; ignore entries tagged for another harness. An empty result names no model.

When the resolved model is non-empty, is not an alias of the active session's actual model, and this Codex runtime can name a subagent model, start the run with `spawn_agent` and pass that model explicitly. Pass `fork_turns: "none"` whenever the runtime exposes that field, including for blind reads: this runtime does not allow a model override with a full fork. Use the same rule for both unmarked and `†` skills. Otherwise retain the shared procedure: load and follow an unmarked project `star-*` skill here, or dispatch the `†` skill's subagent as the shared file requires, without setting a model.

Every model-routed subagent brief is self-contained: tell it to read the selected skill's project `SKILL.md` in full; include the original skill invocation, its resolved `tier=<name>` and `involve=<level>` tokens, `auto=unattended` when this invocation carries it, and the language resolved from `STAR_LANG` or the dialogue. Include the active session's actual provenance as a model id only. Never pass the parent session's model-resolver command or treat its output as the child's model provenance: the child resolves and records its own provenance from its own session context. These routing rules inherit the shared procedure's confirmation, STOP-line, sandbox, and approval limits; they authorize no additional action.

If `.agents/commands/star-auto.md` is missing, report that the project does not contain the STAR auto procedure instead of guessing from the plugin package.
