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
writing. Requires the project Python configured in .env with tomllib
(Python 3.11+); unsupported layouts leave the config unchanged.

Harness details: docs/mds/star-workflow/harness-adapters.md.
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

env_value() { # $1 = key; its last assignment in the target .env, empty when it has none
    [[ -f "${ENV_DIR}/.env" ]] || return 0
    sed -n "s/^$1=//p" "${ENV_DIR}/.env" | tail -1
}

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
    awk -v want="$1" -v known="${ALL_HARNESSES[*]}" -v raw="$2" '
        BEGIN {
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
    ".claude/skills/star-flow-status/SKILL_zh.md"
    ".claude/skills/star-expt-digest/SKILL.md"
    ".claude/skills/star-expt-digest/SKILL_zh.md"
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

    local tier depth skill name
    for tier in plan exec read; do
        depth="$(tier_depth_for claude "$(env_value "$(tier_model_key "${tier}")")")"
        [[ -n "${depth}" ]] || continue
        while IFS= read -r skill; do
            for name in SKILL.md SKILL_zh.md; do
                stamp_frontmatter_field ".claude/skills/${skill}/${name}" effort "${depth}"
            done
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
write_kimi_pool() {
    local config="${KIMI_CODE_HOME:-${HOME}/.kimi-code}/config.toml"
    [[ -f "${config}" ]] || fail "--kimi-pool: ${config} does not exist. Run kimi once, then re-run."
    local tier key model depth python_home conda_home env_name
    local -a entries=()
    for tier in plan exec read; do
        key="$(tier_model_key "${tier}")"
        model="$(tier_model_for kimi "$(env_value "${key}")")"
        [[ -n "${model}" ]] || continue
        depth="$(tier_depth_for kimi "$(env_value "${key}")")"
        entries+=("${tier}" "${model}" "${depth}")
    done
    (( ${#entries[@]} > 0 )) || { log "--kimi-pool: no kimi tier entry in .env; nothing to register."; return 0; }
    python_home="$(env_value PYTHON_HOME)"
    if [[ -z "${python_home}" ]]; then
        conda_home="$(env_value CONDA_HOME)"; env_name="$(env_value ENV_NAME)"
        [[ -n "${conda_home}" && -n "${env_name}" ]] || fail "--kimi-pool: set PYTHON_HOME or CONDA_HOME and ENV_NAME in .env."
        python_home="${conda_home}/envs/${env_name}"
    fi
    "${python_home}/bin/python" - "${config}" "${entries[@]}" <<'PY'
import copy
import datetime
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

try:
    import tomllib
except ImportError:
    sys.exit('--kimi-pool: the project Python needs tomllib (Python 3.11+); config unchanged.')


def value_text(value):
    """Serialize new TOML values without reformatting the original document."""
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, dict):
        return '{ ' + ', '.join(f'{value_text(k)} = {value_text(v)}' for k, v in value.items()) + ' }'
    if isinstance(value, list):
        return '[ ' + ', '.join(map(value_text, value)) + ' ]'
    if isinstance(value, (datetime.date, datetime.time)):
        return value.isoformat()
    return str(value).lower()


config = Path(sys.argv[1])
original = config.read_bytes().decode('utf-8')
try:
    parsed = tomllib.loads(original)
    expected = copy.deepcopy(parsed)
    models = expected.setdefault('models', {})
    secondary = expected.setdefault('secondary_model', {})
    pool = secondary.setdefault('models', {})
    lines = original.splitlines(keepends=True)
    sections = {}
    for i, line in enumerate(lines):
        if not line.lstrip().startswith('['):
            continue
        try:
            table = tomllib.loads(line)
        except tomllib.TOMLDecodeError:
            continue
        path = []
        while isinstance(table, dict) and len(table) == 1:
            key, table = next(iter(table.items()))
            path.append(key)
        if table == {}:
            sections[tuple(path)] = i
    if pool and ('secondary_model', 'models') not in sections:
        raise ValueError('pool must use a [secondary_model.models] table; config unchanged')
    for setting in ('force', 'default_effort'):
        if secondary.get(setting):
            print(f'--kimi-pool: warning: secondary_model.{setting} overrides per-alias routing.')

    inserts = {}
    additions = []

    def add_keys(path, values):
        """Insert new keys into an existing table, or append a new table."""
        block = ''.join(f'{value_text(k)} = {value_text(v)}\n' for k, v in values.items())
        if path in sections:
            inserts[sections[path]] = block
        else:
            header = '.'.join(value_text(part) for part in path)
            additions.append(f'\n[{header}]\n{block}')

    aliases = {}
    default_alias = None
    args = sys.argv[2:]
    for tier, model, depth in zip(args[::3], args[1::3], args[2::3]):
        alias = f'{model}-{depth}' if depth else model
        if alias not in models:
            base = models.get(model)
            if not depth or not base or depth not in base.get('support_efforts', []):
                print(f'--kimi-pool: skipping unavailable model/depth {alias}.')
                continue
            variant = copy.deepcopy(base)
            variant.pop('default_effort', None)
            overrides = variant.setdefault('overrides', {})
            overrides['default_effort'] = depth
            models[alias] = variant
            add_keys(('models', alias), {k: v for k, v in variant.items() if k != 'overrides'})
            add_keys(('models', alias, 'overrides'), overrides)
        aliases.setdefault(alias, f'STAR {tier} tier: {model}' + (f' at {depth} effort.' if depth else '.'))
        if tier == 'exec':
            default_alias = alias
    if not aliases:
        print('--kimi-pool: no registered aliases to add; config unchanged.')
        sys.exit(0)
    if 'default_model' not in secondary:
        secondary['default_model'] = default_alias or next(iter(aliases))
        add_keys(('secondary_model',), {'default_model': secondary['default_model']})
    missing = {alias: hint for alias, hint in aliases.items() if alias not in pool}
    if missing:
        pool.update(missing)
        add_keys(('secondary_model', 'models'), missing)
    if not inserts and not additions:
        print('--kimi-pool: everything already registered; config unchanged.')
        sys.exit(0)
    updated = ''.join(line + ('\n' if not line.endswith('\n') else '') + inserts[i]
                      if i in inserts else line for i, line in enumerate(lines))
    updated += ('\n' if not updated.endswith('\n') else '') + ''.join(additions)
    if tomllib.loads(updated) != expected:
        raise ValueError('unsupported table layout; config unchanged')
except (ValueError, TypeError, AttributeError) as error:
    sys.exit(f'--kimi-pool: {error}')

backup = str(config) + '.star-bak-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
shutil.copy2(config, backup)
with tempfile.NamedTemporaryFile(dir=config.parent, prefix='config.toml.star-tmp-', delete=False) as tmp:
    temporary = Path(tmp.name)
    tmp.write(updated.encode('utf-8'))
try:
    shutil.copymode(config, temporary)
    os.replace(temporary, config)
finally:
    temporary.unlink(missing_ok=True)
print(f'--kimi-pool: updated {config}; backup at {backup}. Start a new Kimi session.')
PY
}

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
