#!/usr/bin/env bash
# STAR SessionStart hook — inject the runtime-reported model id into session
# context so skills record a real model_id instead of "unrecorded".
#
# Claude Code puts a `model` field on the SessionStart payload (and nowhere else:
# no other hook event carries it, and there is no $CLAUDE_MODEL env var). It can
# be absent — after /clear, resume, or conversation recovery — and then the honest
# value per research-workflow-conventions §8 is "unrecorded".
#
# Registered under hooks.SessionStart in .claude/settings.json. Prints one JSON
# object whose additionalContext is added to context before the first prompt.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  model=$(printf '%s' "$input" | jq -r '.model // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  model=$(printf '%s' "$input" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("model") or "")
except Exception:
    print("")' 2>/dev/null)
else
  model=$(printf '%s' "$input" | grep -oE '"model"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
fi

if [ -n "${model:-}" ]; then
  ctx="STAR provenance: this session's runtime-reported model id is ${model}. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'."
else
  ctx="STAR provenance: the runtime stated no model id for this session (e.g. after /clear, resume, or conversation recovery). When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), write 'unrecorded' and do not guess."
fi

# ctx is controlled text with no double quotes or backslashes, so this is valid JSON.
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$ctx"
