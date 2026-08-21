#!/usr/bin/env bash
# Re-apply the nine override records that hold a difference no harness asked for.
# See PROPOSAL.md section 6 for what each one is and why it goes.
#
# Run from the project root, on a clean working tree — port.sh --write rewrites
# every tree, so another session's in-flight edits would be caught up in it.
#
#   bash tasks/tree-dedup/replay.sh
#
# Verified once already: port.sh check goes green and check_consistency.sh passes
# all sections. It was reverted by a concurrent session, not by a failure.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "${ROOT}"
DROP="perl tasks/tree-dedup/drop_records.pl"

# Refuse to run on top of someone else's uncommitted work in the trees: this
# script's own check would then be reporting on their edits, not on these nine.
if ! git diff --quiet -- .agents .claude .cursor .dsh .kimi-code .pi .qwen .github/scripts/port; then
    echo "the skill trees or the port rules carry uncommitted changes — commit or stash them first" >&2
    exit 1
fi

# 1. The neutral tree spells one word limit out and leaves 81 others as ≤.
#    Dropping these two makes score_spec identical in all seven trees.
${DROP} .github/scripts/port/agents.overrides \
    'star-refs-reviewer/references/score_spec.md::4. Digest ' \
    'star-refs-reviewer/references/score_spec_zh.md::4. 摘要 '

# 2 and 3. extract_map: one clause reordered around its own "or the reverse",
#    and two spans that only rejoin the source's hard-wrapped lines.
for tree in agents cursor pi; do
    ${DROP} ".github/scripts/port/${tree}.overrides" \
        'star-metd-summarize/references/extract_map.md::5. **Provenance travels with every passage**'
done
for tree in cursor pi; do
    ${DROP} ".github/scripts/port/${tree}.overrides" \
        'star-metd-summarize/references/extract_map.md::`target:` is required because a collector' \
        'star-metd-summarize/references/extract_map.md::`unread` is not a gap.'
done

bash .github/scripts/port.sh --write
bash .github/scripts/port.sh
echo
echo "now run: bash .github/scripts/check_consistency.sh"
