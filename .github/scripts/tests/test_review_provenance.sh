#!/usr/bin/env bash
# Receipt provenance is verified through the exact report bound by the producer.
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/../../.." && pwd -P)
sandbox=$(mktemp -d)
trap 'rm -rf -- "$sandbox"' EXIT
project="$sandbox/project with spaces"
mkdir -p "$project/wkdrs/demo" "$project/code"
git init -q "$project"
printf 'printf answer\n' > "$project/code/main.sh"
report=wkdrs/demo/CODE_REVIEW_2026-11-04.md
receipt="$project/wkdrs/demo/REVIEW_STATE.md"
helper="$repo/.agents/skills/star-code-reviewer/scripts/review_state.sh"
hook="$repo/.codex/hooks/star_model_id.sh"
cases=0
reset_case() {
    printf '<!-- model_id: fixture\nreview_gate: %s\n-->\n# Review\n' "${1:-passed}" > "$project/$report"
    bash "$helper" --root "$project" record demo "$report" --path code
}
check() {
    local expected=$1 diagnostic=${2:-} actual=0 output
    output=$(bash "$hook" --check "$receipt" '' fixture 2>&1) || actual=$?
    [[ $actual == "$expected" ]] || { printf 'Unexpected exit %s: %s\n' "$actual" "$output"; exit 1; }
    [[ $output == *"$diagnostic"* ]] || { printf 'Missing diagnostic %s: %s\n' "$diagnostic" "$output"; exit 1; }
    cases=$((cases + 1))
}

reset_case
bash "$helper" --root "$project" check demo
bash "$hook" --check "$project/$report" '' fixture
before=$(cat "$receipt")
check 0
[[ $(cat "$receipt") == "$before" ]]
(cd "$project" && bash "$hook" --check wkdrs/demo/REVIEW_STATE.md '' fixture)

printf 'Changed report\n' >> "$project/$report"
check 1 'report content changed'
reset_case
rm "$project/$report"
check 1 'missing report'
reset_case
sed 's/model_id: fixture/model_id: wrong/' "$project/$report" > "$sandbox/report"
cp "$sandbox/report" "$project/$report"
bash "$helper" --root "$project" record demo "$report" --path code
check 1 'model_id mismatch'
reset_case
sed 's/model_id: fixture/author: fixture/' "$project/$report" > "$sandbox/report"
cp "$sandbox/report" "$project/$report"
bash "$helper" --root "$project" record demo "$report" --path code
check 1 "found '<missing>'"

# Provenance alone must neither reject blocked reports nor grant launch approval.
reset_case blocked
check 0
if bash "$helper" --root "$project" check demo > "$sandbox/gate"; then exit 1; fi
grep -q 'blocked review' "$sandbox/gate"
reset_case
printf 'changed source\n' >> "$project/code/main.sh"
check 0
if bash "$helper" --root "$project" check demo > "$sandbox/gate"; then exit 1; fi
grep -q 'source/config scope changed' "$sandbox/gate"

reset_case
printf 'report\t%s\n' "$report" >> "$receipt"
check 1 'duplicate report'
reset_case
sed '/^report_hash/d' "$receipt" > "$sandbox/receipt"
cp "$sandbox/receipt" "$receipt"
check 1 'report content changed'
reset_case
sed 's@CODE_REVIEW_2026-11-04.md@CODE_REVIEW_../outside.md@' "$receipt" > "$sandbox/receipt"
cp "$sandbox/receipt" "$receipt"
check 1 'invalid report path'
reset_case
printf 'unexpected\tvalue\n' >> "$receipt"
check 1 'unknown metadata'
reset_case
cp "$receipt" "$sandbox/REVIEW_STATE.md"
receipt="$sandbox/REVIEW_STATE.md"
check 1 'expected wkdrs/<run>/REVIEW_STATE.md'
printf 'PASS review provenance: %s cases\n' "$cases"
