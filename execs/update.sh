#!/usr/bin/env bash
set -euo pipefail

STAR_REF="main"
SKILL_NAME=""
REF_SET=false
ADOPT=false
DIFF=false
FORCE=false
TOOLS_ARG=""

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# This script's own path in the project. It is in the sync set below, because an
# updater that never replaces itself keeps updating the path list it was written
# with: every path added upstream afterwards — the slash commands, the Pi
# extensions — is invisible to it, and the project silently never receives them.
SELF_PATH="execs/update.sh"

SKILL_ROOTS=(
    ".agents/skills"
    ".claude/skills"
    ".cursor/skills"
    ".dsh/skills"
    ".kimi-code/skills"
    ".pi/skills"
    ".qwen/skills"
)

# STAR-owned session hook assets — model-id provenance and the project-memory
# index; overwritten on update like skills.
HOOK_TREES=(
    ".claude/hooks"
    ".codex/hooks"
    ".cursor/hooks"
    ".dsh/hooks"
    ".kimi-code/hooks"
    # Pi keeps its scripts beside the extension that runs them: .pi/hooks/ is
    # the old name for the extensions directory, and Pi warns whenever it exists.
    ".pi/extensions/star-hooks"
    ".qwen/hooks"
)
# Capability extensions vendored from pi's own examples/extensions (MIT), plus the
# roster star_subagent dispatches to. Pi's core ships no sub-agents, no plan mode and
# no structured question tool; these supply all three, and every name they claim is
# prefixed, since pi refuses to start when two extensions claim one tool or flag name
# and these same examples are commonly installed user-level. STAR-owned and
# overwritten on update like skills — a project's own extensions sit beside them and
# an update keeps those.
EXTENSION_TREES=(
    ".pi/agents"
    ".pi/extensions/star-plan-mode"
    ".pi/extensions/star-subagent"
)
EXTENSION_FILES=(
    ".pi/extensions/star-permission-gate.ts"
    ".pi/extensions/star-questionnaire.ts"
)
HOOK_FILES=(
    # DSH reads its hook table through the Claude Code bridge, and the row that
    # loads that bridge lives in the machine's own $DSH_HOME. Both files here are
    # STAR's alone — the table and the reference copy of that row — so neither
    # holds project settings to preserve, and both are overwritten on update.
    ".dsh/hooks.json"
    ".dsh/cordis.patch.yml"
    ".kimi-code/hooks.example.toml"
)
# Hook registration configs a project may have extended with its own settings;
# installed only when missing, never overwritten.
HOOK_CONFIGS=(
    ".claude/settings.json"
    ".codex/hooks.json"
    ".cursor/hooks.json"
    ".qwen/settings.json"
)
# Project config that is not a hook registration, installed on the same terms.
# .pi/settings.json keeps Pi's skill discovery off .agents/skills: Pi scans both
# roots, and while .pi/skills always wins the name collision — it is loaded first
# — the loser is still reported on every start. Excluding it silences that and
# leaves the shared root alone for the agents that read it as their own — Codex
# has no other, and any agent following the AGENTS.md convention finds it there.
PROJECT_CONFIGS=(
    ".pi/settings.json"
)
# Everything installed when missing and never overwritten, whichever kind it is.
INSTALL_CONFIGS=(
    "${HOOK_CONFIGS[@]}"
    "${PROJECT_CONFIGS[@]}"
)
# The agent instructions, in both copies a project carries: agent-instructions.mdc
# is the AGENTS.md body verbatim, so they belong to the project together. Handled
# like the configs above — a project that has written its own keeps them, and one
# that has none gets them from upstream.
INSTRUCTION_FILES=(
    "AGENTS.md"
    ".cursor/rules/agent-instructions.mdc"
)
# The tool trees --tools and STAR_TOOLS name, one entry per agent tool. Which paths
# belong to which is decided by path_tool below, not by a list here, so a path added
# upstream reaches the right tree without being registered anywhere.
ALL_TOOLS=(claude codex cursor dsh kimi pi qwen)

log() {
    printf '[STAR update] %s\n' "$*"
}

fail() {
    printf '[STAR update] ERROR: %s\n' "$*" >&2
    exit 1
}

# Which tool tree a path belongs to, empty when it belongs to none and every run
# therefore covers it. .agents belongs to none on purpose: it is where the
# AGENTS.md convention puts skills, so every agent that follows the convention
# reads it — Codex has no other project root, Cursor scans it natively, Pi and
# DSH read it beside their own — and a project that has it can be handed to a
# tool STAR ships no tree for at all. It is part of the shared skeleton now,
# updated whichever trees --tools names, and updated first. .codex stays Codex's:
# its hooks and its per-skill manifests. .cursorignore is Cursor's one path
# outside .cursor/; every other path starts with its tool's own directory, so one
# added upstream is classified without being listed here.
path_tool() { # $1 = path relative to the project root
    case "$1" in
        .agents/*)               printf '' ;;
        .codex/*)                printf 'codex' ;;
        .claude/*)               printf 'claude' ;;
        .cursor/*|.cursorignore) printf 'cursor' ;;
        .dsh/*)                  printf 'dsh' ;;
        .kimi-code/*)            printf 'kimi' ;;
        .pi/*)                   printf 'pi' ;;
        .qwen/*)                 printf 'qwen' ;;
    esac
}

# The directories a tool owns, for the sparse checkout below — path_tool read the
# other way round, and kept beside it so the two are edited together. A directory
# missing here is a path the checkout does not have, which stops the command.
tool_dirs() { # $1 = tool name
    case "$1" in
        # .agents is not here: it is in the unconditional sparse set below,
        # because every run syncs it.
        codex)  printf '.codex' ;;
        claude) printf '.claude' ;;
        cursor) printf '.cursor' ;;
        dsh)    printf '.dsh' ;;
        kimi)   printf '.kimi-code' ;;
        pi)     printf '.pi' ;;
        qwen)   printf '.qwen' ;;
    esac
}

is_selected() { # $1 = tool name
    local name
    for name in ${SELECTED_TOOLS[@]+"${SELECTED_TOOLS[@]}"}; do
        [[ "${name}" == "$1" ]] && return 0
    done
    return 1
}

# True for a path this run covers: one outside the tool trees, or one in a selected
# tree. A path that is neither is left exactly as it is — never written, never removed.
path_selected() { # $1 = path relative to the project root
    local tool
    tool="$(path_tool "$1")"
    [[ -n "${tool}" ]] || return 0
    is_selected "${tool}"
}

# Drops the paths this run does not cover; the result is FILTERED.
FILTERED=()
filter_paths() { # $@ = paths relative to the project root
    local path
    FILTERED=()
    for path in "$@"; do
        if path_selected "${path}"; then
            FILTERED+=("${path}")
        fi
    done
}

# Names of the STAR hooks a kept registration config does not register. Empty
# when it registers every hook that applies to it. A config predating a hook
# keeps its own entries — update never overwrites it — so this is what turns a
# silent gap into a line.
#
# Pi and DSH have no row here on purpose. Pi registers hooks in code
# (.pi/extensions/star-hooks/index.ts) and DSH in a STAR-owned table (.dsh/hooks.json),
# both in HOOK_FILES above, which an update always replaces — so no kept file can
# fall behind. Neither carries an involve gate: that hook answers the permission
# prompt before a file edit, and neither raises one — Pi ships no prompts at all,
# and DSH's default workspace-write sandbox lets an in-project edit run unasked.
# How a log line should name an installed config, so a project config is not
# announced as a hook registration.
config_kind() { # $1 = config path (relative or absolute)
    local entry
    for entry in "${HOOK_CONFIGS[@]}"; do
        [[ "$1" == "${entry}" || "$1" == *"/${entry}" ]] && { printf 'hook registration'; return 0; }
    done
    printf 'project config'
}

missing_hooks() { # $1 = registration config path
    # Only a hook registration config can be missing a hook. A project config
    # installed beside them registers none, and asking would report all three as
    # absent from a file that was never meant to carry them.
    local entry is_hook_config=false
    for entry in "${HOOK_CONFIGS[@]}"; do
        [[ "$1" == *"/${entry}" ]] && is_hook_config=true
    done
    [[ "${is_hook_config}" == true ]] || return 0

    local out=""
    grep -q 'star_model_id\.sh' "$1" 2>/dev/null || out="model-id provenance"
    grep -q 'star_memory\.sh' "$1" 2>/dev/null || out="${out:+${out}, }project memory"
    # The involve gate answers a permission prompt, so it applies to the configs
    # whose harness lets a hook decide one — Cursor has no event that gates a
    # file edit, and Kimi's only observes the prompt it fires beside.
    case "$1" in
        */.claude/settings.json|*/.codex/hooks.json|*/.qwen/settings.json)
            grep -q 'star_involve_gate\.sh' "$1" 2>/dev/null || out="${out:+${out}, }involve gate" ;;
    esac
    # The commit guard declines a shell command before it runs, which every
    # harness can express — Claude, Codex and Kimi on PreToolUse, Cursor on
    # beforeShellExecution — so every config carries it.
    grep -q 'star_commit_guard\.sh' "$1" 2>/dev/null || out="${out:+${out}, }commit guard"
    printf '%s' "${out}"
}

usage() {
    cat <<'EOF'
Usage: bash execs/update.sh [ref] [--tools LIST] [--skill NAME] [--force]
       bash execs/update.sh --diff [ref] [--tools LIST] [--skill NAME] [--force]
       bash update.sh [ref] [--tools LIST] --adopt

Overwrite STAR-managed skills, session hooks (model-id provenance, project memory), the slash
commands each tool tree defines, research workflow documentation, the stock experiment launcher
execs/run.sh, and this script itself with files from upstream.
The default ref is main; a branch or tag may be supplied instead. By default all of them are
updated, so local edits to execs/run.sh are replaced along with everything else; the experiment
scripts run.sh launches, under execs/scpts/, are the project's own and are never touched.
This script is in that set so a project keeps receiving paths added upstream after it was created:
an updater that never replaced itself would keep updating the path list it shipped with. The
replacement takes effect from the next run — the current one finishes with the copy it started
from — so when the command reports that it replaced itself, run it once more.
The agent instructions (AGENTS.md and .cursor/rules/agent-instructions.mdc, which carries its
body), the hook registration configs (.claude/settings.json, .codex/hooks.json,
.cursor/hooks.json, .qwen/settings.json) and the project config .pi/settings.json are
installed only when missing and never overwritten,
so a project that has written its own keeps them and one that has none gets them. Use --skill
to update only the named skill across the shared root and the Claude, Cursor, DSH, Kimi, Pi and
Qwen Code skill directories.

--tools limits the run to the named tool trees, comma separated: claude, codex, cursor, dsh,
kimi, pi or qwen — or all, which is the default, or none for the shared skeleton by itself. A
tree left out is not touched at all: not installed, not updated, and never deleted, so a project
keeps whatever it already has there. Without the flag the list comes from STAR_TOOLS
(environment first, then .env), and from every tool when that is unset too. The shared paths —
.agents/skills, the workflow documentation, execs/run.sh, this script, AGENTS.md — are updated
whichever trees are selected, and .agents/skills is written first. It is in that list rather
than behind codex because it is where the AGENTS.md convention puts skills: every agent that
follows the convention reads it, so a project has it whatever tool it runs today, including one
STAR ships no tree for. Deleting it is therefore undone by the next update, unlike a tool tree.

--diff previews an update without changing anything: it lists upstream files that are new
or differ from the local copies, plus project-local files an update would keep. It exits 0
when everything already matches, 2 when an update would change files, and 1 on error — so a
script can tell "an update is available" from "the check itself failed".

--force updates the same paths with both refusals lifted: uncommitted changes under them
are overwritten instead of stopping the command, and the agent instructions and hook
registration configs above are overwritten instead of kept. It widens nothing — the path list
is unchanged, and a file upstream does not have is still left alone. Combined with --diff it
previews that scope without changing anything.

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
  bash execs/update.sh --tools claude
  bash execs/update.sh --tools claude,pi --diff

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
        --tools)
            shift
            (( $# > 0 )) || fail "--tools requires a list of tools."
            [[ -z "${TOOLS_ARG}" ]] || fail "--tools may only be specified once."
            TOOLS_ARG="$1"
            ;;
        --tools=*)
            [[ -z "${TOOLS_ARG}" ]] || fail "--tools may only be specified once."
            TOOLS_ARG="${1#*=}"
            [[ -n "${TOOLS_ARG}" ]] || fail "--tools requires a list of tools."
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

# The project this run targets: --adopt installs into the current directory, every
# other mode updates the project this script lives in. Its .env supplies the keys
# resolved here and further down.
ENV_DIR="${ROOT_DIR}"
[[ "${ADOPT}" == false ]] || ENV_DIR="$(pwd -P)"

env_value() { # $1 = key; its last assignment in the target .env, empty when it has none
    [[ -f "${ENV_DIR}/.env" ]] || return 0
    sed -n "s/^$1=//p" "${ENV_DIR}/.env" | tail -1
}

# Which tool trees this run covers: the flag first, then the environment, then .env,
# then every one of them.
TOOLS_SPEC="${TOOLS_ARG}"
TOOLS_SOURCE="--tools"
if [[ -z "${TOOLS_SPEC}" ]]; then
    TOOLS_SPEC="${STAR_TOOLS:-}"
    TOOLS_SOURCE="the STAR_TOOLS environment variable"
fi
if [[ -z "${TOOLS_SPEC}" ]]; then
    TOOLS_SPEC="$(env_value STAR_TOOLS)"
    TOOLS_SOURCE="STAR_TOOLS in .env"
fi
if [[ -z "${TOOLS_SPEC}" ]]; then
    TOOLS_SPEC="all"
    TOOLS_SOURCE="the default"
fi

SELECTED_TOOLS=()
if [[ "${TOOLS_SPEC}" == "all" ]]; then
    SELECTED_TOOLS=("${ALL_TOOLS[@]}")
elif [[ "${TOOLS_SPEC}" != "none" ]]; then
    while IFS= read -r name; do
        name="${name//[[:space:]]/}"
        [[ -n "${name}" ]] || continue
        known=false
        for tool in "${ALL_TOOLS[@]}"; do
            [[ "${name}" == "${tool}" ]] && known=true
        done
        [[ "${known}" == true ]] || \
            fail "Unknown tool '${name}' in ${TOOLS_SOURCE}. Valid: ${ALL_TOOLS[*]}, all, none."
        is_selected "${name}" || SELECTED_TOOLS+=("${name}")
    done < <(tr ',' '\n' <<<"${TOOLS_SPEC}")
    (( ${#SELECTED_TOOLS[@]} > 0 )) || \
        fail "${TOOLS_SOURCE} names no tool. Use 'none' to cover the shared paths by themselves."
fi

# What a narrowed run leaves behind, said once here rather than path by path below.
if (( ${#SELECTED_TOOLS[@]} < ${#ALL_TOOLS[@]} )); then
    untouched=()
    for tool in "${ALL_TOOLS[@]}"; do
        is_selected "${tool}" || untouched+=("${tool}")
    done
    selected_label="none"
    (( ${#SELECTED_TOOLS[@]} == 0 )) || selected_label="${SELECTED_TOOLS[*]}"
    log "Tools (${TOOLS_SOURCE}): ${selected_label}."
    log "Left alone, neither written nor deleted: ${untouched[*]}."
fi

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
        # The shared root first: every project gets it, whichever tools it picks.
        ".agents/skills"
        # Codex's own half of it — the per-skill manifests .agents/skills links
        # to upstream — installed with the rest of the Codex tree and only then.
        ".codex/skills"
        "${SKILL_ROOTS[@]:1}"
        "${HOOK_TREES[@]}"
        "${EXTENSION_TREES[@]}"
        ".claude/commands"
        ".cursor/commands"
        ".qwen/commands"
        ".pi/prompts"
        ".cursor/rules"
        "docs/mds/star-workflow"
        "docs/srcs"
    )
    ADOPT_FILES=(
        "AGENTS.md"
        ".pi/APPEND_SYSTEM.md"
        ".star/memory/MEMORY.md"
        ".env.example"
        ".gitignore"
        ".cursorignore"
        "execs/run.sh"
        "execs/update.sh"
        "execs/scpts/00_exp.sh"
        "${EXTENSION_FILES[@]}"
        "${HOOK_FILES[@]}"
        "${INSTALL_CONFIGS[@]}"
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
    # The layout directories above belong to no tool and are always created; the
    # two lists before them lose the trees this run does not cover.
    filter_paths "${ADOPT_TREES[@]}"
    ADOPT_TREES=("${FILTERED[@]}")
    filter_paths "${ADOPT_FILES[@]}"
    ADOPT_FILES=("${FILTERED[@]}")
elif [[ -n "${SKILL_NAME}" ]]; then
    [[ "${SKILL_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
        fail "Invalid skill name '${SKILL_NAME}'."

    SYNC_PATHS=()
    for root in "${SKILL_ROOTS[@]}"; do
        SYNC_PATHS+=("${root}/${SKILL_NAME}")
    done
    filter_paths "${SYNC_PATHS[@]}"
    SYNC_PATHS=(${FILTERED[@]+"${FILTERED[@]}"})
    (( ${#SYNC_PATHS[@]} > 0 )) || \
        fail "--skill has no tree to act on: ${TOOLS_SOURCE} selects no tool."

    if [[ "${DIFF}" == true ]]; then
        log "Diffing skill: ${SKILL_NAME}"
    else
        log "Updating skill: ${SKILL_NAME}"
    fi
else
    SYNC_PATHS=(
        # The shared root first: every run syncs it, whichever tools were named.
        ".agents/skills"
        # Codex's own half of it, installed and updated with the Codex tree.
        ".codex/skills"
        # Which skill root each tool owns, for the two hosts that discover more
        # than one and need telling which copy to act on. Only these: the other
        # Cursor rule, agent-instructions.mdc, is in INSTRUCTION_FILES above,
        # installed when missing rather than overwritten.
        ".cursor/rules/skill-roots.mdc"
        ".pi/APPEND_SYSTEM.md"
        # /star, which routes a described request to a skill, in the three hosts
        # that read commands from project files. One command each and no more:
        # all three already expose every skill as /star-<name>, so unlike Pi
        # there is nothing per-skill left to supply. Kimi, DSH and Codex have no
        # such directory — their commands are built in or registered in code.
        ".claude/commands"
        ".cursor/commands"
        ".qwen/commands"
        # Pi prompt templates: /star-<name> for each skill, plus /star routing a
        # request to one. They carry the argument hints a Pi skill cannot, since
        # argument-hint is a prompt-template field there and not a skill field.
        ".pi/prompts"
        "${SKILL_ROOTS[@]:1}"
        "${EXTENSION_TREES[@]}"
        "${EXTENSION_FILES[@]}"
        "${HOOK_TREES[@]}"
        "${HOOK_FILES[@]}"
        "docs/mds/star-workflow"
        "docs/srcs"
        # The stock experiment launcher. Only this one file: the experiment
        # scripts it launches, under execs/scpts/, are the project's own.
        "execs/run.sh"
        # The updater itself, replaced by rename rather than extracted — see the
        # extract step below.
        "${SELF_PATH}"
    )
    filter_paths "${SYNC_PATHS[@]}"
    SYNC_PATHS=("${FILTERED[@]}")
fi

# Without --adopt this script rewrites the project it lives in, derived from its
# own location. A copy run from somewhere else would target that other tree.
if [[ "${ADOPT}" == false ]]; then
    [[ -f "${ROOT_DIR}/execs/run.sh" ]] || \
        fail "${ROOT_DIR} is not a STAR project (no execs/run.sh). This script updates the project it lives in: copy it to <project>/execs/update.sh and run it there, or pass --adopt to install STAR into the current directory."
fi

# Upstream resolution: environment wins, then .env, then the public default.
if [[ -z "${STAR_REPOSITORY:-}" ]]; then
    STAR_REPOSITORY="$(env_value STAR_REPOSITORY)"
fi
STAR_REPOSITORY="${STAR_REPOSITORY:-https://github.com/wanghao9610/STAR.git}"

command -v git >/dev/null 2>&1 || fail "git is required."
command -v tar >/dev/null 2>&1 || fail "tar is required."

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT

SOURCE_DIR="${TEMP_DIR}/repository"
ARCHIVE_FILE="${TEMP_DIR}/star-content.tar"

log "Fetching ${STAR_REF} from ${STAR_REPOSITORY}"

# core.symlinks is set on the clone rather than left to the host's git: where it is
# off — the usual configuration on Windows — a symlink checks out as a small text
# file holding its target path. A file identical across the tool trees is stored
# once under .agents/skills and carried in the other trees as a link to it, so
# every one of them would arrive as that path text and install as garbage. Clone's
# own -c writes it into the new repository's config before anything is checked out,
# so the sparse checkout below reads it too.
CLONE_ARGS=(-c core.symlinks=true --quiet --depth 1 --branch "${STAR_REF}" --single-branch)
if [[ "${ADOPT}" == false ]]; then
    CLONE_ARGS+=(--filter=blob:none --sparse)
fi

git clone \
    "${CLONE_ARGS[@]}" \
    "${STAR_REPOSITORY}" \
    "${SOURCE_DIR}" || fail "Unable to fetch ref '${STAR_REF}' from ${STAR_REPOSITORY}. Check the ref exists (a branch or tag, not a commit SHA), that the network is reachable, and that git is 2.25 or newer — currently $(git --version 2>/dev/null || echo 'unknown')."

if [[ "${ADOPT}" == false ]]; then
    if [[ -n "${SKILL_NAME}" ]]; then
        # The Codex copy of the skill comes along whichever tools are selected: it
        # holds the one stored copy of every file the other trees share, and their
        # links resolve to nothing without it. A checkout path only — SYNC_PATHS
        # above is what gets copied out, so the Codex tree is still written to the
        # project only when codex is selected.
        git -C "${SOURCE_DIR}" sparse-checkout set "${SYNC_PATHS[@]}" \
            ".agents/skills/${SKILL_NAME}" ".codex/skills/${SKILL_NAME}"
    else
        # Directory-only patterns keep sparse-checkout correct in both cone and
        # non-cone mode, so a single file in SYNC_PATHS arrives through its
        # directory — .cursor covers .cursor/rules/skill-roots.mdc. A whole tool
        # directory rather than its skill root, because the configs installed when
        # missing are read from here too. The tar below still copies only
        # SYNC_PATHS: execs brings execs/scpts/ along here, and none of it is
        # copied out — which is also why .agents/skills is listed unconditionally.
        # It holds the one stored copy of every skill file the trees share, linked
        # from the others, so a run selecting only claude still needs it in the
        # checkout for those links to resolve; it is not thereby installed.
        # .codex/skills is listed for the same reason from the other side: it
        # holds the per-skill manifests Codex reads, which .agents/skills links
        # to at the path Codex scans.
        SPARSE_PATHS=(docs/mds/star-workflow docs/srcs execs .agents/skills .codex/skills)
        for tool in ${SELECTED_TOOLS[@]+"${SELECTED_TOOLS[@]}"}; do
            read -ra tool_roots <<<"$(tool_dirs "${tool}")"
            SPARSE_PATHS+=("${tool_roots[@]}")
        done
        git -C "${SOURCE_DIR}" sparse-checkout set "${SPARSE_PATHS[@]}"
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

        # Upstream files that an update would overwrite or add. -L so the walk
        # follows symlinks: a file identical across the tool trees is stored once
        # under .agents/skills and linked from the others, and a link is type l,
        # not type f — without it every shared file would go uncounted and an
        # update that changes one would preview as nothing to do.
        while IFS= read -r rel; do
            if [[ ! -e "${ROOT_DIR}/${rel}" && ! -L "${ROOT_DIR}/${rel}" ]]; then
                printf '  new      %s\n' "${rel}"
                added=$(( added + 1 ))
            elif ! cmp -s "${SOURCE_DIR}/${rel}" "${ROOT_DIR}/${rel}"; then
                printf '  differs  %s\n' "${rel}"
                changed=$(( changed + 1 ))
            fi
        done < <(cd "${SOURCE_DIR}" && find -L "${SYNCED[@]}" -type f | sort)

        # Project-local files under the same paths; an update keeps them. -L here
        # too, so both sides count a file the same way — a project that is itself
        # a STAR checkout has the same links, and they are its files.
        while IFS= read -r rel; do
            if [[ ! -e "${SOURCE_DIR}/${rel}" ]]; then
                printf '  extra    %s (not in upstream ref; update keeps it)\n' "${rel}"
                kept=$(( kept + 1 ))
            fi
        done < <(cd "${ROOT_DIR}" && find -L "${SYNCED[@]}" -type f 2>/dev/null | sort)

        # Agent instructions: installed when missing, never overwritten.
        if [[ -z "${SKILL_NAME}" ]]; then
            for doc in "${INSTRUCTION_FILES[@]}"; do
                # These two lists are not the synced paths and were not filtered
                # with them, so each entry is checked against the selection here.
                path_selected "${doc}" || continue
                [[ -e "${SOURCE_DIR}/${doc}" ]] || continue
                if [[ ! -e "${ROOT_DIR}/${doc}" && ! -L "${ROOT_DIR}/${doc}" ]]; then
                    printf '  new      %s (agent instructions)\n' "${doc}"
                    added=$(( added + 1 ))
                elif ! cmp -s "${SOURCE_DIR}/${doc}" "${ROOT_DIR}/${doc}"; then
                    if [[ "${FORCE}" == true ]]; then
                        printf '  differs  %s (agent instructions; --force overwrites it)\n' "${doc}"
                        changed=$(( changed + 1 ))
                    else
                        printf '  yours    %s (differs from upstream; update never overwrites it)\n' "${doc}"
                    fi
                fi
            done
        fi

        # Hook registration configs: installed when missing, never overwritten.
        if [[ -z "${SKILL_NAME}" ]]; then
            for cfg in "${INSTALL_CONFIGS[@]}"; do
                path_selected "${cfg}" || continue
                [[ -e "${SOURCE_DIR}/${cfg}" ]] || continue
                if [[ ! -e "${ROOT_DIR}/${cfg}" && ! -L "${ROOT_DIR}/${cfg}" ]]; then
                    printf '  new      %s (%s)\n' "${cfg}" "$(config_kind "${cfg}")"
                    added=$(( added + 1 ))
                elif ! cmp -s "${SOURCE_DIR}/${cfg}" "${ROOT_DIR}/${cfg}"; then
                    if [[ "${FORCE}" == true ]]; then
                        printf '  differs  %s (%s; --force overwrites it)\n' "${cfg}" "$(config_kind "${cfg}")"
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
            # Only the flag: a selection from STAR_TOOLS is already in the plain command.
            [[ -z "${TOOLS_ARG}" ]] || hint="${hint} --tools ${TOOLS_ARG}"
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
        # --force also overwrites the agent instructions and the hook registration
        # configs, so they belong in what gets reported as about to be lost.
        DIRTY_PATHS=("${SYNCED[@]}")
        if [[ "${FORCE}" == true && -z "${SKILL_NAME}" ]]; then
            filter_paths "${INSTRUCTION_FILES[@]}" "${INSTALL_CONFIGS[@]}"
            DIRTY_PATHS+=(${FILTERED[@]+"${FILTERED[@]}"})
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

    # Everything but this script is extracted in place. This script is not: bash
    # reads a running script from the file as it goes, by byte offset, so
    # extracting over it would leave the shell resuming inside whatever the new
    # bytes put at that offset. Copy-then-rename instead — the rename swaps the
    # directory entry while the running copy keeps the file it was started from.
    TAR_PATHS=()
    SELF_SYNCED=false
    for path in "${SYNCED[@]}"; do
        if [[ "${path}" == "${SELF_PATH}" ]]; then
            SELF_SYNCED=true
        else
            TAR_PATHS+=("${path}")
        fi
    done

    if (( ${#TAR_PATHS[@]} > 0 )); then
        # -h stores what each symlink points at instead of the link itself, so a
        # file the trees share arrives in the project as a real file. Storing the
        # link would install a path into .agents/skills, which a project that did
        # not select codex never receives.
        tar -C "${SOURCE_DIR}" -chf "${ARCHIVE_FILE}" "${TAR_PATHS[@]}"
        tar -C "${ROOT_DIR}" -xf "${ARCHIVE_FILE}"
    fi

    SELF_REPLACED=false
    if [[ "${SELF_SYNCED}" == true ]] && \
       ! cmp -s "${SOURCE_DIR}/${SELF_PATH}" "${ROOT_DIR}/${SELF_PATH}"; then
        cp -p "${SOURCE_DIR}/${SELF_PATH}" "${ROOT_DIR}/${SELF_PATH}.new"
        mv -f "${ROOT_DIR}/${SELF_PATH}.new" "${ROOT_DIR}/${SELF_PATH}"
        SELF_REPLACED=true
    fi

    if [[ -z "${SKILL_NAME}" ]]; then
        for doc in "${INSTRUCTION_FILES[@]}"; do
            path_selected "${doc}" || continue
            [[ -e "${SOURCE_DIR}/${doc}" ]] || continue
            if [[ ! -e "${ROOT_DIR}/${doc}" && ! -L "${ROOT_DIR}/${doc}" ]]; then
                mkdir -p "$(dirname -- "${ROOT_DIR}/${doc}")"
                cp -p "${SOURCE_DIR}/${doc}" "${ROOT_DIR}/${doc}"
                log "Installed ${doc} (agent instructions)"
            elif [[ "${FORCE}" == true ]]; then
                cp -p "${SOURCE_DIR}/${doc}" "${ROOT_DIR}/${doc}"
                log "Overwrote ${doc} (agent instructions; --force), including any changes you made to it."
            fi
        done
    fi

    if [[ -z "${SKILL_NAME}" ]]; then
        for cfg in "${INSTALL_CONFIGS[@]}"; do
            path_selected "${cfg}" || continue
            [[ -e "${SOURCE_DIR}/${cfg}" ]] || continue
            if [[ ! -e "${ROOT_DIR}/${cfg}" && ! -L "${ROOT_DIR}/${cfg}" ]]; then
                mkdir -p "$(dirname -- "${ROOT_DIR}/${cfg}")"
                cp -p "${SOURCE_DIR}/${cfg}" "${ROOT_DIR}/${cfg}"
                log "Installed ${cfg} ($(config_kind "${cfg}"))"
            elif [[ "${FORCE}" == true ]]; then
                cp -p "${SOURCE_DIR}/${cfg}" "${ROOT_DIR}/${cfg}"
                log "Overwrote ${cfg} ($(config_kind "${cfg}"); --force), including any settings you added to it."
            elif [[ -n "$(missing_hooks "${ROOT_DIR}/${cfg}")" ]]; then
                log "NOTE: ${cfg} was kept and does not register the STAR $(missing_hooks "${ROOT_DIR}/${cfg}") hook."
                log "      Merge the missing hook entry from upstream ${cfg} to enable it."
            fi
        done
    fi

    log "Updated: ${SYNCED[*]}"
    if [[ "${SELF_REPLACED}" == true ]]; then
        log "NOTE: ${SELF_PATH} itself changed, and this run used the copy it started with."
        log "      Run it once more to receive any path the new updater adds."
    fi
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
    # -L for the same reason as the diff walks above: the shared skill files are
    # links to the one copy under .agents/skills, and this walk has to list them
    # to install them. The cp in install_file follows the link and writes a real
    # file, so what lands in the project is self-contained.
    while IFS= read -r rel; do
        install_file "${rel}"
    done < <(cd "${SOURCE_DIR}" && find -L "${tree}" -type f | sort)
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
    log "      An update keeps yours too — it installs AGENTS.md only when missing; --force replaces it."
fi
if [[ -e "${ROOT_DIR}/.gitignore" ]]; then
    # Checked per directory, and tolerant of the glob forms (datas/*, wkdrs/**)
    # that a carve-out rule needs: one combined grep would let a .gitignore
    # naming only datas/ silence the warning about inits/ and wkdrs/ too.
    unignored=()
    for tree in datas inits wkdrs .star/memory/local; do
        grep -qE "^/?${tree}(/|/\*|/\*\*)?$" "${ROOT_DIR}/.gitignore" 2>/dev/null || \
            unignored+=("${tree}/")
    done
    if (( ${#unignored[@]} > 0 )); then
        log "NOTE: your .gitignore was kept and does not ignore ${unignored[*]}."
        log "      Add them before committing: a dataset, a checkpoint tree, or one machine's own notes may enter history."
    fi
fi
for cfg in "${INSTALL_CONFIGS[@]}"; do
    if ! path_selected "${cfg}"; then
        continue
    elif [[ ! -e "${ROOT_DIR}/${cfg}" ]]; then
        continue
    elif [[ -n "$(missing_hooks "${ROOT_DIR}/${cfg}")" ]]; then
        log "NOTE: your ${cfg} was kept and does not register the STAR $(missing_hooks "${ROOT_DIR}/${cfg}") hook."
        log "      Merge the missing hook entry from upstream ${cfg} to enable it."
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
