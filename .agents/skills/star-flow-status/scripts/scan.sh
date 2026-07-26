#!/usr/bin/env bash
#
# STAR flow data collector — one digest instead of one read per file.
#
# Shared by the skills that open the same plans, run logs, and registered
# artifacts before doing anything else. Every copy is byte-identical and CI
# enforces that; it names no harness and no skill, so there is nothing to adapt
# per tree.
#
# Deliberately dumb: it globs, greps, and prints. It decides nothing. No glyphs,
# no coverage verdicts, no ordering, no scoping, no knowledge of which filenames
# the registry expects — it prints what is on disk and the skill applies the
# rules. That split is the point: conventions §8 and each skill's own spec stay
# the single home of every rule, so a producer skill that renames its output
# never has to be mirrored here.
#
# Usage: bash <skill-dir>/scripts/scan.sh [--trails]   # run from the project root
#
#   --trails   provenance mode: print every model_trail entry in full rather
#              than counting it, add each plan's ## Revision History and the
#              model_id header line of files that carry no frontmatter, and
#              widen the sweep to metds/refs/. This is what a cross-artifact
#              provenance ledger reads; the default mode drops all of it because
#              an unbounded trail would crowd out the fields everything else needs.
#
# Reads only. Writes nothing, anywhere.

set -u

TRAILS=0
case "${1:-}" in
    "") ;;
    --trails) TRAILS=1 ;;
    *) printf 'usage: scan.sh [--trails]\n' >&2; exit 2 ;;
esac

FM_CAP=120   # frontmatter lines printed per file before truncation
[ "$TRAILS" = 0 ] || FM_CAP=500

say() { printf '%s\n' "$*"; }

# Leading --- block, capped. Prints nothing for a file that has no frontmatter
# (CODE_REVIEW, REVIEW, refs_index.md carry a header line instead).
#
# Without --trails, model_trail entries are counted rather than printed: the list
# grows without bound over a plan's life and sits above `status:`, so printing it
# would eventually push the fields the readers actually need past the cap. No
# other list is dropped — `sources:` in particular is what a stale-document check
# compares against.
frontmatter() {
    awk -v cap="$FM_CAP" -v trails="$TRAILS" '
        function flush_trail() {
            if (trail_open && trailn > 0) print "  … (" trailn " model_trail entries omitted)"
            trail_open = 0; trailn = 0
        }
        NR == 1 { if ($0 !~ /^---[ \t]*$/) exit; next }
        /^---[ \t]*$/ { flush_trail(); exit }
        trails == 0 && /^model_trail:/ { flush_trail(); trail_open = 1; n++; print; next }
        trails == 0 && trail_open && /^[ \t]/ { trailn++; next }
        trails == 0 && trail_open { flush_trail() }
        { n++
          if (n > cap) { print "  … (frontmatter truncated at " cap " lines)"; exit }
          print }
        END { flush_trail() }
    ' "$1"
}

# Provenance carried on a header line instead of in frontmatter.
header_model() {
    awk 'NR > 10 { exit } /model_id/ { print }' "$1"
}

# A "## <heading>" section body, up to the next "## ".
section_body() {
    awk -v pat="$2" '
        $0 ~ pat { inside = 1; next }
        inside && /^## / { exit }
        inside { print }
    ' "$1"
}

# Structured lines only, each under the "## " heading it sits below: table rows,
# checkbox items, and plan-level-finding notes. Language-agnostic apart from the
# bilingual token pairs (the current labels plus the pre-rename ones, so
# EXEC_LOG.md files already on disk still index), and it keeps prose out of the digest.
body_index() {
    awk '
        /^## / { heading = $0; printed = 0; next }
        heading == "" { next }
        /^\|/ || /^[ \t]*- \[/ || /Plan-level finding/ || /方向性信号/ || /Strategy signal/ || /战略信号/ {
            if (!printed && heading != "") { print heading; printed = 1 }
            print
        }
    ' "$1"
}

# How much of §3 and §5 is still [TBD] — the input to the "too coarse" rule.
# Content lines exclude blanks and HTML-comment template guidance.
tbd_counts() {
    awk '
        /^## +3\./ { sec = 3; next }
        /^## +5\./ { sec = 5; next }
        /^## / { sec = 0; next }
        sec == 0 { next }
        /<!--/ { incomment = 1 }
        { was = incomment }
        /-->/ { incomment = 0 }
        was { next }
        NF == 0 { next }
        { content[sec]++; if (index($0, "[TBD]")) tbd[sec]++ }
        END { printf "[tbd] §3: %d TBD / %d content lines | §5: %d TBD / %d content lines\n",
                     tbd[3]+0, content[3]+0, tbd[5]+0, content[5]+0 }
    ' "$1"
}

dates_seen() {
    grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' "$1" | sort -u | tr '\n' ' '
}

# File selection never goes through a shell glob. An unmatched pattern is a fatal
# error in zsh and expands to itself in POSIX sh, and either one would quietly
# corrupt the digest — a missing wkdrs/*.md took the whole listing with it. find
# behaves the same under every shell, and sorting its output makes the digest
# byte-identical whatever the caller ran it with.
find_md() {   # $1 = dir, $2 = exact depth below it, $3 = name pattern
    [ -d "$1" ] || return 0
    find "$1" -mindepth "$2" -maxdepth "$2" -type f -name "$3" 2>/dev/null | sort
}

find_dirs() { # $1 = dir; immediate subdirectories, trailing slash kept
    [ -d "$1" ] || return 0
    find "$1" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|$|/|' | sort
}

if [ ! -d metds ] && [ ! -d wkdrs ]; then
    say "(no metds/ or wkdrs/ in $(pwd -P) — run this from the project root)"
    exit 0
fi

say "# STAR flow scan — $(pwd -P)"
say "# today: $(date +%Y-%m-%d)"
[ "$TRAILS" = 0 ] || say "# mode: --trails (provenance)"
say "# Raw excerpts only: no status, no glyphs, no verdicts, no ordering, no scoping."
say "# Apply your skill's own rules to what follows."

# ---------------------------------------------------------------- plans
say ""
say "## PLANS — metds/plans/*_plan.md"
plans=0
while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    plans=$(( plans + 1 ))
    say ""
    say "=== $f"
    say "[frontmatter]"
    frontmatter "$f"
    index=$(section_body "$f" '^##[ \t]*Sub-plans')
    if [ -n "$index" ]; then
        say "[sub-plans index]"
        printf '%s\n' "$index" | grep -v '^[ \t]*$'
    fi
    # The one body fact the coverage band needs: an idea file named anywhere in
    # the plan, since the coach records its seed as prose rather than a field.
    seeds=$(grep -o '[A-Za-z0-9._-]*_idea\.md' "$f" | sort -u | tr '\n' ' ')
    [ -z "$seeds" ] || say "[idea refs] $seeds"
    tbd_counts "$f"
    if [ "$TRAILS" = 1 ]; then
        # Not named `history`: that is a special array in zsh, and assigning to it
        # aborts the loop there while working fine everywhere else.
        revisions=$(section_body "$f" '^##[ \t]*Revision History')
        if [ -n "$revisions" ]; then
            say "[revision history]"
            printf '%s\n' "$revisions" | grep -v '^[ \t]*$'
        fi
    fi
done <<PLANS
$(find_md metds/plans 1 '*_plan.md')
PLANS
[ "$plans" -gt 0 ] || say "(none)"

# ---------------------------------------------------------------- runs
say ""
say "## RUNS — wkdrs/*/EXEC_LOG.md"
runs=0
while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    runs=$(( runs + 1 ))
    say ""
    say "=== $f"
    say "[frontmatter]"
    frontmatter "$f"
    say "[body: headings with their table rows, checkboxes, and signals]"
    body_index "$f"
    say "[dates seen] $(dates_seen "$f")"
done <<RUNS
$(find_md wkdrs 2 'EXEC_LOG.md')
RUNS
[ "$runs" -gt 0 ] || say "(none)"

# ---------------------------------------------------------------- other artifacts
# Every other registered-area .md, one depth level down as the self-audit rule
# defines it: metds/, its ideas dir, and each wkdrs/<dir>/. Frontmatter only —
# the state field each row of the registry needs lives there. metds/refs/ is
# listed but not dumped by default: it is checked for the index's presence, and a
# project with fifty paper notes would otherwise drown the digest — --trails
# widens to it, because a provenance ledger does want every note's writer.
say ""
say "## ARTIFACT FRONTMATTER — everything else, depth 1"
artifact_files() {
    find_md metds 1 '*.md'
    find_md metds/ideas 1 '*.md'
    find_md wkdrs 2 '*.md'
    [ "$TRAILS" = 0 ] || find_md metds/refs 1 '*.md'
}
others=0
while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    case "$f" in
        */EXEC_LOG.md) continue ;;
    esac
    fm=$(frontmatter "$f")
    if [ -z "$fm" ]; then
        # No frontmatter. In provenance mode its header line may still name a writer.
        [ "$TRAILS" = 1 ] || continue
        fm=$(header_model "$f")
        [ -n "$fm" ] || continue
    fi
    others=$(( others + 1 ))
    say ""
    say "=== $f"
    printf '%s\n' "$fm"
done <<ARTIFACTS
$(artifact_files)
ARTIFACTS
[ "$others" -gt 0 ] || say "(none with frontmatter)"

# ---------------------------------------------------------------- listing
# Presence and filename dates for the coverage band, and the raw material for the
# self-audit line. Depth 1 only: producers' working subdirs are not registered.
say ""
say "## LISTING — registered areas, depth 1, *.md"
listing=$(
    find_md metds 1 '*.md'
    find_md metds/ideas 1 '*.md'
    find_md metds/refs 1 '*.md'
    find_md metds/plans 1 '*.md'
    find_md wkdrs 1 '*.md'
    find_md wkdrs 2 '*.md'
)
if [ -n "$listing" ]; then
    printf '%s\n' "$listing" | sort
else
    say "(none)"
fi

say ""
say "## DIRS — metds/ and wkdrs/ subdirectories"
dirs=$(find_dirs metds; find_dirs wkdrs)
if [ -n "$dirs" ]; then
    printf '%s\n' "$dirs" | sort
else
    say "(none)"
fi
