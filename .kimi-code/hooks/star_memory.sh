#!/usr/bin/env bash
# STAR UserPromptSubmit hook (Kimi Code) — inject the project's memory index into
# context once per session, so a session starts knowing what earlier sessions in
# this repository learned.
#
# The store is .star/memory/ in the project, not the harness's own memory: one
# file per fact, listed one line each in MEMORY.md, with machine-specific facts
# under local/ (git-ignored, like .env). Only the index is injected — the lines
# are pointers, and the fact itself is read from its file when it matters. What
# belongs in the store, and the format of both, is docs/mds/star-workflow/memory_spec.md.
#
# Why UserPromptSubmit and not SessionStart: in Kimi, SessionStart is
# observation-only (fire-and-forget) and cannot inject context. UserPromptSubmit
# is the only context-injecting event — on exit 0 its stdout is appended to
# context. We fire once per session by keying a marker file on the payload's
# session_id, so it does not repeat every turn.
#
# Registration: Kimi does not auto-load project config, so add the [[hooks]]
# block from .kimi-code/hooks.example.toml to your global config at
# $KIMI_CODE_HOME/config.toml (default ~/.kimi-code/config.toml), or run
# .kimi-code/hooks/install.sh once, which registers both STAR hooks for you.

input=$(cat)

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
    # Entry lines live outside the fenced block that documents their format.
    /^```/ { infence = !infence; next }
    !infence && /^- / {
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
# Nothing to say — and no marker written, so the first memory recorded later in
# this session is still injected on the next prompt.
[ -n "${shared}${machine}" ] || exit 0

# --- session_id, for once-per-session dedup ---
if command -v jq >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("session_id") or "")
except Exception:
    print("")' 2>/dev/null)
else
  sid=$(printf '%s' "$input" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
fi

# Dedup only when we actually have a session id. Without one, every session would
# share a single marker: the first would create it and every later one would exit
# silently, which is indistinguishable from healthy dedup and leaves the memory
# index permanently uninjected. Injecting once per turn is noisier than intended
# but always correct, so that is the safer failure.
if [ -n "${sid}" ]; then
  marker="${TMPDIR:-/tmp}/star_kimi_memory_${sid}"
  [ -e "$marker" ] && exit 0
  : > "$marker" 2>/dev/null || true
fi

printf '%s\n' "STAR project memory — what earlier sessions in this repository learned, recorded under .star/memory/ rather than in your own memory store. Each line is a pointer, not the fact: type · scope · last verified · file — summary. Open the file under .star/memory/ before acting on one. A scope naming a machine or a plan applies only there, and where a memory disagrees with a file in the repository, the file wins. Recording a new one: AGENTS.md section 10."
[ -n "${shared}" ] && printf 'Shared (.star/memory/):\n%s\n' "${shared}"
[ -n "${machine}" ] && printf 'Machine-local (.star/memory/local/):\n%s\n' "${machine}"
exit 0
