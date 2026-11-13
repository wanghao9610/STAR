#!/usr/bin/env bash
# Offline workflow-state regressions with shell tools only.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
for tool in bash awk git perl; do
    command -v "$tool" >/dev/null 2>&1 || { printf 'Required test tool missing: %s\n' "$tool" >&2; exit 1; }
done
# Fail if a regression or runtime helper tries to use the removed dependency.
probe=$(mktemp -d "${TMPDIR:-/tmp}/star-no-jq.XXXXXX")
trap 'rm -rf -- "$probe"' EXIT
export STAR_JQ_PROBE_LOG="$probe/invoked"
cat > "$probe/jq" <<'BLOCK'
#!/bin/sh
printf '%s\n' "$*" >> "$STAR_JQ_PROBE_LOG"
exit 97
BLOCK
chmod +x "$probe/jq"
export PATH="$probe:$PATH"
for suite in "${ROOT_DIR}"/.github/scripts/tests/test_*.sh; do
    [[ -f "$suite" ]] || continue
    bash "$suite"
done
[[ ! -e "$STAR_JQ_PROBE_LOG" ]] || { printf 'Unexpected jq invocation\n' >&2; exit 1; }
printf 'PASS: shell suites ran without jq\n'
