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

# Same-named scripts are one shared file, not per-skill forks. A skill cannot
# reference another skill's copy — the path would carry a foreign invocation
# token and `update.sh --skill` would not guarantee the other skill is even
# installed — so a shared collector is duplicated into each consumer instead,
# and this is what keeps the duplicates honest.
while IFS= read -r base; do
    first=""
    while IFS= read -r path; do
        if [[ -z "${first}" ]]; then
            first="${path}"
        elif ! cmp -s "${first}" "${path}"; then
            fail "${path} differs from ${first}; same-named skill scripts must be one shared file"
            script_errors=1
        fi
    done < <(find "${SKILL_ROOTS[@]}" -type f -name "${base}" | sort)
done < <(find "${SKILL_ROOTS[@]}" -type f -name '*.sh' -exec basename {} \; | sort -u)

(( script_errors == 0 )) && note "skill scripts are byte-identical and executable in all four trees"

# 14. Top-level section parity between .agents and .claude manifests.
#     Check 11 excludes .agents on purpose: it is an adapted variant, not a copy,
#     and its ### sequence and reference-file headings carry their own vocabulary
#     (7-step executor against the others' 9; "contract per area" for "contract
#     per surveyor"). But a SKILL.md's ## sections are its shape, not its wording
#     — Role, Core Principles, Workflow, State & File Rules, Dialogue Discipline —
#     and those are shared. Nothing compared them, and the gap already cost
#     .agents its "## Dialogue Discipline" in 7 of 15 manifests silently
#     (restored in 042ece5). Manifests only, and the SET rather than the sequence,
#     so ordering and every adaptation below ## stay free.
section "Manifest section parity (.agents vs .claude)"
norm_sections() { # $1 = file; prints the file's normalized ## headings, sorted unique
    awk '
        /^## / {
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
    ' "$1" | sort -u
}

section_errors=0
section_files=0
while IFS= read -r skill; do
    for manifest in SKILL.md SKILL_zh.md; do
        baseline=".claude/skills/${skill}/${manifest}"
        other=".agents/skills/${skill}/${manifest}"
        [[ -f "${baseline}" && -f "${other}" ]] || continue   # checks 3 and 5 own missing files
        section_files=$(( section_files + 1 ))
        if ! diff -q <(norm_sections "${baseline}") <(norm_sections "${other}") > /dev/null; then
            fail "${other}: ## sections differ from ${baseline}:"
            diff <(norm_sections "${baseline}") <(norm_sections "${other}") | sed 's/^/      /'
            section_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( section_errors == 0 )) && note ".agents manifests carry the same ## sections as .claude (${section_files} files)"

# 15. The shared scripts parse, and every string they match byte-exactly still has
#     a producer. Check 13 compares the four copies against each other, so a script
#     that is broken or silently mismatched the same way in all four passes it: the
#     copies agree, and agreement is all it asks. Two failure modes get through.
#     A syntax error edited into all four at once — which is how these files are
#     normally edited — stays byte-identical and executable. And a scanner matches
#     on strings some *other* skill's template writes, with nothing linking the two:
#     reword the producer and the scan does not error, it just reports zero, and a
#     rule downstream quietly stops firing. That is what happened to `【待定】`
#     (fixed in 9c25079): star-plan-decomposer wrote it into every Chinese sub-plan,
#     scan.sh counted only `[TBD]`, and the "too coarse to run" rule never fired on
#     a Chinese project from ab4246c until now, with CI green throughout.
#
#     Each row below is a string a shared script matches on, and the files that must
#     still contain it. Both directions are checked, because a row that outlives its
#     scanner is as misleading as a producer that outlives its row. Deliberately
#     absent: `Strategy signal` / `战略信号`, the pre-rename labels body_index still
#     accepts so EXEC_LOG files already on disk keep indexing — they have no producer
#     by design and must not be given one.
section "Grepped literals have a producer"
LITERAL_REGISTRY=(
    "Sub-plans|star-plan-decomposer/SKILL.md"
    "Revision History|star-plan-reviser/references/revision_rules.md"
    "Plan-level finding|star-plan-executor/assets/exec_log_template.md"
    "方向性信号|star-plan-executor/assets/exec_log_template_zh.md"
    "[TBD]|star-plan-decomposer/SKILL.md"
    "【待定】|star-plan-decomposer/SKILL.md"
    "model_trail:|star-plan-coach/assets/plan_template.md"
    "model_id|star-code-reviewer/assets/code_review_template.md,star-plan-reviser/assets/review_report_template.md,star-refs-reviewer/assets/refs_index_template.md"
)

literal_errors=0
SHARED_SCRIPTS=()
while IFS= read -r path; do
    SHARED_SCRIPTS+=("${path}")
done < <(find "${SKILL_ROOTS[@]}" -type f -name '*.sh' | sort)

if (( ${#SHARED_SCRIPTS[@]} == 0 )); then
    fail "no shared skill scripts found; the literal registry has nothing to check against"
    literal_errors=1
fi

for script in "${SHARED_SCRIPTS[@]:-}"; do
    [[ -n "${script}" ]] || continue
    if ! parse_err="$(bash -n "${script}" 2>&1)"; then
        fail "${script} does not parse:"
        printf '%s\n' "${parse_err}" | sed 's/^/      /'
        literal_errors=1
    fi
done

for row in "${LITERAL_REGISTRY[@]}"; do
    (( ${#SHARED_SCRIPTS[@]} > 0 )) || break
    literal="${row%%|*}"
    producers="${row#*|}"

    if ! grep -qF -- "${literal}" "${SHARED_SCRIPTS[@]}"; then
        fail "no shared script matches on '${literal}' any more; drop the registry row or restore the match"
        literal_errors=1
    fi

    for root in "${SKILL_ROOTS[@]}"; do
        found=0
        IFS=',' read -r -a paths <<< "${producers}"
        for rel in "${paths[@]}"; do
            producer="${root}/${rel}"
            [[ -f "${producer}" ]] || continue
            if grep -qF -- "${literal}" "${producer}"; then found=1; break; fi
        done
        if (( found == 0 )); then
            fail "'${literal}' is matched byte-exactly by a shared script but no longer produced in ${root} (expected in: ${producers})"
            literal_errors=1
        fi
    done
done

(( literal_errors == 0 )) && note "${#SHARED_SCRIPTS[@]} shared scripts parse; ${#LITERAL_REGISTRY[@]} grepped literals still produced in all four trees"

# 16. Numbered citations of AGENTS.md sections still name the section they claim.
#     Around 130 places cite AGENTS.md by number, so renumbering one section
#     invalidates every citation of the ones after it. That has already happened
#     twice: layout and runtime became §8 and §9, while star-code-reviewer and
#     star-expt-analyst went on citing §5 and §6 with CI green, because nothing
#     here looked at citations at all.
#
#     Two guards, since a bare "(AGENTS.md §3)" carries no label and cannot be
#     verified from its own text:
#       16a pins the heading map, so a renumber or retitle fails here first;
#       16b re-checks every citation that does carry a label — "§8 layout",
#           "布局符合度（§8）" — against the live map.
#     Lines naming the conventions document are skipped: it carries its own
#     §1-§9, including its own "project layout".
section "AGENTS.md section citations"

AGENTS_SECTIONS=(
    "1|Think Before Coding"
    "2|Simplicity First"
    "3|Surgical Changes"
    "4|Goal-Driven Execution"
    "5|Research Workflow"
    "6|Reply Language"
    "7|Reply Wording"
    "8|Project Layout"
    "9|Project Runtime"
    "10|Verification"
)

# title|regex — every match must contain exactly one §n, and that n must be the
# number AGENTS.md currently gives that title.
CITATION_LABELS=(
    "Project Layout|§[0-9]+ layout"
    "Project Layout|§[0-9]+ 布局"
    "Project Layout|[Ll]ayout (conformance|rules) \(((AGENTS|CLAUDE)\.md )?§[0-9]+\)"
    "Project Layout|布局(符合度|规则)（((AGENTS|CLAUDE)\.md )?§[0-9]+）"
    "Project Runtime|§[0-9]+ runtime"
    "Project Runtime|§[0-9]+ 运行时"
    "Project Runtime|§[0-9]+: no hardcoded"
    "Project Runtime|§[0-9]+：禁止硬编码"
    "Simplicity First|§[0-9]+ simplicity"
    "Simplicity First|§[0-9]+ 简洁"
    "Surgical Changes|§[0-9]+ surgical"
    "Surgical Changes|§[0-9]+ 外科手术"
    "Goal-Driven Execution|Goal-Driven Execution ?(\(|（)((AGENTS|CLAUDE)\.md )?§[0-9]+"
    "Verification|Verification ?(\(|（)§[0-9]+"
)

CITATION_SCAN=("${SKILL_ROOTS[@]}" docs/mds/star-workflow)
cite_errors=0
cite_checked=0

expected_map="$(printf '%s\n' "${AGENTS_SECTIONS[@]}" | sed 's/|/. /')"
actual_map="$(sed -nE 's/^## ([0-9]+\. .+)$/\1/p' AGENTS.md)"
if [[ "${expected_map}" != "${actual_map}" ]]; then
    fail "AGENTS.md section numbering or titles changed; citations elsewhere are numbered against the old map. Re-audit them, then update AGENTS_SECTIONS in this script:"
    diff <(printf '%s\n' "${expected_map}") <(printf '%s\n' "${actual_map}") | sed 's/^/      /'
    cite_errors=1
fi

for rule in "${CITATION_LABELS[@]}"; do
    title="${rule%%|*}"
    pattern="${rule#*|}"
    want="$(sed -nE "s/^## ([0-9]+)\. ${title}\$/\1/p" AGENTS.md | head -n 1)"
    if [[ -z "${want}" ]]; then
        fail "citation rule names '${title}', which is no longer a heading in AGENTS.md"
        cite_errors=1
        continue
    fi

    rule_hits=0
    while IFS= read -r hit; do
        [[ -n "${hit}" ]] || continue
        file="${hit%%:*}"
        rest="${hit#*:}"
        lineno="${rest%%:*}"
        text="${rest#*:}"
        while IFS= read -r match; do
            [[ -n "${match}" ]] || continue
            rule_hits=$(( rule_hits + 1 ))
            got="$(printf '%s' "${match}" | grep -oE '[0-9]+' | head -n 1)"
            if [[ "${got}" != "${want}" ]]; then
                fail "${file}:${lineno}: \"${match}\" cites §${got}, but '${title}' is AGENTS.md §${want}"
                cite_errors=1
            fi
        done < <(printf '%s\n' "${text}" | grep -oE "${pattern}")
    done < <(grep -rnE "${pattern}" --include='*.md' "${CITATION_SCAN[@]}" 2>/dev/null | grep -v 'research-workflow-conventions')

    if (( rule_hits == 0 )); then
        fail "citation rule '${pattern}' matches nothing any more; drop the row or restore the citation"
        cite_errors=1
    fi
    cite_checked=$(( cite_checked + rule_hits ))
done

(( cite_errors == 0 )) && note "AGENTS.md heading map pinned; ${cite_checked} labelled citations resolve"

# 17. The conventions document's numbered structure is pinned, and the workflow
#     docs stay line-aligned across languages.
#     Skills cite this file at sub-section granularity — §7.7 is cited 64 times,
#     §6.3 40 times — so renumbering a section, or inserting an item into the
#     middle of one, silently repoints every citation after it. CONTRIBUTING has
#     said "do not renumber" in prose since the beginning; this is the part of it
#     a script can hold.
#     Item counts are pinned only for the sections whose items are cited as
#     §n.m. §0, §2, §8 and §9 have none, so only their headings are pinned.
section "Conventions document structure"

CONV_EN="docs/mds/star-workflow/research-workflow-conventions.md"
CONV_ZH="docs/mds/star-workflow/research-workflow-conventions.zh-CN.md"
CONV_HEADINGS=(
    '0. Vocabulary'
    '1. Git'
    '2. The STOP line'
    '3. `.env` and the project runtime'
    '4. Real dates'
    '5. Plan-name resolution'
    '6. Delegation'
    '7. Dialogue'
    '8. The output table'
    '9. Project layout'
)
CONV_ITEMS=("1|6" "3|6" "4|3" "5|6" "6|9" "7|10")

conv_items() { # $1 = file, $2 = section number -> top-level numbered items in it
    awk -v want="$2" '
        /^## / { n = $2; sub(/\./, "", n); insec = (n == want) }
        insec && /^[0-9]+\. / { c++ }
        END { print c + 0 }
    ' "$1"
}

conv_errors=0

expected_conv="$(printf '%s\n' "${CONV_HEADINGS[@]}")"
actual_conv="$(sed -nE 's/^## (.+)$/\1/p' "${CONV_EN}")"
if [[ "${expected_conv}" != "${actual_conv}" ]]; then
    fail "${CONV_EN} headings changed; skills cite this file as §n and §n.m. Re-audit the citations, then update CONV_HEADINGS in this script:"
    diff <(printf '%s\n' "${expected_conv}") <(printf '%s\n' "${actual_conv}") | sed 's/^/      /'
    conv_errors=1
fi

if [[ "$(sed -nE 's/^## ([0-9]+)\..*/\1/p' "${CONV_EN}")" != "$(sed -nE 's/^## ([0-9]+)\..*/\1/p' "${CONV_ZH}")" ]]; then
    fail "${CONV_ZH} does not carry the same section numbers as ${CONV_EN}; a §n citation resolves to a different rule per language"
    conv_errors=1
fi

for row in "${CONV_ITEMS[@]}"; do
    sec="${row%%|*}"
    want="${row#*|}"
    for f in "${CONV_EN}" "${CONV_ZH}"; do
        got="$(conv_items "${f}" "${sec}")"
        if [[ "${got}" != "${want}" ]]; then
            fail "${f}: §${sec} carries ${got} numbered items, pinned at ${want} — every §${sec}.n citation past the change now points at a different item"
            conv_errors=1
        fi
    done
done

while IFS= read -r en_doc; do
    zh_doc="${en_doc%.md}.zh-CN.md"
    [[ -f "${zh_doc}" ]] || continue   # check 8 already reports a missing twin
    en_lines="$(wc -l < "${en_doc}" | tr -d ' ')"
    zh_lines="$(wc -l < "${zh_doc}" | tr -d ' ')"
    if [[ "${en_lines}" != "${zh_lines}" ]]; then
        fail "${en_doc} is ${en_lines} lines and ${zh_doc} is ${zh_lines}; the workflow docs are kept line-aligned so cross-language diffs stay readable"
        conv_errors=1
    fi
done < <(find docs/mds/star-workflow -type f -name '*.md' ! -name '*.zh-CN.md' | sort)

(( conv_errors == 0 )) && note "conventions headings and item counts pinned; workflow docs line-aligned en/zh"

# 18. The skills guide stays tied to the skills it describes.
#     Nothing else connects them: 69% of that guide paraphrases the fifteen
#     SKILL.md files, which are authoritative and change far more often, and a
#     skill added, removed, or renamed leaves the guide silently describing a
#     workflow that no longer exists. This holds the joins a script can see —
#     one section per skill, links that resolve, citations that land, anchors
#     that still point at a heading. What a section *says* is still on you.
section "Skills guide coverage"

# file|mode. guide: one numbered section per skill. readme: the landing page,
# where a skill only has to be named — its shape is a table, not sections.
GUIDES=("docs/mds/star-workflow/research-workflow-skills.md|guide"
        "docs/mds/star-workflow/research-workflow-skills.zh-CN.md|guide"
        "README.md|readme"
        "README.zh-CN.md|readme")
guide_errors=0

for guide_row in "${GUIDES[@]}"; do
    guide="${guide_row%%|*}"
    guide_mode="${guide_row#*|}"
    [[ -f "${guide}" ]] || { fail "${guide} is missing"; guide_errors=1; continue; }

    if [[ "${guide_mode}" == "guide" ]]; then
        # one numbered section per skill, and no numbered skill section beyond them
        while IFS= read -r skill; do
            n="$(grep -E '^## [0-9]+\.' "${guide}" | grep -cF "\`\$${skill}\`")"
            if (( n != 1 )); then
                fail "${guide}: ${n} sections for ${skill}, expected 1 — a skill was added, removed, or renamed without the guide"
                guide_errors=1
            fi
        done < <(printf '%s\n' "${SKILLS}")
        sections="$(grep -cE '^## [0-9]+\. `\$star-' "${guide}")"
        expected_sections="$(printf '%s\n' "${SKILLS}" | wc -l | tr -d ' ')"
        if [[ "${sections}" != "${expected_sections}" ]]; then
            fail "${guide} has ${sections} per-skill sections for ${expected_sections} skills"
            guide_errors=1
        fi
    else
        # the name must end where the skill's name ends: a plain substring match
        # would accept `$star-expt-digestx` as a mention of `star-expt-digest`
        while IFS= read -r skill; do
            if ! grep -qE "\\\$${skill}([^A-Za-z0-9_-]|\$)" "${guide}"; then
                fail "${guide} never names ${skill} — a skill was added or renamed without the landing page"
                guide_errors=1
            fi
        done < <(printf '%s\n' "${SKILLS}")
    fi

    # every relative link target exists (the per-section "complete definition"
    # links point into .claude/skills/, four directory levels up)
    while IFS= read -r target; do
        [[ -n "${target}" ]] || continue
        if [[ ! -e "$(dirname "${guide}")/${target}" ]]; then
            fail "${guide}: link target ${target} does not exist"
            guide_errors=1
        fi
    done < <(grep -oE '\]\([^)#][^)]*\)' "${guide}" | sed 's/^](//; s/)$//; s/#.*$//' | grep -vE '^(https?|mailto):' | grep -v '^$' | sort -u)

    # citations of the conventions document land on a section, and on an item
    # that section actually has (CONV_ITEMS is pinned by check 17). Two forms:
    # the guides write "conventions §7.7", while the landing page cites it
    # through a link, putting the name and the § on either side of the target —
    # so that form is matched by the line. Keep both greps free of comments:
    # inside a process substitution bash runs a comment as a command, and the
    # error goes to stderr while the check still reports ok.
    while IFS= read -r cite; do
        [[ -n "${cite}" ]] || continue
        c_sec="${cite%%.*}"
        c_item=""
        [[ "${cite}" == *.* ]] && c_item="${cite#*.}"
        if (( c_sec > 9 )); then
            fail "${guide}: cites conventions §${cite}, which has no such section"
            guide_errors=1
            continue
        fi
        for row in "${CONV_ITEMS[@]}"; do
            [[ "${row%%|*}" == "${c_sec}" ]] || continue
            if [[ -n "${c_item}" ]] && (( c_item > ${row#*|} )); then
                fail "${guide}: cites conventions §${cite}, but §${c_sec} has only ${row#*|} items"
                guide_errors=1
            fi
        done
    done < <({ grep -oE '(conventions|规约) §[0-9]+(\.[0-9]+)?' "${guide}"
               grep -h 'research-workflow-conventions' "${guide}" | grep -oE '§[0-9]+(\.[0-9]+)?'
             } | grep -oE '[0-9]+(\.[0-9]+)?' | sort -u)

    # in-page anchors still match a heading. GitHub lowercases, drops
    # punctuation, and turns spaces into dashes; CJK passes through.
    # perl, not sed/tr: the Chinese guide's headings are multibyte, and a
    # byte-oriented normalizer mangles them into anchors that match nothing.
    anchor_of() { printf '%s' "$1" | perl -CSD -Mutf8 -ne '
        chomp; $_ = lc;
        s/[`\$.,:;?!()\[\]{}"\x27\/\\|<>*#+=~^&%@]//g;
        s/[\x{2014}\x{2013}\x{ff1f}\x{ff01}\x{ff0c}\x{3001}\x{ff1a}\x{ff1b}\x{3002}\x{ff08}\x{ff09}\x{201c}\x{201d}\x{2018}\x{2019}]//g;
        s/ /-/g; print "$_\n"'; }
    headings_file="$(mktemp)"
    while IFS= read -r h; do anchor_of "${h#\#* }" >> "${headings_file}"; done < <(grep -E '^#{2,3} ' "${guide}")
    while IFS= read -r anchor; do
        [[ -n "${anchor}" ]] || continue
        if ! grep -qxF "${anchor}" "${headings_file}"; then
            fail "${guide}: in-page link #${anchor} matches no heading"
            guide_errors=1
        fi
    done < <(grep -oE '\]\(#[^)]+\)' "${guide}" | sed 's/^](#//; s/)$//' | sort -u)
    rm -f "${headings_file}"
done

(( guide_errors == 0 )) && note "skills guide covers every skill once, links and anchors resolve, conventions citations land"

printf '\n'
if (( FAILURES > 0 )); then
    printf '%d check(s) failed.\n' "${FAILURES}"
    exit 1
fi
printf 'All consistency checks passed.\n'
