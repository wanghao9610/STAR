#!/usr/bin/env bash
set -euo pipefail

STAR_REF="main"
SKILL_NAME=""
REF_SET=false
ADOPT=false
DIFF=false
FORCE=false

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

SKILL_ROOTS=(
    ".agents/skills"
    ".claude/skills"
    ".cursor/skills"
    ".kimi-code/skills"
)

# STAR-owned model-id provenance hook assets; overwritten on update like skills.
HOOK_TREES=(
    ".claude/hooks"
    ".codex/hooks"
    ".cursor/hooks"
    ".kimi-code/hooks"
)
HOOK_FILES=(
    ".kimi-code/hooks.example.toml"
)
# Hook registration configs a project may have extended with its own settings;
# installed only when missing, never overwritten.
HOOK_CONFIGS=(
    ".claude/settings.json"
    ".codex/hooks.json"
    ".cursor/hooks.json"
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
Usage: bash execs/update.sh [ref] [--skill NAME] [--force]
       bash execs/update.sh --diff [ref] [--skill NAME] [--force]
       bash update.sh [ref] --adopt

Overwrite STAR-managed agent instructions (AGENTS.md and the Cursor rule that copies it),
skills, model-id provenance hooks, and research workflow documentation with files from
upstream. The default ref is main; a branch or tag may be supplied instead. By default all
of them are updated, so local edits to AGENTS.md are replaced along with everything else.
Hook registration configs (.claude/settings.json, .codex/hooks.json, .cursor/hooks.json)
are installed only when missing and never overwritten. Use --skill to update only
the named skill across the Codex, Claude, Cursor, and Kimi skill directories.

--diff previews an update without changing anything: it lists upstream files that are new
or differ from the local copies, plus project-local files an update would keep. It exits 0
when everything already matches, 2 when an update would change files, and 1 on error — so a
script can tell "an update is available" from "the check itself failed".

--force updates the same paths with both refusals lifted: uncommitted changes under them
are overwritten instead of stopping the command, and the hook registration configs above are
overwritten instead of kept. It widens nothing — the path list is unchanged, and a file
upstream does not have is still left alone. Combined with --diff it previews that scope
without changing anything.

--adopt installs the STAR skeleton into an already-started project instead of updating one.
It runs against the current working directory, which must be a git repository root, and
never overwrites a file that is already there: every existing path is left alone and
reported. Run /star-proj-adopt afterwards to wire the project up.

The upstream repository is STAR_REPOSITORY (environment first, then .env);
default https://github.com/wanghao9610/STAR.git.

Examples:
  bash execs/update.sh
  bash execs/update.sh TAG_OR_BRANCH
  bash execs/update.sh --diff
  bash execs/update.sh --force
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
        --diff)
            DIFF=true
            ;;
        --force)
            FORCE=true
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
    [[ "${DIFF}" == false ]] || fail "--adopt cannot be combined with --diff."
    # Adopt's whole contract is that it never touches an existing file, which is
    # the opposite of what --force asks for.
    [[ "${FORCE}" == false ]] || fail "--adopt cannot be combined with --force."

    ROOT_DIR="$(pwd -P)"
    git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1 || \
        fail "--adopt must run inside a git repository. Run 'git init' first."
    [[ -e "${ROOT_DIR}/.git" ]] || \
        fail "--adopt must run at the repository root, not in a subdirectory."

    # Directories merged file by file, and single files, all copy-if-absent.
    ADOPT_TREES=(
        "${SKILL_ROOTS[@]}"
        "${HOOK_TREES[@]}"
        ".cursor/rules"
        "docs/mds/star-workflow"
        "docs/srcs"
    )
    ADOPT_FILES=(
        "AGENTS.md"
        ".env.example"
        ".gitignore"
        ".cursorignore"
        "execs/run.sh"
        "execs/update.sh"
        "execs/scpts/00_exp.sh"
        "${HOOK_FILES[@]}"
        "${HOOK_CONFIGS[@]}"
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

    if [[ "${DIFF}" == true ]]; then
        log "Diffing skill: ${SKILL_NAME}"
    else
        log "Updating skill: ${SKILL_NAME}"
    fi
else
    SYNC_PATHS=(
        # The shared agent instructions and the Cursor rule that copies their body.
        "AGENTS.md"
        ".cursor/rules"
        "${SKILL_ROOTS[@]}"
        "${HOOK_TREES[@]}"
        "${HOOK_FILES[@]}"
        "docs/mds/star-workflow"
        "docs/srcs"
    )
fi

# Without --adopt this script rewrites the project it lives in, derived from its
# own location. A copy run from somewhere else would target that other tree.
if [[ "${ADOPT}" == false ]]; then
    [[ -f "${ROOT_DIR}/execs/run.sh" ]] || \
        fail "${ROOT_DIR} is not a STAR project (no execs/run.sh). This script updates the project it lives in: copy it to <project>/execs/update.sh and run it there, or pass --adopt to install STAR into the current directory."
fi

# Upstream resolution: environment wins, then .env, then the public default.
if [[ -z "${STAR_REPOSITORY:-}" && -f "${ROOT_DIR}/.env" ]]; then
    STAR_REPOSITORY="$(sed -n 's/^STAR_REPOSITORY=//p' "${ROOT_DIR}/.env" | tail -1)"
fi
STAR_REPOSITORY="${STAR_REPOSITORY:-https://github.com/wanghao9610/STAR.git}"

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
    "${SOURCE_DIR}" || fail "Unable to fetch ref '${STAR_REF}' from ${STAR_REPOSITORY}. Check the ref exists (a branch or tag, not a commit SHA), that the network is reachable, and that git is 2.25 or newer — currently $(git --version 2>/dev/null || echo 'unknown')."

if [[ "${ADOPT}" == false ]]; then
    if [[ -n "${SKILL_NAME}" ]]; then
        git -C "${SOURCE_DIR}" sparse-checkout set "${SYNC_PATHS[@]}"
    else
        # Directory-only patterns keep sparse-checkout correct in both cone and
        # non-cone mode; the tar below still copies only SYNC_PATHS. AGENTS.md is
        # absent on purpose: cone mode rejects a file argument here, and the clone
        # above already checks out every root file. Should a checkout ever miss it,
        # the SYNCED loop below stops with "Upstream ref is missing AGENTS.md".
        git -C "${SOURCE_DIR}" sparse-checkout set \
            .agents .claude .codex .cursor .kimi-code docs/mds/star-workflow docs/srcs
    fi

    SYNCED=()
    for path in "${SYNC_PATHS[@]}"; do
        if [[ -e "${SOURCE_DIR}/${path}" ]]; then
            SYNCED+=("${path}")
        elif [[ "${path}" == .*/hooks* ]]; then
            log "Skipping ${path}: not present in ref '${STAR_REF}'."
        else
            fail "Upstream ref is missing ${path}."
        fi
    done

    if [[ "${DIFF}" == true ]]; then
        changed=0
        added=0
        kept=0

        # Upstream files that an update would overwrite or add.
        while IFS= read -r rel; do
            if [[ ! -e "${ROOT_DIR}/${rel}" && ! -L "${ROOT_DIR}/${rel}" ]]; then
                printf '  new      %s\n' "${rel}"
                added=$(( added + 1 ))
            elif ! cmp -s "${SOURCE_DIR}/${rel}" "${ROOT_DIR}/${rel}"; then
                printf '  differs  %s\n' "${rel}"
                changed=$(( changed + 1 ))
            fi
        done < <(cd "${SOURCE_DIR}" && find "${SYNCED[@]}" -type f | sort)

        # Project-local files under the same paths; an update keeps them.
        while IFS= read -r rel; do
            if [[ ! -e "${SOURCE_DIR}/${rel}" ]]; then
                printf '  extra    %s (not in upstream ref; update keeps it)\n' "${rel}"
                kept=$(( kept + 1 ))
            fi
        done < <(cd "${ROOT_DIR}" && find "${SYNCED[@]}" -type f 2>/dev/null | sort)

        # Hook registration configs: installed when missing, never overwritten.
        if [[ -z "${SKILL_NAME}" ]]; then
            for cfg in "${HOOK_CONFIGS[@]}"; do
                [[ -e "${SOURCE_DIR}/${cfg}" ]] || continue
                if [[ ! -e "${ROOT_DIR}/${cfg}" && ! -L "${ROOT_DIR}/${cfg}" ]]; then
                    printf '  new      %s (hook registration)\n' "${cfg}"
                    added=$(( added + 1 ))
                elif ! cmp -s "${SOURCE_DIR}/${cfg}" "${ROOT_DIR}/${cfg}"; then
                    if [[ "${FORCE}" == true ]]; then
                        printf '  differs  %s (hook registration; --force overwrites it)\n' "${cfg}"
                        changed=$(( changed + 1 ))
                    else
                        printf '  config   %s (differs from upstream; update never overwrites it)\n' "${cfg}"
                    fi
                fi
            done
        fi

        if (( changed + added > 0 )); then
            hint="bash execs/update.sh"
            [[ "${REF_SET}" == false ]] || hint="${hint} ${STAR_REF}"
            [[ -z "${SKILL_NAME}" ]] || hint="${hint} --skill ${SKILL_NAME}"
            [[ "${FORCE}" == false ]] || hint="${hint} --force"
            log "${changed} differ, ${added} new upstream, ${kept} extra local."
            log "'differs' is direction-blind: it includes files you edited yourself."
            log "Run '${hint}' to apply the upstream versions."
            # 2, not 1: fail() uses 1 for every hard error, so a caller could not
            # distinguish "an update is available" from "the check broke".
            exit 2
        fi
        log "Everything STAR manages matches upstream ref '${STAR_REF}'. Nothing to update."
        exit 0
    fi

    # The extract below overwrites in place and cannot be rolled back. Git is the
    # only safety net, so refuse to run when it would not hold: uncommitted edits
    # under a synced path would be destroyed with no copy anywhere.
    if git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
        # --force also overwrites the hook registration configs, so they belong in
        # what gets reported as about to be lost.
        DIRTY_PATHS=("${SYNCED[@]}")
        if [[ "${FORCE}" == true && -z "${SKILL_NAME}" ]]; then
            DIRTY_PATHS+=("${HOOK_CONFIGS[@]}")
        fi
        DIRTY="$(git -C "${ROOT_DIR}" status --porcelain -- "${DIRTY_PATHS[@]}" 2>/dev/null || true)"
        if [[ -n "${DIRTY}" ]]; then
            printf '%s\n' "${DIRTY}" | sed 's/^/      /' >&2
            if [[ "${FORCE}" == true ]]; then
                log "--force: the uncommitted changes above are being overwritten with no way back."
            else
                fail "The paths above have uncommitted changes and would be overwritten with no way back. Commit or stash them first, or preview with 'bash execs/update.sh --diff'."
            fi
        fi
    else
        log "NOTE: not a git repository, so an update cannot be undone. Back up the STAR-managed paths first if you have local edits."
    fi

    tar -C "${SOURCE_DIR}" -cf "${ARCHIVE_FILE}" "${SYNCED[@]}"
    tar -C "${ROOT_DIR}" -xf "${ARCHIVE_FILE}"

    if [[ -z "${SKILL_NAME}" ]]; then
        for cfg in "${HOOK_CONFIGS[@]}"; do
            [[ -e "${SOURCE_DIR}/${cfg}" ]] || continue
            if [[ ! -e "${ROOT_DIR}/${cfg}" && ! -L "${ROOT_DIR}/${cfg}" ]]; then
                mkdir -p "$(dirname -- "${ROOT_DIR}/${cfg}")"
                cp -p "${SOURCE_DIR}/${cfg}" "${ROOT_DIR}/${cfg}"
                log "Installed ${cfg} (hook registration)"
            elif [[ "${FORCE}" == true ]]; then
                cp -p "${SOURCE_DIR}/${cfg}" "${ROOT_DIR}/${cfg}"
                log "Overwrote ${cfg} (hook registration; --force), including any settings you added to it."
            elif ! grep -q 'star_model_id\.sh' "${ROOT_DIR}/${cfg}" 2>/dev/null; then
                log "NOTE: ${cfg} was kept and does not register the STAR model-id provenance hook."
                log "      Merge the hook entry from upstream ${cfg} to enable provenance."
            fi
        done
    fi

    log "Updated: ${SYNCED[*]}"
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
    log "      Adopt keeps it, but a later 'bash execs/update.sh' overwrites it."
fi
if [[ -e "${ROOT_DIR}/.gitignore" ]]; then
    # Checked per directory, and tolerant of the glob forms (datas/*, wkdrs/**)
    # that a carve-out rule needs: one combined grep would let a .gitignore
    # naming only datas/ silence the warning about inits/ and wkdrs/ too.
    unignored=()
    for tree in datas inits wkdrs; do
        grep -qE "^/?${tree}(/|/\*|/\*\*)?$" "${ROOT_DIR}/.gitignore" 2>/dev/null || \
            unignored+=("${tree}/")
    done
    if (( ${#unignored[@]} > 0 )); then
        log "NOTE: your .gitignore was kept and does not ignore ${unignored[*]}."
        log "      Add them before committing, or a dataset or checkpoint tree may enter history."
    fi
fi
for cfg in "${HOOK_CONFIGS[@]}"; do
    if [[ ! -e "${ROOT_DIR}/${cfg}" ]]; then
        continue
    elif ! grep -q 'star_model_id\.sh' "${ROOT_DIR}/${cfg}" 2>/dev/null; then
        log "NOTE: your ${cfg} was kept and does not register the STAR model-id provenance hook."
        log "      Merge the hook entry from upstream ${cfg} to enable provenance."
    elif [[ "${cfg}" == ".codex/hooks.json" ]]; then
        # Registering it is not enough on Codex: a project hook runs only once the
        # project is trusted and the hook itself approved, and a new or changed hook
        # needs approving again. Nothing reports the gap — the hook simply does not
        # fire, and every model_id this workflow records reads "unrecorded".
        log "NOTE: ${cfg} is registered, but Codex runs a project hook only after you approve it."
        log "      Run /hooks in the Codex CLI and approve it — re-approve whenever it changes."
        log "      Until then model_id stays unrecorded in every report, with nothing to see."
    fi
done

log "Next: copy .env.example to .env, then run /star-proj-adopt to wire the project up."
