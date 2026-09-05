#!/usr/bin/env bash
# Offline regression checks for execs/update.sh --models and its static consumers.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/star-model-routing.XXXXXX")"
PROJECT="${TMP_DIR}/project"
trap 'rm -rf -- "${TMP_DIR}"' EXIT

fail() { printf 'FAIL  %s\n' "$*" >&2; exit 1; }
note() { printf 'ok    %s\n' "$*"; }
expect_model() { grep -Fqx "model: \"$2\"" "$1" || fail "$1 should have model $2"; }
run_models() { (cd "${PROJECT}" && bash execs/update.sh --models "$@") >/dev/null; }

mkdir -p "${PROJECT}/execs"
cp "${ROOT_DIR}/execs/update.sh" "${PROJECT}/execs/update.sh"
: > "${PROJECT}/execs/run.sh"
for harness in cursor qwen; do
	for tier in plan exec read; do
		mkdir -p "${PROJECT}/.${harness}/agents"
		cp "${ROOT_DIR}/.${harness}/agents/star-${tier}.md" "${PROJECT}/.${harness}/agents/"
	done
done
for skill in star-flow-status star-expt-digest; do
	for suffix in SKILL.md SKILL_zh.md; do
		mkdir -p "${PROJECT}/.claude/skills/${skill}"
		cp "${ROOT_DIR}/.claude/skills/${skill}/${suffix}" "${PROJECT}/.claude/skills/${skill}/"
	done
done

write_env() { printf '%s\n' "$@" > "${PROJECT}/.env"; }
snapshot() {
	(
		cd "${PROJECT}"
		find .claude .cursor .qwen -type f | LC_ALL=C sort | while IFS= read -r file; do cksum "${file}"; done
	)
}

# Tagged values beat the bare fallback; qwen's EXEC value exercises the fallback,
# while its READ value retains a provider-style colon after the qwen tag.
write_env \
	'STAR_PLAN_MODEL=bare-plan,unknown:ignored,cursor:cursor-plan,qwen:qwen-plan' \
	'STAR_EXEC_MODEL=unknown:ignored,bare-exec,cursor:cursor-exec' \
	'STAR_READ_MODEL=bare-read,claude:claude-read,cursor:cursor-read,qwen:authType:model-id'
run_models

for tier in plan exec read; do
	expect_model "${PROJECT}/.cursor/agents/star-${tier}.md" "cursor-${tier}"
done
expect_model "${PROJECT}/.qwen/agents/star-plan.md" qwen-plan
expect_model "${PROJECT}/.qwen/agents/star-exec.md" bare-exec
expect_model "${PROJECT}/.qwen/agents/star-read.md" authType:model-id
for skill in star-flow-status star-expt-digest; do
	for suffix in SKILL.md SKILL_zh.md; do
		expect_model "${PROJECT}/.claude/skills/${skill}/${suffix}" claude-read
	done
done
note "three tiers route to Cursor and Qwen; Claude stamps only READ"

before="$(snapshot)"
run_models
[[ "$(snapshot)" == "${before}" ]] || fail "a second --models run changed the fixture"
note "--models is idempotent"

write_env 'STAR_PLAN_MODEL=unknown:ignored' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
run_models --harnesses qwen
expect_model "${PROJECT}/.qwen/agents/star-plan.md" qwen-plan
expect_model "${PROJECT}/.qwen/agents/star-exec.md" bare-exec
note "unknown tags and empty values leave existing stamps alone"

write_env 'STAR_PLAN_MODEL=cursor:cursor-only,qwen:qwen-only' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
run_models --harnesses cursor
expect_model "${PROJECT}/.cursor/agents/star-plan.md" cursor-only
expect_model "${PROJECT}/.qwen/agents/star-plan.md" qwen-plan
expect_model "${PROJECT}/.claude/skills/star-flow-status/SKILL.md" claude-read
note "--harnesses changes only the selected tree"

for tree in .agents .claude .cursor .dsh .kimi-code .pi .qwen; do
	while IFS= read -r file; do
		grep -Fq 'Passing a tier model' "${file}" || fail "${file} lacks the tier-model entry"
	done < <(find -L "${ROOT_DIR}/${tree}/skills" -type f -name SKILL.md)
	while IFS= read -r file; do
		grep -Fq '把档位模型传给受托者。' "${file}" || fail "${file} lacks the Chinese tier-model entry"
	done < <(find -L "${ROOT_DIR}/${tree}/skills" -type f -name SKILL_zh.md)
	for skill in star-flow-status star-expt-digest; do
		grep -Fq 'READ-tier entry on this harness.' "${ROOT_DIR}/${tree}/skills/${skill}/SKILL.md" || fail "${tree} ${skill} lacks its READ entry"
		grep -Fq '本宿主的 READ 档入口。' "${ROOT_DIR}/${tree}/skills/${skill}/SKILL_zh.md" || fail "${tree} ${skill} lacks its Chinese READ entry"
	done
done
note "seven trees retain tier-model and READ routing entries"

for schema in TaskItem ChainItem SubagentParams; do
	if ! sed -n "/const ${schema} = Type.Object({/,/^});/p" "${ROOT_DIR}/.pi/extensions/star-subagent/index.ts" | grep -Fq 'model: Type.Optional'; then
		fail "Pi ${schema} schema lacks model"
	fi
done
note "Pi single, parallel, and chain schemas expose model"
