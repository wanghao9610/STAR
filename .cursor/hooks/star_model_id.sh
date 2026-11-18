#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# STAR sessionStart hook (Cursor) — inject the runtime-reported model id into
# session context so skills record a real model_id instead of "unrecorded".
#
# Cursor puts `model_id` (structured id) and `model` on the sessionStart payload,
# and injects the returned `additional_context` string into the conversation.
# When neither is present the honest value per research-workflow-conventions §8 is
# "unrecorded". Registered under hooks.sessionStart in .cursor/hooks.json.

input=$(cat)

model=$(printf '%s' "$input" | star_json_eval 'x=get(r,"model_id"); if(!x || type(x)=="null") x=get(r,"model"); if(type(x)=="string") raw(x)' 2>/dev/null)

if [ -n "${model:-}" ]; then
  ctx="STAR provenance: this session's runtime-reported model id is ${model}. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'."
else
  ctx="STAR provenance: the runtime stated no model id for this session. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), write 'unrecorded' and do not guess."
fi

star_json_context cursor SessionStart "$ctx"
