#!/usr/bin/env bash
# Resolve the involve level a gate hook should act on: the `involve=<level>`
# token of the session's most recent STAR command, or `.env`'s INVOLVE when that
# invocation carried none (workflow conventions §7.7, §7.12).
#
# Sourced by star_plan_gate.sh, star_involve_gate.sh and star_bash_gate.sh; it
# decides nothing itself. Prints one of low / medium / high, or nothing at all —
# and nothing means "no level set", which every caller reads as no decision.
#
# Why the transcript. The token rides in the invocation the user typed, which
# reaches the model and not the hook: a hook is a separate process, and its
# payload carries the tool call, never the words that started the run. What the
# payload does carry is `transcript_path`, and the transcript records a slash
# command as <command-name>/star-auto</command-name> beside a <command-args>
# block holding what was typed after it. That block is the only place read here.
# Plain chat text is ignored on purpose: a message *about* the level — "set
# involve=low for star-auto" — is discussion, and a grep over loose text would
# take it for a setting.
#
# Scope. The most recent STAR command wins for as long as it is the most recent:
# answering a question mid-run leaves it in force, and the next STAR command
# replaces it — with .env when that one names no level. A run's level therefore
# outlives the run itself, until the next command; .env stays the standing level
# and the token is the temporary one.

# The invocation's involve token, read from outside the stop line: the final
# token, or one before `stop=`. The same word after `stop=` is stop-line text,
# not the token — the rule .agents/commands/star-auto.md parses by.
star__involve_token() { # $1 = the <command-args> text
    local args="$1" last before token
    args="${args%"${args##*[![:space:]]}"}"
    last="${args##*[[:space:]]}"
    case "${last}" in
        involve=low|involve=medium|involve=high) printf '%s' "${last#involve=}"; return 0 ;;
    esac
    before="${args%%stop=*}"
    token="$(printf '%s' "${before}" | grep -oE 'involve=(low|medium|high)' | tail -1)"
    printf '%s' "${token#involve=}"
}

star__payload_field() { # $1 = payload JSON, $2 = top-level field name
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$1" | jq -r --arg k "$2" '.[$k] // empty' 2>/dev/null
    else
        printf '%s' "$1" \
            | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
            | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
    fi
}

# The <command-args> of the last STAR command in the transcript. Sidechain turns
# are skipped: a delegated subagent's invocation is not the user's.
star__latest_star_command_args() { # $1 = transcript path
    local transcript="$1"
    [ -n "${transcript}" ] && [ -r "${transcript}" ] || return 0
    if command -v jq >/dev/null 2>&1; then
        jq -r 'select(.type == "user" and (.isSidechain | not))
               | (.message.content) as $c
               | (if ($c | type) == "string" then $c
                  else ([$c[]? | select(.type? == "text") | .text] | join(" ")) end)
               | select(test("<command-name>[[:space:]]*/?star"))
               | capture("<command-args>(?<a>.*?)</command-args>"; "s").a' \
            "${transcript}" 2>/dev/null | tail -1
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "${transcript}" <<'PY' 2>/dev/null
import json, re, sys

name = re.compile(r"<command-name>\s*/?star")
args = re.compile(r"<command-args>(.*?)</command-args>", re.S)
last = ""
with open(sys.argv[1], errors="replace") as fh:
    for line in fh:
        try:
            entry = json.loads(line)
        except Exception:
            continue
        if entry.get("type") != "user" or entry.get("isSidechain"):
            continue
        content = (entry.get("message") or {}).get("content")
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            text = " ".join(b.get("text", "") for b in content
                            if isinstance(b, dict) and b.get("type") == "text")
        else:
            continue
        if not name.search(text):
            continue
        found = args.search(text)
        if found:
            last = found.group(1)
print(last)
PY
    fi
}

star__env_involve() { # $1 = project root
    local line value
    line="$(grep -sE '^INVOLVE=' "$1/.env" | tail -1)"
    value="${line#INVOLVE=}"
    value="${value%%#*}"
    printf '%s' "${value}" | tr -cd '[:alpha:]'
}

star_involve_level() { # $1 = hook payload, $2 = project root
    local args level
    args="$(star__latest_star_command_args "$(star__payload_field "$1" transcript_path)")"
    if [ -n "${args}" ]; then
        level="$(star__involve_token "${args}")"
        [ -n "${level}" ] && { printf '%s' "${level}"; return 0; }
    fi
    star__env_involve "$2"
}
