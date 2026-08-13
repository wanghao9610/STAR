# STAR skill roots (Pi)

Pi discovers project skills from two roots here: `.pi/skills/` and `.agents/skills/`. Both carry the same fifteen `star-*` skills, and on a name collision Pi keeps the first copy it finds and warns — which may be either one.

**Follow the `.pi/skills/` copy.** When a `star-*` skill is surfaced from `.agents/skills/`, open `.pi/skills/<name>/SKILL.md` and act on that instead. The path in the skill listing is where Pi found a copy, not the copy to act on.

The two trees are not interchangeable. `.agents/skills/` is worded for OpenAI Codex: it invokes skills as `$star-<name>`, delegates with `spawn_agent`, gates plans with `update_plan`, and asks through `request_user_input` — none of which exists here. The `.pi/skills/` copies are invoked as `/skill:star-<name>`, name Pi's own built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`), ask in plain text, and do their own work in this context, since Pi ships no sub-agents and no plan mode.

A project that runs only Pi can delete `.agents/`, which removes the collision at the source.
