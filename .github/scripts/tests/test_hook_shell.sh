#!/usr/bin/env bash
# Run the seven hosts' hooks in a disposable project with Python blocked.
set -eu
repo=$(cd "$(dirname "$0")/../../.." && pwd -P)
sandbox=$(mktemp -d "${TMPDIR:-/tmp}/star-hook-tests.XXXXXX")
trap 'rm -rf "$sandbox"' EXIT
project=$sandbox/project
mkdir -p "$project" "$sandbox/bin" "$sandbox/tmp" "$sandbox/kimi"
export PYTHON_PROBE_LOG=$sandbox/python.log
for executable in python python3; do
    cat > "$sandbox/bin/$executable" <<'BLOCK'
#!/bin/sh
printf '%s\n' "$0 $*" >> "$PYTHON_PROBE_LOG"
exit 97
BLOCK
    chmod +x "$sandbox/bin/$executable"
done
export PATH="$sandbox/bin:$PATH"
export TMPDIR=$sandbox/tmp
export KIMI_CODE_HOME=$sandbox/kimi
export CLAUDE_PROJECT_DIR=$project QWEN_PROJECT_DIR=$project
hosts='claude codex qwen dsh cursor kimi-code pi'
for host in $hosts; do
    if [ "$host" = pi ]; then directory=.pi/extensions/star-hooks; else directory=.$host/hooks; fi
    mkdir -p "$project/$directory"
    cp "$repo/$directory/"*.sh "$project/$directory/"
done
cases=0 assertions=0 name=setup data=''
case_() { cases=$((cases + 1)); name=$*; }
fail() { printf 'FAIL %s: %s\n%s\n' "$name" "$*" "$data" >&2; exit 1; }
assert_equal() { assertions=$((assertions + 1)); [ "$data" = "$1" ] || fail "expected: $1"; }
assert_contains() { assertions=$((assertions + 1)); case "$data" in *"$1"*) ;; *) fail "missing: $1" ;; esac; }
assert_json() {
    local expression=$1
    shift
    assertions=$((assertions + 1))
    printf '%s\n' "$data" | jq -e "$@" "$expression" >/dev/null || fail "$expression"
}
hook_path() {
    if [ "$1" = pi ]; then hook=$project/.pi/extensions/star-hooks/$2.sh
    else hook=$project/.$1/hooks/$2.sh; fi
}
run() {
    local expected=$1 input=$2 script=$3 status=0
    shift 3
    data=$(cd "$project" && printf '%s' "$input" | "$BASH" "$script" "$@" 2> "$sandbox/stderr") || status=$?
    assertions=$((assertions + 1))
    [ "$status" -eq "$expected" ] || fail "exit $status, expected $expected: $(cat "$sandbox/stderr")"
}
write() { mkdir -p "$(dirname "$project/$1")"; printf '%s\n' "$2" > "$project/$1"; }
# Claude reads the last main assistant, skips synthetic/sidechain models, and
# retains a session suffix only when it describes the same model.
write claude.jsonl '{"type":"assistant","message":{"model":"claude-old"}}
{"type":"assistant","message":{"model":"claude-current"}}
{"type":"assistant","isSidechain":true,"message":{"model":"delegate-other"}}
{"type":"assistant","message":{"model":"<synthetic>"}}'
hook_path claude star_model_id
case_ 'Claude live transcript wins over stale session model'
run 0 '' "$hook" --resolve "$project/claude.jsonl" claude-old
assert_equal claude-current
case_ 'Claude preserves matching session context suffix'
run 0 '' "$hook" --resolve "$project/claude.jsonl" 'claude-current[1m]'
assert_equal 'claude-current[1m]'
case_ 'Claude unreadable transcript uses exact session fallback'
run 0 '' "$hook" --resolve "$project/absent" 'claude-fallback[1m]'
assert_equal 'claude-fallback[1m]'
write sessions/sid/subagents/workflows/wf_one/agent-a1.jsonl '{"type":"assistant","isSidechain":true,"message":{"model":"claude-delegate"}}'
case_ 'Claude delegate resolves workflow layout and sidechain turns'
run 0 '' "$hook" --resolve "$project/sessions/sid/subagents/agent-a1.jsonl"
assert_equal claude-delegate
case_ 'Claude subagent payload points at its own transcript'
payload=$(jq -nc --arg p "$project/sessions/session.jsonl" '{session_id:"sid",transcript_path:$p,agent_id:"a1"}')
run 0 "$payload" "$hook" --subagent
assert_json '.hookSpecificOutput.hookEventName=="SubagentStart" and (.hookSpecificOutput.additionalContext|contains("/sid/subagents/agent-a1.jsonl"))'
case_ 'Claude incomplete delegate payload makes no provenance claim'
run 0 '{"agent_id":"a1"}' "$hook" --subagent
assert_json '. == {}'
# Payload strings are data: quotes, backslashes, and shell-looking text must
# round-trip through JSON without invoking the text they carry.
model_literal='model "quoted" \ $(touch payload-executed)'
transcript_literal="$project/trace \"quoted\" \\ \$(touch payload-executed).jsonl"
for host in claude codex qwen dsh; do
    hook_path "$host" star_model_id
    case_ "$host payload extraction and JSON encoding"
    payload=$(jq -nc --arg model "$model_literal" --arg path "$transcript_literal" '{model:$model,transcript_path:$path}')
    run 0 "$payload" "$hook"
    assert_json '.hookSpecificOutput.hookEventName=="SessionStart" and (.hookSpecificOutput.additionalContext|type=="string")'
    if [ "$host" = codex ]; then
        assert_json '.hookSpecificOutput.additionalContext|contains($value)' --arg value "session_model_id = $model_literal"
    else assert_json '.hookSpecificOutput.additionalContext|contains($value)' --arg value "$transcript_literal"; fi
    case_ "$host absent model and transcript remain unrecorded"
    run 0 '{}' "$hook"
    assert_json '.hookSpecificOutput.additionalContext|contains("unrecorded")'
done
# Codex resolves turn_context records and checks all registered artifact headers.
write codex.jsonl '{"type":"turn_context","payload":{"model":"gpt-old"}}
{"type":"assistant","message":{"model":"ignored"}}
{"type":"turn_context","payload":{"model":"gpt-current"}}'
hook_path codex star_model_id
case_ 'Codex live turn_context overrides stale session model'
run 0 '' "$hook" --resolve "$project/codex.jsonl" gpt-old
assert_equal gpt-current
case_ 'Codex preserves matching session suffix'
run 0 '' "$hook" --resolve "$project/codex.jsonl" 'gpt-current[large]'
assert_equal 'gpt-current[large]'
for shape in yaml html markdown; do
    case "$shape" in
        yaml) text='---
model_id: gpt-current
---' ;;
        html) text='<!-- model_id: gpt-current -->' ;;
        markdown) text='- **model_id**: `gpt-current`' ;;
    esac
    write artifact "$text"
    case_ "Codex verifies $shape model metadata"
    run 0 '' "$hook" --check "$project/artifact" "$project/codex.jsonl" gpt-old
    assert_equal ''
done
case_ 'Codex rejects mismatched model metadata'
write artifact 'model_id: gpt-old'
run 1 '' "$hook" --check "$project/artifact" "$project/codex.jsonl" gpt-old
assertions=$((assertions + 1))
grep -q 'model_id mismatch' "$sandbox/stderr" || fail 'missing mismatch diagnostic'
case_ 'Codex missing transcript uses session model'
run 0 '' "$hook" --resolve "$project/absent" gpt-fallback
assert_equal gpt-fallback
# Qwen's assistant model is top-level, unlike Claude's nested field.
write qwen.jsonl '{"type":"assistant","model":"qwen-old"}
{"type":"user","model":"ignored"}
{"type":"assistant","model":"qwen-current"}'
hook_path qwen star_model_id
case_ 'Qwen uses last assistant model'
run 0 '' "$hook" --resolve "$project/qwen.jsonl" qwen-start
assert_equal qwen-current
case_ 'Qwen missing transcript uses session fallback'
run 0 '' "$hook" --resolve "$project/absent" qwen-fallback
assert_equal qwen-fallback
# DSH accepts both route shapes and skips non-JSON packed/tail records.
write dsh.jsonl '{"type":"request/context","data":{"provider":"old","model":"old"}}
packed non-json chunk
{"type":"request/header","data":{"header":{"config":{"provider":"deepseek","model":"deepseek-new"}}}}
partial tail'
hook_path dsh star_model_id
case_ 'DSH last route handles header shape and invalid lines'
run 0 '' "$hook" --resolve "$project/dsh.jsonl"
assert_equal deepseek/deepseek-new
case_ 'DSH resolves environment-provided session path'
export DSH_SESSION_JSONL=$project/dsh.jsonl
run 0 '' "$hook" --resolve
assert_equal deepseek/deepseek-new
unset DSH_SESSION_JSONL
case_ 'DSH context route without provider uses model verbatim'
write dsh.jsonl '{"type":"request/context","data":{"model":"direct-model"}}'
run 0 '' "$hook" --resolve "$project/dsh.jsonl"
assert_equal direct-model
case_ 'DSH missing session path yields no invented model'
run 0 '' "$hook" --resolve "$project/absent"
assert_equal ''
# Cursor uses its own lower-case output envelope and prefers model_id.
hook_path cursor star_model_id
case_ 'Cursor model_id takes precedence'
run 0 '{"model_id":"cursor-exact","model":"cursor-generic"}' "$hook"
assert_json '.additional_context|contains("cursor-exact") and (contains("cursor-generic")|not)'
case_ 'Cursor falls back to model'
run 0 '{"model_id":null,"model":"cursor-fallback"}' "$hook"
assert_json '.additional_context|contains("cursor-fallback")'
case_ 'Cursor missing model remains unrecorded'
run 0 '{}' "$hook"
assert_json '.additional_context|contains("unrecorded")'
# Kimi reads only a disposable KIMI_CODE_HOME and places dedup markers in TMPDIR.
printf '%s\n' 'default_model = "kimi-test-model" # fixture' > "$KIMI_CODE_HOME/config.toml"
hook_path kimi-code star_model_id
case_ 'Kimi configured model injects plain provenance'
run 0 '{"session_id":"model-session"}' "$hook"
assert_contains 'configured default model kimi-test-model'
case_ 'Kimi model injection deduplicates the session'
run 0 '{"session_id":"model-session"}' "$hook"
assert_equal ''
case_ 'Kimi missing session id still injects on repeated calls'
run 0 '{}' "$hook"
assert_contains kimi-test-model
run 0 '{}' "$hook"
assert_contains kimi-test-model
case_ 'Kimi absent test config remains unrecorded'
mv "$KIMI_CODE_HOME/config.toml" "$KIMI_CODE_HOME/config.saved"
run 0 '{"session_id":"missing-config"}' "$hook"
assert_contains 'no Kimi default model'
# Pi takes an argument and returns plain text.
hook_path pi star_model_id
case_ 'Pi preserves runtime model text'
run 0 '' "$hook" "$model_literal"
assert_contains "$model_literal"
case_ 'Pi missing model remains unrecorded'
run 0 '' "$hook"
assert_contains unrecorded
# All seven memory copies derive the fixture project root from their own paths.
for host in $hosts; do
    hook_path "$host" star_memory
    case_ "$host empty memory is silent"
    run 0 '{}' "$hook"
    assert_equal ''
done
summary='Use "quoted" paths and \ separators; $(touch payload-executed) stays text.'
write .star/memory/new.md "---
type: decision
scope: project
verified: 2099-01-01
summary: $summary
---
Owned body."
write .star/memory/old.md '---
type: env
scope: machine:test
verified: 2000-01-01
summary: Old environment
---'
write .star/memory/local/local.md '---
type: pitfall
scope: machine:test
verified: 2098-01-01
---
Fallback body sentence.'
index=''
for host in $hosts; do
    hook_path "$host" star_memory
    case_ "$host lists shared and local memory with stale flags"
    run 0 '' "$hook" --list
    assert_contains 'Shared (.star/memory/):'
    assert_contains 'Machine-local (.star/memory/local/):'
    assert_contains "$summary"
    assert_contains 'Fallback body sentence.'
    assert_contains '[stale: verify before relying on it]'
    if [ -z "$index" ]; then index=$data; else assert_equal "$index"; fi
    case_ "$host injects memory in its native output format"
    run 0 '{"session_id":"memory-session"}' "$hook"
    case "$host" in
        cursor) assert_json '.additional_context|contains($summary)' --arg summary "$summary" ;;
        kimi-code|pi) assert_contains "$summary" ;;
        *) assert_json '.hookSpecificOutput.hookEventName=="SessionStart" and (.hookSpecificOutput.additionalContext|contains($summary))' --arg summary "$summary" ;;
    esac
done
hook_path claude star_memory
case_ 'Claude delegate receives memory with SubagentStart event'
run 0 '{}' "$hook" --subagent
assert_json '.hookSpecificOutput.hookEventName=="SubagentStart"'
hook_path kimi-code star_memory
case_ 'Kimi memory deduplicates its session'
run 0 '{"session_id":"memory-session"}' "$hook"
assert_equal ''
# Invoke the sourced level helper through a fixed, test-owned wrapper; payload
# data is passed as arguments, never interpolated into shell program text.
cat > "$sandbox/level.sh" <<'LEVEL'
#!/usr/bin/env bash
. "$1"
star_involve_level "$2" "$3"
LEVEL
write .env 'INVOLVE=high'
level_helper=$project/.claude/hooks/star_involve_level.sh
level_payload=$(jq -nc --arg p "$project/involve.jsonl" '{transcript_path:$p}')
case_ 'Involve defaults to project environment'
run 0 '' "$sandbox/level.sh" "$level_helper" '{}' "$project"
assert_equal high
write involve.jsonl '{"type":"user","message":{"content":"<command-name>/star-auto</command-name><command-args>plan involve=low</command-args>"}}
{"type":"user","message":{"content":"Discussion about involve=high"}}
{"type":"user","isSidechain":true,"message":{"content":"<command-name>/star-auto</command-name><command-args>plan involve=high</command-args>"}}'
case_ 'Involve uses typed STAR token and ignores discussion and sidechain'
run 0 '' "$sandbox/level.sh" "$level_helper" "$level_payload" "$project"
assert_equal low
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"star-flow-status","args":""}}]}}' >> "$project/involve.jsonl"
case_ 'Involve tokenless Skill does not reset user level'
run 0 '' "$sandbox/level.sh" "$level_helper" "$level_payload" "$project"
assert_equal low
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"star-plan-executor","args":"plan involve=medium"}}]}}' >> "$project/involve.jsonl"
case_ 'Involve follows forwarded Skill token'
run 0 '' "$sandbox/level.sh" "$level_helper" "$level_payload" "$project"
assert_equal medium
printf '%s\n' '{"type":"user","message":{"content":"<command-name>/star-flow-status</command-name><command-args></command-args>"}}' >> "$project/involve.jsonl"
case_ 'Involve next typed STAR command without token restores environment'
run 0 '' "$sandbox/level.sh" "$level_helper" "$level_payload" "$project"
assert_equal high
write involve.jsonl '{"type":"user","message":{"content":"<command-name>/star-auto</command-name><command-args>plan involve=low stop=echo involve=high more</command-args>"}}'
case_ 'Involve ignores level-looking words inside stop command'
run 0 '' "$sandbox/level.sh" "$level_helper" "$level_payload" "$project"
assert_equal low
# Edit gates allow only the registered ordinary-file shapes at low involvement.
write .env 'INVOLVE=low'
for host in claude qwen; do
    hook_path "$host" star_involve_gate
    case_ "$host edit gate allows ordinary project file"
    payload=$(jq -nc --arg p "$project/src/quoted file.txt" '{tool_input:{file_path:$p}}')
    run 0 "$payload" "$hook"
    assert_json '.hookSpecificOutput.permissionDecision=="allow"'
    for edited in "$project/.env" "$project/src/../outside" "$sandbox/outside"; do
        case_ "$host edit gate leaves protected or outside path undecided"
        payload=$(jq -nc --arg p "$edited" '{tool_input:{file_path:$p}}')
        run 0 "$payload" "$hook"
        assert_equal ''
    done
done
hook_path codex star_involve_gate
case_ 'Codex patch gate allows ordinary multiline patch'
patch='*** Begin Patch
*** Update File: src/example.sh
@@
-old
+new
*** End Patch'
payload=$(jq -nc --arg p "$patch" '{tool_input:{command:$p}}')
run 0 "$payload" "$hook"
assert_json '.hookSpecificOutput.hookEventName=="PermissionRequest" and .hookSpecificOutput.decision.behavior=="allow"'
for patch in '*** Delete File: src/example.sh' '*** Update File: .env' '*** Update File: src/../../outside'; do
    case_ 'Codex patch gate leaves deletion or protected paths undecided'
    payload=$(jq -nc --arg p "$patch" '{tool_input:{command:$p}}')
    run 0 "$payload" "$hook"
    assert_equal ''
done
hook_path claude star_bash_gate
case_ 'Claude shell gate allows ordinary inspection'
run 0 '{"tool_input":{"command":"rg --files src"}}' "$hook"
assert_json '.hookSpecificOutput.permissionDecision=="allow"'
for command_text in 'rm old-file' 'git push origin main' 'sudo make install' 'find . -delete'; do
    case_ 'Claude shell gate leaves destructive or privileged command undecided'
    payload=$(jq -nc --arg command "$command_text" '{tool_input:{command:$command}}')
    run 0 "$payload" "$hook"
    assert_equal ''
done
# Guard payloads are parsed but never run. Exercise each host envelope, several
# existing refusals, ordinary named staging, and the missing-review launch gate.
write wkdrs/run/EXEC_LOG.md '## Notes'
for host in $hosts; do
    hook_path "$host" star_commit_guard
    for command_text in 'git add -A' 'git rebase main' 'git reset --hard' 'git branch -D research' 'bash execs/scpts/run.sh'; do
        case_ "$host guard declines $command_text"
        case "$host" in
            cursor) expected=2; payload=$(jq -nc --arg c "$command_text" '{command:$c}') ;;
            pi) expected=1; payload='' ;;
            *) expected=0; payload=$(jq -nc --arg c "$command_text" '{tool_input:{command:$c}}') ;;
        esac
        if [ "$host" = pi ]; then run "$expected" '' "$hook" "$command_text"
        else run "$expected" "$payload" "$hook"; fi
        case "$host" in
            cursor) assert_json '.permission=="deny" and (.agent_message|length>0)' ;;
            pi) assert_contains declined ;;
            *) assert_json '.hookSpecificOutput.permissionDecision=="deny"' ;;
        esac
    done
    case_ "$host guard permits named staging without executing payload"
    command_text='git add src/example.sh; touch payload-executed'
    if [ "$host" = pi ]; then run 0 '' "$hook" "$command_text"
    else
        if [ "$host" = cursor ]; then payload=$(jq -nc --arg c "$command_text" '{command:$c}')
        else payload=$(jq -nc --arg c "$command_text" '{tool_input:{command:$c}}'); fi
        run 0 "$payload" "$hook"
    fi
    assert_equal ''
done
case_ 'Payload commands were never executed'
assertions=$((assertions + 1))
[ ! -e "$project/payload-executed" ] || fail 'hook executed payload text'
case_ 'No Python runtime was invoked'
assertions=$((assertions + 1))
[ ! -e "$PYTHON_PROBE_LOG" ] || fail "Python invoked: $(cat "$PYTHON_PROBE_LOG")"
printf 'PASS: %s cases, %s assertions\n' "$cases" "$assertions"
