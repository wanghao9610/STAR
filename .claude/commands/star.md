---
description: Route a request to the right STAR skill, or report the next action
argument-hint: "[what you want to do]"
disable-model-invocation: true
---

Read `.agents/commands/star.md` and apply its router to this request: [$ARGUMENTS]

For an unmarked skill, start the Claude-owned copy with the Skill tool so its model, effort, and fork settings apply. An empty request selects `star-flow-status` with no argument.
