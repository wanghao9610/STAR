#!/usr/bin/env bash
# Content-based review validity. No environment, Python, or Git index required.
# Usage: review_state.sh --root ROOT record RUN REPORT --path PATH... [--plan PLAN...]
#        review_state.sh --root ROOT check RUN
set -euo pipefail
export LC_ALL=C

fail() { printf '%s\n' "$1"; exit 1; }
[[ ${1:-} == --root && -n ${2:-} ]] || fail 'invalid review-state command: --root ROOT is required'
root=$(cd -- "$2" 2>/dev/null && pwd -P) || fail 'invalid review root'
shift 2
action=${1:-}; run=${2:-}; shift "$(( $# >= 2 ? 2 : $# ))"
run=${run%/}; run=${run#wkdrs/}
[[ -n $run && $run != . && $run != .. && $run != */* && $run != *$'\n'* && $run != *$'\t'* ]] || fail 'invalid run name'
run_dir="$root/wkdrs/$run"
[[ -d $run_dir ]] || fail 'missing run directory'
state="$run_dir/REVIEW_STATE.md"

# Metadata is data, never sourced. Root-relative names have no traversal.
valid_path() {
    case "$1" in ''|/*|.|..|../*|*/../*|*/..|./*|*/./*|*/.|*$'\n'*|*$'\t'*|*$'\r'*) return 1 ;; esac
}
source_path() {
    valid_path "$1" || return 1
    case "$1/" in datas/*|inits/*|wkdrs/*|.git/*) return 1 ;; esac
}
hash_file() { git -C "$root" hash-object --no-filters -- "$1" 2>/dev/null; }
hash_stream() { git -C "$root" hash-object --stdin 2>/dev/null; }
scope_hash() {
    local path=$1 file digest listing
    if [[ -L "$root/$path" || -f "$root/$path" ]]; then
        if [[ -L "$root/$path" ]]; then
            [[ ! -d "$root/$path" ]] || return 1
            printf 'link\t%s\n' "$(readlink "$root/$path")"
        fi
        if [[ -f "$root/$path" ]]; then
            digest=$(hash_file "$root/$path") || return 1
            printf 'file\t%s\t%s\n' "$path" "$digest"
        fi
    elif [[ -d "$root/$path" ]]; then
        printf 'directory\t%s\n' "$path"
        # Explicit directories cover additions/deletions, including ignored source.
        # Runtime caches and reserved data/output trees are never source scope.
        listing=$(cd "$root" && find "$path" \
            -type d \( -name .git -o -name __pycache__ -o -name .pytest_cache -o -name node_modules -o -name datas -o -name inits -o -name wkdrs \) -prune -o \
            \( -type f -o -type l \) ! -name '*.pyc' -print0 2>/dev/null |
            while IFS= read -r -d '' file; do
                [[ $file != *$'\t'* && $file != *$'\r'* && $file != *$'\n'* ]] || exit 1
                printf '%s\n' "$file"
            done | sort) || return 1
        if [[ -n $listing ]]; then
            while IFS= read -r file; do
                scope_hash "$file" || return 1
            done <<< "$listing"
        fi
    elif [[ -e "$root/$path" ]]; then
        return 1
    else
        printf 'missing\t%s\n' "$path"
    fi
}
path_hash() { scope_hash "$1" | hash_stream; }
plan_hash() {
    [[ -f "$root/$1" ]] || return 1
    # Keep plan relationships and body constraints, not workflow bookkeeping.
    awk '
        { sub(/\r$/, "") }
        NR == 1 && $0 == "---" { front = 1; next }
        front && $0 == "---" { front = 0; next }
        front {
            # YAML permits sequence items at the same indentation as their key.
            if ($0 ~ /^-([[:space:]]|$)/) {
                if (keep) print
                next
            }
            if ($0 ~ /^[^[:space:]#][^:]*:/) {
                key = $0; sub(/:.*/, "", key)
                keep = key ~ /^(parent|prefix|children|depends_on|traces_to|dropped)$/
                if (keep) print
            } else if (keep && $0 ~ /^[[:space:]]+[^#[:space:]]/) {
                print
            }
            next
        }
        /^#+ / {
            heading = $0; sub(/ .*/, "", heading); level = length(heading)
            if (skip && level <= skip) skip = 0
            title = $0; sub(/^#+[[:space:]]+/, "", title)
            if (title ~ /^([0-9]+[.)]?[[:space:]]+)?(Revision History|修订历史|修订记录)[[:space:]]*$/) skip = level
        }
        !skip { print }
    ' "$root/$1" | hash_stream
}
report_gate() {
    awk '/<!--/ { comment = 1 }
         comment && /^[[:space:]]*review_gate:[[:space:]]*/ {
             sub(/^[[:space:]]*review_gate:[[:space:]]*/, ""); print
         }
         comment && /-->/ { exit }' "$1"
}
latest_report() {
    local file latest=''
    for file in "$run_dir"/CODE_REVIEW_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
        [[ -f $file ]] && latest=$file
    done
    printf '%s' "$latest"
}

case "$action" in
    record)
        report=${1:-}; [[ $# -gt 0 ]] && shift
        valid_path "$report" || fail 'invalid report path'
        [[ $report == "wkdrs/$run/"CODE_REVIEW_*.md && -f "$root/$report" ]] || fail 'missing or invalid run review report'
        [[ $(latest_report) == "$root/$report" ]] || fail 'review report is not the newest run report'
        gate=$(report_gate "$root/$report")
        [[ $gate == passed || $gate == blocked ]] || fail 'invalid report review_gate: reviewer must explicitly set passed or blocked'
        paths=(); plans=()
        while [[ $# -gt 0 ]]; do
            [[ $# -ge 2 ]] || fail 'invalid scope arguments'
            case "$1" in
                --path) source_path "$2" || fail 'invalid source/config scope path'; paths+=("$2") ;;
                --plan) valid_path "$2" || fail 'invalid plan path'; plans+=("$2") ;;
                *) fail 'invalid scope argument' ;;
            esac
            shift 2
        done
        [[ ${#paths[@]} -gt 0 ]] || fail 'missing explicit source/config scope'
        # Construct everything before replacing an existing record.
        report_hash=$(hash_file "$root/$report") || fail 'cannot hash review report'
        content=$(printf 'version\t1\ngate\t%s\nreport\t%s\nreport_hash\t%s\n' "$gate" "$report" "$report_hash"
            for path in "${paths[@]}"; do
                digest=$(path_hash "$path") || exit 1
                printf 'path\t%s\t%s\n' "$path" "$digest"
            done
            for plan in ${plans[@]+"${plans[@]}"}; do
                digest=$(plan_hash "$plan") || exit 1
                printf 'plan\t%s\t%s\n' "$plan" "$digest"
            done) || fail 'cannot hash review scope (missing plan or unsupported path)'
        temporary=$(mktemp "$run_dir/.review-state.XXXXXX")
        trap 'rm -f -- "$temporary"' EXIT
        printf '%s\n' "$content" > "$temporary"
        mv -- "$temporary" "$state"
        ;;
    check)
        [[ $# -eq 0 ]] || fail 'invalid check arguments'
        [[ -f $state ]] || fail 'missing review metadata: verify source and record the review once'
        version=''; gate=''; report=''; report_hash=''
        paths=(); plans=(); hashes=(); plan_hashes=()
        while IFS=$'\t' read -r key value digest extra; do
            [[ -z $extra ]] || fail 'invalid review metadata'
            case "$key" in
                version|gate|report|report_hash)
                    [[ -z $digest ]] || fail 'invalid review metadata'
                    case "$key" in
                        version) [[ -z $version ]] || fail 'invalid review metadata'; version=$value ;;
                        gate) [[ -z $gate ]] || fail 'invalid review metadata'; gate=$value ;;
                        report) [[ -z $report ]] || fail 'invalid review metadata'; report=$value ;;
                        report_hash) [[ -z $report_hash ]] || fail 'invalid review metadata'; report_hash=$value ;;
                    esac ;;
                path)
                    source_path "$value" || fail 'invalid review source/config scope'
                    paths+=("$value"); hashes+=("$digest") ;;
                plan)
                    valid_path "$value" || fail 'invalid review plan scope'
                    plans+=("$value"); plan_hashes+=("$digest") ;;
                *) fail 'invalid review metadata' ;;
            esac
        done < "$state"
        [[ $version == 1 && ( $gate == passed || $gate == blocked ) && ${#paths[@]} -gt 0 ]] || fail 'invalid review metadata'
        valid_path "$report" || fail 'invalid review report path'
        [[ $report == "wkdrs/$run/"CODE_REVIEW_*.md && -f "$root/$report" ]] || fail 'missing reviewed report'
        [[ $(latest_report) == "$root/$report" ]] || fail 'stale review: a newer report has not been recorded'
        [[ $(hash_file "$root/$report") == "$report_hash" ]] || fail 'stale review: report content changed'
        [[ $(report_gate "$root/$report") == "$gate" ]] || fail 'invalid review gate metadata'
        [[ $gate == passed ]] || fail 'blocked review: unresolved blocker/major findings prevent launch'
        for ((i=0; i<${#paths[@]}; i++)); do
            digest=$(path_hash "${paths[i]}") || fail 'invalid review source/config scope'
            [[ $digest == "${hashes[i]}" ]] || fail 'stale review: source/config scope changed'
        done
        for ((i=0; i<${#plans[@]}; i++)); do
            digest=$(plan_hash "${plans[i]}") || fail 'missing reviewed plan'
            [[ $digest == "${plan_hashes[i]}" ]] || fail 'stale review: plan constraints changed'
        done
        ;;
    *) fail 'invalid review-state action: use record or check' ;;
esac
