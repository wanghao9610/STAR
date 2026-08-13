# Model-id Fallbacks

**Language:** English | [简体中文](model_id_spec.zh-CN.md)

The per-runtime detail behind the `model_id` rule in [`research-workflow-conventions.md`](research-workflow-conventions.md) §8. Read it when the provenance line a hook injects is missing, or carries a recovery command in place of an id. The rule itself — record what the runtime reports for the writing session, verbatim, and never guess — stays in §8 and is not repeated here.

## How each runtime reports it

| Runtime | Hook | Event | What it injects | When the value is read |
|---|---|---|---|---|
| Claude Code | `.claude/hooks/star_model_id.sh` | `SessionStart` | a command reading the session transcript; the id itself when none was named | as you write it |
| Codex | `.codex/hooks/star_model_id.sh` | `SessionStart` | a command reading the session rollout; the id itself when none was named | as you write it |
| Cursor | `.cursor/hooks/star_model_id.sh` | `SessionStart` | the id | at session start |
| DSH | `.dsh/hooks/star_model_id.sh` | `SessionStart`, through the Claude Code hook bridge | a command reading the session log | as you write it |
| Kimi | `.kimi-code/hooks/star_model_id.sh` | `UserPromptSubmit` | `default_model` from `~/.kimi-code/config.toml` | from config, never the session |
| Pi | `.pi/hooks/star_model_id.sh` | `before_agent_start`, wired by `.pi/extensions/star-hooks.ts` | the id | at the prompt that will use it, and again after every model change |
| Qwen Code | `.qwen/hooks/star_model_id.sh` | `SessionStart` | a command reading the session transcript; the id itself when none was named | as you write it |

The last column is the difference that matters. A value read as you write it cannot be stale; Cursor's and Kimi's can, because a model switched mid-session changes nothing they read — that is the lag `research-workflow-conventions.md` §8 warns about, and those two rows are what is left of it. Pi is at the other end and needs no recovery command at all: its extension API hands every handler the live model object (`ctx.model`) and fires `model_select` whenever `/model` or `Ctrl+P` changes it, so the line is written from the model that is about to run and a fresh one arrives after every switch — the last one you were given is the one writing. Claude Code also names the model in its system prompt. DSH sits with the first group but gets there differently: its bridge's SessionStart payload carries no `model` at all, so the row injects a command unconditionally rather than falling back to an id — and the log it reads is Zstandard-framed by default, so the recovery needs the `zstd` command on PATH and prints nothing without it. A hook that exists is not necessarily registered — each runtime registers differently (`.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`, `.qwen/settings.json`, `.dsh/hooks.json` plus a row in `$DSH_HOME/cordis.patch.yml`, and `.kimi-code/hooks.example.toml` by hand), so a project can hold the script and still inject nothing. Pi's registration is code rather than config — the extension is discovered automatically, but only once the project is trusted (`/trust`, or `defaultProjectTrust`), and an untrusted project loads no project extension and injects nothing. Qwen Code adds one condition to that: a project-level hook runs only in a trusted folder, which applies only where folder trust has been turned on (`security.folderTrust.enabled`, off by default).

## Claude Code, Codex and Qwen Code, why the id is read at the moment it is written

The `model` field rides on `SessionStart` alone: Claude Code and Codex omit it after `/clear`, resume, compact, or fork, Qwen Code carries one for every start reason it reports (startup, resume, clear, compact), and where it is present it describes the moment the session opened — `/model` changes the model afterwards with no hook firing, so a session that starts on one model and writes with another would record the one it started on. All three runtimes keep a per-turn record of what actually ran, so whenever the payload names one the injected line carries a command instead of an id. Run it as you record the value:

```bash
bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
bash .codex/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
bash "$QWEN_PROJECT_DIR"/.qwen/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
```

with the arguments that line already fills in, and record what it prints verbatim. Claude Code's reader takes `message.model` off this session's own main-loop assistant turns, skipping a delegated subagent's — the question is which model is writing the artifact. Codex's takes `payload.model` off the rollout's `turn_context` records and skips nothing, because a Codex subagent is given a rollout of its own. Qwen Code's takes the top-level `model` off the transcript's `type: "assistant"` records and skips nothing either, because a Qwen subagent writes to a transcript of its own, named `agent_transcript_path` in the payload. In every case it is the runtime's record rather than a guess. `session_model` is what `SessionStart` reported: it stands in when the record names nothing yet, and it wins over an identical id to keep a suffix the record drops (`claude-opus-5[1m]` over `claude-opus-5`), but never over a different one — that difference is a mid-session switch, and the per-turn record is the one that saw it.

## Kimi, when no line was injected at all

Kimi's `SessionStart` cannot inject context and exposes no model id, so its hook runs on `UserPromptSubmit` and injects the configured `default_model` — which is stale if the model was overridden mid-session. Slash-command skill activation does not pass through that event, so a skill opened before any plain user message has seen nothing. Run one read yourself before writing `unrecorded`:

```bash
grep -E '^[[:space:]]*default_model[[:space:]]*=' "${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
```

and record the value verbatim — still self-reported, still possibly stale.

## When `unrecorded` is the right answer

Only when the session names no model anywhere: a runtime that states none, and every read above also empty. Never infer the id from behavior, never reason about which model this is "probably", and never copy one artifact's value into another.
