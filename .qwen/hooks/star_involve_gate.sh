#!/usr/bin/env bash
# Skip Qwen Code's permission prompt for file edits while the project runs at
# INVOLVE=low (.env, workflow conventions §7.7). Confirmation points are
# untouched: the STOP line, deletions and plan approval are questions a skill
# asks, not permission prompts a hook can answer.
#
# Silence means "no decision", so every other level, every path this declines,
# and a project with no .env fall through to the normal permission flow. INVOLVE
# is read on each call, so editing .env takes effect without a restart.
set -uo pipefail

root="${QWEN_PROJECT_DIR:-${PWD}}"

line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
value="${line#INVOLVE=}"
value="${value%%#*}"
involve="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
[[ "${involve}" == "low" ]] || exit 0

input=$(cat)

# The edited path, from edit/write_file (file_path) or notebook_edit
# (notebook_path).
edited_path() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "${input}" \
            | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null
    else
        printf '%s' "${input}" \
            | grep -oE '"(file_path|notebook_path)"[[:space:]]*:[[:space:]]*"[^"]*"' \
            | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
    fi
}

path="$(edited_path)"
case "${path}" in
    "${root}"/*) ;;
    *) exit 0 ;;
esac

# Dot-directories at the project root — .git, .qwen, .star, the other tool
# trees — keep their prompt, the way auto-edit mode keeps one for protected
# paths. Their contents are project machinery, not the code a run is editing.
[[ "${path#"${root}"/}" == .* ]] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"INVOLVE=low"}}\n'
