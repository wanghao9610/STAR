#!/usr/bin/env bash
# Finding closure requires an explicit matching decision, never report chronology.
set -eu
script_dir=$(cd "$(dirname "$0")" && pwd -P)
script=$script_dir/../../../.agents/skills/star-flow-status/scripts/findings.sh
sandbox=$(mktemp -d "${TMPDIR:-/tmp}/star-finding-tests.XXXXXX")
trap 'rm -rf "$sandbox"' EXIT
assertions=0
cases=0
header='## 4. Divergences

| finding_id | source_log | disposition | decision | evidence |
| --- | --- | --- | --- | --- |'
finding='- **Plan-level finding** `run:PF1` — revise objective; evidence: `metds/evidence.md`.'
write() { mkdir -p "$(dirname "$root/$1")"; printf '%s\n' "$2" > "$root/$1"; }
fixture() {
    cases=$((cases + 1))
    root=$sandbox/case$cases
    mkdir -p "$root"
    log=wkdrs/run/EXEC_LOG.md
    write "$log" "## Notes
$finding"
    write metds/evidence.md 'verified decision'
}
report() {
    local name=${1:-review.md} id=${2:-run:PF1} origin=${3:-$log} disposition=${4:-resolved} decision=${5-Revise objective} evidence=${6-'`metds/evidence.md`'}
    write "$name" "$header
| $id | \`$origin\` | $disposition | $decision | $evidence |"
}
fail() { echo "FAIL case $cases: $*" >&2; [ -z "${data:-}" ] || printf '%s\n' "$data" >&2; exit 1; }
assert() {
    assertions=$((assertions + 1))
    printf '%s\n' "$data" | jq -e "$1" >/dev/null || fail "$1"
}
snapshot() {
    { find "$root" -print; find "$root" -type f -exec cksum {} \;; find "$root" -type l -exec readlink {} \;; } | LC_ALL=C sort | cksum
}
check_cli() {
    local expected=$1 before after status=0
    shift
    before=$(snapshot)
    data=$("$BASH" "$script" "$@" 2> "$sandbox/stderr") || status=$?
    assertions=$((assertions + 1))
    [ "$status" -eq "$expected" ] || fail "exit $status, expected $expected: $(cat "$sandbox/stderr")"
    after=$(snapshot)
    assertions=$((assertions + 1))
    [ "$before" = "$after" ] || fail 'resolver changed input files'
    assert 'keys == ["open","resolved","unknowns"]'
}
check() {
    local expected=$1 selected
    shift
    args=(--root "$root" --log "$log")
    for selected in "$@"; do args+=(--report "$selected"); done
    check_cli "$expected" "${args[@]}"
}
# 1. Newer unrelated reviews never close a finding.
fixture
report 2099_review.md other:PF1 wkdrs/other/EXEC_LOG.md
check 0 2099_review.md
assert '. == {open:["run:PF1"], resolved:[], unknowns:[]}'
check 0
assert '.open == ["run:PF1"]'
# 2. Exact decisions close findings regardless of date or unrelated reports.
fixture
report 1900_review.md
check 0 1900_review.md
assert '. == {open:[], resolved:["run:PF1"], unknowns:[]}'
report 2099_review.md other:PF1
check 0 2099_review.md 1900_review.md
assert '.resolved == ["run:PF1"]'
# 3. The same ID with a different source stays open.
fixture
report review.md run:PF1 wkdrs/other/EXEC_LOG.md
check 0 review.md
assert '.open == ["run:PF1"]'
# 4. Deferred findings remain open.
fixture
report review.md run:PF1 "$log" deferred
check 0 review.md
assert '.open == ["run:PF1"]'
# 5. Missing evidence or decisions are unknown.
fixture
for evidence in '`absent.md`' ''; do
    report review.md run:PF1 "$log" resolved 'Revise objective' "$evidence"
    check 2 review.md
    assert '.resolved == [] and (.unknowns|length>0)'
done
report review.md run:PF1 "$log" resolved ''
check 2 review.md
assert '.resolved == [] and (.unknowns|length>0)'
# 6. Resolved supersedes deferred without date or argument-order inference.
fixture
for pair in '1900_deferred.md 2099_resolved.md' '2099_deferred.md 1900_resolved.md'; do
    read -r deferred resolved <<< "$pair"
    report "$deferred" run:PF1 "$log" deferred 'Await objective review'
    report "$resolved"
    check 0 "$deferred" "$resolved"
    assert '. == {open:[],resolved:["run:PF1"],unknowns:[]}'
    check 0 "$resolved" "$deferred"
    assert '. == {open:[],resolved:["run:PF1"],unknowns:[]}'
done
# 7. Multiple deferred notes remain open.
fixture
report first.md run:PF1 "$log" deferred 'Await review'
report second.md run:PF1 "$log" deferred 'Await additional evidence'
check 0 first.md second.md
assert '. == {open:["run:PF1"],resolved:[],unknowns:[]}'
# 8. Conflicting resolved decisions are unknown in either order.
fixture
report first.md
report second.md run:PF1 "$log" resolved 'Keep original objective'
check 2 first.md second.md
first_result=$data
assert '.resolved == [] and .open == []'
check 2 second.md first.md
assertions=$((assertions + 1))
[ "$data" = "$first_result" ] || fail 'report order changed conflict result'
# 9. Stable origin IDs survive resumes.
fixture
write "$log" "## Notes
$finding

### Resume 2026-10-21
- Continued verification."
check 0
assert '.open == ["run:PF1"]'
report
check 0 review.md
assert '.resolved == ["run:PF1"]'
# 10. Comments, fences, and non-Notes sections are ignored.
fixture
hidden='- **Plan-level finding** `run:PF2` — example; evidence: `missing`.'
write "$log" "## Results
$hidden
## Notes
<!--
$hidden
-->
\`\`\`markdown
$hidden
\`\`\`
~~~
$hidden
~~~
$finding"
report
cat >> "$root/review.md" <<'HIDDEN'
<!-- | run:PF1 | `wkdrs/run/EXEC_LOG.md` | deferred | hidden | absent | -->
```
| run:PF1 | `wkdrs/run/EXEC_LOG.md` | deferred | hidden | absent |
```
HIDDEN
check 0 review.md
assert '.resolved == ["run:PF1"]'
# 11. Dropped aliases, Chinese labels, and numbered sections are supported.
fixture
log=wkdrs/dropped/run/EXEC_LOG.md
write "$log" "## 备注
${finding/Plan-level finding/方向性信号}"
report review.md run:PF1 ./wkdrs/run/EXEC_LOG.md
sed 's/## 4. Divergences/## 4、偏差/' "$root/review.md" > "$sandbox/translated"
mv "$sandbox/translated" "$root/review.md"
check 0 review.md
assert '.resolved == ["run:PF1"]'
# 12. Legacy, duplicate, malformed, zero, and foreign origin IDs stay unknown.
fixture
for body in '- **Plan-level finding** old claim; evidence: `metds/evidence.md`.' "$finding
$finding" "$finding
- **Plan-level finding** \`run:PF1\`" "${finding/run:PF1/run:PF0}" "${finding/run:PF1/other:PF1}"; do
    write "$log" "## Notes
$body"
    report
    check 2 review.md
    assert '.resolved == [] and ([.unknowns[].message]|join(" ")|contains("executor"))'
done
# 13. Evidence references are exact and contained, including symlinks and suffixes.
fixture
for evidence in 'text `metds/evidence.md`' '`../outside.md`' '`/etc/passwd`' '`https://example.com`' '`metds/evidence.md` and more'; do
    report review.md run:PF1 "$log" resolved 'Revise objective' "$evidence"
    check 2 review.md
    assert '.resolved == []'
done
mkdir -p "$sandbox/outside"
ln -s "$sandbox/outside" "$root/linked"
report review.md run:PF1 "$log" resolved 'Revise objective' linked
check 2 review.md
assert '.resolved == []'
for evidence in '`metds/evidence.md:12`' '`metds/evidence.md`#decision' '"metds/evidence.md":12#decision'; do
    report review.md run:PF1 "$log" resolved 'Revise objective' "$evidence"
    check 0 review.md
    assert '.resolved == ["run:PF1"]'
done
# 14. Historical evidence survives actual drops and revivals in every owned layout.
fixture
for live in metds/plans/01_other_plan.md wkdrs/other/results/decision.md tasks/other/check.py execs/scpts/other.sh; do
    case "$live" in
        metds/plans/*) dropped=metds/plans/dropped/${live#metds/plans/} ;;
        wkdrs/*) dropped=wkdrs/dropped/${live#wkdrs/} ;;
        tasks/*) dropped=tasks/dropped/${live#tasks/} ;;
        execs/scpts/*) dropped=execs/scpts/dropped/${live#execs/scpts/} ;;
    esac
    write "$live" 'verified evidence'
    report review.md run:PF1 "$log" resolved 'Revise objective' "\`$live\`:12#decision"
    check 0 review.md
    assert '.resolved == ["run:PF1"]'
    mkdir -p "$(dirname "$root/$dropped")"
    mv "$root/$live" "$root/$dropped"
    check 0 review.md
    assert '.resolved == ["run:PF1"]'
    report review.md run:PF1 "$log" resolved 'Revise objective' "\`$dropped\`"
    check 0 review.md
    assert '.resolved == ["run:PF1"]'
    mv "$root/$dropped" "$root/$live"
    check 0 review.md
    assert '.resolved == ["run:PF1"]'
done
# 15. Existing evidence takes precedence over unsafe dropped aliases.
fixture
write metds/plans/01_other_plan.md 'current evidence'
mkdir -p "$root/metds/plans/dropped"
ln -s "$sandbox/outside/missing.md" "$root/metds/plans/dropped/01_other_plan.md"
report review.md run:PF1 "$log" resolved 'Revise objective' '`metds/plans/01_other_plan.md`'
check 0 review.md
assert '.resolved == ["run:PF1"]'
# 16. Alias fallback cannot escape through symlinks in either direction.
fixture
write_external=$sandbox/outside/evidence.md
printf '%s\n' 'external evidence' > "$write_external"
for cited in metds/plans/01_other_plan.md metds/plans/dropped/02_other_plan.md; do
    case "$cited" in
        */dropped/*) alternate=metds/plans/02_other_plan.md ;;
        *) alternate=metds/plans/dropped/01_other_plan.md ;;
    esac
    mkdir -p "$(dirname "$root/$alternate")"
    ln -s "$write_external" "$root/$alternate"
    report review.md run:PF1 "$log" resolved 'Revise objective' "\`$cited\`"
    check 2 review.md
    assert '.resolved == [] and (.unknowns|length>0)'
done
# 17. Missing unrelated paths are never rebound into dropped layouts.
fixture
while IFS='|' read -r cited unrelated; do
    write "$unrelated" 'unrelated evidence'
    report review.md run:PF1 "$log" resolved 'Revise objective' "\`$cited\`"
    check 2 review.md
    assert '.resolved == [] and (.unknowns|length>0)'
done <<'PATHS'
metds/missing.md|metds/dropped/missing.md
metds/plans/notes.md|metds/plans/dropped/notes.md
metds/plans/nested/01_other_plan.md|metds/plans/dropped/nested/01_other_plan.md
wkdrs/results/decision.md|wkdrs/dropped/results/decision.md
wkdrs/env_probe/decision.md|wkdrs/dropped/env_probe/decision.md
execs/scpts/notes.md|execs/scpts/dropped/notes.md
tasks/dropped/dropped/check.py|tasks/dropped/check.py
PATHS
# 18. Attempted malformed decision tables and unreadable reports stay unknown.
fixture
write bad.md '## 4. Divergences
| id | decision |
| run:PF1 | done |'
check 2 bad.md
assert '.unknowns|length>0'
write bad.md '## 4. Divergences
| finding_id | source_log | disposition | decision | evidence |
| run:PF1 | wkdrs/run/EXEC_LOG.md | resolved | done | metds/evidence.md |'
check 2 bad.md
assert '.unknowns|length>0'
check 2 missing.md
assert '.unknowns|length>0'
# 19. A malformed matching row cannot be hidden by a valid report.
fixture
report
write malformed.md "$header
| run:PF1 | wkdrs/run/EXEC_LOG.md | resolved | done | metds/evidence.md | extra |"
check 2 review.md malformed.md
assert '.resolved == []'
check 2 malformed.md review.md
assert '.resolved == []'
# 20. Ordinary pipe-bearing prose does not become decision data.
fixture
write prose.md '## 4. Divergences
The expression a | b describes the shell pipeline.
A quoted `one | two` example remains ordinary prose.'
check 0 prose.md
assert '. == {open:["run:PF1"],resolved:[],unknowns:[]}'
# 21. Unrelated tables do not become owned decision tables.
fixture
write unrelated.md '## 4. Divergences
| metric | before | after |
| --- | --- | --- |
| count | 1 | 2 |

| id | decision |
| --- | --- |
| other | done |'
check 0 unrelated.md
assert '. == {open:["run:PF1"],resolved:[],unknowns:[]}'
# 22. A report without a decision table contributes no resolution or error.
fixture
report
write no-table.md '## 4. Divergences
No finding was considered.'
check 0 review.md no-table.md
assert '. == {open:[],resolved:["run:PF1"],unknowns:[]}'
check 0 no-table.md review.md
assert '. == {open:[],resolved:["run:PF1"],unknowns:[]}'
# 23. All reports without decision tables leave findings open, including section 3.
fixture
write first.md '## 4. Divergences
No finding considered.'
write second.md "${header/## 4./## 3.}"
check 0 first.md second.md
assert '. == {open:["run:PF1"],resolved:[],unknowns:[]}'
# 24. Prose and unrelated tables after an owned table are also independent.
fixture
report
cat >> "$root/review.md" <<'PROSE'
The expression a | b describes a pipeline.

| label | value |
| --- | --- |
| result | checked |
PROSE
check 0 review.md
assert '.resolved == ["run:PF1"] and .unknowns == []'
# 25. Read paths and source aliases must stay inside the root as well.
fixture
ln -s "$sandbox/outside" "$root/external"
report review.md run:PF1 external/EXEC_LOG.md
check 2 review.md
assert '.resolved == [] and (.unknowns|length>0)'
check 2 ../outside/evidence.md
assert '.open == ["run:PF1"] and (.unknowns|length>0)'
# 26. Quoted space-bearing evidence and JSON-sensitive decisions are preserved.
fixture
write 'metds/evidence file.md' checked
report first.md run:PF1 "$log" resolved 'Keep "quoted" \ decision' '"metds/evidence file.md"'
report second.md run:PF1 "$log" resolved 'Keep "quoted" \ decision' '"metds/evidence file.md"'
check 0 first.md second.md
assert '.resolved == ["run:PF1"] and .unknowns == []'
# 27. Different backslash-bearing decisions must still conflict.
fixture
report first.md run:PF1 "$log" resolved 'Keep \ decision'
report second.md run:PF1 "$log" resolved 'Keep \\ decision'
check 2 first.md second.md
assert '.resolved == [] and (.unknowns|length>0)'
# 28. Malformed attempted separators cannot be hidden by a valid report.
fixture
report
write malformed.md '## 4. Divergences
| finding_id | source_log | disposition | decision | evidence |
| ---:- | --- | --- | --- | --- |
| run:PF1 | wkdrs/run/EXEC_LOG.md | resolved | done | metds/evidence.md |'
check 2 review.md malformed.md
assert '.resolved == [] and (.unknowns|length>0)'
# 29. Equals-form options preserve space-bearing roots and repeated reports.
fixture
mv "$root" "$root with spaces"
root="$root with spaces"
report resolved.md
report deferred.md run:PF1 "$log" deferred 'Await additional review'
check_cli 0 "--root=$root" "--log=$log" --report=resolved.md --report=deferred.md
assert '. == {open:[],resolved:["run:PF1"],unknowns:[]}'
# 30. Equals-form report values preserve the resolver quoted-path syntax.
fixture
report 'review with spaces.md'
write 'no table.md' '## 4. Divergences
No finding considered.'
check_cli 0 "--root=$root" "--log=$log" '--report="review with spaces.md"' '--report=`no table.md`'
assert '. == {open:[],resolved:["run:PF1"],unknowns:[]}'
# 31. Separate and equals-form options can be mixed without losing reports.
fixture
report resolved.md
report deferred.md run:PF1 "$log" deferred 'Await additional review'
check_cli 0 --root "$root" "--log=$log" --report resolved.md --report=deferred.md
assert '. == {open:[],resolved:["run:PF1"],unknowns:[]}'
# 32-33. Both help forms succeed without requiring root or log options.
for option in -h --help; do
    fixture
    status=0
    data=$("$BASH" "$script" "$option" 2> "$sandbox/stderr") || status=$?
    assertions=$((assertions + 2))
    [ "$status" -eq 0 ] || fail "help exited $status"
    case "$data" in 'Usage: findings.sh '*) ;; *) fail 'missing help usage' ;; esac
done
printf 'PASS: %s cases, %s assertions\n' "$cases" "$assertions"
