#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# Skip Antigravity's permission prompt for file edits while the run resolves to
# involve=low — from the session's most recent /star* invocation token outside
# any stop= line, falling back to INVOLVE in .env (workflow conventions §7.7).
#
# Registered under PreToolUse matching Antigravity's CLI and IDE file tools
# (write_file|edit_file|write_to_file|replace_file_content|multi_replace_file_content)
# in .agents/hooks.json pointing to .agy/hooks/star_involve_gate.sh.
set -uo pipefail

root_logical="$(cd -- "$(dirname -- "$0")/../.." 2>/dev/null && pwd)" || exit 0
root_physical="$(cd -- "$(dirname -- "$0")/../.." 2>/dev/null && pwd -P)" || exit 0
root="${root_physical}"

input=$(cat)

involve_token() { # $1 = STAR command args text -> low / medium / high / empty
    local args="$1" last before token
    args="${args%"${args##*[![:space:]]}"}"
    last="${args##*[[:space:]]}"
    case "${last}" in
        involve=low|involve=medium|involve=high) printf '%s' "${last#involve=}"; return 0 ;;
    esac
    before="${args%%stop=*}"
    token="$(printf '%s' "${before}" | grep -oE 'involve=(low|medium|high)' | tail -1)"
    printf '%s' "${token#involve=}"
}

resolve_involve() {
    local transcript args level line value
    transcript="$(printf '%s' "$input" | star_json_field 'transcriptPath' 2>/dev/null)"
    if [[ -n "${transcript}" && -r "${transcript}" ]]; then
        args="$(star_json_invocations agy < "${transcript}" 2>/dev/null)"
        if [[ -n "${args}" ]]; then
            level="$(involve_token "${args}")"
            [[ -n "${level}" ]] && { printf '%s' "${level}"; return 0; }
        fi
    fi
    line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
    value="${line#INVOLVE=}"
    value="${value%%#*}"
    printf '%s' "${value}" | tr -cd '[:alpha:]'
}

involve="$(resolve_involve)"
[[ "${involve}" == "low" ]] || exit 0

# Antigravity CLI file tools pass Path; Antigravity IDE/App tools pass TargetFile.
edited_path() { printf '%s' "$input" | star_json_eval 'x=at(r,"toolCall.args.Path"); if(type(x)!="string") x=at(r,"toolCall.args.TargetFile"); if(type(x)=="string") raw(x)' 2>/dev/null; }

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

printf '{"decision":"auto_approve","reason":"INVOLVE=low"}\n'
