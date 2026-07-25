#!/usr/bin/env bash
# STAR SessionStart hook — inject the runtime-reported model id into session
# context so skills record a real model_id instead of "unrecorded".
#
# Claude Code puts a `model` field on the SessionStart payload, and nowhere else:
# no other hook event carries it, and there is no $CLAUDE_MODEL env var. It is
# absent whenever the session did not start fresh — after /clear, resume,
# compact, or fork — which in practice is most sessions.
#
# When it is absent the id is still recoverable rather than lost. Claude Code
# stamps `message.model` on every assistant turn it appends to the session
# transcript, and the payload always carries `transcript_path`. That transcript
# is empty at SessionStart, so the read cannot happen here; instead the injected
# line hands the skill the command to run at the moment it needs the value. It
# reads the runtime's own record of this session, so it is not a guess — but it
# can be less precise than the SessionStart field, which may carry a
# context-window suffix the transcript drops (claude-opus-5[1m] -> claude-opus-5).
#
# Registered under hooks.SessionStart in .claude/settings.json. Prints one JSON
# object whose additionalContext is added to context before the first prompt.

# --resolve <transcript_path>: print the last assistant model id recorded in a
# transcript, or nothing at all. Run on demand by skills, per the line injected
# below. Prints nothing rather than failing, so "unrecorded" stays the fallback.
if [ "${1:-}" = "--resolve" ]; then
    transcript="${2:-}"
    { [ -n "${transcript}" ] && [ -r "${transcript}" ]; } || exit 0
    if command -v jq >/dev/null 2>&1; then
        jq -r 'select(.type == "assistant") | .message.model // empty' \
            "${transcript}" 2>/dev/null | grep -vx '<synthetic>' | tail -1
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "${transcript}" <<'PY' 2>/dev/null
import json, sys

last = ""
with open(sys.argv[1], errors="replace") as fh:
    for line in fh:
        try:
            entry = json.loads(line)
        except Exception:
            continue
        if entry.get("type") != "assistant":
            continue
        model = (entry.get("message") or {}).get("model")
        if model and model != "<synthetic>":
            last = model
print(last)
PY
    fi
    exit 0
fi

input=$(cat)

# Read one top-level string field from the payload.
payload_field() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "${input}" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        printf '%s' "${input}" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get(sys.argv[1]) or "")
except Exception:
    print("")' "$1" 2>/dev/null
    else
        printf '%s' "${input}" \
            | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
            | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
    fi
}

model=$(payload_field model)
transcript=$(payload_field transcript_path)
self="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/star_model_id.sh"

if [ -n "${model:-}" ]; then
    ctx="STAR provenance: this session's runtime-reported model id is ${model}. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'."
elif [ -n "${transcript:-}" ]; then
    ctx="STAR provenance: the runtime stated no model id at session start, which is expected after /clear, resume, compact, or fork. It is still recoverable from this session's own transcript. Before a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), run: bash ${self} --resolve ${transcript} — then copy what it prints verbatim. Write 'unrecorded' only if it prints nothing, and do not guess."
else
    ctx="STAR provenance: the runtime stated no model id for this session and named no transcript to recover it from. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), write 'unrecorded' and do not guess."
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
