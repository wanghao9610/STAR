#!/usr/bin/env bash
source "$(dirname -- "${BASH_SOURCE[0]}")/../../.agents/scripts/json.sh" || { echo "${0##*/}: cannot load .agents/scripts/json.sh; run execs/update.sh" >&2; exit 1; }
# STAR SessionStart hook (Codex CLI) — inject the runtime-reported model id into
# session context so skills record a real model_id instead of "unrecorded".
#
# Codex puts a `model` field (active model slug) on the SessionStart payload and
# accepts the same output shape as Claude Code: hookSpecificOutput.additionalContext.
# That field describes the moment the session opened; /model changes the model
# afterwards with no hook firing, so a session can write with one model while
# still holding the name of another.
#
# Codex also keeps a rollout file per session and stamps a `turn_context` record
# with the model of each turn. The injected context always states SessionStart's
# exact id directly, including when that rollout exists, and also hands the skill
# commands that resolve the live value before a write and verify the artifact
# afterwards. When `model` is absent, the honest SessionStart fallback per
# research-workflow-conventions §8 is "unrecorded". Registered under
# [hooks.SessionStart] in .codex/hooks.json.

# --resolve <transcript_path> [session_model]: print the model of the last turn
# recorded in a rollout, or nothing at all. Run on demand by skills, per the line
# injected below. Prints nothing rather than failing, so "unrecorded" stays the
# fallback.
#
# session_model is what SessionStart reported. It stands in when the rollout
# names nothing yet, and is preferred over an identical id so that a suffix the
# rollout drops survives. It never wins over a different id — that difference is
# a mid-session switch, and the rollout is the one that saw it.
if [ "${1:-}" = "--resolve" ]; then
  transcript="${2:-}"
  session_model="${3:-}"
  resolved=""
  if [ -n "${transcript}" ] && [ -r "${transcript}" ]; then
    resolved=$(star_json_models codex < "$transcript" 2>/dev/null)
  fi

  if [ -z "${resolved}" ]; then
    [ -n "${session_model}" ] && printf '%s\n' "${session_model}"
    exit 0
  fi
  case "${session_model}" in
    "${resolved}"|"${resolved}["*) printf '%s\n' "${session_model}" ;;
    *) printf '%s\n' "${resolved}" ;;
  esac
  exit 0
fi

# --check <artifact> <transcript_path> <session_model>: verify that the
# artifact's model_id matches the rollout's last recorded model, falling back to
# SessionStart's exact id and finally to "unrecorded". A mismatch is a hard
# failure: producer skills must not report completion or commit the artifact.
if [ "${1:-}" = "--check" ]; then
  if [ "$#" -ne 4 ]; then
    printf '%s\n' \
      "usage: $0 --check <artifact> <transcript_path> <session_model>" >&2
    exit 2
  fi

  artifact="${2}"
  transcript="${3}"
  session_model="${4}"
  if [ ! -r "${artifact}" ]; then
    printf '%s\n' "star_model_id.sh: cannot read artifact: ${artifact}" >&2
    exit 1
  fi

  # Machine-generated receipts inherit provenance from their bound report.
  # Verify the binding before reading model metadata; this is independent of
  # review_state.sh's source/plan freshness and launch-gate checks.
  if [ "${artifact##*/}" = REVIEW_STATE.md ]; then
    receipt_error() {
      printf '%s\n' "star_model_id.sh: invalid review receipt ${artifact}: $1" >&2
      exit 1
    }
    run_dir=$(cd -- "$(dirname -- "${artifact}")" && pwd -P) || receipt_error 'cannot resolve directory'
    root=$(cd -- "${run_dir}/../.." && pwd -P) || receipt_error 'cannot resolve root'
    run=${run_dir##*/}
    [ "${run_dir}" = "${root}/wkdrs/${run}" ] || receipt_error 'expected wkdrs/<run>/REVIEW_STATE.md'
    version='' report='' report_hash='' gate=''
    while IFS=$'\t' read -r key value digest extra || [ -n "${key}" ]; do
      [ -z "${extra}" ] || receipt_error 'invalid metadata'
      case "${key}" in
        version|report|report_hash|gate)
          [ -n "${value}" ] && [ -z "${digest}" ] || receipt_error 'invalid metadata'
          case "${key}" in
            version) [ -z "${version}" ] || receipt_error 'duplicate version'; version=$value ;;
            report) [ -z "${report}" ] || receipt_error 'duplicate report'; report=$value ;;
            report_hash) [ -z "${report_hash}" ] || receipt_error 'duplicate report_hash'; report_hash=$value ;;
            gate) [ -z "${gate}" ] || receipt_error 'duplicate gate'; gate=$value ;;
          esac ;;
        path|plan) [ -n "${value}" ] && [ -n "${digest}" ] || receipt_error 'invalid scope metadata' ;;
        *) receipt_error 'unknown metadata' ;;
      esac
    done < "${artifact}"
    [ "${version}" = 1 ] || receipt_error 'unsupported version'
    case "${gate}" in passed|blocked) ;; *) receipt_error 'invalid gate' ;; esac
    case "${report}" in
      "wkdrs/${run}/CODE_REVIEW_"*.md) ;;
      *) receipt_error 'invalid report path' ;;
    esac
    report_name=${report#"wkdrs/${run}/"}
    case "${report_name}" in */*) receipt_error 'invalid report path' ;; esac
    [ -f "${root}/${report}" ] && [ -r "${root}/${report}" ] || receipt_error 'missing report'
    bound_hash=$(git -C "${root}" hash-object --no-filters -- "${root}/${report}" 2>/dev/null) || receipt_error 'cannot hash report'
    [ -n "${report_hash}" ] && [ "${bound_hash}" = "${report_hash}" ] || receipt_error 'report content changed'
    artifact="${root}/${report}"
  fi

  expected=$(bash "$0" --resolve "${transcript}")
  [ -n "${expected}" ] || expected="${session_model}"
  [ -n "${expected}" ] || expected="unrecorded"

  # Artifacts use one of three registered shapes: a YAML frontmatter key, an
  # HTML provenance marker on line 1, or UPSTREAM.md's Markdown key. Read only
  # the header area so prose mentioning model_id cannot masquerade as metadata.
  actual=$(awk '
function first_token(value, fields) {
  sub(/^[[:space:]]+/, "", value)
  split(value, fields, /[[:space:]]+/)
  value = fields[1]
  gsub(/^[<"\047`]+/, "", value)
  gsub(/[>"\047`),.;]+$/, "", value)
  return value
}
NR > 40 { exit }
/^[[:space:]]*model_id[[:space:]]*:/ {
  line = $0
  sub(/^[[:space:]]*model_id[[:space:]]*:[[:space:]]*/, "", line)
  print first_token(line)
  exit
}
NR == 1 && /model_id[[:space:]]*:/ {
  line = $0
  sub(/^.*model_id[[:space:]]*:[[:space:]]*/, "", line)
  print first_token(line)
  exit
}
/^[[:space:]]*-[[:space:]]+\*\*model_id\*\*[[:space:]]*:/ {
  line = $0
  sub(/^[^:]*:[[:space:]]*/, "", line)
  print first_token(line)
  exit
}
' "${artifact}")

  if [ "${actual}" != "${expected}" ]; then
    [ -n "${actual}" ] || actual="<missing>"
    printf '%s\n' \
      "star_model_id.sh: model_id mismatch in ${artifact}: expected '${expected}', found '${actual}'" >&2
    exit 1
  fi
  exit 0
fi

input=$(cat)

# Read one top-level string field from the payload.
payload_field() { printf '%s' "$input" | star_json_field "$1" 2>/dev/null; }

model=$(payload_field model)
transcript=$(payload_field transcript_path)
# Codex offers no project-directory variable, and registers this hook by the same
# relative path, which resolves from the project root a skill also runs in.
self=".codex/hooks/star_model_id.sh"
printf -v transcript_arg '%q' "${transcript:-}"
printf -v model_arg '%q' "${model:-}"
ctx="STAR provenance: session_model_id = ${model:-unrecorded}. This is the exact id SessionStart reported, stated directly even when a rollout exists. Before a STAR skill records a model_id or model_trail entry (research-workflow-conventions section 8), run: bash ${self} --resolve ${transcript_arg} ${model_arg}. Copy its output verbatim; if it prints nothing, use session_model_id, and use 'unrecorded' only when both are absent. Never infer an id from a family description such as 'GPT-5 family'. After writing each artifact, run: bash ${self} --check <artifact> ${transcript_arg} ${model_arg}, replacing <artifact> with its path. A nonzero result blocks reporting completion or committing."

# Encode context without losing quotes, backslashes or line breaks.
star_json_context hook "${event:-SessionStart}" "$ctx"
