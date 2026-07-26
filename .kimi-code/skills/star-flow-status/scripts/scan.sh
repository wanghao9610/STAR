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
# Each of the three sweeps is one awk pass over its whole file list, not one
# process per file. Pulling a file's frontmatter, section bodies, placeholder
# counts and dates costs four or five processes when each extractor is its own
# utility, and on a project with a few hundred registered files that startup
# overhead is most of the runtime — the reading itself is microseconds. The awk
# program below holds the same extractors as functions over one buffered file at
# a time, so the output is unchanged and the process count stays constant.
#
# Usage: bash <skill-dir>/scripts/scan.sh [--slim] [--trails] [--bodies N,N] [--runs DIR,DIR]
#        # run from the project root
#
#   --slim        summarise the two things that grow with a project's history
#                 rather than its plan tree. A table of more than six rows in a
#                 run's body index becomes counts — its header row, how many data
#                 rows follow, and a value histogram per column, with a column
#                 whose values never repeat given as a count. Six rows or fewer
#                 print as they are, since a tally of them is no shorter. Two
#                 kinds of line are never summarised, because a count cannot
#                 stand in for them: un-ticked checkboxes and plan-level
#                 findings. And an artifact sitting inside a run
#                 directory prints no frontmatter, because LISTING already carries
#                 its name and the date in it; how many were left out is printed,
#                 never dropped silently. A run directory here is a wkdrs/ subdir
#                 holding an EXEC_LOG.md, which is the same thing the RUNS sweep
#                 globs for — no new knowledge of the registry enters the script.
#                 Frontmatter, dates, plans, LISTING and DIRS are untouched, and
#                 --trails keeps every artifact, since a provenance read wants the
#                 writers this would drop.
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
SLIM=0
BODY_SECTIONS=""
RUNS_SCOPE=""
usage() { printf 'usage: scan.sh [--slim] [--trails] [--bodies N,N] [--runs DIR,DIR]\n' >&2; exit 2; }
while [ $# -gt 0 ]; do
    case "$1" in
        --slim)   SLIM=1 ;;
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

# The extractors, as one awk program run once per sweep. `mode` picks which of
# the three per-file routines each input path goes through; paths arrive on
# stdin and the file itself is read with getline, so an unreadable or empty file
# behaves as it did when every extractor opened the file for itself.
#
# Every routine works over buf[1..n], the whole file buffered. Registered
# artifacts are small, and buffering is what lets one pass do the work that
# frontmatter, section_body, tbd_counts and dates_seen each used to open the
# file for.
SCAN_AWK='
function readfile(path,   n, line) {
    n = 0
    split("", buf)
    while ((getline line < path) > 0) buf[++n] = line
    close(path)
    return n
}

# Leading --- block, capped, collected into fm[1..fmn]. Collects nothing for a
# file that has no frontmatter (CODE_REVIEW, REVIEW, refs_index.md carry a
# header line instead).
#
# Without --trails, model_trail entries are counted rather than printed: the
# list grows without bound over the life of a plan and sits above `status:`, so
# printing it would eventually push the fields the readers actually need past
# the cap. No other list is dropped — `sources:` in particular is what a
# stale-document check compares against.
function fm_flush() {
    if (trail_open && trailn > 0) fm[++fmn] = "  … (" trailn " model_trail entries omitted)"
    trail_open = 0; trailn = 0
}
function frontmatter(n,   i, c, line) {
    fmn = 0; split("", fm)
    trail_open = 0; trailn = 0
    if (n == 0 || buf[1] !~ /^---[ \t]*$/) return
    c = 0
    for (i = 2; i <= n; i++) {
        line = buf[i]
        if (line ~ /^---[ \t]*$/) { fm_flush(); return }
        if (trails == 0 && line ~ /^model_trail:/) { fm_flush(); trail_open = 1; c++; fm[++fmn] = line; continue }
        if (trails == 0 && trail_open && line ~ /^[ \t]/) { trailn++; continue }
        if (trails == 0 && trail_open) fm_flush()
        c++
        if (c > cap) { fm[++fmn] = "  … (frontmatter truncated at " cap " lines)"; return }
        fm[++fmn] = line
    }
    fm_flush()
}

# Provenance carried on a header line instead of in frontmatter.
function header_model(n,   i, last) {
    fmn = 0; split("", fm)
    last = (n < 10) ? n : 10
    for (i = 1; i <= last; i++) if (buf[i] ~ /model_id/) fm[++fmn] = buf[i]
}

function fm_print(   i) { for (i = 1; i <= fmn; i++) print fm[i] }

# Trailing blank lines are not content — what a `$(...)` capture did to these
# blocks before the callers compared them against the empty string.
function fm_trim() { while (fmn > 0 && fm[fmn] == "") fmn-- }
function sec_trim() { while (secn > 0 && sec[secn] == "") secn-- }

# A "## <heading>" section body, up to the next "## ", into sec[1..secn].
function section_body(n, pat,   i, inside) {
    secn = 0; split("", sec); inside = 0
    for (i = 1; i <= n; i++) {
        if (buf[i] ~ pat) { inside = 1; continue }
        if (inside && buf[i] ~ /^## /) return
        if (inside) sec[++secn] = buf[i]
    }
}
function print_section(n, pat, label,   i) {
    section_body(n, pat)
    sec_trim()
    if (secn == 0) return
    print label
    for (i = 1; i <= secn; i++) if (sec[i] !~ /^[ \t]*$/) print sec[i]
}

# Structured lines only, each under the "## " heading it sits below: table rows,
# checkbox items, and plan-level-finding notes. Language-agnostic apart from the
# bilingual token pairs (the current labels plus the pre-rename ones, so
# EXEC_LOG.md files already on disk still index), and it keeps prose out of the
# digest.
function body_index(n,   i, line, heading, printed) {
    heading = ""; printed = 0
    for (i = 1; i <= n; i++) {
        line = buf[i]
        if (line ~ /^## /) { heading = line; printed = 0; continue }
        if (heading == "") continue
        if (line ~ /^\|/ || line ~ /^[ \t]*- \[/ || line ~ /Plan-level finding/ ||
            line ~ /方向性信号/ || line ~ /Strategy signal/ || line ~ /战略信号/) {
            if (!printed) { print heading; printed = 1 }
            print line
        }
    }
}

# The same lines body_index prints, counted instead. A finished run contributes
# a step table that never changes again, and printing it in full is most of what
# a late-project digest costs; the counts carry what a reader still has to know
# and the histogram keeps the per-status breakdown the rows carried. Meaning is
# assigned here, so the histogram prints the cell values it saw and names no
# state: which of them counts as finished is a rule the reading skill holds.
# Two kinds of line are never summarised, because a count cannot stand in for
# them — an un-ticked checkbox and a plan-level finding.
function split_row(line, cells,   raw, nf, i, s, cnt) {
    nf = split(line, raw, "|")
    cnt = 0
    for (i = 2; i <= nf; i++) {
        s = raw[i]
        gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s)
        if (i == nf && s == "") continue
        cells[++cnt] = s
    }
    return cnt
}
function tally_reset() {
    tmaxcol = 0; trows = 0; thead = ""; tchecks = 0; tunticked = 0; tverbn = 0
    split("", tcount); split("", tdistinct); split("", tdn); split("", tverb); split("", trow)
}
function tally_flush(   c, i, k, v, out, seg, sv) {
    if (theading == "") return
    if (thead == "" && trows == 0 && tchecks == 0 && tverbn == 0) return
    print theading
    if (thead != "") print thead
    # Under seven rows a tally is not smaller than the rows, so print them. That
    # also removes the only way this could lose something: a column is summarised
    # by count alone when its values never repeat, and for a column holding one of
    # a fixed handful of states that cannot happen once the rows outnumber the
    # states — every short table, where it could, is printed in full instead.
    if (trows > 0 && trows <= 6) {
        for (i = 1; i <= trows; i++) print trow[i]
    } else if (trows > 0) {
        out = "[tally] " trows " data rows"
        for (c = 1; c <= tmaxcol; c++) {
            if (tdn[c] == 0) continue
            if (tdn[c] == trows) { out = out " | c" c ": " trows " distinct"; continue }
            for (i = 1; i <= tdn[c]; i++) sv[i] = tdistinct[c SUBSEP i]
            ssort(sv, tdn[c])
            seg = ""
            for (i = 1; i <= tdn[c]; i++) {
                v = sv[i]; k = tcount[c SUBSEP v]
                seg = seg (i == 1 ? "" : ", ") v "×" k
            }
            out = out " | c" c ": " seg
        }
        print out
    }
    if (tchecks > 0) print "[checks] " tchecks " total, " tunticked " un-ticked"
    for (i = 1; i <= tverbn; i++) print tverb[i]
    theading = ""
}
function tally_row(line,   cells, nc, c, v) {
    if (line ~ /^\|[-:| \t]*$/) return
    nc = split_row(line, cells)
    if (thead == "") { thead = line; return }
    trows++
    trow[trows] = line
    if (nc > tmaxcol) tmaxcol = nc
    for (c = 1; c <= nc; c++) {
        v = cells[c]
        # Two statements, not `tdistinct[c SUBSEP ++tdn[c]]`: awk reads a ++ that
        # follows a concatenation as a post-increment of what came before, so
        # that subscript increments SUBSEP itself and silently corrupts every
        # key built from it.
        if (!((c SUBSEP v) in tcount)) {
            tdn[c]++
            tdistinct[c SUBSEP tdn[c]] = v
        }
        tcount[c SUBSEP v]++
    }
}
function body_tally(n,   i, line) {
    theading = ""; tally_reset()
    for (i = 1; i <= n; i++) {
        line = buf[i]
        if (line ~ /^## /) { tally_flush(); theading = line; tally_reset(); continue }
        if (theading == "") continue
        if (line ~ /^\|/) { tally_row(line); continue }
        if (line ~ /^[ \t]*- \[/) {
            tchecks++
            if (line ~ /^[ \t]*- \[[ \t]*\]/) { tunticked++; tverb[++tverbn] = line }
            continue
        }
        if (line ~ /Plan-level finding/ || line ~ /方向性信号/ ||
            line ~ /Strategy signal/ || line ~ /战略信号/) tverb[++tverbn] = line
    }
    tally_flush()
}

# How much of §3 and §5 is still a placeholder — the input to the "too coarse"
# rule. Both markers count: star-plan-decomposer writes `[TBD]` in English
# sub-plans and `【待定】` in Chinese ones, so matching only the first reports
# every Chinese leaf as fully written. Content lines exclude blanks and
# HTML-comment template guidance.
function tbd_counts(n,   i, line, s, was, incomment, c3, c5, t3, t5) {
    s = 0; incomment = 0; c3 = 0; c5 = 0; t3 = 0; t5 = 0
    for (i = 1; i <= n; i++) {
        line = buf[i]
        if (line ~ /^## +3\./) { s = 3; continue }
        if (line ~ /^## +5\./) { s = 5; continue }
        if (line ~ /^## /) { s = 0; continue }
        if (s == 0) continue
        if (line ~ /<!--/) incomment = 1
        was = incomment
        if (line ~ /-->/) incomment = 0
        if (was) continue
        if (line ~ /^[ \t]*$/) continue
        if (s == 3) { c3++; if (index(line, "[TBD]") || index(line, "【待定】")) t3++ }
        else        { c5++; if (index(line, "[TBD]") || index(line, "【待定】")) t5++ }
    }
    printf "[tbd] §3: %d TBD / %d content lines | §5: %d TBD / %d content lines\n", t3, c3, t5, c5
}

function ssort(arr, n,   i, j, t) {
    for (i = 2; i <= n; i++) {
        t = arr[i]; j = i - 1
        while (j >= 1 && arr[j] > t) { arr[j + 1] = arr[j]; j-- }
        arr[j + 1] = t
    }
}

# Every match of a pattern across the file, sorted, deduplicated, space-joined
# with a trailing space — the shape the grep | sort -u | tr pipelines produced.
function scan_all(n, pat,   i, s, k, cnt, out) {
    cnt = 0; split("", hits); split("", hitseen)
    for (i = 1; i <= n; i++) {
        s = buf[i]
        while (match(s, pat)) {
            k = substr(s, RSTART, RLENGTH)
            if (!(k in hitseen)) { hitseen[k] = 1; hits[++cnt] = k }
            s = substr(s, RSTART + RLENGTH)
        }
    }
    ssort(hits, cnt)
    out = ""
    for (i = 1; i <= cnt; i++) out = out hits[i] " "
    return out
}

# Bodies of the numbered "## <n>." sections the caller asked for, capped per
# section, into sec[1..secn]. It matches on the number only, never on the
# heading text, so it stays language-agnostic and knows nothing about what any
# section is called.
function sections_by_number(n, want,   i, j, parts, sel, line, num, inside, printed, lines, head) {
    secn = 0; split("", sec); split("", sel)
    j = split(want, parts, ",")
    for (i = 1; i <= j; i++) { gsub(/[^0-9]/, "", parts[i]); if (parts[i] != "") sel[parts[i]] = 1 }
    inside = 0
    for (i = 1; i <= n; i++) {
        line = buf[i]
        if (line ~ /^## /) {
            inside = 0
            if (match(line, /^##[ \t]+[0-9]+\./)) {
                num = substr(line, RSTART, RLENGTH); gsub(/[^0-9]/, "", num)
                if (num in sel) { inside = 1; printed = 0; lines = 0; head = line }
            }
            continue
        }
        if (!inside) continue
        if (lines >= bodycap) {
            if (lines == bodycap) { sec[++secn] = "  … (section truncated at " bodycap " lines)"; lines++ }
            continue
        }
        if (!printed) { sec[++secn] = head; printed = 1 }
        sec[++secn] = line; lines++
    }
}

# Is this run directory inside the --runs scope? Empty scope means every run.
function in_runs_scope(path,   d) {
    if (scope == "") return 1
    d = path; sub(/^wkdrs\//, "", d); sub(/\/.*$/, "", d)
    return index("," scope ",", "," d ",") > 0
}

function do_plan(path,   n, seeds) {
    n = readfile(path)
    seen++
    print ""
    print "=== " path
    print "[frontmatter]"
    frontmatter(n); fm_print()
    # The tree shape and the "too coarse" input are what a status or digest read
    # needs; a provenance read has no use for either, so --trails drops both.
    if (trails == 0) print_section(n, "^##[ \t]*Sub-plans", "[sub-plans index]")
    # The one body fact the coverage band needs: an idea file named anywhere in
    # the plan, since the coach records its seed as prose rather than a field.
    seeds = scan_all(n, "[A-Za-z0-9._-]*_idea[.]md")
    if (seeds != "") print "[idea refs] " seeds
    if (trails == 0) tbd_counts(n)
    else print_section(n, "^##[ \t]*Revision History", "[revision history]")
}

function do_run(path,   n) {
    n = readfile(path)
    seen++
    print ""
    print "=== " path
    print "[frontmatter]"
    frontmatter(n); fm_print()
    if (!in_runs_scope(path)) {
        print "[body and dates omitted — outside --runs scope]"
        return
    }
    if (slim == 0) {
        print "[body: headings with their table rows, checkboxes, and signals]"
        body_index(n)
    } else {
        print "[body: counted per heading; un-ticked checkboxes and findings verbatim]"
        body_tally(n)
    }
    if (trails == 0) print "[dates seen] " scan_all(n, "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]")
}

function do_artifact(path,   n, i, tmp, slashes, d) {
    if (path ~ /\/EXEC_LOG\.md$/) return
    # Inside a run directory, LISTING already carries the name and the date in
    # it, which is all a presence-and-freshness check reads. --trails is the one
    # read that wants more, so it keeps them.
    if (slim == 1 && trails == 0) {
        d = path
        if (sub(/^wkdrs\//, "", d) && sub(/\/.*$/, "", d) && index("," rundirs ",", "," d ",") > 0) {
            skipped++
            return
        }
    }
    n = readfile(path)
    frontmatter(n); fm_trim()
    if (fmn == 0) {
        # No frontmatter. In provenance mode its header line may still name a writer.
        if (trails == 0) return
        header_model(n); fm_trim()
        if (fmn == 0) return
    }
    seen++
    print ""
    print "=== " path
    fm_print()
    if (bodysel == "") return
    tmp = path; slashes = gsub(/\//, "/", tmp)
    if (path !~ /^wkdrs\// || slashes < 2) return
    # --runs gates the bodies for the same reason it gates the per-run body
    # index: a report inside wkdrs/<run>/ belongs to that run. Frontmatter above
    # stays project-wide either way, so a caller that scopes the bodies still
    # sees every artifact exists.
    if (!in_runs_scope(path)) { print "[bodies omitted — outside --runs scope]"; return }
    sections_by_number(n, bodysel)
    sec_trim()
    if (secn == 0) return
    print "[bodies: sections " bodysel "]"
    for (i = 1; i <= secn; i++) print sec[i]
}

{
    if ($0 == "") next
    if (mode == "plans") do_plan($0)
    else if (mode == "runs") do_run($0)
    else do_artifact($0)
}
END {
    if (seen == 0) print nonemsg
    if (skipped > 0) print "(" skipped " artifact(s) inside run directories omitted by --slim — see LISTING)"
}
'

sweep() {   # $1 = mode, $2 = what to say when the sweep found nothing; paths on stdin
    awk -v mode="$1" -v nonemsg="$2" -v cap="$FM_CAP" -v bodycap="$BODY_CAP" \
        -v trails="$TRAILS" -v slim="$SLIM" -v scope="$RUNS_SCOPE" \
        -v bodysel="$BODY_SECTIONS" -v rundirs="$RUN_DIRS" "$SCAN_AWK"
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

# Which wkdrs/ subdirs --slim treats as run directories: the ones holding an
# EXEC_LOG.md, which is the same set the RUNS sweep globs. wkdrs/digests/,
# wkdrs/results/ and wkdrs/env_*/ hold no log, so their frontmatter is never
# skipped — and the script still has no list of what the registry expects.
RUN_DIRS=""
[ "$SLIM" = 0 ] || RUN_DIRS=$(find_md wkdrs 2 'EXEC_LOG.md' | sed 's|^wkdrs/||; s|/EXEC_LOG\.md$||' | tr '\n' ',')

say "# STAR flow scan — $(pwd -P)"
say "# today: $(date +%Y-%m-%d)"
[ "$TRAILS" = 0 ] || say "# mode: --trails (provenance)"
say "# Raw excerpts only: no status, no glyphs, no verdicts, no ordering, no scoping."
say "# Apply your skill's own rules to what follows."

# ---------------------------------------------------------------- plans
say ""
say "## PLANS — metds/plans/*_plan.md"
find_md metds/plans 1 '*_plan.md' | sweep plans "(none)"

# ---------------------------------------------------------------- runs
say ""
say "## RUNS — wkdrs/*/EXEC_LOG.md"
find_md wkdrs 2 'EXEC_LOG.md' | sweep runs "(none)"

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
artifact_files | sweep artifacts "(none with frontmatter)"

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
