#!/usr/bin/env bash
# Offline regression checks for execs/configure.sh and its static consumers.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/star-model-routing.XXXXXX")"
PROJECT="${TMP_DIR}/project"
trap 'rm -rf -- "${TMP_DIR}"' EXIT

fail() { printf 'FAIL  %s\n' "$*" >&2; exit 1; }
note() { printf 'ok    %s\n' "$*"; }
expect_model() { grep -Fqx "model: \"$2\"" "$1" || fail "$1 should have model $2"; }
expect_plain_model() { grep -Fqx "model: $2" "$1" || fail "$1 should have unquoted model $2"; }
expect_effort() { grep -Fqx "effort: \"$2\"" "$1" || fail "$1 should have effort $2"; }
run_models() { (cd "${PROJECT}" && bash execs/configure.sh "$@") >/dev/null; }
models_output() { (cd "${PROJECT}" && bash execs/configure.sh "$@") 2>&1; }
test_python_home="$(sed -n 's/^PYTHON_HOME=//p' "${ROOT_DIR}/.env" | tail -1)"
if [[ -z "${test_python_home}" ]]; then
	test_conda_home="$(sed -n 's/^CONDA_HOME=//p' "${ROOT_DIR}/.env" | tail -1)"
	test_env_name="$(sed -n 's/^ENV_NAME=//p' "${ROOT_DIR}/.env" | tail -1)"
	[[ -n "${test_conda_home}" && -n "${test_env_name}" ]] || fail "configure the project Python in .env"
	test_python_home="${test_conda_home}/envs/${test_env_name}"
fi
test_python="${test_python_home}/bin/python"

mkdir -p "${PROJECT}/execs"
cp "${ROOT_DIR}/execs/configure.sh" "${PROJECT}/execs/configure.sh"
cp "${ROOT_DIR}/execs/update.sh" "${PROJECT}/execs/update.sh"
: > "${PROJECT}/execs/run.sh"
for flag in --models --kimi-pool; do
	if output="$(cd "${PROJECT}" && bash execs/update.sh "${flag}" 2>&1)"; then
		fail "update.sh still accepts the removed ${flag} option"
	fi
	grep -Fq "Unknown option: ${flag}" <<<"${output}" || fail "unexpected rejection of ${flag}"
done
note "update.sh rejects model operations; configure.sh owns the offline entry points"
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
# The three named delegates Claude Code dispatches a tier through: their frontmatter
# is where a depth becomes a per-dispatch control rather than the run's own setting.
mkdir -p "${PROJECT}/.claude/agents"
for tier in plan exec read; do
	cp "${ROOT_DIR}/.claude/agents/star-${tier}.md" "${PROJECT}/.claude/agents/"
done

write_env() { printf '%s\n' "PYTHON_HOME=${test_python_home}" "$@" > "${PROJECT}/.env"; }
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
	expect_plain_model "${PROJECT}/.cursor/agents/star-${tier}.md" "cursor-${tier}"
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
# of that tier, Cursor appends it as -<depth> on the named agent's model field —
# the flat one-id-per-depth form its catalog lists — Qwen keeps a non-depth suffix
# in the name, and a suffix spelling no depth stays part of the name.
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
expect_effort "${PROJECT}/.claude/agents/star-plan.md" xhigh
expect_effort "${PROJECT}/.claude/agents/star-exec.md" high
expect_effort "${PROJECT}/.claude/agents/star-read.md" medium
expect_plain_model "${PROJECT}/.cursor/agents/star-exec.md" 'cursor-exec-high'
expect_model "${PROJECT}/.qwen/agents/star-read.md" qwen-read@keep
note "a depth suffix reaches Claude Code as effort, Cursor as a -<depth> id, and leaves other model names clean"

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
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.md" ||
	fail "harness adapters do not define Codex per-dispatch effort"
grep -Fq '显式传给 `reasoning_effort`' \
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.zh-CN.md" ||
	fail "Chinese harness adapters do not define Codex per-dispatch effort"
grep -Fq 'appends a configured `@<depth>` to the model as `-<depth>` and writes that flat id, unquoted, onto that tier'\''s named agent'\''s `model:`' \
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.md" ||
	fail "harness adapters do not stamp Cursor -<depth> as the model field"
grep -Fq 'scan that list for a slug of the same model family that already carries the wanted depth' \
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.md" ||
	fail "harness adapters do not map Cursor @depth onto a listed variant"
grep -Fq 'omit `model` so the file stamp is not overridden' \
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.md" ||
	fail "harness adapters do not leave an unlisted Cursor Task model unpassed"
grep -Fq '把 `.env` 的 `@<深度>` 以 `-<深度>` 接在模型名后，再把这个扁平 id 不加引号写进该档具名代理的 `model:`' \
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.zh-CN.md" ||
	fail "Chinese harness adapters do not stamp Cursor -<depth> as the model field"
grep -Fq '在该列表里找同族且已带所需深度的 slug' \
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.zh-CN.md" ||
	fail "Chinese harness adapters do not map Cursor @depth onto a listed variant"
grep -Fq '省略 `model`，以免盖过文件盖章' \
	"${ROOT_DIR}/docs/mds/star-workflow/harness-adapters.zh-CN.md" ||
	fail "Chinese harness adapters do not leave an unlisted Cursor Task model unpassed"
grep -Fq 'or carries a depth' "${ROOT_DIR}/.claude/commands/star-auto.md" ||
	fail "Claude star-auto does not route an explicit same-model depth"
while IFS= read -r file; do
	grep -Fq 'a configured depth is reason enough to dispatch' "${file}" ||
		fail "${file} does not route a same-model depth to a named agent"
done < <(find -L "${ROOT_DIR}/.claude/skills" -type f -name SKILL.md)
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

# Kimi consumes both halves at dispatch through its secondary-model pool: a depth
# selects the pool alias binding it. This checks the parsed summary and contracts.
write_env \
	'STAR_PLAN_MODEL=kimi:kimi-k3@max' \
	'STAR_EXEC_MODEL=kimi:kimi-k3@high' \
	'STAR_READ_MODEL=kimi:kimi-k3'
kimi_output="$(models_output --harnesses kimi)"
for expected in \
	'STAR_PLAN_MODEL in .env gives Kimi Code at dispatch: model alias kimi-k3-max' \
	'STAR_EXEC_MODEL in .env gives Kimi Code at dispatch: model alias kimi-k3-high' \
	'STAR_READ_MODEL in .env gives Kimi Code at dispatch: model alias kimi-k3;'; do
	grep -Fq "${expected}" <<<"${kimi_output}" || fail "Kimi model/depth summary lacks: ${expected}"
done
while IFS= read -r file; do
	grep -Fq 'a configured depth is reason enough to dispatch' "${file}" ||
		fail "${file} does not route a same-model depth to a pool alias"
done < <(find -L "${ROOT_DIR}/.kimi-code/skills" -type f -name SKILL.md)
while IFS= read -r file; do
	grep -Fq '也足以构成派发的理由' "${file}" ||
		fail "${file} does not route a same-model depth to a pool alias in Chinese"
done < <(find -L "${ROOT_DIR}/.kimi-code/skills" -type f -name SKILL_zh.md)
note "Kimi summaries name the pool alias per depth; skills route a same-model depth"

# --kimi-pool registers the variants and pool keys the kimi tier entries need in
# Kimi Code's own config: additive, idempotent, never over an existing entry, and
# a skipped variant never leaves a dangling pool key behind.
KIMI_HOME="${TMP_DIR}/kimi-home"
mkdir -p "${KIMI_HOME}"
cat > "${KIMI_HOME}/config.toml" <<'EOF'
[models.kimi-k3]
provider = "managed:kimi-code"
model = "k3"
max_context_size = 1048576
capabilities = [ "thinking" ]
support_efforts = [ "low", "high", "max" ]
default_effort = "high"

[models.kimi-k3-low]
provider = "managed:kimi-code"
model = "k3"
max_context_size = 1048576
support_efforts = [ "low", "high", "max" ]

[models.kimi-k3-low.overrides]
default_effort = "low"

[secondary_model]
default_model = "kimi-k3-low"

[secondary_model.models]
kimi-k3-low = "User's own hint, kept."
EOF
write_env \
	'STAR_PLAN_MODEL=kimi:kimi-k3@max' \
	'STAR_EXEC_MODEL=kimi:kimi-k3@high' \
	'STAR_READ_MODEL=kimi:kimi-k3@low'
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
cfg="${KIMI_HOME}/config.toml"
expect_pool() { grep -Fq "$2" "${cfg}" || fail "--kimi-pool: $1"; }
"${test_python}" - "${cfg}" <<'PY'
import sys
import tomllib
from pathlib import Path
config = tomllib.loads(Path(sys.argv[1]).read_text())
for depth in ('max', 'high'):
    variant = config['models'][f'kimi-k3-{depth}']
    assert variant['provider'] == 'managed:kimi-code'
    assert variant['model'] == 'k3'
    assert variant['overrides']['default_effort'] == depth
PY
expect_pool "plan pool key missing"        '"kimi-k3-max" = "STAR plan tier: kimi-k3 at max effort."'
expect_pool "exec pool key missing"        '"kimi-k3-high" = "STAR exec tier: kimi-k3 at high effort."'
expect_pool "user pool key overwritten"    'kimi-k3-low = "User'"'"'s own hint, kept."'
expect_pool "user default_model overwritten" 'default_model = "kimi-k3-low"'
[[ "$(grep -cE '^\[models\."?kimi-k3-low"?\]' "${cfg}")" == 1 ]] ||
	fail "--kimi-pool rewrote the user's own kimi-k3-low variant"
before="$(cksum "${cfg}")"
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "--kimi-pool is not idempotent"
write_env 'STAR_PLAN_MODEL=kimi:ghost@high' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
grep -q ghost "${cfg}" && fail "--kimi-pool registered a pool key for a missing base model"
write_env 'STAR_PLAN_MODEL=kimi:ghost' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
before="$(cksum "${cfg}")"
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "--kimi-pool changed the config for a missing plain model"

# Legal indentation must not turn an existing default or pool key into a duplicate.
sed 's/^default_model/  default_model/; s/^kimi-k3-low =/  kimi-k3-low =/' "${cfg}" > "${cfg}.indented"
mv "${cfg}.indented" "${cfg}"
write_env 'STAR_PLAN_MODEL=kimi:kimi-k3' 'STAR_EXEC_MODEL=kimi:kimi-k3@low' 'STAR_READ_MODEL='
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
expect_pool "indented default changed" '  default_model = "kimi-k3-low"'
expect_pool "indented pool key changed" '  kimi-k3-low = "User'"'"'s own hint, kept."'
expect_pool "existing plain model not registered" '"kimi-k3" = "STAR plan tier: kimi-k3."'
before="$(cksum "${cfg}")"
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "--kimi-pool is not idempotent with indented keys"
write_env 'STAR_PLAN_MODEL=kimi:kimi-k3@max' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
cat > "${cfg}" <<'EOF'
[models.kimi-k3]
provider = "managed:kimi-code"
model = "k3"
support_efforts = ["max"]
[secondary_model]
default_model = "kimi-k3"
models = { kimi-k3 = "x" }
EOF
before="$(cksum "${cfg}")"
if (cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null 2>&1); then
	fail "--kimi-pool accepted an inline-table pool"
fi
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "--kimi-pool changed an unsupported config"
note "--kimi-pool registers variants and pool keys, keeps user entries, skips dangling aliases"

# Missing aliases must also leave a config with no pool entirely untouched.
printf '%s\n' '[models.kimi-k3]' 'model = "k3"' > "${cfg}"
write_env 'STAR_PLAN_MODEL=kimi:ghost' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
before="$(cksum "${cfg}")"
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "--kimi-pool created a pool for a missing model"

# A missing interpreter must fail before writing, even for a registered plain model.
write_env "PYTHON_HOME=${TMP_DIR}/missing-python" 'STAR_PLAN_MODEL=kimi:kimi-k3'
if (cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null 2>&1); then
	fail "--kimi-pool ran without its parser runtime"
fi
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "--kimi-pool wrote without its parser runtime"
write_env 'STAR_PLAN_MODEL=kimi:kimi-k3' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
"${test_python}" - "${cfg}" <<'PY'
import sys
import tomllib
from pathlib import Path
path = Path(sys.argv[1])
config = tomllib.loads(path.read_text())
assert config['secondary_model']['default_model'] == 'kimi-k3'
assert config['secondary_model']['models'] == {'kimi-k3': 'STAR plan tier: kimi-k3.'}
backup = sorted(path.parent.glob('config.toml.star-bak-*'))[-1]
assert backup.read_bytes() == b'[models.kimi-k3]\nmodel = "k3"\n'
PY
note "--kimi-pool handles missing pools, requires its parser, and preserves a complete backup"

# --kimi-pool refuses a missing config rather than inventing one.
if (cd "${PROJECT}" && KIMI_CODE_HOME="${TMP_DIR}/nowhere" bash execs/configure.sh --kimi-pool >/dev/null 2>&1); then
	fail "--kimi-pool ran without a config.toml"
fi
note "--kimi-pool refuses a missing config"

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
[[ "$(snapshot)" == "${before}" ]] || fail "a second configure.sh run changed the fixture"
note "configure.sh is idempotent"

write_env 'STAR_PLAN_MODEL=unknown:ignored' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
run_models --harnesses qwen
expect_model "${PROJECT}/.qwen/agents/star-plan.md" qwen-plan
expect_model "${PROJECT}/.qwen/agents/star-exec.md" bare-exec
note "unknown tags and empty values leave existing stamps alone"

write_env 'STAR_PLAN_MODEL=cursor:cursor-only,qwen:qwen-only' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
run_models --harnesses cursor
expect_plain_model "${PROJECT}/.cursor/agents/star-plan.md" cursor-only
expect_model "${PROJECT}/.qwen/agents/star-plan.md" qwen-plan
expect_model "${PROJECT}/.claude/skills/star-flow-status/SKILL.md" claude-read
note "--harnesses changes only the selected tree"

# The tier lists in execs/configure.sh duplicate the roster's Tier column, and a skill
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
	' "${ROOT_DIR}/execs/configure.sh" | LC_ALL=C sort
}
for tier in plan exec read; do
	diff <(roster_tier_skills "${tier}") <(script_tier_skills "${tier}") > /dev/null ||
		fail "execs/configure.sh's ${tier}-tier skill list does not match the §10 roster's ${tier} rows"
done
note "the depth-stamp tier lists match the conventions §10 roster"

for tree in .agents .claude .cursor .dsh .kimi-code .pi .qwen; do
	while IFS= read -r file; do
		grep -Fq 'Passing a tier model' "${file}" || fail "${file} lacks the tier-model entry"
	done < <(find -L "${ROOT_DIR}/${tree}/skills" -type f -name SKILL.md)
	while IFS= read -r file; do
		grep -Fq '传给受托者。' "${file}" || fail "${file} lacks the Chinese tier-model entry"
	done < <(find -L "${ROOT_DIR}/${tree}/skills" -type f -name SKILL_zh.md)
	for skill in star-flow-status star-expt-digest; do
		grep -Fq 'READ-tier entry on this harness.' "${ROOT_DIR}/${tree}/skills/${skill}/SKILL.md" || fail "${tree} ${skill} lacks its READ entry"
		grep -Fq '本宿主的 READ 档入口。' "${ROOT_DIR}/${tree}/skills/${skill}/SKILL_zh.md" || fail "${tree} ${skill} lacks its Chinese READ entry"
	done
done
note "seven trees retain tier-model and READ routing entries"

while IFS= read -r file; do
	grep -Fq 'Pass the stamped id when this session'\''s selectable `Task` `model` list contains it' "${file}" ||
		fail "${file} does not pass the stamped Cursor id when Task lists it"
	grep -Fq 'scan that list for a slug of the same model family that already carries the wanted depth' "${file}" ||
		fail "${file} does not map Cursor @depth onto a listed variant"
	grep -Fq 'omit `model` so the file stamp is not overridden' "${file}" ||
		fail "${file} does not leave an unlisted Cursor Task model unpassed"
	grep -Fq 'appends a configured `@<depth>` as `-<depth>` and writes that flat id' "${file}" ||
		fail "${file} does not keep Cursor's flat -<depth> id as the stamp"
	if grep -Fq 'Do not pass an undocumented per-call' "${file}"; then
		fail "${file} still forbids passing Task model"
	fi
	if grep -Fq 'the file is not the routing' "${file}"; then
		fail "${file} still denies the official Cursor stamp"
	fi
done < <(find -L "${ROOT_DIR}/.cursor/skills" -type f -name SKILL.md)
while IFS= read -r file; do
	grep -Fq '本会话 `Task` 的 `model` 可选列表含该盖章 id 时就传它' "${file}" ||
		fail "${file} does not pass the stamped Cursor id when Task lists it in Chinese"
	grep -Fq '在该列表里找同族且已带所需深度的 slug' "${file}" ||
		fail "${file} does not map Cursor @depth onto a listed variant in Chinese"
	grep -Fq '省略 `model`，以免盖过文件盖章' "${file}" ||
		fail "${file} does not leave an unlisted Cursor Task model unpassed in Chinese"
	grep -Fq '把配置的 `@<深度>` 以 `-<深度>` 接在模型名后' "${file}" ||
		fail "${file} does not keep Cursor's flat -<depth> id as the stamp in Chinese"
	if grep -Fq '不传文档未声明的按次' "${file}"; then
		fail "${file} still forbids passing Task model in Chinese"
	fi
	if grep -Fq '文件也不是路由' "${file}"; then
		fail "${file} still denies the official Cursor stamp in Chinese"
	fi
done < <(find -L "${ROOT_DIR}/.cursor/skills" -type f -name SKILL_zh.md)
grep -Fq 'Pass the stamped id when this session'\''s selectable `Task` `model` list contains it' \
	"${ROOT_DIR}/.cursor/commands/star-auto.md" ||
	fail "Cursor star-auto does not pass the stamped id when Task lists it"
grep -Fq 'scan that list for a slug of the same model family that already carries the wanted depth' \
	"${ROOT_DIR}/.cursor/commands/star-auto.md" ||
	fail "Cursor star-auto does not map @depth onto a listed variant"
grep -Fq 'omit `model` so the file stamp is not overridden' \
	"${ROOT_DIR}/.cursor/commands/star-auto.md" ||
	fail "Cursor star-auto does not leave an unlisted Task model unpassed"
if grep -Fq 'Do not pass an undocumented per-call model parameter' \
	"${ROOT_DIR}/.cursor/commands/star-auto.md"; then
	fail "Cursor star-auto still forbids passing Task model"
fi
if grep -Fq 'they are not the routing' \
	"${ROOT_DIR}/.cursor/commands/star-auto.md"; then
	fail "Cursor star-auto still denies the official Cursor stamp"
fi
note "Cursor skills and star-auto stamp a flat -<depth> id, pass a listed Task slug, and omit model when none matches"

for schema in TaskItem ChainItem SubagentParams; do
	if ! sed -n "/const ${schema} = Type.Object({/,/^});/p" "${ROOT_DIR}/.pi/extensions/star-subagent/index.ts" | grep -Fq 'model: Type.Optional'; then
		fail "Pi ${schema} schema lacks model"
	fi
done
note "Pi single, parallel, and chain schemas expose model"

# Exercise the updater's actual install paths against a local upstream snapshot.
UPSTREAM="${TMP_DIR}/upstream"
UPDATE_PROJECT="${TMP_DIR}/update-project"
mkdir -p "${UPSTREAM}" "${UPDATE_PROJECT}"
git -C "${ROOT_DIR}" archive HEAD | tar -x -C "${UPSTREAM}"
cp -p "${ROOT_DIR}/execs/update.sh" "${ROOT_DIR}/execs/configure.sh" "${UPSTREAM}/execs/"
git -C "${UPSTREAM}" init -q -b main
git -C "${UPSTREAM}" add -f .
git -C "${UPSTREAM}" -c core.hooksPath=/dev/null -c user.name=Test \
	-c user.email=test@example.invalid commit -qm fixture
git -C "${UPDATE_PROJECT}" init -q
printf '%s\n' 'STAR_HARNESSES=cursor' 'STAR_READ_MODEL=cursor:fixture-read' > "${UPDATE_PROJECT}/.env"
run_update() {
	(cd "${UPDATE_PROJECT}" && STAR_REPOSITORY="${UPSTREAM}" bash "$@") \
		> "${TMP_DIR}/update.log" 2>&1 || { cat "${TMP_DIR}/update.log"; fail "updater integration"; }
}
run_update "${UPSTREAM}/execs/update.sh" --adopt --harnesses cursor
[[ -f "${UPDATE_PROJECT}/execs/configure.sh" ]] || fail "adopt omitted configure.sh"
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-read
printf '# stale test fixture\n' > "${UPDATE_PROJECT}/execs/configure.sh"
run_update execs/update.sh --force --harnesses cursor
cmp -s "${UPSTREAM}/execs/configure.sh" "${UPDATE_PROJECT}/execs/configure.sh" || fail "update omitted configure.sh"
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-read
rm "${UPDATE_PROJECT}/execs/configure.sh"
run_update execs/update.sh --force --skill star-flow-status --harnesses cursor
[[ -f "${UPDATE_PROJECT}/execs/configure.sh" ]] || fail "skill update omitted configure.sh"
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-read
note "adopt, ordinary update and skill update install configure.sh and reapply model settings"
