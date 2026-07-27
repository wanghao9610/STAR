#!/usr/bin/env bash
# STAR SessionStart hook (Codex CLI) — inject the runtime-reported model id into
# session context so skills record a real model_id instead of "unrecorded".
#
# Codex puts a `model` field (active model slug) on the SessionStart payload and
# accepts the same output shape as Claude Code: hookSpecificOutput.additionalContext.
# That field describes the moment the session opened; /model changes the model
# afterwards with no hook firing, so a session can write with one model while
# still holding the name of another.
#
# Codex also keeps a rollout file per session and stamps a `turn_context` record
# with the model of each turn. Where the payload names that file in
# `transcript_path`, the injected line hands the skill a command that reads it at
# the moment the value is recorded, which is the moment it is true. Where it does
# not, the session-start field is all there is, and is injected as before. When
# `model` is absent too, the honest value per research-workflow-conventions §8 is
# "unrecorded". Registered under [hooks.SessionStart] in .codex/hooks.json.

# --resolve <transcript_path> [session_model]: print the model of the last turn
# recorded in a rollout, or nothing at all. Run on demand by skills, per the line
# injected below. Prints nothing rather than failing, so "unrecorded" stays the
# fallback.
#
# session_model is what SessionStart reported. It stands in when the rollout
# names nothing yet, and is preferred over an identical id so that a suffix the
# rollout drops survives. It never wins over a different id — that difference is
# a mid-session switch, and the rollout is the one that saw it.
if [ "${1:-}" = "--resolve" ]; then
  transcript="${2:-}"
  session_model="${3:-}"
  resolved=""
  if [ -n "${transcript}" ] && [ -r "${transcript}" ]; then
    if command -v jq >/dev/null 2>&1; then
      resolved=$(jq -r 'select(.type == "turn_context") | .payload.model // empty' \
        "${transcript}" 2>/dev/null | tail -1)
    elif command -v python3 >/dev/null 2>&1; then
      resolved=$(python3 - "${transcript}" <<'PY' 2>/dev/null
import json, sys

last = ""
with open(sys.argv[1], errors="replace") as fh:
    for line in fh:
        try:
            entry = json.loads(line)
        except Exception:
            continue
        if entry.get("type") != "turn_context":
            continue
        model = (entry.get("payload") or {}).get("model")
        if model:
            last = model
print(last)
PY
      )
    fi
  fi

  if [ -z "${resolved}" ]; then
    [ -n "${session_model}" ] && printf '%s\n' "${session_model}"
    exit 0
  fi
  case "${session_model}" in
    "${resolved}"|"${resolved}["*) printf '%s\n' "${session_model}" ;;
    *) printf '%s\n' "${resolved}" ;;
  esac
  exit 0
fi

input=$(cat)

# Read one top-level string field from the payload.
payload_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get(sys.argv[1]) or "")
except Exception:
    print("")' "$1" 2>/dev/null
  else
    printf '%s' "$input" \
      | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
  fi
}

model=$(payload_field model)
transcript=$(payload_field transcript_path)
# Codex offers no project-directory variable, and registers this hook by the same
# relative path, which resolves from the project root a skill also runs in.
self=".codex/hooks/star_model_id.sh"

if [ -n "${transcript:-}" ]; then
  ctx="STAR provenance: read this session's model id when you record it, not from memory — the runtime states it at session start only, and /model changes it afterwards without saying so. Before a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), run: bash ${self} --resolve ${transcript}${model:+ ${model}} — then copy what it prints verbatim. Write 'unrecorded' only if it prints nothing, and do not guess."
elif [ -n "${model:-}" ]; then
  ctx="STAR provenance: this session's runtime-reported model id is ${model}, and the runtime named no rollout to check it against later. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'. If you switch models mid-session, this string is the one you started with, not the one writing."
else
  ctx="STAR provenance: the runtime stated no model id for this session. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), write 'unrecorded' and do not guess."
fi

# ctx now embeds a filesystem path, so encode it as JSON rather than assuming it
# is quote-free; the last branch sanitizes instead, having no encoder to hand.
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg c "${ctx}" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
elif command -v python3 >/dev/null 2>&1; then
  python3 -c 'import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))' "${ctx}"
else
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
    "$(printf '%s' "${ctx}" | tr -d '"\\')"
fi
