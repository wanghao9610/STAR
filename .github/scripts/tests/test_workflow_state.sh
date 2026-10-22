#!/usr/bin/env bash
# Disposable local Git repositories exercise the read-only shell validator.
set -eu
export GIT_OPTIONAL_LOCKS=0 LC_ALL=C
SCRIPT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/.agents/skills/star-flow-status/scripts/validate.sh
suite=$(mktemp -d "${TMPDIR:-/tmp}/star-workflow-state.XXXXXX")
trap 'rm -rf "$suite"' EXIT
count=0
fail() { echo "FAIL: $test_name: $*" >&2; exit 1; }
git_fixture() { git -C "$root" "$@"; }
write() {
    local path=${3:-$root}/$1
    mkdir -p "${path%/*}"
    printf '%b' "$2" > "$path"
}
plan() {
    local prefix=metds/plans
    [ "${3:-false}" = false ] || prefix=$prefix/dropped
    write "$prefix/$1" "---\n$2---\n"
}
run_log() {
    local prefix=wkdrs fields=${3:-$'status: in_progress\n'}
    [ "${6:-false}" = false ] || prefix=$prefix/dropped
    write "$prefix/$1/EXEC_LOG.md" "---\nrun: $1\nsource_plan: $2\n$fields---\n${4:-}" "${5:-$root}"
}
# Hash every fixture file, including the Git index/refs and other worktrees.
# A path inventory catches empty files/directories created by a validator too.
snapshot() {
    find "$case_dir" -print | sort
    find "$case_dir" -type f -exec shasum -a 256 {} \; | sort
}
check() {
    local expected=${1:-0} actual before after
    before=$(snapshot)
    if output=$("$BASH" "$SCRIPT" --root "$root" --json); then actual=0; else actual=$?; fi
    after=$(snapshot)
    [ "$before" = "$after" ] || fail 'validator changed fixture files or Git state'
    [ "$actual" -eq "$expected" ] || fail "expected exit $expected, got $actual: $output"
    printf '%s' "$output" | jq -e '
      (keys == ["findings","unknowns"]) and
      all(.[]; . == sort_by(.path,.code,.message))' >/dev/null || fail "invalid or unsorted result: $output"
}
has_code() { printf '%s' "$output" | jq -e --arg code "$1" --arg kind "${2:-findings}" 'any(.[$kind][];.code==$code)' >/dev/null || fail "missing $1: $output"; }
no_code() { printf '%s' "$output" | jq -e --arg code "$1" --arg kind "${2:-findings}" 'all(.[$kind][];.code!=$code)' >/dev/null || fail "unexpected $1: $output"; }
codes_are() { printf '%s' "$output" | jq -e --argjson expected "$1" --arg kind "${2:-findings}" '([.[$kind][].code]|unique)==($expected|sort)' >/dev/null || fail "wrong codes: $output"; }
only_stop() {
    printf '%s' "$output" | jq -e --arg name "$1" '[.findings[]|[.code,(.path|split("/")[-2])]]==[["terminal_open_stop",$name]]' >/dev/null || fail "wrong STOP findings: $output"
}
graph() {
    plan 0_root_plan.md 'prefix: "0"\nchildren:\n  - "00_a_plan.md"\n  - '\''01_b_plan.md'\''\n'
    plan 00_a_plan.md 'prefix: "00"\nparent: 0_root_plan.md\nexec_status: done\nexec_runs: ["00_run",] # trailing comma\n'
    plan 01_b_plan.md 'prefix: "01"\nparent: 0_root_plan.md\ndepends_on:\n  - "00" # preserve leading zero\n'
    run_log 00_run 00_a_plan.md 'status: done\n'
}
test_clean_graph_and_quoted_multiline_lists() {
    graph
    check
    codes_are '[]'; codes_are '[]' unknowns
    local from_cwd cli before flag actual
    from_cwd=$(cd "$root" && "$BASH" "$SCRIPT" --json)
    [ "$from_cwd" = "$output" ] || fail 'default current-directory root differs'
    [ "$(cd "$root" && "$BASH" "$SCRIPT")" = 'No workflow state inconsistencies found.' ] || fail 'wrong clean text output'
    cli=$(cd "$root" && "$BASH" "$SCRIPT" --root=. --json)
    [ "$cli" = "$output" ] || fail '--root=. differs from the default root'
    ln -s "$root" "$case_dir/root with spaces"
    before=$(snapshot)
    cli=$("$BASH" "$SCRIPT" "--root=$case_dir/root with spaces" --json)
    [ "$cli" = "$output" ] || fail '--root=PATH mishandled spaces'
    if cli=$(PATH=/nonexistent "$BASH" "$SCRIPT" --root= 2>&1); then actual=0; else actual=$?; fi
    [ "$actual" -eq 2 ] && [ -n "$cli" ] || fail 'empty --root= must report a usage error'
    if cli=$(PATH=/nonexistent "$BASH" "$SCRIPT" --root '' 2>&1); then actual=0; else actual=$?; fi
    [ "$actual" -eq 2 ] && [ -n "$cli" ] || fail 'empty --root must report a usage error'
    for flag in --help -h; do
        cli=$(PATH=/nonexistent "$BASH" "$SCRIPT" "--root=$case_dir/absent" "$flag") || fail "$flag failed"
        case "$cli" in Usage:*) ;; *) fail "$flag did not print usage" ;; esac
    done
    [ "$before" = "$(snapshot)" ] || fail 'CLI checks changed fixture files or Git state'
}
test_quotes_and_comments() {
    plan 0_root_plan.md "prefix: '0'\ndropped: '2026-01-01 — owner''s # reason' # comment\nchildren: [00_a_plan.md]\n"
    plan 00_a_plan.md 'prefix: "00"\nparent: "0_root_plan.md"\nexec_runs:\n  - "00_run"\n'
    run_log 00_run 00_a_plan.md 'status: done\n' '## Awaiting user (STOP line)\n<!-- - [ ] `bash hidden.sh` -->\n- [ ] `bash execs/scpts/<run>.sh`\n- [x] `bash completed.sh`\n## Notes\n- [ ] unrelated\n'
    check
    # Indentless lists and JSON string escapes belong to the same template subset.
    printf '%s\n' --- 'prefix: "\u0030\u0030"' 'parent: 0_root_plan.md' 'exec_runs:' '- "00_run" # indentless' --- > "$root/metds/plans/00_a_plan.md"
    printf '%s\n' --- 'run: "00_run"' 'source_plan: "\u0030\u0030_a_plan.md"' 'status: done' --- '## Awaiting user' '<!-- hidden' '- [ ] `bash hidden.sh`' '-->' '- [ ] [TBD]' '- [ ] 【待定】' > "$root/wkdrs/00_run/EXEC_LOG.md"
    check
}
test_parent_is_authoritative() {
    plan 0_root_plan.md 'children: [00_a_plan.md]\n'
    plan 1_other_plan.md ''
    plan 00_a_plan.md 'parent: 1_other_plan.md\n'
    check 1; codes_are '["parent_child_mismatch","unlisted_child"]'
}
test_missing_links_and_dependency() {
    plan 0_root_plan.md "prefix: '0'\nchildren: [00_missing_plan.md]\ndepends_on: ['99']\n"
    plan 00_orphan_plan.md 'parent: 9_missing_plan.md\n'
    check 1; has_code missing_child; has_code missing_parent; has_code missing_dependency
}
test_duplicate_filename_is_unknown() {
    plan 0_root_plan.md ''
    plan 0_root_plan.md 'dropped: 2026-01-01 — stale\n' true
    plan 00_a_plan.md 'parent: 0_root_plan.md\n'
    check 2; has_code ambiguous_plan unknowns; no_code missing_parent
}
test_parent_and_dependency_cycles() {
    plan 0_root_plan.md 'parent: 00_a_plan.md\nchildren: [00_a_plan.md]\n'
    plan 00_a_plan.md 'parent: 0_root_plan.md\nchildren: [0_root_plan.md]\n'
    check 1; has_code parent_cycle
    plan 0_root_plan.md 'children: [00_a_plan.md, 01_b_plan.md]\n'
    plan 00_a_plan.md 'prefix: "00"\nparent: 0_root_plan.md\ndepends_on: ["01"]\n'
    plan 01_b_plan.md 'prefix: "01"\nparent: 0_root_plan.md\ndepends_on: ["00"]\n'
    check 1; has_code dependency_cycle
}
test_dropped_plan_run_resolution_and_inheritance() {
    plan 0_root_plan.md 'prefix: "0"\nchildren: [00_a_plan.md]\ndropped: 2026-01-01 — stopped\n' true
    plan 00_a_plan.md 'prefix: "00"\nparent: 0_root_plan.md\nexec_runs: [00_run]\n' true
    run_log 00_run 00_a_plan.md 'status: in_progress\n' '' "$root" true
    check
    printf '\n## Awaiting user (STOP line)\n- [ ] `bash run.sh`\n' >> "$root/wkdrs/dropped/00_run/EXEC_LOG.md"
    check 1; has_code terminal_open_stop
}
test_active_dependency_on_dropped_or_abandoned() {
    graph
    plan 00_a_plan.md 'prefix: "00"\nparent: 0_root_plan.md\nexec_status: abandoned\n'
    check 1; has_code unavailable_dependency
    plan 00_a_plan.md 'prefix: "00"\nparent: 0_root_plan.md\ndropped: 2026-01-01 — stopped\n'
    check 1; has_code unavailable_dependency
}
test_done_without_run_and_missing_run() {
    plan 0_root_plan.md 'exec_status: done\n'
    check 1; has_code done_without_run
    plan 0_root_plan.md 'exec_status: done\nexec_runs: [00_missing]\n'
    check 1; has_code missing_run
}
test_source_plan_mismatch_and_missing_source() {
    plan 0_root_plan.md 'exec_runs: [00_run]\n'
    run_log 00_run other_plan.md
    run_log 01_run missing_plan.md
    check 1; codes_are '["source_plan_mismatch","missing_source_plan"]'
}
test_terminal_stop_english_chinese_and_legacy_status() {
    plan 0_root_plan.md 'exec_status: skipped\nexec_run: 00_run\n'
    run_log 00_run 0_root_plan.md 'status: in_progress\n' '## 待用户执行（红线）\n- [ ] `bash run.sh`\n'
    check 1; has_code terminal_open_stop
    plan 0_root_plan.md 'exec_runs: [00_run]\n'
    run_log 00_run 0_root_plan.md 'status: done\n' '## Awaiting user (STOP line)\n- [ ] `bash run.sh`\n'
    check 1; has_code terminal_open_stop
}
test_terminal_plan_does_not_activate_historical_stop() {
    plan 0_root_plan.md 'exec_status: done\nexec_runs: [00_old, 00_current]\n'
    run_log 00_old 0_root_plan.md 'status: in_progress\n' '## Awaiting user (STOP line)\n- [ ] `bash old.sh`\n'
    run_log 00_current 0_root_plan.md 'status: done\n'
    check
    local status
    for status in pending in_progress; do
        run_log 00_current 0_root_plan.md "status: $status\n" '## Awaiting user (STOP line)\n- [ ] `bash current.sh`\n'
        check 1; only_stop 00_current
    done
}
test_historical_run_still_checks_ownership_and_status() {
    plan 0_root_plan.md 'exec_status: done\nexec_runs: [00_old, 00_current]\n'
    run_log 00_old other_plan.md 'status: invented\n' '## Awaiting user (STOP line)\n- [ ] `bash old.sh`\n'
    write wkdrs/00_old/EXEC_LOG.md '---\nrun: 00_wrong\nsource_plan: other_plan.md\nstatus: invented\n---\n## Awaiting user\n- [ ] `bash old.sh`\n'
    run_log 00_current 0_root_plan.md 'status: done\n'
    check 2; codes_are '["run_name_mismatch","source_plan_mismatch"]'; codes_are '["unsupported_field"]' unknowns
}
test_historical_terminal_run_stop_stays_historical() {
    plan 0_root_plan.md 'exec_status: done\nexec_runs: [00_old, 00_current]\n'
    run_log 00_current 0_root_plan.md 'status: done\n'
    local status
    for status in done abandoned skipped; do
        run_log 00_old 0_root_plan.md "status: $status\n" '## Awaiting user (STOP line)\n- [ ] `bash old.sh`\n'
        check
    done
}
test_dropped_plan_only_passes_drop_state_to_current_run() {
    plan 0_root_plan.md 'children: [00_a_plan.md]\ndropped: 2026-01-01 — stopped\n' true
    plan 00_a_plan.md 'parent: 0_root_plan.md\nexec_runs: [00_old, 00_current]\n' true
    local name
    for name in 00_old 00_current; do run_log "$name" 00_a_plan.md 'status: in_progress\n' '## Awaiting user (STOP line)\n- [ ] `bash run.sh`\n' "$root" true; done
    check 1; only_stop 00_current
}
test_unknown_current_run_does_not_inherit_terminal_state() {
    local fields
    for fields in 'exec_runs: [00_run\n' 'exec_runs: [00_run]\nexec_run: 00_run\n'; do
        plan 0_root_plan.md "exec_status: done\n$fields"
        run_log 00_run 0_root_plan.md 'status: in_progress\n' '## Awaiting user (STOP line)\n- [ ] `bash run.sh`\n'
        check 2; codes_are '[]'; codes_are '["unsupported_field"]' unknowns
    done
}
test_unlisted_terminal_log_keeps_its_own_stop_check() {
    plan 0_root_plan.md 'exec_status: done\nexec_runs: [00_current]\n'
    run_log 00_current 0_root_plan.md 'status: done\n'
    run_log 00_unlisted 0_root_plan.md 'status: in_progress\n' '## Awaiting user (STOP line)\n- [ ] `bash run.sh`\n'
    check
    run_log 00_unlisted 0_root_plan.md 'status: done\n' '## Awaiting user (STOP line)\n- [ ] `bash run.sh`\n'
    check 1; only_stop 00_unlisted
}
test_unsupported_fields_are_unknown_without_false_missing_run() {
    local fields
    for fields in 'exec_runs: &runs [00_run]\n' 'exec_runs: [00_run\n' 'exec_runs:\n  bad: mapping\n' 'exec_runs: ["<run>"]\n' 'exec_runs: []\nexec_runs: [00_run]\n' 'exec_status: invented\n' 'exec_runs: [[00_run]]\n' 'exec_runs: [null]\n' 'exec_runs: [00_run]\n  - 01_run\n' 'exec_run: "unterminated\n' 'exec_run: *alias\n' 'exec_run: {run: 00_run}\n'; do
        plan 0_root_plan.md "$fields"
        check 2; has_code unsupported_field unknowns; no_code missing_run
    done
}
test_malformed_frontmatter_and_unreadable_root() {
    write metds/plans/0_root_plan.md '---\nexec_runs: []\n'
    check 2; has_code frontmatter unknowns
    local saved_root=$root
    root=$root/absent
    check 2; has_code unreadable unknowns
    root=$saved_root
}
test_unreadable_plan_is_not_reported_missing() {
    mkdir -p "$root/metds/plans/0_root_plan.md"
    plan 00_a_plan.md 'parent: 0_root_plan.md\n'
    check 2; has_code unreadable unknowns; no_code missing_parent
}
test_named_run_in_worktree() {
    plan 0_root_plan.md 'exec_runs: [00_run]\n'
    local tree=$case_dir/'worktree with spaces'
    git_fixture worktree add -qb 00_run "$tree"
    run_log 00_run 0_root_plan.md 'status: in_progress\n' '' "$tree"
    check
}
test_named_run_on_branch_and_unrelated_branch_ignored() {
    plan 0_root_plan.md 'exec_runs: [00_run]\n'
    local tree=$case_dir/'branch fixture' unrelated=$case_dir/'unrelated fixture'
    git_fixture worktree add -qb 00_run "$tree"
    run_log 00_run 0_root_plan.md 'status: in_progress\n' '' "$tree"
    git -C "$tree" add wkdrs; git -C "$tree" commit -qm 'run log'
    git_fixture worktree remove "$tree"
    git_fixture worktree add -qb user-unrelated "$unrelated"
    run_log 99_unclaimed absent_plan.md 'status: in_progress\n' '' "$unrelated"
    git -C "$unrelated" add wkdrs; git -C "$unrelated" commit -qm 'unrelated orphan'
    check
    plan 0_root_plan.md ''
    check
}
test_ambiguous_dependency_and_unsupported_drop_stay_unknown() {
    plan 0_root_plan.md 'prefix: "0"\nchildren: [00_a_plan.md, 01_b_plan.md]\n'
    plan 00_a_plan.md 'prefix: "00"\nparent: 0_root_plan.md\n'
    plan 00_a_plan.md 'prefix: "00"\nparent: 0_root_plan.md\n' true
    plan 01_b_plan.md 'prefix: "01"\nparent: 0_root_plan.md\ndepends_on: ["00"]\ndropped: false\n'
    check 2; has_code ambiguous_plan unknowns; has_code dependency_resolution unknowns; has_code unsupported_field unknowns; no_code missing_dependency
}
test_missing_worktree_is_unknown_and_does_not_claim_orphan() {
    plan 0_root_plan.md 'exec_runs: [00_run]\n'
    local tree=$case_dir/gone
    git_fixture worktree add -qb 00_run "$tree"
    mv "$tree" "$case_dir/moved"
    check 2; has_code run_resolution unknowns; no_code missing_run
}
test_no_git_cannot_prove_run_missing() {
    plan 0_root_plan.md 'exec_runs: [00_run]\n'
    mv "$root/.git" "$root/git-disabled"
    check 2; no_code missing_run; has_code run_resolution unknowns
}
for test_name in \
    test_clean_graph_and_quoted_multiline_lists \
    test_quotes_and_comments \
    test_parent_is_authoritative \
    test_missing_links_and_dependency \
    test_duplicate_filename_is_unknown \
    test_parent_and_dependency_cycles \
    test_dropped_plan_run_resolution_and_inheritance \
    test_active_dependency_on_dropped_or_abandoned \
    test_done_without_run_and_missing_run \
    test_source_plan_mismatch_and_missing_source \
    test_terminal_stop_english_chinese_and_legacy_status \
    test_terminal_plan_does_not_activate_historical_stop \
    test_historical_run_still_checks_ownership_and_status \
    test_historical_terminal_run_stop_stays_historical \
    test_dropped_plan_only_passes_drop_state_to_current_run \
    test_unknown_current_run_does_not_inherit_terminal_state \
    test_unlisted_terminal_log_keeps_its_own_stop_check \
    test_unsupported_fields_are_unknown_without_false_missing_run \
    test_malformed_frontmatter_and_unreadable_root \
    test_unreadable_plan_is_not_reported_missing \
    test_named_run_in_worktree \
    test_named_run_on_branch_and_unrelated_branch_ignored \
    test_ambiguous_dependency_and_unsupported_drop_stay_unknown \
    test_missing_worktree_is_unknown_and_does_not_claim_orphan \
    test_no_git_cannot_prove_run_missing; do
    count=$((count+1))
    case_dir=$suite/$count
    root=$case_dir/project
    mkdir -p "$root"
    git_fixture init -q
    git_fixture config user.name 'Workflow Fixture'
    git_fixture config user.email fixture@example.invalid
    write README.md 'fixture\n'
    git_fixture add README.md
    git_fixture commit -qm fixture
    "$test_name"
    printf 'ok %s - %s\n' "$count" "$test_name"
done
printf 'Passed %s workflow-state cases.\n' "$count"
