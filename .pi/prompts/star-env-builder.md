---
description: Build and verify the project's Python runtime from .env
argument-hint: "[ENV_NAME | add <package>…] [DESCRIPTION] [involve=low]"
---
Read `.pi/skills/star-env-builder/SKILL.md` in full and follow it as this run's instructions. This command is the skill's only entry point here: `.pi/settings.json` sets `enableSkillCommands: false`, so no `/skill:` command stands beside it. Everything that file says about its opening load, the conventions it reads, the involve level and its own steps applies unchanged.

This run's argument, between the brackets: [$@]

Empty brackets mean no argument was given: use the skill's own no-argument behaviour rather than asking which argument was meant.
