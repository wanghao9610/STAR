#!/usr/bin/env bash
# Read .env's INVOLVE for the Devin permission gates. Sourced by
# star_involve_gate.sh and star_bash_gate.sh; decides nothing itself.
#
# Devin's hook payload carries no transcript path, so the `involve=` token of
# the most recent STAR command cannot reach a gate the way Claude Code's can:
# the level is .env's INVOLVE alone. The comparison is exact — low means the
# literal low, optionally quoted, exported, indented, comment- or CR-terminated.
# Anything else, including a lookalike such as `low1`, is not low, and a later
# malformed line overrides an earlier valid one, the way a re-read file does.
star_devin_involve_low() { # $1 = project root
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
