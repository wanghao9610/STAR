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
# Usage: bash <skill-dir>/scripts/scan.sh [--trails] [--bodies N,N] [--runs DIR,DIR]
#        # run from the project root
#
#   --trails      provenance mode: print every model_trail entry in full rather
#                 than counting it, add each plan's ## Revision History and the
#                 model_id header line of files that carry no frontmatter, and
#                 widen the sweep to metds/refs/. This is what a cross-artifact
#                 provenance ledger reads; the default mode drops all of it because
#                 an unbounded trail would crowd out the fields everything else needs.
#                 It also drops what a provenance read has no use for: the sub-plans
#                 index, the placeholder counts, the per-run dates line, and DIRS.
#                 model_trail itself is never capped — printing every entry is the
#                 whole point of the mode, and a ledger with a hole in it is worse
#                 than a long one.
#
#   --bodies N,N  for each depth-2 wkdrs artifact, also print the body of the
#                 "## <N>." sections named, capped. The caller names the numbers:
#                 which sections carry the facts is the reading skill's rule, not
#                 this script's, so a producer that renumbers its report is a
#                 one-line change in that skill and nothing here. Without this the
#                 depth-2 sweep stays frontmatter-only, as before.
#
#   --runs DIR,DIR  restrict the per-run body index and dates line, and any
#                 --bodies sections, to these run directories. Frontmatter is still
#                 printed for every run and every artifact, and PLANS, LISTING and
#                 DIRS stay project-wide: a subtree question still needs every
#                 plan's parent:, and the drift check counts report-shaped files
#                 across the whole project. A run outside the scope is named as
#                 omitted, never dropped silently. Pair it with --bodies whenever
#                 the caller has already decided which runs it is reading: without
#                 it, --bodies prints every report in the project's history.
#
# Reads only. Writes nothing, anywhere.

set -u

TRAILS=0
BODY_SECTIONS=""
RUNS_SCOPE=""
usage() { printf 'usage: scan.sh [--trails] [--bodies N,N] [--runs DIR,DIR]\n' >&2; exit 2; }
while [ $# -gt 0 ]; do
    case "$1" in
        --trails) TRAILS=1 ;;
        --bodies) [ $# -ge 2 ] || usage; BODY_SECTIONS="$2"; shift ;;
        --runs)   [ $# -ge 2 ] || usage; RUNS_SCOPE="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

FM_CAP=120   # frontmatter lines printed per file before truncation
[ "$TRAILS" = 0 ] || FM_CAP=500
BODY_CAP=60  # lines printed per --bodies section before truncation

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

# How much of §3 and §5 is still a placeholder — the input to the "too coarse" rule.
# Both markers count: star-plan-decomposer writes `[TBD]` in English sub-plans and
# `【待定】` in Chinese ones, so matching only the first reports every Chinese leaf as
# fully written. Content lines exclude blanks and HTML-comment template guidance.
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
        { content[sec]++; if (index($0, "[TBD]") || index($0, "【待定】")) tbd[sec]++ }
        END { printf "[tbd] §3: %d TBD / %d content lines | §5: %d TBD / %d content lines\n",
                     tbd[3]+0, content[3]+0, tbd[5]+0, content[5]+0 }
    ' "$1"
}

dates_seen() {
    grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' "$1" | sort -u | tr '\n' ' '
}

# Bodies of the numbered "## <n>." sections the caller asked for, capped per
# section. It matches on the number only, never on the heading text, so it stays
# language-agnostic and knows nothing about what any section is called.
sections_by_number() {   # $1 = file, $2 = comma-separated section numbers
    awk -v want="$2" -v cap="$BODY_CAP" '
        BEGIN { n = split(want, a, ","); for (i = 1; i <= n; i++) { gsub(/[^0-9]/, "", a[i]); if (a[i] != "") sel[a[i]] = 1 } }
        /^## / {
            inside = 0
            if (match($0, /^##[ \t]+[0-9]+\./)) {
                num = substr($0, RSTART, RLENGTH); gsub(/[^0-9]/, "", num)
                if (num in sel) { inside = 1; printed = 0; lines = 0; head = $0 }
            }
            next
        }
        inside {
            if (lines >= cap) { if (lines == cap) { print "  … (section truncated at " cap " lines)"; lines++ } next }
            if (!printed) { print head; printed = 1 }
            print; lines++
        }
    ' "$1"
}

# Is this run directory inside the --runs scope? Empty scope means every run.
in_runs_scope() {   # $1 = path under wkdrs/
    [ -n "$RUNS_SCOPE" ] || return 0
    d=${1#wkdrs/}; d=${d%%/*}
    case ",$RUNS_SCOPE," in
        *",$d,"*) return 0 ;;
    esac
    return 1
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
    # The tree shape and the "too coarse" input are what a status or digest read
    # needs; a provenance read has no use for either, so --trails drops both.
    if [ "$TRAILS" = 0 ]; then
        index=$(section_body "$f" '^##[ \t]*Sub-plans')
        if [ -n "$index" ]; then
            say "[sub-plans index]"
            printf '%s\n' "$index" | grep -v '^[ \t]*$'
        fi
    fi
    # The one body fact the coverage band needs: an idea file named anywhere in
    # the plan, since the coach records its seed as prose rather than a field.
    seeds=$(grep -o '[A-Za-z0-9._-]*_idea\.md' "$f" | sort -u | tr '\n' ' ')
    [ -z "$seeds" ] || say "[idea refs] $seeds"
    [ "$TRAILS" = 1 ] || tbd_counts "$f"
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
    if ! in_runs_scope "$f"; then
        say "[body and dates omitted — outside --runs scope]"
    else
        say "[body: headings with their table rows, checkboxes, and signals]"
        body_index "$f"
        [ "$TRAILS" = 1 ] || say "[dates seen] $(dates_seen "$f")"
    fi
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
    if [ -n "$BODY_SECTIONS" ]; then
        case "$f" in
            wkdrs/*/*)
                # --runs gates the bodies for the same reason it gates the per-run
                # body index: a report inside wkdrs/<run>/ is that run's content.
                # Frontmatter above stays project-wide either way, so a caller that
                # scopes the bodies still sees every artifact exists.
                if ! in_runs_scope "$f"; then
                    say "[bodies omitted — outside --runs scope]"
                else
                    bodies=$(sections_by_number "$f" "$BODY_SECTIONS")
                    if [ -n "$bodies" ]; then
                        say "[bodies: sections $BODY_SECTIONS]"
                        printf '%s\n' "$bodies"
                    fi
                fi
                ;;
        esac
    fi
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

if [ "$TRAILS" = 0 ]; then
    say ""
    say "## DIRS — metds/ and wkdrs/ subdirectories"
    dirs=$(find_dirs metds; find_dirs wkdrs)
    if [ -n "$dirs" ]; then
        printf '%s\n' "$dirs" | sort
    else
        say "(none)"
    fi
fi
