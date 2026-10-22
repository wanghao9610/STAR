#!/usr/bin/env bash
# Record launch identity and executor receipts; never execute recorded argv.
# Requires Bash 3.2+, jq, flock (Linux) or shlock (macOS), and Unix utilities.
# Same-directory rename protects metadata from partial writes; sync flushes
# writes before cleanup. This is not a per-file/per-directory fsync guarantee.
# flock releases on process death; shlock reclaims dead local PIDs. PID reuse
# conservatively reports busy. shlock is for a local filesystem, not shared NFS.
set -e
set -o pipefail

fail() { printf 'launch state: %s\n' "$*" >&2; exit 2; }
usage() {
    case "${1:-}" in
        prepare) printf '%s\n' 'Usage: launch_state.sh prepare --run RUN --pid PID --log LOG --output OUTPUT [--output OUTPUT ...] --code-version VERSION --review-version VERSION -- COMMAND [ARG ...]' ;;
        exited) printf '%s\n' 'Usage: launch_state.sh exited --run RUN --attempt ATTEMPT --exit-code INTEGER' ;;
        acknowledge) printf '%s\n' 'Usage: launch_state.sh acknowledge --run RUN --attempt ATTEMPT --evidence FILE [--verified-output OUTPUT ...]' ;;
        inspect) printf '%s\n' 'Usage: launch_state.sh inspect --run RUN' ;;
        *) printf '%s\n' 'Usage: launch_state.sh {prepare,exited,acknowledge,inspect} [OPTIONS]' 'Record launch identity and executor receipts; never execute recorded commands.' ;;
    esac
    printf '%s\n' '  -h, --help  Show this help and exit.'
}
pid_lock='' temp_write=''
release() {
    [ -z "$temp_write" ] || rm -f "$temp_write"
    if [ -n "$pid_lock" ] && [ "$(cat "$pid_lock" 2>/dev/null)" = "$$" ]; then
        rm -f "$pid_lock"
    fi
}
trap release EXIT
trap 'exit 2' HUP INT TERM
trap 'fail "operation failed; preserve launch evidence and inspect filesystem permissions"' ERR

now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
lexical_absolute() {
    local value=$1
    case "$value" in /*) ;; *) value="$PWD_PHYSICAL/$value" ;; esac
    jq -nr --arg p "$value" '$p | split("/") | reduce .[] as $s ([]; if $s=="" or $s=="." then . elif $s==".." then .[0:-1] else .+[$s] end) | "/"+join("/")'
}
real_absolute() {
    local value=$1 resolved='' component rest target count=0
    case "$value" in /*) ;; *) value="$PWD_PHYSICAL/$value" ;; esac
    rest=${value#/}
    while [ -n "$rest" ]; do
        case "$rest" in */*) component=${rest%%/*}; rest=${rest#*/} ;; *) component=$rest; rest= ;; esac
        case "$component" in
            ''|.) continue ;;
            ..) resolved=${resolved%/*}; continue ;;
        esac
        if [ -L "$resolved/$component" ]; then
            count=$((count + 1))
            [ "$count" -le 40 ] || fail 'too many symbolic links in path'
            target=$(readlink "$resolved/$component")
            case "$target" in /*) resolved=; target=${target#/} ;; esac
            rest="$target${rest:+/$rest}"
        else
            resolved="$resolved/$component"
        fi
    done
    printf '%s\n' "${resolved:-/}"
}
atomic_write() {
    local path=$1 content=$2
    temp_write=$(mktemp "$path.XXXXXX")
    printf '%s\n' "$content" > "$temp_write"
    mv -f "$temp_write" "$path"
    temp_write=
    sync
}
# Shared field validation is applied to every receipt, including historical
# receipts. It validates the record, never the continued existence of evidence.
STATE_FILTER='
 def nonempty: type=="string" and length>0;
 def path: nonempty and startswith("/") and (test("[\\r\\n]")|not);
 def version: nonempty and (ascii_downcase | gsub("^\\s+|\\s+$";"") | IN("", "unknown", "unrecorded", "none") | not);
 def integer: type=="number" and floor==.;
 def statevalid:
 type=="object" and .schema==1 and
 (.attempt|type=="string" and test("^[0-9a-f]{32}$")) and
 (.prepared_at|nonempty) and (.cwd|path) and
 (.command_argv|type=="array" and length>0 and all(.[];type=="string")) and
 (.code_version|version) and (.review_version|version) and
 (.pid|integer and .>0) and (.log|path) and
 (.outputs|type=="array" and length>0 and all(.[];path) and (unique|length)==length);
 def receiptvalid:
 statevalid and (.exit_code|integer) and (.exited_at|nonempty) and
 (.collected_at|nonempty) and (.verification_evidence|path) and
 (.evidence_sha256|type=="string" and test("^[0-9a-f]{64}$")) and
 (.verified_outputs|type=="array" and all(.[];path) and (unique|length)==length) and
 ((.verified_outputs-.outputs)|length==0) and
 (if .exit_code==0 then .result=="collected" and ((.verified_outputs|sort)==(.outputs|sort)) else .result=="failed" end);
 def launchfields: {schema,attempt,prepared_at,cwd,command_argv,code_version,review_version,pid,log,outputs};
'
read_state() {
    local marker state first second third
    [ -f "$run/.await" ] || fail 'missing .await'
    marker=$(awk '{sub(/\r$/, ""); print}' "$run/.await")
    first=$(printf '%s\n' "$marker" | sed -n '1p')
    second=$(printf '%s\n' "$marker" | sed -n '2p')
    third=$(printf '%s\n' "$marker" | sed -n '3p')
    state=$(printf '%s\n' "$marker" | sed -n '4p')
    [ "$(printf '%s\n' "$marker" | wc -l | tr -d ' ')" = 4 ] &&
    printf '%s\n' "$state" | jq -e "$STATE_FILTER statevalid and (.pid|tostring)==\$first and .log==\$second and .outputs[0]==\$third" --arg first "$first" --arg second "$second" --arg third "$third" >/dev/null ||
        fail 'legacy or malformed .await: preserve evidence; reconcile identity explicitly'
    printf '%s\n' "$state"
}
read_exit() {
    local event
    [ -f "$run/.await.exit" ] || fail 'missing .await.exit'
    event=$(awk '{sub(/\r$/, ""); print}' "$run/.await.exit")
    printf '%s\n' "$event" | jq -e "$STATE_FILTER type==\"object\" and .attempt==\$attempt and (.exit_code|integer) and (.exited_at|nonempty)" --arg attempt "$1" >/dev/null ||
        fail 'legacy or mismatched exit: preserve evidence; reconcile identity explicitly'
    printf '%s\n' "$event"
}
receipts() {
    local records
    records=$(awk '
        {sub(/\r$/, "")}
        /^```star-launch-receipt$/ {if (inside) exit 2; inside=1; next}
        inside==1 {record=$0; inside=2; next}
        inside==2 {if ($0!="```") exit 2; print record; inside=0}
        END {if (inside) exit 2}
    ' "$run/EXEC_LOG.md") || fail 'malformed collection receipt: reconcile EXEC_LOG.md before continuing'
    printf '%s\n' "$records" | jq -ces "$STATE_FILTER all(.[];receiptvalid) and ((map(.attempt)|unique|length)==length)" >/dev/null ||
        fail 'malformed collection receipt: reconcile EXEC_LOG.md before continuing'
    printf '%s\n' "$records" | jq -cs '.'
}
validate_binding() {
    local receipt=$1 state=${2:-} event=${3:-}
    if [ -n "$state" ]; then
        jq -ne "$STATE_FILTER (\$receipt|launchfields)==(\$state|launchfields)" --argjson receipt "$receipt" --argjson state "$state" >/dev/null ||
            fail 'collection receipt does not match launch identity; preserve evidence'
    fi
    if [ -n "$event" ]; then
        jq -ne '$receipt.attempt==$event.attempt and $receipt.exit_code==$event.exit_code and $receipt.exited_at==$event.exited_at' --argjson receipt "$receipt" --argjson event "$event" >/dev/null ||
            fail 'collection receipt does not match exit evidence; preserve evidence'
    fi
}
cleanup() {
    local receipt=$1 state='' event='' attempt
    attempt=$(printf '%s\n' "$receipt" | jq -r .attempt)
    if [ -e "$run/.await" ]; then
        state=$(read_state)
        [ "$(printf '%s\n' "$state" | jq -r .attempt)" = "$attempt" ] || return 0
    fi
    if [ -e "$run/.await.exit" ]; then event=$(read_exit "$attempt"); fi
    validate_binding "$receipt" "$state" "$event"
    rm -f "$run/.await.exit"
    rm -f "$run/.await"
}

[ "$#" -gt 0 ] || fail 'operation required: prepare, exited, acknowledge, inspect'
operation=$1; shift
case "$operation" in -h|--help) usage; exit 0 ;; prepare|exited|acknowledge|inspect) ;; *) fail 'unknown operation' ;; esac
run_arg='' pid='' log_arg='' code_version='' review_version='' attempt='' exit_code='' evidence_arg=''
outputs=() verified=() command_argv=()
while [ "$#" -gt 0 ]; do
    key=$1; shift
    case "$key" in
        --run=*|--pid=*|--log=*|--output=*|--code-version=*|--review-version=*|--attempt=*|--exit-code=*|--evidence=*|--verified-output=*)
            value=${key#*=}; key=${key%%=*}; set -- "$value" "$@" ;;
    esac
    case "$key" in
        -h|--help) usage "$operation"; exit 0 ;;
        --) [ "$operation" = prepare ] || fail 'unexpected command'; command_argv=("$@"); break ;;
        --run|--pid|--log|--output|--code-version|--review-version|--attempt|--exit-code|--evidence|--verified-output)
            [ "$#" -gt 0 ] || fail "missing value for $key"
            value=$1; shift
            case "$key" in
                --run) run_arg=$value ;;
                --pid) [ "$operation" = prepare ] || fail 'unexpected --pid'; pid=$value ;;
                --log) [ "$operation" = prepare ] || fail 'unexpected --log'; log_arg=$value ;;
                --output) [ "$operation" = prepare ] || fail 'unexpected --output'; outputs+=("$value") ;;
                --code-version) [ "$operation" = prepare ] || fail 'unexpected --code-version'; code_version=$value ;;
                --review-version) [ "$operation" = prepare ] || fail 'unexpected --review-version'; review_version=$value ;;
                --attempt) [ "$operation" = exited ] || [ "$operation" = acknowledge ] || fail 'unexpected --attempt'; attempt=$value ;;
                --exit-code) [ "$operation" = exited ] || fail 'unexpected --exit-code'; exit_code=$value ;;
                --evidence) [ "$operation" = acknowledge ] || fail 'unexpected --evidence'; evidence_arg=$value ;;
                --verified-output) [ "$operation" = acknowledge ] || fail 'unexpected --verified-output'; verified+=("$value") ;;
            esac ;;
        -*) fail "unknown argument: $key" ;;
        *) [ "$operation" = prepare ] || fail "unexpected argument: $key"; command_argv=("$key" "$@"); break ;;
    esac
done
command -v jq >/dev/null 2>&1 || fail 'jq is required'
[ -n "$run_arg" ] || fail '--run is required'
PWD_PHYSICAL=$(pwd -P)
run=$(real_absolute "$run_arg")
[ -d "$run" ] && [ -f "$run/EXEC_LOG.md" ] || fail 'run must already contain EXEC_LOG.md'
if command -v flock >/dev/null 2>&1; then
    exec 9>> "$run/.await.lock"
    flock -n 9 || fail 'launch lock busy; another writer owns .await.lock'
elif command -v shlock >/dev/null 2>&1; then
    if [ -e "$run/.await.lock.pid" ]; then
        owner=$(cat "$run/.await.lock.pid")
        [[ "$owner" =~ ^[1-9][0-9]*$ ]] || fail 'launch lock owner unknown: preserve .await.lock.pid for reconciliation'
    fi
    # shlock conservatively refuses a dead PID file modified in the current
    # second. Retry once across that timestamp boundary; never unlink it here.
    if ! shlock -p "$$" -f "$run/.await.lock.pid"; then
        sleep 1
        shlock -p "$$" -f "$run/.await.lock.pid" || fail 'launch lock busy or unavailable: .await.lock.pid'
    fi
    pid_lock="$run/.await.lock.pid"
else
    fail 'flock or shlock is required for recoverable launch locking'
fi

case "$operation" in
prepare)
    [ ! -e "$run/.await" ] && [ ! -e "$run/.await.exit" ] || fail 'uncollected launch state exists; executor must acknowledge it before another attempt'
    [ "${#command_argv[@]}" -gt 0 ] && [ "${#outputs[@]}" -gt 0 ] && [ -n "$log_arg" ] && [[ "$pid" =~ ^[0-9]+$ ]] || fail 'exact command argv, positive wrapper PID, log, outputs, and explicit versions are required'
    normalized=()
    for value in "${outputs[@]}"; do normalized+=("$(lexical_absolute "$value")"); done
    output_json=$(jq -cn --args '$ARGS.positional | reduce .[] as $p ([]; if index($p) then . else .+[$p] end)' -- "${normalized[@]}")
    argv_json=$(jq -cn --args '$ARGS.positional' -- "${command_argv[@]}")
    attempt=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
    state=$(jq -cn --arg attempt "$attempt" --arg prepared_at "$(now)" --arg cwd "$PWD_PHYSICAL" --arg code_version "$code_version" --arg review_version "$review_version" --arg pid "$pid" --arg log "$(real_absolute "$log_arg")" --argjson outputs "$output_json" --argjson argv "$argv_json" '{schema:1,attempt:$attempt,prepared_at:$prepared_at,cwd:$cwd,command_argv:$argv,code_version:$code_version,review_version:$review_version,pid:($pid|tonumber),log:$log,outputs:$outputs}')
    printf '%s\n' "$state" | jq -e "$STATE_FILTER statevalid" >/dev/null || fail 'exact command argv, positive wrapper PID, one-line paths, and explicit versions are required'
    marker=$(printf '%s\n' "$state" | jq -r '.pid,.log,.outputs[0]')
    atomic_write "$run/.await" "$marker
$state"
    printf '%s\n' "$attempt"
    ;;
exited)
    [ -n "$attempt" ] && [[ "$exit_code" =~ ^-?[0-9]+$ ]] || fail '--attempt and integer --exit-code are required'
    state=$(read_state)
    [ "$(printf '%s\n' "$state" | jq -r .attempt)" = "$attempt" ] || fail 'attempt does not match active launch'
    if [ -e "$run/.await.exit" ]; then
        event=$(read_exit "$attempt")
        jq -ne --argjson event "$event" --arg code "$exit_code" '$event.exit_code==($code|tonumber)' >/dev/null || fail 'recorded exit code cannot be changed'
    else
        event=$(jq -cn --arg attempt "$attempt" --arg code "$exit_code" --arg at "$(now)" '{attempt:$attempt,exit_code:($code|tonumber),exited_at:$at}')
        atomic_write "$run/.await.exit" "$event"
    fi
    printf '%s\n' "$event"
    ;;
acknowledge)
    [ -n "$attempt" ] && [ -n "$evidence_arg" ] || fail '--attempt and --evidence are required'
    records=$(receipts)
    prior=$(printf '%s\n' "$records" | jq -c --arg attempt "$attempt" '.[] | select(.attempt==$attempt)')
    if [ -n "$prior" ]; then
        cleanup "$prior"
        jq -cn --argjson receipt "$prior" '{status:"already_collected",receipt:$receipt}'
        exit 0
    fi
    state=$(read_state)
    [ "$(printf '%s\n' "$state" | jq -r .attempt)" = "$attempt" ] || fail 'attempt does not match active launch'
    event=$(read_exit "$attempt")
    normalized=()
    for value in "${verified[@]}"; do normalized+=("$(lexical_absolute "$value")"); done
    verified_json=$(jq -cn --args '$ARGS.positional|unique' -- "${normalized[@]}")
    jq -ne --argjson state "$state" --argjson verified "$verified_json" '($verified-$state.outputs)|length==0' >/dev/null || fail 'verified output does not belong to this attempt'
    jq -ne --argjson state "$state" --argjson event "$event" --argjson verified "$verified_json" '$event.exit_code!=0 or $verified==($state.outputs|sort)' >/dev/null || fail 'successful exit requires every expected output to be explicitly verified'
    for value in "${normalized[@]}"; do [ -e "$value" ] || fail 'a verified output is missing'; done
    evidence=$(real_absolute "$evidence_arg")
    [ -f "$evidence" ] && [ "$evidence" != "$run/EXEC_LOG.md" ] || fail 'verification evidence must be a separate existing file'
    if command -v sha256sum >/dev/null 2>&1; then hash=$(sha256sum < "$evidence"); else hash=$(shasum -a 256 < "$evidence"); fi
    hash=${hash%% *}
    receipt=$(jq -cn --argjson state "$state" --argjson event "$event" --arg at "$(now)" --argjson verified "$verified_json" --arg evidence "$evidence" --arg hash "$hash" '$state+$event+{collected_at:$at,result:(if $event.exit_code==0 then "collected" else "failed" end),verified_outputs:$verified,verification_evidence:$evidence,evidence_sha256:$hash}')
    printf '\n### Launch collection %s\n\n```star-launch-receipt\n%s\n```\n' "$attempt" "$receipt" >> "$run/EXEC_LOG.md"
    sync
    cleanup "$receipt"
    jq -cn --argjson receipt "$receipt" '{status:"acknowledged",receipt:$receipt}'
    ;;
inspect)
    state=$(read_state)
    attempt=$(printf '%s\n' "$state" | jq -r .attempt)
    event='' status=waiting
    if [ -e "$run/.await.exit" ]; then event=$(read_exit "$attempt"); status=exited; fi
    records=$(receipts)
    prior=$(printf '%s\n' "$records" | jq -c --arg attempt "$attempt" '.[] | select(.attempt==$attempt)')
    if [ -n "$prior" ]; then validate_binding "$prior" "$state" "$event"; status=already_collected; fi
    jq -cn --arg status "$status" --argjson launch "$state" --argjson event "${event:-null}" '{status:$status,launch:$launch,exit:$event}'
    ;;
esac
