#!/usr/bin/env bash
#
# Equivalence harness for check_consistency.sh.
#
# The acceptance test for any rewrite of that script is not "faster". It is
# "every section still fails on the same input, with the same wording, naming
# the same file". This runs the whole fault table from equiv_faults.tsv against
# a throwaway copy of HEAD and compares the output byte for byte against a
# recorded golden run.
#
#   bash .github/scripts/equiv_check.sh --regen   record local ignored goldens
#                                                 (do this BEFORE touching the checker)
#   bash .github/scripts/equiv_check.sh           compare against them
#
# Exit 0 when every case matches, 1 when any diverges, 2 on a harness error.
#
# Work copies come from `git archive HEAD`, so an uncommitted edit in the real
# tree is invisible here on purpose: the local goldens describe a commit, not a
# working tree. They are generated test state and are intentionally not tracked.
# Faults use perl -i rather than sed -i, whose BSD and GNU forms disagree about
# the backup-suffix argument.

set -u
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
FAULTS="${ROOT}/.github/scripts/equiv_faults.tsv"
GOLDEN="${ROOT}/.github/scripts/equiv_golden"
JOBS="${EQUIV_JOBS:-4}"
REGEN=false
[[ "${1:-}" == "--regen" ]] && REGEN=true

[[ -f "${FAULTS}" ]] || { echo "no fault table at ${FAULTS}" >&2; exit 2; }
command -v perl >/dev/null || { echo "perl is required" >&2; exit 2; }
git -C "${ROOT}" rev-parse HEAD >/dev/null 2>&1 || { echo "not a git repo" >&2; exit 2; }
mkdir -p "${GOLDEN}"
if [[ "${REGEN}" == false ]] &&
   ! find "${GOLDEN}" -maxdepth 1 -type f -name '*.txt' -print -quit | grep -q .; then
    echo "no local equivalence goldens; run equiv_check.sh --regen on the clean baseline first" >&2
    exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

run_one() { # $1=id $2=section $3=apply $4=must
    local id="$1" section="$2" apply="$3" must="$4"
    local W="${TMP}/w_${id}"
    mkdir -p "${W}"
    git -C "${ROOT}" archive HEAD | tar -x -C "${W}" || { echo "archive failed" > "${TMP}/out_${id}"; return; }
    ( cd "${W}" && eval "${apply}" ) >/dev/null 2>&1
    local out rc
    out="$( cd "${W}" && bash .github/scripts/check_consistency.sh 2>&1 )"
    rc=$?
    { printf 'exit=%s\n' "${rc}"; printf '%s\n' "${out}"; } > "${TMP}/out_${id}"
    # the sanity assertion the table exists for: a fault must actually fail,
    # and must name the file the table says it names
    local note="ok"
    if [[ "${must}" == "-" ]]; then
        (( rc == 0 )) || note="EXPECTED-CLEAN-BUT-FAILED"
    else
        if (( rc == 0 )); then
            note="FAULT-NOT-CAUGHT"
        elif ! printf '%s' "${out}" | grep -q -- "${must}"; then
            note="CAUGHT-BUT-DOES-NOT-NAME:${must}"
        fi
    fi
    printf '%s\n' "${note}" > "${TMP}/note_${id}"
}

ids=(); n=0
while IFS=$'\t' read -r id section apply must; do
    [[ -z "${id}" || "${id}" == \#* ]] && continue
    ids+=("${id}")
    run_one "${id}" "${section}" "${apply}" "${must}" &
    n=$(( n + 1 ))
    (( n % JOBS == 0 )) && wait
done < "${FAULTS}"
wait

same=0; diverged=0; unsound=0
printf '%-8s %-42s %s\n' ID SECTION RESULT
printf '%s\n' "------------------------------------------------------------------------"
while IFS=$'\t' read -r id section apply must; do
    [[ -z "${id}" || "${id}" == \#* ]] && continue
    note="$(cat "${TMP}/note_${id}" 2>/dev/null || echo MISSING)"
    [[ "${note}" == ok ]] || { unsound=$(( unsound + 1 )); printf '%-8s %-42s UNSOUND %s\n' "${id}" "${section:0:42}" "${note}"; }
    if [[ "${REGEN}" == true ]]; then
        cp "${TMP}/out_${id}" "${GOLDEN}/${id}.txt"
        same=$(( same + 1 ))
    elif [[ ! -f "${GOLDEN}/${id}.txt" ]]; then
        printf '%-8s %-42s NO-GOLDEN\n' "${id}" "${section:0:42}"; diverged=$(( diverged + 1 ))
    elif diff -q "${GOLDEN}/${id}.txt" "${TMP}/out_${id}" >/dev/null; then
        same=$(( same + 1 ))
    else
        printf '%-8s %-42s DIVERGED\n' "${id}" "${section:0:42}"
        diff -u "${GOLDEN}/${id}.txt" "${TMP}/out_${id}" | sed -n '1,12p' | sed 's/^/         /'
        diverged=$(( diverged + 1 ))
    fi
done < "${FAULTS}"
printf '%s\n' "------------------------------------------------------------------------"
if [[ "${REGEN}" == true ]]; then
    printf '%s golden cases recorded; %s unsound\n' "${same}" "${unsound}"
    (( unsound == 0 )) || { echo "fix the fault table before trusting these goldens" >&2; exit 1; }
    exit 0
fi
printf '%s/%s identical, %s divergent, %s unsound\n' "${same}" "$(( same + diverged ))" "${diverged}" "${unsound}"
(( diverged == 0 && unsound == 0 )) || exit 1
