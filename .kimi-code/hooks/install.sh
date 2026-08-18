#!/usr/bin/env bash
# Register STAR's Kimi hooks in Kimi's GLOBAL config; running it again changes nothing.
#
# Three hooks: model_id provenance, the project-memory index injected from
# .star/memory/, and the commit guard that declines the git commands the workflow
# conventions §1 forbid. The first two inject context on UserPromptSubmit; the
# guard decides instead, so it registers on PreToolUse matching Bash.
#
# Kimi has no project-level hook config, so the [[hooks]] entries must live in
# the global config at $KIMI_CODE_HOME/config.toml (default ~/.kimi-code/config.toml).
# This is one-time-per-machine setup: because the command paths are relative and
# Kimi runs hooks from the project root, those entries then cover every STAR
# project with no per-project editing.
#
# Safe to re-run: each hook is registered only when it is not there already, so a
# machine set up before the memory hook existed gains just that one. It backs the
# config up before its first modification, and appends new [[hooks]] table arrays
# (valid TOML) rather than rewriting anything.
set -euo pipefail

cfg="${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
# script | label | event | matcher (empty matcher = every occurrence)
hooks=("star_model_id.sh|STAR model_id provenance hook|UserPromptSubmit|"
       "star_memory.sh|STAR project-memory hook|UserPromptSubmit|"
       "star_commit_guard.sh|STAR commit guard|PreToolUse|Bash")

# Make sure this repo's hook scripts are executable.
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
for row in "${hooks[@]}"; do
  script="${row%%|*}"
  [ -f "$here/${script}" ] && chmod +x "$here/${script}" 2>/dev/null || true
done

mkdir -p "$(dirname "$cfg")"
[ -f "$cfg" ] || : > "$cfg"

backed_up=false
added=0
for row in "${hooks[@]}"; do
  IFS='|' read -r script label event matcher <<< "$row"

  if grep -qF "${script}" "$cfg" 2>/dev/null; then
    echo "${label} already registered in $cfg — skipped."
    continue
  fi

  if [ "$backed_up" = false ]; then
    cp "$cfg" "$cfg.star-bak"
    backed_up=true
  fi

  {
    printf '\n# --- %s (added by .kimi-code/hooks/install.sh) ---\n' "${label}"
    printf '[[hooks]]\n'
    printf 'event = "%s"\n' "${event}"
    if [ -n "${matcher}" ]; then printf 'matcher = "%s"\n' "${matcher}"; fi
    printf 'command = ".kimi-code/hooks/%s"\n' "${script}"
    printf 'timeout = 10\n'
  } >> "$cfg"

  echo "Registered ${label} in $cfg"
  added=$(( added + 1 ))
done

if (( added == 0 )); then
  echo "Nothing to do — all three STAR hooks were already registered."
  exit 0
fi

echo "  backup written to $cfg.star-bak"
echo "  they now run in every STAR project — no per-project setup needed."
