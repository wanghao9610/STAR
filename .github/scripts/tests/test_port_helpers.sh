#!/usr/bin/env bash
# New shell helpers are generated as exact relative links.
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
trees=(claude cursor dsh kimi-code pi qwen)
mkdir -p "$fixture/.github/scripts/port" "$fixture/.agents/skills/example/scripts"
for tree in "${trees[@]}"; do printf 'sentinel\tchanged\n' > "$fixture/.github/scripts/port/$tree.rules"; done
printf '#!/bin/bash\nprintf sentinel\n' > "$fixture/.agents/skills/example/scripts/check.sh"
chmod +x "$fixture/.agents/skills/example/scripts/check.sh"
port() { PORT_ROOT="$fixture" perl "$ROOT_DIR/.github/scripts/port/port.pl" "$1" "${trees[@]}" > "$fixture/result"; }
if port check; then echo 'missing helper passed check' >&2; exit 1; fi
port write
for tree in "${trees[@]}"; do
    target="$fixture/.$tree/skills/example/scripts/check.sh"
    [[ -L $target && -x $target ]]
    cmp -s "$target" "$fixture/.agents/skills/example/scripts/check.sh"
done
port check
target="$fixture/.claude/skills/example/scripts/check.sh"
rm "$target"
printf 'wrong\n' > "$target"
if port check; then echo 'drifted helper passed check' >&2; exit 1; fi
port write
port check
echo 'PASS port helpers: create, check and repair'
