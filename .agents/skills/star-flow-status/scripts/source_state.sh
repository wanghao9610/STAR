#!/usr/bin/env bash
# Bind an owned Markdown artifact to explicit source contents. Bash 3.2, awk, git.
# check is read-only and never starts the interpreter: 0 current, 1 stale, 2 unknown.
set -euo pipefail
export LC_ALL=C
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 2; }

result() { star_json_object status "$1" reason "$2"; }
unknown() { result unknown "$1"; exit 2; }
stale() { result stale "$1"; exit 1; }
usage() {
    printf '%s\n' \
        'Usage: source_state.sh --root ROOT record ARTIFACT --kind KIND [--reason TEXT] [--runtime ABSOLUTE_PYTHON] SOURCE...' \
        '       source_state.sh --root ROOT check ARTIFACT --kind KIND [--runtime ABSOLUTE_PYTHON] [--require PATH ...]' \
        '       source_state.sh --root ROOT clear ARTIFACT --kind analysis-exemption' \
        'Kinds: analysis, results, method, environment, analysis-exemption.' \
        'Sources: --file PATH, --document PATH, --plan PATH, --method-plan PATH, --report PATH, --exemption PATH.' \
        'Paths are root-relative files. Results check --report analyses and --exemption execution records recursively.'
}
[[ ${1:-} != --help && ${1:-} != -h ]] || { usage; exit 0; }
[[ ${1:-} == --root && -n ${2:-} ]] || unknown '--root is required'
root=$(cd -- "$2" 2>/dev/null && pwd -P) || unknown 'root is unavailable'
shift 2
[[ $# -ge 2 ]] || unknown 'action and artifact are required'
action=$1; artifact=$2; shift 2
valid_path() {
    case "$1" in ''|/*|.|..|../*|*/../*|*/..|./*|*/./*|*/.|*$'\n'*|*$'\r'*|*$'\t'*) return 1 ;; esac
}
valid_path "$artifact" || unknown 'invalid artifact path'
[[ -f "$root/$artifact" && ! -L "$root/$artifact" ]] || unknown 'artifact must be an existing regular Markdown file'
artifact_parent=$(cd -- "$(dirname -- "$root/$artifact")" && pwd -P) || unknown 'artifact parent is unavailable'
[[ $artifact_parent == "$root" || $artifact_parent == "$root/"* ]] || unknown 'artifact resolves outside the selected checkout'
kind=''; reason=''; runtime=''; sources=(); modes=(); required=()
while [[ $# -gt 0 ]]; do
    [[ $# -ge 2 ]] || unknown 'missing option value'
    case "$1" in
        --kind) [[ -z $kind ]] || unknown 'duplicate kind'; kind=$2 ;;
        --reason) reason=$2 ;;
        --runtime) [[ -z $runtime ]] || unknown 'duplicate runtime'; runtime=$2 ;;
        --file|--document|--plan|--method-plan|--report|--exemption)
            [[ $action == record ]] || unknown 'source options belong to record'
            valid_path "$2" && [[ $2 != "$artifact" ]] || unknown 'invalid or self-referencing source'
            modes+=("${1#--}"); sources+=("$2") ;;
        --require)
            [[ $action == check ]] || unknown '--require belongs to check'
            valid_path "$2" || unknown 'invalid required source'; required+=("$2") ;;
        *) unknown 'unsupported option' ;;
    esac
    shift 2
done
case "$kind:$artifact" in
    analysis:wkdrs/*/EXPT_ANALYSIS_*.md|results:wkdrs/results/results*.md|method:metds/overview.md|method:metds/dataset.md|method:metds/framework.md|method:metds/training.md|method:metds/evaluation.md|environment:wkdrs/env_*/ENV_REPORT.md|analysis-exemption:wkdrs/*/EXEC_LOG.md) ;;
    *) unknown 'artifact path does not match its kind' ;;
esac

# The reserved block is always data. Duplicate, unclosed or malformed blocks fail.
without_state() {
    awk -v preserve="${2:-0}" '
        { raw=$0; sub(/\r$/, "") }
        $0 == "<!-- star-source-state" { if (seen++) exit 2; inside=1; next }
        inside && $0 == "-->" { inside=0; next }
        !inside { print preserve ? raw : $0 }
        END { if (inside) exit 2 }
    ' "$1"
}
metadata() {
    awk '
        { sub(/\r$/, "") }
        $0 == "<!-- star-source-state" { if (seen++) exit 2; inside=1; next }
        inside && $0 == "-->" { inside=0; next }
        inside { print }
        END { if (inside || seen != 1) exit 2 }
    ' "$1" | star_json_eval 'if(type(r)!="object") exit 2; print json(r)' 2>/dev/null
}
canonical() {
    local mode=$1
    awk -v mode="$mode" '
        { sub(/\r$/, "") }
        NR == 1 && $0 == "---" { front=1; next }
        front && $0 == "---" { front=0; next }
        front {
            if ($0 ~ /^-([[:space:]]|$)/) { if (keep) print; next }
            if ($0 ~ /^[^[:space:]#][^:]*:/) {
                key=$0; sub(/:.*/, "", key)
                keep=key !~ /^(model_id|model_trail|created|started|updated|generated|analyzed|merged)$/
                if (mode == "plan" || mode == "method-plan") {
                    keep=key ~ /^(parent|prefix|children|depends_on|traces_to|dropped|language)$/
                    if (mode == "method-plan" && key ~ /^(status|exec_status)$/) keep=1
                    if (mode == "method-plan" && key == "finalized") {
                        value=$0; sub(/^[^:]*:[[:space:]]*/, "", value)
                        if (value != "" && value != "null" && value != "false" && value != "—") print "finalized: present"
                    }
                }
                if (keep) print
            } else if (keep && $0 ~ /^[[:space:]]+[^#[:space:]]/) print
            next
        }
        /^#+ / && (mode == "plan" || mode == "method-plan") {
            heading=$0; sub(/ .*/, "", heading); level=length(heading)
            if (skip && level <= skip) skip=0
            title=$0; sub(/^#+[[:space:]]+/, "", title)
            if (title ~ /^([0-9]+[.)]?[[:space:]]+)?(Revision History|修订历史|修订记录)[[:space:]]*$/) skip=level
        }
        !skip { print }
        END { if (front) exit 2 }
    '
}
frontmatter_value() {
    local raw
    raw=$(awk -v key="$2" '
        { sub(/\r$/, "") }
        NR == 1 { if ($0 != "---") exit 2; front=1; next }
        front && $0 == "---" { front=0; exit }
        front && index($0,key ":") == 1 { value=$0; sub(/^[^:]*:[[:space:]]*/, "", value); print value; count++ }
        END { if (front || count != 1) exit 2 }
    ' "$1") || return 2
    case "$raw" in
        \"*) printf '%s\n' "$raw" | star_json_eval 'if(type(r)!="string") exit 2; raw(r)' ;;
        \') return 2 ;;
        \'*) [[ $raw == *\' ]] || return 2; raw=${raw#\'}; raw=${raw%\'}; printf '%s\n' "$raw" | sed "s/''/'/g" ;;
        *) printf '%s\n' "$raw" | sed 's/[[:space:]]#.*$//; s/[[:space:]]*$//' ;;
    esac
}
existing_metadata_valid() {
    if grep -q '^<!-- star-source-state' "$root/$artifact"; then
        metadata "$root/$artifact" | binding_valid basic >/dev/null 2>&1 || return 2
    fi
}
hash_stream() { git -C "$root" hash-object --stdin 2>/dev/null; }
hash_file() { git -C "$root" hash-object --no-filters -- "$1" 2>/dev/null; }
document_hash() { without_state "$1" | canonical "$2" | hash_stream; }
source_hash() {
    local path=$1 mode=$2 digest binding source_kind
    [[ ! "$root/$path" -ef "$root/$artifact" ]] || return 2
    if [[ $mode == file && ! -e "$root/$path" && ! -L "$root/$path" ]]; then
        printf 'missing\n' | hash_stream
        return
    fi
    [[ -f "$root/$path" && -r "$root/$path" ]] || return 2
    case "$mode" in
        file)
            digest=$(hash_file "$root/$path") || return 2
            printf 'file\t%s\n' "$digest" | hash_stream ;;
        document|plan|method-plan) document_hash "$root/$path" "$mode" ;;
        report|exemption)
            [[ $kind == results ]] || return 2
            source_kind=analysis; [[ $mode != exemption ]] || source_kind=analysis-exemption
            bash "${BASH_SOURCE[0]}" --root "$root" check "$path" --kind "$source_kind" >/dev/null || return 2
            # A refreshed analysis may retain rounded values but bind new evidence.
            digest=$(document_hash "$root/$path" document) || return 2
            binding=$(metadata "$root/$path" | star_json_eval 'put(r,"sources",sorted(get(r,"sources"),"path,mode",0)); print json(r)') || return 2
            printf '%s\n%s\n' "$digest" "$binding" | hash_stream ;;
        *) return 2 ;;
    esac
}
runtime_hash() {
    local python=$1 prefix file digest
    [[ $python == /* && -f $python && -x $python && $python != *$'\n'* && $python != *$'\t'* ]] || return 2
    prefix=$(cd -- "$(dirname -- "$python")/.." && pwd -P) || return 2
    digest=$(hash_file "$python") || return 2
    {
        printf 'interpreter\t%s\t%s\n' "$python" "$digest"
        for file in "$prefix"/pyvenv.cfg "$prefix"/conda-meta/*.json \
            "$prefix"/lib/python*/site-packages/*.dist-info/METADATA \
            "$prefix"/lib/python*/site-packages/*.egg-info/PKG-INFO \
            "$prefix"/lib/python*/site-packages/*.egg-info \
            "$prefix"/lib/python*/site-packages/*.egg-link \
            "$prefix"/Lib/site-packages/*.dist-info/METADATA \
            "$prefix"/Lib/site-packages/*.egg-info/PKG-INFO; do
            [[ -f $file ]] || continue
            digest=$(hash_file "$file") || return 2
            printf '%s\t%s\n' "${file#"$prefix"/}" "$digest"
        done
    } | hash_stream
}
binding_valid() {
    star_json_awk '
    function digest(id) { return type(id)=="string" && val(id) ~ /^([0-9a-f]{40}|[0-9a-f]{64})$/ }
    END {
        r=document(); src=get(r,"sources")
        if(type(r)!="object" || type(get(r,"schema"))!="number" || field(r,"schema")!=1 || field(r,"kind")!=a(1) || field(r,"artifact")!=a(2) || !digest(get(r,"digest")) || type(get(r,"reason"))!="string" || type(get(r,"runtime"))!="string" || type(get(r,"runtime_digest"))!="string" || type(src)!="array" || !size(src)) exit 1
        for(i=0;i<size(src);i++) {
            x=get(src,i); path=field(x,"path"); mode=field(x,"mode")
            if(type(get(x,"path"))!="string" || mode !~ /^(file|document|plan|method-plan|report|exemption)$/ || !digest(get(x,"digest")) || seen[path]++) exit 1
        }
        if(a(3)=="basic") exit 0
        if(a(1)=="analysis-exemption" && field(r,"reason")=="") exit 1
        if(a(1)=="environment") { if(substr(field(r,"runtime"),1,1)!="/" || !digest(get(r,"runtime_digest"))) exit 1 }
        else if(field(r,"runtime")!="" || field(r,"runtime_digest")!="") exit 1
    }' "$kind" "$artifact" "${1:-check}"
}
scope_valid() {
    star_json_eval '
        src=get(r,"sources"); for(i=0;i<size(src);i++) modes[field(get(src,i),"mode")]++
        kind=a(1)
        if(kind=="method") { if(!modes["method-plan"] || modes["method-plan"]+modes["file"]!=size(src)) exit 1 }
        else if(kind=="results") { if(!modes["report"]) exit 1 }
        else if(kind=="analysis" || kind=="analysis-exemption") { if(!modes["plan"] || !(modes["file"]+modes["document"]) || modes["report"] || modes["exemption"]) exit 1 }
        else if(modes["file"]+modes["document"]!=size(src)) exit 1
    ' "$kind"
}

case "$action" in
    clear)
        [[ $kind == analysis-exemption && -z $runtime && -z $reason ]] || unknown 'only the executor may clear an analysis exemption'
        existing_metadata_valid || unknown 'malformed source binding; preserve it for reconciliation'
        original=$(hash_file "$root/$artifact") || unknown 'artifact unreadable'
        temporary=$(mktemp "$(dirname -- "$root/$artifact")/.source-state.XXXXXX")
        trap 'rm -f -- "$temporary"' EXIT
        cp -p -- "$root/$artifact" "$temporary"
        without_state "$root/$artifact" 1 > "$temporary" || unknown 'malformed source block; preserve it for reconciliation'
        [[ $(hash_file "$root/$artifact") == "$original" ]] || unknown 'artifact changed during clearing'
        mv -- "$temporary" "$root/$artifact"
        result cleared 'exemption binding removed; execution history retained'
        ;;
    record)
        existing_metadata_valid || unknown 'malformed source binding; preserve it for reconciliation'
        [[ ${#sources[@]} -gt 0 ]] || unknown 'record requires explicit sources'
        [[ $kind != analysis-exemption || -n $reason ]] || unknown 'analysis exemption requires a reason'
        if [[ $kind == analysis-exemption ]]; then
            [[ $(frontmatter_value "$root/$artifact" status) == done ]] || unknown 'only a completed run can receive an analysis exemption'
        fi
        [[ $kind != environment || -n $runtime ]] || unknown 'environment record requires its verified interpreter'
        [[ $kind == environment || -z $runtime ]] || unknown 'runtime is only valid for environment records'
        entries='[]'
        for ((i=0; i<${#sources[@]}; i++)); do
            digest=$(source_hash "${sources[i]}" "${modes[i]}") || unknown "cannot bind source: ${sources[i]}"
            entries=$(star_json_new 'r=parse(a(1)); x=object(); put(x,"path",string(a(2))); put(x,"mode",string(a(3))); put(x,"digest",string(a(4))); add(r,x); print json(r)' "$entries" "${sources[i]}" "${modes[i]}" "$digest")
        done
        star_json_eval 'for(i=0;i<size(r);i++) if(seen[field(get(r,i),"path")]++) exit 1' <<<"$entries" >/dev/null || unknown 'duplicate sources'
        entries=$(star_json_eval 'print json(sorted(r,"path,mode",0))' <<<"$entries")
        runtime_digest=''
        if [[ $kind == environment ]]; then
            [[ $(frontmatter_value "$root/$artifact" status) == verified ]] || unknown 'only a verified environment can be recorded'
            declared_runtime=$(frontmatter_value "$root/$artifact" interpreter) || unknown 'report must identify its verified interpreter'
            [[ $declared_runtime == "$runtime" ]] || unknown 'runtime does not match the interpreter verified in the report'
            runtime_digest=$(runtime_hash "$runtime") || unknown 'verified interpreter or package metadata unavailable'
        fi
        original=$(hash_file "$root/$artifact") || unknown 'artifact unreadable'
        digest=$(document_hash "$root/$artifact" document) || unknown 'invalid existing source block'
        state=$(star_json_new 'r=object(); put(r,"schema",number(1)); put(r,"kind",string(a(1))); put(r,"artifact",string(a(2))); put(r,"digest",string(a(3))); put(r,"reason",string(a(4))); put(r,"runtime",string(a(5))); put(r,"runtime_digest",string(a(6))); put(r,"sources",parse(a(7))); print json(r)' "$kind" "$artifact" "$digest" "$reason" "$runtime" "$runtime_digest" "$entries")
        scope_valid <<<"$state" || unknown 'source modes do not cover this artifact kind'
        temporary=$(mktemp "$(dirname -- "$root/$artifact")/.source-state.XXXXXX")
        trap 'rm -f -- "$temporary"' EXIT
        cp -p -- "$root/$artifact" "$temporary"
        without_state "$root/$artifact" 1 > "$temporary" || unknown 'invalid existing source block'
        printf '<!-- star-source-state\n%s\n-->\n' "$state" >> "$temporary"
        [[ $(hash_file "$root/$artifact") == "$original" ]] || unknown 'artifact changed during recording'
        mv -- "$temporary" "$root/$artifact"
        result current 'sources recorded after producer verification'
        ;;
    check)
        state=$(metadata "$root/$artifact") || unknown 'missing or malformed source binding; producer verification is required'
        binding_valid <<<"$state" >/dev/null 2>&1 || unknown 'invalid source binding'
        scope_valid <<<"$state" || unknown 'invalid source coverage'
        digest=$(document_hash "$root/$artifact" document) || unknown 'malformed artifact content'
        [[ $digest == "$(star_json_get .digest <<<"$state")" ]] || stale 'artifact content changed'
        for path in ${required[@]+"${required[@]}"}; do
            star_json_eval 'src=get(r,"sources"); for(i=0;i<size(src);i++) if(field(get(src,i),"path")==a(1)) exit 0; exit 1' "$path" <<<"$state" >/dev/null || stale "new or uncovered source: $path"
        done
        count=$(star_json_eval 'print size(get(r,"sources"))' <<<"$state")
        for ((i=0; i<count; i++)); do
            path=$(star_json_get ".sources[$i].path" <<<"$state"); mode=$(star_json_get ".sources[$i].mode" <<<"$state")
            valid_path "$path" && [[ $path != "$artifact" ]] || unknown 'invalid source path'
            digest=$(source_hash "$path" "$mode") || unknown "source missing, unreadable or unverified: $path"
            [[ $digest == "$(star_json_get ".sources[$i].digest" <<<"$state")" ]] || stale "source content changed: $path"
        done
        if [[ $kind == environment ]]; then
            [[ -n $runtime ]] || unknown 'pass the interpreter currently resolved from .env'
            declared_runtime=$(frontmatter_value "$root/$artifact" interpreter) || unknown 'report interpreter is missing or malformed'
            [[ $(frontmatter_value "$root/$artifact" status) == verified && $declared_runtime == "$(star_json_get .runtime <<<"$state")" ]] || unknown 'report does not verify the bound interpreter'
            [[ $runtime == "$(star_json_get .runtime <<<"$state")" ]] || stale 'configured interpreter changed'
            digest=$(runtime_hash "$runtime") || unknown 'current interpreter or package metadata unavailable'
            [[ $digest == "$(star_json_get .runtime_digest <<<"$state")" ]] || stale 'interpreter or installed package metadata changed'
        elif [[ -n $runtime ]]; then
            unknown 'runtime is only valid for environment checks'
        fi
        result current 'recorded contents match'
        ;;
    *) unknown 'use record, check or clear' ;;
esac
