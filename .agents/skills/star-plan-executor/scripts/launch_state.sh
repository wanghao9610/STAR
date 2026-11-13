#!/usr/bin/env bash
# Record launch identity and executor receipts; never execute recorded argv.
# Requires Bash 3.2+, awk, flock (Linux) or shlock (macOS), and Unix utilities.
# Same-directory rename protects metadata from partial writes; sync flushes
# writes before cleanup. This is not a per-file/per-directory fsync guarantee.
# flock releases on process death; shlock reclaims dead local PIDs. PID reuse
# conservatively reports busy. shlock is for a local filesystem, not shared NFS.
set -e
set -o pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../.agents/scripts/json.sh"
LAUNCH_JSON=$(cat "${STAR_JSON_LIB%/*}/launch.awk")
launch_json() { local program=$1; shift; star_json_awk "$LAUNCH_JSON
END { r=document(); $program }" "$@"; }

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
    star_json_new 'n=split(a(1),parts,"/"); path=""; for(i=1;i<=n;i++) { if(parts[i]=="" || parts[i]==".") continue; if(parts[i]=="..") sub("/[^/]*$","",path); else path=path "/" parts[i] }; print (path=="" ? "/" : path)' "$value"
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
read_state() {
    local marker state first second third
    [ -f "$run/.await" ] || fail 'missing .await'
    marker=$(awk '{sub(/\r$/, ""); print}' "$run/.await")
    first=$(printf '%s\n' "$marker" | sed -n '1p')
    second=$(printf '%s\n' "$marker" | sed -n '2p')
    third=$(printf '%s\n' "$marker" | sed -n '3p')
    state=$(printf '%s\n' "$marker" | sed -n '4p')
    [ "$(printf '%s\n' "$marker" | wc -l | tr -d ' ')" = 4 ] &&
    printf '%s\n' "$state" | launch_json 'if(!statevalid(r) || field(r,"pid")!=a(1) || field(r,"log")!=a(2) || val(at(r,"outputs.0"))!=a(3)) exit 1' "$first" "$second" "$third" >/dev/null ||
        fail 'legacy or malformed .await: preserve evidence; reconcile identity explicitly'
    printf '%s\n' "$state"
}
read_exit() {
    local event
    [ -f "$run/.await.exit" ] || fail 'missing .await.exit'
    event=$(awk '{sub(/\r$/, ""); print}' "$run/.await.exit")
    printf '%s\n' "$event" | launch_json 'if(type(r)!="object" || field(r,"attempt")!=a(1) || !integer(get(r,"exit_code")) || !nonempty(get(r,"exited_at"))) exit 1' "$1" >/dev/null ||
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
    printf '%s\n' "$records" | star_json_awk "$LAUNCH_JSON"'
END { r=stream(input); for(i=0;i<size(r);i++) { x=get(r,i); if(!receiptvalid(x) || seen[field(x,"attempt")]++) exit 1 } }' >/dev/null ||
        fail 'malformed collection receipt: reconcile EXEC_LOG.md before continuing'
    printf '%s\n' "$records" | star_json_awk 'END { print json(stream(input)) }'
}
validate_binding() {
    local receipt=$1 state=${2:-} event=${3:-}
    if [ -n "$state" ]; then
        launch_json 's=parse(a(1)); if(!equal(launchfields(r),launchfields(s))) exit 1' "$state" <<<"$receipt" >/dev/null ||
            fail 'collection receipt does not match launch identity; preserve evidence'
    fi
    if [ -n "$event" ]; then
        launch_json 'e=parse(a(1)); if(!equal(get(r,"attempt"),get(e,"attempt")) || !equal(get(r,"exit_code"),get(e,"exit_code")) || !equal(get(r,"exited_at"),get(e,"exited_at"))) exit 1' "$event" <<<"$receipt" >/dev/null ||
            fail 'collection receipt does not match exit evidence; preserve evidence'
    fi
}
cleanup() {
    local receipt=$1 state='' event='' attempt
    attempt=$(printf '%s\n' "$receipt" | star_json_get attempt)
    if [ -e "$run/.await" ]; then
        state=$(read_state)
        [ "$(printf '%s\n' "$state" | star_json_get attempt)" = "$attempt" ] || return 0
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
    output_json=$(star_json_new 'r=array(); for(i=1;i<=ENVIRON["STAR_JSON_ARG_COUNT"];i++) { x=string(a(i)); if(!contains(r,x)) add(r,x) }; print json(r)' "${normalized[@]}")
    argv_json=$(star_json_new 'r=array(); for(i=1;i<=ENVIRON["STAR_JSON_ARG_COUNT"];i++) add(r,string(a(i))); print json(r)' "${command_argv[@]}")
    attempt=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
    state=$(star_json_new 'r=object(); put(r,"schema",number(1)); put(r,"attempt",string(a(1))); put(r,"prepared_at",string(a(2))); put(r,"cwd",string(a(3))); put(r,"code_version",string(a(4))); put(r,"review_version",string(a(5))); put(r,"pid",number(a(6)+0)); put(r,"log",string(a(7))); put(r,"outputs",parse(a(8))); put(r,"command_argv",parse(a(9))); print json(r)' "$attempt" "$(now)" "$PWD_PHYSICAL" "$code_version" "$review_version" "$pid" "$(real_absolute "$log_arg")" "$output_json" "$argv_json")
    printf '%s\n' "$state" | launch_json 'if(!statevalid(r)) exit 1' >/dev/null || fail 'exact command argv, positive wrapper PID, one-line paths, and explicit versions are required'
    marker=$(printf '%s\n' "$state" | star_json_eval 'raw(get(r,"pid")); raw(get(r,"log")); raw(at(r,"outputs.0"))')
    atomic_write "$run/.await" "$marker
$state"
    printf '%s\n' "$attempt"
    ;;
exited)
    [ -n "$attempt" ] && [[ "$exit_code" =~ ^-?[0-9]+$ ]] || fail '--attempt and integer --exit-code are required'
    state=$(read_state)
    [ "$(printf '%s\n' "$state" | star_json_get attempt)" = "$attempt" ] || fail 'attempt does not match active launch'
    if [ -e "$run/.await.exit" ]; then
        event=$(read_exit "$attempt")
        star_json_eval 'if(field(r,"exit_code")+0!=a(1)+0) exit 1' "$exit_code" <<<"$event" >/dev/null || fail 'recorded exit code cannot be changed'
    else
        event=$(star_json_new 'r=object(); put(r,"attempt",string(a(1))); put(r,"exit_code",number(a(2)+0)); put(r,"exited_at",string(a(3))); print json(r)' "$attempt" "$exit_code" "$(now)")
        atomic_write "$run/.await.exit" "$event"
    fi
    printf '%s\n' "$event"
    ;;
acknowledge)
    [ -n "$attempt" ] && [ -n "$evidence_arg" ] || fail '--attempt and --evidence are required'
    records=$(receipts)
    prior=$(printf '%s\n' "$records" | star_json_eval 'for(i=0;i<size(r);i++) if(field(get(r,i),"attempt")==a(1)) print json(get(r,i))' "$attempt")
    if [ -n "$prior" ]; then
        cleanup "$prior"
        star_json_new 'r=object(); put(r,"status",string(a(1))); put(r,"receipt",parse(a(2))); print json(r)' "already_collected" "$prior"
        exit 0
    fi
    state=$(read_state)
    [ "$(printf '%s\n' "$state" | star_json_get attempt)" = "$attempt" ] || fail 'attempt does not match active launch'
    event=$(read_exit "$attempt")
    normalized=()
    for value in "${verified[@]}"; do normalized+=("$(lexical_absolute "$value")"); done
    verified_json=$(star_json_new 'r=array(); for(i=1;i<=ENVIRON["STAR_JSON_ARG_COUNT"];i++) add(r,string(a(i))); print json(sorted(r,"",1))' "${normalized[@]}")
    launch_json 's=parse(a(1)); if(!subset(r,get(s,"outputs"))) exit 1' "$state" <<<"$verified_json" >/dev/null || fail 'verified output does not belong to this attempt'
    launch_json 's=parse(a(1)); e=parse(a(2)); if(field(e,"exit_code")+0==0 && !equal(r,sorted(get(s,"outputs"),"",0))) exit 1' "$state" "$event" <<<"$verified_json" >/dev/null || fail 'successful exit requires every expected output to be explicitly verified'
    for value in "${normalized[@]}"; do [ -e "$value" ] || fail 'a verified output is missing'; done
    evidence=$(real_absolute "$evidence_arg")
    [ -f "$evidence" ] && [ "$evidence" != "$run/EXEC_LOG.md" ] || fail 'verification evidence must be a separate existing file'
    if command -v sha256sum >/dev/null 2>&1; then hash=$(sha256sum < "$evidence"); else hash=$(shasum -a 256 < "$evidence"); fi
    hash=${hash%% *}
    receipt=$(star_json_new 's=parse(a(1)); e=parse(a(2)); r=merge(s,e); put(r,"collected_at",string(a(3))); put(r,"result",string(field(e,"exit_code")+0==0 ? "collected" : "failed")); put(r,"verified_outputs",parse(a(4))); put(r,"verification_evidence",string(a(5))); put(r,"evidence_sha256",string(a(6))); print json(r)' "$state" "$event" "$(now)" "$verified_json" "$evidence" "$hash")
    printf '\n### Launch collection %s\n\n```star-launch-receipt\n%s\n```\n' "$attempt" "$receipt" >> "$run/EXEC_LOG.md"
    sync
    cleanup "$receipt"
    star_json_new 'r=object(); put(r,"status",string(a(1))); put(r,"receipt",parse(a(2))); print json(r)' "acknowledged" "$receipt"
    ;;
inspect)
    state=$(read_state)
    attempt=$(printf '%s\n' "$state" | star_json_get attempt)
    event='' status=waiting
    if [ -e "$run/.await.exit" ]; then event=$(read_exit "$attempt"); status=exited; fi
    records=$(receipts)
    prior=$(printf '%s\n' "$records" | star_json_eval 'for(i=0;i<size(r);i++) if(field(get(r,i),"attempt")==a(1)) print json(get(r,i))' "$attempt")
    if [ -n "$prior" ]; then validate_binding "$prior" "$state" "$event"; status=already_collected; fi
    star_json_new 'r=object(); put(r,"status",string(a(1))); put(r,"launch",parse(a(2))); put(r,"exit",parse(a(3))); print json(r)' "$status" "$state" "${event:-null}"
    ;;
esac
