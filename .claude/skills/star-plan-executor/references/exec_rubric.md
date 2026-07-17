# Execution Finalization Checklist

Run before calling a run done (Step 6). Report failing items (≤5, ranked by importance) with the file/step and a concrete fix.

1. **Done-criterion actually checked** — the sub-plan's §5 check was run and its evidence (test pass / metric vs threshold / output exists) is recorded in EXEC_LOG, not merely asserted.

2. **Every step has a real check result** — no step is `done` in EXEC_LOG without a pass recorded by the **main loop**, not only the agent's self-report.

3. **Nothing heavy ran autonomously** — every long/multi-GPU training, full-dataset eval, or costly API call is in "Awaiting user", not silently executed (`stop_line_rules.md`).

4. **Files are where they belong** — intermediate working files under `tasks/<plan-name>/`; `EXEC_PLAN.md`, `EXEC_LOG.md`, and generated outputs under `wkdrs/<run>/`; data under `datas/`; weights under `inits/`; run scripts under `execs/scpts/`; code changes only under `${CODE_NAME}/`. Nothing generated is left in `metds/plans/`.

5. **Runtime is the project env** — commands went through `.env`'s conda env; no system python, no hardcoded local paths.

6. **State is resumable** — `wkdrs/<run>/EXEC_LOG.md` reflects true per-step status and the sub-plan frontmatter has `exec_status` + `exec_runs`, this run appended rather than replacing the last. A fresh session could resume from the log alone.

7. **Changes are surgical** — code diffs trace to EXEC_PLAN steps; no unrelated refactors or "improvements" to adjacent code (CLAUDE.md §3).

8. **Handoffs are runnable** — each "Awaiting user" command is complete (conda invocation, inputs, output path) and states what to bring back for verification.

9. **The sub-plan is true to what ran** — every user-confirmed material deviation is synced into the sub-plan's §2–§5 with a `## Revision History` entry (`plan_sync_rules.md`); no row sits unsynced in EXEC_PLAN "Divergences" or EXEC_LOG "Pending amendments" without an explicit user decision to skip it.

10. **Values a document will cite are captured** — every value this run settled that the sub-plan left unstated and a `metds/*.md` section cites (hyperparameters, initialization, the reproduction command) is in the sub-plan already or sits as an ENRICHED row awaiting the user (`plan_sync_rules.md`). A value only EXEC_LOG knows is a value `star-metd-summarize` will report as a permanent gap.
