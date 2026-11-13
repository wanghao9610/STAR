# Schema checks for recoverable experiment launches and collection receipts.
function nonempty(id) { return type(id)=="string" && length(val(id))>0 }
function pathvalue(id) { return nonempty(id) && substr(val(id),1,1)=="/" && val(id) !~ /[\r\n]/ }
function versionvalue(id,    s) { s=tolower(val(id)); gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return nonempty(id) && s !~ /^(unknown|unrecorded|none)?$/ }
function integer(id) { return type(id)=="number" && val(id)+0==int(val(id)+0) }
function paths(id,required,    seen,i,x) {
    if(type(id)!="array" || (required && !size(id))) return 0
    for(i=0;i<size(id);i++) { x=get(id,i); if(!pathvalue(x) || seen[val(x)]++) return 0 }
    return 1
}
function statevalid(r,    args,i) {
    args=get(r,"command_argv")
    if(type(r)!="object" || type(get(r,"schema"))!="number" || field(r,"schema")+0!=1 || type(get(r,"attempt"))!="string" || field(r,"attempt") !~ /^[0-9a-f]{32}$/ || !nonempty(get(r,"prepared_at")) || !pathvalue(get(r,"cwd")) || type(args)!="array" || !size(args) || !versionvalue(get(r,"code_version")) || !versionvalue(get(r,"review_version")) || !integer(get(r,"pid")) || field(r,"pid")+0<=0 || !pathvalue(get(r,"log")) || !paths(get(r,"outputs"),1)) return 0
    for(i=0;i<size(args);i++) if(type(get(args,i))!="string") return 0
    return 1
}
function subset(x,y,    i) { for(i=0;i<size(x);i++) if(!contains(y,get(x,i))) return 0; return 1 }
function receiptvalid(r,    outputs,verified) {
    outputs=get(r,"outputs"); verified=get(r,"verified_outputs")
    return statevalid(r) && integer(get(r,"exit_code")) && nonempty(get(r,"exited_at")) && nonempty(get(r,"collected_at")) && pathvalue(get(r,"verification_evidence")) && type(get(r,"evidence_sha256"))=="string" && field(r,"evidence_sha256") ~ /^[0-9a-f]{64}$/ && paths(verified,0) && subset(verified,outputs) && (field(r,"exit_code")+0==0 ? field(r,"result")=="collected" && equal(sorted(verified,"",0),sorted(outputs,"",0)) : field(r,"result")=="failed")
}
function launchfields(r,    out,f,n,i) {
    out=object(); n=split("schema attempt prepared_at cwd command_argv code_version review_version pid log outputs",f," ")
    for(i=1;i<=n;i++) put(out,f[i],get(r,f[i])); return out
}
