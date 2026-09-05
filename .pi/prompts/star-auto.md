---
description: Drive the STAR workflow toward a stated goal, starting each next skill itself
argument-hint: "[goal] [stop=<stop line>] [involve=low]"
---

Read `.agents/commands/star-auto.md` and follow it with this invocation: [$@]

For every run this command starts, resolve its tier and any mode exception under conventions §10.8, then resolve the `pi` entry of that tier key or its untagged fallback using Pi's `provider/model` spelling. With a non-empty value and an installed `star-runner` whose dispatch schema accepts `model`, delegate the whole selected skill to `star-runner` and pass the value as `model`; it is not a `star-implementer` action dispatch. The brief is self-contained: the Pi-owned skill path to read in full, the original invocation, resolved `tier=<name>` and `involve=<level>`, `auto=unattended` when present, and the language resolved from `STAR_LANG` or the dialogue. It inherits every confirmation, STOP-line, sandbox, and approval boundary from the shared procedure; model routing authorizes nothing more. Do not pass the parent model-resolver command; the delegate records its own actual session model.

With an empty value, no `star-runner`, no supported `model` field, an unavailable model, or a rejected dispatch that has not started work, retain the original route: for an unmarked skill, read the Pi-owned copy under `.pi/skills/` in full and follow it; for a skill marked †, dispatch the subagent the shared file requires. When a non-empty key cannot route, state one reason and do not change the extension or model configuration from this run.
