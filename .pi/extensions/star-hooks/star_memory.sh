#!/usr/bin/env bash
# STAR session hook (Pi) — print the project's memory index so a session starts
# knowing what earlier sessions in this repository learned.
#
# The store is .star/memory/ in the project, not the harness's own memory: one
# file per fact, with a git-ignored local/ beside it (like .env) holding what
# stays on this machine: the machine: scoped facts, and any memory the user
# keeps off the repository. What is printed is an index built here from each
# file's frontmatter — type, scope, verified, summary — one line per memory,
# newest first: the lines are pointers, and the fact itself is read from its
# file when it matters. What belongs in the store, and the file format, is
# docs/mds/star-workflow/memory_spec.md.
#
# `--list` prints that index as plain text and reads no payload: the form a
# person, a test, or the consistency check calls by hand.
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
list=false
[ "${1:-}" = "--list" ] && list=true

root="$(cd -- "$(dirname -- "$0")/../../.." 2>/dev/null && pwd -P)" || exit 0

# An `env` memory is a fact about a machine, and machines change under it; six
# months is where "recorded" stops implying "still true". The other three types
# do not age this way — a dead end stays dead — and flagging them would teach the
# reader to skip the flag. Both spellings are tried because the flag is BSD's on
# macOS and GNU's on Linux; where neither works, nothing is marked at all.
cutoff="$(date -v-180d +%Y-%m-%d 2>/dev/null || date -d '180 days ago' +%Y-%m-%d 2>/dev/null || true)"

entries() { # $1 = store directory -> one index line per memory file, newest first
    [ -d "$1" ] || return 0
    set -- "$1"/*.md
    [ -f "$1" ] || return 0
    awk -v cutoff="${cutoff}" '
        # A memory is its frontmatter: the line is built from type, scope, verified
        # and summary. A file with no summary is listed by its first body line — the
        # sentence the spec asks the body to open with — so a memory written before
        # the field existed still reaches the session.
        FNR == 1 { if (pending) emit(); cur = FILENAME; infm = 0; pending = 0; split("", f) }
        /^---$/ { if (infm < 2) { infm++; if (infm == 2) { if (f["summary"] != "") emit(); else pending = 1 } }; next }
        infm == 1 && match($0, /^[a-z_]+: */) { f[substr($0, 1, index($0, ":") - 1)] = substr($0, RLENGTH + 1) }
        pending && infm == 2 && NF { f["summary"] = $0; emit(); pending = 0 }
        END { if (pending) emit() }
        function emit(    slug, line) {
            slug = cur; sub(/.*\//, "", slug); sub(/\.md$/, "", slug)
            line = "- " f["type"] " · " f["scope"] " · " f["verified"] " · [" slug "](" slug ".md) — " f["summary"]
            if (f["type"] == "env" && cutoff != "" && f["verified"] < cutoff)
                line = line "  [stale: verify before relying on it]"
            print f["verified"] "\t" line
        }
    ' "$@" | LC_ALL=C sort -r | cut -f2-
}

shared="$(entries "${root}/.star/memory")"
machine="$(entries "${root}/.star/memory/local")"
[ -n "${shared}${machine}" ] || exit 0
if $list; then
    [ -n "${shared}" ] && printf 'Shared (.star/memory/):\n%s\n' "${shared}"
    [ -n "${machine}" ] && printf 'Machine-local (.star/memory/local/):\n%s\n' "${machine}"
    exit 0
fi

printf '%s\n' "STAR project memory — what earlier sessions in this repository learned, recorded under .star/memory/ rather than in your own memory store. Each line is a pointer, not the fact: type · scope · last verified · file — summary. Open the file under .star/memory/ before acting on one. A scope naming a machine or a plan applies only there, and where a memory disagrees with a file in the repository, the file wins. Recording a new one: AGENTS.md section 10."
[ -n "${shared}" ] && printf 'Shared (.star/memory/):\n%s\n' "${shared}"
[ -n "${machine}" ] && printf 'Machine-local (.star/memory/local/):\n%s\n' "${machine}"
exit 0
