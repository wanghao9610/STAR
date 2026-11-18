#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# STAR SessionStart hook (Antigravity) — inject the runtime-reported model id
# into session context so skills record a real model_id instead of "unrecorded".
#
# Antigravity passes `modelName` on the SessionStart payload (which may be
# "auto" when model selection is automatic) and injects `injectSteps` with a
# `systemMessage` object into the conversation. Registered in .agents/hooks.json
# pointing to .gemini/antigravity-cli/hooks/star_model_id.sh.

input=$(cat)

model=$(printf '%s' "$input" | star_json_field modelName 2>/dev/null)

if [ -n "${model:-}" ] && [ "${model}" != "auto" ]; then
  ctx="STAR provenance: this session's runtime-reported model id is ${model}. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'."
else
  ctx="STAR provenance: the runtime stated no concrete model id for this session (modelName=${model:-unset}). If the runtime's own session context names a concrete model id, copy it verbatim; otherwise write 'unrecorded' and do not guess (research-workflow-conventions section 8)."
fi

star_json_context agy SessionStart "$ctx"
