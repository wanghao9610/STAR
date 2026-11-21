#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# Skip Devin's permission prompt for file edits while the project runs at
# INVOLVE=low (.env, workflow conventions §7.7). Confirmation points are
# untouched: the STOP line and deletions are questions a skill asks, not
# permission prompts a hook can answer.
#
# Devin's hook payload names the tool call and its input but no transcript
# path, so the `involve=` token of the most recent STAR command cannot reach
# this hook the way Claude Code's can: the level is .env's INVOLVE, resolved
# on each call so an edit to .env takes effect without a restart. Silence
# means "no decision", so every other level, every path this declines, and a
# project that sets none fall through to the normal permission flow.
#
# Registered under PreToolUse matching ^(edit|write|notebook_edit)$ in
# .devin/hooks.v1.json — anchored, because Devin matches a regex anywhere in the
# tool name, and todo_write or an MCP tool such as mcp__<server>__write_file must
# not inherit this approve. apply_patch is left out: its input field is not
# documented, so its edits keep their prompt at every level.
set -uo pipefail

root="${DEVIN_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: a hook that exits without
# reading stdin leaves the runtime's write to fail.
input=$(cat)

source "$(dirname -- "${BASH_SOURCE[0]}")/star_involve_level.sh" || exit 0
star_devin_involve_low "${root}" || exit 0

# The edited path, from edit/write (file_path) or notebook_edit (notebook_path).
edited_path() { printf '%s' "$input" | star_json_eval 'x=at(r,"tool_input.file_path"); if(type(x)=="null" || !x) x=at(r,"tool_input.notebook_path"); if(type(x)=="string") raw(x)' 2>/dev/null; }

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

# Dot-directories at the project root, or at a worktree's root — .git, .devin,
# .star, the other tool trees, a worktree's linked .env — keep their prompt, the
# way an accept-edits mode keeps one for protected paths. Their contents are
# project machinery, not the code a run is editing. A `..` segment can climb
# back out of either root, so a path carrying one keeps its prompt too.
[[ "${rel}" == .* || "${rel}" == */../* || "${rel}" == */.. ]] && exit 0

printf '{"decision":"approve","reason":"involve=low"}\n'
