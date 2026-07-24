#!/usr/bin/env bash
# STAR upstream consistency check.
#
# Guards the invariants the four per-tool skill trees (.agents/.claude/.cursor/
# .kimi-code) and the shared docs are supposed to keep while being maintained by
# hand. Run from anywhere inside the repo: bash .github/scripts/check_consistency.sh
# Exits non-zero if any check fails. Upstream-maintainer tooling only — this
# directory is not synced to downstream projects by execs/update.sh.
set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "${ROOT_DIR}"

SKILL_ROOTS=(.agents/skills .claude/skills .cursor/skills .kimi-code/skills)
FAILURES=0

fail() { printf 'FAIL  %s\n' "$*"; FAILURES=$(( FAILURES + 1 )); }
note() { printf 'ok    %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

list_skills() { # $1 = skill root
    find "$1" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort
}

frontmatter_has_line() { # $1 = file, $2 = exact line expected inside the leading --- block
    awk -v want="$2" 'NR == 1 { next } /^---[ \t]*$/ { exit } $0 == want { found = 1; exit } END { exit !found }' "$1"
}

# 1. The four roots carry the same, non-empty set of skill directories.
section "Skill directory sets"
SKILLS="$(list_skills "${SKILL_ROOTS[0]}")"
if [[ -z "${SKILLS}" ]]; then
    fail "${SKILL_ROOTS[0]} contains no skill directories"
else
    for root in "${SKILL_ROOTS[@]:1}"; do
        if [[ "$(list_skills "${root}")" != "${SKILLS}" ]]; then
            fail "${root} skill set differs from ${SKILL_ROOTS[0]}:"
            diff <(printf '%s\n' "${SKILLS}") <(list_skills "${root}") | sed 's/^/      /'
        fi
    done
    note "$(printf '%s\n' "${SKILLS}" | wc -l | tr -d ' ') skills, same set in all four roots"
fi

# 2. Frontmatter name matches the directory name in every tree.
section "Frontmatter name = directory name"
name_errors=0
for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        manifest="${root}/${skill}/SKILL.md"
        if [[ ! -f "${manifest}" ]]; then
            fail "${manifest} is missing"
            name_errors=1
            continue
        fi
        if ! frontmatter_has_line "${manifest}" "name: ${skill}"; then
            fail "${manifest}: frontmatter name does not match directory '${skill}'"
            name_errors=1
        fi
    done < <(printf '%s\n' "${SKILLS}")
done
(( name_errors == 0 )) && note "every SKILL.md name matches its directory"

# 3. Per-skill file inventory is identical across the four trees, apart from the
#    Codex-only agents/ manifest directory.
section "File inventory parity (ignoring .agents agents/ manifests)"
parity_errors=0
while IFS= read -r skill; do
    baseline="$(cd "${SKILL_ROOTS[0]}/${skill}" && find . -type f ! -path './agents/*' | sort)"
    for root in "${SKILL_ROOTS[@]:1}"; do
        listing="$(cd "${root}/${skill}" && find . -type f | sort)"
        if [[ "${listing}" != "${baseline}" ]]; then
            fail "${root}/${skill} file set differs from ${SKILL_ROOTS[0]}/${skill}:"
            diff <(printf '%s\n' "${baseline}") <(printf '%s\n' "${listing}") | sed 's/^/      /'
            parity_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( parity_errors == 0 )) && note "file sets match across all four trees"

# 4. Implicit-invocation guards: Codex via agents/openai.yaml, the other three
#    via disable-model-invocation frontmatter.
section "User-invoked-only guards"
guard_errors=0
while IFS= read -r skill; do
    manifest=".agents/skills/${skill}/agents/openai.yaml"
    if [[ ! -f "${manifest}" ]]; then
        fail "${manifest} is missing"
        guard_errors=1
    elif ! grep -q 'allow_implicit_invocation: false' "${manifest}"; then
        fail "${manifest}: allow_implicit_invocation: false not found"
        guard_errors=1
    fi
    for root in .claude/skills .cursor/skills .kimi-code/skills; do
        if ! frontmatter_has_line "${root}/${skill}/SKILL.md" "disable-model-invocation: true"; then
            fail "${root}/${skill}/SKILL.md: disable-model-invocation: true not in frontmatter"
            guard_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( guard_errors == 0 )) && note "all skills are guarded against model auto-invocation"

# 5. Bilingual twins: every skill .md has its _zh.md counterpart and vice versa.
# Deliberately English-only files are exempt: star-code-architect's SKILL_zh.md
# states upstream_template.md has no _zh version (UPSTREAM.md is always English).
section "Bilingual twins in skill trees"
twin_errors=0
while IFS= read -r f; do
    if [[ "${f}" == */star-code-architect/assets/upstream_template.md ]]; then
        continue
    fi
    if [[ "${f}" == *_zh.md ]]; then
        [[ -f "${f%_zh.md}.md" ]] || { fail "${f} has no English counterpart"; twin_errors=1; }
    else
        [[ -f "${f%.md}_zh.md" ]] || { fail "${f} has no _zh.md counterpart"; twin_errors=1; }
    fi
done < <(find "${SKILL_ROOTS[@]}" -type f -name '*.md')
(( twin_errors == 0 )) && note "every skill .md file has its bilingual twin"

# 6. Every SKILL.md defers to the shared conventions document.
section "Shared-conventions reference"
conv_errors=0
for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        grep -q 'research-workflow-conventions\.md' "${root}/${skill}/SKILL.md" || {
            fail "${root}/${skill}/SKILL.md does not reference research-workflow-conventions.md"
            conv_errors=1
        }
    done < <(printf '%s\n' "${SKILLS}")
done
(( conv_errors == 0 )) && note "every SKILL.md references the conventions document"

# 7. Invocation tokens are tree-appropriate: $star-* in .agents, /star-* in
#    .claude and .cursor, /skill:star-* in .kimi-code.
section "Invocation-token hygiene"
token_errors=0
check_absent() { # $1 = tree, $2 = literal token
    local hits
    hits="$(grep -RnF -- "$2" "$1" || true)"
    if [[ -n "${hits}" ]]; then
        fail "$1 contains foreign invocation token '$2':"
        printf '%s\n' "${hits}" | sed 's/^/      /'
        token_errors=1
    fi
}
while IFS= read -r skill; do
    check_absent .agents/skills "/${skill}"
    check_absent .agents/skills "skill:${skill}"
    for root in .claude/skills .cursor/skills; do
        check_absent "${root}" "\$${skill}"
        check_absent "${root}" "skill:${skill}"
    done
    check_absent .kimi-code/skills "\$${skill}"
    # Bare /star-* is foreign in the Kimi tree; /skill:star-* does not contain it.
    check_absent .kimi-code/skills "/${skill}"
done < <(printf '%s\n' "${SKILLS}")
(( token_errors == 0 )) && note "invocation tokens are consistent per tree"

# 8. Workflow docs ship as en/zh pairs.
section "Bilingual twins in docs/mds/star-workflow"
doc_errors=0
while IFS= read -r f; do
    if [[ "${f}" == *.zh-CN.md ]]; then
        [[ -f "${f%.zh-CN.md}.md" ]] || { fail "${f} has no English counterpart"; doc_errors=1; }
    else
        [[ -f "${f%.md}.zh-CN.md" ]] || { fail "${f} has no .zh-CN.md counterpart"; doc_errors=1; }
    fi
done < <(find docs/mds/star-workflow -type f -name '*.md')
(( doc_errors == 0 )) && note "workflow docs are paired en/zh"

# 9. The always-on Cursor rule body stays in sync with AGENTS.md.
#    AGENTS.md: title + blank line, then the shared body.
#    agent-instructions.mdc: 4 frontmatter lines + blank line, then the same body.
section "Cursor rule mirrors AGENTS.md"
if diff <(tail -n +3 AGENTS.md) <(tail -n +6 .cursor/rules/agent-instructions.mdc) > /dev/null; then
    note ".cursor/rules/agent-instructions.mdc matches the AGENTS.md body"
else
    fail ".cursor/rules/agent-instructions.mdc has drifted from AGENTS.md:"
    diff <(tail -n +3 AGENTS.md) <(tail -n +6 .cursor/rules/agent-instructions.mdc) | sed 's/^/      /'
fi

# 10. Model-id provenance hooks exist, are executable, and are registered.
section "Provenance hooks"
hook_errors=0
for f in .claude/hooks/star_model_id.sh .codex/hooks/star_model_id.sh \
         .cursor/hooks/star_model_id.sh .kimi-code/hooks/star_model_id.sh \
         .kimi-code/hooks/install.sh; do
    [[ -x "${f}" ]] || { fail "${f} is missing or not executable"; hook_errors=1; }
done
for f in .claude/settings.json .codex/hooks.json .cursor/hooks.json .kimi-code/hooks.example.toml; do
    [[ -f "${f}" ]] || { fail "${f} is missing"; hook_errors=1; }
done
(( hook_errors == 0 )) && note "hooks present, executable, and registered"

printf '\n'
if (( FAILURES > 0 )); then
    printf '%d check(s) failed.\n' "${FAILURES}"
    exit 1
fi
printf 'All consistency checks passed.\n'
