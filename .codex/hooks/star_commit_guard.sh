#!/usr/bin/env bash
# STAR PreToolUse hook (Codex CLI) — decline the git commands that break the
# workflow conventions §1 in the ways that are expensive to undo. It is the floor
# under INVOLVE=low, which answers the commit offer itself (§1.5, §7.7): with
# nobody reading the staged file list, blanket staging and history rewrites are
# what turn a cheap local commit into one that needs surgery to unpick.
#
# Declined: blanket or forced staging (add -A / . / * / :/ / -u / -f, commit -a),
# the history rewrites §1.3 names (commit --amend, rebase, reset --hard,
# filter-branch, filter-repo), the forced branch operations §11 makes costly
# (branch -D / -f, switch -C / -f / --discard-changes, checkout -B / -f — an
# execution branch force-deleted before its records reach the base branch loses
# them), and a commit whose staged files exceed 10 MB — a
# checkpoint or a dataset in history is a research repository's one costly
# mistake, since clearing it back out needs exactly those rewrites. `push` is
# deliberately absent: no rule here makes a skill likelier to push, and a user
# who asks for one directly should get it.
#
# Registered under [hooks.PreToolUse] matching Bash in .codex/hooks.json. Codex
# offers no project-directory variable and runs hooks with the session cwd as
# their working directory, which is the project root a skill also runs in.
# PreToolUse rather than PermissionRequest, which the involve gate uses: that one
# fires only where the CLI would have waited on you, so a command the project
# already trusts never reaches it, and a guard is worth nothing on the commands
# nobody was going to be asked about. PreToolUse sees every tool call, and the
# allow a released codex-cli rejected is not what this hook returns.
#
# A floor, not a proof. It reads one shell line at a time and cannot resolve
# quoting, so a flag written after a commit message (`commit -m x --amend`) is
# past where it stops reading. Silence means "no decision", so that case, an
# unfamiliar spelling, and a machine with no JSON parser all fall through to the
# normal permission flow. What it declines is the user's to run.
set -uo pipefail

# Every harness registers this script by its own path inside the project, so the
# project root is two levels up from the script itself — no environment variable
# and no payload field, which differ per harness.
root="$(cd -- "$(dirname -- "$0")/../.." 2>/dev/null && pwd -P)" || exit 0

input=$(cat)

# The shell command, from Bash's tool_input.
command_text() {
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

cmd="$(command_text)"
case "${cmd}" in
    *git*) ;;
    *) exit 0 ;;
esac

# The reason reaches the agent as JSON, so it carries no quote and no backslash.
deny() { # $1 = one-line reason
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s (declined by .codex/hooks/star_commit_guard.sh — hand it to the user to run)"}}\n' "$1"
    exit 0
}

# 10 MB. No source file, plan, or report comes near it; a checkpoint clears it by
# orders of magnitude.
size_limit=$((10 * 1024 * 1024))

# Staged paths over the limit, as a printable list. Empty when none are.
staged_oversize() {
    local f size out=""
    while IFS= read -r -d '' f; do
        [[ -f "${root}/${f}" ]] || continue
        size="$(wc -c < "${root}/${f}" 2>/dev/null)" || continue
        size="${size//[[:space:]]/}"
        case "${size}" in ''|*[!0-9]*) continue ;; esac
        (( size > size_limit )) && out="${out:+${out}, }${f} ($((size / 1024 / 1024)) MB)"
    done < <(git -C "${root}" diff --cached --name-only -z 2>/dev/null)
    printf '%s' "${out}"
}

# One shell line can carry several commands, so each is read on its own: `cd x &&
# git add -A` is the add it looks like.
while IFS= read -r segment; do
    read -ra tok <<< "${segment}"
    [[ ${#tok[@]} -gt 0 ]] || continue
    case "${tok[0]}" in
        git|*/git) ;;
        *) continue ;;
    esac

    # Walk past git's own options — `git -C dir add` names its subcommand third.
    i=1
    while [[ ${i} -lt ${#tok[@]} ]]; do
        case "${tok[i]}" in
            -C|-c|--git-dir|--work-tree|--namespace|--exec-path) i=$((i + 2)) ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
        esac
    done
    [[ ${i} -lt ${#tok[@]} ]] || continue

    case "${tok[i]}" in
        add)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                # `git add "."` is the instruction `git add .` is; word splitting
                # keeps the quotes, so one pair comes off before matching.
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                case "${arg}" in
                    -A|--all|-u|--update|--no-ignore-removal|.|:/|:/*|'*')
                        deny "STAR conventions §1.1: a blanket add stages work this run did not do, and in a research repository it sweeps in checkpoints, datasets and scratch. Stage the paths this run wrote, by name." ;;
                    -f|--force)
                        deny "STAR conventions §1.6: a force-add puts a git-ignored path — .env, datas/, inits/ — into history. Stage a tracked path instead." ;;
                    --*) ;;
                    -*[Auf]*)
                        deny "STAR conventions §1.1 and §1.6: this flag cluster carries a blanket or forced add. Stage the paths this run wrote, by name." ;;
                esac
            done
            ;;
        commit)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                case "${arg}" in
                    -m|--message|-F|--file|-t|--template|--fixup|--squash|-C|--reuse-message|--reedit-message|-m*|--message=*|--file=*)
                        break ;;
                    --amend)
                        deny "STAR conventions §1.3: no history rewrites — the user owns the branch and the remote. Make a new commit instead." ;;
                    --all)
                        deny "STAR conventions §1.1: commit --all stages every tracked modification, including work this run did not do. Stage the paths this run wrote, by name, then commit without it." ;;
                    --*) ;;
                    -*a*)
                        deny "STAR conventions §1.1: commit -a stages every tracked modification, including work this run did not do. Stage the paths this run wrote, by name, then commit without -a." ;;
                esac
            done
            big="$(staged_oversize)"
            [[ -n "${big}" ]] && \
                deny "STAR conventions §1.6: staged over 10 MB — ${big}. Clearing a large file back out of history needs a rewrite §1.3 forbids, so unstage it first."
            ;;
        rebase)
            deny "STAR conventions §1.3: no history rewrites — the user owns the branch and the remote." ;;
        filter-branch|filter-repo)
            deny "STAR conventions §1.3: no history rewrites — the user owns the branch and the remote." ;;
        reset)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                [[ "${tok[j]}" == --hard ]] && \
                    deny "STAR conventions §1.3: reset --hard discards uncommitted work, including anything the user had in the tree."
            done
            ;;
        branch)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                case "${arg}" in
                    -D|--delete-force)
                        deny "STAR conventions §11: a force-deleted branch takes its unmerged commits and run records with it. Merge or discard at the confirmation point first; a merged branch deletes with -d." ;;
                    -f|--force)
                        deny "STAR conventions §1.3: forcing a branch onto another commit rewrites where its history points. Create a new branch instead." ;;
                    --*) ;;
                    -*[Df]*)
                        deny "STAR conventions §1.3 and §11: this flag cluster carries a forced branch delete or move. Merge or discard at the confirmation point first." ;;
                esac
            done
            ;;
        switch)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                case "${arg}" in
                    -C|--force-create)
                        deny "STAR conventions §1.3: switch -C resets an existing branch to another commit — a history rewrite in effect. Pick a fresh branch name." ;;
                    -f|--force|--discard-changes)
                        deny "STAR conventions §1.3: a forced switch discards uncommitted work, including anything the user had in the tree." ;;
                esac
            done
            ;;
        checkout)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                case "${arg}" in
                    --) break ;;
                    -B)
                        deny "STAR conventions §1.3: checkout -B resets an existing branch to another commit — a history rewrite in effect. Pick a fresh branch name." ;;
                    -f|--force)
                        deny "STAR conventions §1.3: a forced checkout discards uncommitted work, including anything the user had in the tree." ;;
                esac
            done
            ;;
    esac
done < <(printf '%s\n' "${cmd}" | tr ';&|()' '\n\n\n\n\n')

exit 0
