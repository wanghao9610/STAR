#!/usr/bin/env bash
# STAR PermissionRequest hook (Codex CLI) — skip the approval prompt for a file
# edit while the project runs at INVOLVE=low (.env, workflow conventions §7.7).
# Confirmation points are untouched: the STOP line, commit offers, deletions and
# plan approval are questions a skill asks, not prompts a hook can answer.
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

line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
value="${line#INVOLVE=}"
value="${value%%#*}"
involve="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
[[ "${involve}" == "low" ]] || exit 0

input=$(cat)

# apply_patch arrives as the shell command that carries the patch envelope, so
# the paths are the envelope's own headers rather than a field. Decoding a
# multi-line JSON string needs a parser; with neither at hand the hook declines.
patch_text() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "${input}" | jq -r '.tool_input.command // empty' 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        printf '%s' "${input}" | python3 -c 'import sys, json
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("command") or "")
except Exception:
    print("")' 2>/dev/null
    fi
}

# Every path the patch names must sit in the project, outside the dot-directories
# at its root — .git, .codex, .star, the other tool trees — whose contents are
# project machinery rather than the code a run is editing.
path_ok() { # $1 = path as the header writes it, relative to cwd or absolute
    local rel="$1"
    case "$1" in
        /*) case "$1" in
                "${root}"/*) rel="${1#"${root}"/}" ;;
                *) return 1 ;;
            esac ;;
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
