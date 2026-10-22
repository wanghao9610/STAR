#!/usr/bin/env bash
# Discovery needs no runtime; an experiment runs only when explicitly named.
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
fixture="$(mktemp -d)"
fixture="$(cd "$fixture" && pwd -P)"
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/execs/scpts"
cp "$ROOT_DIR/execs/run.sh" "$fixture/execs/run.sh"
: > "$fixture/execs/scpts/.gitkeep"
fail() { printf 'FAIL launcher: %s\n' "$*" >&2; exit 1; }

output=$(bash "$fixture/execs/run.sh")
[[ $output == *'Usage:'* && $output == *'No experiment scripts found'* ]] || fail 'empty project discovery'

cat > "$fixture/execs/scpts/baseline.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$ROOT_DIR" "$PYTHON_BIN" "$@" > "$WORK_DIR/launched.txt"
EOF
# An invalid .env must not be read by discovery commands.
printf 'exit 97\n' > "$fixture/.env"
for option in '' --help --list; do
    if [[ -n $option ]]; then output=$(bash "$fixture/execs/run.sh" "$option")
    else output=$(bash "$fixture/execs/run.sh"); fi
    [[ ! -e "$fixture/wkdrs/launched.txt" ]] || fail 'discovery launched an experiment'
    [[ $option == --help || $output == *baseline* ]] || fail 'discovery omitted named experiment'
done
[[ $(bash "$fixture/execs/run.sh" --list) == baseline ]] || fail 'list included directory placeholder'

mkdir -p "$fixture/code" "$fixture/wkdrs" "$fixture/runtime/bin"
printf '#!/bin/sh\nexit 98\n' > "$fixture/runtime/bin/python"
chmod +x "$fixture/runtime/bin/python"
printf 'CODE_NAME=code\nPYTHON_HOME="%s/runtime"\nCONDA_HOME=\nENV_NAME=\n' "$fixture" > "$fixture/.env"
bash "$fixture/execs/run.sh" baseline --config 'config with spaces.yaml' 'literal $(false)' >/dev/null
# The expected argument deliberately contains literal shell metacharacters.
# shellcheck disable=SC2016
printf '%s\n' "$fixture" "$fixture/runtime/bin/python" --config 'config with spaces.yaml' 'literal $(false)' > "$fixture/expected"
cmp -s "$fixture/expected" "$fixture/wkdrs/launched.txt" || fail 'named experiment arguments or environment changed'

if bash "$fixture/execs/run.sh" missing > "$fixture/error" 2>&1; then fail 'missing experiment accepted'; fi
grep -Fq 'Experiment script not found: missing.sh' "$fixture/error" || fail 'missing experiment diagnostic'
echo 'PASS launcher: empty/discovery paths, explicit selection, argument forwarding and missing-name handling'
