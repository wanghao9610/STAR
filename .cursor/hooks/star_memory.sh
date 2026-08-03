#!/usr/bin/env bash
# STAR sessionStart hook (Cursor) — inject the project's memory index into
# session context so a session starts knowing what earlier sessions in this
# repository learned.
#
# The store is .star/memory/ in the project, not the harness's own memory: one
# file per fact, listed one line each in MEMORY.md, with machine-specific facts
# under local/ (git-ignored, like .env). Only the index is injected — the lines
# are pointers, and the fact itself is read from its file when it matters. What
# belongs in the store, and the format of both, is docs/mds/star-workflow/memory_spec.md.
#
# Nothing is printed when the store holds no entries, so a fresh project pays
# nothing: the rule that creates the first memory is AGENTS.md section 10, which
# is loaded anyway.
#
# Registered under hooks.sessionStart in .cursor/hooks.json. Cursor injects the
# returned `additional_context` string into the conversation.

# The payload is not read, but it is consumed: the runtime writes it to this
# hook's stdin and a hook that never reads leaves that write to fail.
cat >/dev/null 2>&1

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
  jq -cn --arg c "${ctx}" '{additional_context: $c}'
elif command -v python3 >/dev/null 2>&1; then
  python3 -c 'import sys, json
print(json.dumps({"additional_context": sys.argv[1]}))' "${ctx}"
else
  printf '{"additional_context":"%s"}\n' \
    "$(printf '%s' "${ctx}" | tr -d '"\\' | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')"
fi
