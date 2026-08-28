#!/usr/bin/env bash
# Skip Claude's permission prompt for shell commands while the project runs at
# INVOLVE=low (.env, workflow conventions §7.7) — the shell counterpart of
# star_involve_gate.sh, so a goal-driven run (goal mode re-invoking star-auto)
# is not parked at a prompt for every ls, grep, or python call. The red lines
# stay prompts at every level: deletion, sudo, disk and device writes, system
# and package installs, process kills, service control, git push, and forced
# mv/cp — this gate stays silent on those, and the normal permission flow takes
# over. Confirmation points are untouched: the STOP line and the questions a
# skill must ask are model turns, not permission prompts a hook can answer.
# star_commit_guard.sh runs beside this gate on the same matcher and its deny
# outranks this allow, so a blanket add is still declined, not allowed.
#
# A floor, not a proof. It reads one shell line at a time, cannot resolve
# quoting, and does not match redirection — `> file` overwrites pass, since the
# skills write logs and reports through them. Silence means "no decision", so
# every red line, every other level, a payload it cannot read, and a project
# with no .env all fall through to the normal permission flow. INVOLVE is read
# on each call, so editing .env takes effect without a restart.
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
    else
        # No parser on PATH: an allow read out of a misparsed payload could
        # cover a red line, so an unreadable command keeps its prompt.
        printf ''
    fi
}

cmd="$(command_text)"
[[ -n "${cmd}" ]] || exit 0

# A heredoc body is data, not commands — a commit-message line reading "rm old
# code" is not the rm it spells. Drop each body through its delimiter before
# the segments are read. Only a bare-word delimiter (EOF-shaped) opens one, and
# a here-string's <<< is erased first, so an arithmetic x<<2 cannot swallow the
# lines after it and hide a real command; anything malformed falls back to
# reading every line, which errs toward the prompt, never past it.
strip_heredocs() {
    local line probe rest delim="" body=0 out=""
    while IFS= read -r line; do
        if (( body )); then
            [[ "${line}" == "${delim}" || "${line//$'\t'/}" == "${delim}" ]] && body=0
            continue
        fi
        out="${out}${line}"$'\n'
        probe="${line//<<</ }"
        [[ "${probe}" == *'<<'* ]] || continue
        rest="${probe##*<<}"
        rest="${rest#-}"
        read -r delim rest <<< "${rest}" || delim=""
        delim="${delim#\'}"; delim="${delim%\'}"; delim="${delim#\"}"; delim="${delim%\"}"
        case "${delim}" in
            [A-Za-z_]*[!A-Za-z0-9_]*) ;;
            [A-Za-z_]*) body=1 ;;
        esac
    done <<< "${cmd}"
    printf '%s' "${out}"
}
cmd="$(strip_heredocs)"
[[ -n "${cmd}" ]] || exit 0

# One shell line can carry several commands, so each is read on its own:
# `cd x && sudo make install` is the sudo it looks like.
while IFS= read -r segment; do
    read -ra tok <<< "${segment}"
    [[ ${#tok[@]} -gt 0 ]] || continue

    # Walk past wrappers, assignments, flags, and a timeout's duration to the
    # command itself, so `env rm`, `timeout 30 rm`, and `xargs rm` are the rm
    # they carry.
    i=0
    while [[ ${i} -lt ${#tok[@]} ]]; do
        t="${tok[i]}"
        # A quote pair can span tokens (`bash -c "rm x"` splits as `"rm x"`),
        # so each side strips on its own, not only as a pair.
        t="${t#\'}"; t="${t#\"}"; t="${t%\'}"; t="${t%\"}"
        case "${t##*/}" in
            env|command|exec|nohup|time|nice|caffeinate|stdbuf|timeout|xargs|sh|bash|zsh)
                i=$((i + 1)) ;;
            *=*|-*|[0-9]*)
                i=$((i + 1)) ;;
            *)
                break ;;
        esac
    done
    [[ ${i} -lt ${#tok[@]} ]] || continue
    # The walk left this token's quote-stripped form in t.
    name="${t##*/}"

    case "${name}" in
        rm|rmdir|unlink|shred|srm|trash)
            exit 0 ;;
        sudo|su|doas)
            exit 0 ;;
        dd|mkfs*|fdisk|parted|diskutil|truncate)
            exit 0 ;;
        shutdown|reboot|halt|poweroff|launchctl|systemctl|service)
            exit 0 ;;
        kill|pkill|killall)
            exit 0 ;;
        modprobe|insmod|kextload|kextunload)
            exit 0 ;;
        apt|apt-get|aptitude|yum|dnf|pacman|zypper|brew|port|softwareupdate|installer)
            exit 0 ;;
        crontab)
            exit 0 ;;
        find)
            # A find that deletes or executes is whatever it carries.
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                case "${tok[j]}" in
                    -delete|-exec|-execdir|-ok|-okdir) exit 0 ;;
                esac
            done
            ;;
        git)
            # Walk past git's own options — `git -C dir push` names its
            # subcommand third. Push goes outward and is hard to retract.
            j=$((i + 1))
            while [[ ${j} -lt ${#tok[@]} ]]; do
                case "${tok[j]}" in
                    -C|-c|--git-dir|--work-tree|--namespace|--exec-path) j=$((j + 2)) ;;
                    -*) j=$((j + 1)) ;;
                    *) break ;;
                esac
            done
            [[ ${j} -lt ${#tok[@]} && "${tok[j]}" == "push" ]] && exit 0
            ;;
        mv|cp)
            # Only the forced form; a plain mv is how a dropped plan's files
            # move aside (§8), and prompting it would re-block a designed move.
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;; esac
                case "${arg}" in
                    --) break ;;
                    -f|--force|-*f*) exit 0 ;;
                esac
            done
            ;;
    esac
done < <(printf '%s\n' "${cmd}" | tr ';&|()' '\n\n\n\n\n')

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"INVOLVE=low (star_bash_gate.sh); red-line commands keep their prompt"}}\n'
