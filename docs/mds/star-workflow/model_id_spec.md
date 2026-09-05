# Model-id Fallbacks

**Language:** English | [简体中文](model_id_spec.zh-CN.md)

The per-runtime detail behind the `model_id` rule in [`research-workflow-conventions.md`](research-workflow-conventions.md) §8. Read it when the provenance line a hook injects is missing, or carries a recovery command in place of an id. The rule itself — record what the runtime reports for the writing session, verbatim, and never guess — stays in §8, not repeated here.

## How each runtime reports it

| Runtime | Hook | Event | What it injects | When the value is read |
|---|---|---|---|---|
| Claude Code | `.claude/hooks/star_model_id.sh` | `SessionStart`, and `SubagentStart` for a delegate | a command reading the session transcript, or the delegate's own; the id itself when none was named | as you write it |
| Codex | `.codex/hooks/star_model_id.sh` | `SessionStart` | the exact `session_model_id`, a command reading the session rollout, and a post-write check | as you write it, then after the write |
| Cursor | `.cursor/hooks/star_model_id.sh` | `SessionStart` | the id | at session start |
| DSH | `.dsh/hooks/star_model_id.sh` | `SessionStart`, through the Claude Code hook bridge | a command reading the session log | as you write it |
| Kimi | `.kimi-code/hooks/star_model_id.sh` | `UserPromptSubmit` | `default_model` from `~/.kimi-code/config.toml` | from config, never the session |
| Pi | `.pi/extensions/star-hooks/star_model_id.sh` | `before_agent_start`, wired by `.pi/extensions/star-hooks/index.ts` | the id | at the prompt that will use it, and again after every model change |
| Qwen Code | `.qwen/hooks/star_model_id.sh` | `SessionStart` | a command reading the session transcript; the id itself when none was named | as you write it |

The last column is the difference that matters. A value read as you write it cannot be stale; Cursor's and Kimi's can, because a model switched mid-session changes nothing they read — the lag `research-workflow-conventions.md` §8 warns about, now down to those two rows. Pi is at the other end and needs no recovery command: its extension API hands every handler the live model object (`ctx.model`) and fires `model_select` whenever `/model` or `Ctrl+P` changes it, so the line is written from the model about to run and a fresh one arrives after every switch — the last one you were given is the one writing. Claude Code also names the model in its system prompt. DSH sits with the first group but gets there differently: its bridge's SessionStart payload carries no `model` at all, so the row injects a command unconditionally, never falling back to an id — and the log it reads is Zstandard-framed by default, so the recovery needs `zstd` on PATH and prints nothing without it. A hook that exists is not necessarily registered — each runtime registers differently (`.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`, `.qwen/settings.json`, `.dsh/hooks.json` plus a row in `$DSH_HOME/cordis.patch.yml`, and `.kimi-code/hooks.example.toml` by hand), so a project can hold the script and inject nothing. Pi's registration is code, not config — the extension is discovered automatically, but only in a trusted project (`/trust`, or `defaultProjectTrust`); untrusted, it loads no project extension and injects nothing. Qwen Code adds one condition: a project-level hook runs only in a trusted folder, which applies only where folder trust is on (`security.folderTrust.enabled`, off by default).

## Claude Code, Codex and Qwen Code, why the id is read at the moment it is written

The `model` field rides on `SessionStart` alone: Claude Code and Codex omit it after `/clear`, resume, compact, or fork, Qwen Code carries one for every start reason it reports (startup, resume, clear, compact), and where present it describes the moment the session opened — `/model` changes the model afterwards with no hook firing, so a session that starts on one model and writes with another records the one it started on. All three keep a per-turn record of what actually ran, so their injected lines carry a command that reads it. Codex also states the exact `SessionStart` value directly as `session_model_id`, even when a rollout exists; that preserves the precise id when a skill misses the dynamic read, without pretending the snapshot saw a later model switch. Run the resolver as you record the value:

```bash
bash .claude/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
bash .codex/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
bash "$QWEN_PROJECT_DIR"/.qwen/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
```

with the arguments that line already fills in, and record what it prints verbatim. Claude Code's reader takes `message.model` off this session's own main-loop assistant turns, skipping a sidechain's — the question is which model is writing the artifact, and a delegate writing one reads its own transcript instead, below. Codex's takes `payload.model` off the rollout's `turn_context` records and skips nothing: a Codex subagent gets its own rollout. Qwen Code's takes the top-level `model` off the transcript's `type: "assistant"` records and skips nothing either: a Qwen subagent writes its own transcript, named `agent_transcript_path` in the payload. In every case it is the runtime's record, not a guess. `session_model` is what `SessionStart` reported: it stands in when the record names nothing yet, and wins over an identical id to keep a suffix the record drops (`claude-opus-5[1m]` over `claude-opus-5`), but never over a different one — that difference is a mid-session switch, and the per-turn record saw it.

A delegate has a record of its own, and has to be told where it is. Claude Code writes a sub-agent's turns to `<the session transcript's directory>/<session_id>/subagents/agent-<agent_id>.jsonl`, and the session transcript carries none of them, so `--resolve` run against the session transcript from inside a delegate answers with the model that dispatched it. `SubagentStart` is what closes that: it fires for a sub-agent where `SessionStart` does not, and its payload carries the `session_id`, `transcript_path` and `agent_id` that path is built from — but no `model` field, which is why the injected line is a command here too. The reader drops the sidechain filter for a path under `subagents/`, since a delegate's own file marks none of its turns that way and the filter would skip all of them. No session model is passed alongside: the session's is not the delegate's.

Codex's same injected line supplies the post-write command:

```bash
bash .codex/hooks/star_model_id.sh --check <artifact> <rollout> <session_model>
```

Run it once per artifact after the last write and before reporting completion or committing. It compares the artifact's `model_id` with the rollout resolver's output, falling back first to the exact `SessionStart` value and then to `unrecorded`. A mismatch exits nonzero and blocks both completion and commit until corrected and re-checked. Neither the resolver nor this check derives an id from a descriptive label such as "GPT-5 family".

## Kimi, when no line was injected at all

Kimi's `SessionStart` cannot inject context and exposes no model id, so its hook runs on `UserPromptSubmit` and injects the configured `default_model` — stale if the model was overridden mid-session. Slash-command skill activation does not pass through that event, so a skill opened before any plain user message has seen nothing. Run one read yourself before writing `unrecorded`:

```bash
grep -E '^[[:space:]]*default_model[[:space:]]*=' "${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
```

and record the value verbatim — still self-reported, still possibly stale.

## When `unrecorded` is the right answer

Only when the session names no model anywhere: a runtime that states none, and every read above also empty. Never infer the id from behavior, never reason about which model this is "probably", and never copy one artifact's value into another.
