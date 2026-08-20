#!/usr/bin/env bash
# Skip Claude's permission prompt for file edits while the project runs at
# INVOLVE=low (.env, workflow conventions §7.7). Confirmation points are
# untouched: the STOP line, deletions and plan approval are questions a skill
# asks, not permission prompts a hook can answer.
#
# Silence means "no decision", so every other level, every path this declines,
# and a project with no .env fall through to the normal permission flow. INVOLVE
# is read on each call, so editing .env takes effect without a restart.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: the runtime writes it to this
# hook's stdin, and a hook that exits without reading leaves that write to fail.
input=$(cat)

line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
value="${line#INVOLVE=}"
value="${value%%#*}"
involve="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
[[ "${involve}" == "low" ]] || exit 0

# The edited path, from Edit/Write (file_path) or NotebookEdit (notebook_path).
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

# Dot-directories at the project root — .git, .claude, .star, the other tool
# trees — keep their prompt, the way acceptEdits mode keeps one for protected
# paths. Their contents are project machinery, not the code a run is editing.
[[ "${path#"${root}"/}" == .* ]] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"INVOLVE=low"}}\n'
