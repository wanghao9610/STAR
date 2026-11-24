#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# STAR PreToolUse hook (Claude Code) — decline the git commands that break the
# workflow conventions §1 in the ways that are expensive to undo. It is the floor
# under INVOLVE=low, which answers the commit offer itself (§1.5, §7.7): with
# nobody reading the staged file list, blanket staging and history rewrites are
# what turn a cheap local commit into one that needs surgery to unpick.
#
# Declined: blanket or forced staging (add/stage -A / . / ./ / * / :/ / -u / -f,
# commit -a), the history rewrites §1.3 names (commit --amend, rebase, reset
# --hard, filter-branch, filter-repo), the forced branch operations §11 makes
# costly (branch -D / -f, switch -C / -f / --discard-changes, checkout -B / -f —
# an execution branch force-deleted before its records reach the base branch
# loses them), a forced worktree removal (worktree remove --force, which deletes
# the tree's untracked artifacts), and a commit that would record a file over
# 10 MB — a checkpoint or a dataset in history is a research repository's one
# costly mistake, since clearing it back out needs exactly those rewrites. The
# size is read from the checkout the commit runs in (the payload's working
# directory, a preceding `cd`, or git's -C), so a run worktree is checked too.
# `push` is deliberately absent: no rule here makes a skill likelier to push, and
# a user who asks for one directly should get it.
#
# Registered under PreToolUse matching Bash in .claude/settings.json. One copy
# per harness tree (conventions §1, "The guard"), each differing only in how its
# harness names the command and working directory on the way in and the decision
# on the way out.
#
# It also holds the order the executor's report states (conventions §2): a
# prepared STOP-line command launches after its code review. A launch is the
# run's script, `execs/scpts/<run>.sh`, in command position — past nohup,
# timeout, sudo, source, bash -c, shell keywords and the other wrappers — or a
# redirect into the `wkdrs/<run>/.await` marker a star-auto launch writes; either
# requires current content-based review metadata and a passed review gate. Log
# dates do not determine validity. The run dir is looked up in this checkout
# first, then in the run's worktree at ../<root-dirname>--wt/<run>/ (§11.8), where
# a worktree run keeps its records until the merge. Writing the script, reading
# the marker, a `bash -n` syntax check, and light validation through execs/run.sh
# pass: none of them is the launch.
#
# A floor, not a proof. It reads one shell line at a time and cannot resolve
# quoting: a quote that opens inside one token and closes in another is matched
# only at its own edges, and a pathspec spelled with glob characters or
# `:(...)` magic is read as the literal path it is not. Silence means "no
# decision", so a spelling no branch below can read falls through to the normal
# permission flow. What it declines is the user's to run.
set -uo pipefail

# Every harness registers this script by its own path inside the project, so the
# project root is two levels up from the script itself — no environment variable
# and no payload field, which differ per harness.
root="$(cd -- "$(dirname -- "$0")/../.." 2>/dev/null && pwd -P)" || exit 0

input=$(cat)

# The shell command, from Bash's tool_input.
command_text() { printf '%s' "$input" | star_json_field 'tool_input.command' 2>/dev/null; }
# The directory the command runs in, from the payload's cwd.
payload_cwd() { printf '%s' "$input" | star_json_field 'cwd' 2>/dev/null; }

cmd="$(command_text)"
case "${cmd}" in
    *git*|*execs/scpts/*|*.await*) ;;
    *) exit 0 ;;
esac

# The reason reaches the agent as JSON, so it carries no quote and no backslash.
deny() { # $1 = one-line reason, $2 = what to do instead (default: hand it to the user)
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s (declined by .claude/hooks/star_commit_guard.sh — %s)"}}\n' "$1" "${2:-hand it to the user to run}"
    exit 0
}

# 10 MB. No source file, plan, or report comes near it; a checkpoint clears it by
# orders of magnitude.
size_limit=$((10 * 1024 * 1024))

# Append one path to over_list when its size exceeds the limit.
add_over() { # $1 = path, $2 = size in bytes
    local name="$1" size="${2//[[:space:]]/}"
    case "${size}" in ''|*[!0-9]*) return 0 ;; esac
    (( size > size_limit )) || return 0
    # Reasons reach the agent as JSON: no quote, no backslash, no control byte.
    name="${name//\\/}"; name="${name//\"/}"; name="${name//[[:cntrl:]]/ }"
    over_list="${over_list:+${over_list}, }${name} ($((size / 1024 / 1024)) MB)"
}

# Paths over the limit that a commit run in $1 would record, left in over_list:
# the staged blobs (a staged deletion records nothing, and an LFS pointer is
# sized as the pointer it is), plus each pathspec named on the commit line,
# whose working-tree content is what such a commit records.
oversize() { # $1 = checkout directory, $2… = pathspecs from the commit line
    local dir="$1" f size
    shift
    over_list=""
    while IFS= read -r -d '' f; do
        size="$(git -C "${dir}" cat-file -s ":${f}" 2>/dev/null)" || continue
        add_over "${f}" "${size}"
    done < <(git -C "${dir}" diff --cached --name-only --diff-filter=d -z 2>/dev/null)
    for f in "$@"; do
        case "${f}" in /*) ;; *) f="${dir}/${f}" ;; esac
        [[ -f "${f}" ]] || continue
        size="$(wc -c < "${f}" 2>/dev/null)" || continue
        add_over "${f#"${dir}"/}" "${size}"
    done
}

# A directory named relative to another, quote-stripped and resolved; empty when
# it does not exist.
resolve_dir() { # $1 = base directory, $2 = path as written
    local d="$2"
    d="${d#\'}"; d="${d#\"}"; d="${d%\'}"; d="${d%\"}"
    case "${d}" in /*) ;; *) d="$1/${d}" ;; esac
    (cd -- "${d}" 2>/dev/null && pwd -P)
}

# Resolve the run's actual checkout before checking its content-based review.
# No run log means this is not a recognized STAR launch. A missing helper in a
# recognized run fails closed so old installations cannot bypass the review.
unreviewed_run() {
    local run_root="${root}" dir="${root}/wkdrs/$1" helper reason
    if [[ ! -f "${dir}/EXEC_LOG.md" ]]; then
        run_root="$(dirname "${root}")/$(basename "${root}")--wt/$1"
        dir="${run_root}/wkdrs/$1"
    fi
    [[ -f "${dir}/EXEC_LOG.md" ]] || return 0
    helper="${run_root}/.agents/skills/star-code-reviewer/scripts/review_state.sh"
    if [[ ! -f "${helper}" ]]; then
        printf 'STAR conventions §2: review-state helper missing for wkdrs/%s/; update STAR and verify the review before launch' "$1"
        return 0
    fi
    if ! reason="$(bash "${helper}" --root "${run_root}" check "$1" 2>/dev/null)"; then
        # Hook JSON reasons must not contain raw path quoting or control bytes.
        reason="${reason//\\/}"; reason="${reason//\"/}"
        reason="${reason//$'\n'/ }"; reason="${reason//$'\r'/ }"; reason="${reason//$'\t'/ }"
        printf 'STAR conventions §2: wkdrs/%s/ review does not authorize launch: %s' "$1" "${reason:-invalid review state; refresh the review}"
    fi
    return 0
}

# The command a segment runs: past wrappers, shell keywords, assignments,
# options, and a timeout's duration or a nice's count. Sets ci (its index, or
# the token count when there is none) and cmd0 (its quote-stripped form), and
# syntax_only when a shell wrapper carries -n, which reads a script without
# running it.
command_position() {
    local t in_shell=0
    ci=0; cmd0=""; syntax_only=0
    while [[ ${ci} -lt ${#tok[@]} ]]; do
        # A quote pair can span tokens (`bash -c "git add -A"` splits as `"git`),
        # so each side strips on its own.
        t="${tok[ci]}"
        t="${t#\'}"; t="${t#\"}"; t="${t%\'}"; t="${t%\"}"
        case "${t##*/}" in
            env|command|exec|nohup|setsid|time|nice|caffeinate|stdbuf|timeout|sudo|xargs|eval|source|.|if|then|do|else|elif|while|until|'{'|'!')
                in_shell=0; ci=$((ci + 1)) ;;
            sh|bash|zsh)
                in_shell=1; ci=$((ci + 1)) ;;
            --*|*=*)
                ci=$((ci + 1)) ;;
            -*)
                (( in_shell )) && [[ ${t} == *n* ]] && syntax_only=1
                ci=$((ci + 1)) ;;
            *)
                # Durations and counts are wrapper arguments; numbered run
                # scripts are commands, not numeric arguments.
                if [[ ${t} =~ ^[0-9]+(\.[0-9]+)?[smhd]?$ ]]; then ci=$((ci + 1)); else cmd0="${t}"; break; fi ;;
        esac
    done
}

# The checkout the line's git commands run in, moved by each `cd` before them.
work_dir="$(payload_cwd)"
work_dir="$(resolve_dir "${root}" "${work_dir:-.}")"
[[ -n "${work_dir}" ]] || work_dir="${root}"

# The end index of an option's value: the token the option names, or — when the
# value opens a quote it does not close on its own token — the token the quote
# closes on. Reads `tok` (the segment's words), since a message can span words.
commit_option_value_end() { # $1 = first token index, $2 = value or its first token
    local k="$1" value="$2" quote
    quote="${value:0:1}"
    case "$quote" in
        \"|\')
            if [[ "${value:1}" != *"${quote}" ]]; then
                while (( ++k < ${#tok[@]} )); do
                    [[ "${tok[k]}" == *"${quote}" ]] && break
                done
            fi ;;
    esac
    printf '%s' "$k"
}

# The command line with every ; & | ( ) inside a quoted string blanked, and a
# quoted newline joined, so a commit message in the `type(scope): …` style no
# longer cuts its own command in two. The plain split still runs as well: it is
# what exposes a command quoted inside `bash -c "…"`, which this one keeps whole.
quote_masked() {
    awk '
        {
            out = ""; n = length($0)
            for (i = 1; i <= n; i++) {
                c = substr($0, i, 1)
                if (esc) { esc = 0; out = out c; continue }
                if (c == "\\" && q != "\047") { esc = 1; out = out c; continue }
                if (q == "" && (c == "\"" || c == "\047")) q = c
                else if (q != "" && c == q) q = ""
                else if (q != "" && index(";&|()", c)) c = " "
                out = out c
            }
            if (q != "") printf "%s ", out; else print out
        }
        END { if (q != "") print "" }'
}

# One shell line can carry several commands, so each is read on its own: `cd x &&
# git add -A` is the add it looks like.
while IFS= read -r segment; do
    read -ra tok <<< "${segment}"
    [[ ${#tok[@]} -gt 0 ]] || continue
    command_position

    if [[ "${cmd0}" == cd ]]; then
        next_dir="$(resolve_dir "${work_dir}" "${tok[ci + 1]:-${HOME:-.}}")"
        [[ -n "${next_dir}" ]] && work_dir="${next_dir}"
        continue
    fi

    # A prepared STOP-line command launches only after its review (conventions
    # §2; the header). The run whose launch this segment is, if any: the run's
    # script in command position, else a redirect into the run's .await marker.
    launch_run=""
    if (( ! syntax_only )); then
        case "${cmd0}" in
            execs/scpts/*.sh|*/execs/scpts/*.sh)
                launch_run="${cmd0##*execs/scpts/}"; launch_run="${launch_run%.sh}" ;;
        esac
    fi
    if [[ -z "${launch_run}" ]]; then
        for ((lj = 0; lj < ${#tok[@]}; lj++)); do
            lt="${tok[lj]}"
            case "${lt}" in
                \>*|[0-9]\>*) lt="${lt#[0-9]}"; lt="${lt#>}"; lt="${lt#>}" ;;
                *) (( lj > 0 )) && [[ "${tok[lj - 1]}" == *\> ]] || continue ;;
            esac
            lt="${lt#\'}"; lt="${lt#\"}"; lt="${lt%\'}"; lt="${lt%\"}"
            case "${lt}" in
                wkdrs/*/.await|wkdrs/*/.await.*|*/wkdrs/*/.await|*/wkdrs/*/.await.*)
                    launch_run="${lt##*wkdrs/}"; launch_run="${launch_run%%/*}" ;;
            esac
        done
    fi
    if [[ -n "${launch_run}" && "${launch_run}" != */* ]]; then
        launch_reason="$(unreviewed_run "${launch_run}")"
        [[ -n "${launch_reason}" ]] && \
            deny "${launch_reason}" "run star-code-reviewer on that run first; the launch follows the review"
    fi

    case "${cmd0##*/}" in
        git) ;;
        *) continue ;;
    esac

    # Walk past git's own options — `git -C dir add` names its subcommand third.
    git_dir="${work_dir}"
    i=$((ci + 1))
    while [[ ${i} -lt ${#tok[@]} ]]; do
        case "${tok[i]}" in
            -C)
                next_dir="$(resolve_dir "${git_dir}" "${tok[i + 1]:-}")"
                [[ -n "${next_dir}" ]] && git_dir="${next_dir}"
                i=$((i + 2)) ;;
            -c|--git-dir|--work-tree|--namespace|--exec-path) i=$((i + 2)) ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
        esac
    done
    [[ ${i} -lt ${#tok[@]} ]] || continue
    sub="${tok[i]}"; sub="${sub#\'}"; sub="${sub#\"}"; sub="${sub%\'}"; sub="${sub%\"}"

    case "${sub}" in
        add|stage)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                # `git add "."` is the instruction `git add .` is; word splitting
                # keeps the quotes, so one pair comes off before matching.
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                case "${arg}" in
                    -A|--all|-u|--update|--no-ignore-removal|.|./|:/|:/.|':/*'|'*'|'./*')
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
            paths=(); path_only=0
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                if (( path_only )); then
                    paths+=("${arg}"); continue
                fi
                case "${arg}" in
                    --) path_only=1 ;;
                    -m|--message|-F|--file|-t|--template|--fixup|--squash|-C|-c|--reuse-message|--reedit-message)
                        j=$((j + 1)); j="$(commit_option_value_end "$j" "${tok[j]:-}")" ;;
                    --message=*|--file=*|--template=*|--fixup=*|--squash=*|--reuse-message=*|--reedit-message=*)
                        j="$(commit_option_value_end "$j" "${tok[j]#*=}")" ;;
                    -m?*|-F?*|-t?*|-C?*|-c?*)
                        j="$(commit_option_value_end "$j" "${tok[j]:2}")" ;;
                    --amend)
                        deny "STAR conventions §1.3: no history rewrites — the user owns the branch and the remote. Make a new commit instead." ;;
                    --all)
                        deny "STAR conventions §1.1: commit --all stages every tracked modification, including work this run did not do. Stage the paths this run wrote, by name, then commit without it." ;;
                    --*) ;;
                    -*)
                        # Only an a before the first value-taking letter is -a:
                        # -uall and -Sabc carry the letter inside their value.
                        cluster="${arg#-}"; cluster="${cluster%%[uSCcmFt]*}"
                        [[ "${cluster}" == *a* ]] && \
                            deny "STAR conventions §1.1: commit -a stages every tracked modification, including work this run did not do. Stage the paths this run wrote, by name, then commit without -a." ;;
                    *) paths+=("${arg}") ;;
                esac
            done
            oversize "${git_dir}" ${paths[@]+"${paths[@]}"}
            [[ -n "${over_list}" ]] && \
                deny "STAR conventions §1.6: this commit records a file over 10 MB — ${over_list}. Clearing a large file back out of history needs a rewrite §1.3 forbids, so leave it out of the commit."
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
                    --*) ;;
                    -*[Cf]*)
                        deny "STAR conventions §1.3: this flag cluster carries a forced switch or a branch reset. Pick a fresh branch name, and keep uncommitted work." ;;
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
                    --*) ;;
                    -*[Bf]*)
                        deny "STAR conventions §1.3: this flag cluster carries a forced checkout or a branch reset. Pick a fresh branch name, and keep uncommitted work." ;;
                esac
            done
            ;;
        worktree)
            wt_remove=0
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
                case "${arg}" in
                    remove) wt_remove=1 ;;
                    --*) [[ "${arg}" == --force ]] && (( wt_remove )) && \
                            deny "STAR conventions §11.9: a forced worktree removal deletes the tree's untracked artifacts. Move them to the main checkout first — a clean tree removes without --force." ;;
                    -*f*)
                        (( wt_remove )) && \
                            deny "STAR conventions §11.9: a forced worktree removal deletes the tree's untracked artifacts. Move them to the main checkout first — a clean tree removes without --force." ;;
                esac
            done
            ;;
    esac
done < <(printf '%s\n' "${cmd}" | tr ';&|()' '\n\n\n\n\n'; printf '%s\n' "${cmd}" | quote_masked | tr ';&|()' '\n\n\n\n\n')

exit 0
