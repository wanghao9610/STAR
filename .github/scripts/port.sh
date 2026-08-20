#!/usr/bin/env bash
# Generate the seven skill trees from the one authored copy in .claude/skills.
#
#   bash .github/scripts/port.sh              # check: every tree still matches what
#                                             # .claude plus the rules would produce
#   bash .github/scripts/port.sh --write      # write the generated bodies into the trees
#   bash .github/scripts/port.sh --regen      # re-record the overrides from the trees
#   bash .github/scripts/port.sh --tree pi …  # one tree (repeatable), any mode
#
# The seven trees ship the same fifteen skills to seven agent harnesses, and each
# harness names its own terminal, file reader, question tool and sub-agent. That
# made every wording change a seven-times edit that nothing checked: a sentence
# reworded in six trees and missed in the seventh drew no error, because no file
# ever claimed to be a copy of another. This says so, and proves it.
#
# Two inputs per tree, in .github/scripts/port/:
#   <tree>.rules      ordered `pattern<TAB>replacement`, that harness's vocabulary
#   <tree>.overrides  every span the vocabulary cannot reach — i.e. every place the
#                     tree genuinely says something else, anchored by the source
#                     lines themselves
#
# A file the trees do not word differently at all — a rubric, a template, a scan
# script — is stored once, in .agents/skills, and every other tree carries a
# relative symlink at the same path. Nothing lists which files those are: a tree
# links a file when its generated text and .agents' come out the same, and holds
# its own file when they do not, decided again on every run. Downstream projects
# never see the links; execs/update.sh resolves them as it copies, so an
# installed tree is real files, self-contained, exactly as before.
#
# Frontmatter is not generated. Each harness tunes its own `description` to its own
# length limit and trigger wording; check_consistency.sh holds those invariants.
# Everything below the closing `---` is generated.
#
# --regen accepts the trees as they stand and rewrites the override files to match.
# It is the deliberate move after porting a passage by hand — never the way to make
# a red check go green, which is what makes a failing --check meaningful.
set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MODE="check"
TREES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check) MODE="check"; shift ;;
        --write) MODE="write"; shift ;;
        --regen) MODE="regen"; shift ;;
        --tree)  TREES+=("${2#.}"); shift 2 ;;
        -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "port.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
# .claude is in the list for its links alone: it is the source, so its own bodies
# are what they are, but a file it shares with .agents lives there like any other
# tree's.
[[ ${#TREES[@]} -gt 0 ]] || TREES=(agents claude cursor dsh kimi-code pi qwen)

command -v perl >/dev/null 2>&1 || { echo "port.sh: perl not found" >&2; exit 2; }

echo "port: ${MODE} — .claude/skills -> ${#TREES[@]} tree(s), shared files in .agents/skills"
PORT_ROOT="${ROOT_DIR}" perl "${ROOT_DIR}/.github/scripts/port/port.pl" "${MODE}" "${TREES[@]}"
rc=$?

if [[ "${MODE}" == "check" ]]; then
    if [[ ${rc} -eq 0 ]]; then
        echo "ok  every tree is what .claude/skills plus its own vocabulary produces, and every file it does not word differently is a link into .agents/skills"
    else
        cat <<'MSG'

A tree no longer matches. Either the tree was edited directly — port the change to
.claude/skills instead and re-run --write — or a .claude line an override is
anchored on was reworded, in which case that tree's own wording of it needs the
same edit: fix it in <tree>.overrides, then --regen.

A file reported as one that must be a link, or as a link that is no longer shared,
needs neither: the wording moved it across the line and --write puts it on the
right side.
MSG
    fi
fi
exit ${rc}
