---
name: star-auto
description: Drive the STAR workflow toward the goal an explicitly invoked /star-auto request states, starting each next skill itself under that invocation's grant. Do not use unless the user typed /star-auto.
argument-hint: "<goal> [stop=<stop line>] [involve=<level>]"
triggers:
  - user
---

# Drive the workflow toward a goal

Read `.agents/commands/star-auto.md` from the current project root and follow it as the authoritative procedure.
Write the user-facing wording in the language resolved under conventions §7.6: Chinese when `.env` sets `STAR_LANG=zh`, or when it is unset and the conversation is in Chinese. `.agents/commands/star-auto.md` is the only procedure; its decisions do not change with the language.

Devin spells the shared file's invocations as written: `/star-auto <goal> [stop=<stop line>] [involve=<level>]` is this command, and `/star-<name> <argument>` starts a project skill from `.agents/skills/`.

For every run this command starts, resolve its tier and any mode exception under conventions §10.8, then resolve the `devin` entry of that tier key or its untagged fallback, splitting off a final `@<depth>`. `run_subagent` takes a `profile`, not a model, so a non-empty resolved value selects the named delegate `star-plan`, `star-exec` or `star-read` in `.devin/agents/`, whose `model:` `bash execs/configure.sh` stamped from the same key (conventions §13, Devin). The stamp is the routing mechanism: pass the profile and do not try to name a model in the brief. A configured `@<depth>` has no per-dispatch control — state once that it is ignored. With an empty value, keep the shared procedure's delegate selection. Apply this to unmarked and `†` skills alike.

A dispatched run's brief is self-contained: tell it to read the selected skill's `.agents/skills/<name>/SKILL.md` in full; include the original invocation, its resolved `tier=<name>` and `involve=<level>` tokens, `auto=unattended` when this invocation carries it, and the language resolved from `STAR_LANG` or the dialogue. A read-only dispatch — a bounded collection or a blind read — keeps the `subagent_explore` profile, whose tool set is what keeps it read-only, since the named agents carry no tool restriction. The delegate gets no session hook context: say in the brief that it records `model_id` as `unrecorded`. These routing rules inherit every confirmation, STOP-line, sandbox, and approval boundary of the shared procedure; they authorize no additional action.

If `.agents/commands/star-auto.md` is missing, report that the project does not contain the STAR auto procedure instead of guessing from this wrapper.
