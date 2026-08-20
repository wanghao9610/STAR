#!/usr/bin/env bash
# Gate one rewrite before it is applied.
#   usage: bash tasks/prose-compression/check_rewrite.sh OLD.txt NEW.txt [--doc]
# Fails loudly if the new text drops a frozen literal the old text carried, or
# introduces a token check 23 bans in a skill tree. --doc also asserts equal line count.
set -uo pipefail
OLD="${1:?old}"; NEW="${2:?new}"; MODE="${3:-}"
rc=0

# 1. frozen literals present in OLD must survive in NEW
while IFS= read -r lit; do
    [[ -n "${lit}" ]] || continue
    if grep -qF -- "${lit}" "${OLD}" && ! grep -qF -- "${lit}" "${NEW}"; then
        echo "DROPPED FROZEN LITERAL: ${lit}"; rc=1
    fi
done <<'LITS'
stay out
stays out
不装载
excerpt
accept that the result is written out
not loaded at runtime
Match the user's language.
Reusing an earlier load.
Shared conventions.
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'
awk '/^## /{k=/^## (
Sub-plans
Revision History
Plan-level finding
[TBD]
【待定】
model_trail:
model_id
LITS

# 2. tokens check 23 bans outside .claude/.kimi-code (a ported passage carries them everywhere)
for t in 'Bash' 'Shell' 'ReadFile'; do
    grep -qE "\\b${t}\\b" "$NEW" && { echo "PORT HAZARD: '${t}' is banned in .agents/.cursor(-partly)/.qwen/.pi/.dsh (check 23)"; rc=1; }
done
grep -qF '`Read`' "$NEW" && { echo "PORT HAZARD: \`Read\` is banned in .agents/.qwen/.pi/.dsh (check 23)"; rc=1; }

# 3. bare §n is a load claim inside the opening-load block (check 20d / 21)
grep -oE '§[0-9]+([^.0-9]|$)' "$NEW" | sed 's/^/  bare section citation: /'

# 4. docs/mds/star-workflow twins are line-aligned (check 17)
if [[ "$MODE" == "--doc" ]]; then
    lo="$(wc -l < "$OLD" | tr -d ' ')"; ln="$(wc -l < "$NEW" | tr -d ' ')"
    [[ "$lo" == "$ln" ]] || { echo "LINE COUNT ${lo} -> ${ln}: the .zh-CN twin must change by the same amount (check 17)"; rc=1; }
fi

ow="$(wc -w < "$OLD" | tr -d ' ')"; nw="$(wc -w < "$NEW" | tr -d ' ')"
oe="$(grep -o '—' "$OLD" | wc -l | tr -d ' ')"; ne="$(grep -o '—' "$NEW" | wc -l | tr -d ' ')"
printf 'words %s -> %s   em-dashes %s -> %s   %s\n' "$ow" "$nw" "$oe" "$ne" "$( (( rc == 0 )) && echo OK || echo BLOCKED )"
exit $rc
