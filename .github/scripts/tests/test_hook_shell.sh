#!/usr/bin/env bash
# Run the harness hooks in a disposable project with Python blocked.
set -eu
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)/.agents/scripts/json.sh"
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
export CLAUDE_PROJECT_DIR=$project QWEN_PROJECT_DIR=$project DEVIN_PROJECT_DIR=$project
mkdir -p "$project/.agents/scripts"
cp "$repo/.agents/scripts/"* "$project/.agents/scripts/"
hosts='claude codex qwen dsh cursor kimi-code pi agy devin'
for host in $hosts; do
    if [ "$host" = pi ]; then directory=.pi/extensions/star-hooks
    elif [ "$host" = agy ]; then directory=.agy/hooks
    else directory=.$host/hooks; fi
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
    printf '%s\n' "$data" | star_json_eval "$expression" "$@" >/dev/null || fail "$expression"
}
hook_path() {
    if [ "$1" = pi ]; then hook=$project/.pi/extensions/star-hooks/$2.sh
    elif [ "$1" = agy ]; then hook=$project/.agy/hooks/$2.sh
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
payload=$(star_json_object session_id sid transcript_path "$project/sessions/session.jsonl" agent_id a1)
run 0 "$payload" "$hook" --subagent
assert_json 'if(!(equal(at(r,".hookSpecificOutput.hookEventName"),parse("\"SubagentStart\"")))) exit 1; if(!index(val(at(r,".hookSpecificOutput.additionalContext")),"/sid/subagents/agent-a1.jsonl")) exit 1'
case_ 'Claude incomplete delegate payload makes no provenance claim'
run 0 '{"agent_id":"a1"}' "$hook" --subagent
assert_json 'if(!equal(r,parse("{}"))) exit 1'
# Payload strings are data: quotes, backslashes, and shell-looking text must
# round-trip through JSON without invoking the text they carry.
model_literal='model "quoted" \ $(touch payload-executed)'
transcript_literal="$project/trace \"quoted\" \\ \$(touch payload-executed).jsonl"
for host in claude codex qwen dsh; do
    hook_path "$host" star_model_id
    case_ "$host payload extraction and JSON encoding"
    payload=$(star_json_object model "$model_literal" transcript_path "$transcript_literal")
    run 0 "$payload" "$hook"
    assert_json 'if(!(equal(at(r,".hookSpecificOutput.hookEventName"),parse("\"SessionStart\"")) && (type(at(r,".hookSpecificOutput.additionalContext"))=="string"))) exit 1'
    if [ "$host" = codex ]; then
        assert_json 'if(!index(val(at(r,".hookSpecificOutput.additionalContext")),a(1))) exit 1' "session_model_id = $model_literal"
    elif [ "$host" = dsh ]; then
        assert_json 'if(!index(val(at(r,".hookSpecificOutput.additionalContext")),a(1))) exit 1' "$transcript_literal"
    else
        # The injected resolver command carries its arguments shell-quoted.
        printf -v quoted_transcript '%q' "$transcript_literal"
        printf -v quoted_model '%q' "$model_literal"
        assert_json 'if(!index(val(at(r,".hookSpecificOutput.additionalContext")),a(1) " " a(2))) exit 1' "$quoted_transcript" "$quoted_model"
    fi
    case_ "$host absent model and transcript remain unrecorded"
    run 0 '{}' "$hook"
    assert_json 'if(!index(val(at(r,".hookSpecificOutput.additionalContext")),"unrecorded")) exit 1'
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
for template in code_review_template.md code_review_template_zh.md; do
    sed 's/model_id: <[^>]*>/model_id: gpt-current/' \
        "$repo/.agents/skills/star-code-reviewer/assets/$template" > "$project/artifact"
    case_ "Codex verifies rendered review template $template"
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
assert_json 'if(!index(val(at(r,".additional_context")),"cursor-exact") || index(val(at(r,".additional_context")),"cursor-generic")) exit 1'
case_ 'Cursor falls back to model'
run 0 '{"model_id":null,"model":"cursor-fallback"}' "$hook"
assert_json 'if(!index(val(at(r,".additional_context")),"cursor-fallback")) exit 1'
case_ 'Cursor missing model remains unrecorded'
run 0 '{}' "$hook"
assert_json 'if(!index(val(at(r,".additional_context")),"unrecorded")) exit 1'
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
        cursor) assert_json 'if(!index(val(at(r,".additional_context")),a(1))) exit 1' "$summary" ;;
        agy) assert_json 'if(!index(val(at(r,".injectSteps[0].systemMessage.systemMessage")),a(1))) exit 1' "$summary" ;;
        kimi-code|pi) assert_contains "$summary" ;;
        *) assert_json 'if(!(equal(at(r,".hookSpecificOutput.hookEventName"),parse("\"SessionStart\"")))) exit 1; if(!index(val(at(r,".hookSpecificOutput.additionalContext")),a(1))) exit 1' "$summary" ;;
    esac
done
hook_path claude star_memory
case_ 'Claude delegate receives memory with SubagentStart event'
run 0 '{}' "$hook" --subagent
assert_json 'if(!(equal(at(r,".hookSpecificOutput.hookEventName"),parse("\"SubagentStart\"")))) exit 1'
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
level_payload=$(star_json_object transcript_path "$project/involve.jsonl")
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
    payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$project/src/quoted file.txt")
    run 0 "$payload" "$hook"
    assert_json 'if(!(equal(at(r,".hookSpecificOutput.permissionDecision"),parse("\"allow\"")))) exit 1'
    for edited in "$project/.env" "$project/src/../outside" "$sandbox/outside"; do
        case_ "$host edit gate leaves protected or outside path undecided"
        payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$edited")
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
payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "$patch")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".hookSpecificOutput.hookEventName"),parse("\"PermissionRequest\"")) && equal(at(r,".hookSpecificOutput.decision.behavior"),parse("\"allow\"")))) exit 1'
for patch in '*** Delete File: src/example.sh' '*** Update File: .env' '*** Update File: src/../../outside'; do
    case_ 'Codex patch gate leaves deletion or protected paths undecided'
    payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "$patch")
    run 0 "$payload" "$hook"
    assert_equal ''
done
hook_path agy star_model_id
write agy.jsonl '{"step_index":0,"type":"USER_INPUT","content":"hi"}
{"step_index":1,"type":"PLANNER_RESPONSE","model":"gemini-4-old"}
{"step_index":2,"type":"PLANNER_RESPONSE","model":"gemini-4-live"}
{"step_index":3,"type":"PLANNER_RESPONSE","model":"auto"}'
case_ 'Antigravity --resolve reads the latest concrete PLANNER_RESPONSE model'
run 0 '' "$hook" --resolve "$project/agy.jsonl" gemini-4-old
assert_equal gemini-4-live
case_ 'Antigravity --resolve recovers concrete model when session started as auto'
run 0 '' "$hook" --resolve "$project/agy.jsonl" auto
assert_equal gemini-4-live
case_ 'Antigravity --resolve falls back to concrete session model when transcript is unreadable'
run 0 '' "$hook" --resolve "$project/absent" gemini-4-fallback
assert_equal gemini-4-fallback
case_ 'Antigravity --resolve stays empty for auto fallback when transcript is unreadable'
run 0 '' "$hook" --resolve "$project/absent" auto
assert_equal ''
case_ 'Antigravity SessionStart with transcriptPath injects shell-quoted --resolve command'
payload=$(star_json_object modelName "$model_literal" transcriptPath "$transcript_literal")
run 0 "$payload" "$hook"
printf -v quoted_transcript '%q' "$transcript_literal"
printf -v quoted_model '%q' "$model_literal"
assert_json 'if(!index(val(at(r,".injectSteps[0].systemMessage.systemMessage")),a(1) " " a(2))) exit 1' "$quoted_transcript" "$quoted_model"
case_ 'Antigravity SessionStart with auto modelName and transcriptPath still injects --resolve'
payload=$(star_json_object modelName auto transcriptPath "$project/agy.jsonl")
run 0 "$payload" "$hook"
assert_json 'if(!index(val(at(r,".injectSteps[0].systemMessage.systemMessage")),"--resolve")) exit 1; if(index(val(at(r,".injectSteps[0].systemMessage.systemMessage"))," auto ")) exit 1'
case_ 'Antigravity SessionStart injects concrete modelName via injectSteps when no transcriptPath'
run 0 '{"modelName":"gemini-4-hydrogen"}' "$hook"
assert_json 'if(type(at(r,".injectSteps[0].systemMessage.systemMessage"))!="string" || !index(val(at(r,".injectSteps[0].systemMessage.systemMessage")),"gemini-4-hydrogen")) exit 1'
case_ 'Antigravity SessionStart treats auto modelName without transcriptPath as unrecorded fallback'
run 0 '{"modelName":"auto"}' "$hook"
assert_json 'if(!index(val(at(r,".injectSteps[0].systemMessage.systemMessage")),"unrecorded")) exit 1'
case_ 'Antigravity payload extraction and JSON encoding without transcriptPath'
payload=$(star_json_object modelName "$model_literal")
run 0 "$payload" "$hook"
assert_json 'if(!index(val(at(r,".injectSteps[0].systemMessage.systemMessage")),a(1))) exit 1' "$model_literal"
case_ 'Antigravity SessionStart without modelName stays unrecorded'
run 0 '{}' "$hook"
assert_json 'if(!index(val(at(r,".injectSteps[0].systemMessage.systemMessage")),"unrecorded")) exit 1'
hook_path agy star_involve_gate
for arg_key in Path TargetFile; do
    case_ "Antigravity involve gate auto-approves a run worktree file via $arg_key"
    payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,a(1),string(a(2))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$arg_key" "${project}--wt/run1/src/example.sh")
    run 0 "$payload" "$hook"
    assert_json 'if(!(equal(at(r,".decision"),parse("\"auto_approve\"")))) exit 1'
    case_ "Antigravity involve gate leaves a worktree dot-directory undecided via $arg_key"
    payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,a(1),string(a(2))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$arg_key" "${project}--wt/run1/.env")
    run 0 "$payload" "$hook"
    assert_equal ''
done
for tool in write_file edit_file; do
    case_ "Antigravity involve gate auto-approves CLI $tool on a project file at INVOLVE=low"
    payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"Path",string(a(1))); put(tc,"name",string(a(2))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$project/src/quoted file.txt" "$tool")
    run 0 "$payload" "$hook"
    assert_json 'if(!(equal(at(r,".decision"),parse("\"auto_approve\"")))) exit 1'
done
for tool in write_to_file replace_file_content multi_replace_file_content; do
    case_ "Antigravity involve gate auto-approves IDE $tool on a project file at INVOLVE=low"
    payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"TargetFile",string(a(1))); put(tc,"name",string(a(2))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$project/src/quoted file.txt" "$tool")
    run 0 "$payload" "$hook"
    assert_json 'if(!(equal(at(r,".decision"),parse("\"auto_approve\"")))) exit 1'
done
for arg_key in Path TargetFile; do
    for edited in "$project/.env" "$project/src/../outside" "$sandbox/outside"; do
        case_ "Antigravity involve gate leaves protected or outside path undecided via $arg_key"
        payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,a(1),string(a(2))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$arg_key" "$edited")
        run 0 "$payload" "$hook"
        assert_equal ''
    done
done
case_ 'Antigravity hooks.json registers both CLI and IDE file tools'
assertions=$((assertions + 1))
grep -qF '"matcher": "write_file|edit_file|write_to_file|replace_file_content|multi_replace_file_content"' "$repo/.agents/hooks.json" || fail 'agy involve gate matcher'
# Antigravity involve gate resolves the latest /star* invocation's involve=
# token from transcriptPath, falling back to INVOLVE in .env.
write .env 'INVOLVE=medium'
write agy-involve-low.jsonl '{"type":"USER_INPUT","content":"<USER_REQUEST>\n/star-plan-executor 00 involve=low\n</USER_REQUEST>\n<ADDITIONAL_METADATA>x</ADDITIONAL_METADATA>"}'
case_ 'Antigravity involve gate honors per-invocation involve=low over INVOLVE=medium in .env'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"Path",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); put(r,"transcriptPath",string(a(2))); print json(r)' "$project/src/example.sh" "$project/agy-involve-low.jsonl")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"auto_approve\"")))) exit 1'
write agy-involve-stop.jsonl '{"type":"USER_INPUT","content":"<USER_REQUEST>\n/star-auto finish plan 00 stop=never run involve=low jobs\n</USER_REQUEST>"}'
case_ 'Antigravity involve gate ignores involve=low inside stop= text'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"Path",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); put(r,"transcriptPath",string(a(2))); print json(r)' "$project/src/example.sh" "$project/agy-involve-stop.jsonl")
run 0 "$payload" "$hook"
assert_equal ''
write agy-involve-chat.jsonl '{"type":"USER_INPUT","content":"<USER_REQUEST>\nplease explain /star-auto involve=low\n</USER_REQUEST>"}'
case_ 'Antigravity involve gate ignores non-leading /star mention in plain chat'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"Path",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); put(r,"transcriptPath",string(a(2))); print json(r)' "$project/src/example.sh" "$project/agy-involve-chat.jsonl")
run 0 "$payload" "$hook"
assert_equal ''
write agy-involve-reset.jsonl '{"type":"USER_INPUT","content":"<USER_REQUEST>\n/star-plan-executor 00 involve=low\n</USER_REQUEST>"}
{"type":"USER_INPUT","content":"<USER_REQUEST>\n/star-plan-executor 00\n</USER_REQUEST>"}'
case_ 'Antigravity involve gate falls back to .env after a later bare /star command'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"Path",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); put(r,"transcriptPath",string(a(2))); print json(r)' "$project/src/example.sh" "$project/agy-involve-reset.jsonl")
run 0 "$payload" "$hook"
assert_equal ''
write .env 'INVOLVE=low'
write agy-involve-high.jsonl '{"type":"USER_INPUT","content":"<USER_REQUEST>\n/star-plan-executor 00 involve=high\n</USER_REQUEST>"}'
case_ 'Antigravity involve gate honors per-invocation involve=high over INVOLVE=low in .env'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"Path",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); put(r,"transcriptPath",string(a(2))); print json(r)' "$project/src/example.sh" "$project/agy-involve-high.jsonl")
run 0 "$payload" "$hook"
assert_equal ''
# Devin reports no model field in its SessionStart payload; the hook tolerates a
# `model` if a future event carries one, and stays unrecorded until then.
hook_path devin star_model_id
case_ 'Devin SessionStart without model stays unrecorded'
run 0 '{"source":"startup","session_id":"devin-s1"}' "$hook"
assert_json 'if(!(equal(at(r,".hookSpecificOutput.hookEventName"),parse("\"SessionStart\"")) && index(val(at(r,".hookSpecificOutput.additionalContext")),"unrecorded"))) exit 1'
case_ 'Devin SessionStart injects a model field it happens to carry'
run 0 '{"model":"swe-2"}' "$hook"
assert_json 'if(!index(val(at(r,".hookSpecificOutput.additionalContext")),a(1))) exit 1' "swe-2"
hook_path devin star_involve_gate
case_ 'Devin involve gate approves an ordinary project file'
payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$project/src/quoted file.txt")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
for edited in "$project/.env" "$project/src/../outside" "$sandbox/outside"; do
    case_ 'Devin involve gate leaves protected or outside path undecided'
    payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$edited")
    run 0 "$payload" "$hook"
    assert_equal ''
done
hook_path devin star_bash_gate
case_ 'Devin shell gate approves ordinary inspection at INVOLVE=low'
payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "rg --files src")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
for command_text in 'rm -rf build' 'git push origin main' 'sudo make install'; do
    case_ "Devin shell gate leaves destructive or privileged command undecided: $command_text"
    payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "$command_text")
    run 0 "$payload" "$hook"
    assert_equal ''
done
# Both Devin gates take low only as the exact literal: a lookalike value, or a
# later malformed line overriding an earlier low, stays undecided.
for env_lines in 'INVOLVE=low1' 'INVOLVE=low!' 'INVOLVE=low
INVOLVE=medium' 'INVOLVE=low
INVOLVE="unterminated'; do
    write .env "$env_lines"
    for gate in star_involve_gate star_bash_gate; do
        hook_path devin "$gate"
        case_ "Devin $gate stays undecided on malformed INVOLVE: ${env_lines//$'\n'/ ; }"
        if [ "$gate" = star_involve_gate ]; then
            payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$project/src/quoted file.txt")
        else
            payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "rg --files src")
        fi
        run 0 "$payload" "$hook"
        assert_equal ''
    done
done
# The other edit gates read .env's INVOLVE the same exact way: a lookalike such
# as low1 is no level, while an exported quoted low with a comment still is.
other_gate() { # $1 = host
    hook_path "$1" star_involve_gate
    case "$1" in
        agy) payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"Path",string(a(1))); put(tc,"name",string("write_file")); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$project/src/quoted file.txt") ;;
        codex) payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" '*** Begin Patch
*** Update File: src/example.sh
@@
-old
+new
*** End Patch') ;;
        *) payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$project/src/quoted file.txt") ;;
    esac
    run 0 "$payload" "$hook"
}
for host in claude codex qwen agy; do
    write .env 'INVOLVE=low1'
    case_ "$host edit gate sets no level from a lookalike INVOLVE=low1"
    other_gate "$host"
    assert_equal ''
    write .env '  export INVOLVE="low" # comment'
    case_ "$host edit gate accepts an exported quoted low with a comment"
    other_gate "$host"
    assert_contains 'low'
done
# Quoting, export, indentation, a trailing comment and CRLF still count as low.
write .env '  export INVOLVE="low" # comment'
hook_path devin star_involve_gate
case_ 'Devin involve gate accepts an exported quoted low with a comment'
payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$project/src/quoted file.txt")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
hook_path devin star_bash_gate
case_ 'Devin shell gate accepts an exported quoted low with a comment'
payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "rg --files src")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
printf 'INVOLVE=low\r\n' > "$project/.env"
hook_path devin star_involve_gate
case_ 'Devin involve gate accepts a CRLF low'
payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "file_path" "$project/src/quoted file.txt")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
# The run's own involve= token outranks .env (conventions §7.7): the recorder keeps
# the last typed STAR command's token per session, and both gates read it first.
devin_record() { # $1 = session_id, $2 = typed prompt
    hook_path devin star_involve_record
    payload=$(star_json_new 'r=object(); put(r,"hook_event_name",string("UserPromptSubmit")); put(r,"session_id",string(a(1))); put(r,"prompt",string(a(2))); print json(r)' "$1" "$2")
    run 0 "$payload" "$hook"
    assert_equal ''
}
devin_gate() { # $1 = gate, $2 = session_id
    hook_path devin "$1"
    if [ "$1" = star_involve_gate ]; then
        payload=$(star_json_new 'r=object(); x=object(); put(x,"file_path",string(a(1))); put(r,"tool_input",x); put(r,"session_id",string(a(2))); print json(r)' "$project/src/a.txt" "$2")
    else
        payload=$(star_json_new 'r=object(); x=object(); put(x,"command",string(a(1))); put(r,"tool_input",x); put(r,"session_id",string(a(2))); print json(r)' "rg --files src" "$2")
    fi
    run 0 "$payload" "$hook"
}
write .env 'INVOLVE=low'
case_ 'Devin recorder keeps involve=high from a typed STAR command'
devin_record dv-high '/star-plan-executor 03 involve=high'
for gate in star_involve_gate star_bash_gate; do
    case_ "Devin $gate keeps its prompt under involve=high although .env says low"
    devin_gate "$gate" dv-high
    assert_equal ''
    case_ "Devin $gate in another session still reads .env's low"
    devin_gate "$gate" dv-other
    assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
done
case_ 'Devin recorder ignores a prompt that is not a STAR command'
devin_record dv-high 'thanks, carry on involve=low'
devin_gate star_involve_gate dv-high
assert_equal ''
case_ 'Devin recorder ignores a lookalike command such as /start'
devin_record dv-start '/start something involve=high'
devin_gate star_involve_gate dv-start
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
case_ 'Devin STAR command without a token hands the level back to .env'
devin_record dv-high '/star-flow-status'
devin_gate star_involve_gate dv-high
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
write .env 'INVOLVE=medium'
case_ 'Devin involve=low on the typed command approves under .env medium'
devin_record dv-low '/star-auto finish leaf 03 stop=any paid API call involve=low'
devin_gate star_involve_gate dv-low
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
case_ 'Devin token before stop= still counts, one after it is the stop line text'
devin_record dv-stop '/star-auto goal involve=low stop=ask before involve=high runs'
devin_gate star_involve_gate dv-stop
assert_json 'if(!(equal(at(r,".decision"),parse("\"approve\"")))) exit 1'
write .env 'INVOLVE=low'
case_ 'Devin hooks.v1.json registers the involve recorder on UserPromptSubmit'
assertions=$((assertions + 1))
star_json_eval 'x=at(r,"UserPromptSubmit.0.hooks.0.command"); if(!index(val(x),".devin/hooks/star_involve_record.sh")) exit 1' < "$repo/.devin/hooks.v1.json" >/dev/null || fail 'devin recorder registration'
case_ 'Devin hooks.v1.json registers its own hook copies on the documented matchers'
assertions=$((assertions + 1))
grep -qF '"matcher": "^exec$"' "$repo/.devin/hooks.v1.json" || fail 'devin exec matcher is not anchored'
assertions=$((assertions + 1))
grep -qF '"matcher": "^(edit|write|notebook_edit)$"' "$repo/.devin/hooks.v1.json" || fail 'devin edit matcher is not anchored'
assertions=$((assertions + 1))
grep -qF '.devin/hooks/star_commit_guard.sh' "$repo/.devin/hooks.v1.json" || fail 'devin guard registration'
hook_path claude star_bash_gate
case_ 'Claude shell gate allows ordinary inspection'
run 0 '{"tool_input":{"command":"rg --files src"}}' "$hook"
assert_json 'if(!(equal(at(r,".hookSpecificOutput.permissionDecision"),parse("\"allow\"")))) exit 1'
heredoc_in_quotes='echo "use cat <<EOF for that"
rm -rf wkdrs/old'
for command_text in 'rm old-file' 'git push origin main' 'sudo make install' 'find . -delete' \
    'if true; then git push origin main; fi' '{ rm -rf build; }' 'for f in a b; do rm -f "$f"; done' \
    'if rm -rf build; then echo ok; fi' '! rm -rf build' "$heredoc_in_quotes"; do
    case_ "Claude shell gate leaves destructive or privileged command undecided: $command_text"
    payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "$command_text")
    run 0 "$payload" "$hook"
    assert_equal ''
done
# Guard payloads are parsed but never run. Exercise each host envelope, several
# existing refusals, ordinary named staging, and the missing-review launch gate.
write wkdrs/run/EXEC_LOG.md '## Notes'
for host in $hosts; do
    hook_path "$host" star_commit_guard
    for command_text in 'git add -A' 'git rebase main' 'git reset --hard' 'git branch -D research' 'bash execs/scpts/run.sh' \
        'env git add -A' '{ git add -A; }' 'if true; then git add -A; fi' 'git stage -A' 'echo x | xargs git add -A' \
        'GIT_DIR=.git git commit --amend' 'time git rebase main' 'git add ./' 'git checkout -fB main origin/main' \
        'git switch -fC topic' 'git worktree remove -ff ../tree' 'timeout 12h bash execs/scpts/run.sh' \
        'source execs/scpts/run.sh' '. execs/scpts/run.sh' 'sudo bash execs/scpts/run.sh' 'echo go 1>wkdrs/run/.await' \
        'git commit -m wip --amend' 'git commit -m "fix(scope): x" --amend' 'git commit -m "a; b" -a' \
        'bash -c "git add -A; echo done"'; do
        case_ "$host guard declines $command_text"
        case "$host" in
            cursor) expected=2; payload=$(star_json_object command "$command_text") ;;
            pi) expected=1; payload='' ;;
            agy) expected=0; payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"CommandLine",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$command_text") ;;
            *) expected=0; payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "$command_text") ;;
        esac
        [ "$host" = devin ] && expected=2
        if [ "$host" = pi ]; then run "$expected" '' "$hook" "$command_text"
        else run "$expected" "$payload" "$hook"; fi
        case "$host" in
            cursor) assert_json 'if(!(equal(at(r,".permission"),parse("\"deny\"")) && (length(val(at(r,".agent_message")))>0))) exit 1' ;;
            pi) assert_contains declined ;;
            agy) assert_json 'if(!(equal(at(r,".decision"),parse("\"deny\"")) && (length(val(at(r,".reason")))>0))) exit 1' ;;
            devin) assert_json 'if(!(equal(at(r,".decision"),parse("\"block\"")) && (length(val(at(r,".reason")))>0))) exit 1' ;;
            *) assert_json 'if(!(equal(at(r,".hookSpecificOutput.permissionDecision"),parse("\"deny\"")))) exit 1' ;;
        esac
    done
    for command_text in 'git add src/example.sh; touch payload-executed' 'git add :/docs/example.md' \
        'git commit -uall -m message' 'git commit -Sabc123 -m message' 'bash -n execs/scpts/run.sh' \
        'git commit -m "fix(scope): keep -a and --amend; out"'; do
        case_ "$host guard permits $command_text without executing payload"
        if [ "$host" = pi ]; then run 0 '' "$hook" "$command_text"
        else
            if [ "$host" = cursor ]; then payload=$(star_json_object command "$command_text")
            elif [ "$host" = agy ]; then payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"CommandLine",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "$command_text")
            else payload=$(star_json_new 'r=object(); x=object(); put(x,a(1),string(a(2))); put(r,"tool_input",x); print json(r)' "command" "$command_text"); fi
            run 0 "$payload" "$hook"
        fi
        assert_equal ''
    done
done
# Devin's exec input may name the directory the command runs in (workdir). The
# 10 MB check must read that checkout, and fall back to the project root without it.
hook_path devin star_commit_guard
big_tree=$sandbox/devin-big
git init -q "$big_tree"
dd if=/dev/zero of="$big_tree/big.bin" bs=1048576 count=11 2>/dev/null
git -C "$big_tree" add big.bin
case_ 'Devin guard sizes the commit in tool_input.workdir'
payload=$(star_json_new 'r=object(); x=object(); put(x,"command",string(a(1))); put(x,"workdir",string(a(2))); put(r,"tool_input",x); print json(r)' "git commit -m big" "$big_tree")
run 2 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"block\"")) && index(val(at(r,".reason")),"10 MB"))) exit 1'
case_ 'Devin guard without workdir reads the project root'
payload=$(star_json_new 'r=object(); x=object(); put(x,"command",string(a(1))); put(r,"tool_input",x); print json(r)' "git commit -m big")
run 0 "$payload" "$hook"
assert_equal ''
# A commit's message options carry values, and its `--` ends option parsing:
# the pathspecs after them still reach the 10 MB check, while message text that
# spells a flag is not read as one. No commit payload is ever run.
pathspec_tree=$sandbox/devin-pathspec
git init -q "$pathspec_tree"
# The staged blob is small; what a pathspec commit records is the working copy.
printf 'small\n' > "$pathspec_tree/big.bin"
git -C "$pathspec_tree" add big.bin
dd if=/dev/zero of="$pathspec_tree/big.bin" bs=1048576 count=11 2>/dev/null
printf 'small\n' > "$pathspec_tree/small.txt"
case_ 'Devin guard sizes an unstaged pathspec after a separated message'
payload=$(star_json_new 'r=object(); x=object(); put(x,"command",string(a(1))); put(x,"workdir",string(a(2))); put(r,"tool_input",x); print json(r)' 'git commit -m "two words" -- big.bin' "$pathspec_tree")
run 2 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"block\"")) && index(val(at(r,".reason")),"10 MB"))) exit 1'
case_ 'Devin guard sizes an unstaged pathspec after an attached message'
payload=$(star_json_new 'r=object(); x=object(); put(x,"command",string(a(1))); put(x,"workdir",string(a(2))); put(r,"tool_input",x); print json(r)' 'git commit -m"two words" -- big.bin' "$pathspec_tree")
run 2 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"block\"")) && index(val(at(r,".reason")),"10 MB"))) exit 1'
case_ 'Devin guard ignores flag text inside a commit message'
payload=$(star_json_new 'r=object(); x=object(); put(x,"command",string(a(1))); put(x,"workdir",string(a(2))); put(r,"tool_input",x); print json(r)' 'git commit -m "has --amend text" small.txt' "$pathspec_tree")
run 0 "$payload" "$hook"
assert_equal ''
# Antigravity CLI passes the working directory in common top-level cwd (no Cwd
# arg on run_command), while IDE surfaces may pass toolCall.args.Cwd.
hook_path agy star_commit_guard
case_ 'Antigravity guard sizes the commit in toolCall.args.Cwd'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"CommandLine",string(a(1))); put(args,"Cwd",string(a(2))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "git commit -m big" "$big_tree")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"deny\"")) && index(val(at(r,".reason")),"10 MB"))) exit 1'
case_ 'Antigravity guard sizes the commit in top-level cwd when Cwd is absent'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"CommandLine",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); put(r,"cwd",string(a(2))); print json(r)' "git commit -m big" "$big_tree")
run 0 "$payload" "$hook"
assert_json 'if(!(equal(at(r,".decision"),parse("\"deny\"")) && index(val(at(r,".reason")),"10 MB"))) exit 1'
case_ 'Antigravity guard without Cwd or cwd reads the project root'
payload=$(star_json_new 'r=object(); tc=object(); args=object(); put(args,"CommandLine",string(a(1))); put(tc,"args",args); put(r,"toolCall",tc); print json(r)' "git commit -m big")
run 0 "$payload" "$hook"
assert_equal ''
case_ 'Payload commands were never executed'
assertions=$((assertions + 1))
[ ! -e "$project/payload-executed" ] || fail 'hook executed payload text'
case_ 'No Python runtime was invoked'
assertions=$((assertions + 1))
[ ! -e "$PYTHON_PROBE_LOG" ] || fail "Python invoked: $(cat "$PYTHON_PROBE_LOG")"
printf 'PASS: %s cases, %s assertions\n' "$cases" "$assertions"
