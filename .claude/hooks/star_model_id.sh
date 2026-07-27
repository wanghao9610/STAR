#!/usr/bin/env bash
# STAR SessionStart hook — inject the runtime-reported model id into session
# context so skills record a real model_id instead of "unrecorded".
#
# Claude Code puts a `model` field on the SessionStart payload, and nowhere else:
# no other hook event carries it, and there is no $CLAUDE_MODEL env var. It is
# absent whenever the session did not start fresh — after /clear, resume,
# compact, or fork — which in practice is most sessions. And when it is present
# it is a snapshot of one moment: /model switches the model without any hook
# firing, so a session that starts on one model and writes with another would
# record the one it started on.
#
# Both holes have the same floor. Claude Code stamps `message.model` on every
# assistant turn it appends to the session transcript, and the payload always
# carries `transcript_path`. That transcript is empty at SessionStart, so the
# read cannot happen here; instead the injected line hands the skill the command
# to run at the moment it needs the value, which is also the moment the answer is
# true. The SessionStart field is passed along to that command, because it is the
# more precise of the two when they agree: it may carry a context-window suffix
# the transcript drops (claude-opus-5[1m] -> claude-opus-5).
#
# Registered under hooks.SessionStart in .claude/settings.json. Prints one JSON
# object whose additionalContext is added to context before the first prompt.

# --resolve <transcript_path> [session_model]: print the model id of the last
# main-loop assistant turn in a transcript, or nothing at all. Run on demand by
# skills, per the line injected below. Prints nothing rather than failing, so
# "unrecorded" stays the fallback.
#
# Sidechain turns are skipped: a delegated subagent may run a different model,
# and the question this answers is which model is writing the artifact.
#
# session_model is what SessionStart reported, and settles the two ways the
# transcript alone is not enough. It stands in when the transcript names nothing
# yet, and it is preferred over an identical id to keep a context-window suffix
# the transcript drops. It never wins over a different id — that difference is a
# mid-session switch, and the transcript is the one that saw it.
if [ "${1:-}" = "--resolve" ]; then
    transcript="${2:-}"
    session_model="${3:-}"
    resolved=""
    if [ -n "${transcript}" ] && [ -r "${transcript}" ]; then
        if command -v jq >/dev/null 2>&1; then
            resolved=$(jq -r 'select(.type == "assistant" and (.isSidechain | not)) | .message.model // empty' \
                "${transcript}" 2>/dev/null | grep -vx '<synthetic>' | tail -1)
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
        if entry.get("type") != "assistant" or entry.get("isSidechain"):
            continue
        model = (entry.get("message") or {}).get("model")
        if model and model != "<synthetic>":
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
    # Same model, richer string: claude-opus-5[1m] over claude-opus-5.
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

if [ -n "${transcript:-}" ]; then
    ctx="STAR provenance: read this session's model id when you record it, not from memory — the runtime states it at session start only, and /model changes it afterwards without saying so. Before a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), run: bash ${self} --resolve ${transcript}${model:+ ${model}} — then copy what it prints verbatim. Write 'unrecorded' only if it prints nothing, and do not guess."
elif [ -n "${model:-}" ]; then
    ctx="STAR provenance: this session's runtime-reported model id is ${model}, and the runtime named no transcript to check it against later. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'. If you switch models mid-session, this string is the one you started with, not the one writing."
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
