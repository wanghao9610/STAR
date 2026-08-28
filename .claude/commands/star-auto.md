---
description: Drive the STAR workflow toward a stated goal, starting each next skill itself
argument-hint: "[goal] [stop=<stop line>] [involve=<level>]"
disable-model-invocation: true
---

Read `.agents/commands/star-auto.md` and follow it with this invocation: [$ARGUMENTS]

For an unmarked skill, start the Claude-owned copy with the Skill tool so its model, effort, and fork settings apply. For a skill marked † in the roster, dispatch a subagent that reads the Claude-owned copy under `.claude/skills/` in full and follows it, as the shared file says.
