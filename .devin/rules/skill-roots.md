---
trigger: always_on
---

# Skill Roots for Devin

Guidelines for loading STAR skills from the several roots Devin scans without mixing incompatible instructions.

## 1. Follow the Tool-Neutral Copy

**When duplicate skills exist, Devin must use the copy under `.agents/skills/`.**

- Devin has no adapted skill tree in this repo: `.agents/skills/` is the copy its own skill loader reads natively, and the wording there names no tool — "your plan tool", "a read-only sub-agent" / "a writing sub-agent", "your question tool" — which maps to Devin's plan mode, `subagent_explore` / `subagent_general` and `run_subagent` profiles, and `ask_user_question`.
- Ignore sibling copies under `.claude/skills/`, `.codex/skills/` and any other imported root: they are written for those hosts' tool names and are not for Devin to act on. `.devin/config.json` turns off the documented import keys; whatever a loader still surfaces is cosmetic only.
- `.devin/skills/` holds two kinds of wrapper. `star` and `star-auto` delegate to the shared roster under `.agents/commands/`. The seven skills marked † in the conventions §10 roster each have a user-only wrapper of the same name, which shadows the shared manifest and reads it in full, so Devin starts them only when the user types them. Every other `star-*` skill is loaded from `.agents/skills/` directly.

## 2. Named Delegates

**STAR's dispatch profiles live in `.devin/agents/`.** A complete skill or implementation phase with a configured tier uses `star-plan`, `star-exec` or `star-read`. For bounded codebase-only collection use `star-read-local` on the configured READ model; for a blind review use `star-plan-blind` on the configured PLAN model. These two profiles restrict tools to `read`, `grep` and `glob`. When no model is configured or routing cannot be confirmed, use `subagent_explore` for those local read-only tasks; it uses Devin's default subagent model, not the configured tier. A bounded paper reader or citation expander that must fetch a record uses `star-read` when READ is configured, otherwise the built-in `subagent_general`; the brief authorizes writing only the one fetched record per item under its cache prefix.

Before a configured dispatch, resolve the expected Devin model id, including the depth suffix — a `-<depth>` the id already carries is not appended twice — and check that the chosen profile exists and its frontmatter `model` matches that id. If it is missing or stale, or the session has not reloaded changed profiles, tell the user to run `bash execs/configure.sh --harnesses devin` and open a new session; use the normal unpinned/local route, disclose the fallback in the decisions record, and do not set configuration during a skill. A disk match does not prove the runtime model: record `unrecorded` unless the runtime supplies an id.
