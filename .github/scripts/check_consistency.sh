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

# 12. Frontmatter descriptions stay inside the SKILL.md spec limit, in every tree.
#     The limit is 1024 *characters* and it is not one harness's quirk: the
#     agentskills.io SKILL.md spec, Anthropic's Agent Skills docs and the Kimi
#     CLI docs all state 1-1024 for `description`. This once read as a
#     ".kimi-code budget" of 1050 bytes, reverse-engineered from that tree's data
#     because it was the only tree that had ever been condensed — see
#     .github/CONTRIBUTING.md. Two consequences of that guess, both fixed here:
#       - characters, not bytes. These descriptions carry §, — and → , so bytes
#         run up to 8 past characters and a byte check at 1024 rejects valid
#         files. awk's length() is bytes on BWK awk, so the count goes through
#         perl, as check 18's anchors already do.
#       - the folded-block indicator is not part of the value. `description: >-`
#         left ">-" in the measured text and inflated every folded file by 3.
#     SKILL.md only: it is the registered manifest whose description the platform
#     surfaces. SKILL_zh.md is loaded as a resource and runs past 1300 chars.
#
#     Not checked, because no repo state can hold it: a harness may truncate the
#     listing well before the spec limit. Cursor cut three .agents descriptions
#     at exactly 1536 characters mid-word, so a description over ~1500 loses its
#     tail in the listing the agent matches against, silently.
section "Description length (<= ${DESC_MAX:=1024} characters, SKILL.md spec)"
desc_errors=0
while IFS= read -r manifest; do
    len="$(awk '
        NR == 1 && /^---[ \t]*$/ { fm = 1; next }
        fm && /^---[ \t]*$/ { exit }
        fm && /^description:/ { grab = 1; sub(/^description:[ \t]*/, ""); sub(/^[>|][-+]?[ \t]*$/, "") }
        fm && grab && /^[A-Za-z_-]+:/ && !/^description:/ { exit }
        grab { gsub(/^[ \t]+|[ \t]+$/, ""); if (length($0)) body = body (length(body) ? " " : "") $0 }
        END { print body }
    ' "${manifest}" | perl -CSD -Mutf8 -ne 'chomp; $n += length; END { print $n + 0 }')"
    if (( len > DESC_MAX )); then
        fail "${manifest}: description is ${len} characters, over the ${DESC_MAX}-character SKILL.md limit"
        desc_errors=1
    fi
done < <(find "${SKILL_ROOTS[@]}" -name 'SKILL.md' | sort)
(( desc_errors == 0 )) && note "all descriptions within ${DESC_MAX} characters in all four trees"

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
CONV_ITEMS=("1|6" "3|6" "4|3" "5|6" "6|9" "7|11")

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

# 19. Opening-load invariants.
#     Three passes built the skills' opening load (10dd4da, e5841a2, bfe6c03):
#     one message per run — whole files through the harness's file-reading
#     tool, Bash carrying only the .env probe and the scripts only Bash can
#     run — and SKILL_zh.md kept as a human-readable edition, never a runtime
#     load. Nothing above guards any of that: an edit could cat the
#     conventions back into a Bash block (guaranteeing the >30 KB spill the
#     shape exists to avoid), re-add the SKILL_zh runtime read, or drop the
#     .env probe from one tree, and every check above would stay green. The
#     literals pinned here — the probe line, the language-paragraph opening,
#     the zh blockquote opening — are the strings the load discipline rides
#     on; rewording any of them centrally means updating this check in the
#     same commit.
#
#     Two skills carry conventions text in that Bash call on purpose:
#     star-expt-digest and star-refs-reviewer load a bounded awk excerpt of
#     the sections they act on (about 26-27 KB) instead of the whole file,
#     which is what lets it ride in Bash at all. That is why the ban below is
#     on `cat`-ing the *whole* conventions file — 35 KB, a guaranteed spill —
#     rather than on Bash carrying any conventions text.
section "Opening-load invariants"
open_errors=0
PROBE_LINE="grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'"
lang_seen="$(mktemp)"
bq_seen="$(mktemp)"

for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        for f in SKILL.md SKILL_zh.md; do
            path="${root}/${skill}/${f}"
            [[ -f "${path}" ]] || continue   # check 3 owns missing files
            n="$(grep -cF -- "${PROBE_LINE}" "${path}")"
            if (( n != 1 )); then
                fail "${path}: ${n} .env probe lines, expected exactly 1"
                open_errors=1
            fi
            # Only the .agents fallback sentence may cat the conventions, and
            # that sentence is marked by "accept the spill" / "接受落盘".
            while IFS= read -r hit; do
                [[ -n "${hit}" ]] || continue
                printf '%s' "${hit}" | grep -q 'accept the spill\|接受落盘' && continue
                fail "${path}:${hit%%:*}: cats the conventions inside Bash outside the marked fallback sentence"
                open_errors=1
            done < <(grep -n 'cat docs/mds/star-workflow/research-workflow-conventions' "${path}" 2>/dev/null)
        done

        en="${root}/${skill}/SKILL.md"
        if [[ -f "${en}" ]]; then
            n="$(grep -c "^Match the user's language\." "${en}")"
            if (( n != 1 )); then
                fail "${en}: ${n} language paragraphs, expected exactly 1"
                open_errors=1
            elif ! grep "^Match the user's language\." "${en}" | grep -qF 'not loaded at runtime'; then
                fail "${en}: language paragraph no longer says SKILL_zh.md is not loaded at runtime"
                open_errors=1
            else
                grep "^Match the user's language\." "${en}" >> "${lang_seen}"
            fi
        fi
        zh="${root}/${skill}/SKILL_zh.md"
        if [[ -f "${zh}" ]]; then
            n="$(grep -c '^> 本文件是 `SKILL\.md` 的中文对照版' "${zh}")"
            if (( n != 1 )); then
                fail "${zh}: ${n} header blockquotes of the documentation-edition form, expected exactly 1"
                open_errors=1
            else
                grep '^> 本文件是 `SKILL\.md` 的中文对照版' "${zh}" >> "${bq_seen}"
            fi
        fi
    done < <(printf '%s\n' "${SKILLS}")
done

# Both passages are uniform across all sixty file pairs by design, so a
# partial re-edit — one tree reworded, the rest left behind — shows up here.
if (( $(sort -u "${lang_seen}" | wc -l) > 1 )); then
    fail "the language paragraph differs across SKILL.md files; it is uniform by design:"
    sort -u "${lang_seen}" | cut -c1-80 | sed 's/^/      /'
    open_errors=1
fi
if (( $(sort -u "${bq_seen}" | wc -l) > 1 )); then
    fail "the zh header blockquote differs across SKILL_zh.md files; it is uniform by design"
    open_errors=1
fi
rm -f "${lang_seen}" "${bq_seen}"

stale_reads="$(grep -rn 'in full before acting\|与读取本文件\|issue its read together' "${SKILL_ROOTS[@]}" || true)"
if [[ -n "${stale_reads}" ]]; then
    fail "SKILL_zh runtime-read phrasing has returned:"
    printf '%s\n' "${stale_reads}" | sed 's/^/      /'
    open_errors=1
fi

(( open_errors == 0 )) && note "opening loads hold: one probe line per file, no conventions cat outside the fallback, SKILL_zh not a runtime load, language paragraph and blockquote uniform"

# 20. The section-selective conventions load stays honest.
#     Two skills load only the conventions sections they act on, as an awk
#     excerpt in their opening Bash call (b698f49). That buys ~25% per run and
#     costs two invariants nothing else holds.
#
#     The excerpt has to stay under the Bash spill line, and it has ~3 KB of
#     room. This is the only place that can be caught: `execs/update.sh` copies
#     docs/mds/star-workflow wholesale into downstream projects, which are told
#     not to edit it, so the file can only grow *here*. Without the size
#     assertion below, growing §7 by 4 KB silently converts a one-message load
#     into two round trips in every downstream run, with CI green.
#
#     And the section set now lives twice in each file: once in the awk regex,
#     once in the prose that says what arrives and what does not. Those drift
#     apart the way every other pair in this script has — a reader trusts the
#     prose, a run gets the regex.
#
#     Pinned strings, in the same sense as check 19's: the canonical selector
#     shape `awk '/^## /{k=/^## (a|b)\./} k'`, and the phrases that separate the
#     loaded list from the excluded one in prose — "stay out" and "不装载".
#     Rewording any of them centrally means updating this check in the same
#     commit. Only bare §n counts in that prose; §n.m is a sub-item citation,
#     which is how a stay-out reason may point at a section that IS loaded.
#
#     Known gap, deliberate: star-flow-status also loads part of the conventions,
#     but through `sed` ranges plus an item-level pass over §7, so a section-level
#     parser cannot verify it and it carries no canonical selector to find. Giving
#     it this shape is a change to the most-run skill in the flow and belongs in
#     its own commit.
section "Selective conventions load"

LOAD_EXCERPT_MAX=${LOAD_EXCERPT_MAX:-28000}

# skill|file|section — a citation of a section the skill no longer loads, kept on
# purpose because the sentence restates the rule and cites it only for provenance.
# A `_zh` suffix is stripped before matching, so one row covers both languages.
# Checked both ways, like check 15: a row whose citation is gone fails too.
RESTATED_REGISTRY=(
    "star-expt-digest|SKILL.md|1"
    "star-expt-digest|SKILL.md|2"
    "star-expt-digest|SKILL.md|4"
    "star-expt-digest|references/digest_rubric.md|2"
    "star-expt-digest|references/scope_spec.md|4"
    "star-refs-reviewer|SKILL.md|1"
)

sel_errors=0
sel_files=0
registry_hit=()

bare_sections() { # stdin -> one bare section number per line, sorted unique
    grep -oE '§[0-9]+(\.[0-9]+)?' | grep -v '\.' | tr -d '§' | sort -nu
}

for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        for f in SKILL.md SKILL_zh.md; do
            path="${root}/${skill}/${f}"
            [[ -f "${path}" ]] || continue

            sel="$(grep -F "awk '/^## /{k=/^## (" "${path}" | head -n 1)"
            [[ -n "${sel}" ]] || continue
            sel_files=$(( sel_files + 1 ))

            if [[ "${f}" == SKILL_zh.md ]]; then
                conv="${CONV_ZH}"
                lang=zh
            else
                conv="${CONV_EN}"
                lang=en
            fi

            # 20a. the selector names a set, and applies it to its own language's file
            want="$(sed -nE "s/.*k=\/\^## \(([0-9|]+)\)\\\\\.\/.*/\1/p" <<< "${sel}")"
            if [[ -z "${want}" ]]; then
                fail "${path}: carries a section selector whose set cannot be parsed"
                sel_errors=1
                continue
            fi
            if ! grep -qF -- "${conv}" <<< "${sel}"; then
                fail "${path}: its selector does not read ${conv}"
                sel_errors=1
            fi

            # 20b. what it prints is exactly what it names — the renumber guard
            excerpt="$(awk -v r="^## (${want})\\\\." '/^## /{k=($0~r)} k' "${conv}")"
            if [[ -z "${excerpt}" ]]; then
                fail "${path}: selector (${want}) prints nothing from ${conv}; the conventions may have been renumbered"
                sel_errors=1
                continue
            fi
            got="$(sed -nE 's/^## ([0-9]+)\..*/\1/p' <<< "${excerpt}" | sort -n | paste -sd'|' -)"
            wsorted="$(tr '|' '\n' <<< "${want}" | sort -n | paste -sd'|' -)"
            if [[ "${got}" != "${wsorted}" ]]; then
                fail "${path}: selector names §${wsorted//|/, §} but prints §${got//|/, §}"
                sel_errors=1
            fi

            # 20c. the excerpt stays clear of the Bash spill line
            bytes="$(wc -c <<< "${excerpt}" | tr -d ' ')"
            if (( bytes > LOAD_EXCERPT_MAX )); then
                fail "${path}: excerpt is ${bytes} bytes, over the ${LOAD_EXCERPT_MAX} budget — it will spill and cost the round trip the one-message load exists to avoid. Split the load across two Bash calls in the same message, or drop a section."
                sel_errors=1
            fi

            # The load block: from its heading to the next ## section.
            start="$(grep -nE '^\*\*Shared conventions\.|^\*\*通用规约。' "${path}" | head -n 1 | cut -d: -f1)"
            if [[ -z "${start}" ]]; then
                fail "${path}: has a section selector but no Shared-conventions block to describe it"
                sel_errors=1
                continue
            fi
            block="$(awk -v s="${start}" 'NR>=s{ if (NR>s && /^## /) exit; print }' "${path}")"
            end="$(awk -v s="${start}" 'NR>s && /^## /{print NR-1; exit}' "${path}")"
            [[ -n "${end}" ]] || end="$(wc -l < "${path}")"

            # The loaded list and the stay-out list can share one line, so the split is
            # on the phrase inside the flattened block, not on a line number. The block
            # goes through a file, never `awk -v`, which would eat its backslashes.
            flat="$(mktemp)"
            tr '\n' ' ' <<< "${block}" > "${flat}"

            # 20d. prose vs regex: what the block says arrives is the set, and what it
            #      says stays out is the complement.
            split_at="$(awk '{
                best = 0
                split("stay out|stays out|不装载", marks, "|")
                for (i in marks) { p = index($0, marks[i]); if (p > 0 && (best == 0 || p < best)) best = p }
                print best
            }' "${flat}")"
            if [[ "${split_at}" == "0" ]]; then
                fail "${path}: the load block never says which sections stay out (pinned phrases: \"stay out\" / \"不装载\")"
                sel_errors=1
            else
                claims_in="$(awk -v n="${split_at}" '{print substr($0, 1, n - 1)}' "${flat}" | bare_sections | paste -sd'|' -)"
                claims_out="$(awk -v n="${split_at}" '{print substr($0, n)}' "${flat}" | bare_sections | paste -sd'|' -)"
                if [[ "${claims_in}" != "${wsorted}" ]]; then
                    fail "${path}: the block says §${claims_in//|/, §} arrives but the selector loads §${wsorted//|/, §}"
                    sel_errors=1
                fi
                expect_out="$(for n in 0 1 2 3 4 5 6 7 8 9; do
                                  grep -qx "${n}" <<< "$(tr '|' '\n' <<< "${wsorted}")" || printf '%s\n' "${n}"
                              done | paste -sd'|' -)"
                if [[ "${claims_out}" != "${expect_out}" ]]; then
                    fail "${path}: the block names §${claims_out//|/, §} as staying out; the sections it does not load are §${expect_out//|/, §}"
                    sel_errors=1
                fi
            fi

            # 20e. the size the prose quotes is the size the selector produces. This
            #      caught two real errors when the shape was written: a stale figure,
            #      and en/zh rounding that made one excerpt look smaller than its twin.
            claimed_kb="$(awk '{
                best = 0
                split("excerpt|摘录", marks, "|")
                for (i in marks) { p = index($0, marks[i]); if (p > 0 && (best == 0 || p < best)) best = p }
                if (best > 0) print substr($0, best)
            }' "${flat}" | grep -oE '[0-9]+ KB' | head -n 1 | grep -oE '[0-9]+')"
            if [[ -z "${claimed_kb}" ]]; then
                fail "${path}: the load block never states the excerpt's size, so nothing ties its prose to the ${bytes} bytes it loads"
                sel_errors=1
            else
                measured_kb=$(( (bytes + 500) / 1000 ))
                diff_kb=$(( claimed_kb > measured_kb ? claimed_kb - measured_kb : measured_kb - claimed_kb ))
                if (( diff_kb > 1 )); then
                    fail "${path}: the block says the excerpt is ${claimed_kb} KB; it is ${bytes} bytes (${measured_kb} KB)"
                    sel_errors=1
                fi
            fi

            # 20f. every conventions citation outside the block resolves inside the
            #      loaded set, or is a pinned restatement.
            while IFS= read -r hit; do
                [[ -n "${hit}" ]] || continue
                lineno="${hit%%:*}"
                # inside the block itself 20d owns the citations; outside it they must resolve
                (( lineno >= start && lineno <= end )) && continue
                n="$(printf '%s' "${hit#*:}" | grep -oE '(conventions|规约) §[0-9]+' |
                     grep -oE '[0-9]+' | head -n 1)"
                [[ -n "${n}" ]] || continue
                grep -qx "${n}" <<< "$(tr '|' '\n' <<< "${wsorted}")" && continue
                key="${skill}|${f/_zh.md/.md}|${n}"
                if printf '%s\n' "${RESTATED_REGISTRY[@]}" | grep -qxF "${key}"; then
                    registry_hit+=("${root}|${lang}|${key}")
                else
                    fail "${path}:${lineno}: cites conventions §${n}, which this skill no longer loads. Restate the rule and add '${key}' to RESTATED_REGISTRY, or put §${n} back in the selector."
                    sel_errors=1
                fi
            done < <(grep -nE '(conventions|规约) §[0-9]+' "${path}" || true)

            rm -f "${flat}"
        done

        # references/ carry citations too, and no selector of their own — they are
        # checked against the skill's SKILL.md set.
        en_manifest="${root}/${skill}/SKILL.md"
        [[ -f "${en_manifest}" ]] || continue
        sel="$(grep -F "awk '/^## /{k=/^## (" "${en_manifest}" | head -n 1)"
        [[ -n "${sel}" ]] || continue
        want="$(sed -nE "s/.*k=\/\^## \(([0-9|]+)\)\\\\\.\/.*/\1/p" <<< "${sel}")"
        while IFS= read -r ref; do
            [[ -n "${ref}" ]] || continue
            while IFS= read -r hit; do
                [[ -n "${hit}" ]] || continue
                n="$(printf '%s' "${hit#*:}" | grep -oE '(conventions|规约) §[0-9]+' |
                     grep -oE '[0-9]+' | head -n 1)"
                [[ -n "${n}" ]] || continue
                grep -qx "${n}" <<< "$(tr '|' '\n' <<< "${want}")" && continue
                rel="${ref#"${root}/${skill}/"}"
                [[ "${rel}" == *_zh.md ]] && reflang=zh || reflang=en
                key="${skill}|${rel/_zh.md/.md}|${n}"
                if printf '%s\n' "${RESTATED_REGISTRY[@]}" | grep -qxF "${key}"; then
                    registry_hit+=("${root}|${reflang}|${key}")
                else
                    fail "${ref}:${hit%%:*}: cites conventions §${n}, which ${skill} no longer loads. Restate the rule and add '${key}' to RESTATED_REGISTRY, or put §${n} back in the selector."
                    sel_errors=1
                fi
            done < <(grep -nE '(conventions|规约) §[0-9]+' "${ref}" || true)
        done < <(find "${root}/${skill}/references" -type f -name '*.md' 2>/dev/null | sort)
    done < <(printf '%s\n' "${SKILLS}")
done

# The other direction, per tree: a registry row whose citation is gone is as
# misleading as an unregistered citation, and asking each tree separately also
# catches the restatement dropped from one tree and left in the other three.
for row in "${RESTATED_REGISTRY[@]}"; do
    for root in "${SKILL_ROOTS[@]}"; do
        skill_of_row="${row%%|*}"
        [[ -d "${root}/${skill_of_row}" ]] || continue
        for lang in en zh; do
            if ! printf '%s\n' "${registry_hit[@]:-}" | grep -qxF "${root}|${lang}|${row}"; then
                fail "RESTATED_REGISTRY row '${row}' matches no citation in the ${lang} files of ${root}; drop the row or restore the restatement there"
                sel_errors=1
            fi
        done
    done
done

if (( sel_errors == 0 )); then
    if (( sel_files == 0 )); then
        note "no skill loads the conventions selectively; nothing to check"
    else
        note "${sel_files} selective loads hold: sections printed match sections named, prose matches the selector, excerpts under ${LOAD_EXCERPT_MAX} bytes with their stated sizes, ${#RESTATED_REGISTRY[@]} restatements pinned"
    fi
fi

# 21. The reuse-an-earlier-load paragraph is present, uniform, and inside the load.
#     A second skill in the same conversation is allowed to skip the parts of the
#     opening load it can still see verbatim, which is the only thing that makes a
#     multi-skill session cost one full load instead of N. The permission lives in
#     one paragraph per manifest, and three ways of losing it are invisible above:
#     dropping it from one tree (checks 1-3 compare file sets, not contents),
#     rewording it in one tree so the trees disagree about what may be skipped, and
#     moving it below the first ## heading, where it stops being part of the load
#     the reader is deciding about. It carries no bare §n on purpose — check 20d
#     reads every §n in this same block as a claim about which sections load.
section "Reuse-an-earlier-load paragraph"
reuse_errors=0
reuse_en="$(mktemp)"
reuse_zh="$(mktemp)"

for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        for f in SKILL.md SKILL_zh.md; do
            path="${root}/${skill}/${f}"
            [[ -f "${path}" ]] || continue   # check 3 owns missing files
            if [[ "${f}" == SKILL_zh.md ]]; then
                lead='^\*\*复用上一次装载。\*\*'
                head='^\*\*通用规约。'
                seen="${reuse_zh}"
            else
                lead='^\*\*Reusing an earlier load\.\*\*'
                head='^\*\*Shared conventions\.'
                seen="${reuse_en}"
            fi

            n="$(grep -cE "${lead}" "${path}")"
            if (( n != 1 )); then
                fail "${path}: ${n} reuse-an-earlier-load paragraphs, expected exactly 1"
                reuse_errors=1
                continue
            fi
            grep -E "${lead}" "${path}" >> "${seen}"

            if grep -qE '§[0-9]+([^.0-9]|$)' <<< "$(grep -E "${lead}" "${path}")"; then
                fail "${path}: the reuse paragraph cites a bare §n; check 20d reads those as load claims"
                reuse_errors=1
            fi

            start="$(grep -nE "${head}" "${path}" | head -n 1 | cut -d: -f1)"
            at="$(grep -nE "${lead}" "${path}" | head -n 1 | cut -d: -f1)"
            next_h="$(awk -v s="${start:-0}" 'NR>s && /^## /{print NR; exit}' "${path}")"
            if [[ -z "${start}" ]] || (( at < start )) || { [[ -n "${next_h}" ]] && (( at > next_h )); }; then
                fail "${path}: the reuse paragraph sits outside the opening-load block"
                reuse_errors=1
            fi
        done
    done < <(printf '%s\n' "${SKILLS}")
done

for pair in "en:${reuse_en}" "zh:${reuse_zh}"; do
    lang="${pair%%:*}"
    file="${pair#*:}"
    if (( $(sort -u "${file}" | wc -l) > 1 )); then
        fail "the ${lang} reuse paragraph differs across manifests; it is uniform by design:"
        sort -u "${file}" | cut -c1-80 | sed 's/^/      /'
        reuse_errors=1
    fi
done
rm -f "${reuse_en}" "${reuse_zh}"

(( reuse_errors == 0 )) && note "every manifest carries the reuse paragraph, uniform per language, inside the opening-load block"

printf '\n'
if (( FAILURES > 0 )); then
    printf '%d check(s) failed.\n' "${FAILURES}"
    exit 1
fi
printf 'All consistency checks passed.\n'
