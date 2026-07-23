#!/usr/bin/env bash
set -euo pipefail

STAR_REPOSITORY="${STAR_REPOSITORY:-https://github.com/wanghao9610/STAR.git}"
STAR_REF="main"
SKILL_NAME=""
REF_SET=false
ADOPT=false

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

SKILL_ROOTS=(
    ".agents/skills"
    ".claude/skills"
    ".cursor/skills"
    ".kimi-code/skills"
)

log() {
    printf '[STAR update] %s\n' "$*"
}

fail() {
    printf '[STAR update] ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash execs/update.sh [ref] [--skill NAME]
       bash update.sh [ref] --adopt

Overwrite STAR-managed skills and research workflow documentation with files from upstream.
The default ref is main; a branch or tag may be supplied instead.
By default, all skills and workflow documentation are updated. Use --skill to update only
the named skill across the Codex, Claude, Cursor, and Kimi skill directories.

--adopt installs the STAR skeleton into an already-started project instead of updating one.
It runs against the current working directory, which must be a git repository root, and
never overwrites a file that is already there: every existing path is left alone and
reported. Run /star-proj-adopt afterwards to wire the project up.

Examples:
  bash execs/update.sh
  bash execs/update.sh TAG_OR_BRANCH
  bash execs/update.sh --skill star-plan-coach
  bash execs/update.sh TAG_OR_BRANCH --skill star-plan-coach

  cd /path/to/my-existing-project
  curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAR/main/execs/update.sh -o /tmp/star-update.sh
  bash /tmp/star-update.sh --adopt
EOF
}

while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --skill)
            shift
            (( $# > 0 )) || fail "--skill requires a skill name."
            [[ -z "${SKILL_NAME}" ]] || fail "--skill may only be specified once."
            SKILL_NAME="$1"
            ;;
        --skill=*)
            [[ -z "${SKILL_NAME}" ]] || fail "--skill may only be specified once."
            SKILL_NAME="${1#*=}"
            [[ -n "${SKILL_NAME}" ]] || fail "--skill requires a skill name."
            ;;
        --adopt)
            ADOPT=true
            ;;
        -*)
            fail "Unknown option: $1"
            ;;
        *)
            [[ "${REF_SET}" == false ]] || fail "Only one ref may be supplied."
            STAR_REF="$1"
            REF_SET=true
            ;;
    esac
    shift
done

if [[ "${ADOPT}" == true ]]; then
    [[ -z "${SKILL_NAME}" ]] || fail "--adopt cannot be combined with --skill."

    ROOT_DIR="$(pwd -P)"
    git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1 || \
        fail "--adopt must run inside a git repository. Run 'git init' first."
    [[ -e "${ROOT_DIR}/.git" ]] || \
        fail "--adopt must run at the repository root, not in a subdirectory."

    # Directories merged file by file, and single files, all copy-if-absent.
    ADOPT_TREES=(
        "${SKILL_ROOTS[@]}"
        ".cursor/rules"
        "docs/mds/star-workflow"
    )
    ADOPT_FILES=(
        "AGENTS.md"
        ".env.example"
        ".gitignore"
        "execs/run.sh"
        "execs/update.sh"
    )
    # Layout directories the workflow expects to exist.
    ADOPT_DIRS=(
        "datas"
        "inits"
        "metds/ideas"
        "metds/plans"
        "metds/refs"
        "tasks"
        "wkdrs"
        "execs/scpts"
    )
elif [[ -n "${SKILL_NAME}" ]]; then
    [[ "${SKILL_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
        fail "Invalid skill name '${SKILL_NAME}'."

    SYNC_PATHS=()
    for root in "${SKILL_ROOTS[@]}"; do
        SYNC_PATHS+=("${root}/${SKILL_NAME}")
    done

    log "Updating skill: ${SKILL_NAME}"
else
    SYNC_PATHS=(
        "${SKILL_ROOTS[@]}"
        "docs/mds/star-workflow"
    )
fi

command -v git >/dev/null 2>&1 || fail "git is required."
command -v tar >/dev/null 2>&1 || fail "tar is required."

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT

SOURCE_DIR="${TEMP_DIR}/repository"
ARCHIVE_FILE="${TEMP_DIR}/star-content.tar"

log "Fetching ${STAR_REF} from ${STAR_REPOSITORY}"

CLONE_ARGS=(--quiet --depth 1 --branch "${STAR_REF}" --single-branch)
if [[ "${ADOPT}" == false ]]; then
    CLONE_ARGS+=(--filter=blob:none --sparse)
fi

git clone \
    "${CLONE_ARGS[@]}" \
    "${STAR_REPOSITORY}" \
    "${SOURCE_DIR}" || fail "Unable to fetch ref '${STAR_REF}'."

if [[ "${ADOPT}" == false ]]; then
    git -C "${SOURCE_DIR}" sparse-checkout set "${SYNC_PATHS[@]}"

    for path in "${SYNC_PATHS[@]}"; do
        [[ -d "${SOURCE_DIR}/${path}" ]] || fail "Upstream ref is missing ${path}."
    done

    tar -C "${SOURCE_DIR}" -cf "${ARCHIVE_FILE}" "${SYNC_PATHS[@]}"
    tar -C "${ROOT_DIR}" -xf "${ARCHIVE_FILE}"

    log "Updated: ${SYNC_PATHS[*]}"
    log "Review the changes with git status and git diff before committing them."
    exit 0
fi

# --adopt: install into an existing project, never overwriting what is already there.
installed=0
skipped=0

install_file() {
    local rel="$1"
    local src="${SOURCE_DIR}/${rel}"
    local dst="${ROOT_DIR}/${rel}"

    [[ -e "${src}" ]] || return 0
    if [[ -e "${dst}" || -L "${dst}" ]]; then
        printf '  kept    %s (already present)\n' "${rel}"
        skipped=$(( skipped + 1 ))
        return 0
    fi
    mkdir -p "$(dirname -- "${dst}")"
    cp -p "${src}" "${dst}"
    printf '  added   %s\n' "${rel}"
    installed=$(( installed + 1 ))
}

for tree in "${ADOPT_TREES[@]}"; do
    [[ -d "${SOURCE_DIR}/${tree}" ]] || fail "Upstream ref is missing ${tree}."
    while IFS= read -r rel; do
        install_file "${rel}"
    done < <(cd "${SOURCE_DIR}" && find "${tree}" -type f | sort)
done

for file in "${ADOPT_FILES[@]}"; do
    install_file "${file}"
done

for dir in "${ADOPT_DIRS[@]}"; do
    if [[ -e "${ROOT_DIR}/${dir}" || -L "${ROOT_DIR}/${dir}" ]]; then
        printf '  kept    %s/ (already present)\n' "${dir}"
        skipped=$(( skipped + 1 ))
    else
        mkdir -p "${ROOT_DIR}/${dir}"
        printf '  added   %s/\n' "${dir}"
        installed=$(( installed + 1 ))
    fi
done

if [[ -e "${ROOT_DIR}/CLAUDE.md" || -L "${ROOT_DIR}/CLAUDE.md" ]]; then
    printf '  kept    CLAUDE.md (already present)\n'
    skipped=$(( skipped + 1 ))
elif [[ -e "${ROOT_DIR}/AGENTS.md" ]]; then
    ln -s AGENTS.md "${ROOT_DIR}/CLAUDE.md"
    printf '  added   CLAUDE.md -> AGENTS.md\n'
    installed=$(( installed + 1 ))
fi

log "Adopted into ${ROOT_DIR}: ${installed} added, ${skipped} left alone."
if (( skipped > 0 )); then
    log "Nothing that was already there was modified. Review the kept lines above."
fi

# Two kept files have consequences worth naming rather than leaving for the user to discover.
if [[ -e "${ROOT_DIR}/AGENTS.md" ]] && \
   ! cmp -s "${SOURCE_DIR}/AGENTS.md" "${ROOT_DIR}/AGENTS.md"; then
    log "NOTE: your AGENTS.md was kept, so STAR's project conventions are not in it."
    log "      Compare against ${STAR_REPOSITORY} AGENTS.md and merge what you want."
fi
if [[ -e "${ROOT_DIR}/.gitignore" ]] && \
   ! grep -qE '^/?(datas|inits|wkdrs)/?$' "${ROOT_DIR}/.gitignore" 2>/dev/null; then
    log "NOTE: your .gitignore was kept and does not ignore datas/ inits/ wkdrs/."
    log "      Add them before committing, or a dataset or checkpoint tree may enter history."
fi

log "Next: copy .env.example to .env, then run /star-proj-adopt to wire the project up."
