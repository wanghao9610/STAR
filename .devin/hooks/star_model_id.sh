#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# STAR SessionStart hook (Devin) — inject the runtime-reported model id into
# session context so skills record a real model_id instead of "unrecorded".
#
# Devin's SessionStart payload carries `source` and `session_id`
# only: no model field, and no transcript path a --resolve command could read
# later, so a session that reports no model stays "unrecorded" (conventions §8).
# Registered under SessionStart in .devin/hooks.v1.json.

input=$(cat)

model=$(printf '%s' "$input" | star_json_field model 2>/dev/null)

if [ -n "${model:-}" ]; then
  ctx="STAR provenance: this session's runtime-reported model id is ${model}. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'. If you switch models mid-session, this string is the one you started with, not the one writing."
else
  ctx="STAR provenance: the runtime stated no model id for this session and named no transcript to recover it from. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), write 'unrecorded' and do not guess."
fi

star_json_context devin SessionStart "$ctx"
