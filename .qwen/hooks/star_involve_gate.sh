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

# The payload is read before the level is tested: the runtime writes it to this
# hook's stdin, and a hook that exits without reading leaves that write to fail.
input=$(cat)

line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
value="${line#INVOLVE=}"
value="${value%%#*}"
involve="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
[[ "${involve}" == "low" ]] || exit 0

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

# A run's worktree sits beside the project, at ../<root-dirname>--wt/<run>/
# (conventions §11.8), and its edits are the run's own as much as edits in the
# project are; any other path outside the project keeps its prompt.
wt="$(dirname "${root}")/$(basename "${root}")--wt"
path="$(edited_path)"
case "${path}" in
    "${root}"/*) rel="${path#"${root}"/}" ;;
    "${wt}"/*/*) rel="${path#"${wt}"/}"; rel="${rel#*/}" ;;
    *) exit 0 ;;
esac

# Dot-directories at the project root, or at a worktree's root — .git, .qwen,
# .star, the other tool trees, a worktree's linked .env — keep their prompt, the
# way auto-edit mode keeps one for protected paths. Their contents are project
# machinery, not the code a run is editing. A `..` segment can climb back out
# of either root, so a path carrying one keeps its prompt too.
[[ "${rel}" == .* || "${rel}" == */../* || "${rel}" == */.. ]] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"INVOLVE=low"}}\n'
