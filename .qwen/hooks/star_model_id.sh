#!/usr/bin/env bash
# STAR SessionStart hook (Qwen Code) — inject the runtime-reported model id into
# session context so skills record a real model_id instead of "unrecorded".
#
# Qwen Code puts a `model` field on the SessionStart payload for every start
# reason it reports — startup, resume, clear and compact alike — so unlike Claude
# Code's copy of this hook there is no start shape that arrives without one. What
# it cannot cover is the same hole everywhere: /model switches the model without
# firing any hook, so a session that starts on one model and writes with another
# would record the one it started on.
#
# The floor under that is the session transcript. Qwen Code appends one record
# per model response to <project dir>/chats/<session_id>.jsonl, each carrying
# `type: "assistant"` and the `model` that wrote it, and the payload always names
# the file in `transcript_path`. The transcript is empty at SessionStart, so the
# read cannot happen here; instead the injected line hands the skill the command
# to run at the moment it needs the value, which is also the moment the answer is
# true. The SessionStart field is passed along to that command as the fallback
# for a transcript that has no assistant turn yet.
#
# Registered under hooks.SessionStart in .qwen/settings.json. Prints one JSON
# object whose additionalContext is added to context before the first prompt.

# --resolve <transcript_path> [session_model]: print the model id of the last
# assistant turn in a transcript, or nothing at all. Run on demand by skills, per
# the line injected below. Prints nothing rather than failing, so "unrecorded"
# stays the fallback.
#
# No sidechain filter is needed here, unlike Claude Code's copy: a Qwen subagent
# writes to its own transcript, named separately in the hook payload as
# `agent_transcript_path`, so this file holds main-loop turns only — which is the
# question this answers, namely which model is writing the artifact.
#
# session_model is what SessionStart reported. It stands in when the transcript
# names nothing yet, and never wins over an id the transcript does name — that
# difference is a mid-session switch, and the transcript is the one that saw it.
if [ "${1:-}" = "--resolve" ]; then
    transcript="${2:-}"
    session_model="${3:-}"
    resolved=""
    if [ -n "${transcript}" ] && [ -r "${transcript}" ]; then
        if command -v jq >/dev/null 2>&1; then
            resolved=$(jq -r 'select(.type == "assistant") | .model // empty' \
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
        if entry.get("type") != "assistant":
            continue
        model = entry.get("model")
        if model:
            last = model
print(last)
PY
            )
        fi
    fi

    if [ -n "${resolved}" ]; then
        printf '%s\n' "${resolved}"
    elif [ -n "${session_model}" ]; then
        printf '%s\n' "${session_model}"
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
self="${QWEN_PROJECT_DIR:-.}/.qwen/hooks/star_model_id.sh"

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
