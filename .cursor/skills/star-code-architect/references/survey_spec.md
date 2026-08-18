# Survey Spec

Read-only reconnaissance that turns a codebase into a **repo map** the architecture design (Step C1) can trust. Surveyors never modify a file.

## Areas

One `Task` subagent (`subagent_type: explore`) per area, run in parallel (none of them writes a file another surveyor writes, so running them together is safe here — it is not safe everywhere: subagents that fetch share one budget per host, conventions §6.9):

| Area | Looks at | Key questions |
|---|---|---|
| Structure & dependencies | top-level dirs, package layout, internal imports | What are the modules? Which direction do imports flow? Any cycles? |
| Config system | config files/dirs, registry mechanisms, CLI arg parsing | How is an experiment specified? Registry or plain imports? |
| Data pipeline | dataset classes, transforms, loaders, download scripts | Where do datasets plug in? Hardcoded paths? |
| Train/eval entrypoints | train/test scripts, engines, loops, schedulers | What is the launch entry point? One entrypoint or many? |
| Scripts & tools | tools/, scripts/, shell files, notebooks | What is essential vs one-off cruft? |
| Tests & docs | tests/, CI config, docs/ | What is covered? What can serve as a quick verification suite? |

**Light mode** (repos under ~50 Python files — size only; a fresh clone is routinely 3–12× that, so provenance is not the test): collapse to a single pass over all areas — by one `explore` Task subagent or the main agent itself.

## Return format per surveyor

- **Scope**: its area only, read-only; "do not modify, create, or delete any file."
- **Return** (structured):
  - `inventory` — dirs/modules in its area, one line each: path + responsibility.
  - `entrypoints` — runnable entry points found (scripts, CLI commands), if in scope.
  - `mechanisms` — how the area works (config style, registry use, data flow), 3–6 bullets.
  - `smells` — only findings that could motivate a migration item: dead code, duplication, cross-layer imports, naming inconsistencies, giant files. Each: path + one-line evidence.
  - `unknowns` — what it could not determine and why.

## Merging into the repo map

The main agent merges area reports into one repo map:

1. **Module inventory** — annotated tree, one-line responsibility per top-level dir.
2. **Dependency direction** — which layers import which; note violations.
3. **Ranked suspicious patterns** — deduplicated across areas, ranked by how much they would obstruct the plan's work; keep only those worth a migration item. Everything else is recorded as style notes for `codearc.md` §3, not as migrations.

   A ranked suspicious pattern becomes a numbered migration item only after the main agent re-opens its cited path at the cited evidence and confirms the finding still holds (conventions §6.6). What does not hold up is dropped, or demoted to a §3 style note for `codearc.md`. The `path:line` it was confirmed at goes in the migration table's reason column — this is the one place in the skill where an unconfirmed subagent claim would otherwise pass a user confirmation point and then move files.

The repo map feeds Step C1 directly and is summarized (not dumped) to the user.
