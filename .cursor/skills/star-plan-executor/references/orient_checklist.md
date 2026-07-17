# Codebase Orientation Checklist

Run before drafting EXEC_PLAN (Step 2). Goal: know what exists in `${CODE_NAME}/` before you plan to change it. Never assume a module, entrypoint, or config exists — read it.

1. **Resolve the runtime.** Read `.env`; get `CODE_NAME`, `CONDA_HOME`, `PYTHON_HOME` (`docs/mds/star-workflow/research-workflow-conventions.md` §3).

2. **Map the code root.** List `${CODE_NAME}/`. If it holds only `.gitkeep` (empty), declare **greenfield**: the plan scaffolds structure from scratch and the gap list is "everything".

3. **Locate what §2 names.** For each dependency the sub-plan's §2 lists — a module/entrypoint under `${CODE_NAME}/`, a dataset under `datas/`, weights under `inits/` — confirm it actually exists and note its real path. A missing hard dependency is a Step 1 blocker, not something to invent.

4. **Trace each §3 step to code.** For every step in the sub-plan's §3 Task Breakdown, decide: does the code to do this **exist**, need **modifying**, or need **creating**? This mapping IS the gap list that seeds EXEC_PLAN's Orientation and Actions.

5. **Find the run surface.** Identify how the project is actually run — the train/eval entrypoint, config format, CLI conventions. Read `execs/run.sh` (the project's canonical run entrypoint) and list `execs/scpts/` (where run scripts live); these define the launch convention. Later commands must go through this + the conda env, not ad-hoc one-off scripts. If `execs/run.sh` is empty (greenfield), the plan may scaffold it, and any reusable launch script this run prepares goes under `execs/scpts/<run>.sh` — not loose in `wkdrs/`.

6. **Check upstream artifacts.** For each prefix in the leaf's `depends_on` (mirrored in §2), confirm the upstream sibling is `exec_status: done` and its deliverables actually exist under `wkdrs/` / `inits/` / `datas/`. If an upstream leaf is not `done`, the current leaf is blocked — say so and stop.

**Output of this step:** a gap list (per §3 step: exists / modify / create, with real paths) plus the identified run surface. This feeds directly into Step 3's EXEC_PLAN.
