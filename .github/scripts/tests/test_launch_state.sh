#!/usr/bin/env bash
# Offline launch metadata regressions. Recorded commands are never executed.
set -e
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)/.agents/scripts/json.sh"
set -o pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd -P)
TOOL="$ROOT/.agents/skills/star-plan-executor/scripts/launch_state.sh"
TEMP=$(mktemp -d)
TEMP=$(cd "$TEMP" && pwd -P)
trap 'find "$TEMP" -depth -delete' EXIT
count=0
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
eq() { [ "$1" = "$2" ] || fail "${3:-values differ}: [$1] != [$2]"; }
json() { printf '%s\n' "$result" | star_json_eval "$1" >/dev/null || fail "JSON assertion: $1"; }
exists() { [ -e "$1" ] || fail "missing $1"; }
# Passes only when the pattern is searched for and not found: a missing file or
# a grep error fails too, rather than reading as absence.
lacks() { local rc=0; grep -q -- "$1" "$2" || rc=$?; [ "$rc" -eq 1 ] || fail "$3"; }
absent() { [ ! -e "$1" ] || fail "unexpected $1"; }
setup() {
    count=$((count + 1))
    run="$TEMP/case-$count"; mkdir "$run"
    output="$run/result.json"; evidence="$run/verification.txt"
    printf '# Existing execution record\n\nHistorical evidence stays.\n' > "$run/EXEC_LOG.md"
    printf 'Verified expected output against command and version.\n' > "$evidence"
}
cli() { result=$(bash "$TOOL" "$1" --run "$run" "${@:2}"); }
reject() {
    local code=0
    result=$(bash "$TOOL" "$1" --run "$run" "${@:2}" 2> "$run/error") || code=$?
    eq "$code" 2 'expected rejection'
}
prepare() {
    cli prepare --pid 123 --log "$run/raw.log" --output "$output" --code-version source:abc123 --review-version review:def456 -- bash execs/scpts/demo.sh 'literal $(touch should-not-exist); argument' ''
    attempt=$result
}
finish() { cli exited --attempt "$attempt" --exit-code "${1:-0}"; }
collect() { cli acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"; }
state() { sed -n '4p' "$run/.await"; }
snapshot() {
    cp "$run/.await" "$run/marker-before"
    cp "$run/.await.exit" "$run/exit-before"
    cp "$run/EXEC_LOG.md" "$run/log-before"
}
preserved() {
    cmp -s "$run/.await" "$run/marker-before" || fail 'marker changed on rejection'
    cmp -s "$run/.await.exit" "$run/exit-before" || fail 'exit changed on rejection'
    cmp -s "$run/EXEC_LOG.md" "$run/log-before" || fail 'execution log changed on rejection'
}
receipt_fixture() {
    prepare; printf result > "$output"; finish
    cp "$run/.await" "$run/saved-marker"
    cp "$run/.await.exit" "$run/saved-exit"
    collect
    printf '%s\n' "$result" | star_json_eval 'print json(get(r,"receipt"))' > "$run/receipt.json"
    cp "$run/saved-marker" "$run/.await"
    cp "$run/saved-exit" "$run/.await.exit"
}
replace_receipt() {
    local receipt
    receipt=$(star_json_eval "$1; print json(r)" < "$run/receipt.json")
    printf '# Existing execution record\n\nHistorical evidence stays.\n\n```star-launch-receipt\n%s\n```\n' "$receipt" > "$run/EXEC_LOG.md"
}
pass() { printf 'ok %s - %s\n' "$count" "$1"; }
crlf() { awk '{sub(/\r$/, ""); printf "%s\r\n", $0}' "$1" > "$1.converted"; mv "$1.converted" "$1"; }

setup; prepare; finish 1; snapshot
locks_before=$(find "$run" -name '.await.lock*' -type f -exec cksum {} \;)
for help_flag in -h --help; do
    result=$(bash "$TOOL" "$help_flag")
    [[ "$result" == Usage:* ]] || fail 'missing top-level help'
    for help_operation in prepare exited acknowledge inspect; do
        result=$(bash "$TOOL" "$help_operation" "$help_flag")
        [[ "$result" == "Usage: launch_state.sh $help_operation "* ]] || fail 'missing subcommand help'
        result=$(bash "$TOOL" "$help_operation" --run "$run" "$help_flag")
        [[ "$result" == "Usage: launch_state.sh $help_operation "* ]] || fail 'help with run option failed'
    done
done
preserved
eq "$(find "$run" -name '.await.lock*' -type f -exec cksum {} \;)" "$locks_before" 'help changed lock files'
pass 'top-level and subcommand help succeeds without touching launch evidence or locks'

setup; prepare; finish 1
cli acknowledge --attempt "$attempt" --evidence "$evidence"
crlf "$run/EXEC_LOG.md"; cp "$run/EXEC_LOG.md" "$run/log-collected"
cli acknowledge --attempt "$attempt" --evidence "$evidence"
json 'if(!(equal(at(r,".status"),parse("\"already_collected\"")) && equal(at(r,".receipt.exit_code"),parse("1")))) exit 1'
cmp -s "$run/EXEC_LOG.md" "$run/log-collected" || fail 'CRLF receipt history overwritten on replay'
absent "$run/.await"; absent "$run/.await.exit"
pass 'CRLF receipt history replays without a marker or rewriting the log'

setup; prepare; finish 1
crlf "$run/.await"; crlf "$run/.await.exit"; snapshot
cli inspect; json 'if(!(equal(at(r,".status"),parse("\"exited\"")) && equal(at(r,".exit.exit_code"),parse("1")))) exit 1'
reject prepare --pid 456 --log log --output out --code-version new --review-version new -- bash other
preserved
cli acknowledge --attempt "$attempt" --evidence "$evidence"
json 'if(!(equal(at(r,".status"),parse("\"acknowledged\"")) && equal(at(r,".receipt.result"),parse("\"failed\"")))) exit 1'
absent "$run/.await"; absent "$run/.await.exit"
pass 'CRLF active marker and exit remain bound and cannot be overwritten'

setup; receipt_fixture
crlf "$run/.await"; crlf "$run/.await.exit"; crlf "$run/EXEC_LOG.md"; snapshot
cli inspect; json 'if(!(equal(at(r,".status"),parse("\"already_collected\"")))) exit 1'
preserved
collect; json 'if(!(equal(at(r,".status"),parse("\"already_collected\"")))) exit 1'
cmp -s "$run/EXEC_LOG.md" "$run/log-before" || fail 'CRLF cleanup rewrote receipt history'
absent "$run/.await"; absent "$run/.await.exit"
pass 'CRLF receipt and active files support cleanup after interruption'

setup; receipt_fixture; replace_receipt 'x=object(); put(x,"attempt",get(r,"attempt")); r=x'
crlf "$run/EXEC_LOG.md"; crlf "$run/.await"; crlf "$run/.await.exit"; snapshot
reject inspect; reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"; preserved
pass 'incomplete CRLF receipt fails without altering raw launch evidence'

setup; output="$run/result with spaces.json"
mv "$evidence" "$run/verification evidence.txt"; evidence="$run/verification evidence.txt"
result=$(bash "$TOOL" prepare --run="$run" --pid=123 --log="$run/raw log.txt" --output="$output" --code-version=source:abc123 --review-version=review:def456 -- bash '--arg=value' '--run=literal' '--help')
attempt=$result
result=$(state)
json 'if(!(equal(at(r,".command_argv"),parse("[\"bash\",\"--arg=value\",\"--run=literal\",\"--help\"]")))) exit 1'
eq "$(sed -n '3p' "$run/.await")" "$output"
printf result > "$output"
result=$(bash "$TOOL" exited --run="$run" --attempt="$attempt" --exit-code=0)
json 'if(!(equal(at(r,".exit_code"),parse("0")))) exit 1'
result=$(bash "$TOOL" inspect --run="$run")
json 'if(!(equal(at(r,".status"),parse("\"exited\"")))) exit 1'
result=$(bash "$TOOL" acknowledge --run="$run" --attempt="$attempt" --evidence="$evidence" --verified-output="$output")
json 'if(!(equal(at(r,".status"),parse("\"acknowledged\"")) && equal(at(r,".receipt.result"),parse("\"collected\"")))) exit 1'
absent "$run/.await"; absent "$run/.await.exit"
pass 'equals-form options preserve spaced paths and literal command options after separator'

setup; prepare
marker=$(cat "$run/.await")
eq "$(sed -n '1p' "$run/.await")" 123
eq "$(sed -n '2p' "$run/.await")" "$run/raw.log"
eq "$(sed -n '3p' "$run/.await")" "$output"
result=$(state); json 'if(!(equal(at(r,".schema"),parse("1")) && equal(at(r,".code_version"),parse("\"source:abc123\"")) && equal(at(r,".review_version"),parse("\"review:def456\"")) && equal(at(r,".command_argv[-1]"),parse("\"\"")) && equal(at(r,".command_argv[-2]"),parse("\"literal $(touch should-not-exist); argument\"")))) exit 1'
absent "$ROOT/should-not-exist"
reject prepare --pid 456 --log log --output out --code-version new --review-version new -- bash other
eq "$(cat "$run/.await")" "$marker"
pass 'exact argv and identity; duplicate preparation preserves marker'

setup; receipt_fixture
cli inspect; json 'if(!(equal(at(r,".status"),parse("\"already_collected\"")))) exit 1'
collect; json 'if(!(equal(at(r,".status"),parse("\"already_collected\"")))) exit 1'
absent "$run/.await"; absent "$run/.await.exit"
cp "$run/EXEC_LOG.md" "$run/log-collected"
collect; cmp -s "$run/EXEC_LOG.md" "$run/log-collected" || fail 'duplicate receipt'
eq "$(awk '/^```star-launch-receipt$/{n++}END{print n}' "$run/EXEC_LOG.md")" 1
pass 'receipt persists before cleanup; repeated collection is idempotent'

setup; prepare; finish 17
cli acknowledge --attempt "$attempt" --evidence "$evidence"
json 'if(!(equal(at(r,".receipt.exit_code"),parse("17")) && equal(at(r,".receipt.result"),parse("\"failed\"")) && equal(at(r,".receipt.verified_outputs"),parse("[]")))) exit 1'
lacks 'status: done' "$run/EXEC_LOG.md" 'failed attempt marked done'
pass 'failed exit remains failed without outputs'

setup; prepare
cli inspect; json 'if(!(equal(at(r,".status"),parse("\"waiting\"")))) exit 1'
reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"
exists "$run/.await"
lacks '^```star-launch-receipt' "$run/EXEC_LOG.md" 'waiting attempt collected'
pass 'waiting cannot be collected'

setup; prepare; finish
reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"
printf result > "$output"
reject acknowledge --attempt "$attempt" --evidence "$evidence"
exists "$run/.await.exit"
pass 'missing or unverified outputs preserve state'

setup; mkdir "$run/work" "$run/outputs"
old_pwd=$PWD; cd "$run/work"; output=../outputs/latest
prepare; target="$run/result.json"; printf result > "$target"; ln -s "$target" "$output"
finish; collect
json 'if(!(equal(at(r,".receipt.outputs"),at(r,".receipt.verified_outputs")))) exit 1'
eq "$(printf '%s\n' "$result" | star_json_get 'receipt.outputs[0]')" "$run/outputs/latest"
cd "$old_pwd"
pass 'relative output symlink created after preparation keeps lexical identity'

setup; printf old > "$run/old.json"; output="$run/latest"; ln -s "$run/old.json" "$output"
prepare; unlink "$output"; printf new > "$run/new.json"; ln -s "$run/new.json" "$output"
finish; collect
eq "$(printf '%s\n' "$result" | star_json_get 'receipt.outputs[0]')" "$output"
pass 'retargeted output symlink keeps lexical identity'

setup; prepare; printf result > "$output"; finish; collect
eq "$(printf '%s\n' "$result" | star_json_get 'receipt.outputs[0]')" "$output"
pass 'normal output file keeps identity'

setup; printf result > "$run/target.json"; ln -s "$run/target.json" "$output"; prepare
ln -s "$run/target.json" "$run/unrelated"; finish
reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$run/unrelated"
exists "$run/.await.exit"
pass 'unrelated symlink to the same target is rejected'

setup; prepare; ln -s "$run/missing" "$output"; finish
reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"
exists "$run/.await.exit"
pass 'broken output symlink is rejected'

setup; prepare; first=$attempt; printf result > "$output"; finish
cp "$run/.await.exit" "$run/old-exit"; collect; prepare
[ "$attempt" != "$first" ] || fail 'attempt identity reused'
cp "$run/old-exit" "$run/.await.exit"; snapshot
reject inspect; reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"; preserved
pass 'old exit cannot satisfy new attempt'

setup; prepare; first=$attempt; printf result > "$output"; finish; collect; prepare
second=$attempt; cli acknowledge --attempt "$first" --evidence "$evidence"
eq "$(state | star_json_get attempt)" "$second"
pass 'repeated old acknowledgment cannot remove new attempt'

setup; printf '123\nraw.log\nresult.json\n' > "$run/.await"; printf '0\n' > "$run/.await.exit"; snapshot
reject inspect; reject acknowledge --attempt legacy --evidence "$evidence" --verified-output "$output"; preserved
pass 'legacy marker and plain exit are preserved'

setup; prepare; printf '0\n' > "$run/.await.exit"; printf result > "$output"; snapshot
reject inspect; reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"; preserved
pass 'plain exit cannot complete versioned attempt'

setup; receipt_fixture; unlink "$run/.await.exit"
# Historical evidence/output files may legitimately disappear after collection.
unlink "$evidence"; unlink "$output"
cli inspect; json 'if(!(equal(at(r,".status"),parse("\"already_collected\"")))) exit 1'
collect; absent "$run/.await"; collect
pass 'cleanup after exit removal uses receipt without rechecking historical files'

setup
reject prepare --pid 123 --log log --output output --code-version unknown --review-version review:abc -- bash script
absent "$run/.await"; unlink "$run/EXEC_LOG.md"; reject inspect; absent "$run/EXEC_LOG.md"
pass 'unknown versions and missing execution log are rejected'

setup; prepare
reject exited --attempt wrong --exit-code 0
finish 3; finish 3; reject exited --attempt "$attempt" --exit-code 0
eq "$(star_json_get exit_code < "$run/.await.exit")" 3
pass 'exit identity is checked and exit code is immutable'

# Every malformed receipt must fail both inspection and acknowledgment before
# either marker, exit evidence, or the execution log can change.
for mutation in \
    'x=object(); put(x,"attempt",get(r,"attempt")); r=x' \
    'x=object(); for(i=1;i<=size(r);i++) {key=keys[r,i]; if(key!="schema") put(x,key,get(r,key))}; r=x' \
    'put(r,"schema",parse("\"1\""))' \
    'put(r,"command_argv",parse("\"bash\""))' \
    'put(r,"pid",parse("\"123\""))' \
    'put(r,"outputs",parse("[17]"))' \
    'put(r,"exit_code",parse("\"0\""))' \
    'put(r,"result",parse("\"failed\""))' \
    'put(r,"verified_outputs",parse("[]"))' \
    'put(r,"verified_outputs",parse("[\"/unrelated\"]"))' \
    'put(r,"verification_evidence",parse("null"))' \
    'put(r,"evidence_sha256",parse("\"bad\""))' \
    'x=object(); for(i=1;i<=size(r);i++) {key=keys[r,i]; if(key!="exited_at") put(x,key,get(r,key))}; r=x' \
    'put(r,"collected_at",parse("17"))' \
    'put(r,"code_version",parse("\"unknown\""))' \
    'put(r,"review_version",parse("null"))' \
    'put(r,"prepared_at",parse("false"))' \
    'put(r,"cwd",parse("\"relative\""))'; do
    setup; receipt_fixture; replace_receipt "$mutation"; snapshot
    reject inspect; reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"; preserved
    pass "invalid receipt preserves all evidence: $mutation"
done

for mutation in 'put(r,"code_version",parse("\"source:other\""))' 'put(r,"exit_code",parse("17")); put(r,"result",parse("\"failed\""))' 'put(r,"exited_at",parse("\"different\""))'; do
    setup; receipt_fixture; replace_receipt "$mutation"; snapshot
    reject inspect; reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"; preserved
    pass "receipt binding mismatch preserves all evidence: $mutation"
done

setup; receipt_fixture; printf '\n```star-launch-receipt\n{"attempt":"broken"}\n' >> "$run/EXEC_LOG.md"; snapshot
reject inspect; reject acknowledge --attempt "$attempt" --evidence "$evidence" --verified-output "$output"; preserved
pass 'truncated receipt block is rejected'

setup; prepare; printf result > "$output"; finish
cp "$run/.await.exit" "$run/saved-exit"; collect
cp "$run/saved-exit" "$run/.await.exit"
collect; absent "$run/.await.exit"
pass 'cleanup recovers with only exit evidence remaining'

setup; prepare
if command -v flock >/dev/null 2>&1; then
    # A real lock holder dies by SIGKILL; the kernel must release its lock.
    bash -c 'exec 9>> "$1/.await.lock"; flock 9; printf ready > "$1/ready"; while :; do read -r -t 1 unused || :; done' _ "$run" & holder=$!
    for wait_iteration in $(seq 1 100); do [ ! -f "$run/ready" ] || break; sleep 0.02; done
    exists "$run/ready"; reject inspect; kill -KILL "$holder"; wait "$holder" 2>/dev/null || :
    cli inspect; json 'if(!(equal(at(r,".status"),parse("\"waiting\"")))) exit 1'
else
    printf '%s\n' "$$" > "$run/.await.lock.pid"
    reject inspect; eq "$(cat "$run/.await.lock.pid")" "$$"
    # Use a real exited child's PID rather than guessing a high unused PID.
    bash -c 'exit 0' & dead_pid=$!; wait "$dead_pid"
    printf '%s\n' "$dead_pid" > "$run/.await.lock.pid"
    cli inspect; json 'if(!(equal(at(r,".status"),parse("\"waiting\"")))) exit 1'; absent "$run/.await.lock.pid"
fi
pass 'active writer blocks access; dead owner lock is recovered'

if ! command -v flock >/dev/null 2>&1; then
    setup; prepare; printf 'unknown\n' > "$run/.await.lock.pid"
    reject inspect; eq "$(cat "$run/.await.lock.pid")" unknown
    pass 'unknown lock owner is preserved and reported'
fi
printf 'PASS: %s launch-state shell regression cases\n' "$count"
