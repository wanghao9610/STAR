# Survey Spec

Read-only reconnaissance that turns a codebase into a **repo map** the architecture design (Step C1) can trust. Surveyors never modify a file.

## Lanes

Work the lanes sequentially by default; delegate a bounded lane only when collaboration tools are available and it materially helps (lanes are read-only, so concurrent delegation — at most 3 — is safe):

| Lane | Looks at | Key questions |
|---|---|---|
| Structure & dependencies | top-level dirs, package layout, internal imports | What are the modules? Which direction do imports flow? Any cycles? |
| Config system | config files/dirs, registry mechanisms, CLI arg parsing | How is an experiment specified? Registry or plain imports? |
| Data pipeline | dataset classes, transforms, loaders, download scripts | Where do datasets plug in? Hardcoded paths? |
| Train/eval entrypoints | train/test scripts, engines, loops, schedulers | What is the run surface? One entrypoint or many? |
| Scripts & tools | tools/, scripts/, shell files, notebooks | What is essential vs one-off cruft? |
| Tests & docs | tests/, CI config, docs/ | What is covered? What can serve as a quick verification suite? |

**Light mode** (Branch A fresh clones, or repos under ~50 Python files): collapse to a single inline pass over all lanes.

## Contract per lane (local or delegated)

- **Scope**: its lane only, read-only; "do not modify, create, or delete any file."
- **Return** (structured):
  - `inventory` — dirs/modules in its lane, one line each: path + responsibility.
  - `entrypoints` — runnable surfaces found (scripts, CLI commands), if in scope.
  - `mechanisms` — how the lane works (config style, registry use, data flow), 3–6 bullets.
  - `smells` — only findings that could motivate a migration item: dead code, duplication, cross-layer imports, naming inconsistencies, giant files. Each: path + one-line evidence.
  - `unknowns` — what it could not determine and why.

## Merging into the repo map

The main agent merges lane reports into one repo map:

1. **Module inventory** — annotated tree, one-line responsibility per top-level dir.
2. **Dependency direction** — which layers import which; note violations.
3. **Ranked smells** — deduplicated across lanes, ranked by how much they would obstruct the plan's work; keep only those worth a migration item. Everything else is recorded as style notes for `codearc.md` §3, not as migrations.

The repo map feeds Step C1 directly and is summarized (not dumped) to the user.
