#!/usr/bin/env bash
set -euo pipefail

STAR_REPOSITORY="${STAR_REPOSITORY:-https://github.com/wanghao9610/STAR.git}"
STAR_REF="main"
SKILL_NAME=""
REF_SET=false

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

SKILL_ROOTS=(
    ".agents/skills"
    ".claude/skills"
    ".cursor/skills"
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

Overwrite STAR-managed skills and research workflow documentation with files from upstream.
The default ref is main; a branch or tag may be supplied instead.
By default, all skills and workflow documentation are updated. Use --skill to update only
the named skill across the Codex, Claude, and Cursor skill directories.

Examples:
  bash execs/update.sh
  bash execs/update.sh TAG_OR_BRANCH
  bash execs/update.sh --skill star-plan-coach
  bash execs/update.sh TAG_OR_BRANCH --skill star-plan-coach
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

if [[ -n "${SKILL_NAME}" ]]; then
    [[ "${SKILL_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
        fail "Invalid skill name '${SKILL_NAME}'."

    SYNC_PATHS=()
    for root in "${SKILL_ROOTS[@]}"; do
        SYNC_PATHS+=("${root}/${SKILL_NAME}")
    done
else
    SYNC_PATHS=(
        "${SKILL_ROOTS[@]}"
        "docs/mds/star-workflow"
    )
fi

if [[ -n "${SKILL_NAME}" ]]; then
    log "Updating skill: ${SKILL_NAME}"
fi

command -v git >/dev/null 2>&1 || fail "git is required."
command -v tar >/dev/null 2>&1 || fail "tar is required."

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT

SOURCE_DIR="${TEMP_DIR}/repository"
ARCHIVE_FILE="${TEMP_DIR}/star-content.tar"

log "Fetching ${STAR_REF} from ${STAR_REPOSITORY}"
git clone \
    --quiet \
    --depth 1 \
    --filter=blob:none \
    --sparse \
    --branch "${STAR_REF}" \
    --single-branch \
    "${STAR_REPOSITORY}" \
    "${SOURCE_DIR}" || fail "Unable to fetch ref '${STAR_REF}'."

git -C "${SOURCE_DIR}" sparse-checkout set "${SYNC_PATHS[@]}"

for path in "${SYNC_PATHS[@]}"; do
    [[ -d "${SOURCE_DIR}/${path}" ]] || fail "Upstream ref is missing ${path}."
done

tar -C "${SOURCE_DIR}" -cf "${ARCHIVE_FILE}" "${SYNC_PATHS[@]}"
tar -C "${ROOT_DIR}" -xf "${ARCHIVE_FILE}"

log "Updated: ${SYNC_PATHS[*]}"
log "Review the changes with git status and git diff before committing them."
