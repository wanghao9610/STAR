#!/usr/bin/env bash
set -euo pipefail

STAR_REPOSITORY="${STAR_REPOSITORY:-https://github.com/wanghao9610/STAR.git}"
STAR_REF="${1:-main}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

SYNC_PATHS=(
    ".agents/skills"
    ".claude/skills"
    ".cursor/skills"
    "docs/mds/rsch-workflow"
)

log() {
    printf '[STAR update] %s\n' "$*"
}

fail() {
    printf '[STAR update] ERROR: %s\n' "$*" >&2
    exit 1
}

if [[ "${STAR_REF}" == "-h" || "${STAR_REF}" == "--help" ]]; then
    cat <<'EOF'
Usage: bash execs/update.sh [ref]

Overwrite STAR-managed skills and research workflow documentation with files from upstream.
The default ref is main; a branch or tag may be supplied instead.

Examples:
  bash execs/update.sh
  bash execs/update.sh TAG_OR_BRANCH
EOF
    exit 0
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
