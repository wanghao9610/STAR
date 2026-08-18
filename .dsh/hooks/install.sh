#!/usr/bin/env bash
# Register STAR's DSH hooks in DeepSeek Harness's GLOBAL composition; running it again changes nothing.
#
# Three hooks: model_id provenance, the project-memory index injected from
# .star/memory/, and the commit guard that declines the git commands the workflow
# conventions §1 forbid. The first two inject context on SessionStart; the guard
# decides instead, so it registers on PreToolUse matching DSH's `bash` tool.
#
# DSH reads no plugin configuration out of a project, so the row that loads the
# hook bridge has to live in the machine's own $DSH_HOME/cordis.patch.yml
# (default ~/.dsh/cordis.patch.yml), which every profile applies. This is
# one-time-per-machine setup: the bridge's configPath is relative and resolves
# against the directory dsh was launched in, so that one row then covers every
# STAR project with no per-project editing, and a project without .dsh/hooks.json
# registers nothing.
#
# Safe to re-run: the row is added only when it is not there already, the file is
# backed up before its first modification, and the row is appended as a new patch
# operation rather than rewriting anything.
#
# It installs no packages. The bridge is not a dsh dependency, so this script
# reports which of your profiles still need it and prints the command; running
# pnpm inside your profiles is yours to approve, not a side effect of this.
set -euo pipefail

home="${DSH_HOME:-$HOME/.dsh}"
patch="${home}/cordis.patch.yml"
bridge='@deepseek-ai/dsh-hooks-claude-code'
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Make sure this repo's hook scripts are executable.
for script in star_model_id.sh star_memory.sh star_commit_guard.sh; do
  [ -f "${here}/${script}" ] && chmod +x "${here}/${script}" 2>/dev/null || true
done

mkdir -p "${home}"
[ -f "${patch}" ] || : > "${patch}"

if grep -qF "${bridge}" "${patch}" 2>/dev/null; then
  echo "The hook bridge is already registered in ${patch} — left alone."
else
  cp "${patch}" "${patch}.star-bak"
  {
    printf '\n# --- STAR hooks (added by .dsh/hooks/install.sh) ---\n'
    printf '# configPath is relative on purpose: it resolves against the directory dsh was\n'
    printf '# launched in, so this one row serves every STAR project. A project without the\n'
    printf '# file registers nothing. See <project>/.dsh/cordis.patch.yml for the full note.\n'
    printf -- '- insert:\n'
    printf '    - id: star-hooks\n'
    printf "      name: '%s'\n" "${bridge}"
    printf '      config:\n'
    printf '        configPath: ./.dsh/hooks.json\n'
  } >> "${patch}"
  echo "Registered the STAR hook bridge in ${patch}"
  echo "  backup written to ${patch}.star-bak"
  echo "  it now applies in every STAR project you launch dsh from — no per-project setup."
fi

# The row names a package that has to resolve from the profile that loads it.
# A profile missing it fails the row at boot, which is worth naming here rather
# than leaving to a startup error.
needs=()
if [ -d "${home}/profiles" ]; then
  for dir in "${home}"/profiles/*/; do
    [ -d "${dir}" ] || continue
    name="$(basename "${dir}")"
    [ "${name}" = "node_modules" ] && continue
    [ -d "${dir}node_modules/${bridge}" ] || needs+=("${name}")
  done
fi

echo
if (( ${#needs[@]} == 0 )) && [ -d "${home}/profiles" ]; then
  echo "Every profile already carries ${bridge}."
else
  echo "Add the bridge to each profile you use — it is not a dsh dependency:"
  if (( ${#needs[@]} > 0 )); then
    for name in "${needs[@]}"; do
      printf '  dsh plugin --profile %s add %s\n' "${name}" "${bridge}"
    done
  else
    printf '  dsh plugin --profile <name> add %s\n' "${bridge}"
  fi
fi
echo
echo "Then check the composed tree without booting it:"
echo "  dsh --profile <name> --dump-config"
