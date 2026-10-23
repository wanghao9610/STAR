# Source bindings and analysis applicability

Use this contract when a producer finishes an analysis, results table, method document, environment report, or engineering-only execution record, and when a consumer decides whether to reuse it. The helper is `bash .agents/skills/star-flow-status/scripts/source_state.sh --root <run-checkout>`. It requires shell tools, jq and git, never a Python environment. The producer owns the decision and writes only its existing artifact; status checks never record or repair metadata.

## Record after verification

Run `record <artifact> --kind <kind>` after the artifact's final content and provenance are written. Name every input supporting its conclusions using these options, repeated as needed:

- `--file <path>`: exact file contents, including raw metrics, check output, configuration, dependency definitions or a small input manifest. An explicitly absent file is bound as absent, so its later creation invalidates the record. Do not hash entire datasets, checkpoint blobs or directories.
- `--document <path>`: Markdown content without the helper block or frontmatter dates/provenance. Use for EXEC_PLAN and EXEC_LOG where they affect the conclusion; body changes remain significant.
- `--plan <path>`: plan body and semantic relationships, excluding bookkeeping and Revision History. Use the leaf and relevant ancestors for analysis and exemptions.
- `--method-plan <path>`: the same, plus planning/execution status and whether finalized is set. Use every live plan consulted for a method document, including readiness and source selection; a newly relevant plan must not disappear just because the old document did not cite it.
- `--report <path>`: a current analysis and its bound evidence. Used by results tables only; stale or legacy analysis must be refreshed by its owner before aggregation.
- `--exemption <path>`: a current engineering exemption and its evidence, used by results tables for their non-numeric engineering rows. Withdrawal or changed evidence invalidates the dependent table.

Source paths are root-relative files and may follow declared input symlinks, as project data and worktree inputs do. The writable artifact must resolve inside the selected checkout and cannot itself be a symlink. The helper appends one reserved `star-source-state` HTML comment containing content fingerprints, source paths and kind, preserving the existing body bytes and adding a separator newline when the original last line has none; clearing retains that separator. It never copies source contents or assigns a research verdict. Recording again requires the producer to verify the changed inputs; refreshing hashes alone cannot clear a stale result. Run the normal model-provenance check after this final write too.

Examples, replacing paths with the actual verified scope:

```bash
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/01_demo/EXPT_ANALYSIS_2026-10-22.md --kind analysis --plan metds/plans/01_demo_plan.md --plan metds/plans/0_root_plan.md --document wkdrs/01_demo/EXEC_PLAN.md --file wkdrs/01_demo/metrics.json
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/results/results.md --kind results --report wkdrs/01_demo/EXPT_ANALYSIS_2026-10-22.md
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record metds/framework.md --kind method --method-plan metds/plans/0_root_plan.md --method-plan metds/plans/01_demo_plan.md
```

The date in an example is a placeholder, not a report date to copy. Method output may additionally bind a configuration file when it supplies a fact such as the code path; only its fingerprint is stored. Existing `sources:` dates remain readable provenance, never the freshness decision.

## Check without writing

Run `check <artifact> --kind <kind>`, adding `--require <path>` for every source that should be covered **now**. Source inventories come from the current scope, not from the old artifact: require the current leaf/ancestor constraints for analysis, all current eligible analysis reports and engineering-exemption logs for a results table, and every currently consulted live plan for method output. This detects new inputs as well as edits and removals. Check results-table inputs individually too; a current table cannot rehabilitate a stale analysis.

The JSON result and exit code distinguish `current` (0), `stale` (1: changed content or uncovered current source), and `unknown` (2: missing legacy metadata, unsupported/malformed state or unavailable evidence). Both nonzero outcomes prohibit claiming freshness; route verification to the producer. Dates and mtimes never rescue an unknown artifact. A legacy record needs one source-verified refresh within an authorized producer run. Never mass-stamp historical reports from status.

Use the checkout housing the run. If only branch-side text is accessible and the source files cannot be checked there, report freshness as unknown; do not compare it against another checkout. A valid binding establishes correspondence to the named inputs, not complete scope or a correct scientific interpretation; those remain the producer's responsibility.

## Environment identity

The environment producer records only a report whose `status` is `verified`, after all required runnable checks and any authorized `.env` update:

```bash
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/env_demo_20261022/ENV_REPORT.md --kind environment --runtime "$ENV_PY" --file code/requirements.txt --file code/requirements/runtime.txt
```

Include every dependency definition, included requirements file and lock/configuration file used to build that environment. The report's `interpreter:` identifies the checked absolute interpreter. The helper binds its bytes and installed package metadata (dist-info/egg-info and conda records); it never executes that interpreter. Adding, removing or changing recorded package versions invalidates the binding.

For a status check, resolve the **current** interpreter from `.env` under conventions §3 and pass it as `check <report> --kind environment --runtime <current-interpreter>`, with `--require` for the current dependency definitions. Use the latest relevant report for that interpreter; a partial/blocked report or conflicting evidence does not fall back to an older passing report. A missing interpreter, legacy report or mismatched binding means verification is needed, not that the environment must be rebuilt. Route to `star-env-builder` for verification/repair; install nothing from status.

A matching package inventory cannot prove imports, device availability or editable code still work. The executor still performs the target's narrow import/entrypoint checks before using Python. Known current failures override a matching fingerprint. After `add`, preserve `verified` only when the previous baseline was current and checks cover all installed changes; transitive upgrades or an uncertain baseline require the affected runnable checks before recording a new verified binding. Otherwise keep the report partial/blocked.

## Engineering-only analysis exemption

The executor may record an exemption during finalization only when the actual run is exclusively engineering work: no experimental metric or research conclusion, no hypothesis/baseline/ablation comparison, no data split/selection or evaluation-changing preprocessing, and no training, evaluation or paid inference run. Every required action/deliverable check must already be verified. A task title, a small sample or missing evidence is not an exemption; an existing experimental run cannot be relabelled to hide its results. Explicit user requests for analysis still run.

Record `analysis: not applicable` with a concrete reason and the verification evidence in EXEC_LOG's existing Notes, then bind that same log:

```bash
bash .agents/skills/star-flow-status/scripts/source_state.sh --root "$PWD" record wkdrs/01_demo/EXEC_LOG.md --kind analysis-exemption --reason "Packaging repair only; import checks verified." --plan metds/plans/01_demo_plan.md --plan metds/plans/0_root_plan.md --document wkdrs/01_demo/EXEC_PLAN.md --file code/package.py --file wkdrs/01_demo/import-check.log
```

Include the actual changed source/configuration and evidence files; where a review receipt exists, include it too. After any later executor write, re-evaluate applicability and record only after the final content is settled. If the run now needs analysis, record that decision in Notes and use `clear <EXEC_LOG-path> --kind analysis-exemption` to remove only the obsolete binding, retaining the execution history. Do not mark an experiment exempt because its metric is missing; route that gap to analysis as usual. Code review, launch authority, completion checks and plan-level findings remain independent requirements.

Status suppresses automatic missing-analysis follow-up only for `check EXEC_LOG.md --kind analysis-exemption` returning current with the current plans required. A changed or malformed exemption routes to the executor for reclassification; no exemption defaults to analysis. The analyst's aggregate and digest consumers list current exempt runs as engineering work with no metrics, excluding them from missing-analysis gaps and numeric tables. They never manufacture an analysis report or count the exemption as a verified research result.
