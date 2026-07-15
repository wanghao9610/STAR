#!/usr/bin/env bash
set -euo pipefail

#######################################################################
#                          PART 1  Environment                        #
#######################################################################
# Logging
LOG_TIME="$(date "+%Y-%m-%d-%H-%M-%S")"
LOG_FORMAT="[${LOG_TIME}] [INFO] [$0]"

log() {
    echo -e "${LOG_FORMAT} $*"
}

fail() {
    echo -e "${LOG_FORMAT} [ERROR] $*" >&2
    exit 1
}

# Project paths are derived from this launcher; machine-specific paths
# are loaded from the project .env file.
EXEC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${EXEC_DIR}/.." && pwd -P)"
ENV_FILE="${ROOT_DIR}/.env"

[[ -f "${ENV_FILE}" ]] || fail "Missing ${ENV_FILE}. Copy .env.example to .env and configure it first."

set -a
# shellcheck source=/dev/null
source "${ENV_FILE}"
set +a

: "${CODE_NAME:?CODE_NAME must be set in ${ENV_FILE}}"
: "${CONDA_HOME:?CONDA_HOME must be set in ${ENV_FILE}}"
: "${PYTHON_HOME:?PYTHON_HOME must be set in ${ENV_FILE}}"

CONDA_BIN="${CONDA_HOME}/bin/conda"
[[ -x "${CONDA_BIN}" ]] || fail "Conda executable not found at CONDA_HOME/bin/conda."

if [[ -x "${PYTHON_HOME}" && ! -d "${PYTHON_HOME}" ]]; then
    PYTHON_BIN="${PYTHON_HOME}"
else
    PYTHON_BIN="${PYTHON_HOME}/bin/python"
fi
[[ -x "${PYTHON_BIN}" ]] || fail "Python executable not found under PYTHON_HOME."

PYTHON_ENV="$(cd -- "$(dirname -- "${PYTHON_BIN}")/.." && pwd -P)"
eval "$("${CONDA_BIN}" shell.bash hook 2>/dev/null)"
conda activate "${PYTHON_ENV}"

#######################################################################
#                          PART 2  Project                            #
#######################################################################
CODE_DIR="${ROOT_DIR}/${CODE_NAME}"
DATA_DIR="${ROOT_DIR}/datas"
INIT_DIR="${ROOT_DIR}/inits"
WORK_DIR="${ROOT_DIR}/wkdrs"
SCPT_DIR="${EXEC_DIR}/scpts"

export ROOT_DIR CODE_DIR DATA_DIR INIT_DIR WORK_DIR SCPT_DIR

cd "${ROOT_DIR}"

#######################################################################
#                          PART 3  Launcher                           #
#######################################################################
usage() {
    cat <<EOF
Usage: bash execs/run.sh [experiment] [arguments...]

Launch an experiment from execs/scpts/. The default experiment is 00_exp.sh.

Options:
  -h, --help    Show this help message.
  -l, --list    List available experiment scripts.

Examples:
  bash execs/run.sh
  bash execs/run.sh 00_exp --config config.yaml
EOF
}

list_experiments() {
    local script
    local found=0

    for script in "${SCPT_DIR}"/*.sh; do
        [[ -e "${script}" ]] || continue
        printf '%s\n' "$(basename -- "${script}")"
        found=1
    done

    if (( found == 0 )); then
        log "No experiment scripts found in ${SCPT_DIR}."
    fi
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    -l|--list)
        list_experiments
        exit 0
        ;;
esac

EXPERIMENT_NAME="${1:-00_exp}"
if (( $# > 0 )); then
    shift
fi

[[ "${EXPERIMENT_NAME}" != */* ]] || fail "Experiment must be a script name under execs/scpts/."
[[ "${EXPERIMENT_NAME}" == *.sh ]] || EXPERIMENT_NAME="${EXPERIMENT_NAME}.sh"

EXPERIMENT_SCRIPT="${SCPT_DIR}/${EXPERIMENT_NAME}"
[[ -f "${EXPERIMENT_SCRIPT}" ]] || fail "Experiment script not found: ${EXPERIMENT_NAME}"

log "Python: ${PYTHON_BIN}"
log "Experiment: ${EXPERIMENT_NAME}"

exec bash "${EXPERIMENT_SCRIPT}" "$@"
