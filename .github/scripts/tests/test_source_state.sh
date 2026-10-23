#!/usr/bin/env bash
# Source freshness, environment identity and engineering exemptions; no Python runs.
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
HELPER="$ROOT_DIR/.agents/skills/star-flow-status/scripts/source_state.sh"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
cases=0
fail() { echo "FAIL source state: $*" >&2; exit 1; }
note() { cases=$((cases+1)); echo "ok source state: $*"; }
write() { mkdir -p "$(dirname -- "$project/$1")"; printf '%s' "$2" > "$project/$1"; }
helper() { bash "$HELPER" --root "$project" "$@"; }
check() {
    local want=$1 actual=0 output; shift
    output=$(helper "$@") || actual=$?
    [[ $actual == "$want" ]] || fail "expected $want, got $actual: $output"
    jq -e '.status == "current" or .status == "stale" or .status == "unknown"' <<<"$output" >/dev/null || fail 'invalid check response'
}
reset_case() {
    project="$scratch/case-$cases"
    mkdir -p "$project"
    git init -q "$project"
    plan=metds/plans/01_demo_plan.md
    report=wkdrs/01_demo/EXPT_ANALYSIS_2026-10-22.md
    log=wkdrs/01_demo/EXEC_LOG.md
    write "$plan" $'---\nupdated: 2026-10-22\nexec_status: done\nparent: 0_root_plan.md\nmodel_trail:\n  - model: fixture\n---\n## 5. Done\naccuracy >= 0.8\n## Revision History\nBookkeeping\n'
    write "$report" $'---\nrun: 01_demo\nverdict: met\nanalyzed: 2026-10-22\n---\nAccuracy 0.9.\n'
    write "$log" $'---\nstatus: done\nupdated: 2026-10-22\n---\nAll checks passed.\n'
    write wkdrs/01_demo/metrics.json '{"accuracy":0.9}'
    write code/main.sh 'echo answer'
}
record_analysis() { helper record "$report" --kind analysis --plan "$plan" --file wkdrs/01_demo/metrics.json >/dev/null; }

reset_case; record_analysis
before=$(git -C "$project" hash-object "$project/$report")
check 0 check "$report" --kind analysis --require "$plan"
[[ $(git -C "$project" hash-object "$project/$report") == "$before" ]] || fail 'check wrote report'
record_analysis
[[ $(git -C "$project" hash-object "$project/$report") == "$before" ]] || fail 'record is not idempotent'
note 'current, read-only check and idempotent record'

reset_case; record_analysis; write wkdrs/01_demo/metrics.json '{"accuracy":0.7}'
check 1 check "$report" --kind analysis; note 'same-day metric change'
reset_case; record_analysis; sed 's/>= 0.8/>= 0.95/' "$project/$plan" > "$scratch/plan"; cp "$scratch/plan" "$project/$plan"
check 1 check "$report" --kind analysis; note 'same-day criterion change'
reset_case; record_analysis; sed 's/2026-10-22/2026-10-23/g; s/model: fixture/model: other/; s/Bookkeeping/Another entry/; s/exec_status: done/exec_status: in_progress/' "$project/$plan" > "$scratch/plan"; cp "$scratch/plan" "$project/$plan"
check 0 check "$report" --kind analysis; note 'plan bookkeeping does not invalidate analysis'
reset_case; record_analysis; printf '\nEdited conclusion.\n' >> "$project/$report"
check 1 check "$report" --kind analysis; note 'edited artifact requires producer verification'
reset_case; check 2 check "$report" --kind analysis; note 'legacy report never passes from its date'
reset_case; record_analysis; printf '\n<!-- star-source-state\n{}\n-->\n' >> "$project/$report"
check 2 check "$report" --kind analysis; note 'duplicate metadata rejected'
reset_case; record_analysis; printf '\n<!-- star-source-state\n' >> "$project/$report"
check 2 check "$report" --kind analysis; note 'unclosed metadata rejected'
reset_case; record_analysis; check 1 check "$report" --kind analysis --require metds/plans/02_added_plan.md
note 'new expected source not silently omitted'
reset_case; helper record "$report" --kind analysis --plan "$plan" --file wkdrs/01_demo/pending.json >/dev/null
check 0 check "$report" --kind analysis; write wkdrs/01_demo/pending.json '{}'; check 1 check "$report" --kind analysis
note 'new output invalidates an analysis of its absence'
reset_case; helper record "$report" --kind analysis --plan "$plan" --file wkdrs/01_demo/pending.json >/dev/null
write wkdrs/01_demo/pending.json $'missing\n'; check 1 check "$report" --kind analysis
note 'missing-state encoding cannot collide with a real file'
reset_case; record_analysis; rm "$project/wkdrs/01_demo/metrics.json"; check 1 check "$report" --kind analysis
note 'deleted evidence invalidates analysis'
reset_case; record_analysis; sed $'s/$/\r/' "$project/$report" > "$scratch/crlf"; cp "$scratch/crlf" "$project/$report"
check 0 check "$report" --kind analysis; note 'CRLF records remain readable'
reset_case; sed $'s/$/\r/' "$project/$report" > "$scratch/original"; cp "$scratch/original" "$project/$report"
record_analysis
head -c "$(wc -c < "$scratch/original" | tr -d ' ')" "$project/$report" | cmp -s - "$scratch/original" || fail 'record changed existing CRLF body'
check 0 check "$report" --kind analysis; note 'record preserves original CRLF body bytes'
reset_case; write "$report" $'---\nrun: 01_demo\n# Unclosed header\n'
check 2 record "$report" --kind analysis --plan "$plan" --file wkdrs/01_demo/metrics.json
note 'unclosed frontmatter cannot hide changed body text'
reset_case; printf '<!-- star-source-state\nnot JSON\n-->\n' >> "$project/$report"
before=$(git -C "$project" hash-object "$project/$report")
check 2 record "$report" --kind analysis --plan "$plan" --file wkdrs/01_demo/metrics.json
[[ $(git -C "$project" hash-object "$project/$report") == "$before" ]] || fail 'record erased damaged metadata'
note 'malformed existing metadata is preserved'
reset_case; record_analysis
sed 's/"kind":"analysis"/"kind":"results"/; s@"artifact":"wkdrs/01_demo/EXPT_ANALYSIS_2026-10-22.md"@"artifact":"wkdrs/results/results.md"@' "$project/$report" > "$scratch/wrong-owner"
cp "$scratch/wrong-owner" "$project/$report"; before=$(git -C "$project" hash-object "$project/$report")
check 2 record "$report" --kind analysis --plan "$plan" --file wkdrs/01_demo/metrics.json
[[ $(git -C "$project" hash-object "$project/$report") == "$before" ]] || fail 'record overwrote another artifact binding'
note 'metadata for a different artifact is preserved as invalid'
reset_case; mkdir -p "$scratch/outside"; cp "$project/$report" "$scratch/outside/EXPT_ANALYSIS_2026-10-22.md"
mv "$project/wkdrs/01_demo" "$project/wkdrs/backup"; ln -s "$scratch/outside" "$project/wkdrs/01_demo"
before=$(git -C "$project" hash-object "$scratch/outside/EXPT_ANALYSIS_2026-10-22.md")
check 2 record "$report" --kind analysis --plan "$plan" --file code/main.sh
[[ $(git -C "$project" hash-object "$scratch/outside/EXPT_ANALYSIS_2026-10-22.md") == "$before" ]] || fail 'record wrote outside checkout'
note 'artifact directory links cannot escape the checkout'
reset_case; before=$(git -C "$project" hash-object "$project/$report")
check 2 record "$report" --kind analysis --plan "$plan" --plan "$plan"
[[ $(git -C "$project" hash-object "$project/$report") == "$before" ]] || fail 'failed record changed artifact'
note 'failed recording preserves artifact'

reset_case; write 'data with space;$(touch should-not-run).json' '{"ok":true}'
helper record "$report" --kind analysis --plan "$plan" --file 'data with space;$(touch should-not-run).json' >/dev/null
check 0 check "$report" --kind analysis
[[ ! -e "$project/should-not-run" && ! -e should-not-run ]] || fail 'source path executed'
note 'paths with spaces and shell text stay data'
reset_case; check 2 record "$report" --kind analysis --plan "$plan" --file ../outside
note 'path traversal rejected'
reset_case; ln -s "$project/$report" "$project/self.md"
check 2 record "$report" --kind analysis --plan "$plan" --document self.md
note 'source aliases cannot use the artifact as its own evidence'
reset_case; check 2 record "$report" --kind analysis --file code/main.sh
note 'analysis requires plan constraints as well as evidence'

reset_case; record_analysis; results=wkdrs/results/results.md; write "$results" '# Results'
helper record "$results" --kind results --report "$report" >/dev/null
check 0 check "$results" --kind results --require "$report"
write wkdrs/01_demo/metrics.json '{"accuracy":0.1}'
check 2 check "$results" --kind results
note 'results do not transitively trust a stale analysis'
reset_case; record_analysis; results=wkdrs/results/results.md; write "$results" '# Results'
helper record "$results" --kind results --report "$report" >/dev/null
write wkdrs/01_demo/metrics.json '{"accuracy":0.91}'; record_analysis
check 1 check "$results" --kind results
note 'same-day reanalysis invalidates its results table'
reset_case; record_analysis; results=wkdrs/results/results.md; write "$results" '# Results and engineering work'
helper record "$log" --kind analysis-exemption --reason 'Packaging checks complete.' --plan "$plan" --file code/main.sh >/dev/null
helper record "$results" --kind results --report "$report" --exemption "$log" >/dev/null
check 0 check "$results" --kind results
helper clear "$log" --kind analysis-exemption >/dev/null
check 2 check "$results" --kind results
note 'withdrawn engineering exemption invalidates dependent results'

reset_case; method=metds/framework.md; write "$method" '# Framework'
helper record "$method" --kind method --method-plan "$plan" >/dev/null
check 0 check "$method" --kind method
sed 's/exec_status: done/exec_status: pending/' "$project/$plan" > "$scratch/plan"; cp "$scratch/plan" "$project/$plan"
check 1 check "$method" --kind method; note 'method verification state is a semantic input'
reset_case; method=metds/framework.md; write "$method" '# Framework'
helper record "$method" --kind method --method-plan "$plan" >/dev/null
sed 's/accuracy >= 0.8/accuracy >= 0.95/' "$project/$plan" > "$scratch/plan"; cp "$scratch/plan" "$project/$plan"
check 1 check "$method" --kind method; note 'method content changes within a day'

reset_case; helper record "$log" --kind analysis-exemption --reason 'Packaging only; import checks verified.' --plan "$plan" --file code/main.sh >/dev/null
check 0 check "$log" --kind analysis-exemption
write code/main.sh 'echo changed'; check 1 check "$log" --kind analysis-exemption
note 'engineering exemption is bound to implementation'
reset_case; helper record "$log" --kind analysis-exemption --reason 'Packaging only.' --plan "$plan" --file code/main.sh >/dev/null
printf '\nAnalysis now required: experiment added.\n' >> "$project/$log"
helper clear "$log" --kind analysis-exemption >/dev/null
check 2 check "$log" --kind analysis-exemption
grep -q 'All checks passed.' "$project/$log" && grep -q 'experiment added' "$project/$log" || fail 'clearing lost history'
note 'executor withdraws exemption without deleting execution history'
reset_case; write "$log" $'---\nstatus: done\n---\n## Notes / decisions\n<!-- analysis: not applicable hidden template -->\n- analysis: not applicable — packaging only\n- analysis: required — experiment added\n'
scan=$(cd "$project" && bash "$ROOT_DIR/.agents/skills/star-flow-status/scripts/scan.sh" --slim)
[[ $scan == *'analysis: not applicable — packaging only'* && $scan == *'analysis: required — experiment added'* && $scan != *'hidden template'* ]] || fail 'scan omitted decisions or exposed template comments'
note 'status scan exposes real applicability decisions without template noise'
reset_case; check 2 record "$log" --kind analysis-exemption --plan "$plan" --file code/main.sh
note 'exemption requires a stated decision'
reset_case; write "$log" $'---\nstatus: in_progress\n---\nWork unfinished.\n'
check 2 record "$log" --kind analysis-exemption --reason 'Packaging only.' --plan "$plan" --file code/main.sh
note 'unfinished work cannot receive an analysis exemption'
reset_case; printf '\nanalysis: not applicable\n' >> "$project/$log"
check 2 check "$log" --kind analysis-exemption; note 'legacy prose alone cannot exempt analysis'

make_env() {
    envdir="$project/env with space"
    mkdir -p "$envdir/bin" "$envdir/lib/python3.12/site-packages/example-1.dist-info"
    printf '#!/bin/sh\nexit 99\n' > "$envdir/bin/python"; chmod +x "$envdir/bin/python"
    printf 'Name: example\nVersion: 1\n' > "$envdir/lib/python3.12/site-packages/example-1.dist-info/METADATA"
    envreport=wkdrs/env_demo_20261022/ENV_REPORT.md
    write "$envreport" "$(printf '%s\n' '---' 'status: verified' "interpreter: \"$envdir/bin/python\"" '---' 'L1-L3 passed.')"$'\n'
    write requirements.txt 'example==1'
    helper record "$envreport" --kind environment --runtime "$envdir/bin/python" --file requirements.txt >/dev/null
}
reset_case; make_env; check 0 check "$envreport" --kind environment --runtime "$envdir/bin/python"
note 'environment identity checked without launching Python'
reset_case; make_env; mkdir -p "$project/another/bin"; cp "$envdir/bin/python" "$project/another/bin/python"
check 2 record "$envreport" --kind environment --runtime "$project/another/bin/python" --file requirements.txt
check 0 check "$envreport" --kind environment --runtime "$envdir/bin/python"
note 'report interpreter must equal the verified runtime argument'
reset_case; make_env; check 2 check "$envreport" --kind environment
note 'environment check requires the currently resolved interpreter'
reset_case; make_env; check 1 check "$envreport" --kind environment --runtime "$project/another/bin/python"
note 'changed configured interpreter'
reset_case; make_env; printf '#!/bin/sh\nexit 98\n' > "$envdir/bin/python"
check 1 check "$envreport" --kind environment --runtime "$envdir/bin/python"; note 'interpreter replaced at same path'
reset_case; make_env; printf 'Name: example\nVersion: 2\n' > "$envdir/lib/python3.12/site-packages/example-1.dist-info/METADATA"
check 1 check "$envreport" --kind environment --runtime "$envdir/bin/python"; note 'installed package version changed'
reset_case; make_env; mkdir -p "$envdir/lib/python3.12/site-packages/added-1.dist-info"; echo 'Version: 1' > "$envdir/lib/python3.12/site-packages/added-1.dist-info/METADATA"
check 1 check "$envreport" --kind environment --runtime "$envdir/bin/python"; note 'package inventory addition'
reset_case; make_env; rm "$envdir/lib/python3.12/site-packages/example-1.dist-info/METADATA"
check 1 check "$envreport" --kind environment --runtime "$envdir/bin/python"; note 'package inventory deletion'
reset_case; make_env; write requirements.txt 'example==2'
check 1 check "$envreport" --kind environment --runtime "$envdir/bin/python"; note 'dependency definition changed'
reset_case; make_env; rm "$envdir/bin/python"
check 2 check "$envreport" --kind environment --runtime "$envdir/bin/python"; note 'missing interpreter is unknown'
reset_case; make_env; write "$envreport" $'---\nstatus: partial\n---\nImport failed.\n'
check 2 record "$envreport" --kind environment --runtime "$envdir/bin/python" --file requirements.txt
note 'partial environment cannot receive verified binding'
printf 'PASS source state: %s cases\n' "$cases"
