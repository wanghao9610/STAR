#!/usr/bin/env bash
#
# star-flow-status data collector — one digest instead of one read per file.
#
# Deliberately dumb: it globs, greps, and prints. It decides nothing. No glyphs,
# no coverage verdicts, no ordering, no scoping, no knowledge of which filenames
# the registry expects — it prints what is on disk and the skill applies the
# rules. That split is the point: conventions §8 and references/status_spec.md
# stay the single home of every rule, so a producer skill that renames its output
# never has to be mirrored here.
#
# Usage: bash <skill-dir>/scripts/scan.sh    # run from the project root
#
# Reads only. Writes nothing, anywhere.

set -u

FM_CAP=120   # frontmatter lines printed per file before truncation

say() { printf '%s\n' "$*"; }

# Leading --- block, capped. Prints nothing for a file that has no frontmatter
# (CODE_REVIEW, REVIEW, refs_index.md carry a header line instead).
#
# model_trail entries are counted, not printed: the list grows without bound over
# a plan's life and sits above `status:` in the frontmatter, so printing it would
# eventually push the fields this skill actually reads past the cap. No other list
# is dropped — `sources:` in particular is what the stale-method-docs row compares.
frontmatter() {
    awk -v cap="$FM_CAP" '
        function flush_trail() {
            if (trail_open && trailn > 0) print "  … (" trailn " model_trail entries omitted)"
            trail_open = 0; trailn = 0
        }
        NR == 1 { if ($0 !~ /^---[ \t]*$/) exit; next }
        /^---[ \t]*$/ { flush_trail(); exit }
        /^model_trail:/ { flush_trail(); trail_open = 1; n++; print; next }
        trail_open && /^[ \t]/ { trailn++; next }
        trail_open { flush_trail() }
        { n++
          if (n > cap) { print "  … (frontmatter truncated at " cap " lines)"; exit }
          print }
        END { flush_trail() }
    ' "$1"
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
# checkbox items, and strategy-signal notes. Language-agnostic apart from the one
# bilingual token pair, and it keeps prose out of the digest.
body_index() {
    awk '
        /^## / { heading = $0; printed = 0; next }
        heading == "" { next }
        /^\|/ || /^[ \t]*- \[/ || /Strategy signal/ || /战略信号/ {
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

if [ ! -d metds ] && [ ! -d wkdrs ]; then
    say "(no metds/ or wkdrs/ in $(pwd -P) — run this from the project root)"
    exit 0
fi

say "# STAR flow scan — $(pwd -P)"
say "# today: $(date +%Y-%m-%d)"
say "# Raw excerpts only: no status, no glyphs, no coverage verdicts, no ordering,"
say "# no scoping. Apply SKILL.md and references/status_spec.md to what follows."

# ---------------------------------------------------------------- plans
say ""
say "## PLANS — metds/plans/*_plan.md"
plans=0
for f in metds/plans/*_plan.md; do
    [ -f "$f" ] || continue
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
done
[ "$plans" -gt 0 ] || say "(none)"

# ---------------------------------------------------------------- runs
say ""
say "## RUNS — wkdrs/*/EXEC_LOG.md"
runs=0
for f in wkdrs/*/EXEC_LOG.md; do
    [ -f "$f" ] || continue
    runs=$(( runs + 1 ))
    say ""
    say "=== $f"
    say "[frontmatter]"
    frontmatter "$f"
    say "[body: headings with their table rows, checkboxes, and signals]"
    body_index "$f"
    say "[dates seen] $(dates_seen "$f")"
done
[ "$runs" -gt 0 ] || say "(none)"

# ---------------------------------------------------------------- other artifacts
# Every other registered-area .md, one depth level down as the self-audit rule
# defines it: metds/, its ideas dir, and each wkdrs/<dir>/. Frontmatter only —
# the state field each row of the registry needs lives there. metds/refs/ is
# listed but not dumped: it is checked for the index's presence, and a project
# with fifty paper notes would otherwise drown the digest.
say ""
say "## ARTIFACT FRONTMATTER — everything else, depth 1"
others=0
for f in metds/*.md metds/ideas/*.md wkdrs/*/*.md; do
    [ -f "$f" ] || continue
    case "$f" in
        metds/plans/*|*/EXEC_LOG.md) continue ;;
    esac
    fm=$(frontmatter "$f")
    [ -n "$fm" ] || continue
    others=$(( others + 1 ))
    say ""
    say "=== $f"
    printf '%s\n' "$fm"
done
[ "$others" -gt 0 ] || say "(none with frontmatter)"

# ---------------------------------------------------------------- listing
# Presence and filename dates for the coverage band, and the raw material for the
# self-audit line. Depth 1 only: producers' working subdirs are not registered.
say ""
say "## LISTING — registered areas, depth 1, *.md"
listing=$(ls -d metds/*.md metds/ideas/*.md metds/refs/*.md metds/plans/*.md \
                wkdrs/*.md wkdrs/*/*.md 2>/dev/null | sort)
if [ -n "$listing" ]; then
    printf '%s\n' "$listing"
else
    say "(none)"
fi

say ""
say "## DIRS — metds/ and wkdrs/ subdirectories"
dirs=$(ls -d metds/*/ wkdrs/*/ 2>/dev/null | sort)
if [ -n "$dirs" ]; then
    printf '%s\n' "$dirs"
else
    say "(none)"
fi
