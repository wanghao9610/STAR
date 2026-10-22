#!/usr/bin/env bash
# Apply the project's tier models and depths without fetching upstream files.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
ENV_DIR="${ROOT_DIR}"
ALL_HARNESSES=(claude codex cursor dsh kimi pi qwen)
KIMI_POOL=false
HARNESSES_ARG=""

log() { printf '[STAR configure] %s\n' "$*"; }
fail() { printf '[STAR configure] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Usage: bash execs/configure.sh [--harnesses LIST]
       bash execs/configure.sh --kimi-pool

Read STAR_PLAN_MODEL, STAR_EXEC_MODEL and STAR_READ_MODEL from .env and
synchronize the model and depth fields supported by each selected harness.
Empty entries leave existing fields unchanged. Reload sessions whose static
agent definitions changed. No upstream files are fetched.

--harnesses selects comma-separated harness tags, all or none. Without it,
use STAR_HARNESSES (environment, then .env), defaulting to all.

--kimi-pool registers the configured Kimi aliases in its user config instead
of stamping project files. It preserves existing entries and backs up before
writing. Supports canonical TOML tables with single-line fields;
unsupported layouts leave the config unchanged.

Harness details: docs/mds/star-workflow/research-workflow-conventions.md §13.
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --kimi-pool) KIMI_POOL=true ;;
        --harnesses)
            shift
            (( $# > 0 )) || fail "--harnesses requires a list."
            [[ -z "${HARNESSES_ARG}" ]] || fail "--harnesses may only be specified once."
            HARNESSES_ARG="$1"
            [[ -n "${HARNESSES_ARG}" ]] || fail "--harnesses requires a list." ;;
        --harnesses=*)
            [[ -z "${HARNESSES_ARG}" ]] || fail "--harnesses may only be specified once."
            HARNESSES_ARG="${1#*=}"
            [[ -n "${HARNESSES_ARG}" ]] || fail "--harnesses requires a list." ;;
        -h|--help) usage; exit 0 ;;
        *) fail "Unknown option: $1" ;;
    esac
    shift
done

parse_env_literal() { # $1 = key, $2 = raw value; print a literal without evaluating shell code
    local key="$1" raw="$2" value="" state=unquoted char next i
    if [[ "${raw}" == "'"* ]]; then
        state=single
        raw="${raw:1}"
    elif [[ "${raw}" == '"'* ]]; then
        state=double
        raw="${raw:1}"
    fi

    for (( i = 0; i < ${#raw}; i++ )); do
        char="${raw:i:1}"
        case "${state}" in
            single)
                if [[ "${char}" == "'" ]]; then state=closed; else value+="${char}"; fi ;;
            double)
                case "${char}" in
                    '"') state=closed ;;
                    '$'|'`')
                        fail "Invalid ${key} in ${ENV_DIR}/.env: shell expansion is unsupported; use single quotes for a literal value." ;;
                    $'\\')
                        (( ++i < ${#raw} )) || fail "Invalid ${key} in ${ENV_DIR}/.env: trailing backslash in a double-quoted value."
                        next="${raw:i:1}"
                        case "${next}" in
                            '$'|'`'|'"'|$'\\') value+="${next}" ;;
                            *) value+="\\${next}" ;;
                        esac ;;
                    $'\r'|$'\n')
                        fail "Invalid ${key} in ${ENV_DIR}/.env: values must stay on one line." ;;
                    *) value+="${char}" ;;
                esac ;;
            unquoted)
                case "${char}" in
                    '$'|'`')
                        fail "Invalid ${key} in ${ENV_DIR}/.env: shell expansion is unsupported; use single quotes for a literal value." ;;
                    '~')
                        if [[ -z "${value}" || "${value}" == *: ]]; then
                            fail "Invalid ${key} in ${ENV_DIR}/.env: unquoted tilde expansion is unsupported; quote or escape the literal value."
                        fi
                        value+="${char}" ;;
                    ';'|'&'|'|'|'<'|'>'|'('|')')
                        fail "Invalid ${key} in ${ENV_DIR}/.env: unquoted shell syntax is unsupported; quote or escape the literal value." ;;
                    "'"|'"')
                        fail "Invalid ${key} in ${ENV_DIR}/.env: quotes must enclose the whole value." ;;
                    $'\\')
                        (( ++i < ${#raw} )) || fail "Invalid ${key} in ${ENV_DIR}/.env: trailing backslash in an unquoted value."
                        value+="${raw:i:1}" ;;
                    ' '|$'\t') state=after ;;
                    $'\r'|$'\n')
                        fail "Invalid ${key} in ${ENV_DIR}/.env: values must stay on one line." ;;
                    *) value+="${char}" ;;
                esac ;;
            closed)
                case "${char}" in
                    ' '|$'\t') state=after ;;
                    *) fail "Invalid ${key} in ${ENV_DIR}/.env: unexpected text after the quoted value." ;;
                esac ;;
            after)
                case "${char}" in
                    ' '|$'\t') ;;
                    '#') break ;;
                    *) fail "Invalid ${key} in ${ENV_DIR}/.env: unexpected text after the literal value." ;;
                esac ;;
        esac
    done
    case "${state}" in
        single|double)
            fail "Invalid ${key} in ${ENV_DIR}/.env: unterminated ${state}-quoted value." ;;
    esac
    printf '%s' "${value}"
}

env_value() { # $1 = key; its last assignment in the target .env, empty when it has none
    local key="$1" line="" current found=false
    [[ -f "${ENV_DIR}/.env" ]] || return 0
    while IFS= read -r current || [[ -n "${current}" ]]; do
        current="${current%$'\r'}"
        if [[ "${current}" == "${key}="* ]]; then
            line="${current#*=}"
            found=true
        fi
    done < "${ENV_DIR}/.env"
    [[ "${found}" == true ]] || return 0
    parse_env_literal "${key}" "${line}"
}

# Validate every effective file value before any manifest is changed. A flag or
# environment harness selection outranks .env and leaves its file value unused.
if [[ -z "${HARNESSES_ARG}" && -z "${STAR_HARNESSES:-}" ]]; then
    env_value STAR_HARNESSES >/dev/null
fi
for env_key in STAR_PLAN_MODEL STAR_EXEC_MODEL STAR_READ_MODEL; do
    env_value "${env_key}" >/dev/null
done

is_selected() { # $1 = harness name
    local name
    for name in ${SELECTED_HARNESSES[@]+"${SELECTED_HARNESSES[@]}"}; do
        [[ "${name}" == "$1" ]] && return 0
    done
    return 1
}

# A tier key holds one model name, or comma-separated <harness>:<model> entries so
# one .env serves every tree (workflow conventions §10.8). Reduce a raw value to what
# one harness gets: its own tagged entry, else an untagged one, else nothing. A tag
# no harness in ALL_HARNESSES answers to is skipped, which is what leaves an entry
# written for a harness this version does not ship unread instead of misapplied.
tier_entry_for() { # $1 = harness token, $2 = the raw key value
    RAW_VALUE="$2" awk -v want="$1" -v known="${ALL_HARNESSES[*]}" '
        BEGIN {
            raw = ENVIRON["RAW_VALUE"]
            n = split(known, k, " ")
            for (i = 1; i <= n; i++) is_tag[k[i]] = 1
            n = split(raw, entry, ",")
            for (i = 1; i <= n; i++) {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", entry[i])
                if (entry[i] == "") continue
                p = index(entry[i], ":")
                tag = (p > 1) ? substr(entry[i], 1, p - 1) : ""
                if (tag != "" && is_tag[tag]) {
                    if (tag == want) {
                        value = substr(entry[i], p + 1)
                        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                        print value
                        exit
                    }
                    continue
                }
                if (tag != "") continue          # a tag no tree answers to
                if (bare == "") bare = entry[i]
            }
            print bare
        }'
}

# An entry may end in `@<depth>`: the thinking depth a harness that can set one gives
# the runs and delegates of that tier (workflow conventions §10.8). Only a suffix
# spelling a depth in this vocabulary is read as one, so a model name carrying an '@'
# of its own reaches its harness whole.
is_tier_depth() { # $1 = the candidate suffix
    case "$1" in
        low|medium|high|xhigh|max) return 0 ;;
        ''|*[!0-9]*) return 1 ;;
        *[1-9]*) return 0 ;;
        *) return 1 ;;
    esac
}

tier_model_for() { # $1 = harness token, $2 = the raw key value; the model alone
    local entry
    entry="$(tier_entry_for "$1" "$2")"
    if [[ "${entry}" == *@* ]] && is_tier_depth "${entry##*@}"; then
        printf '%s' "${entry%@*}"
    else
        printf '%s' "${entry}"
    fi
}

tier_depth_for() { # $1 = harness token, $2 = the raw key value; the depth, or nothing
    local entry
    entry="$(tier_entry_for "$1" "$2")"
    [[ "${entry}" == *@* ]] || return 0
    is_tier_depth "${entry##*@}" || return 0
    printf '%s' "${entry##*@}"
}

# Some hosts need a static file to select a delegate's model. Claude Code reads
# its READ-tier model from these two forked-skill manifests; Cursor and Qwen read
# their plan, exec, and read models from named agents below. Cursor resolves only
# the flat ids its model catalog lists, one per depth, so a configured @depth is
# appended as -<depth> rather than written as a parameter.
# The files cannot read
# `.env` themselves, so the updater stamps them after install. An empty key writes
# nothing, leaving each shipped value in place (workflow conventions §10.8).
READ_TIER_MANIFESTS=(
    ".claude/skills/star-flow-status/SKILL.md"
    ".claude/skills/star-expt-digest/SKILL.md"
)

# A Claude Code run reads its thinking depth from the manifest it was invoked
# through, so a tier's depth is stamped into every manifest of that tier — and a
# delegate reads it from the named agent it was dispatched as, so the same depth is
# stamped into .claude/agents/star-<tier>.md. Which skill belongs to which tier is
# the roster in workflow conventions §10; keep these three lists and that table
# saying the same thing.
CLAUDE_PLAN_SKILLS=(
    "star-idea-storm"
    "star-plan-coach"
    "star-code-architect"
    "star-plan-decomposer"
    "star-plan-executor"
    "star-expt-analyst"
    "star-plan-reviser"
    "star-metd-summarize"
)
CLAUDE_EXEC_SKILLS=(
    "star-proj-adopt"
    "star-refs-reviewer"
    "star-env-builder"
    "star-code-reviewer"
    "star-code-release"
)
CLAUDE_READ_SKILLS=(
    "star-expt-digest"
    "star-flow-status"
)

yaml_field_line() { # $1 = field name, $2 = its value; a YAML double-quoted line
    local value="$2"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s: "%s"' "$1" "${value}"
}

yaml_plain_field_line() { # $1 = field name, $2 = its value; unquoted (Cursor model:)
    local value="$2"
    case "${value}" in
        *$'\n'*|*$'\r'*) fail "Refusing to stamp a multiline ${1} value." ;;
    esac
    printf '%s: %s' "$1" "${value}"
}

cursor_model_stamp() { # $1 = model id, $2 = depth or empty; Cursor's model: encoding
    local model="$1" depth="$2"
    if [[ -n "${depth}" && "${model}" != *"-${depth}" ]]; then
        printf '%s-%s' "${model}" "${depth}"
    else
        printf '%s' "${model}"
    fi
}

stamp_frontmatter_field() { # $1 = path, $2 = field, $3 = value, $4 = quoted|plain
    local path="$1" field="$2" value="$3" style="${4:-quoted}" tmp line
    [[ -f "${ROOT_DIR}/${path}" ]] || return 0
    tmp="${ROOT_DIR}/${path}.star-stamp"
    # Only the first frontmatter block is changed. The new line is supplied
    # through the environment so an id containing backslashes is not re-parsed
    # as an awk -v escape sequence. Cursor's agent loader treats quote characters
    # as part of the model name, so its model: line is stamped unquoted.
    if [[ "${style}" == plain ]]; then
        line="$(yaml_plain_field_line "${field}" "${value}")"
    else
        line="$(yaml_field_line "${field}" "${value}")"
    fi
    FIELD_LINE="${line}" awk -v key="${field}" '
        NR == 1 { print; stage = ($0 == "---") ? 1 : 3; next }
        stage == 1 && $0 == "---" {
            for (i = 1; i <= n; i++) {
                print buf[i]
                if (!stamped && !placed && buf[i] ~ /^name:[[:space:]]/) {
                    print ENVIRON["FIELD_LINE"]
                    placed = 1
                }
            }
            if (!stamped && !placed) print ENVIRON["FIELD_LINE"]
            stage = 3
            print
            next
        }
        stage == 1 && $0 ~ "^" key ":[[:space:]]" { buf[++n] = ENVIRON["FIELD_LINE"]; stamped = 1; next }
        stage == 1 { buf[++n] = $0; next }
        { print }
    ' "${ROOT_DIR}/${path}" > "${tmp}" || {
        rm -f -- "${tmp}"
        fail "Could not stamp the tier ${field} into ${path}."
    }
    if cmp -s "${tmp}" "${ROOT_DIR}/${path}"; then
        rm -f -- "${tmp}"
    else
        mv -f -- "${tmp}" "${ROOT_DIR}/${path}"
        log "Stamped ${field}: ${value} into ${path}"
    fi
}

stamp_read_model() {
    # A tree this run does not cover is left alone here too, so a project that
    # excluded Claude keeps whatever its .claude holds, stamp included.
    is_selected claude || return 0

    local value path
    value="$(tier_model_for claude "$(env_value STAR_READ_MODEL)")"
    [[ -n "${value}" ]] || return 0

    for path in "${READ_TIER_MANIFESTS[@]}"; do
        stamp_frontmatter_field "${path}" model "${value}"
    done
}

claude_tier_skills() { # $1 = plan, exec, or read
    case "$1" in
        plan) printf '%s\n' "${CLAUDE_PLAN_SKILLS[@]}" ;;
        exec) printf '%s\n' "${CLAUDE_EXEC_SKILLS[@]}" ;;
        read) printf '%s\n' "${CLAUDE_READ_SKILLS[@]}" ;;
        *) fail "Unknown model tier '$1'." ;;
    esac
}

stamp_claude_depths() {
    is_selected claude || return 0

    local tier depth skill
    for tier in plan exec read; do
        depth="$(tier_depth_for claude "$(env_value "$(tier_model_key "${tier}")")")"
        [[ -n "${depth}" ]] || continue
        while IFS= read -r skill; do
            stamp_frontmatter_field ".claude/skills/${skill}/SKILL.md" effort "${depth}"
        done < <(claude_tier_skills "${tier}")
        stamp_frontmatter_field ".claude/agents/star-${tier}.md" effort "${depth}"
    done
}

tier_model_key() { # $1 = plan, exec, or read
    case "$1" in
        plan) printf 'STAR_PLAN_MODEL' ;;
        exec) printf 'STAR_EXEC_MODEL' ;;
        read) printf 'STAR_READ_MODEL' ;;
        *) fail "Unknown model tier '$1'." ;;
    esac
}

stamp_named_models() { # $1 = cursor or qwen
    local harness="$1" tier key raw value path style
    is_selected "${harness}" || return 0

    for tier in plan exec read; do
        key="$(tier_model_key "${tier}")"
        raw="$(env_value "${key}")"
        value="$(tier_model_for "${harness}" "${raw}")"
        [[ -n "${value}" ]] || continue
        style=quoted
        if [[ "${harness}" == cursor ]]; then
            value="$(cursor_model_stamp "${value}" "$(tier_depth_for cursor "${raw}")")"
            style=plain
        fi
        path=".${harness}/agents/star-${tier}.md"
        stamp_frontmatter_field "${path}" model "${value}" "${style}"
    done
}

stamp_models() {
    stamp_read_model
    stamp_claude_depths
    stamp_named_models cursor
    stamp_named_models qwen
}

model_stamp_summary() {
    local harness tier key value depth any=false
    for harness in claude codex cursor qwen kimi; do
        is_selected "${harness}" || continue
        if [[ "${harness}" == claude ]]; then
            value="$(tier_model_for claude "$(env_value STAR_READ_MODEL)")"
            if [[ -n "${value}" ]]; then
                log "STAR_READ_MODEL in .env gives Claude Code: ${value}."
                any=true
            fi
            for tier in plan exec read; do
                key="$(tier_model_key "${tier}")"
                depth="$(tier_depth_for claude "$(env_value "${key}")")"
                if [[ -n "${depth}" ]]; then
                    log "${key} in .env gives Claude Code's ${tier}-tier manifests and its star-${tier} agent the depth: ${depth}."
                    any=true
                fi
            done
            continue
        fi
        if [[ "${harness}" == codex ]]; then
            for tier in plan exec read; do
                key="$(tier_model_key "${tier}")"
                value="$(tier_model_for codex "$(env_value "${key}")")"
                [[ -n "${value}" ]] || continue
                depth="$(tier_depth_for codex "$(env_value "${key}")")"
                log "${key} in .env gives Codex at dispatch: model ${value}, requested reasoning effort ${depth:-default}; no file stamp is required."
                any=true
            done
            continue
        fi
        if [[ "${harness}" == kimi ]]; then
            # Kimi stamps nothing: a depth reaches the dispatch as the secondary-model
            # pool alias binding it, which only the user's own config can register.
            for tier in plan exec read; do
                key="$(tier_model_key "${tier}")"
                value="$(tier_model_for kimi "$(env_value "${key}")")"
                [[ -n "${value}" ]] || continue
                depth="$(tier_depth_for kimi "$(env_value "${key}")")"
                if [[ -n "${depth}" ]]; then
                    log "${key} in .env gives Kimi Code at dispatch: model alias ${value}-${depth} — a [models] variant binding ${value} at depth ${depth} that your ~/.kimi-code/config.toml registers and [secondary_model.models] lists; no file stamp is required. Register it with: bash execs/configure.sh --kimi-pool."
                else
                    log "${key} in .env gives Kimi Code at dispatch: model alias ${value}; no file stamp is required."
                fi
                any=true
            done
            continue
        fi
        for tier in plan exec read; do
            key="$(tier_model_key "${tier}")"
            value="$(tier_model_for "${harness}" "$(env_value "${key}")")"
            if [[ -n "${value}" ]]; then
                if [[ "${harness}" == cursor ]]; then
                    value="$(cursor_model_stamp "${value}" "$(tier_depth_for cursor "$(env_value "${key}")")")"
                fi
                log "${key} in .env gives ${harness}: ${value}."
                any=true
            fi
        done
    done
    [[ "${any}" == true ]] || log "No selected Claude Code, Codex, Cursor, Qwen, or Kimi tier key names a model or a depth in .env; nothing was stamped."
}

# Kimi Code keeps its subagent model pool in the user's own config, which no skill
# run may write. This is the explicit, user-invoked exception: register the
# [models] variants and pool keys the configured kimi tier entries need (workflow
# conventions §10.8). Additive and idempotent — an entry already there, whatever
# it says, is kept as the user wrote it; the file is backed up before any write.
write_kimi_pool() (
    local config="${KIMI_CODE_HOME:-${HOME}/.kimi-code}/config.toml"
    [[ -f "${config}" ]] || fail "--kimi-pool: ${config} does not exist. Run kimi once, then re-run."
    local tier key model depth entries="" temporary="" backup=""
    for tier in plan exec read; do
        key="$(tier_model_key "${tier}")"
        model="$(tier_model_for kimi "$(env_value "${key}")")"
        [[ -n "${model}" ]] || continue
        [[ "${model}" != *[$'\001'-$'\037'$'\177']* ]] || fail "--kimi-pool: control characters in model name; config unchanged."
        depth="$(tier_depth_for kimi "$(env_value "${key}")")"
        entries+="${tier}"$'\034'"${model}"$'\034'"${depth}"$'\n'
    done
    [[ -n "${entries}" ]] || { log "--kimi-pool: no kimi tier entry in .env; nothing to register."; return 0; }
    temporary="$(mktemp "${config}.star-tmp-XXXXXX")"
    trap '[[ -z "${temporary}" ]] || rm -f -- "${temporary}"' EXIT
    cp -p "${config}" "${temporary}"
    # A deliberately bounded TOML reader: canonical tables and single-line
    # scalar/array fields. Original lines are retained byte-for-byte apart from
    # a final newline. Inline tables, dotted assignments, multiline values and
    # array tables are rejected before writing, rather than interpreted loosely.
    if ! STAR_KIMI_ENTRIES="${entries}" awk '
        function trim(s) {gsub(/^[ \t]+|[ \t\r]+$/, "", s); return s}
        function die(message) {print "--kimi-pool: " message "; config unchanged." > "/dev/stderr"; bad=1; exit 2}
        function quote(s,    i,c,r) {
            r="\""
            for(i=1;i<=length(s);i++) {c=substr(s,i,1); if(c=="\\" || c=="\"") r=r "\\"; r=r c}
            return r "\""
        }
        function unquote(s,    q,i,c,r) {
            q=substr(s,1,1)
            if(q!="\"" && q!=sprintf("%c",39)) return s
            if(substr(s,length(s),1)!=q) die("unsupported quoted key")
            r=""
            for(i=2;i<length(s);i++) {
                c=substr(s,i,1)
                if(c=="\\" && q=="\"") {
                    c=substr(s,++i,1)
                    if(c!="\\" && c!="\"") die("escaped table/key names require a canonical literal spelling")
                }
                r=r c
            }
            return r
        }
        function pathparts(s, a,    n,i,start,q,c,escaped,token) {
            n=0; i=1
            while(i<=length(s)) {
                while(substr(s,i,1)~/[ \t]/) i++
                start=i; q=substr(s,i,1)
                if(q=="\"" || q==sprintf("%c",39)) {
                    i++; escaped=0
                    while(i<=length(s)) {
                        c=substr(s,i,1)
                        if(c==q && !escaped) break
                        if(c=="\\" && q=="\"" && !escaped) escaped=1; else escaped=0
                        i++
                    }
                    if(i>length(s)) die("unterminated quoted key")
                    token=substr(s,start,i-start+1); i++
                } else {
                    while(substr(s,i,1)~/[A-Za-z0-9_-]/ && i<=length(s)) i++
                    token=substr(s,start,i-start)
                    if(token=="") die("unsupported table/key syntax")
                }
                a[++n]=unquote(token)
                if(a[n] ~ /[[:cntrl:]]/) die("control characters in table/key name")
                while(substr(s,i,1)~/[ \t]/ && i<=length(s)) i++
                if(i>length(s)) return n
                if(substr(s,i,1)!=".") die("unsupported table/key syntax")
                i++; if(i>length(s)) die("trailing dot in table/key")
            }
            return n
        }
        function pathtext(path,    n,a,i,r) {
            n=split(path,a,SUBSEP); r=""
            for(i=1;i<=n;i++) r=r (i>1?".":"") quote(a[i])
            return r
        }
        function uncomment(s,    i,c,q,r,escaped) {
            q=""; r=""; escaped=0
            for(i=1;i<=length(s);i++) {
                c=substr(s,i,1)
                if(q=="") {if(c=="#") break; if(c=="\"" || c==sprintf("%c",39)) q=c}
                else if(c==q && !escaped) q=""
                r=r c
                if(c=="\\" && q=="\"" && !escaped) escaped=1; else escaped=0
            }
            if(q!="") die("multiline or unterminated string is unsupported")
            return trim(r)
        }
        function skipspace() {while(substr(value,pos,1)~/[ \t]/ && pos<=length(value)) pos++}
        function datevalid(s,    year,month,day,days) {
            if(s!~/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return 0
            year=substr(s,1,4)+0;month=substr(s,6,2)+0;day=substr(s,9,2)+0
            split("31 28 31 30 31 30 31 31 30 31 30 31",days," ")
            if(year%4==0 && (year%100!=0 || year%400==0)) days[2]=29
            return year>0 && month>=1 && month<=12 && day>=1 && day<=days[month]
        }
        function timevalid(s,zone,    suffix) {
            if(s!~/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9](\.[0-9]+)?([Zz]|[+-][0-9][0-9]:[0-9][0-9])?$/) return 0
            if(substr(s,1,2)+0>23 || substr(s,4,2)+0>59 || substr(s,7,2)+0>59) return 0
            suffix=substr(s,9);sub(/^\.[0-9]+/,"",suffix)
            if(suffix=="") return 1
            if(!zone) return 0
            return suffix~/^[Zz]$/ || (substr(suffix,2,2)+0<24 && substr(suffix,5,2)+0<60)
        }
        function atom(    start,q,c,token,digits,n,j,code) {
            skipspace(); start=pos; q=substr(value,pos,1)
            if(q=="\"" || q==sprintf("%c",39)) {
                if(substr(value,pos,3)==q q q) die("multiline strings are unsupported")
                pos++
                while(pos<=length(value)) {
                    c=substr(value,pos++,1)
                    if(c==q) return
                    if(c=="\\" && q=="\"") {
                        c=substr(value,pos++,1)
                        if(c=="u" || c=="U") {
                            n=(c=="u"?4:8); digits=substr(value,pos,n)
                            if(length(digits)!=n || digits~/[^0-9a-fA-F]/) die("invalid Unicode string escape")
                            code=0
                            for(j=1;j<=n;j++) code=code*16+index("0123456789abcdef",tolower(substr(digits,j,1)))-1
                            if(code>1114111 || (code>=55296 && code<=57343)) die("invalid Unicode scalar in string escape")
                            pos+=n
                        } else if(index("btnfr\"\\",c)==0 || c=="") die("invalid string escape")
                    } else if(c~/[[:cntrl:]]/ && c!="\t") die("control character in string")
                }
                die("unterminated string")
            }
            if(q=="[") {
                pos++; skipspace(); if(substr(value,pos,1)=="]") {pos++; return}
                while(pos<=length(value)) {
                    atom(); skipspace(); c=substr(value,pos++,1)
                    if(c=="]") return
                    if(c!=",") die("unsupported array syntax")
                    skipspace(); if(substr(value,pos,1)=="]") {pos++; return}
                }
                die("multiline arrays are unsupported")
            }
            while(pos<=length(value) && substr(value,pos,1)!~/[ \t,\]]/) pos++
            token=substr(value,start,pos-start)
            if(token=="true" || token=="false" || token~/^[+-]?(inf|nan)$/) return
            if(token~/^[+-]?(0|[1-9](_?[0-9])*)$/) return
            if(token~/^[+-]?(0|[1-9](_?[0-9])*)\.[0-9](_?[0-9])*([eE][+-]?[0-9](_?[0-9])*)?$/) return
            if(token~/^[+-]?(0|[1-9](_?[0-9])*)[eE][+-]?[0-9](_?[0-9])*$/) return
            if(token~/^0x[0-9a-fA-F](_?[0-9a-fA-F])*$/ || token~/^0o[0-7](_?[0-7])*$/ || token~/^0b[01](_?[01])*$/) return
            if(datevalid(token) || timevalid(token,0)) return
            if(length(token)>10 && substr(token,11,1)~/[Tt]/ && datevalid(substr(token,1,10)) && timevalid(substr(token,12),1)) return
            die("unsupported value (use canonical single-line scalar/array fields, not inline tables)")
        }
        function validvalue(s) {value=s;pos=1;atom();skipspace();if(pos<=length(value)) die("unsupported value suffix")}
        function supports(raw,depth,    n,a,i,item) {
            if(substr(raw,1,1)!="[" || substr(raw,length(raw),1)!="]") return 0
            raw=substr(raw,2,length(raw)-2); n=split(raw,a,",")
            for(i=1;i<=n;i++) {
                item=trim(a[i])
                if((substr(item,1,1)=="\"" || substr(item,1,1)==sprintf("%c",39)) && unquote(item)==depth) return 1
            }
            return 0
        }
        function insert(path,key,raw,    line) {
            changed=1
            line=quote(key) " = " raw "\n"
            if(path in sections) inserts[sections[path]]=inserts[sections[path]] line
            else additions=additions "\n[" pathtext(path) "]\n" line
        }
        function clone(base,alias,depth,    bp,ap,i,path,override,found) {
            bp="models" SUBSEP base; ap="models" SUBSEP alias; override=bp SUBSEP "overrides"
            if(kind[override]=="value" || kind[override SUBSEP "default_effort"]=="table" || kind[bp SUBSEP "default_effort"]=="table") die("variant overrides must use canonical scalar fields and tables")
            changed=1
            additions=additions "\n"
            for(i=1;i<=NR;i++) {
                path=sectionpath[i]
                if(path!=bp && index(path,bp SUBSEP)!=1) continue
                if(header[i]) {
                    additions=additions "[" pathtext(ap substr(path,length(bp)+1)) "]\n"
                    if(path==override) {additions=additions "default_effort = " quote(depth) "\n"; found=1}
                } else if(!((path==bp || path==override) && field[i]=="default_effort")) additions=additions lines[i] "\n"
            }
            if(!found) additions=additions "\n[" pathtext(ap SUBSEP "overrides") "]\ndefault_effort = " quote(depth) "\n"
        }
        {
            lines[NR]=$0; text=uncomment($0)
            if(substr(text,1,1)=="[") {
                if(substr(text,1,2)=="[[" || substr(text,length(text),1)!="]") die("array tables or malformed headers are unsupported")
                n=pathparts(substr(text,2,length(text)-2),parts)
                if(!n) die("empty table path")
                current=""
                for(i=1;i<=n;i++) {
                    current=current (i>1?SUBSEP:"") parts[i]
                    if(kind[current]=="value") die("table conflicts with an existing value")
                    kind[current]="table"
                }
                if(current in sections) die("duplicate table")
                sections[current]=NR; header[NR]=1
                if(n>=2 && parts[1]=="models") models[parts[2]]=1
            } else if(text!="") {
                # Find the assignment after a possibly quoted key.
                q=""; escaped=0; equals=0
                for(i=1;i<=length(text);i++) {
                    c=substr(text,i,1)
                    if(q=="") {if(c=="=") {equals=i;break}; if(c=="\"" || c==sprintf("%c",39)) q=c}
                    else if(c==q && !escaped) q=""
                    if(c=="\\" && q=="\"" && !escaped) escaped=1; else escaped=0
                }
                if(!equals) die("unsupported assignment")
                n=pathparts(trim(substr(text,1,equals-1)),parts)
                if(n!=1) die("dotted assignments are unsupported; use explicit tables")
                key=parts[1]; field[NR]=key; raw=trim(substr(text,equals+1)); validvalue(raw)
                path=(current==""?key:current SUBSEP key)
                if(path in kind) die("duplicate or conflicting key")
                kind[path]="value"; values[path]=raw
                if(current=="" && (key=="models" || key=="secondary_model")) die("models and secondary_model must use explicit tables")
            }
            sectionpath[NR]=current
        }
        END {
            if(bad) exit 2
            secondary="secondary_model"; pool=secondary SUBSEP "models"
            if(kind[secondary]=="value" || kind[pool]=="value") die("secondary model pool must use an explicit table")
            for(setting_index=1;setting_index<=2;setting_index++) {
                setting=(setting_index==1?"force":"default_effort"); raw=values[secondary SUBSEP setting]
                if(raw!="" && raw!="false" && raw!="0" && raw!="\"\"" && raw!=sprintf("%c%c",39,39))
                    print "--kimi-pool: warning: secondary_model." setting " overrides per-alias routing." > "/dev/stderr"
            }
            nentries=split(ENVIRON["STAR_KIMI_ENTRIES"],entry,"\n")
            for(e=1;e<=nentries;e++) {
                if(entry[e]=="") continue
                split(entry[e],item,sprintf("%c",28)); tier=item[1]; model=item[2]; depth=item[3]; alias=model (depth!=""?"-" depth:"")
                if(!(alias in models)) {
                    if(depth=="" || !(model in models) || !("models" SUBSEP model in sections) || !supports(values["models" SUBSEP model SUBSEP "support_efforts"],depth)) {
                        print "--kimi-pool: skipping unavailable model/depth " alias "." > "/dev/stderr"; continue
                    }
                    clone(model,alias,depth); models[alias]=1
                }
                if(!(alias in aliases)) {
                    aliases[alias]="STAR " tier " tier: " model (depth!=""?" at " depth " effort.":".")
                    ordered[++alias_count]=alias
                }
                if(tier=="exec") default_alias=alias
            }
            if(!alias_count) exit
            if(!(secondary SUBSEP "default_model" in kind)) insert(secondary,"default_model",quote(default_alias!=""?default_alias:ordered[1]))
            pool_block=""
            for(i=1;i<=alias_count;i++) {
                alias=ordered[i]
                if(!(pool SUBSEP alias in kind)) pool_block=pool_block quote(alias) " = " quote(aliases[alias]) "\n"
            }
            if(pool_block!="") {
                changed=1
                if(pool in sections) inserts[sections[pool]]=inserts[sections[pool]] pool_block
                else additions=additions "\n[" pathtext(pool) "]\n" pool_block
            }
            if(!changed) exit
            for(i=1;i<=NR;i++) {print lines[i]; if(i in inserts) printf "%s",inserts[i]}
            printf "%s",additions
        }
    ' "${config}" > "${temporary}"; then
        fail "--kimi-pool: unsupported TOML layout; original config was preserved."
    fi
    if [[ ! -s "${temporary}" ]] || cmp -s "${config}" "${temporary}"; then
        log "--kimi-pool: everything already registered or unavailable; config unchanged."
        return 0
    fi
    backup="$(mktemp "${config}.star-bak-$(date '+%Y%m%d-%H%M%S')-XXXXXX")"
    cp -p "${config}" "${backup}"
    mv -f "${temporary}" "${config}"
    temporary=""
    log "--kimi-pool: updated ${config}; backup at ${backup}. Start a new Kimi session."
)
HARNESSES_SPEC="${HARNESSES_ARG:-${STAR_HARNESSES:-$(env_value STAR_HARNESSES)}}"
HARNESSES_SPEC="${HARNESSES_SPEC:-all}"
SELECTED_HARNESSES=()
case "${HARNESSES_SPEC}" in
    all) SELECTED_HARNESSES=("${ALL_HARNESSES[@]}") ;;
    none) ;;
    *)
        while IFS= read -r name; do
            name="${name//[[:space:]]/}"
            [[ -n "${name}" ]] || continue
            case " ${ALL_HARNESSES[*]} " in
                *" ${name} "*) is_selected "${name}" || SELECTED_HARNESSES+=("${name}") ;;
                *) fail "Unknown harness '${name}'. Valid: ${ALL_HARNESSES[*]}, all, none." ;;
            esac
        done < <(tr ',' '\n' <<<"${HARNESSES_SPEC}")
        (( ${#SELECTED_HARNESSES[@]} > 0 )) || fail "No harness selected; use 'none' explicitly." ;;
esac

if [[ "${KIMI_POOL}" == true ]]; then
    write_kimi_pool
else
    stamp_models
fi
model_stamp_summary
