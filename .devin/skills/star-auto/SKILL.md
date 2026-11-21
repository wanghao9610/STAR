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

For every run this command starts, resolve its tier and any mode exception under conventions §10.8, then resolve the `devin` entry of that tier key or its untagged fallback, splitting off a final `@<depth>`. `run_subagent` takes a `profile`, not a model, so a non-empty resolved value selects a named delegate in `.devin/agents/`, whose `model:` `bash execs/configure.sh` stamps from the same key (conventions §13, Devin). The stamp is the routing mechanism: pass the profile and do not try to name a model in the brief. A configured `@<depth>` reaches the profile the same way: `configure.sh` appends it to the stamped model as `-<depth>`, the form Devin's per-depth model ids take (`claude-opus-5-5-high`). Follow `.devin/rules/skill-roots.md`, section 2, for the profile, its model check and fallback: resolve the expected id including the depth suffix, check that the profile exists and its frontmatter `model` matches it, and when it cannot be confirmed take the unpinned/local route and disclose the fallback in the decisions record — never guess an id and never write configuration during a skill. With an empty value, keep the shared procedure's delegate selection — `subagent_general`, or the local read route for codebase reads; a fallback is not a way to bypass a policy rejection. Apply this to unmarked and `†` skills alike.

A dispatched run's brief is self-contained: tell it to read the selected skill's `.agents/skills/<name>/SKILL.md` in full; include the original invocation, its resolved `tier=<name>` and `involve=<level>` tokens, `auto=unattended` when this invocation carries it, and the language resolved from `STAR_LANG` or the dialogue. A complete READ-tier skill — `star-refs-reviewer`'s own run — may produce the report its manifest authorizes, and dispatches on `star-read` when READ is configured. A bounded read-only codebase collection is not that: it goes to `star-read-local` only when READ is configured and the profile's stamp matches the resolved id, and a blind review to `star-plan-blind` under the same PLAN condition — otherwise the fallback `.devin/rules/skill-roots.md`, section 2 names; both are restricted to `read`, `grep` and `glob`. A bounded paper reader or citation expander that must fetch a record goes to `star-read` when READ is configured, otherwise the built-in `subagent_general`; the brief authorizes writing only the one fetched record per item under its cache prefix. The delegate gets no session hook context: say in the brief that it records `model_id` as `unrecorded` unless the runtime supplies an actual id. Pass only relevant project-memory file pointers, and record a requested depth as requested, never as applied without runtime evidence. These routing rules inherit every confirmation, STOP-line, sandbox, and approval boundary of the shared procedure; they authorize no additional action.

If `.agents/commands/star-auto.md` is missing, report that the project does not contain the STAR auto procedure instead of guessing from this wrapper.
