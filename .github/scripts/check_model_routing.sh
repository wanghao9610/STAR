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
expect_effort() { grep -Fqx "effort: \"$2\"" "$1" || fail "$1 should have effort $2"; }
run_models() { (cd "${PROJECT}" && bash execs/update.sh --models "$@") >/dev/null; }
models_output() { (cd "${PROJECT}" && bash execs/update.sh --models "$@") 2>&1; }

mkdir -p "${PROJECT}/execs"
cp "${ROOT_DIR}/execs/update.sh" "${PROJECT}/execs/update.sh"
: > "${PROJECT}/execs/run.sh"
for harness in cursor qwen; do
	for tier in plan exec read; do
		mkdir -p "${PROJECT}/.${harness}/agents"
		cp "${ROOT_DIR}/.${harness}/agents/star-${tier}.md" "${PROJECT}/.${harness}/agents/"
	done
done
# The two READ manifests take the READ model; the other two stand in for the plan
# and exec tiers, which take a depth and no model.
for skill in star-flow-status star-expt-digest star-plan-executor star-code-reviewer; do
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
note "three tiers route to Cursor and Qwen; Claude stamps only the READ model"

# A tier entry may end in @<depth>. Claude Code takes the depth into every manifest
# of that tier, every tree takes the model without it, and a suffix spelling no
# depth stays part of the name.
write_env \
	'STAR_PLAN_MODEL=claude:claude-plan@xhigh' \
	'STAR_EXEC_MODEL=claude:claude-exec@high,cursor:cursor-exec@high' \
	'STAR_READ_MODEL=claude:claude-read@medium,qwen:qwen-read@keep'
run_models

expect_effort "${PROJECT}/.claude/skills/star-plan-executor/SKILL.md" xhigh
expect_effort "${PROJECT}/.claude/skills/star-plan-executor/SKILL_zh.md" xhigh
expect_effort "${PROJECT}/.claude/skills/star-code-reviewer/SKILL.md" high
for skill in star-flow-status star-expt-digest; do
	expect_model "${PROJECT}/.claude/skills/${skill}/SKILL.md" claude-read
	expect_effort "${PROJECT}/.claude/skills/${skill}/SKILL.md" medium
done
if grep -Fqx 'model: "claude-plan"' "${PROJECT}/.claude/skills/star-plan-executor/SKILL.md"; then
	fail "a plan-tier manifest should take its tier's depth and no model stamp"
fi
expect_model "${PROJECT}/.cursor/agents/star-exec.md" cursor-exec
expect_model "${PROJECT}/.qwen/agents/star-read.md" qwen-read@keep
note "a depth suffix reaches Claude Code's manifests and leaves every model name clean"

# Codex consumes both halves at dispatch rather than through a static manifest.
# This checks the parsed summary and instruction contracts, not a live dispatch.
write_env \
	'STAR_PLAN_MODEL=codex:gpt-6-astra@xhigh' \
	'STAR_EXEC_MODEL=codex:gpt-6-astra@high' \
	'STAR_READ_MODEL=codex:gpt-6-astra@low'
codex_output="$(models_output --harnesses codex)"
for expected in \
	'STAR_PLAN_MODEL in .env gives Codex at dispatch: model gpt-6-astra, requested reasoning effort xhigh' \
	'STAR_EXEC_MODEL in .env gives Codex at dispatch: model gpt-6-astra, requested reasoning effort high' \
	'STAR_READ_MODEL in .env gives Codex at dispatch: model gpt-6-astra, requested reasoning effort low'; do
	grep -Fq "${expected}" <<<"${codex_output}" || fail "Codex model/depth summary lacks: ${expected}"
done
for file in \
	"${ROOT_DIR}/.codex/plugins/star/skills/star-auto/SKILL.md" \
	"${ROOT_DIR}/.codex/plugins/star/skills/star-auto/SKILL_zh.md"; do
	grep -Fq 'reasoning_effort' "${file}" || fail "${file} does not pass Codex effort per dispatch"
	grep -Fq 'fork_turns' "${file}" || fail "${file} does not preserve fresh-context routing"
done
grep -Fq 'even when the model is unchanged' \
	"${ROOT_DIR}/.codex/plugins/star/skills/star-auto/SKILL.md" ||
	fail "Codex star-auto does not route an explicit same-model depth"
grep -Fq '即使不换模型也会触发' \
	"${ROOT_DIR}/.codex/plugins/star/skills/star-auto/SKILL_zh.md" ||
	fail "Chinese Codex star-auto does not route an explicit same-model depth"
grep -Fq 'or the harness can apply its depth per dispatch' \
	"${ROOT_DIR}/.agents/skills/star-plan-executor/SKILL.md" ||
	fail "star-plan-executor does not route a same-model EXEC depth"
grep -Fq 'or a depth this harness can apply per dispatch' \
	"${ROOT_DIR}/.agents/skills/star-code-architect/SKILL.md" ||
	fail "star-code-architect does not route a same-model EXEC depth"
grep -Fq 'passes it explicitly as `reasoning_effort`' \
	"${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.md" ||
	fail "workflow conventions do not define Codex per-dispatch effort"
grep -Fq '显式传给 `reasoning_effort`' \
	"${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.zh-CN.md" ||
	fail "Chinese workflow conventions do not define Codex per-dispatch effort"
grep -Fq 'Codex passes a supported named depth per dispatch as `reasoning_effort`' \
	"${ROOT_DIR}/AGENTS.md" ||
	fail "AGENTS.md does not expose Codex per-dispatch effort"
for skill in star-flow-status star-expt-digest; do
	entry="$(grep -F '**READ-tier entry on this harness.**' "${ROOT_DIR}/.agents/skills/${skill}/SKILL.md")"
	grep -Fq 'or the harness can apply its depth per dispatch' <<<"${entry}" ||
		fail "${skill} READ entry omits a same-model depth"
	grep -Fq 'with that model and supported depth' <<<"${entry}" ||
		fail "${skill} READ entry does not pass its depth"
	if grep -Fq 'differs from the known current model' <<<"${entry}"; then
		fail "${skill} READ entry still requires a different model"
	fi
	entry="$(grep -F '**本宿主的 READ 档入口。**' "${ROOT_DIR}/.agents/skills/${skill}/SKILL_zh.md")"
	grep -Fq '或宿主能逐次应用其深度' <<<"${entry}" ||
		fail "Chinese ${skill} READ entry omits a same-model depth"
	grep -Fq '传入该模型与受支持的深度' <<<"${entry}" ||
		fail "Chinese ${skill} READ entry does not pass its depth"
	if grep -Fq '不同于已知当前模型' <<<"${entry}"; then
		fail "Chinese ${skill} READ entry still requires a different model"
	fi
done
note "Codex summaries parse three efforts; auto, EXEC, and direct READ instructions carry depth routing"

# Only positive numeric suffixes are depths. Zero and unknown suffixes belong to
# the model name; leading zeros on a positive number do not change its validity.
for suffix in 0 00 keep 1 001 2048; do
	write_env "STAR_PLAN_MODEL=codex:gpt-6-astra@${suffix}" 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
	case "${suffix}" in
		0|00|keep) expected="model gpt-6-astra@${suffix}, requested reasoning effort default" ;;
		*) expected="model gpt-6-astra, requested reasoning effort ${suffix}" ;;
	esac
	codex_output="$(models_output --harnesses codex)"
	grep -Fq "${expected}" <<<"${codex_output}" || fail "incorrect Codex suffix parsing: @${suffix}"
done
note "positive integer depths parse; zero and unknown suffixes remain model text"

# An entry with no depth changes no depth: the stamps above stay as they are.
write_env 'STAR_PLAN_MODEL=claude:claude-plan' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
run_models
expect_effort "${PROJECT}/.claude/skills/star-plan-executor/SKILL.md" xhigh
expect_effort "${PROJECT}/.claude/skills/star-code-reviewer/SKILL.md" high
note "an entry without a depth leaves the stamped depth in place"

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

# The tier lists in execs/update.sh duplicate the roster's Tier column, and a skill
# that changes tier in one and not the other takes the wrong depth with nothing said.
roster_tier_skills() { # $1 = plan, exec, or read
	awk -v want="$1" -F'|' '
		/^\| `star-/ {
			name = $2; tier = $3
			gsub(/[` \t\302\240]/, "", name); sub(/†/, "", name)
			gsub(/[ \t]/, "", tier)
			if (tier == want) print name
		}
	' "${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.md" | LC_ALL=C sort
}
script_tier_skills() { # $1 = plan, exec, or read
	awk -v arr="CLAUDE_$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')_SKILLS=(" '
		index($0, arr) == 1 { inside = 1; next }
		inside && /^\)/ { exit }
		inside { gsub(/["[:space:]]/, ""); if ($0 != "") print }
	' "${ROOT_DIR}/execs/update.sh" | LC_ALL=C sort
}
for tier in plan exec read; do
	diff <(roster_tier_skills "${tier}") <(script_tier_skills "${tier}") > /dev/null ||
		fail "execs/update.sh's ${tier}-tier skill list does not match the §10 roster's ${tier} rows"
done
note "the depth-stamp tier lists match the conventions §10 roster"

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
