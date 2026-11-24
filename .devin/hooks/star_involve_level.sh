#!/usr/bin/env bash
# Resolve the involve level for the Devin permission gates, and record the token
# that sets it. Sourced by star_involve_gate.sh, star_bash_gate.sh and
# star_involve_record.sh; decides nothing itself.
#
# The level follows conventions §7.7: the `involve=` token of the session's most
# recent STAR command, else `.env`'s INVOLVE. Devin's tool payloads carry no
# transcript path, so star_involve_record.sh reads the token on UserPromptSubmit,
# whose payload carries the typed prompt, and keeps it per session_id in a
# per-user state directory outside the project. A STAR command without a token
# records an empty file, which hands the level back to `.env`; a prompt that is
# not a STAR command leaves the record alone.
#
# The `.env` comparison is exact — low means the literal low, optionally quoted,
# exported, indented, comment- or CR-terminated. Anything else, including a
# lookalike such as `low1`, is not low, and a later malformed line overrides an
# earlier valid one, the way a re-read file does.

star_devin_state_file() { # $1 = session_id -> path, or nothing for an unusable id
    local sid
    sid="$(printf '%s' "$1" | LC_ALL=C tr -cd 'A-Za-z0-9._-')"
    [ -n "${sid}" ] || return 1
    printf '%s/star-devin-involve-%s/%s' "${TMPDIR:-/tmp}" "$(id -u)" "${sid}"
}

# The involve level a typed prompt sets, when it is a STAR command: prints low,
# medium, high, or nothing for a STAR command without one. Exit 1 when the prompt
# is not a STAR command at all.
star_devin_prompt_token() { # $1 = prompt text
    local text="$1" args last before token re='^/star(-[a-z][a-z-]*)?([[:space:]]|$)'
    text="${text#"${text%%[![:space:]]*}"}"
    [[ "${text}" =~ ${re} ]] || return 1
    args="${text#"${BASH_REMATCH[0]}"}"
    args="${args%"${args##*[![:space:]]}"}"
    last="${args##*[[:space:]]}"
    case "${last}" in
        involve=low|involve=medium|involve=high) printf '%s' "${last#involve=}"; return 0 ;;
    esac
    before="${args%%stop=*}"
    token="$(printf '%s' "${before}" | grep -oE 'involve=(low|medium|high)' | tail -1)"
    printf '%s' "${token#involve=}"
}

star_devin_env_low() { # $1 = project root
    [ -r "$1/.env" ] || return 1
    LC_ALL=C awk '
        /^[[:blank:]]*(export[[:blank:]]+)?INVOLVE=/ {
            sub(/^[^=]*=/, "")
            sub(/\r$/, "")
            value = $0
        }
        END {
            q = sprintf("%c", 39)
            exit !(value ~ ("^(low|\"low\"|" q "low" q ")([[:blank:]]+#[^\r]*)?[[:blank:]]*$"))
        }
    ' "$1/.env"
}

star_devin_involve_low() { # $1 = project root, $2 = session_id (may be empty)
    local state token
    if state="$(star_devin_state_file "${2:-}")" && [ -f "${state}" ]; then
        token="$(head -n 1 "${state}" 2>/dev/null)"
        if [ -n "${token}" ]; then
            [ "${token}" = low ]
            return
        fi
    fi
    star_devin_env_low "$1"
}
