# STAR skill roots (Pi)

Pi can discover project skills from two roots here: `.pi/skills/` and `.agents/skills/`. Both carry the same fifteen `star-*` skills. `.pi/settings.json` excludes the second (`"skills": ["!**/.agents/skills/**"]`), so in a normal checkout only `.pi/skills/` is loaded and there is nothing to choose between.

**If that exclusion is ever removed, follow the `.pi/skills/` copy.** `.pi/skills/` is loaded first and wins the name collision, so it is already the copy Pi hands you — but the loser is reported at startup, and the path in that report is where Pi found a copy, not the copy to act on.

The two trees are not interchangeable. `.agents/skills/` is worded for OpenAI Codex: it invokes skills as `$star-<name>`, delegates with `spawn_agent`, gates plans with `update_plan`, and asks through `request_user_input` — none of which exists here. The `.pi/skills/` copies are invoked as `/star-<name>`, name Pi's own built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`), ask in plain text, and do their own work in this context, since Pi ships no sub-agents and no plan mode.

Skills are invoked as `/star-<name>`, from the prompt templates in `.pi/prompts/`. `.pi/settings.json` sets `enableSkillCommands: false`, so there is no `/skill:star-<name>` beside it — one command per skill, not two. That makes `.pi/prompts/` load-bearing for the seven slash-only skills: they are hidden from this prompt by `disable-model-invocation`, so deleting those templates would leave no way to reach them.

A project that runs only Pi can delete `.agents/`, which removes the question at the source.
