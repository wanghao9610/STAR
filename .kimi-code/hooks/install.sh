#!/usr/bin/env bash
# Register the STAR model_id hook in Kimi's GLOBAL config, idempotently.
#
# Kimi has no project-level hook config, so the [[hooks]] entry must live in the
# global config at $KIMI_CODE_HOME/config.toml (default ~/.kimi-code/config.toml).
# This is one-time-per-machine setup: because the command path is relative and
# Kimi runs hooks from the project root, the single entry then covers every STAR
# project with no per-project editing.
#
# Safe to re-run: it detects an existing registration and does nothing. It backs
# the config up before its first modification, and appends a new [[hooks]] table
# array (valid TOML) rather than rewriting anything.
set -euo pipefail

cfg="${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
hook_cmd=".kimi-code/hooks/star_model_id.sh"

# Make sure this repo's hook script is executable.
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[ -f "$here/star_model_id.sh" ] && chmod +x "$here/star_model_id.sh" 2>/dev/null || true

mkdir -p "$(dirname "$cfg")"
[ -f "$cfg" ] || : > "$cfg"

if grep -q 'star_model_id\.sh' "$cfg" 2>/dev/null; then
  echo "STAR model_id hook already registered in $cfg — nothing to do."
  exit 0
fi

cp "$cfg" "$cfg.star-bak"

{
  printf '\n# --- STAR model_id provenance hook (added by .kimi-code/hooks/install.sh) ---\n'
  printf '[[hooks]]\n'
  printf 'event = "UserPromptSubmit"\n'
  printf 'command = "%s"\n' "$hook_cmd"
  printf 'timeout = 10\n'
} >> "$cfg"

echo "Registered the STAR model_id hook in $cfg"
echo "  backup written to $cfg.star-bak"
echo "  it now runs in every STAR project — no per-project setup needed."
