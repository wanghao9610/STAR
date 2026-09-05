---
description: Drive the STAR workflow toward a stated goal, starting each next skill itself
---

Read `.agents/commands/star-auto.md` and follow it with this invocation: [{{args}}]

For every run this command starts, resolve its tier and any mode exception under conventions §10.8, then resolve the `qwen` entry of that tier key or its untagged fallback. With a non-empty value, first read `.qwen/agents/star-<tier>.md`, verify that its frontmatter `model` equals the resolved value, and verify that the named agent is loaded in this session; `bash execs/update.sh --models` synchronizes the files, but a new session loads them. When both checks pass, dispatch that named `agent` for the whole selected skill, whether unmarked or marked †. Do not place the raw model value in `agent`'s `model` parameter: it selects a configured grade, and `fork` cannot override a model. The brief is self-contained: the Qwen-owned skill path to read in full, the original invocation, resolved `tier=<name>` and `involve=<level>`, `auto=unattended` when present, and the language resolved from `STAR_LANG` or the dialogue. It inherits every confirmation, STOP-line, sandbox, and approval boundary from the shared procedure; model routing authorizes nothing more. Do not pass the parent model-resolver command; the delegate records its own actual session model.

With an empty value, or when the matching named agent is missing, stale, or not loaded, retain the original route: for an unmarked skill, read the Qwen-owned copy under `.qwen/skills/` in full and follow it; for a skill marked †, dispatch the subagent the shared file requires. When a non-empty key cannot route, state the required sync or reload and do not repair it from this run.
