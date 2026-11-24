#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# STAR PermissionRequest hook (Codex CLI) — skip the approval prompt for a file
# edit while the project runs at INVOLVE=low (.env, workflow conventions §7.7).
# Confirmation points are untouched: the STOP line, deletions and plan approval
# are questions a skill asks, not prompts a hook can answer.
#
# Codex's counterpart to Claude's PreToolUse gate, written to Codex's own shapes.
# PermissionRequest is the event that fires just before the CLI waits on the
# user, and it is the one that takes decision.behavior; PreToolUse also documents
# an allow, but a released codex-cli rejected it, so approval goes through the
# event built for it. Registered under [hooks.PermissionRequest] in
# .codex/hooks.json, matching apply_patch. Codex offers no project-directory
# variable and runs hooks with the session cwd as their working directory, which
# is the project root a skill also runs in.
#
# Silence means "no decision", so every other level, every patch this declines,
# and a project with no .env fall through to the normal approval prompt.
set -uo pipefail

root="${PWD}"

# The payload is read before the level is tested: the runtime writes it to this
# hook's stdin, and a hook that exits without reading leaves that write to fail.
input=$(cat)

# Exact: low only as the literal (optionally quoted, exported, indented or
# commented); a lookalike such as low1 sets no level.
involve="$([ -r "${root}/.env" ] && LC_ALL=C awk '
    /^[[:blank:]]*(export[[:blank:]]+)?INVOLVE=/ { sub(/^[^=]*=/, ""); sub(/\r$/, ""); value = $0 }
    END {
        q = sprintf("%c", 39); lv = "(low|medium|high)"
        if (value !~ ("^(" lv "|\"" lv "\"|" q lv q ")([[:blank:]]+#[^\r]*)?[[:blank:]]*$")) exit
        sub(/[[:blank:]].*$/, "", value); gsub(/"/, "", value); gsub(q, "", value); print value
    }' "${root}/.env")"
[[ "${involve}" == "low" ]] || exit 0

# apply_patch arrives as the shell command that carries the patch envelope, so
# the paths are the envelope's own headers rather than a field. Decoding a
# multi-line JSON string uses the shared JSON reader.
patch_text() { printf '%s' "$input" | star_json_field tool_input.command 2>/dev/null; }

# Every path the patch names must sit in the project, or in a run's worktree
# beside it at ../<root-dirname>--wt/<run>/ (conventions §11.8), and outside the
# dot-directories at either root — .git, .codex, .star, the other harness trees,
# a worktree's linked .env — whose contents are project machinery rather than
# the code a run is editing.
wt="$(dirname "${root}")/$(basename "${root}")--wt"
path_ok() { # $1 = path as the header writes it, relative to cwd or absolute
    local rel="$1"
    case "$1" in
        /*) case "$1" in
                "${root}"/*) rel="${1#"${root}"/}" ;;
                "${wt}"/*/*) rel="${1#"${wt}"/}"; rel="${rel#*/}" ;;
                *) return 1 ;;
            esac ;;
        ../"${wt##*/}"/*/*) rel="${1#../"${wt##*/}"/}"; rel="${rel#*/}" ;;
    esac
    case "${rel}" in
        .*|*/..|*/../*) return 1 ;;
    esac
    return 0
}

headers="$(patch_text | grep -E '^\*\*\* (Add|Update|Delete) File: |^\*\*\* Move to: ')"

# No envelope, no decision. A Bash command reaching this hook by a mis-set
# matcher carries no headers either, so it declines rather than admitting a shell
# command through the gate meant for edits.
[[ -n "${headers}" ]] || exit 0

# The gate covers what Claude's covers: files added and files updated. A patch
# that deletes or renames keeps its prompt, deletion being asked at every level.
printf '%s\n' "${headers}" | grep -qE '^\*\*\* Delete File: |^\*\*\* Move to: ' && exit 0

while IFS= read -r header; do
    path_ok "${header#*: }" || exit 0
done <<< "${headers}"

printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}\n'
