#!/usr/bin/env bash
# STAR UserPromptSubmit hook (Kimi Code) — inject the session's model id into
# context once per session so skills record a real model_id instead of
# "unrecorded".
#
# Why UserPromptSubmit and not SessionStart: in Kimi, SessionStart is
# observation-only (fire-and-forget) and cannot inject context, and its payload
# carries no model id. UserPromptSubmit is the only context-injecting event —
# on exit 0 its stdout is appended to context. We fire once per session by
# keying a marker file on the payload's session_id, so it does not repeat every
# turn.
#
# Kimi does not expose the active model to hooks, so we read `default_model`
# from config.toml — the CONFIGURED default, which can differ from the active
# model if it was overridden with `kimi -m` or `/model`. Self-reported per
# research-workflow-conventions §8, so a mid-session switch can leave a stale
# value.
#
# Registration: Kimi does not auto-load project config, so this hook cannot be
# committed live the way the other harnesses' are. Add the [[hooks]] block from
# .kimi-code/hooks.example.toml to your global config at
# $KIMI_CODE_HOME/config.toml (default ~/.kimi-code/config.toml), with the
# absolute path to this script, to enable it.

input=$(cat)

# --- session_id, for once-per-session dedup ---
if command -v jq >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("session_id") or "")
except Exception:
    print("")' 2>/dev/null)
else
  sid=$(printf '%s' "$input" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
fi

marker="${TMPDIR:-/tmp}/star_kimi_model_id_${sid:-nosession}"
# Already injected for this session → stay silent (exit 0, no stdout).
[ -e "$marker" ] && exit 0
: > "$marker" 2>/dev/null || true

# --- configured default model from config.toml (global; Kimi has no per-project config) ---
model=""
cfg="${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
if [ -f "$cfg" ]; then
  model=$(grep -E '^[[:space:]]*default_model[[:space:]]*=' "$cfg" | head -1 \
            | sed -E 's/^[^=]*=[[:space:]]*"?([^"#]*)"?.*/\1/' | sed -E 's/[[:space:]]+$//')
fi

if [ -n "${model:-}" ]; then
  ctx="STAR provenance: this Kimi session has configured default model ${model} (from config.toml; the active model may differ if it was overridden with kimi -m or /model). When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), record the model actually answering — normally ${model} — verbatim; do not write 'unrecorded'."
else
  ctx="STAR provenance: no Kimi default model could be read from config.toml. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), record the model you are running if known, otherwise write 'unrecorded'; do not guess."
fi

printf '%s\n' "$ctx"
exit 0
