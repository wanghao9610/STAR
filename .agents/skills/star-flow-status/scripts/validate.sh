#!/usr/bin/env bash
# Read the workflow template subset without modifying the repository or Git state.
set -u
export GIT_OPTIONAL_LOCKS=0 LC_ALL=C
root=.
json=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        --root) [ "$#" -ge 2 ] && [ -n "$2" ] || { echo 'validate.sh: --root requires a directory' >&2; exit 2; }; root=$2; shift 2 ;;
        --root=*) root=${1#--root=}; [ -n "$root" ] || { echo 'validate.sh: --root requires a directory' >&2; exit 2; }; shift ;;
        --json) json=true; shift ;;
        -h|--help) echo 'Usage: validate.sh [--root ROOT] [--json]'; exit 0 ;;
        *) echo "validate.sh: unrecognized argument: $1" >&2; exit 2 ;;
    esac
done
source "$(dirname -- "${BASH_SOURCE[0]}")/../../../../.agents/scripts/json.sh"
WORKFLOW_JSON=$(cat "${STAR_JSON_LIB%/*}/workflow.awk")
workflow_json() { local program=$1; shift; star_json_awk "$WORKFLOW_JSON
END { r=document(); $program }" "$@"; }
if [ -d "$root" ]; then
    root=$(cd "$root" && pwd -P)
else
    case "$root" in /*) ;; *) root=$PWD/$root ;; esac
    root=$(star_json_new 'n=split(a(1),parts,"/"); path=""; for(i=1;i<=n;i++) {if(parts[i]=="" || parts[i]==".") continue; if(parts[i]=="..") sub("/[^/]*$","",path); else path=path "/" parts[i]}; print (path=="" ? "/" : path)' "$root")
fi

# Bash inventories files; the shared awk code reads JSON and checks the graph.

records=
append_record() { records=$records$1$'\n'; }
read_record() {
    local kind=$1 name=$2 path=$3 record message
    if [ ! -f "$path" ] || [ ! -r "$path" ]; then
        message='File is not a readable regular file.'
        append_record "$(star_json_new 'r=object(); put(r,"kind",string(a(1))); put(r,"name",string(a(2))); put(r,"path",string(a(3))); put(r,"read_error",string(a(4))); print json(r)' "$kind" "$name" "$path" "$message")"
    elif ! iconv -f UTF-8 -t UTF-8 "$path" >/dev/null 2>&1; then
        append_record "$(star_json_new 'r=object(); put(r,"kind",string(a(1))); put(r,"name",string(a(2))); put(r,"path",string(a(3))); put(r,"read_error",string(a(4))); print json(r)' "$kind" "$name" "$path" "Cannot read UTF-8 text.")"
    elif record=$(star_json_awk 'END { r=object(); put(r,"kind",string(a(1))); put(r,"name",string(a(2))); put(r,"path",string(a(3))); put(r,"text",string(input)); print json(r) }' "$kind" "$name" "$path" < "$path" 2>/dev/null); then
        append_record "$record"
    else
        append_record "$(star_json_new 'r=object(); put(r,"kind",string(a(1))); put(r,"name",string(a(2))); put(r,"path",string(a(3))); put(r,"read_error",string(a(4))); print json(r)' "$kind" "$name" "$path" "Cannot read file.")"
    fi
}
inventory_error() {
    append_record "$(star_json_new 'r=object(); put(r,"kind",string("inventory_error")); put(r,"code",string("unreadable")); put(r,"path",string(a(1))); put(r,"message",string("Cannot enumerate directory.")); print json(r)' "$1")"
}
collect() {
    local base=$1 kind=$2 entry child name
    [ -e "$base" ] || return 0
    if [ ! -d "$base" ] || ! ls -A "$base" >/dev/null 2>&1; then inventory_error "$base"; return; fi
    for entry in "$base"/* "$base"/.[!.]* "$base"/..?*; do
        [ -e "$entry" ] || [ -L "$entry" ] || continue
        name=${entry##*/}
        if [ "$kind" = plan ]; then
            case "$name" in *_plan.md) read_record plan "$name" "$entry" ;; esac
        elif [ -d "$entry" ]; then
            if ! ls -A "$entry" >/dev/null 2>&1; then inventory_error "$entry"; continue; fi
            child=$entry/EXEC_LOG.md
            if [ -e "$child" ] || [ -L "$child" ]; then read_record run "$name" "$child"; fi
        fi
    done
}
if [ ! -d "$root" ]; then
    result=$(star_json_new 'r=object(); u=array(); x=object(); put(x,"code",string("unreadable")); put(x,"path",string(a(1))); put(x,"message",string("Root is not a directory.")); add(u,x); put(r,"findings",array()); put(r,"unknowns",u); print json(r)' "$root")
else
    collect "$root/metds/plans" plan
    collect "$root/metds/plans/dropped" plan
    collect "$root/wkdrs" run
    collect "$root/wkdrs/dropped" run
    state=$(printf '%s' "$records" | star_json_awk "$WORKFLOW_JSON"'
END { print json(prepare_state(stream(input))) }') || exit 2
    names=$(printf '%s' "$state" | workflow_json 'p=get(r,"plans"); for(i=0;i<size(p);i++) count[field(get(p,i),"name")]++; for(i=0;i<size(p);i++) {n=get(p,i); if(count[field(n,"name")]!=1) continue; runs=get(n,"runs"); for(j=0;j<size(runs);j++) if(safe_run(val(get(runs,j)))) print val(get(runs,j))}' | sort -u)
    trees='' trees_loaded=false trees_available=false
    resolved='' resolution_issues=''
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if printf '%s' "$state" | star_json_eval 'runs=get(r,"runs"); for(i=0;i<size(runs);i++) if(field(get(runs,i),"name")==a(1)) exit 0; exit 1' "$name" >/dev/null; then continue; fi
        reason='' code=missing_run unknown=false found=false
        if [ "$trees_loaded" = false ]; then
            trees_loaded=true
            if trees=$(git --no-pager -C "$root" worktree list --porcelain 2>/dev/null); then trees_available=true; fi
        fi
        if [ "$trees_available" = false ]; then
            code=run_resolution unknown=true reason="Cannot inspect Git worktrees/branches for run $name."
        else
            tree=$(printf '%s\n' "$trees" | awk -v wanted="$name" '/^worktree / {p=substr($0,10)} /^branch refs\/heads\// {if(substr($0,19)==wanted) print p}')
            if [ -n "$tree" ] && [ ! -d "$tree" ]; then
                code=run_resolution unknown=true reason="Run worktree is unavailable: $tree"
            else
                if [ -n "$tree" ]; then
                    for relative in "wkdrs/$name/EXEC_LOG.md" "wkdrs/dropped/$name/EXEC_LOG.md"; do
                        if [ -e "$tree/$relative" ]; then records=; read_record run "$name" "$tree/$relative"; resolved=$resolved$records; found=true; break; fi
                    done
                fi
                if [ "$found" = false ]; then
                    if branches=$(git --no-pager -C "$root" branch --list '--format=%(refname:short)' "$name" 2>/dev/null); then
                        if [ "$branches" = "$name" ]; then
                            for relative in "wkdrs/$name/EXEC_LOG.md" "wkdrs/dropped/$name/EXEC_LOG.md"; do
                                spec=refs/heads/$name:$relative
                                if content=$(git --no-pager -C "$root" show "$spec" 2>/dev/null); then
                                    if ! printf '%s' "$content" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then
                                        code=run_resolution unknown=true reason="Cannot read $spec."; break
                                    fi
                                    resolved=$resolved$(printf '%s' "$content" | star_json_awk 'END {r=object(); put(r,"kind",string("run")); put(r,"name",string(a(1))); put(r,"path",string(a(2))); put(r,"text",string(input)); print json(r)}' "$name" "$spec")
                                    found=true; break
                                elif ! present=$(git --no-pager -C "$root" ls-tree --name-only "refs/heads/$name" -- "$relative" 2>/dev/null) || [ -n "$present" ]; then
                                    code=run_resolution unknown=true reason="Cannot read $spec."; break
                                fi
                            done
                        fi
                    else code=run_resolution unknown=true reason="Cannot inspect branch for run $name."
                    fi
                fi
            fi
        fi
        if [ "$found" = false ]; then
            [ -n "$reason" ] || reason="No execution log at live/dropped paths, named worktree or branch for $name."
            # A shared unresolved run is reported at each claiming plan, as in the original.
            owners=$(printf '%s' "$state" | star_json_eval 'p=get(r,"plans"); out=array(); for(i=0;i<size(p);i++) count[field(get(p,i),"name")]++; for(i=0;i<size(p);i++) {n=get(p,i); if(count[field(n,"name")]==1 && contains(get(n,"runs"),string(a(1)))) add(out,get(n,"path"))}; print json(out)' "$name")
            resolution_issues=$resolution_issues$(printf '%s' "$owners" | star_json_eval 'for(i=0;i<size(r);i++) {x=object(); put(x,"code",string(a(1))); put(x,"path",get(r,i)); put(x,"message",string(a(2))); put(x,"unknown",boolean(a(3)=="true")); print json(x)}' "$code" "$reason" "$unknown")
        fi
    done < <(printf '%s\n' "$names")
    result=$(printf '%s\n%s\n%s\n' "$state" "$resolved" "$resolution_issues" | star_json_awk "$WORKFLOW_JSON"'
      END { all=stream(input); state=get(all,0); for(i=1;i<size(all);i++) {x=get(all,i); if(field(x,"kind")=="run") add(get(state,"runs"),document_record(x)); else add(get(state,field(x,"unknown")=="true" ? "unknowns" : "findings"),issue(field(x,"code"),field(x,"path"),field(x,"message")))}; print json(validate(state)) }') || exit 2
fi
if [ "$json" = true ]; then
    printf '%s\n' "$result"
else
    printf '%s' "$result" | star_json_eval '
      f=get(r,"findings"); u=get(r,"unknowns")
      if(!size(f) && !size(u)) print "No workflow state inconsistencies found."
      for(i=0;i<size(f);i++) {x=get(f,i); print "finding " field(x,"code") ": " field(x,"path") ": " field(x,"message")}
      for(i=0;i<size(u);i++) {x=get(u,i); print "unknown " field(x,"code") ": " field(x,"path") ": " field(x,"message")}'
fi
printf '%s' "$result" | star_json_eval 'if(!size(get(r,"unknowns"))) exit 1' >/dev/null && exit 2
printf '%s' "$result" | star_json_eval 'if(!size(get(r,"findings"))) exit 1' >/dev/null && exit 1
exit 0
