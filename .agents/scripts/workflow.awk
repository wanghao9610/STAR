# Parse STAR's documented frontmatter subset and validate its plan/run graph.
function trim(s) { sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); return s }
function issue(code,path,message,    r) { r=object(); put(r,"code",string(code)); put(r,"path",string(path)); put(r,"message",string(message)); return r }
function finding(code,path,message) { add(G_findings,issue(code,path,message)) }
function unknown(code,path,message) { add(G_unknowns,issue(code,path,message)) }
function invalid(n,key) { return contains(get(n,"invalid"),string(key)) }
function mark(n,key) { if(!invalid(n,key)) add(get(n,"invalid"),string(key)) }
function data(n,key) { return field(get(n,"data"),key) }
function value(n,key) { return get(get(n,"data"),key) }
function terminal(s) { return s=="done" || s=="abandoned" || s=="skipped" }
function status(s) { return s=="pending" || s=="in_progress" || s=="blocked" || terminal(s) }
function textvalue(id) { return !id || type(id)=="null" ? "None" : val(id) }
function uncomment(s,    i,c,q,out) {
    q=""; out=""
    for(i=1;i<=length(s);i++) {
        c=substr(s,i,1)
        if(q=="\"" && c=="\\") {out=out c substr(s,++i,1); continue}
        if(q=="\047" && c==q && substr(s,i+1,1)==q) {out=out c c; i++; continue}
        if(q!="" && c==q) q=""
        else if(q=="" && (c=="\"" || c=="\047") && (trim(out)=="" || trim(out) ~ /[\[,]$/ || trim(out)=="-")) q=c
        else if(q=="" && c=="#" && (i==1 || substr(s,i-1,1) ~ /[[:space:]]/)) break
        out=out c
    }
    if(q!="") parse_message="unclosed quote"
    return trim(out)
}
function scalar(s,    id) {
    s=uncomment(s); if(parse_message!="") return 0
    if(s=="" || s ~ /^(null|Null|NULL|~)$/) return null()
    if(substr(s,1,1)=="\"") {
        id=tryparse(s); if(!id || type(id)!="string") {parse_message="unsupported quoted scalar"; return 0}
    } else if(substr(s,1,1)=="\047") {
        if(s !~ /^\047([^\047]|\047\047)*\047$/) {parse_message="unsupported quoted scalar"; return 0}
        s=substr(s,2,length(s)-2); gsub(/\047\047/,"\047",s); id=string(s)
    } else {
        if(s ~ /^[\[{}\]&*!|>@`]/ || index(s,": ") || index(s,"\t")) {parse_message="unsupported scalar syntax"; return 0}
        id=string(s)
    }
    if(val(id) ~ /[<>]/) {parse_message="unfilled template placeholder"; return 0}
    return id
}
function inline_list(s,    result,i,c,q,start,piece,id) {
    result=array()
    if(substr(s,1,1)!="[" || substr(s,length(s))!="]") {parse_message="expected an inline or multiline list"; return 0}
    s=trim(substr(s,2,length(s)-2)); if(s=="") return result
    q=""; start=1
    for(i=1;i<=length(s)+1;i++) {
        c=substr(s,i,1)
        if(q=="\"" && c=="\\") {i++; continue}
        if(q=="\047" && c==q && substr(s,i+1,1)==q) {i++; continue}
        if(q!="" && c==q) q=""
        else if(q=="" && (c=="\"" || c=="\047")) q=c
        else if(q=="" && c ~ /[\[\]{}]/) {parse_message="nested lists/maps are unsupported"; return 0}
        else if(q=="" && (c=="," || i>length(s))) {
            piece=trim(substr(s,start,i-start)); start=i+1
            if(i>length(s) && piece=="" && size(result)) break
            id=scalar(piece); if(!id) return 0
            if(type(id)=="null") {parse_message="list entries must be strings"; return 0}; add(result,id)
        }
    }
    if(q!="") {parse_message="unclosed quote"; return 0}
    return result
}
function doc_issue(n,code,message) { add(get(n,"unknowns"),issue(code,field(n,"path"),message)) }
function document_record(record,    n,kind,fields,nf,f,i,j,k,text,lines,nlines,end,line,key,raw,nested,nn,v,list,child,nextline,opening,closing) {
    n=object(); kind=field(record,"kind"); put(n,"kind",string(kind)); put(n,"name",get(record,"name")); put(n,"path",get(record,"path")); put(n,"data",object()); put(n,"invalid",array()); put(n,"unknowns",array()); put(n,"body",string(""))
    fields=kind=="plan" ? "parent prefix children depends_on exec_status exec_runs exec_run dropped" : "run source_plan status branch worktree"; nf=split(fields,f," ")
    if(has(record,"read_error")) {for(i=1;i<=nf;i++) mark(n,f[i]); doc_issue(n,"unreadable",field(record,"read_error")); return n}
    text=field(record,"text")
    while((opening=index(text,"<!--")) && (closing=index(substr(text,opening+4),"-->"))) text=substr(text,1,opening-1) substr(text,opening+4+closing+2)
    nlines=split(text,lines,"\n"); for(i=1;i<=nlines;i++) sub(/\r$/,"",lines[i]); put(n,"body",string(text))
    if(trim(lines[1])!="---") {for(i=1;i<=nf;i++) mark(n,f[i]); doc_issue(n,"frontmatter","Missing YAML frontmatter."); return n}
    end=0; for(i=2;i<=nlines;i++) if(trim(lines[i])=="---") {end=i; break}
    if(!end) {for(i=1;i<=nf;i++) mark(n,f[i]); doc_issue(n,"frontmatter","Unclosed YAML frontmatter."); return n}
    text=""; for(i=end+1;i<=nlines;i++) text=text (i>end+1 ? "\n" : "") lines[i]; put(n,"body",string(text))
    i=2
    while(i<end) {
        line=lines[i]
        if(line !~ /^[A-Za-z_][A-Za-z_0-9-]*:([[:space:]]|$)/) {
            if(trim(line)!="" && line !~ /^[[:space:]#]/) {for(k=1;k<=nf;k++) mark(n,f[k]); doc_issue(n,"frontmatter","Unsupported frontmatter line: " line)}
            i++; continue
        }
        key=line; sub(/:.*/,"",key); raw=substr(line,length(key)+2); nextline=end
        for(j=i+1;j<end;j++) if(trim(lines[j])!="" && lines[j] !~ /^[[:space:]]|^- /) {nextline=j; break}
        k=0; for(j=1;j<=nf;j++) if(f[j]==key) k=1
        if(!k) {i=nextline; continue}
        parse_message=""; raw=uncomment(raw); nn=0
        for(j=i+1;j<nextline;j++) {nested[j]=uncomment(lines[j]); if(nested[j]!="") nn++}
        v=0
        if(has(get(n,"data"),key) || invalid(n,key)) parse_message="duplicate field"
        else if(parse_message=="") {
            if(key=="children" || key=="depends_on" || key=="exec_runs") {
                if(raw!="") {if(nn) parse_message="list has both inline and block content"; else v=inline_list(raw)}
                else {
                    v=array()
                    for(j=i+1;j<nextline && parse_message=="";j++) if(nested[j]!="") {
                        if(substr(nested[j],1,2)!="- ") {parse_message="unsupported block list"; break}
                        child=scalar(substr(nested[j],3)); if(child && type(child)!="null") add(v,child); else if(parse_message=="") parse_message="list entries must be strings"
                    }
                }
            } else {if(nn) parse_message="expected a scalar, found block content"; else v=scalar(raw)}
        }
        if(parse_message!="") {mark(n,key); put(get(n,"data"),key,null()); doc_issue(n,"unsupported_field",key ": " parse_message)}
        else put(get(n,"data"),key,v)
        i=nextline
    }
    return n
}
function safe_run(s) { return s ~ /^[A-Za-z0-9][A-Za-z0-9_.-]*$/ && s!="." && s!=".." && s!="dropped" }
function safe_plan(s) { return s !~ /\// && s ~ /_plan\.md$/ }
function prepare(n,    runs) {
    if(type(value(n,"dropped"))!="null" && data(n,"dropped")!="" && data(n,"dropped") !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}([[:space:]]|$)/) {mark(n,"dropped"); doc_issue(n,"unsupported_field","dropped must start with its decision date.")}
    runs=array()
    if(!invalid(n,"exec_runs") && !invalid(n,"exec_run")) {
        if(data(n,"exec_run")!="" && type(value(n,"exec_run"))!="null") {
            if(has(get(n,"data"),"exec_runs")) {mark(n,"run_selection"); doc_issue(n,"unsupported_field","Both exec_run and exec_runs are present.")}
            else add(runs,value(n,"exec_run"))
        } else if(type(value(n,"exec_runs"))=="array") runs=value(n,"exec_runs")
    }
    put(n,"runs",runs); return n
}
function prepare_state(records,    s,plans,runs,unknowns,i,r,n,key,j) {
    s=object(); plans=array(); runs=array(); unknowns=array()
    for(i=0;i<size(records);i++) {
        r=get(records,i)
        if(field(r,"kind")=="inventory_error") {add(unknowns,issue(field(r,"code"),field(r,"path"),field(r,"message"))); continue}
        n=document_record(r)
        if(field(r,"kind")=="plan") add(plans,prepare(n))
        else {key=field(n,"name"); j=0; for(k=0;k<size(runs);k++) if(field(get(runs,k),"name")==key) j=1; if(!j) add(runs,n)}
    }
    put(s,"plans",plans); put(s,"runs",runs); put(s,"findings",array()); put(s,"unknowns",unknowns); return s
}
function resolution(name,path,kind,    i,n,count,found) {
    if(!safe_plan(name)) {unknown("unsupported_reference",path,kind " must be a plan filename: " (name=="" ? "None" : name)); return 0}
    for(i=0;i<size(G_plans);i++) {n=get(G_plans,i); if(field(n,"name")==name) {count++; found=n}}
    if(count==1) return found
    if(!count) finding("missing_" kind,path,"Plan does not exist in live/dropped inventory: " name ".")
    return 0
}
function inherit(n,seen,    path,parent) {
    if(!n) return 0
    path=field(n,"path"); if(index(seen,"\034" path "\034")) return -1
    if(invalid(n,"dropped") || invalid(n,"parent")) return -1
    if(data(n,"dropped")!="" && type(value(n,"dropped"))!="null") return 1
    parent=field(n,"parent")
    if(parent=="" && data(n,"parent")!="" && data(n,"parent")!="none" && type(value(n,"parent"))!="null") return -1
    return inherit(G_by_path[parent],seen "\034" path "\034")
}
function walkcycle(n,edge,    path,i,j,nexts,nextpath,cycle,smallest,names) {
    path=field(n,"path"); if(active[path]) {
        cycle=array(); smallest=path; names=array()
        for(i=active[path];i<=active_count;i++) {nextpath=active_paths[i]; if(("x" nextpath)<("x" smallest)) smallest=nextpath; j=split(nextpath,parts,"/"); add(names,string(parts[j]))}
        names=sorted(names,"",0); cycle=""; for(i=0;i<size(names);i++) cycle=cycle (i ? ", " : "") val(get(names,i))
        finding(edge "_cycle",smallest,"Cycle among " cycle "."); return
    }
    if(visited[path]) return
    active[path]=++active_count; active_paths[active_count]=path
    if(edge=="parent") {nextpath=field(n,"parent"); if(nextpath!="") walkcycle(G_by_path[nextpath],edge)}
    else {nexts=get(n,"deps"); for(i=0;i<size(nexts);i++) walkcycle(G_by_path[val(get(nexts,i))],edge)}
    active_count--; active[path]=0; visited[path]=1
}
function cycles(edge,    i) { split("",active); split("",visited); active_count=0; for(i=0;i<size(G_nodes);i++) walkcycle(get(G_nodes,i),edge) }
function checkrun(run,owner,    resolved,current,runs,i,name,path,lines,nlines,line,section,historical) {
    resolved=owner; path=field(run,"path"); name=field(run,"name")
    if(!owner && !invalid(run,"source_plan") && type(value(run,"source_plan"))!="null" && has(get(run,"data"),"source_plan")) resolved=resolution(data(run,"source_plan"),path,"source_plan")
    if(resolved) resolved=G_by_path[field(resolved,"path")]
    runs=get(resolved,"runs"); current=resolved && size(runs)>0 && val(get(runs,size(runs)-1))==name
    if(!invalid(run,"run") && data(run,"run")!=name) finding("run_name_mismatch",path,"Run field does not match directory/run name " name ".")
    if(!invalid(run,"source_plan")) {
        if(owner && data(run,"source_plan")!=field(owner,"name")) finding("source_plan_mismatch",path,"Run claimed by " field(owner,"name") " names source_plan " textvalue(value(run,"source_plan")) ".")
        else if(!owner && (!value(run,"source_plan") || type(value(run,"source_plan"))=="null")) finding("missing_source_plan",path,"Run has no source_plan.")
    }
    historical=resolved && contains(runs,string(name)) && !current
    if(!historical && (terminal(data(run,"status")) || (current && !invalid(resolved,"exec_status") && terminal(data(resolved,"exec_status"))) || (current && field(resolved,"inherited_drop")=="true"))) {
        nlines=split(field(run,"body"),lines,"\n"); section=0
        for(i=1;i<=nlines;i++) {
            line=lines[i]
            if(line ~ /^#{1,6}[[:space:]]+/) section=(tolower(line) ~ /^##[[:space:]]+(awaiting user([^[:alnum:]_]|$)|待用户执行)/)
            else if(section && line ~ /^[[:space:]]*[-*][[:space:]]+\[ \][[:space:]]+[^[:space:]]/ && tolower(line) !~ /<[^>]*>|【待定】|\[tbd\]/) finding("terminal_open_stop",path,"Terminal/dropped state still has an unchecked STOP command: " trim(line))
        }
    }
    if(!invalid(run,"status") && !status(data(run,"status"))) unknown("unsupported_field",path,"Missing or unrecognized run status.")
}
function validate(state,    i,j,k,n,p,r,path,name,names,children,child,parent,drop,dependencies,prefix,siblings,ambiguous,incomplete,dep,runs,run,claimed,issues) {
    G_plans=get(state,"plans"); G_runs=get(state,"runs"); G_findings=get(state,"findings"); G_unknowns=get(state,"unknowns"); G_nodes=array()
    for(i=0;i<size(G_plans);i++) {n=get(G_plans,i); names[field(n,"name")]++; issues=get(n,"unknowns"); for(j=0;j<size(issues);j++) add(G_unknowns,get(issues,j))}
    for(i=0;i<size(G_plans);i++) {
        n=get(G_plans,i); name=field(n,"name")
        if(names[name]>1) {if(!reported[name]++) unknown("ambiguous_plan",name,"Duplicate filename in live/dropped inventory."); continue}
        put(n,"parent",null()); put(n,"deps",array()); add(G_nodes,n); G_by_path[field(n,"path")]=n
    }
    for(i=0;i<size(G_nodes);i++) {
        n=get(G_nodes,i); path=field(n,"path")
        if(!invalid(n,"parent") && data(n,"parent")!="" && data(n,"parent")!="none" && type(value(n,"parent"))!="null") {p=resolution(data(n,"parent"),path,"parent"); if(p) put(n,"parent",get(p,"path"))}
        children=value(n,"children")
        if(!invalid(n,"children")) for(j=0;j<size(children);j++) {
            child=val(get(children,j)); p=resolution(child,path,"child")
            if(p && !invalid(p,"parent") && data(p,"parent")!=field(n,"name")) finding("parent_child_mismatch",path,child " does not name this plan as parent.")
        }
    }
    for(i=0;i<size(G_nodes);i++) {
        n=get(G_nodes,i); p=G_by_path[field(n,"parent")]
        if(p && !invalid(p,"children") && !contains(value(p,"children"),get(n,"name"))) finding("unlisted_child",field(n,"path"),"Authoritative parent does not list this child: " field(p,"name") ".")
    }
    cycles("parent")
    for(i=0;i<size(G_nodes);i++) {n=get(G_nodes,i); drop=inherit(n,""); put(n,"inherited_drop",drop<0 ? null() : boolean(drop))}
    for(i=0;i<size(G_nodes);i++) {
        n=get(G_nodes,i); path=field(n,"path"); parent=field(n,"parent")
        if(!invalid(n,"depends_on") && !invalid(n,"parent") && (parent!="" || data(n,"parent")=="" || data(n,"parent")=="none" || type(value(n,"parent"))=="null")) {
            dependencies=value(n,"depends_on")
            for(j=0;j<size(dependencies);j++) {
                prefix=val(get(dependencies,j)); siblings=array(); ambiguous=0; incomplete=0
                for(k=0;k<size(G_plans);k++) {p=get(G_plans,k); if(names[field(p,"name")]>1 && data(p,"prefix")==prefix) ambiguous=1}
                for(k=0;k<size(G_nodes);k++) {
                    p=get(G_nodes,k)
                    if(field(p,"parent")!=parent || invalid(p,"parent") || (field(p,"parent")=="" && data(p,"parent")!="" && data(p,"parent")!="none" && type(value(p,"parent"))!="null")) continue
                    if(invalid(p,"prefix") || data(p,"prefix")=="" || type(value(p,"prefix"))=="null") incomplete=1
                    if(!invalid(p,"prefix") && data(p,"prefix")==prefix) add(siblings,p)
                }
                if(ambiguous || (!size(siblings) && incomplete)) unknown("dependency_resolution",path,"Cannot resolve sibling prefix with ambiguous/incomplete plan metadata: " prefix ".")
                else if(size(siblings)!=1) {
                    if(size(siblings)) unknown("dependency_resolution",path,"Dependency is not one unambiguous sibling prefix: " prefix ".")
                    else finding("missing_dependency",path,"Dependency is not one unambiguous sibling prefix: " prefix ".")
                } else {
                    dep=get(siblings,0); add(get(n,"deps"),get(dep,"path"))
                    if(field(n,"inherited_drop")=="false" && (field(dep,"inherited_drop")=="true" || data(dep,"exec_status")=="abandoned" || data(dep,"exec_status")=="skipped")) finding("unavailable_dependency",path,"Active plan depends on dropped/abandoned plan " field(dep,"name") ".")
                }
            }
        }
        if(!invalid(n,"exec_status") && has(get(n,"data"),"exec_status") && type(value(n,"exec_status"))!="null" && !status(data(n,"exec_status"))) {mark(n,"exec_status"); unknown("unsupported_field",path,"Unrecognized exec_status: " textvalue(value(n,"exec_status")))}
        if(!invalid(n,"exec_runs") && !invalid(n,"exec_run") && !invalid(n,"run_selection") && data(n,"exec_status")=="done" && !size(get(n,"runs"))) finding("done_without_run",path,"Done plan has no execution run.")
    }
    cycles("dependency")
    for(i=0;i<size(G_runs);i++) {run=get(G_runs,i); issues=get(run,"unknowns"); for(j=0;j<size(issues);j++) add(G_unknowns,get(issues,j))}
    for(i=0;i<size(G_nodes);i++) {
        n=get(G_nodes,i); runs=get(n,"runs")
        for(j=0;j<size(runs);j++) {
            name=val(get(runs,j)); if(!safe_run(name)) {unknown("unsupported_run",field(n,"path"),"Run names must name one wkdrs directory: " name); continue}
            claimed[name]=1; for(k=0;k<size(G_runs);k++) {run=get(G_runs,k); if(field(run,"name")==name) checkrun(run,n)}
        }
    }
    for(i=0;i<size(G_runs);i++) {run=get(G_runs,i); if(!claimed[field(run,"name")]) checkrun(run,0)}
    r=object(); put(r,"findings",sorted(G_findings,"path,code,message",1)); put(r,"unknowns",sorted(G_unknowns,"path,code,message",1)); return r
}
