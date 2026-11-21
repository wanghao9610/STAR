#!/usr/bin/env bash
# Offline regression checks for execs/configure.sh and its static consumers.
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/star-model-routing.XXXXXX")"
PROJECT="${TMP_DIR}/project"
trap 'rm -rf -- "${TMP_DIR}"' EXIT

fail() { printf 'FAIL  %s\n' "$*" >&2; exit 1; }
note() { printf 'ok    %s\n' "$*"; }
harness_adapter() {
	awk -v heading="#### $1" '$0 == heading { active=1; next } active && /^#### / { exit } active' \
		"${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.md"
}
expect_model() { grep -Fqx "model: \"$2\"" "$1" || fail "$1 should have model $2"; }
expect_plain_model() { grep -Fqx "model: $2" "$1" || fail "$1 should have unquoted model $2"; }
expect_effort() { grep -Fqx "effort: \"$2\"" "$1" || fail "$1 should have effort $2"; }
run_models() { (cd "${PROJECT}" && bash execs/configure.sh "$@") >/dev/null; }
models_output() { (cd "${PROJECT}" && bash execs/configure.sh "$@") 2>&1; }
# A literal fixture path exercises .env parsing without any runtime dependency.
test_python_home="${TMP_DIR}/unused interpreter path"
unset STAR_HARNESSES STAR_REPOSITORY STAR_PLAN_MODEL STAR_EXEC_MODEL STAR_READ_MODEL

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
for harness in cursor qwen devin; do
	for tier in plan exec read; do
		mkdir -p "${PROJECT}/.${harness}/agents"
		cp "${ROOT_DIR}/.${harness}/agents/star-${tier}.md" "${PROJECT}/.${harness}/agents/"
	done
	# Devin's two bounded read-only profiles take their tier's stamp too.
	if [[ "${harness}" == devin ]]; then
		cp "${ROOT_DIR}/.devin/agents/star-plan-blind.md" "${ROOT_DIR}/.devin/agents/star-read-local.md" \
			"${PROJECT}/.devin/agents/"
	fi
done
# The two READ manifests take the READ model; the other two stand in for the plan
# and exec tiers, which take a depth and no model.
for skill in star-flow-status star-expt-digest star-plan-executor star-code-reviewer; do
	mkdir -p "${PROJECT}/.claude/skills/${skill}"
	cp "${ROOT_DIR}/.claude/skills/${skill}/SKILL.md" "${PROJECT}/.claude/skills/${skill}/"
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
		find .claude .cursor .devin .qwen -type f | LC_ALL=C sort | while IFS= read -r file; do cksum "${file}"; done
	)
}

# Quoted values use the same literals as a sourced .env, including spaces and
# backslashes. CRLF and comments after a value do not become part of it.
printf 'PYTHON_HOME="%s"\r\nSTAR_HARNESSES="cursor" # selected tree\r\nSTAR_READ_MODEL='"'"'cursor:quoted\\model'"'"' # literal slash\r\n' \
	"${test_python_home}" > "${PROJECT}/.env"
run_models
expect_plain_model "${PROJECT}/.cursor/agents/star-read.md" 'quoted\model'
write_env 'STAR_HARNESSES=qwen' 'STAR_READ_MODEL="qwen:double\"quote\$dollar"'
run_models
grep -Fqx 'model: "double\"quote$dollar"' "${PROJECT}/.qwen/agents/star-read.md" ||
	fail "double-quoted .env escapes did not match sourced shell literals"
write_env 'STAR_HARNESSES=qwen' 'STAR_READ_MODEL=qwen:space\ model'
run_models
expect_model "${PROJECT}/.qwen/agents/star-read.md" 'space model'
write_env 'STAR_HARNESSES=qwen' 'STAR_READ_MODEL="qwen:literal;(&|<>~)"'
run_models
expect_model "${PROJECT}/.qwen/agents/star-read.md" 'literal;(&|<>~)'
note "quoted .env values, escapes, paths, trailing comments, backslashes and CRLF parse as literals"

# Dynamic shell syntax must fail as configuration and must never run. Malformed
# quoting must also fail instead of becoming an unknown harness or empty value.
expansion_marker="${TMP_DIR}/env-expansion-ran"
printf '%s\n' "PYTHON_HOME=${test_python_home}" \
	"STAR_HARNESSES=\"\$(touch ${expansion_marker})\"" > "${PROJECT}/.env"
if expansion_output="$(models_output)"; then
	fail "configure.sh accepted shell expansion syntax in .env"
fi
[[ ! -e "${expansion_marker}" ]] || fail "configure.sh executed shell expansion syntax in .env"
grep -Fq 'shell expansion is unsupported' <<<"${expansion_output}" ||
	fail "configure.sh did not explain rejected shell expansion syntax"
control_marker="${TMP_DIR}/env-control-ran"
printf '%s\n' "PYTHON_HOME=${test_python_home}" \
	"STAR_HARNESSES=cursor;touch ${control_marker}" > "${PROJECT}/.env"
if control_output="$(models_output)"; then
	fail "configure.sh accepted unquoted shell control syntax in .env"
fi
[[ ! -e "${control_marker}" ]] || fail "configure.sh executed shell control syntax in .env"
grep -Fq 'unquoted shell syntax is unsupported' <<<"${control_output}" ||
	fail "configure.sh did not explain rejected shell control syntax"
write_env 'STAR_HARNESSES=~cursor'
if tilde_output="$(models_output)"; then
	fail "configure.sh accepted unquoted tilde expansion in .env"
fi
grep -Fq 'unquoted tilde expansion is unsupported' <<<"${tilde_output}" ||
	fail "configure.sh did not explain rejected tilde expansion"
plan_before_malformed="$(cksum "${PROJECT}/.cursor/agents/star-plan.md")"
write_env 'STAR_PLAN_MODEL=cursor:must-not-stamp' 'STAR_READ_MODEL="cursor:unterminated'
if malformed_output="$(models_output --harnesses cursor)"; then
	fail "configure.sh accepted an unterminated quoted .env value"
fi
grep -Fq 'unterminated double-quoted value' <<<"${malformed_output}" ||
	fail "configure.sh did not explain an unterminated quoted .env value"
[[ "$(cksum "${PROJECT}/.cursor/agents/star-plan.md")" == "${plan_before_malformed}" ]] ||
	fail "configure.sh stamped a valid tier before rejecting a later malformed value"
write_env 'STAR_HARNESSES="unterminated' 'STAR_READ_MODEL=cursor:flag-override-read'
run_models --harnesses cursor
expect_plain_model "${PROJECT}/.cursor/agents/star-read.md" flag-override-read
write_env 'STAR_HARNESSES="unterminated' 'STAR_READ_MODEL=cursor:env-override-read'
(cd "${PROJECT}" && STAR_HARNESSES=cursor bash execs/configure.sh >/dev/null)
expect_plain_model "${PROJECT}/.cursor/agents/star-read.md" env-override-read
note "invalid active .env syntax fails without execution or partial stamps; flag and environment harness overrides skip the unused file value"

# Tagged values beat the bare fallback; qwen's EXEC value exercises the fallback,
# while its READ value retains a provider-style colon after the qwen tag.
write_env \
	'STAR_PLAN_MODEL=bare-plan,unknown:ignored,cursor:cursor-plan,devin:devin-plan,qwen:qwen-plan' \
	'STAR_EXEC_MODEL=unknown:ignored,bare-exec,cursor:cursor-exec,devin:swe' \
	'STAR_READ_MODEL=bare-read,claude:claude-read,cursor:cursor-read,devin:devin-read,qwen:authType:model-id'
run_models

for tier in plan exec read; do
	expect_plain_model "${PROJECT}/.cursor/agents/star-${tier}.md" "cursor-${tier}"
done
expect_model "${PROJECT}/.devin/agents/star-plan.md" devin-plan
expect_model "${PROJECT}/.devin/agents/star-exec.md" swe
expect_model "${PROJECT}/.devin/agents/star-read.md" devin-read
expect_model "${PROJECT}/.qwen/agents/star-plan.md" qwen-plan
expect_model "${PROJECT}/.qwen/agents/star-exec.md" bare-exec
expect_model "${PROJECT}/.qwen/agents/star-read.md" authType:model-id
for skill in star-flow-status star-expt-digest; do
	expect_model "${PROJECT}/.claude/skills/${skill}/SKILL.md" claude-read
done
note "three tiers route to Cursor, Devin and Qwen; Claude stamps only the READ model"

# A tier entry may end in @<depth>. Claude Code takes the depth into every manifest
# of that tier, Cursor appends it as -<depth> on the named agent's model field —
# the flat one-id-per-depth form its catalog lists — Devin does the same on its
# quoted model field, Qwen keeps a non-depth suffix in the name, and a suffix
# spelling no depth stays part of the name. Devin's READ entry is the untagged
# fallback.
write_env \
	'STAR_PLAN_MODEL=claude:claude-plan@xhigh,devin:devin-plan@high' \
	'STAR_EXEC_MODEL=claude:claude-exec@high,cursor:cursor-exec@high' \
	'STAR_READ_MODEL=bare-read,claude:claude-read@medium,qwen:qwen-read@keep'
devin_log="$(models_output)"

expect_effort "${PROJECT}/.claude/skills/star-plan-executor/SKILL.md" xhigh
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
expect_model "${PROJECT}/.devin/agents/star-plan.md" devin-plan-high
expect_model "${PROJECT}/.devin/agents/star-plan-blind.md" devin-plan-high
expect_model "${PROJECT}/.devin/agents/star-read.md" bare-read
expect_model "${PROJECT}/.devin/agents/star-read-local.md" bare-read
if grep -q '^effort:' "${PROJECT}/.devin/agents/star-plan.md"; then
	fail "Devin takes its depth in the model id, not an effort field"
fi
grep -Fq 'STAR_PLAN_MODEL in .env gives Devin: devin-plan-high stamped into .devin/agents/star-plan.md' <<< "${devin_log}" ||
	fail "configure.sh does not report the Devin depth it stamped"
note "a depth suffix reaches Claude Code as effort, Cursor and Devin as a -<depth> id, and leaves other model names clean"

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
file="${ROOT_DIR}/.codex/plugins/star/skills/star-auto/SKILL.md"
grep -Fq 'reasoning_effort' "${file}" || fail "${file} does not pass Codex effort per dispatch"
grep -Fq 'fork_turns' "${file}" || fail "${file} does not preserve fresh-context routing"
grep -Fq 'even when the model is unchanged' "${file}" ||
	fail "Codex star-auto does not route an explicit same-model depth"
grep -Fq 'or the harness can apply its depth per dispatch' \
	"${ROOT_DIR}/.agents/skills/star-plan-executor/SKILL.md" ||
	fail "star-plan-executor does not route a same-model EXEC depth"
grep -Fq 'or a depth this harness can apply per dispatch' \
	"${ROOT_DIR}/.agents/skills/star-code-architect/SKILL.md" ||
	fail "star-code-architect does not route a same-model EXEC depth"
grep -Fq 'passes it explicitly as `reasoning_effort`' \
	"${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.md" ||
	fail "harness adapters do not define Codex per-dispatch effort"
grep -Fq 'appends a configured `@<depth>` to the model as `-<depth>` and writes that flat id, unquoted, onto that tier'\''s named agent'\''s `model:`' \
	"${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.md" ||
	fail "harness adapters do not stamp Cursor -<depth> as the model field"
grep -Fq 'scan that list for a slug of the same model family that already carries the wanted depth' \
	"${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.md" ||
	fail "harness adapters do not map Cursor @depth onto a listed variant"
grep -Fq 'omit `model` so the file stamp is not overridden' \
	"${ROOT_DIR}/docs/mds/star-workflow/research-workflow-conventions.md" ||
	fail "harness adapters do not leave an unlisted Cursor Task model unpassed"
grep -Fq 'or carries a depth' "${ROOT_DIR}/.claude/commands/star-auto.md" ||
	fail "Claude star-auto does not route an explicit same-model depth"
claude_adapter=$(harness_adapter 'Claude Code')
grep -Fq 'a configured depth is a routing difference even when the tier model aliases the active model' <<<"${claude_adapter}" ||
	fail "Claude shared adapter does not route a same-model depth"
grep -Fq 'subagent_type: star-plan' <<<"${claude_adapter}" ||
	fail "Claude shared adapter does not select a named agent for depth"
for skill in star-flow-status star-expt-digest; do
	grep -Eq '^\*\*Tier:\*\* READ\.' "${ROOT_DIR}/.agents/skills/${skill}/SKILL.md" ||
		fail "${skill} does not name its READ tier"
	if grep -Fq '**READ-tier entry on this harness.**' "${ROOT_DIR}/.agents/skills/${skill}/SKILL.md"; then
		fail "${skill} still hands the whole run to a READ delegate"
	fi
done
note "Codex summaries parse three efforts; auto and EXEC hand-offs carry depth routing; flow-status and digest runs stay where they were started"

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
kimi_adapter=$(harness_adapter 'Kimi Code')
grep -Fq 'A configured depth is thus a routing difference even when the tier model aliases the active model' <<<"${kimi_adapter}" ||
	fail "Kimi shared adapter does not route a same-model depth"
grep -Fq 'dispatched as the pool alias binding that model at that depth' <<<"${kimi_adapter}" ||
	fail "Kimi shared adapter does not select a pool alias for depth"
note "Kimi summaries name the pool alias per depth; skills route a same-model depth"

# Antigravity consumes only the four invoke_subagent Model literals at dispatch,
# ignores @<depth>, and warns on unsupported names.
write_env \
	'STAR_PLAN_MODEL=agy:pro@high' \
	'STAR_EXEC_MODEL=agy:flash' \
	'STAR_READ_MODEL=flash_lite'
agy_output="$(models_output --harnesses agy)"
for expected in \
	'STAR_PLAN_MODEL in .env gives Antigravity at dispatch: Model=pro; @high is ignored because invoke_subagent exposes no per-dispatch depth' \
	'STAR_EXEC_MODEL in .env gives Antigravity at dispatch: Model=flash; no file stamp is required.' \
	'STAR_READ_MODEL in .env gives Antigravity at dispatch: Model=flash_lite; no file stamp is required.'; do
	grep -Fq "${expected}" <<<"${agy_output}" || fail "Antigravity model summary lacks: ${expected}"
done
write_env 'STAR_PLAN_MODEL=agy:custom-model' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
agy_warn="$(models_output --harnesses agy)"
grep -Fq "WARNING: STAR_PLAN_MODEL in .env resolves to 'custom-model' for Antigravity, but invoke_subagent Model accepts only inherit, flash_lite, flash, or pro; dispatch will fall back to inherit." <<<"${agy_warn}" ||
	fail "Antigravity invalid-model warning missing: ${agy_warn}"
agy_adapter=$(harness_adapter Antigravity)
for rule in \
	'`invoke_subagent`'\''s `Model` parameter accepts only `inherit`, `flash_lite`, `flash` or `pro`' \
	'Use `TypeName: "research"` for codebase-only read-only collection and blind reads' \
	'star-refs-reviewer'; do
	grep -Fq "${rule}" <<<"${agy_adapter}" || fail "Antigravity shared adapter lacks rule: ${rule}"
done
grep -Fq 'TypeName: "research"' "${ROOT_DIR}/.agy/skills/star-auto/SKILL.md" ||
	fail "Antigravity star-auto lacks research delegate mapping"
grep -Fq 'star-refs-reviewer' "${ROOT_DIR}/.agy/skills/star-auto/SKILL.md" ||
	fail "Antigravity star-auto lacks network-fetching collector exception"
grep -Fq '`inherit` means keep the active session'\''s model' "${ROOT_DIR}/.agy/skills/star-auto/SKILL.md" ||
	fail "Antigravity star-auto does not treat inherit as keeping the active session model"
grep -Fq 'WaitMsBeforeAsync: 500' "${ROOT_DIR}/.agy/skills/star-auto/SKILL.md" ||
	fail "Antigravity star-auto does not use native run_command backgrounding for launch waits"
grep -Fq 'note_agy_hooks' "${ROOT_DIR}/execs/update.sh" ||
	fail "execs/update.sh lacks stale .agents/hooks.json migration note for .agy/hooks/"
note "Antigravity summaries validate invoke_subagent Model literals, warn on invalid values, and document delegate routing"

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
expect_toml_field() { # exact canonical header, field name, literal value
	awk -v header="$1" -v key="$2" -v expected="$3" '
		function trim(s) {gsub(/^[ \t]+|[ \t\r]+$/, "",s);return s}
		/^[ \t]*\[/ {inside=(trim($0)==header);next}
		inside {
			at=index($0,"="); name=trim(substr($0,1,at-1)); gsub(/^"|"$/,"",name)
			if(name==key && trim(substr($0,at+1))==expected) found=1
		}
		END {exit !found}
	' "${cfg}" || fail "--kimi-pool: missing $1 $2 = $3"
}
for depth in max high; do
	expect_toml_field "[\"models\".\"kimi-k3-${depth}\"]" provider '"managed:kimi-code"'
	expect_toml_field "[\"models\".\"kimi-k3-${depth}\"]" model '"k3"'
	expect_toml_field "[\"models\".\"kimi-k3-${depth}\".\"overrides\"]" default_effort "\"${depth}\""
done
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

# Pool registration is independent of the project interpreter configuration.
cp "${cfg}" "${cfg}.expected-backup"
write_env "PYTHON_HOME=${TMP_DIR}/missing-python" 'STAR_PLAN_MODEL=kimi:kimi-k3'
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null)
expect_toml_field '["secondary_model"]' default_model '"kimi-k3"'
expect_toml_field '["secondary_model"."models"]' kimi-k3 '"STAR plan tier: kimi-k3."'
backup_found=false
for backup in "${cfg}".star-bak-*; do
	if cmp -s "${backup}" "${cfg}.expected-backup"; then backup_found=true; fi
done
[[ "${backup_found}" == true ]] || fail "--kimi-pool did not preserve a complete backup"
note "--kimi-pool handles missing pools without Python and preserves a complete backup"

# A canonical quoted model name containing dots stays one table component;
# cloned variants retain comments, provider fields and nested user overrides.
cat > "${cfg}" <<'EOF'
# User configuration stays.
[models."vendor.k3"]
provider = "managed:kimi-code"
model = "k3"
support_efforts = ["high", "max"]
default_effort = "high"
custom_flag = true # kept in the variant
[models."vendor.k3".overrides]
temperature = 0.25
default_effort = "high"
[secondary_model]
force = true
EOF
write_env 'STAR_PLAN_MODEL=kimi:vendor.k3@max' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
cp "${cfg}" "${cfg}.quoted-original"
pool_output="$(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool 2>&1)"
grep -Fq 'secondary_model.force overrides per-alias routing' <<<"${pool_output}" || fail "missing pool override warning"
expect_toml_field '["models"."vendor.k3-max"]' provider '"managed:kimi-code"'
expect_toml_field '["models"."vendor.k3-max"."overrides"]' temperature '0.25'
expect_toml_field '["models"."vendor.k3-max"."overrides"]' default_effort '"max"'
grep -Fq 'custom_flag = true # kept in the variant' "${cfg}" || fail "variant lost custom field/comment"
sed '/^"default_model" =/d' "${cfg}" | head -n "$(wc -l < "${cfg}.quoted-original" | tr -d ' ')" > "${cfg}.prefix"
cmp -s "${cfg}.prefix" "${cfg}.quoted-original" || fail "original comments or fields changed"
before="$(cksum "${cfg}")"
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null 2>&1)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "quoted model config is not idempotent"
write_env 'STAR_PLAN_MODEL=kimi:vendor.k3@low' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null 2>&1)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "unsupported depth changed config"
write_env 'STAR_PLAN_MODEL=kimi:vendor.k3@unknown' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null 2>&1)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "unknown depth suffix created a dangling alias"
note "--kimi-pool preserves quoted dotted names, provider fields, nested overrides and comments; unsupported depths leave no aliases"

# Unsupported forms are rejected as a whole, without either a partial update or
# a backup. Lack of a final newline does not change a no-op configuration.
for layout in inline multiline dotted array-table invalid-number invalid-date; do
	case "${layout}" in
		inline) printf '[models.k3]\nmodel = "k3"\nextra = { enabled = true }\n' > "${cfg}" ;;
		multiline) printf '[models.k3]\nmodel = "k3"\nsupport_efforts = [\n"high"\n]\n' > "${cfg}" ;;
		dotted) printf 'models.k3.model = "k3"\n' > "${cfg}" ;;
		array-table) printf '[[models.k3]]\nmodel = "k3"\n' > "${cfg}" ;;
		invalid-number) printf '[models.k3]\nmodel = "k3"\nsize = 01\n' > "${cfg}" ;;
		invalid-date) printf '[models.k3]\nmodel = "k3"\ncreated = 2026-02-30\n' > "${cfg}" ;;
	esac
	write_env 'STAR_PLAN_MODEL=kimi:k3' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
	before="$(cksum "${cfg}")"
	backup_count="$(find "${KIMI_HOME}" -name 'config.toml.star-bak-*' | wc -l)"
	if (cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null 2>&1); then
		fail "--kimi-pool accepted unsupported ${layout} layout"
	fi
	[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "--kimi-pool changed unsupported ${layout} layout"
	[[ "$(find "${KIMI_HOME}" -name 'config.toml.star-bak-*' | wc -l)" == "${backup_count}" ]] || fail "unsupported layout made a backup"
done
printf '[models.k3]\nmodel = "k3"' > "${cfg}"
write_env 'STAR_PLAN_MODEL=kimi:ghost' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
before="$(cksum "${cfg}")"
(cd "${PROJECT}" && KIMI_CODE_HOME="${KIMI_HOME}" bash execs/configure.sh --kimi-pool >/dev/null 2>&1)
[[ "$(cksum "${cfg}")" == "${before}" ]] || fail "no-op added a final newline"
note "--kimi-pool rejects unsupported layouts unchanged and preserves no-op files without a final newline"

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

write_env 'STAR_PLAN_MODEL=cursor:cursor-only,devin:devin-only,qwen:qwen-only' 'STAR_EXEC_MODEL=' 'STAR_READ_MODEL='
devin_before="$(cat "${PROJECT}/.devin/agents/star-plan.md")"
run_models --harnesses cursor
expect_plain_model "${PROJECT}/.cursor/agents/star-plan.md" cursor-only
expect_model "${PROJECT}/.qwen/agents/star-plan.md" qwen-plan
[[ "$(cat "${PROJECT}/.devin/agents/star-plan.md")" == "${devin_before}" ]] ||
	fail "--harnesses cursor stamped the unselected Devin tree"
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
		grep -Eq '^\*\*Passing a tier model.*§6.*§10\.8.*§13' "${file}" || fail "${file} does not route delegation to shared scope, tier and harness rules"
	done < <(find -L "${ROOT_DIR}/${tree}/skills" -type f -name SKILL.md)
	for skill in star-flow-status star-expt-digest; do
		grep -Eq '^\*\*Tier:\*\* READ\.' "${ROOT_DIR}/${tree}/skills/${skill}/SKILL.md" || fail "${tree} ${skill} lacks its READ Tier line"
	done
done
note "seven trees retain tier-model entries, and flow-status and digest name their READ tier"

# Dispatch policy lives once in the harness adapter; manifests link to it above.
cursor_adapter=$(harness_adapter Cursor)
for rule in \
	'pass the stamped id when this session'\''s selectable `Task` `model` list contains it' \
	'scan that list for a slug of the same model family that already carries the wanted depth' \
	'omit `model` so the file stamp is not overridden' \
	'appends a configured `@<depth>` to the model as `-<depth>`'; do
	grep -Fq "${rule}" <<<"${cursor_adapter}" || fail "Cursor shared adapter lacks dispatch rule: ${rule}"
done
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
UPSTREAM="${TMP_DIR}/upstream with space"
UPDATE_PROJECT="${TMP_DIR}/update-project"
mkdir -p "${UPSTREAM}" "${UPDATE_PROJECT}"
git -C "${ROOT_DIR}" archive HEAD | tar -x -C "${UPSTREAM}"
cp -p "${ROOT_DIR}/execs/update.sh" "${ROOT_DIR}/execs/configure.sh" "${ROOT_DIR}/execs/run.sh" "${UPSTREAM}/execs/"
cp -p "${ROOT_DIR}/execs/scpts/.gitkeep" "${UPSTREAM}/execs/scpts/"
review_scripts=".agents/skills/star-code-reviewer/scripts"
mkdir -p "${UPSTREAM}/${review_scripts}"
cp -p "${ROOT_DIR}/${review_scripts}/review_state.sh" "${UPSTREAM}/${review_scripts}/"
source_skill=".agents/skills/star-flow-status"
mkdir -p "${UPSTREAM}/${source_skill}/scripts" "${UPSTREAM}/${source_skill}/references"
cp -p "${ROOT_DIR}/${source_skill}/scripts/source_state.sh" "${UPSTREAM}/${source_skill}/scripts/"
cp -p "${ROOT_DIR}/${source_skill}/references/source_state.md" "${ROOT_DIR}/${source_skill}/references/source_state_zh.md" "${UPSTREAM}/${source_skill}/references/"
mkdir -p "${UPSTREAM}/.agents/scripts"
cp -p "${ROOT_DIR}/.agents/scripts/"* "${UPSTREAM}/.agents/scripts/"
cp -p "${ROOT_DIR}/.cursor/hooks/star_model_id.sh" "${UPSTREAM}/.cursor/hooks/"
# The archive is HEAD's tree; the working tree's .devin — like execs/ and the
# shared helpers above — is what the Devin cases below install and compare.
cp -Rp "${ROOT_DIR}/.devin/." "${UPSTREAM}/.devin/"
git -C "${UPSTREAM}" init -q -b main
git -C "${UPSTREAM}" add -f .
git -C "${UPSTREAM}" -c core.hooksPath=/dev/null -c user.name=Test \
	-c user.email=test@example.invalid commit -qm fixture
git -C "${UPDATE_PROJECT}" init -q
run_update() {
	(cd "${UPDATE_PROJECT}" && bash "$@") \
		> "${TMP_DIR}/update.log" 2>&1 || { cat "${TMP_DIR}/update.log"; fail "updater integration"; }
}
check_json_runtime() {
    local file output
    for file in json.sh json.awk launch.awk workflow.awk; do
        cmp -s "${ROOT_DIR}/.agents/scripts/$file" "${UPDATE_PROJECT}/.agents/scripts/$file" || fail "update omitted shared JSON helper $file"
    done
    output=$(printf '%s' '{"model_id":"fixture-runtime"}' | bash "${UPDATE_PROJECT}/.cursor/hooks/star_model_id.sh")
    [[ $output == *fixture-runtime* ]] || fail "installed hook cannot load the shared JSON reader"
}
update_expansion_marker="${TMP_DIR}/update-env-expansion-ran"
printf 'STAR_REPOSITORY="$(touch %s)"\n' "${update_expansion_marker}" > "${UPDATE_PROJECT}/.env"
if (cd "${UPDATE_PROJECT}" && bash "${UPSTREAM}/execs/update.sh" --adopt --harnesses cursor) \
		> "${TMP_DIR}/update.log" 2>&1; then
	fail "update.sh accepted shell expansion syntax in .env"
fi
[[ ! -e "${update_expansion_marker}" ]] || fail "update.sh executed shell expansion syntax in .env"
grep -Fq 'shell expansion is unsupported' "${TMP_DIR}/update.log" ||
	fail "update.sh did not explain rejected shell expansion syntax"
printf 'STAR_REPOSITORY="$(touch %s)"\nSTAR_HARNESSES="unterminated\nSTAR_READ_MODEL=cursor:fixture-read\n' \
	"${update_expansion_marker}" > "${UPDATE_PROJECT}/.env"
if ! (cd "${UPDATE_PROJECT}" && STAR_REPOSITORY="file://${UPSTREAM}" \
		bash "${UPSTREAM}/execs/update.sh" --adopt --harnesses cursor) \
		> "${TMP_DIR}/update.log" 2>&1; then
	cat "${TMP_DIR}/update.log"
	fail "updater overrides did not bypass unused malformed .env values"
fi
[[ ! -e "${update_expansion_marker}" ]] || fail "update.sh evaluated an overridden repository value"
check_json_runtime
[[ -f "${UPDATE_PROJECT}/execs/configure.sh" ]] || fail "adopt omitted configure.sh"
[[ -f "${UPDATE_PROJECT}/execs/scpts/.gitkeep" ]] || fail "adopt omitted the empty experiment directory marker"
[[ ! -e "${UPDATE_PROJECT}/execs/scpts/00_exp.sh" ]] || fail "adopt installed the removed example experiment"
adopt_usage="$(cd "${UPDATE_PROJECT}" && bash execs/run.sh)"
[[ "${adopt_usage}" == *'Usage:'* ]] || fail "fresh adoption does not show launcher help without an experiment"
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-read

printf 'STAR_REPOSITORY='"'"'%s'"'"' # local fixture\r\nSTAR_HARNESSES="unterminated\r\nSTAR_READ_MODEL='"'"'cursor:fixture-read'"'"'\r\n' \
	"file://${UPSTREAM}" > "${UPDATE_PROJECT}/.env"
printf '# stale test fixture\n' > "${UPDATE_PROJECT}/execs/configure.sh"
(cd "${UPDATE_PROJECT}" && STAR_HARNESSES=cursor bash execs/update.sh --force) \
	> "${TMP_DIR}/update.log" 2>&1 || { cat "${TMP_DIR}/update.log"; fail "updater environment override"; }
check_json_runtime
cmp -s "${UPSTREAM}/execs/configure.sh" "${UPDATE_PROJECT}/execs/configure.sh" || fail "update omitted configure.sh"
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-read
printf 'STAR_REPOSITORY='"'"'%s'"'"' # local fixture\r\nSTAR_HARNESSES="cursor" # selected tree\r\nSTAR_READ_MODEL='"'"'cursor:fixture-read'"'"'\r\n' \
	"file://${UPSTREAM}" > "${UPDATE_PROJECT}/.env"
rm "${UPDATE_PROJECT}/execs/configure.sh"
rm "${UPDATE_PROJECT}/${review_scripts}/review_state.sh"
rm -rf "${UPDATE_PROJECT}/.agents/scripts"
run_update execs/update.sh --force --skill star-flow-status --harnesses cursor
check_json_runtime
[[ -f "${UPDATE_PROJECT}/execs/configure.sh" ]] || fail "skill update omitted configure.sh"
cmp -s "${ROOT_DIR}/${review_scripts}/review_state.sh" "${UPDATE_PROJECT}/${review_scripts}/review_state.sh" ||
	fail "status-only update omitted its shared review-validity helper"
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-read
rm "${UPDATE_PROJECT}/${review_scripts}/review_state.sh"
run_update execs/update.sh --force --skill star-plan-executor --harnesses cursor
cmp -s "${ROOT_DIR}/${review_scripts}/review_state.sh" "${UPDATE_PROJECT}/${review_scripts}/review_state.sh" ||
	fail "executor-only update omitted its shared review-validity helper"
rm "${UPDATE_PROJECT}/${source_skill}/scripts/source_state.sh" "${UPDATE_PROJECT}/${source_skill}/references/source_state.md"
run_update execs/update.sh --force --skill star-expt-analyst --harnesses cursor
cmp -s "${ROOT_DIR}/${source_skill}/scripts/source_state.sh" "${UPDATE_PROJECT}/${source_skill}/scripts/source_state.sh" ||
	fail "analyst-only update omitted its shared source-validity helper"
cmp -s "${ROOT_DIR}/${source_skill}/references/source_state.md" "${UPDATE_PROJECT}/${source_skill}/references/source_state.md" ||
	fail "analyst-only update omitted its source-validity contract"
note "the updater honors overrides, installs shared validity helpers, and reapplies model settings"

# A stamped project previews as current, and neither an uncommitted stamp nor a
# project-own untracked file blocks the next update.
printf 'STAR_REPOSITORY='"'"'%s'"'"'\n  export STAR_HARNESSES=cursor\nSTAR_READ_MODEL='"'"'cursor:fixture-read'"'"'\n' \
	"file://${UPSTREAM}" > "${UPDATE_PROJECT}/.env"
run_update execs/update.sh --force
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-read
git -C "${UPDATE_PROJECT}" add -A
git -C "${UPDATE_PROJECT}" -c core.hooksPath=/dev/null -c user.name=Test -c user.email=test@example.invalid commit -qm stamped
if ! (cd "${UPDATE_PROJECT}" && bash execs/update.sh --diff) > "${TMP_DIR}/update.log" 2>&1; then
	cat "${TMP_DIR}/update.log"; fail "update.sh --diff reports a stamped project as changed"
fi
! grep -q '\.claude/' "${TMP_DIR}/update.log" || fail "an exported STAR_HARNESSES line was ignored"
printf 'STAR_REPOSITORY='"'"'%s'"'"'\nSTAR_HARNESSES=cursor\nSTAR_READ_MODEL='"'"'cursor:fixture-other'"'"'\n' \
	"file://${UPSTREAM}" > "${UPDATE_PROJECT}/.env"
(cd "${UPDATE_PROJECT}" && bash execs/configure.sh) > "${TMP_DIR}/update.log" 2>&1 || fail "configure.sh restamp"
mkdir -p "${UPDATE_PROJECT}/.cursor/skills/project-own"
printf 'own\n' > "${UPDATE_PROJECT}/.cursor/skills/project-own/SKILL.md"
run_update execs/update.sh
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-other
[[ -f "${UPDATE_PROJECT}/.cursor/skills/project-own/SKILL.md" ]] || fail "update removed a project-own skill"
note "a stamped project previews as current, and stamps or own files do not block an update"

# A malformed tier key is refused before anything is fetched or overwritten.
printf 'STAR_REPOSITORY='"'"'%s'"'"'\nSTAR_HARNESSES=cursor\nSTAR_PLAN_MODEL="$(touch %s)"\n' \
	"file://${UPSTREAM}" "${update_expansion_marker}" > "${UPDATE_PROJECT}/.env"
if (cd "${UPDATE_PROJECT}" && bash execs/update.sh --force) > "${TMP_DIR}/update.log" 2>&1; then
	fail "update.sh accepted a malformed STAR_PLAN_MODEL"
fi
grep -q 'Invalid STAR_PLAN_MODEL' "${TMP_DIR}/update.log" || fail "malformed tier key diagnostic"
! grep -q 'Fetching' "${TMP_DIR}/update.log" || fail "update.sh fetched before validating the tier keys"
expect_plain_model "${UPDATE_PROJECT}/.cursor/agents/star-read.md" fixture-other
note "a malformed tier key is refused before the fetch"

# --adopt never runs a project's own execs/configure.sh.
ADOPT_PROJECT="${TMP_DIR}/adopt-project"
adopt_marker="${TMP_DIR}/project-configure-ran"
mkdir -p "${ADOPT_PROJECT}/execs"
git -C "${ADOPT_PROJECT}" init -q
printf '#!/usr/bin/env bash\ntouch %q\n' "${adopt_marker}" > "${ADOPT_PROJECT}/execs/configure.sh"
(cd "${ADOPT_PROJECT}" && STAR_REPOSITORY="file://${UPSTREAM}" bash "${UPSTREAM}/execs/update.sh" --adopt --harnesses cursor) \
	> "${TMP_DIR}/update.log" 2>&1 || { cat "${TMP_DIR}/update.log"; fail "adopt with a project configure.sh"; }
[[ ! -e "${adopt_marker}" ]] || fail "--adopt ran the project's own execs/configure.sh"
grep -q "execs/configure.sh is the project's own" "${TMP_DIR}/update.log" || fail "--adopt did not report skipped stamping"
note "--adopt never runs a project's own configure.sh"

# Stamping refuses a manifest whose frontmatter never closes and leaves it intact.
printf 'STAR_HARNESSES=cursor\nSTAR_READ_MODEL=cursor:fixture-third\n' > "${UPDATE_PROJECT}/.env"
printf -- '---\nname: star-read\nmodel: fixture-other\n--- \nBody line.\n' > "${UPDATE_PROJECT}/.cursor/agents/star-read.md"
before=$(cat "${UPDATE_PROJECT}/.cursor/agents/star-read.md")
if (cd "${UPDATE_PROJECT}" && bash execs/configure.sh) > "${TMP_DIR}/update.log" 2>&1; then
	fail "configure.sh stamped a manifest with unclosed frontmatter"
fi
[[ "$(cat "${UPDATE_PROJECT}/.cursor/agents/star-read.md")" == "${before}" ]] || fail "configure.sh truncated an unclosed manifest"
note "stamping refuses unclosed frontmatter without truncating"

# A Devin adoption installs the whole .devin tree — the five registered hooks
# plus the sourced level helper, nine user-only wrappers, five dispatch
# profiles and configs that parse — and no sibling harness tree. The two
# read-only profiles take the same stamp their tier's named profile does.
DEVIN_PROJECT="${TMP_DIR}/devin-project"
mkdir -p "${DEVIN_PROJECT}"
git -C "${DEVIN_PROJECT}" init -q
printf 'STAR_REPOSITORY='"'"'file://%s'"'"'\nSTAR_HARNESSES=devin\nSTAR_PLAN_MODEL=devin:devin-plan@high\nSTAR_READ_MODEL=devin:devin-read\n' \
	"${UPSTREAM}" > "${DEVIN_PROJECT}/.env"
(cd "${DEVIN_PROJECT}" && bash "${UPSTREAM}/execs/update.sh" --adopt --harnesses devin) \
	> "${TMP_DIR}/update.log" 2>&1 || { cat "${TMP_DIR}/update.log"; fail "devin adopt"; }
for hook in star_model_id star_memory star_commit_guard star_involve_gate star_bash_gate star_involve_level; do
	[[ -f "${DEVIN_PROJECT}/.devin/hooks/${hook}.sh" ]] || fail "devin adopt omitted .devin/hooks/${hook}.sh"
done
[[ "$(find "${DEVIN_PROJECT}/.devin/skills" -name SKILL.md | wc -l | tr -d ' ')" == 9 ]] ||
	fail "devin adopt did not install the nine user-only wrappers"
for profile in star-plan star-exec star-read star-plan-blind star-read-local; do
	[[ -f "${DEVIN_PROJECT}/.devin/agents/${profile}.md" ]] || fail "devin adopt omitted .devin/agents/${profile}.md"
done
for tree in .claude .codex .cursor .dsh .kimi-code .pi .qwen .agy; do
	[[ ! -e "${DEVIN_PROJECT}/${tree}" ]] || fail "devin adopt installed sibling tree ${tree}"
done
expect_model "${DEVIN_PROJECT}/.devin/agents/star-plan.md" devin-plan-high
expect_model "${DEVIN_PROJECT}/.devin/agents/star-plan-blind.md" devin-plan-high
expect_model "${DEVIN_PROJECT}/.devin/agents/star-read-local.md" devin-read
(cd "${DEVIN_PROJECT}" && source .agents/scripts/json.sh && \
	star_json_eval 'x=1' < .devin/hooks.v1.json && star_json_eval 'x=1' < .devin/config.json) \
	>/dev/null || fail "devin adopt installed a config that does not parse"
note "devin adopt installs the .devin tree, no sibling harnesses, and stamps both read-only profiles"

# A kept hooks.v1.json that drifted — unanchored matcher, old timeout, no shell
# gate — is warned about by script name and preserved byte for byte. Drift is
# generated from the canonical file through the shipped JSON library so the
# kept file stays valid JSON throughout.
git -C "${DEVIN_PROJECT}" add -A
git -C "${DEVIN_PROJECT}" -c core.hooksPath=/dev/null -c user.name=Test \
	-c user.email=test@example.invalid commit -qm devin
kept="${DEVIN_PROJECT}/.devin/hooks.v1.json"
(cd "${DEVIN_PROJECT}" && source .agents/scripts/json.sh && star_json_eval '
	x=at(r,"PreToolUse[0]"); put(x,"matcher",string("exec"))
	h=get(x,"hooks"); nh=array()
	for(i=0;i<size(h);i++) {
		hk=get(h,i)
		if(index(field(hk,"command"),"star_bash_gate")) continue
		put(hk,"timeout",number(10)); add(nh,hk)
	}
	put(x,"hooks",nh); print json(r)' < .devin/hooks.v1.json > .devin/hooks.v1.json.drifted) ||
	fail "could not build the drifted hook config"
mv "${kept}.drifted" "${kept}"
drifted_sum="$(cksum "${kept}")"
(cd "${DEVIN_PROJECT}" && bash execs/update.sh) > "${TMP_DIR}/update.log" 2>&1 ||
	{ cat "${TMP_DIR}/update.log"; fail "devin update over a drifted kept config"; }
grep -q 'outdated or missing STAR hook registrations' "${TMP_DIR}/update.log" ||
	fail "a drifted kept hooks.v1.json drew no warning"
for script in star_bash_gate.sh star_commit_guard.sh; do
	grep -q "${script}" "${TMP_DIR}/update.log" || fail "warning omitted ${script}"
done
[[ "$(cksum "${kept}")" == "${drifted_sum}" ]] || fail "update overwrote the kept hooks.v1.json"
note "a drifted kept hooks.v1.json warns by script name and is preserved"

# A kept file that differs only in formatting, or adds a registration of the
# project's own, warns nothing: neither is a missing or outdated STAR entry.
# Built from upstream's canonical file, since the kept one still holds drift.
(cd "${DEVIN_PROJECT}" && source .agents/scripts/json.sh && star_json_eval '
	x=at(r,"SessionStart[0]"); h=get(x,"hooks")
	hk=object(); put(hk,"type",string("command"))
	put(hk,"command",string("bash .devin/hooks/star_project.sh")); put(hk,"timeout",number(5))
	add(h,hk); print json(r)' < "${UPSTREAM}/.devin/hooks.v1.json" > .devin/hooks.v1.json.custom) ||
	fail "could not build the custom kept config"
mv "${kept}.custom" "${kept}"
custom_sum="$(cksum "${kept}")"
(cd "${DEVIN_PROJECT}" && bash execs/update.sh) > "${TMP_DIR}/update.log" 2>&1 ||
	{ cat "${TMP_DIR}/update.log"; fail "devin update over a custom kept config"; }
! grep -q 'outdated or missing STAR hook registrations' "${TMP_DIR}/update.log" ||
	fail "formatting and a custom registration drew a drift warning"
[[ "$(cksum "${kept}")" == "${custom_sum}" ]] || fail "update overwrote the custom kept config"
note "a custom or reformatted kept hooks.v1.json warns nothing and is preserved"

# Drift inside a canonical command — extra arguments on the same script — is
# flagged for that script alone.
(cd "${DEVIN_PROJECT}" && source .agents/scripts/json.sh && star_json_eval '
	x=at(r,"SessionStart[0]"); h=get(x,"hooks")
	for(i=0;i<size(h);i++) {
		hk=get(h,i)
		if(index(field(hk,"command"),"star_memory"))
			put(hk,"command",string(field(hk,"command") " --changed"))
	}
	print json(r)' < "${UPSTREAM}/.devin/hooks.v1.json" > .devin/hooks.v1.json.cmdchange) ||
	fail "could not build the command-drifted kept config"
mv "${kept}.cmdchange" "${kept}"
cmdchange_sum="$(cksum "${kept}")"
(cd "${DEVIN_PROJECT}" && bash execs/update.sh) > "${TMP_DIR}/update.log" 2>&1 ||
	{ cat "${TMP_DIR}/update.log"; fail "devin update over a command-drifted kept config"; }
grep -q 'star_memory.sh' "${TMP_DIR}/update.log" || fail "a changed canonical command drew no per-script warning"
if grep -q 'star_bash_gate.sh\|star_commit_guard.sh' "${TMP_DIR}/update.log"; then
	fail "an unchanged registration was named alongside the changed command"
fi
[[ "$(cksum "${kept}")" == "${cmdchange_sum}" ]] || fail "update overwrote the command-drifted kept config"
note "a changed canonical command warns on that script only and is preserved"
