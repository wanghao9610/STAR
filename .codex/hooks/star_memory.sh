#!/usr/bin/env bash
# STAR SessionStart hook (Codex CLI) — inject the project's memory index into
# session context so a session starts knowing what earlier sessions in this
# repository learned.
#
# The store is .star/memory/ in the project, not the harness's own memory: one
# file per fact, with a git-ignored local/ beside it (like .env) holding what
# stays on this machine: the machine: scoped facts, and any memory the user
# keeps off the repository. What is injected is an index built here from each
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
# Registered under [hooks.SessionStart] in .codex/hooks.json. Codex accepts the
# same output shape as Claude Code: hookSpecificOutput.additionalContext.

list=false
[ "${1:-}" = "--list" ] && list=true
# The payload is not read, but it is consumed: the runtime writes it to this
# hook's stdin and a hook that never reads leaves that write to fail.
$list || cat >/dev/null 2>&1

# Every harness registers this script by its own path inside the project, so the
# project root is two levels up from the script itself — no environment variable
# and no payload field, which differ per harness.
root="$(cd -- "$(dirname -- "$0")/../.." 2>/dev/null && pwd -P)" || exit 0

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

ctx="STAR project memory — what earlier sessions in this repository learned, recorded under .star/memory/ rather than in your own memory store. Each line is a pointer, not the fact: type · scope · last verified · file — summary. Open the file under .star/memory/ before acting on one. A scope naming a machine or a plan applies only there, and where a memory disagrees with a file in the repository, the file wins. Recording a new one: AGENTS.md section 10."
[ -n "${shared}" ] && ctx="${ctx}
Shared (.star/memory/):
${shared}"
[ -n "${machine}" ] && ctx="${ctx}
Machine-local (.star/memory/local/):
${machine}"

# ctx carries text this repository's own memories wrote, so it is encoded rather
# than assumed quote-free; the last branch sanitizes instead, having no encoder
# to hand, and joins the lines itself because a raw newline is invalid in JSON.
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg c "${ctx}" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
elif command -v python3 >/dev/null 2>&1; then
  python3 -c 'import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))' "${ctx}"
else
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
    "$(printf '%s' "${ctx}" | tr -d '"\\' | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')"
fi
