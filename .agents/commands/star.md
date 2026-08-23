# Route a STAR request

Use the roster below to route a research-workflow request to exactly one STAR skill.

| Skill | | Purpose |
| --- | --- | --- |
| `star-code-architect` | † | Set up or reorganize the codebase and write `metds/codearc.md` |
| `star-code-release` | † | Prepare the repository for release; it never publishes one |
| `star-code-reviewer` | | Review code against the conventions and what a plan promised |
| `star-env-builder` | | Build and verify the project's Python runtime from `.env` |
| `star-expt-analyst` | | Judge a run's results against the plan's done-criteria |
| `star-expt-digest` | | Summarize what the experiment programme has done lately |
| `star-flow-status` | | Show the plan tree, progress, and exactly one next action |
| `star-idea-storm` | † | Converge a vague interest into a scored, finalized research topic |
| `star-metd-summarize` | | Compile the finished plan tree into paper-ready method documents |
| `star-plan-coach` | † | Draft or reopen a research plan, one coached question at a time |
| `star-plan-decomposer` | † | Split a finished plan into executable leaf sub-plans |
| `star-plan-executor` | | Execute a leaf sub-plan: plan, approve, code, and lightly validate |
| `star-plan-reviser` | † | Revise a plan against execution evidence, item by item |
| `star-proj-adopt` | † | Adopt an already-started project into STAR without disturbing it |
| `star-refs-reviewer` | | Build per-paper notes and a verified `reference.bib` |

The seven skills marked † are explicit-only because each controls a researcher-owned decision. This generic `/star` router never starts one: ask for explicit confirmation, give the exact `/star-<name> <argument>` command, and wait. The other eight may be selected when the request plainly matches.

If the request is empty, select `star-flow-status`. Otherwise, name the chosen skill, give the one-line reason, and pass through the request as its argument. Start an unmarked skill through the active harness's native skill mechanism and use that harness's owned copy. If two skills are equally plausible, ask one concise question instead of blending their scopes. Never bypass a skill by producing its owned artifact from general knowledge.
