#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# Skip Antigravity's permission prompt for file edits while the project runs at
# INVOLVE=low (.env, workflow conventions §7.7).
#
# Registered under PreToolUse matching edit_file|write_file in
# .agents/hooks.json pointing to .gemini/antigravity-cli/hooks/star_involve_gate.sh.
set -uo pipefail

root_logical="$(cd -- "$(dirname -- "$0")/../../.." 2>/dev/null && pwd)" || exit 0
root_physical="$(cd -- "$(dirname -- "$0")/../../.." 2>/dev/null && pwd -P)" || exit 0
root="${root_physical}"

input=$(cat)

line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
value="${line#INVOLVE=}"
value="${value%%#*}"
involve="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
[[ "${involve}" == "low" ]] || exit 0

edited_path() { printf '%s' "$input" | star_json_field 'toolCall.args.Path' 2>/dev/null; }

wt_logical="$(dirname "${root_logical}")/$(basename "${root_logical}")--wt"
wt_physical="$(dirname "${root_physical}")/$(basename "${root_physical}")--wt"
path="$(edited_path)"
while [[ "${path}" == *//* ]]; do path="${path//\/\///}"; done
case "${path}" in
    "${root_physical}"/*) rel="${path#"${root_physical}"/}" ;;
    "${root_logical}"/*) rel="${path#"${root_logical}"/}" ;;
    "${wt_physical}"/*/*) rel="${path#"${wt_physical}"/}"; rel="${rel#*/}" ;;
    "${wt_logical}"/*/*) rel="${path#"${wt_logical}"/}"; rel="${rel#*/}" ;;
    *) exit 0 ;;
esac

[[ "${rel}" == .* || "${rel}" == */../* || "${rel}" == */.. ]] && exit 0

printf '{"decision":"allow","reason":"INVOLVE=low"}\n'
