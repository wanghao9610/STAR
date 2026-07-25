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

# The rewrite that retokenizes a ported skill targets "/star-*", and the one
# repo path carrying that substring is docs/mds/star-workflow/. A hand-run
# rewrite once turned its separator into "docs/mds$star-workflow/" in .agents,
# and the checks above passed it: the token is not foreign to that tree, and
# check 6 matches the filename, not the directory. Every "docs/mds" in the
# skill trees must still be followed by "/star-workflow/".
mangled_paths="$(grep -rn 'docs/mds[^/]' "${SKILL_ROOTS[@]}" || true)"
if [[ -n "${mangled_paths}" ]]; then
    fail "docs/mds/ path separator damaged (token rewrite hit a directory name):"
    printf '%s\n' "${mangled_paths}" | sed 's/^/      /'
    token_errors=1
fi

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

# 11. Heading structure matches across the three trees that share it.
#     Checks 1-3 compare file *sets*; nothing compared what is inside them, so a
#     section could be dropped from one tree, or reordered, and every check passed.
#     This compares the heading sequence of each file.
#
#     Normalization: a heading is truncated at its first "(" or "（" and stripped of
#     backticks, so harness vocabulary inside a heading is free to differ —
#     "Step 4: Approval gate (`ExitPlanMode`)" and "Step 4：审批门（退出 Plan 模式）"
#     compare equal to their siblings. What remains must match exactly.
#
#     .agents is deliberately excluded: it is an adapted variant, not a copy (7-step
#     executor against the others' 9), and its headings differ in 23 files. That is a
#     known gap — see .github/CONTRIBUTING.md, "What the checks do not catch".
section "Heading structure (.claude / .cursor / .kimi-code)"
STRUCT_ROOTS=(.claude/skills .cursor/skills .kimi-code/skills)

norm_headings() { # $1 = file; prints one normalized heading per line
    awk '
        /^#/ {
            n = 0
            while (substr($0, n + 1, 1) == "#") n++
            if (n < 2 || n > 4) next
            if (substr($0, n + 1, 1) != " ") next
            line = $0
            p = index(line, "(")
            q = index(line, "（")
            if (q > 0 && (p == 0 || q < p)) p = q
            if (p > 0) line = substr(line, 1, p - 1)
            gsub(/`/, "", line)
            gsub(/[ \t]+/, " ", line)
            sub(/^ +/, "", line)
            sub(/ +$/, "", line)
            print tolower(line)
        }
    ' "$1"
}

struct_errors=0
struct_files=0
while IFS= read -r rel; do
    baseline_file="${STRUCT_ROOTS[0]}/${rel}"
    struct_files=$(( struct_files + 1 ))
    for root in "${STRUCT_ROOTS[@]:1}"; do
        other="${root}/${rel}"
        [[ -f "${other}" ]] || continue   # inventory parity is check 3's job
        if ! diff -q <(norm_headings "${baseline_file}") <(norm_headings "${other}") > /dev/null; then
            fail "${other}: heading structure differs from ${baseline_file}:"
            diff <(norm_headings "${baseline_file}") <(norm_headings "${other}") | sed 's/^/      /'
            struct_errors=1
        fi
    done
done < <(cd "${STRUCT_ROOTS[0]}" && find . -type f -name '*.md' | sed 's|^\./||' | sort)
(( struct_errors == 0 )) && note "heading structure matches across the three trees (${struct_files} files)"

# 12. Kimi frontmatter descriptions stay inside their length budget.
#     Every .kimi-code description is at or under 1041 bytes while the other
#     trees run to 1989, and the short ones end in complete sentences — they were
#     condensed on purpose, not truncated. The budget was undocumented, so a
#     later edit could silently exceed it. See .github/CONTRIBUTING.md.
#     SKILL.md only: it is the registered manifest whose description the platform
#     surfaces. SKILL_zh.md is loaded as a resource and runs past 1300 chars.
section "Kimi description budget (<= ${KIMI_DESC_MAX:=1050} bytes)"
desc_errors=0
while IFS= read -r manifest; do
    len="$(awk '
        NR == 1 && /^---[ \t]*$/ { fm = 1; next }
        fm && /^---[ \t]*$/ { exit }
        fm && /^description:/ { grab = 1; sub(/^description:[ \t]*/, ""); }
        fm && grab && /^[A-Za-z_-]+:/ && !/^description:/ { exit }
        grab { gsub(/^[ \t]+|[ \t]+$/, ""); if (length($0)) body = body (length(body) ? " " : "") $0 }
        END { print length(body) }
    ' "${manifest}")"
    if (( len > KIMI_DESC_MAX )); then
        fail "${manifest}: description is ${len} bytes, over the ${KIMI_DESC_MAX}-byte Kimi budget"
        desc_errors=1
    fi
done < <(find .kimi-code/skills -name 'SKILL.md' | sort)
(( desc_errors == 0 )) && note "all Kimi descriptions within ${KIMI_DESC_MAX} bytes"

# 13. Skill helper scripts are byte-identical across the four trees, and executable.
#     The .md files are adapted per tree — invocation tokens, harness vocabulary —
#     but a script reads project files and names no harness, so it has nothing to
#     adapt. A copy that has drifted is a bug, not a variant. Check 3 compares file
#     sets only, so without this a script could differ in every tree and pass.
section "Skill script parity"
script_errors=0
while IFS= read -r rel; do
    baseline="${SKILL_ROOTS[0]}/${rel}"
    [[ -x "${baseline}" ]] || { fail "${baseline} is not executable"; script_errors=1; }
    for root in "${SKILL_ROOTS[@]:1}"; do
        other="${root}/${rel}"
        [[ -f "${other}" ]] || continue   # inventory parity is check 3's job
        [[ -x "${other}" ]] || { fail "${other} is not executable"; script_errors=1; }
        if ! cmp -s "${baseline}" "${other}"; then
            fail "${other} differs from ${baseline}; skill scripts must be byte-identical"
            script_errors=1
        fi
    done
done < <(cd "${SKILL_ROOTS[0]}" && find . -type f -name '*.sh' | sed 's|^\./||' | sort)
(( script_errors == 0 )) && note "skill scripts are byte-identical and executable in all four trees"

printf '\n'
if (( FAILURES > 0 )); then
    printf '%d check(s) failed.\n' "${FAILURES}"
    exit 1
fi
printf 'All consistency checks passed.\n'
