# A strict JSON reader/writer and small tree API; no user text is evaluated.
# NUL strings are rejected because shell variables cannot preserve them.
{ if(!streaming) input = input $0 "\n" }
function a(i) { return i<=ENVIRON["STAR_JSON_ARG_COUNT"] ? ENVIRON["STAR_JSON_ARG_" i] : "" }
function reset_json() { serial=0; split("",types); split("",values); split("",children); split("",keys); split("",sizes) }
function parse_error(message) { parse_failure=message; return 0 }
function die(message) { print "JSON: " message > "/dev/stderr"; exit 2 }
function node(type,value,    id) { id=++serial; types[id]=type; values[id]=value; return id }
function string(value) { return node("string",value) }
function number(value) { return node("number",value) }
function boolean(value) { return node("boolean",value ? "true" : "false") }
function null() { return node("null","null") }
function object() { return node("object","") }
function array() { return node("array","") }
function put(id,key,value) {
    if (!((id SUBSEP key) in children)) keys[id,++sizes[id]]=key
    children[id,key]=value; return id
}
function add(id,value) { return put(id,sizes[id]+0,value) }
function get(id,key) { return ((id SUBSEP key) in children) ? children[id,key] : 0 }
function val(id) { return values[id] }
function field(id,key,    x) { x=get(id,key); return type(x)=="null" ? "" : val(x) }
function size(id) { return sizes[id]+0 }
function type(id) { return types[id] }
function has(id,key) { return (id SUBSEP key) in children }
function at(id,path,    n,p,i,key) {
    gsub(/\[|\]/,".",path); sub(/^\./,"",path); n=split(path,p,".")
    for(i=1;i<=n;i++) if(p[i]!="") {
        key=p[i]; if(type(id)=="array" && key ~ /^-[0-9]+$/) key=size(id)+key
        id=get(id,key)
    }
    return id
}
function raw(id) { if(type(id)=="string") print val(id); else print json(id) }
function quote(text,    i,c,out,n) {
    out="\""
    for(i=1;i<=length(text);i++) {
        c=substr(text,i,1)
        if(c=="\"" || c=="\\") out=out "\\" c
        else if(c=="\n") out=out "\\n"
        else if(c=="\r") out=out "\\r"
        else if(c=="\t") out=out "\\t"
        else if(c==sprintf("%c",8)) out=out "\\b"
        else if(c==sprintf("%c",12)) out=out "\\f"
        else if(c ~ /[[:cntrl:]]/) {
            for(n=0;n<128;n++) if(c==sprintf("%c",n)) break
            out=out sprintf("\\u%04x",n)
        } else out=out c
    }
    return out "\""
}
function json(id,    out,i,j,key,list,n,temp) {
    if(!id) return "null"
    if(type(id)=="string") return quote(val(id))
    if(type(id)!="array" && type(id)!="object") return val(id)
    n=size(id); for(i=1;i<=n;i++) list[i]=keys[id,i]
    if(type(id)=="object") for(i=2;i<=n;i++) {
        temp=list[i]; j=i-1
        while(j>0 && ("x" list[j]) > ("x" temp)) { list[j+1]=list[j]; j-- }
        list[j+1]=temp
    }
    out=type(id)=="array" ? "[" : "{"
    for(i=1;i<=n;i++) { key=list[i]; out=out (i>1 ? "," : "") (type(id)=="object" ? quote(key) ":" : "") json(get(id,key)) }
    return out (type(id)=="array" ? "]" : "}")
}
function equal(x,y,    i,key) {
    if(type(x)!=type(y)) return 0
    if(type(x)=="number") return val(x)+0==val(y)+0
    if(type(x)!="object" && type(x)!="array") return (val(x) "x")== (val(y) "x")
    if(size(x)!=size(y)) return 0
    for(i=1;i<=size(x);i++) {key=keys[x,i]; if(!has(y,key) || !equal(get(x,key),get(y,key))) return 0}
    return 1
}
function contains(id,value,    i) { for(i=0;i<size(id);i++) if(equal(get(id,i),value)) return 1; return 0 }
function less(x,y,fields,    f,n,i,left,right) {
    n=split(fields,f,",")
    if(fields=="") {left=type(x)=="string" ? val(x) : json(x); right=type(y)=="string" ? val(y) : json(y); return ("x" left)<("x" right)}
    for(i=1;i<=n;i++) {left=field(x,f[i]); right=field(y,f[i]); if((left "x")!=(right "x")) return ("x" left)<("x" right)}
    return 0
}
function sorted(id,fields,unique,    result,list,n,i,j,tmp) {
    n=size(id); for(i=1;i<=n;i++) list[i]=get(id,i-1)
    for(i=2;i<=n;i++) {tmp=list[i]; j=i-1; while(j>0 && less(tmp,list[j],fields)) {list[j+1]=list[j]; j--}; list[j+1]=tmp}
    result=array()
    for(i=1;i<=n;i++) if(!unique || i==1 || !equal(list[i],list[i-1])) add(result,list[i])
    return result
}
function merge(x,y,    result,i,key) {
    result=object()
    for(i=1;i<=size(x);i++) {key=keys[x,i]; put(result,key,get(x,key))}
    for(i=1;i<=size(y);i++) {key=keys[y,i]; put(result,key,get(y,key))}
    return result
}
function whitespace() { while(substr(source,pos,1) ~ /[ \t\r\n]/ && pos<=length(source)) pos++ }
function hex4(    text,i,c,n) {
    text=substr(source,pos,4); if(length(text)!=4 || text ~ /[^0-9a-fA-F]/) return parse_error("invalid Unicode escape")
    pos+=4; n=0; for(i=1;i<=4;i++) {c=tolower(substr(text,i,1)); n=n*16+index("0123456789abcdef",c)-1}; return n
}
function utf8(n) {
    if(n<128) return sprintf("%c",n)
    if(n<2048) return sprintf("%c%c",192+int(n/64),128+n%64)
    if(n<65536) return sprintf("%c%c%c",224+int(n/4096),128+int(n/64)%64,128+n%64)
    return sprintf("%c%c%c%c",240+int(n/262144),128+int(n/4096)%64,128+int(n/64)%64,128+n%64)
}
function readstring(    out,c,n,low) {
    pos++; out=""
    while(pos<=length(source)) {
        c=substr(source,pos++,1)
        if(c=="\"") return out
        if(c=="\\") {
            c=substr(source,pos++,1)
            if(c=="u") {
                n=hex4(); if(parse_failure!="") return ""; if(n==0) return parse_error("NUL strings cannot be represented by shell variables")
                if(n>=55296 && n<=56319) {
                    if(substr(source,pos,2)!="\\u") return parse_error("unpaired Unicode surrogate")
                    pos+=2; low=hex4(); if(parse_failure!="") return ""; if(low<56320 || low>57343) return parse_error("unpaired Unicode surrogate")
                    n=65536+(n-55296)*1024+low-56320
                } else if(n>=56320 && n<=57343) return parse_error("unpaired Unicode surrogate")
                c=utf8(n)
            } else if(c=="n") c="\n"; else if(c=="r") c="\r"; else if(c=="t") c="\t"
            else if(c=="b") c=sprintf("%c",8); else if(c=="f") c=sprintf("%c",12)
            else if(c!="\"" && c!="\\" && c!="/") return parse_error("invalid string escape")
        } else if(c ~ /[[:cntrl:]]/ && c!=sprintf("%c",127)) return parse_error("unescaped control character")
        out=out c
    }
    return parse_error("unclosed string")
}
function readvalue(depth,    c,id,key,value,token) {
    if(depth>128) return parse_error("nesting exceeds 128 levels")
    whitespace(); c=substr(source,pos,1)
    if(c=="\"") { token=readstring(); if(parse_failure!="") return 0; return string(token) }
    if(c=="{" || c=="[") {
        id=c=="{" ? object() : array(); pos++; whitespace()
        if(substr(source,pos,1)==(c=="{" ? "}" : "]")) {pos++; return id}
        while(1) {
            whitespace()
            if(c=="{") {if(substr(source,pos,1)!="\"") return parse_error("expected object key"); key=readstring(); if(parse_failure!="") return 0; whitespace(); if(substr(source,pos++,1)!=":") return parse_error("expected colon")}
            else key=size(id)
            value=readvalue(depth+1); if(!value) return 0; put(id,key,value); whitespace(); token=substr(source,pos++,1)
            if(token==(c=="{" ? "}" : "]")) return id
            if(token!=",") return parse_error("expected comma or closing delimiter")
        }
    }
    token=substr(source,pos)
    if(match(token,/^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/)) {token=substr(token,1,RLENGTH); pos+=length(token); return number(token)}
    if(substr(token,1,4)=="true") {pos+=4; return boolean(1)}
    if(substr(token,1,5)=="false") {pos+=5; return boolean(0)}
    if(substr(token,1,4)=="null") {pos+=4; return null()}
    return parse_error("expected JSON value")
}
function tryparse(text,    id) { parse_failure=""; source=text; pos=1; id=readvalue(0); if(!id) return 0; whitespace(); if(pos<=length(source)) return parse_error("extra JSON data"); return id }
function parse(text,    id) { id=tryparse(text); if(!id) die(parse_failure); return id }
function stream(text,    result,value) { parse_failure=""; source=text; pos=1; result=array(); whitespace(); while(pos<=length(source)) {value=readvalue(0); if(!value) die(parse_failure); add(result,value); whitespace()}; return result }
function document() { return parse(input) }
