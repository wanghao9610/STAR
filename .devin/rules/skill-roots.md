---
trigger: always_on
---

# Skill Roots for Devin

Guidelines for loading STAR skills from the several roots Devin scans without mixing incompatible instructions.

## 1. Follow the Tool-Neutral Copy

**When duplicate skills exist, Devin must use the copy under `.agents/skills/`.**

- Devin has no adapted skill tree in this repo: `.agents/skills/` is the copy its own skill loader reads natively, and the wording there names no tool — "your plan tool", "a read-only sub-agent" / "a writing sub-agent", "your question tool" — which maps to Devin's plan mode, `subagent_explore` / `subagent_general` and `run_subagent` profiles, and `ask_user_question`.
- Ignore sibling copies under `.claude/skills/`, `.codex/skills/`, `.cursor/skills/` and any other imported root: they are written for those hosts' tool names and are not for Devin to act on. `.devin/config.json` turns off the documented import keys; whatever a loader still surfaces is cosmetic only.
- `.devin/skills/` holds exactly two wrappers, `star` and `star-auto`, which delegate to the shared roster under `.agents/commands/`. Every `star-*` skill is loaded from `.agents/skills/` like any other.

## 2. Named Delegates

**STAR's three dispatch profiles live in `.devin/agents/`**: `star-plan`, `star-exec` and `star-read`. A `run_subagent` call for tier work names one of them; a read-only collection or blind read uses the built-in `subagent_explore` profile instead.
