#!/usr/bin/env bash
# STAR session hook (Pi) — print the project's memory index so a session starts
# knowing what earlier sessions in this repository learned.
#
# The store is .star/memory/ in the project, not the harness's own memory: one
# file per fact, listed one line each in MEMORY.md, with machine-specific facts
# under local/ (git-ignored, like .env). Only the index is printed — the lines
# are pointers, and the fact itself is read from its file when it matters. What
# belongs in the store, and the format of both, is docs/mds/star-workflow/memory_spec.md.
#
# Nothing is printed when the store holds no entries, so a fresh project pays
# nothing: the rule that creates the first memory is AGENTS.md section 10, which
# is loaded anyway.
#
# Pi has no command-hook protocol — its extension point is TypeScript — so this
# copy takes no payload and prints the context as plain text. Wrapping it into a
# message the model sees is .pi/extensions/star-hooks/index.ts's job, which is also why
# there is no JSON encoder here: the four other trees encode because the runtime
# reads their stdout as JSON, and Pi's reads it as text.

# Every harness registers this script by its own path inside the project, so the
# project root is derived from the script itself — no environment variable and no
# payload field, which differ per harness. Three levels here, not the other trees'
# two: Pi reserves .pi/hooks/ as the old name for extensions and warns when it
# exists, so these scripts live beside the extension that runs them, one directory
# deeper (.pi/extensions/star-hooks/).
root="$(cd -- "$(dirname -- "$0")/../../.." 2>/dev/null && pwd -P)" || exit 0

# An `env` memory is a fact about a machine, and machines change under it; six
# months is where "recorded" stops implying "still true". The other three types
# do not age this way — a dead end stays dead — and flagging them would teach the
# reader to skip the flag. Both spellings are tried because the flag is BSD's on
# macOS and GNU's on Linux; where neither works, nothing is marked at all.
cutoff="$(date -v-180d +%Y-%m-%d 2>/dev/null || date -d '180 days ago' +%Y-%m-%d 2>/dev/null || true)"

entries() { # $1 = index file -> its entry lines, aged `env` ones marked
    [ -r "$1" ] || return 0
    awk -v cutoff="${cutoff}" '
        /^- / {
            if (split($0, f, " · ") >= 4 && cutoff != "" &&
                substr(f[1], 3) == "env" && f[3] < cutoff)
                print $0 "  [stale: verify before relying on it]"
            else
                print
        }
    ' "$1"
}

shared="$(entries "${root}/.star/memory/MEMORY.md")"
machine="$(entries "${root}/.star/memory/local/MEMORY.md")"
[ -n "${shared}${machine}" ] || exit 0

printf '%s\n' "STAR project memory — what earlier sessions in this repository learned, recorded under .star/memory/ rather than in your own memory store. Each line is a pointer, not the fact: type · scope · last verified · file — summary. Open the file under .star/memory/ before acting on one. A scope naming a machine or a plan applies only there, and where a memory disagrees with a file in the repository, the file wins. Recording a new one: AGENTS.md section 10."
[ -n "${shared}" ] && printf 'Shared (.star/memory/):\n%s\n' "${shared}"
[ -n "${machine}" ] && printf 'Machine-local (.star/memory/local/):\n%s\n' "${machine}"
exit 0
