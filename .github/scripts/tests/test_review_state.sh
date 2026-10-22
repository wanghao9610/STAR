#!/usr/bin/env bash
# Review receipts and real hook behavior, using disposable repositories only.
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT
HELPER=.agents/skills/star-code-reviewer/scripts/review_state.sh
RUN=01_example
REPORT="wkdrs/$RUN/CODE_REVIEW_2026-10-21.md"
PLAN=metds/plans/01_example_plan.md
HOOKS=(.claude/hooks/star_commit_guard.sh .codex/hooks/star_commit_guard.sh
    .cursor/hooks/star_commit_guard.sh .dsh/hooks/star_commit_guard.sh
    .kimi-code/hooks/star_commit_guard.sh .qwen/hooks/star_commit_guard.sh
    .pi/extensions/star-hooks/star_commit_guard.sh)
cases=0
fail() { printf 'FAIL review state: %s\n' "$*" >&2; exit 1; }
note() { cases=$((cases + 1)); printf 'ok review state: %s\n' "$*"; }
write() { mkdir -p "$(dirname -- "$project/$1")"; printf '%s' "$2" > "$project/$1"; }
reset_case() {
    project="$TMP_DIR/case-$cases/project"
    mkdir -p "$project"
    git init -q "$project"
    for file in "$HELPER" "${HOOKS[@]}"; do
        mkdir -p "$(dirname -- "$project/$file")"
        cp -p "$ROOT_DIR/$file" "$project/$file"
    done
    write "wkdrs/$RUN/EXEC_LOG.md" $'# Execution\n2026-10-21 implemented\n'
    write "$REPORT" $'# Review\n<!-- model_id: fixture\nreview_gate: passed\n-->\nNo findings.\n'
    write code/main.sh $'printf answer\n'
    write configs/runtime.json $'{"enabled":true}\n'
    write "$PLAN" $'---\nupdated: 2026-10-21\nstatus: ready\nmodel_trail:\n  - model: fixture\n---\n# Example\n## 2. Method\nReturn 42.\n## Revision History\nOld entry.\n## 5. Criteria\nCheck the return value.\n'
}
helper() { bash "$project/$HELPER" --root "$project" "$@"; }
record() { helper record "$RUN" "$REPORT" --path code --path configs/runtime.json --plan "$PLAN"; }
check() {
    local result rc
    if result=$(helper check "$RUN" 2>"$TMP_DIR/error"); then rc=0; else rc=$?; fi
    [[ ! -s "$TMP_DIR/error" ]] || fail "unexpected stderr: $(cat "$TMP_DIR/error")"
    if [[ $# -eq 0 ]]; then
        [[ $rc -eq 0 && -z $result ]] || fail "expected current receipt: $result"
    else
        [[ $rc -ne 0 && $result == *"$1"* ]] || fail "expected $1: $result"
        [[ $result != *$'\n'* ]] || fail 'diagnostic must be one line'
    fi
}
hooks() {
    local reason="${1:-}" command="${2:-bash execs/scpts/$RUN.sh}" output rc payload hook
    payload=$(jq -cn --arg c "$command" '{command:$c,tool_input:{command:$c}}')
    for hook in "${HOOKS[@]}"; do
        if [[ $hook == .pi/* ]]; then
            if output=$(bash "$project/$hook" "$command"); then rc=0; else rc=$?; fi
        else
            if output=$(printf '%s' "$payload" | bash "$project/$hook"); then rc=0; else rc=$?; fi
        fi
        if [[ -z $reason ]]; then
            [[ $rc -eq 0 && -z $output ]] || fail "$hook should allow: $output"
        else
            [[ $output == *"$reason"* ]] || fail "$hook missing reason: $output"
            case "$hook" in
                .pi/*) [[ $rc -eq 1 ]] || fail "$hook exit" ;;
                .cursor/*) [[ $rc -eq 2 ]] && jq -e '.permission == "deny"' <<<"$output" >/dev/null || fail "$hook deny" ;;
                *) [[ $rc -eq 0 ]] && jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<<"$output" >/dev/null || fail "$hook deny" ;;
            esac
        fi
    done
}
snapshot() { (cd "$project" && find . -type f -exec cksum {} \; | LC_ALL=C sort); }

reset_case; record
before=$(snapshot); check; [[ $(snapshot) == "$before" ]] || fail 'check wrote files'
note 'current receipt and read-only check'
reset_case; record; write code/main.sh 'changed'; check 'source/config scope changed'
note 'same-day dirty source'
reset_case; record; write configs/runtime.json '{"enabled":false}'; check 'source/config scope changed'
note 'same-day configuration'
reset_case; write .env 'SECRET=fixture-first'
helper record "$RUN" "$REPORT" --path code --path .env --plan "$PLAN"
! grep -q SECRET "$project/wkdrs/$RUN/REVIEW_STATE.md" || fail 'receipt exposed configuration contents'
write .env 'SECRET=fixture-second'; check 'source/config scope changed'
note 'configuration hashes do not expose values'
reset_case; record; write "$PLAN" $'---\nupdated: 2026-10-21\n---\n## 2. Method\nChanged.\n'
check 'plan constraints changed'; note 'same-day plan body'
for field in depends_on children; do
    for newline in lf crlf; do
        reset_case
        text=$(printf '%s:\n# comment\n- "01"\n' "$field")
        plan=$(printf '%s\n%s\n%s\n' '---' "$text" $'updated: 2026-10-21\n---\n## 1. Objective\nUnchanged.')
        if [[ $newline == crlf ]]; then plan=$(printf '%s\n' "$plan" | sed $'s/$/\r/'); fi
        write "$PLAN" "$plan"; record; check
        write "$PLAN" "${plan/\"01\"/\"02\"}"; check 'plan constraints changed'
        note "indentless $field with $newline"
    done
done
reset_case
plan=$'---\ndepends_on:\n- "01"\nmodel_trail:\n- model: before\nexec_runs:\n- old_attempt\nupdated: 2026-10-21\n---\n## 1. Objective\nUnchanged.\n'
write "$PLAN" "$plan"; record
plan=${plan/before/after}; plan=${plan/old_attempt/new_attempt}; plan=${plan/2026-10-21/2026-10-22}
write "$PLAN" "$plan"; check; note 'indentless bookkeeping stays reusable'
for field in parent prefix children depends_on traces_to dropped; do
    reset_case
    case "$field" in children|depends_on|traces_to) value=$'\n  - before' ;; *) value=' before' ;; esac
    plan=$(printf '%s\n%s:%s\n%s\n' '---' "$field" "$value" $'updated: 2026-10-21\n---\n## 1. Objective\nUnchanged.')
    write "$PLAN" "$plan"; record; write "$PLAN" "${plan/before/after}"; check 'plan constraints changed'
    note "semantic frontmatter $field"
done
reset_case
plan=$(cat "$project/$PLAN")
write "$PLAN" "$(printf '%s\n' "$plan" | sed $'s/$/\r/')"; record
plan=${plan/2026-10-21/2026-10-22}; plan=${plan/ready/done}; plan=${plan/fixture/another}; plan=${plan/Old entry./New entry.}
write "$PLAN" "$(printf '%s\n' "$plan" | sed $'s/$/\r/')"; check
note 'CRLF bookkeeping and revision history stay reusable'
reset_case; record; write "wkdrs/$RUN/EXEC_LOG.md" '2099-12-31 log-only update'; check; hooks
note 'log-only updates do not stale review'
reset_case; record; write 'code/new module.ts' 'new source'; check 'source/config scope changed'
note 'directory additions'
reset_case; record; rm "$project/code/main.sh"; check 'source/config scope changed'
note 'directory deletions'
reset_case; helper record "$RUN" "$REPORT" --path code/removed.sh --plan "$PLAN"; check
write code/removed.sh 'restored'; check 'source/config scope changed'; note 'reviewed missing file restored'
reset_case; record; write code/__pycache__/module.pyc cache; write code/datas/data.csv data; write code/inits/weights.bin weights; check
note 'runtime caches and data excluded'
reset_case
if helper record "$RUN" "$REPORT" --path datas >"$TMP_DIR/result"; then fail 'dataset accepted'; fi
grep -q 'invalid source/config scope' "$TMP_DIR/result" || fail 'dataset diagnostic'
note 'dataset scope rejected'
reset_case; check 'missing review metadata'; hooks 'missing review metadata'; note 'legacy metadata missing'
reset_case; write "wkdrs/$RUN/REVIEW_STATE.md" "\$(touch $TMP_DIR/must-not-exist)"
check 'invalid review metadata'; hooks 'invalid review metadata'; [[ ! -e $TMP_DIR/must-not-exist ]] || fail 'metadata executed'
note 'invalid metadata never executed'
reset_case; record; before=$(cat "$project/wkdrs/$RUN/REVIEW_STATE.md"); rm "$project/$PLAN"; check 'missing reviewed plan'
if record >"$TMP_DIR/result"; then fail 'missing plan accepted'; fi
[[ $(cat "$project/wkdrs/$RUN/REVIEW_STATE.md") == "$before" ]] || fail 'failed record replaced receipt'
note 'failed recording preserves receipt'
reset_case; record; rm "$project/$REPORT"; check 'missing reviewed report'; hooks 'missing reviewed report'
note 'missing report'
reset_case; record; printf 'changed\n' >> "$project/$REPORT"; check 'report content changed'; note 'edited report'
reset_case; record; write "${REPORT/2026-10-21/2026-10-22}" 'new review'; check 'newer report has not been recorded'
note 'newer unrecorded report'
for gate in unknown '' $'passed\nreview_gate: blocked'; do
    reset_case; write "$REPORT" "$(printf '<!--\nreview_gate: %s\n-->\n' "$gate")"
    if record >"$TMP_DIR/result"; then fail 'invalid gate accepted'; fi
    grep -q review_gate "$TMP_DIR/result" || fail 'gate diagnostic'
    note 'explicit single gate required'
done
reset_case; write "$REPORT" $'<!--\nreview_gate: blocked\n-->\n'; record; check 'blocked review'; hooks 'blocked review'
note 'blocked review prevents launch'
reset_case; record; write code/main.sh changed
hooks 'source/config scope changed' "nohup bash execs/scpts/$RUN.sh > /tmp/fixture.log"
hooks 'source/config scope changed' "printf ready > wkdrs/$RUN/.await"
note 'every hook recognizes guarded launch forms'
reset_case; record; rm "$project/$HELPER"; hooks 'review-state helper missing'; note 'missing helper blocks launch'
reset_case; hooks '' 'bash execs/scpts/unknown.sh'; hooks '' "cat wkdrs/$RUN/.await"; note 'unknown run and read-only marker access'
reset_case
main_project=$project
tree=$(git -C "$project" mktree </dev/null)
commit=$(printf 'fixture\n' | git -C "$project" -c user.name=Fixture -c user.email=fixture@example.invalid commit-tree "$tree")
worktree="${project}--wt/$RUN"
mkdir -p "$(dirname -- "$worktree")"
git -C "$project" worktree add --detach -q "$worktree" "$commit"
for file in "$HELPER" "${HOOKS[@]}" "$REPORT" "$PLAN" code/main.sh configs/runtime.json "wkdrs/$RUN/EXEC_LOG.md"; do
    mkdir -p "$(dirname -- "$worktree/$file")"; cp -p "$project/$file" "$worktree/$file"
done
rm "$project/wkdrs/$RUN/EXEC_LOG.md"
project=$worktree; record; project=$main_project; write code/main.sh 'main changed'; hooks
project=$worktree; write code/main.sh 'worktree changed'; project=$main_project; hooks 'source/config scope changed'
note 'linked worktree source is authoritative'
reset_case; tool_dir="$TMP_DIR/tools"; mkdir -p "$tool_dir"
for tool in bash git awk sort find readlink mktemp mv rm; do ln -s "$(command -v "$tool")" "$tool_dir/$tool"; done
PATH="$tool_dir" bash "$project/$HELPER" --root "$project" record "$RUN" "$REPORT" --path code --plan "$PLAN"
PATH="$tool_dir" bash "$project/$HELPER" --root "$project" check "$RUN"
note 'helper needs no language runtime'
reset_case
/bin/bash "$project/$HELPER" --root "$project" record "wkdrs/$RUN" "$REPORT" --path code
/bin/bash "$project/$HELPER" --root "$project" check "$RUN"
note 'system Bash optional plan scope'
printf 'PASS review state: %s cases\n' "$cases"
