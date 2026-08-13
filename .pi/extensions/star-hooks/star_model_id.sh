#!/usr/bin/env bash
# STAR session hook (Pi) — print the runtime-reported model id so skills record a
# real model_id instead of "unrecorded".
#
# Pi is the one runtime where this value cannot go stale. Its extension API hands
# the live model object to every handler (ctx.model) and fires model_select
# whenever /model or Ctrl+P changes it, so .pi/extensions/star-hooks/index.ts reads the
# id at the prompt that will use it and prints a fresh line after every switch.
# The other five trees have to work around a field that rides on session start
# alone: Claude Code, Codex and Qwen Code inject a command that reads the session
# record as you write, Cursor injects the id it saw at the start, and Kimi reads
# a config file. Nothing here parses a session file for that reason.
#
# Called as: star_model_id.sh [model-id]. With no argument — or an empty one —
# the runtime named no model, and "unrecorded" is the honest value per
# research-workflow-conventions §8. Prints plain text; wrapping it into a message
# the model sees is the extension's job.

model="${1:-}"

if [ -n "${model}" ]; then
    printf '%s\n' "STAR provenance: this session's runtime-reported model id is ${model}. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), copy this exact string verbatim; do not write 'unrecorded'. If the model changes mid-session, a new line like this one arrives with the new id — the last one you were given is the one writing."
else
    printf '%s\n' "STAR provenance: the runtime stated no model id for this session. When a STAR skill records a model_id or a model_trail entry (research-workflow-conventions section 8), write 'unrecorded' and do not guess."
fi
exit 0
