# Workflow Harness Adapters

**Language:** English | [简体中文](harness-adapters.zh-CN.md)

This file preserves STAR's per-harness invocation spelling and model-routing mechanics for [conventions](research-workflow-conventions.md) §10 (the skill roster and routing). The conventions own scope, authority, tier assignment, relocation conditions and provenance requirements; this file describes how each harness applies them. Read the current harness's entry before choosing an invocation or dispatch parameter, and use only capabilities the active interface supports.

## Invocation spelling and configuration tags

Fifteen skills, invoked as `/star-<name>` in Claude Code, Cursor, Pi and Qwen Code, `$star-<name>` in Codex, `/skill:star-<name>` in Kimi Code and DSH.

| Harness | Tag in `STAR_HARNESSES` and model entries |
| --- | --- |
| Claude Code | `claude` |
| Codex | `codex` |
| Cursor | `cursor` |
| DSH | `dsh` |
| Kimi Code | `kimi` |
| Pi | `pi` |
| Qwen Code | `qwen` |

Model names retain their harness spelling, for example `pi:anthropic/claude-fable-5`, `claude:fable`, and `claude:claude-opus-5[1m]`. Tag selection, untagged fallback and `@<depth>` parsing follow conventions §10.8 (model and depth routing). One alias comparison is `opus` for `claude-opus-5[1m]`: ignore the context-window suffix for comparison, while recording the runtime's model id verbatim in artifacts.

## Model and thinking depth

### Claude Code

Claude Code takes the depth from the `effort:` frontmatter that `bash execs/configure.sh` writes into each tier's manifests and into its named `star-plan`, `star-exec` and `star-read` agents: a run invoked through a manifest reasons at that manifest's tier depth, and a delegate dispatched as one of those agents reasons at that agent's, so naming the agent is how a depth is named per dispatch there — a configured Claude Code depth is a routing difference even when the tier model aliases the active model, and a delegate dispatched as a plain subagent type still inherits the dispatching run's depth.

### Codex

Codex needs no file stamp: whenever its current `spawn_agent` interface accepts the suffix for the selected model, every tier dispatch passes it explicitly as `reasoning_effort`; a configured Codex depth is therefore a routing difference even when the tier model aliases the active model, and a phase that changes tier can change both.

A direct invocation of `star-plan-coach` or `star-idea-storm` stays in the main thread and keeps its effort; `star-auto` can start them at the configured PLAN effort and relay questions back. This preserves the coaching exception in conventions §10.8 (run relocation conditions).

### Cursor

Cursor resolves only the flat ids its model catalog lists, one per depth — `cursor-grok-4.6-xhigh`, `claude-opus-5-high` — and rejects a parameterised `id[effort=<depth>]`, so a base id that exists only as depth-suffixed variants never resolves on its own. `bash execs/configure.sh` therefore appends a configured `@<depth>` to the model as `-<depth>` and writes that flat id, unquoted, onto that tier's named agent's `model:` — Cursor's loader treats quote characters as part of the name. Name the delegate `star-plan`, `star-exec` or `star-read` so the stamp can apply. `Task` also exposes a per-call `model` and no separate depth parameter; a passed `model` overrides the file. Pass the stamped id when this session's selectable `Task` `model` list contains it; otherwise scan that list for a slug of the same model family that already carries the wanted depth — a speed-tier variant such as `cursor-grok-4.6-xhigh-fast` counts — and pass it when listed. Do not invent a slug, do not pass an `@<depth>` suffix or a bracketed parameter, and do not pass a family match at the wrong depth. If nothing listed matches, omit `model` so the file stamp is not overridden, and say once that the per-call slug was unavailable. A listed stamped id or preset is a routing difference even when the tier model aliases the active model; an unlisted depth is not claimed applied.

### Qwen Code

Qwen's named agents take the model without the suffix.

### Kimi Code

`--kimi-pool` requires the project Python configured in `.env` with `tomllib` (Python 3.11+). It parses and validates the complete edit before writing; unsupported table layouts leave the config unchanged.

Kimi Code likewise has no per-dispatch depth parameter: its `Agent` / `AgentSwarm` `model` accepts only aliases from the configured secondary-model pool, so a configured `@<depth>` is dispatched as the pool alias binding that model at that depth — conventionally `<model>-<depth>`, a `[models]` variant carrying that `default_effort` which the user registers in `~/.kimi-code/config.toml` and lists in the pool, by hand or with `bash execs/configure.sh --kimi-pool`, and which no skill run ever writes — so a configured Kimi depth is a routing difference even when the tier model aliases the active model; where no pool entry binds the depth, the dispatch passes the model alone and says once that the depth went unapplied, and a section-wide `[secondary_model].default_effort` overrides every variant binding.

### DSH and Pi

Read their skill manifests and the active delegation interface, applying only the model and depth controls actually exposed; this reference supplies no additional depth parameter for them.

## Model provenance and post-write checks

Runtime events, hook paths, model-id recovery commands and post-write check commands live in [model_id_spec.md](model_id_spec.md) (per-runtime provenance). That file already preserves the system-prompt source, session-record resolution and fallback order, and the concrete post-write call; conventions §8 (artifacts and provenance) retains the requirements shared by every producer.
