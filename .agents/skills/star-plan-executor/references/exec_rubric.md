# Execution Finalization Checklist

Run before calling a run done (Step 5). Report failing items (≤5, ranked by importance) with the file/step and a concrete fix.

1. **Done-criterion actually checked** — the sub-plan's §5 check has verifiable evidence (test pass / metric vs threshold / output exists) recorded in EXEC_LOG, including the exact command, raw result or artifact, and corresponding code version. It is not merely asserted, and a costly check is not repeated just to let the main agent claim it ran the command.

2. **Every step has a real check result** — no step is `done` in EXEC_LOG without a pass verified by the main agent from either its own run or inspectable original evidence: exact command, exit/result, raw log or artifact, and corresponding code version. A delegate's summary alone does not pass. Missing or stale provenance requires the narrow check to be re-run; integration that changes behavior, dependencies, or checked code requires the affected checks to be re-run.

3. **Every heavy launch was authorized and bounded** — each long/multi-GPU training, full-dataset eval, or costly API call is either in "Awaiting user" or has a recorded specific ordinary-run authorization / valid `star-auto` launch, its stated cost, and the applicable cost boundary. No irreversible action is inferred from either grant (`stop_line_rules.md`).

4. **Files are where they belong** — the plan's own tool scripts and intermediate working files under `tasks/<plan-name>/`, and no script loose in `execs/`; `EXEC_PLAN.md`, `EXEC_LOG.md`, and generated outputs under `wkdrs/<run>/`; data under `datas/`; weights under `inits/`; run scripts under `execs/scpts/`; code changes only under `${CODE_NAME}/`. Nothing generated is left in `metds/plans/`. Scratch is retained by default; it is removed only on the user's specific request after durable artifacts and evidence are promoted.

5. **Runtime is the project env** — commands went through `.env`'s conda env; no system python, no hardcoded local paths.

6. **State is resumable** — `wkdrs/<run>/EXEC_LOG.md` reflects true per-step status and the sub-plan frontmatter has `exec_status` + `exec_runs`, this run appended, not replacing the last. A fresh session could resume from the log alone.

7. **Changes are surgical** — code diffs trace to EXEC_PLAN steps; no unrelated refactors or "improvements" to adjacent code (`AGENTS.md` §3).

8. **Handoffs are runnable** — each "Awaiting user" command is complete (conda invocation, inputs, output path) and states what to bring back for verification.

9. **The sub-plan is true to what ran** — every authorized material deviation is synced into the sub-plan's §2–§5 with a `## Revision History` entry (`plan_sync_rules.md`); no row sits unsynced in EXEC_PLAN "Divergences" or EXEC_LOG "Pending amendments" without an explicit user decision to skip it, and a decided row is never offered again.

10. **Values a document will cite are captured** — every value this run settled that the sub-plan left unstated and a `metds/*.md` section cites (hyperparameters, initialization, the reproduction command) is in the sub-plan or sits as an ENRICHED row awaiting an authorization decision (`plan_sync_rules.md`). A value only EXEC_LOG knows is one `star-metd-summarize` will report as a permanent gap.

11. **No abandoned or erased work** — a step that ended `blocked` says in EXEC_LOG what became of its action-owned files: restored from the action-start snapshot, or kept by an explicit applicable user decision. Restoration never erases pre-existing/user edits or raw execution evidence, and no commit stages a failed attempt's leftovers (`agent_dispatch_spec.md`).
