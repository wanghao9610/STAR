#!/usr/bin/env bash
# Skip Claude's permission prompt for file edits while the project runs at
# INVOLVE=low (.env, workflow conventions §7.7). Confirmation points are
# untouched: the STOP line and deletions are questions a skill asks, not
# permission prompts a hook can answer. Plan approval at low is the executor's
# own text, which stays out of plan mode there: Claude Code's plan dialog
# answers to no hook.
#
# The level comes from star_involve_level.sh: the `involve=` token of the
# session's most recent STAR command, or `.env`'s INVOLVE when it carried none.
# Silence means "no decision", so every other level, every path this declines,
# and a project that sets none fall through to the normal permission flow. The
# level is resolved on each call, so a new invocation — or an edit to .env —
# takes effect without a restart.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: it carries the transcript path
# the level is resolved from, and a hook that exits without reading stdin leaves
# the runtime's write to fail.
input=$(cat)

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/star_involve_level.sh"
involve="$(star_involve_level "${input}" "${root}")"
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

# Dot-directories at the project root, or at a worktree's root — .git, .claude,
# .star, the other tool trees, a worktree's linked .env — keep their prompt, the
# way acceptEdits mode keeps one for protected paths. Their contents are project
# machinery, not the code a run is editing. A `..` segment can climb back out
# of either root, so a path carrying one keeps its prompt too.
[[ "${rel}" == .* || "${rel}" == */../* || "${rel}" == */.. ]] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"involve=low"}}\n'
