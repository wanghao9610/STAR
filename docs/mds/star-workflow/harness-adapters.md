# Workflow Harness Adapters

**Language:** English | [简体中文](harness-adapters.zh-CN.md)

This file preserves STAR's per-harness invocation spelling and model-routing mechanics for [conventions](research-workflow-conventions.md) §10 (the skill roster and routing). The conventions own scope, authority, tier assignment, where a run executes, and provenance requirements; this file describes how each harness applies them. Read the current harness's entry before choosing an invocation or dispatch parameter, and use only capabilities the active interface supports.

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

Claude Code takes the depth from the `effort:` frontmatter that `bash execs/configure.sh` writes into each tier's manifests and into its named `star-plan`, `star-exec` and `star-read` agents. A run invoked through a manifest reasons at that manifest's tier depth, and a delegate dispatched as one of those agents reasons at that agent's; naming the agent is therefore how a depth is named per dispatch there. A directly invoked run thus already has its roster tier's depth, but not the depth of a tier its mode switches to (conventions §10.8: `star-expt-analyst aggregate` and `watch`, `star-refs-reviewer synthesize`, `star-proj-adopt backfill`, `star-code-release check`), which Claude Code applies only per dispatch. `star-flow-status` and `star-expt-digest` also fork on the READ model stamped into their manifests. So the opening line of conventions §10.8 (where a run executes) names a tier model the session is not running and, for a mode that changes tier, that tier's depth; for those two it names nothing. For a phase hand-off or a `star-auto` start, a configured Claude Code depth is a routing difference even when the tier model aliases the active model, and a delegate dispatched as a plain subagent type still inherits the dispatching run's depth. A read-only dispatch — a collector or a blind read — is the exception: it keeps the generic `Explore` type, whose tool set is what keeps it read-only, because the named agents carry no tool restriction; it takes the tier's model but not its depth, and the run says so once.

A subagent cannot dispatch subagents: a run started as a subagent runs its phase hand-offs and its inner delegates' work locally, on its own model and depth.

### Codex

Codex needs no file stamp: whenever its current `spawn_agent` interface accepts the suffix for the selected model, every tier dispatch passes it explicitly as `reasoning_effort`; a configured Codex depth is therefore a routing difference even when the tier model aliases the active model, and a phase that changes tier can change both.

A direct invocation of any skill stays in the main thread on the session's model and effort. Codex applies a depth only per dispatch, so a configured Codex depth is one the run's opening line names (conventions §10.8, where a run executes); `star-auto` starts each run at its tier's model and effort, `star-plan-coach` and `star-idea-storm` included, and relays their questions back.

### Cursor

Cursor resolves only the flat ids its model catalog lists, one per depth — `cursor-grok-4.6-xhigh`, `claude-opus-5-high` — and rejects a parameterised `id[effort=<depth>]`, so a base id that exists only as depth-suffixed variants never resolves on its own. `bash execs/configure.sh` therefore appends a configured `@<depth>` to the model as `-<depth>` and writes that flat id, unquoted, onto that tier's named agent's `model:` — Cursor's loader treats quote characters as part of the name. Name the delegate `star-plan`, `star-exec` or `star-read` so the stamp can apply. `Task` also exposes a per-call `model` and no separate depth parameter; a passed `model` overrides the file. Pass the stamped id when this session's selectable `Task` `model` list contains it; otherwise scan that list for a slug of the same model family that already carries the wanted depth — a speed-tier variant such as `cursor-grok-4.6-xhigh-fast` counts — and pass it when listed. Do not invent a slug, do not pass an `@<depth>` suffix or a bracketed parameter, and do not pass a family match at the wrong depth. If nothing listed matches, omit `model` so the file stamp is not overridden, and say once that the per-call slug was unavailable. A listed stamped id or preset is a routing difference even when the tier model aliases the active model; an unlisted depth is not claimed applied.

### Qwen Code

Qwen's named agents take the model without the suffix.

### Kimi Code

`bash execs/configure.sh --kimi-pool`, which registers the depth variants described below, requires the project Python configured in `.env` with `tomllib` (Python 3.11+). It parses and validates the complete edit before writing; unsupported table layouts leave the config unchanged.

Kimi Code likewise has no per-dispatch depth parameter: its `Agent` / `AgentSwarm` `model` accepts only aliases from the configured secondary-model pool. A configured `@<depth>` is therefore dispatched as the pool alias binding that model at that depth — conventionally `<model>-<depth>`, a `[models]` variant carrying that `default_effort`. The user registers that variant in `~/.kimi-code/config.toml` and lists it in the pool, by hand or with `bash execs/configure.sh --kimi-pool`; no skill run ever writes it. A configured Kimi depth is thus a routing difference even when the tier model aliases the active model. Where no pool entry binds the depth, the dispatch passes the model alone and says once that the depth went unapplied. A section-wide `[secondary_model].default_effort` overrides every variant binding.

### DSH and Pi

Read their skill manifests and the active delegation interface, applying only the model and depth controls actually exposed; this reference supplies no additional depth parameter for them.

## Model provenance and post-write checks

Runtime events, hook paths, model-id recovery commands and post-write check commands live in [model_id_spec.md](model_id_spec.md) (per-runtime provenance). That file already preserves the system-prompt source, session-record resolution and fallback order, and the concrete post-write call; conventions §8 (artifacts and provenance) retains the requirements shared by every producer.
