#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 0; }
# STAR UserPromptSubmit hook (Devin) — remember the `involve=` token of the STAR
# command the user just typed, so the permission gates resolve the run's own
# level (conventions §7.7) rather than `.env`'s alone. Devin's tool payloads carry
# no transcript, so this is the one event that sees the typed text.
#
# It records and never decides: every path exits 0 with no output, so a prompt is
# never blocked by it. A STAR command writes its token, or an empty record when it
# carries none; any other prompt leaves the record as it was. The record lives
# outside the project, per user and per session_id (star_involve_level.sh).
#
# Registered under UserPromptSubmit in .devin/hooks.v1.json.
set -uo pipefail

input=$(cat)
source "$(dirname -- "${BASH_SOURCE[0]}")/star_involve_level.sh" || exit 0

prompt="$(printf '%s' "${input}" | star_json_field prompt 2>/dev/null)"
token="$(star_devin_prompt_token "${prompt}")" || exit 0
sid="$(printf '%s' "${input}" | star_json_field session_id 2>/dev/null)"
state="$(star_devin_state_file "${sid}")" || exit 0
mkdir -p "$(dirname -- "${state}")" 2>/dev/null && chmod 700 "$(dirname -- "${state}")" 2>/dev/null || exit 0
printf '%s\n' "${token}" > "${state}" 2>/dev/null
exit 0
