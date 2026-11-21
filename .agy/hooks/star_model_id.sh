#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# STAR SessionStart hook (Antigravity) — inject the runtime-reported model id
# into session context so skills record a real model_id instead of "unrecorded".
#
# Antigravity passes `modelName` (which may be "auto" when model selection is
# automatic) and `transcriptPath` on the SessionStart payload, and injects
# `injectSteps` with a `systemMessage` object into the conversation. Every model
# turn appended to `transcript.jsonl` records `type: "PLANNER_RESPONSE"` with
# the concrete `model` that wrote it, so when `transcriptPath` is present this
# hook hands skills a `--resolve` command that reads the live writing model at
# artifact-write time — covering mid-session model switches and `auto` starts.
# Registered in .agents/hooks.json pointing to .agy/hooks/star_model_id.sh.

# --resolve <transcript_path> [session_model]: print the model id of the last
# PLANNER_RESPONSE turn in a transcript, else a concrete session_model, or
# nothing at all so "unrecorded" remains the fallback.
if [ "${1:-}" = "--resolve" ]; then
    transcript="${2:-}"
    session_model="${3:-}"
    resolved=""
    if [ -n "${transcript}" ] && [ -r "${transcript}" ]; then
        resolved=$(star_json_models agy < "$transcript" 2>/dev/null)
    fi

    if [ -n "${resolved}" ]; then
        printf '%s\n' "${resolved}"
    elif [ -n "${session_model}" ] && [ "${session_model}" != "auto" ]; then
        printf '%s\n' "${session_model}"
    fi
    exit 0
fi

input=$(cat)

payload_field() { printf '%s' "$input" | star_json_field "$1" 2>/dev/null; }

model=$(payload_field modelName)
transcript=$(payload_field transcriptPath)
concrete_model=""
if [ -n "${model:-}" ] && [ "${model}" != "auto" ]; then
    concrete_model="${model}"
fi

self=".agy/hooks/star_model_id.sh"
printf -v transcript_arg '%q' "${transcript:-}"
printf -v model_arg '%q' "${concrete_model:-}"

if [ -n "${transcript:-}" ]; then
    ctx="STAR provenance: read this session's model id when you record it, not from memory — the runtime states it at session start only, and switching models changes it afterwards without firing a hook. Before a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), run: bash ${self} --resolve ${transcript_arg}${concrete_model:+ ${model_arg}} — then copy what it prints verbatim. Write 'unrecorded' only if it prints nothing, and do not guess."
elif [ -n "${concrete_model}" ]; then
    ctx="STAR provenance: this session's runtime-reported model id is ${concrete_model}, and the runtime named no transcript to check it against later. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'."
else
    ctx="STAR provenance: the runtime stated no concrete model id for this session (modelName=${model:-unset}) and named no transcript to recover it from. If the runtime's own session context names a concrete model id, copy it verbatim; otherwise write 'unrecorded' and do not guess (research-workflow-conventions section 8)."
fi

star_json_context agy SessionStart "$ctx"
