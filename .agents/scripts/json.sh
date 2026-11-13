#!/usr/bin/env bash
# Portable JSON operations for STAR scripts. Requires Bash 3.2 and POSIX awk.
STAR_JSON_LIB="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/json.awk"
star_json_awk() {
    local program=$1 index=0 value
    shift
    for value in "$@"; do
        index=$((index + 1))
        export "STAR_JSON_ARG_$index=$value"
    done
    LC_ALL=C STAR_JSON_ARG_COUNT=$index awk -f "$STAR_JSON_LIB" -f <(printf '%s\n' "$program")
}
star_json_eval() { local program=$1; shift; star_json_awk "END { r = document(); $program }" "$@"; }
star_json_new() { local program=$1; shift; star_json_awk "END { $program }" "$@" </dev/null; }
star_json_get() { star_json_eval 'raw(at(r,a(1)))' "$1"; }
star_json_object() {
    star_json_new 'r=object(); for(i=1;i<=ENVIRON["STAR_JSON_ARG_COUNT"];i+=2) put(r,a(i),string(a(i+1))); print json(r)' "$@"
}
star_json_field() { star_json_eval 'x=at(r,a(1)); if(type(x)=="string") raw(x)' "$1"; }
star_json_context() {
    star_json_new 'r=object(); if(a(1)=="cursor") put(r,"additional_context",string(a(3))); else { x=object(); put(x,"hookEventName",string(a(2))); put(x,"additionalContext",string(a(3))); put(r,"hookSpecificOutput",x) }; print json(r)' "$@"
}
star_json_models() {
    star_json_awk '
    BEGIN { streaming=1 }
    { reset_json(); r=tryparse($0); if(!r) next; x=0
      if(a(1)=="claude" && field(r,"type")=="assistant" && (a(2)=="true" || field(r,"isSidechain")!="true")) x=at(r,"message.model")
      if(a(1)=="codex" && field(r,"type")=="turn_context") x=at(r,"payload.model")
      if(a(1)=="qwen" && field(r,"type")=="assistant") x=get(r,"model")
      if(a(1)=="dsh") {
          d=0; if(field(r,"type")=="request/context") d=get(r,"data")
          else if(field(r,"type")=="request/header") d=at(r,"data.header.config")
          x=get(d,"model"); if(type(x)=="string") { p=field(d,"provider"); if(p!="") x=string(p "/" val(x)) }
      }
      if(type(x)=="string" && val(x)!="<synthetic>") last=val(x)
    }
    END { if(last!="") print last }' "$@"
}
star_json_invocations() {
    star_json_awk '
    BEGIN { streaming=1 }
    { reset_json(); r=tryparse($0); if(!r || field(r,"isSidechain")=="true") next
      c=at(r,"message.content")
      if(field(r,"type")=="user") {
          text=""; if(type(c)=="string") text=val(c)
          else for(i=0;i<size(c);i++) { x=get(c,i); if(field(x,"type")=="text") text=text (text!="" ? " " : "") field(x,"text") }
          if(text ~ /<command-name>[[:space:]]*\/?star/ && match(text,/<command-args>/)) {
              args=substr(text,RSTART+RLENGTH); end=index(args,"</command-args>"); if(end) {last=substr(args,1,end-1); found=1}
          }
      } else if(field(r,"type")=="assistant") for(i=0;i<size(c);i++) {
          x=get(c,i); args=val(at(x,"input.args"))
          if(field(x,"type")=="tool_use" && field(x,"name")=="Skill" && val(at(x,"input.skill")) ~ /^star/ && args ~ /involve=(low|medium|high)/) {last=args; found=1}
      }
    }
    END { if(found) print last }'
}
