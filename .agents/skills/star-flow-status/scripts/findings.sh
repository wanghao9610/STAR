#!/usr/bin/env bash
# Resolve stable findings from explicitly selected reports without changing inputs.
set -u
export LC_ALL=C
root='' log=''
reports=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root=*) root=${1#--root=}; shift ;;
        --log=*) log=${1#--log=}; shift ;;
        --report=*) reports+=("${1#--report=}"); shift ;;
        --root|--log|--report)
            [ "$#" -ge 2 ] || { echo "Missing value for $1" >&2; exit 2; }
            case "$1" in
                --root) root=$2 ;;
                --log) log=$2 ;;
                --report) reports+=("$2") ;;
            esac
            shift 2 ;;
        -h|--help) echo 'Usage: findings.sh --root ROOT --log LOG [--report REPORT ...]'; exit 0 ;;
        *) echo "Unsupported argument: $1" >&2; exit 2 ;;
    esac
done
[ -n "$root" ] && [ -n "$log" ] || { echo '--root and --log are required' >&2; exit 2; }
command -v jq >/dev/null || { echo 'jq is required' >&2; exit 2; }
root=$(cd "$root" 2>/dev/null && pwd -P) || { echo 'Cannot read root' >&2; exit 2; }
work=$(mktemp -d "${TMPDIR:-/tmp}/star-findings.XXXXXX") || exit 2
trap 'rm -rf "$work"' EXIT
: > "$work/origins"
: > "$work/invalid"
: > "$work/rows"
: > "$work/unknowns"
unknown() {
    if [ "$#" -eq 3 ]; then
        jq -nc --arg path "$1" --arg message "$2" --arg finding_id "$3" '{path:$path,message:$message,finding_id:$finding_id}' >> "$work/unknowns"
    else
        jq -nc --arg path "$1" --arg message "$2" '{path:$path,message:$message}' >> "$work/unknowns"
    fi
}
# Parse one quoted or unquoted root-relative reference with optional line/anchor.
reference() {
    [[ "$1" =~ [[:cntrl:]] ]] && return 1
    printf '%s\n' "$1" | awk '
    { s = $0; sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s)
      q = substr(s, 1, 1)
      if (q == "`" || q == "\047" || q == "\042") {
          sub(/(:[1-9][0-9]*)?(#[A-Za-z0-9_.-]+)?$/, "", s)
          if (length(s) < 3 || substr(s, length(s)) != q) exit 1
          s = substr(s, 2, length(s)-2)
      } else if (s ~ /[[:space:]]/) exit 1
      sub(/(:[1-9][0-9]*)?(#[A-Za-z0-9_.-]+)?$/, "", s)
      if (s == "" || s ~ /[[:cntrl:]`\047\042#:]/ || substr(s,1,1) == "/") exit 1
      print s
    }'
}
# Resolve existing symlinks, including links in a missing path's ancestors.
# Traversal is component-wise so a symlink followed by .. has filesystem semantics.
contained() {
    local value pending part base target hops
    value=$(reference "$1") || return 1
    pending=$value
    base=$root
    hops=0
    while [ -n "$pending" ]; do
        case "$pending" in
            */*) part=${pending%%/*}; pending=${pending#*/} ;;
            *) part=$pending; pending= ;;
        esac
        case "$part" in
            ''|.) continue ;;
            ..) base=${base%/*}; [ -n "$base" ] || base=/ ;;
            *)
                if [ "$base" = / ]; then base=/$part; else base=$base/$part; fi
                if [ -L "$base" ]; then
                    hops=$((hops + 1)); [ "$hops" -le 40 ] || return 1
                    target=$(readlink "$base") || return 1
                    base=${base%/*}; [ -n "$base" ] || base=/
                    if [ -n "$pending" ]; then pending=$target/$pending; else pending=$target; fi
                    case "$pending" in /*) base=/; pending=${pending#/} ;; esac
                fi ;;
        esac
    done
    if [ "$root" = / ]; then
        normalized=${base#/}
    else case "$base" in
        "$root") normalized= ;;
        "$root"/*) normalized=${base#"$root"/} ;;
        *) return 1 ;;
    esac; fi
    absolute=$base
}
log_key() {
    contained "$1" || return 1
    case "$normalized" in wkdrs/dropped/*) key=wkdrs/${normalized#wkdrs/dropped/} ;; *) key=$normalized ;; esac
    [[ "$key" =~ ^wkdrs/([A-Za-z0-9][A-Za-z0-9_.-]*)/EXEC_LOG\.md$ ]] || return 1
    run=${BASH_REMATCH[1]}
}
evidence_path() {
    local prefix remainder owner alternate
    contained "$1" || { error='expected one contained root-relative path'; return 1; }
    [ -e "$absolute" ] && return 0
    case "$normalized" in
        metds/plans/*) prefix=metds/plans/ ;;
        wkdrs/*) prefix=wkdrs/ ;;
        tasks/*) prefix=tasks/ ;;
        execs/scpts/*) prefix=execs/scpts/ ;;
        *) error='matching row evidence does not exist'; return 1 ;;
    esac
    remainder=${normalized#"$prefix"}
    case "$remainder" in dropped/*) remainder=${remainder#dropped/}; alternate=$prefix$remainder ;; *) alternate=${prefix}dropped/$remainder ;; esac
    owner=${remainder%%/*}
    case "$prefix" in
        metds/plans/) [[ "$remainder" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*_plan\.md$ ]] || return 1 ;;
        execs/scpts/) [[ "$remainder" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*\.sh$ ]] || return 1 ;;
        *) [[ "$owner" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || return 1 ;;
    esac
    [ "$owner" != dropped ] || return 1
    if [ "$prefix" = wkdrs/ ]; then
        case "$owner" in reviews|results|digests|release|env_*|ideas_*|refs_*) return 1 ;; esac
    fi
    contained "$alternate" || { error='evidence fallback escapes root'; return 1; }
    [ -e "$absolute" ] || return 1
}
# Strip comments and fenced examples before either parser sees Markdown.
visible() {
    awk '
    { s=$0; out=""
      while (length(s)) {
        if (comment) { i=index(s,"-->"); if (!i) {s=""; break}; s=substr(s,i+3); comment=0 }
        else { i=index(s,"<!--"); if (!i) {out=out s; break}; out=out substr(s,1,i-1); s=substr(s,i+4); comment=1 }
      }
      if (out ~ /^ ? ? ?(```|~~~)/) {
        token=out; sub(/^ ? ? ?/,"",token); ch=substr(token,1,1); count=0
        while (substr(token,count+1,1)==ch) count++
        if (!fence) {fence=ch; width=count}
        else if (ch==fence && count>=width && substr(token,count+1) ~ /^[[:space:]]*$/) fence=""
        next
      }
      if (!fence) print out
    }' "$1"
}
source=$log
if contained "$log"; then source=$normalized; fi
if log_key "$source"; then
    source_key=$key
    if [ -f "$absolute" ] && [ -r "$absolute" ]; then
        visible "$absolute" | awk -v run="$run" '
        /^#{1,2}[[:space:]]/ { notes=(tolower($0) ~ /^##[[:space:]]+(notes([^A-Za-z0-9_]|$)|备注|笔记)/) }
        { if (!notes || $0 !~ /^[[:space:]]*-[[:space:]]+\*\*(Plan-level finding|方向性信号)\*\*/) next
          s=$0; sub(/^[[:space:]]*-[[:space:]]+\*\*(Plan-level finding|方向性信号)\*\*[[:space:]]*/,"",s)
          id=""; if (s ~ /^`[^`]+`/) { id=s; sub(/^`/,"",id); sub(/`.*/,"",id) }
          good=(s ~ /^`[A-Za-z0-9][A-Za-z0-9_.-]*:PF[1-9][0-9]*`[[:space:]]*—[[:space:]]*[^[:space:]]/ && index(id,run ":PF")==1)
          print (good ? "origin" : "bad") "\t" id
        }' > "$work/origin-events"
        while IFS="$(printf '\t')" read -r type finding; do
            if [ "$type" = origin ]; then
                if grep -Fxq "$finding" "$work/origins"; then
                    printf '%s\n' "$finding" >> "$work/invalid"
                    unknown "$source" 'Duplicate origin ID; executor must reconcile it.' "$finding"
                else printf '%s\n' "$finding" >> "$work/origins"; fi
            else
                if [ -n "$finding" ]; then
                    printf '%s\n' "$finding" >> "$work/invalid"
                    unknown "$source" 'Legacy/malformed finding: executor must reconcile the origin and assign a stable run-scoped ID; do not invent one.' "$finding"
                else unknown "$source" 'Legacy/malformed finding: executor must reconcile the origin and assign a stable run-scoped ID; do not invent one.'; fi
            fi
        done < "$work/origin-events"
    else unknown "$source" 'Cannot read execution log.'; fi
else unknown "$log" 'Unsupported execution log path: expected a contained live/dropped execution log.'; fi
for report in ${reports[@]+"${reports[@]}"}; do
    if ! contained "$report"; then unknown "$report" 'expected one contained root-relative path'; continue; fi
    relative=$normalized
    if [ ! -f "$absolute" ] || [ ! -r "$absolute" ]; then unknown "$relative" 'Cannot read report.'; continue; fi
    visible "$absolute" | awk -v origins="$work/origins" '
    function trim(s) {sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); return s}
    function json(s) {gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\t/,"\\t",s); gsub(/\r/,"\\r",s); return "\"" s "\""}
    function bad(id) {print "{\"type\":\"bad\",\"finding\":" json(id) "}"}
    BEGIN {while ((getline id < origins)>0) known[id]=1; close(origins)}
    /^#{1,2}[[:space:]]/ {if (header==1) bad(""); section=($0 ~ /^##[[:space:]]+4([.、．:：)）[:space:]]|$)/); header=0; next}
    {if (!section) next
     s=trim($0)
     if (index(s,"|")==0) {if (s!="" && header==1) bad(""); if (s!="" || header==2) header=0; next}
     sub(/^\|/,"",s); sub(/\|$/,"",s); n=split(s,c,"|")
     for(i=1;i<=n;i++) c[i]=trim(c[i])
     id=c[1]; gsub(/^`|`$/,"",id)
     if (header==2 && n!=5 && !(id in known) && $0 !~ /^[[:space:]]*\|/ && $0 !~ /\|[[:space:]]*$/) {header=0; next}
     exact=(n==5 && c[1]=="finding_id" && c[2]=="source_log" && c[3]=="disposition" && c[4]=="decision" && c[5]=="evidence")
     if (exact) {if(header==1) bad(""); header=1; next}
     sep=(n==5); for(i=1;i<=n;i++) if(c[i] !~ /^:?-{3,}:?$/) sep=0
     if (header==1 && sep) {header=2; next}
     attempted=0; for(i=1;i<=n;i++) if(c[i]=="finding_id" || c[i]=="source_log" || c[i]=="disposition") attempted=1
     if (header==1 || attempted || (header!=2 && (id in known))) {bad(id in known ? id : ""); header=0; next}
     if (header!=2) next
     if(n!=5) {bad(id in known ? id : ""); next}
     if (!(id in known)) next
     print "{\"type\":\"row\",\"finding\":" json(id) ",\"origin\":" json(c[2]) ",\"disposition\":" json(c[3]) ",\"decision\":" json(c[4]) ",\"evidence\":" json(c[5]) "}"
    }
    END {if(header==1) bad("")}' > "$work/report-events"
    while IFS= read -r event; do
        origin='' disposition='' decision='' evidence=''
        eval "$(printf '%s\n' "$event" | jq -r 'to_entries | map(.key + "=" + (.value|@sh)) | join(" ")')"
        if [ "$type" = bad ]; then
            [ -z "$finding" ] || printf '%s\n' "$finding" >> "$work/invalid"
            unknown "$relative" 'Unsupported finding decision table; use the five exact machine column names.'
            continue
        fi
        if ! log_key "$origin"; then
            printf '%s\n' "$finding" >> "$work/invalid"
            unknown "$relative" 'source_log must name a contained live/dropped execution log' "$finding"
            continue
        fi
        [ "$key" = "$source_key" ] || continue
        if { [ "$disposition" != resolved ] && [ "$disposition" != deferred ]; } || [ -z "$decision" ]; then
            printf '%s\n' "$finding" >> "$work/invalid"
            unknown "$relative" 'matching row needs an explicit disposition and decision' "$finding"
            continue
        fi
        error='matching row evidence does not exist'
        if ! evidence_path "$evidence"; then
            printf '%s\n' "$finding" >> "$work/invalid"
            unknown "$relative" "$error" "$finding"
            continue
        fi
        jq -nc --arg finding "$finding" --arg disposition "$disposition" --arg decision "$decision" '{finding:$finding,disposition:$disposition,decision:$decision}' >> "$work/rows"
    done < "$work/report-events"
done
jq -n --rawfile origins "$work/origins" --rawfile invalid "$work/invalid" --slurpfile rows "$work/rows" --slurpfile unknowns "$work/unknowns" --arg source "$source" '
  ($origins|split("\n")|map(select(length>0))|unique) as $ids |
  ($invalid|split("\n")) as $bad |
  [$ids[] as $id | ([$rows[]|select(.finding==$id and .disposition=="resolved")|.decision]|unique) as $decisions |
    {id:$id, decisions:$decisions, invalid: (($bad|index($id))!=null or ($decisions|length)>1)}] as $findings |
  {open:[$findings[]|select(.invalid|not)|select(.decisions|length==0)|.id],
   resolved:[$findings[]|select(.invalid|not)|select(.decisions|length>0)|.id],
   unknowns:($unknowns + [$findings[]|select(.decisions|length>1)|{path:$source,finding_id:.id,message:"Conflicting resolved decisions; reconcile explicit decisions."}] | unique | sort_by(.path,.finding_id // "",.message))}' > "$work/result"
cat "$work/result"
jq -e '.unknowns|length==0' "$work/result" >/dev/null || exit 2
