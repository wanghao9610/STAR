---
name: star-auto
disable-model-invocation: true
description: Drive the STAR workflow toward the goal an explicitly invoked /star-auto request states, starting each next skill itself under that invocation's grant. Do not use unless the user typed /star-auto.
---

# Drive the workflow toward a goal

Read `.agents/commands/star-auto.md` from the current project root and follow it as the authoritative procedure.
Write the user-facing wording in the language resolved under conventions §7.6: Chinese when `.env` sets `STAR_LANG=zh`, or when it is unset and the conversation is in Chinese. `.agents/commands/star-auto.md` is the only procedure; its decisions do not change with the language.

Antigravity spells the shared file's invocations as written: `/star-auto <goal> [stop=<stop line>] [involve=<level>]` is this command, and `/star-<name> <argument>` starts a project skill from `.agents/skills/`.

For every run this command starts, resolve its tier and any mode exception under conventions §10.8, then resolve the `agy` entry of that tier key or its untagged fallback, splitting off a final `@<depth>`. `invoke_subagent` takes `Model` only as `inherit`, `flash_lite`, `flash` or `pro` and exposes no per-dispatch depth (conventions §13, Antigravity). `inherit` means keep the active session's model (no routing difference). When the resolved model is `flash_lite`, `flash` or `pro` and differs from the active session's model, start the run with `invoke_subagent`, passing that `Model`; apply this to unmarked and `†` skills alike. For any other model name, or an `@<depth>` suffix, keep `inherit` and state once that the interface cannot select that model or depth. With an empty value, `inherit`, or no routing difference, retain the shared procedure: load and follow an unmarked `star-*` skill here, or dispatch the `†` skill's subagent as the shared file requires.

A dispatched run's brief is self-contained: tell it to read the selected skill's `.agents/skills/<name>/SKILL.md` in full; include the original invocation, its resolved `tier=<name>` and `involve=<level>` tokens, `auto=unattended` when this invocation carries it, and the language resolved from `STAR_LANG` or the dialogue. Keep a codebase-only read-only start on `TypeName: "research"`, and use `TypeName: "self"` for a writing run or a read-only run that must fetch arbitrary URLs or write run caches (such as `star-refs-reviewer`, because `research` runs in a read-only sandbox with no network access), preserving the brief's scope limits. Do not pass the parent session's model-resolver command; the delegate records its own actual session model. These routing rules inherit every confirmation, STOP-line, sandbox, and approval boundary of the shared procedure; they authorize no additional action.

For "Waiting on a launched command", use Antigravity's native background execution instead of shell `&` backgrounding and `sleep` polling: run the prepared `launch_state.sh` wrapper command directly in `run_command` with `WaitMsBeforeAsync: 500` (keeping `bash execs/scpts/<run>.sh` visible to `star_commit_guard.sh`), then end the turn so Antigravity's completion notification wakes the run when the command exits.

If `.agents/commands/star-auto.md` is missing, report that the project does not contain the STAR auto procedure instead of guessing from this wrapper.
