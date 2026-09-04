#!/usr/bin/env bash
# STAR SessionStart and SubagentStart hook — inject the runtime-reported model id
# into context so skills record a real model_id instead of "unrecorded".
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
# A delegate is the same problem one level down, and a worse one: SessionStart
# does not fire for a sub-agent at all, so without a second mount a delegate
# running its own model inherits the session's provenance line and records the
# model that dispatched it. SubagentStart does fire, and carries `session_id`,
# `transcript_path` and `agent_id` but no `model`, which is enough — --subagent
# below derives the delegate's own transcript from those three and injects the
# same kind of command pointed at it.
#
# Registered under hooks.SessionStart (no argument) and hooks.SubagentStart
# (--subagent) in .claude/settings.json. Prints one JSON object whose
# additionalContext is added to that context before its first prompt.

# --resolve <transcript_path> [session_model]: print the model id of the last
# assistant turn in a transcript, or nothing at all. Run on demand by skills,
# per the line injected below. Prints nothing rather than failing, so
# "unrecorded" stays the fallback.
#
# Which turns count depends on which transcript this is. In a session
# transcript, sidechain turns are skipped: a delegated sub-agent may run a
# different model, and the question this answers is which model is writing the
# artifact. A delegate's own transcript — .../subagents/agent-<id>.jsonl, a
# separate file as of Claude Code 2.1.260, with the session transcript carrying
# none of those turns any more — holds nothing but that delegate's
# turns and marks none of them as sidechain, so the same filter there would drop
# every turn and answer with the session model, the one id already known to be
# wrong.
#
# session_model is what SessionStart reported, and settles the two ways the
# transcript alone is not enough. It stands in when the transcript names nothing
# yet, and it is preferred over an identical id to keep a context-window suffix
# the transcript drops. It never wins over a different id — that difference is a
# mid-session switch, and the transcript is the one that saw it. A delegate is
# given no session model, because the session's is not the delegate's.
if [ "${1:-}" = "--resolve" ]; then
    transcript="${2:-}"
    session_model="${3:-}"
    resolved=""
    case "${transcript}" in
        */subagents/agent-*.jsonl) delegate=true ;;
        *) delegate=false ;;
    esac
    if [ -n "${transcript}" ] && [ -r "${transcript}" ]; then
        if command -v jq >/dev/null 2>&1; then
            if [ "${delegate}" = true ]; then
                filter='select(.type == "assistant") | .message.model // empty'
            else
                filter='select(.type == "assistant" and (.isSidechain | not)) | .message.model // empty'
            fi
            resolved=$(jq -r "${filter}" \
                "${transcript}" 2>/dev/null | grep -vx '<synthetic>' | tail -1)
        elif command -v python3 >/dev/null 2>&1; then
            resolved=$(python3 - "${transcript}" "${delegate}" <<'PY' 2>/dev/null
import json, sys

path, delegate = sys.argv[1], sys.argv[2] == "true"
last = ""
with open(path, errors="replace") as fh:
    for line in fh:
        try:
            entry = json.loads(line)
        except Exception:
            continue
        if entry.get("type") != "assistant":
            continue
        if not delegate and entry.get("isSidechain"):
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

event="SessionStart"
[ "${1:-}" = "--subagent" ] && event="SubagentStart"

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

# ctx embeds a filesystem path, so encode it as JSON rather than assuming it is
# quote-free; the last branch sanitizes instead, having no encoder to hand.
emit_context() { # $1 = hook event name, $2 = the context text
    if command -v jq >/dev/null 2>&1; then
        jq -cn --arg e "$1" --arg c "$2" \
            '{hookSpecificOutput: {hookEventName: $e, additionalContext: $c}}'
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": sys.argv[1], "additionalContext": sys.argv[2]}}))' \
            "$1" "$2"
    else
        printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' \
            "$1" "$(printf '%s' "$2" | tr -d '"\\')"
    fi
}

self="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/star_model_id.sh"

if [ "${event}" = "SubagentStart" ]; then
    session_id=$(payload_field session_id)
    transcript=$(payload_field transcript_path)
    agent_id=$(payload_field agent_id)
    if [ -z "${session_id}" ] || [ -z "${transcript}" ] || [ -z "${agent_id}" ]; then
        # Nothing to point the delegate at, and a wrong path is worse than none:
        # it would resolve to nothing and read as "the runtime named no model".
        printf '{}\n'
        exit 0
    fi
    # The payload names the session's transcript, and a delegate's sits beside
    # it under the session's own directory. Claude Code does not document which
    # of the two `transcript_path` carries, so a path already naming a delegate
    # file is taken as it stands rather than nested a second time.
    case "${transcript}" in
        */subagents/agent-*.jsonl) agent_transcript="${transcript}" ;;
        *) agent_transcript="$(dirname "${transcript}")/${session_id}/subagents/agent-${agent_id}.jsonl" ;;
    esac
    ctx="STAR provenance: this run is a delegate; the model id you record is this delegate's, not the session's. Before a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), run: bash ${self} --resolve ${agent_transcript} — at the moment you write, not earlier — then copy what it prints verbatim. Write 'unrecorded' only if it prints nothing, and do not guess."
    emit_context "${event}" "${ctx}"
    exit 0
fi

model=$(payload_field model)
transcript=$(payload_field transcript_path)

if [ -n "${transcript:-}" ]; then
    ctx="STAR provenance: read this session's model id when you record it, not from memory — the runtime states it at session start only, and /model changes it afterwards without saying so. Before a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), run: bash ${self} --resolve ${transcript}${model:+ ${model}} — then copy what it prints verbatim. Write 'unrecorded' only if it prints nothing, and do not guess."
elif [ -n "${model:-}" ]; then
    ctx="STAR provenance: this session's runtime-reported model id is ${model}, and the runtime named no transcript to check it against later. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'. If you switch models mid-session, this string is the one you started with, not the one writing."
else
    ctx="STAR provenance: the runtime stated no model id for this session and named no transcript to recover it from. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), write 'unrecorded' and do not guess."
fi

emit_context "${event}" "${ctx}"
