---
description: Drive the STAR workflow toward a stated goal, starting each next skill itself
argument-hint: "[goal] [stop=<stop line>] [involve=low]"
disable-model-invocation: true
---

Read `.agents/commands/star-auto.md` and follow it with this invocation: [$ARGUMENTS]

Starting a skill on Claude Code (conventions §10.8): `star-flow-status` and `star-expt-digest` start with the Skill tool, whose manifests already fork them on the READ tier. For every other skill, take its tier from the §10 roster — mode exceptions in §10.8 — and the matching `STAR_<TIER>_MODEL` value from the `.env` lookup this run already did. Where that value is non-empty and is not an alias of the model this session is running, dispatch one subagent (`subagent_type: general-purpose`, `model:` that value) that reads `.claude/skills/<name>/SKILL.md` in full and follows it, the brief carrying the original argument plus `involve=<level> tier=<tier>`, and `auto=unattended` where the shared file says so; started on its tier already, that run does not relocate itself again. Otherwise start an unmarked skill with the Skill tool, so its model, effort, and fork settings apply, and a † skill by the same subagent dispatch with no `model` parameter, exactly as before. The model this session is running is what the `--resolve` command in the session's STAR provenance line prints, run once before the loop; where the line carries no command, the id it states; where it names none, every start goes out as if the keys were empty. An alias is the family name inside that id (`opus` for `claude-opus-5[1m]`) or the id itself, a context-window suffix aside. Every start logs its tier and the model it got, beside what the shared file already has it record.
