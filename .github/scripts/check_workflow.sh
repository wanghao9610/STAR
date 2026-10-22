#!/usr/bin/env bash
# Offline workflow-state regressions with shell tools only.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
for tool in bash awk jq git perl; do
    command -v "$tool" >/dev/null 2>&1 || { printf 'Required test tool missing: %s\n' "$tool" >&2; exit 1; }
done
for suite in "${ROOT_DIR}"/.github/scripts/tests/test_*.sh; do
    [[ -f "$suite" ]] || continue
    bash "$suite"
done
