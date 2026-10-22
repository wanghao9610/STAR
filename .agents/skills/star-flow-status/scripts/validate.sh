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
command -v jq >/dev/null 2>&1 || { echo 'validate.sh requires jq.' >&2; exit 2; }
if [ -d "$root" ]; then
    root=$(cd "$root" && pwd -P)
else
    case "$root" in /*) ;; *) root=$PWD/$root ;; esac
    root=$(jq -nr --arg path "$root" '$path | split("/") | reduce .[] as $p ([]; if $p == "" or $p == "." then . elif $p == ".." then .[:-1] else . + [$p] end) | "/" + join("/")')
fi

# jq handles JSON strings and the graph; Bash alone inventories and reads files.
# This parser deliberately supports only the workflow template's YAML subset.
common='
def trim: gsub("^\\s+|\\s+$"; "");
def fields($kind): if $kind == "plan" then ["parent","prefix","children","depends_on","exec_status","exec_runs","exec_run","dropped"] else ["run","source_plan","status","branch","worktree"] end;
def listfield: . == "children" or . == "depends_on" or . == "exec_runs";
def issue($code;$path;$message): {code:$code,path:$path,message:$message};
def bad($key): (.invalid | index($key)) != null;
def terminal: . == "done" or . == "abandoned" or . == "skipped";
def status: . == "pending" or . == "in_progress" or . == "blocked" or terminal;
def textvalue: if . == null then "None" else tostring end;
def uncomment:
  . as $s | explode as $chars |
  reduce range(0; $chars|length) as $i
    ({quote:0,skip:false,end:null};
     if .end != null then . elif .skip then .skip=false
     else $chars[$i] as $c |
       if .quote == 34 and $c == 92 then .skip=true
       elif .quote == 39 and $c == 39 and $chars[$i+1] == 39 then .skip=true
       elif .quote != 0 and $c == .quote then .quote=0
       elif .quote == 0 and ($c == 34 or $c == 39) and
         (($s[0:$i]|trim) == "" or ($s[0:$i]|trim|test("[\\[,]$")) or ($s[0:$i]|trim) == "-") then .quote=$c
       elif .quote == 0 and $c == 35 and ($i == 0 or ($chars[$i-1]|[.]|implode|test("\\s"))) then .end=$i
       else . end end) |
  if .quote != 0 then error("unclosed quote") else $s[0:(.end // ($chars|length))]|trim end;
def scalar:
  uncomment | trim |
  if . == "" or . == "null" or . == "Null" or . == "NULL" or . == "~" then null
  else
    if startswith("\"") then (try fromjson catch error("unsupported quoted scalar")) | if type != "string" then error("expected a string") else . end
    elif startswith("\u0027") then if test("^\u0027(?:[^\u0027]|\u0027\u0027)*\u0027$";"s") then .[1:-1]|gsub("\u0027\u0027";"\u0027") else error("unsupported quoted scalar") end
    elif test("^[\\[{}\\]&*!|>@`]") or contains(": ") or contains("\t") then error("unsupported scalar syntax")
    else . end |
    if contains("<") or contains(">") then error("unfilled template placeholder") else . end
  end;
def inline_list:
  if (startswith("[") and endswith("]"))|not then error("expected an inline or multiline list") else .[1:-1]|trim end |
  if . == "" then [] else
  . as $s | explode as $chars |
  reduce range(0; $chars|length) as $i
    ({quote:0,skip:false,start:0,pieces:[]};
     if .skip then .skip=false else $chars[$i] as $c |
       if .quote == 34 and $c == 92 then .skip=true
       elif .quote == 39 and $c == 39 and $chars[$i+1] == 39 then .skip=true
       elif .quote != 0 and $c == .quote then .quote=0
       elif .quote == 0 and ($c == 34 or $c == 39) then .quote=$c
       elif .quote == 0 and $c == 44 then .pieces += [$s[.start:$i]] | .start=$i+1
       elif .quote == 0 and ($c == 91 or $c == 93 or $c == 123 or $c == 125) then error("nested lists/maps are unsupported")
       else . end end) |
  (.pieces + [$s[.start:]]) |
  if (.[-1]|trim) == "" then .[:-1] else . end |
  map(scalar | if . == null then error("list entries must be strings") else . end) end;
def document:
  . as $record | fields(.kind) as $fields |
  {name:.name,path:.path,kind:.kind,data:{},invalid:[],unknowns:[],body:""} |
  if $record.read_error? then .invalid=$fields | .unknowns=[issue("unreadable";.path;$record.read_error)]
  else ($record.text | gsub("<!--.*?-->";"";"m") | split("\n") | map(rtrimstr("\r"))) as $lines |
    .body=($lines|join("\n")) |
    if ($lines|length) == 0 or ($lines[0]|trim) != "---" then .invalid=$fields | .unknowns=[issue("frontmatter";.path;"Missing YAML frontmatter.")]
    else ([range(1; $lines|length) | select(($lines[.]|trim) == "---")][0]) as $end |
    if $end == null then .invalid=$fields | .unknowns=[issue("frontmatter";.path;"Unclosed YAML frontmatter.")]
    else .body=($lines[$end+1:]|join("\n")) | .cursor=1 |
      until(.cursor >= $end;
        .cursor as $i | $lines[$i] as $line |
        ([$line|capture("^(?<key>[A-Za-z_][\\w-]*):(?:\\s+(?<raw>.*)|\\s*)$")][0]) as $match |
        if $match == null then
          .cursor += 1 |
          if ($line|trim) != "" and ($line|test("^\\s|^#")|not) then
            .invalid |= (. + $fields|unique) | .unknowns += [issue("frontmatter";.path;"Unsupported frontmatter line: " + $line)]
          else . end
        else $match.key as $key |
          ([range($i+1;$end) | select(($lines[.]|trim) != "" and ($lines[.]|test("^\\s|^- ")|not))][0] // $end) as $next |
          .cursor=$next |
          if ($fields|index($key)) == null then . else
            (try (
              if (.data|has($key)) or bad($key) then error("duplicate field") else . end |
              ($match.raw // "" | uncomment) as $raw |
              ($lines[$i+1:$next] | map(uncomment|trim) | map(select(. != ""))) as $nested |
              if ($key|listfield) then
                if $raw != "" then
                  if ($nested|length)>0 then error("list has both inline and block content") else $raw|inline_list end
                else $nested|map(if startswith("- ") then .[2:]|scalar|if . == null then error("list entries must be strings") else . end else error("unsupported block list") end) end
              else if ($nested|length)>0 then error("expected a scalar, found block content") else $raw|scalar end end |
              {value:.}
             ) catch {error:.}) as $parsed |
            if $parsed|has("error") then
              .invalid |= (. + [$key]|unique) | del(.data[$key]) | .unknowns += [issue("unsupported_field";.path;$key + ": " + $parsed.error)]
            else .data[$key]=$parsed.value end
          end
        end) | del(.cursor)
    end end
  end;
def prepare:
  if .kind == "plan" then
    if .data.dropped != null and .data.dropped != "" and (.data.dropped|test("^[0-9]{4}-[0-9]{2}-[0-9]{2}(?:\\s|$)")|not) then
      .invalid |= (. + ["dropped"]|unique) | .unknowns += [issue("unsupported_field";.path;"dropped must start with its decision date.")]
    else . end |
    if (bad("exec_runs") or bad("exec_run")) then .runs=[]
    elif .data.exec_run != null and .data.exec_run != "" then
      if .data|has("exec_runs") then .runs=[] | .unknowns += [issue("unsupported_field";.path;"Both exec_run and exec_runs are present.")] | .invalid += ["run_selection"]
      else .runs=[.data.exec_run] end
    else .runs=(.data.exec_runs // []) end
  else . end;
def safe_run: type == "string" and test("^[A-Za-z0-9][A-Za-z0-9_.-]*\\z") and . != "." and . != ".." and . != "dropped";
def safe_plan: type == "string" and (contains("/")|not) and endswith("_plan.md");
def resolution($plans;$name;$path;$kind):
  if ($name|safe_plan)|not then {node:null,findings:[],unknowns:[issue("unsupported_reference";$path;$kind + " must be a plan filename: " + ($name|textvalue))]}
  else [$plans[] | select(.name == $name)] as $matches |
    if ($matches|length) == 1 then {node:$matches[0],findings:[],unknowns:[]}
    elif ($matches|length) == 0 then {node:null,findings:[issue("missing_"+$kind;$path;"Plan does not exist in live/dropped inventory: " + $name + ".")],unknowns:[]}
    else {node:null,findings:[],unknowns:[]} end end;
def inherit($nodes;$node;$seen):
  if $node == null then false
  elif ($seen|index($node.path)) != null then null
  elif ($node|bad("dropped") or bad("parent")) then null
  elif $node.data.dropped != null and $node.data.dropped != "" then true
  elif $node.parent == null and ($node.data.parent != null and $node.data.parent != "none") then null
  else inherit($nodes; ([$nodes[]|select(.path == $node.parent)][0]); $seen + [$node.path]) end;
def walkcycle($nodes;$path;$edge):
  if (.active|index($path)) != null then
    .active[(.active|index($path)):] as $cycle |
    .cycles += [issue($edge+"_cycle";($cycle|min);"Cycle among " + ($cycle|map(split("/")[-1])|sort|join(", ")) + ".")]
  elif (.visited|index($path)) != null then .
  else .active += [$path] |
    ([$nodes[]|select(.path==$path)][0] | if $edge == "parent" then [.parent|select(.!=null)] else .deps end) as $edges |
    reduce $edges[] as $next (. ; walkcycle($nodes;$next;$edge)) |
    .active = .active[:-1] | .visited += [$path]
  end;
def cycles($nodes;$edge):
  reduce $nodes[].path as $path ({active:[],visited:[],cycles:[]}; walkcycle($nodes;$path;$edge)) | .cycles;
def stops:
  split("\n") | reduce .[] as $line ({section:false,lines:[]};
    if $line|test("^#{1,6}\\s+") then .section=($line|test("^##\\s+(?:Awaiting user\\b|待用户执行)";"i"))
    elif .section and ($line|test("^\\s*[-*]\\s+\\[ \\]\\s+\\S")) and ($line|test("<[^>]*>|【待定】|\\[TBD\\]";"i")|not) then .lines += [$line|trim]
    else . end) | .lines;
def checkrun($plans;$nodes;$run;$owner):
  $run.data as $d |
  (if $owner == null and ($run|bad("source_plan")|not) and $d.source_plan != null then resolution($plans;$d.source_plan;$run.path;"source_plan") else {node:$owner,findings:[],unknowns:[]} end) as $r |
  ($r.node as $rnode | if $rnode == null then null else [$nodes[]|select(.path==$rnode.path)][0] end) as $resolved_owner |
  ($resolved_owner != null and ($resolved_owner.runs|length)>0 and $resolved_owner.runs[-1]==$run.name) as $current |
  {findings: (
    (if ($run|bad("run")|not) and $d.run != $run.name then [issue("run_name_mismatch";$run.path;"Run field does not match directory/run name " + $run.name + ".")] else [] end) +
    (if ($run|bad("source_plan")|not) then
       if $owner != null and $d.source_plan != $owner.name then [issue("source_plan_mismatch";$run.path;"Run claimed by " + $owner.name + " names source_plan " + ($d.source_plan|textvalue) + ".")]
       elif $owner == null and $d.source_plan == null then [issue("missing_source_plan";$run.path;"Run has no source_plan.")]
       else $r.findings end else [] end) +
    (if $resolved_owner != null and ($resolved_owner.runs|index($run.name)) != null and ($current|not) then []
     elif ($d.status|terminal) or ($current and (($resolved_owner|bad("exec_status"))|not) and ($resolved_owner.data.exec_status|terminal)) or ($current and $resolved_owner.dropped == true) then
       [$run.body|stops[]|issue("terminal_open_stop";$run.path;"Terminal/dropped state still has an unchecked STOP command: " + .)] else [] end)
   ), unknowns: ($r.unknowns + (if ($run|bad("status")|not) and ($d.status|status|not) then [issue("unsupported_field";$run.path;"Missing or unrecognized run status.")] else [] end))};
def validate:
  .plans as $plans |
  .unknowns += [$plans[]|.unknowns[]] |
  .unknowns += [$plans|group_by(.name)[]|select(length>1)|issue("ambiguous_plan";.[0].name;"Duplicate filename in live/dropped inventory.")] |
  .nodes=[$plans[] as $p|select(([$plans[]|select(.name==$p.name)]|length)==1)|$p|.parent=null|.deps=[]] |
  reduce range(0;.nodes|length) as $i (. ;
    .nodes[$i] as $n |
    if ($n|bad("parent")|not) and $n.data.parent != null and $n.data.parent != "none" then
      resolution($plans;$n.data.parent;$n.path;"parent") as $r |
      .nodes[$i].parent=$r.node.path | .findings += $r.findings | .unknowns += $r.unknowns
    else . end |
    if $n|bad("children")|not then reduce ($n.data.children // [])[] as $child (. ;
      resolution($plans;$child;$n.path;"child") as $r |
      .findings += $r.findings | .unknowns += $r.unknowns |
      if $r.node != null and ($r.node|bad("parent")|not) and $r.node.data.parent != $n.name then .findings += [issue("parent_child_mismatch";$n.path;$child + " does not name this plan as parent.")] else . end)
    else . end) |
  .nodes as $nodes |
  .findings += [$nodes[] as $n | $nodes[] | select(.path==$n.parent) | select((bad("children")|not) and ((.data.children // [])|index($n.name)) == null) | issue("unlisted_child";$n.path;"Authoritative parent does not list this child: " + .name + ".")] |
  .findings += cycles($nodes;"parent") |
  .nodes |= map(.dropped=inherit($nodes;.;[])) |
  .nodes as $nodes |
  reduce range(0;.nodes|length) as $i (. ; .nodes[$i] as $n |
    if ($n|bad("depends_on") or bad("parent")|not) and ($n.parent != null or $n.data.parent == null or $n.data.parent == "none") then
      reduce ($n.data.depends_on // [])[] as $prefix (. ;
        [$nodes[]|select(.parent==$n.parent and (bad("parent")|not) and (.parent != null or .data.parent == null or .data.parent == "none"))] as $peers |
        [$peers[]|select((bad("prefix")|not) and .data.prefix==$prefix)] as $siblings |
        ([$plans|group_by(.name)[]|select(length>1)|.[]|select(.data.prefix==$prefix)]|length>0) as $ambiguous |
        ([$peers[]|select(bad("prefix") or .data.prefix==null or .data.prefix=="")]|length>0) as $incomplete |
        if $ambiguous or (($siblings|length)==0 and $incomplete) then .unknowns += [issue("dependency_resolution";$n.path;"Cannot resolve sibling prefix with ambiguous/incomplete plan metadata: " + $prefix + ".")]
        elif ($siblings|length) != 1 then
          if ($siblings|length)>0 then .unknowns += [issue("dependency_resolution";$n.path;"Dependency is not one unambiguous sibling prefix: " + $prefix + ".")]
          else .findings += [issue("missing_dependency";$n.path;"Dependency is not one unambiguous sibling prefix: " + $prefix + ".")] end
        else $siblings[0] as $dep | .nodes[$i].deps += [$dep.path] |
          if $n.dropped==false and ($dep.dropped==true or $dep.data.exec_status=="abandoned" or $dep.data.exec_status=="skipped") then .findings += [issue("unavailable_dependency";$n.path;"Active plan depends on dropped/abandoned plan " + $dep.name + ".")] else . end
        end)
    else . end |
    if ($n|bad("exec_status")|not) and $n.data.exec_status != null and ($n.data.exec_status|status|not) then
      .nodes[$i].invalid += ["exec_status"] | .unknowns += [issue("unsupported_field";$n.path;"Unrecognized exec_status: " + ($n.data.exec_status|textvalue))]
    else . end |
    if ($n|bad("exec_runs") or bad("exec_run") or bad("run_selection")|not) and $n.data.exec_status=="done" and ($n.runs|length)==0 then .findings += [issue("done_without_run";$n.path;"Done plan has no execution run.")] else . end) |
  .findings += cycles(.nodes;"dependency") |
  .nodes as $nodes | .runs as $runs |
  .unknowns += [$runs[]|.unknowns[]] |
  reduce $nodes[] as $n (. ; reduce $n.runs[] as $name (. ;
    if ($name|safe_run)|not then .unknowns += [issue("unsupported_run";$n.path;"Run names must name one wkdrs directory: " + ($name|textvalue))]
    else ([$runs[]|select(.name==$name)][0]) as $run |
      if $run != null then checkrun($plans;$nodes;$run;$n) as $r | .findings += $r.findings | .unknowns += $r.unknowns
      else . end end)) |
  reduce $runs[] as $run (. ;
    if ([$nodes[]|.runs[]|select(.==$run.name)]|length)==0 then checkrun($plans;$nodes;$run;null) as $r | .findings += $r.findings | .unknowns += $r.unknowns else . end) |
  {findings:(.findings|unique|sort_by(.path,.code,.message)), unknowns:(.unknowns|unique|sort_by(.path,.code,.message))};
'

records=
append_record() { records=$records$1$'\n'; }
read_record() {
    local kind=$1 name=$2 path=$3 record message
    if [ ! -f "$path" ] || [ ! -r "$path" ]; then
        message='File is not a readable regular file.'
        append_record "$(jq -cn --arg kind "$kind" --arg name "$name" --arg path "$path" --arg error "$message" '{kind:$kind,name:$name,path:$path,read_error:$error}')"
    elif ! iconv -f UTF-8 -t UTF-8 "$path" >/dev/null 2>&1; then
        append_record "$(jq -cn --arg kind "$kind" --arg name "$name" --arg path "$path" '{kind:$kind,name:$name,path:$path,read_error:"Cannot read UTF-8 text."}')"
    elif record=$(jq -Rsc --arg kind "$kind" --arg name "$name" --arg path "$path" '{kind:$kind,name:$name,path:$path,text:.}' "$path" 2>/dev/null); then
        append_record "$record"
    else
        append_record "$(jq -cn --arg kind "$kind" --arg name "$name" --arg path "$path" '{kind:$kind,name:$name,path:$path,read_error:"Cannot read file."}')"
    fi
}
inventory_error() {
    append_record "$(jq -cn --arg path "$1" '{kind:"inventory_error",code:"unreadable",path:$path,message:"Cannot enumerate directory."}')"
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
    result=$(jq -cn --arg root "$root" '{findings:[],unknowns:[{code:"unreadable",path:$root,message:"Root is not a directory."}]}')
else
    collect "$root/metds/plans" plan
    collect "$root/metds/plans/dropped" plan
    collect "$root/wkdrs" run
    collect "$root/wkdrs/dropped" run
    state=$(printf '%s' "$records" | jq -sc "$common"'
      {plans:[.[]|select(.kind=="plan")|document|prepare],runs:[.[]|select(.kind=="run")|document],findings:[],unknowns:[.[]|select(.kind=="inventory_error")|del(.kind)]}') || exit 2
    # Preserve live-before-dropped precedence and resolve only explicitly named runs.
    state=$(printf '%s' "$state" | jq -c '.runs |= (reduce .[] as $r ([]; if any(.[];.name==$r.name) then . else .+[$r] end))')
    names=$(printf '%s' "$state" | jq -r "$common"'.plans | group_by(.name)[] | select(length==1) | .[0].runs[] | select(safe_run)' | sort -u)
    trees='' trees_loaded=false trees_available=false
    resolved='' resolution_issues=''
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if printf '%s' "$state" | jq -e --arg name "$name" 'any(.runs[];.name==$name)' >/dev/null; then continue; fi
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
                                    resolved=$resolved$(printf '%s' "$content" | jq -Rsc --arg name "$name" --arg path "$spec" '{kind:"run",name:$name,path:$path,text:.}')$'\n'
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
            owners=$(printf '%s' "$state" | jq -c --arg name "$name" '[.plans|group_by(.name)[]|select(length==1)|.[0]|select(.runs|index($name))|.path]')
            resolution_issues=$resolution_issues$(printf '%s' "$owners" | jq -c --arg code "$code" --arg reason "$reason" --argjson unknown "$unknown" '.[]|{code:$code,path:.,message:$reason,unknown:$unknown}')$'\n'
        fi
    done < <(printf '%s\n' "$names")
    extra=$(printf '%s' "$resolved" | jq -sc "$common"'map(document)') || exit 2
    issues=$(printf '%s' "$resolution_issues" | jq -sc '.')
    result=$(printf '%s\n%s\n%s\n' "$state" "$extra" "$issues" | jq -sc "$common"'
      . as $all | .[0] | .runs += $all[1] |
      .findings += [$all[2][]|select(.unknown|not)|del(.unknown)] |
      .unknowns += [$all[2][]|select(.unknown)|del(.unknown)] | validate') || exit 2
fi
if [ "$json" = true ]; then
    printf '%s\n' "$result" | jq .
else
    printf '%s' "$result" | jq -r '
      if (.findings|length)==0 and (.unknowns|length)==0 then "No workflow state inconsistencies found."
      else (.findings[]|"finding \(.code): \(.path): \(.message)"),(.unknowns[]|"unknown \(.code): \(.path): \(.message)") end'
fi
printf '%s' "$result" | jq -e '.unknowns|length>0' >/dev/null && exit 2
printf '%s' "$result" | jq -e '.findings|length>0' >/dev/null && exit 1
exit 0
