# STAR skill roots (Pi)

Pi can discover project skills from two roots here: `.pi/skills/` and `.agents/skills/`. Both carry the same fifteen `star-*` skills. `.pi/settings.json` excludes the second (`"skills": ["!**/.agents/skills/**"]`), so in a normal checkout only `.pi/skills/` is loaded and there is nothing to choose between.

**If that exclusion is ever removed, follow the `.pi/skills/` copy.** `.pi/skills/` is loaded first and wins the name collision, so it is already the copy Pi hands you — but the loser is reported at startup, and the path in that report is where Pi found a copy, not the copy to act on.

The two trees are not interchangeable. `.agents/skills/` is worded for OpenAI Codex: it invokes skills as `$star-<name>`, delegates with `spawn_agent`, gates plans with `update_plan`, and asks through `request_user_input` — none of which exists here. The `.pi/skills/` copies are invoked as `/star-<name>`, name Pi's own built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`), and reach the four tools below.

Skills are invoked as `/star-<name>`, from the prompt templates in `.pi/prompts/`. `.pi/settings.json` sets `enableSkillCommands: false`, so there is no `/skill:star-<name>` beside it — one command per skill, not two. That makes `.pi/prompts/` load-bearing for the seven slash-only skills: they are hidden from this prompt by `disable-model-invocation`, so deleting those templates would leave no way to reach them.

## What `.pi/extensions/` adds

Pi's core ships no sub-agents, no plan mode and no structured question tool. This repository ships all three, vendored from pi's own `examples/extensions` (MIT):

- **`star_subagent`** — delegation. Its roster is `.pi/agents/`: `star-collector` (read-only, returns the form it was given), `star-implementer` (one step, under a written brief), `star-auditor` (blind second read, scores nothing else). Scope defaults to `project`, which is that roster.
- **`star_questionnaire`** — one question per call, 2–4 options with the recommendation marked (conventions §7.3). In a headless run it returns `UI not available`: there is nobody to answer, so that is where the run stops (§7.2), not a signal to ask in plain text and carry on.
- **`/star-plan`** — read-only exploration. This is the **user's** switch, not a tool you can call. A skill that must write nothing before approval holds that gate itself.
- A confirm before `rm -rf`, `sudo` and `chmod 777`. In a headless run there is no one to confirm, so such a command is refused outright.

Every name above is prefixed because pi refuses to start when two extensions claim one tool or flag name, and these examples are commonly installed user-level too.

**All four load only after the project is trusted** (`pi --approve`, or `/trust` once). Untrusted, none of them exists — and a skill that names one then falls back to what STAR does on a host without it: conventions §6.1 has the main agent fill a dispatch locally, against the same return format and in the same order, and a question becomes plain text, still one at a time.

A project that runs only Pi can delete `.agents/`, which removes the skill-root question at the source.
