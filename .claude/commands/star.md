---
description: Route a request to the right STAR skill, or report the next action
argument-hint: "[what you want to do]"
disable-model-invocation: true
---
The STAR skill roster, with what each one is for:

| Skill | | Purpose |
|---|---|---|
| `star-code-architect` | † | Bootstrap or reorganize the codebase and write metds/codearc.md |
| `star-code-release` | † | Prepare the repository for release; it never publishes one |
| `star-code-reviewer` | | Review code against the conventions and against what a plan promised |
| `star-env-builder` | | Build and verify the project's Python runtime from .env |
| `star-expt-analyst` | | Judge a run's results against the plan's done-criteria |
| `star-expt-digest` | | Summarize what the experiment programme has done lately |
| `star-flow-status` | | Show the plan tree, progress, and the single next action |
| `star-idea-storm` | † | Converge a vague interest into a scored, finalized research topic |
| `star-metd-summarize` | | Compile the finished plan tree into paper-ready method documents |
| `star-plan-coach` | † | Draft or reopen a research plan, one coached question at a time |
| `star-plan-decomposer` | † | Split a finished plan into executable leaf sub-plans |
| `star-plan-executor` | | Execute a leaf sub-plan: plan, approve, then code and light validation |
| `star-plan-reviser` | † | Revise a plan against execution evidence, item by item |
| `star-proj-adopt` | † | Adopt an already-started project into STAR without disturbing it |
| `star-refs-reviewer` | | Build the related-work base: per-paper notes and a verified reference.bib |

The seven marked † are slash-only (conventions §10.1): each sits on a decision that belongs to the researcher, so the agent never starts one on its own initiative. Here that is enforced by `disable-model-invocation: true` in their manifests, which keeps them out of your skill listing — the Skill tool cannot reach one, and only the user typing `/star-<name>` can start it. The other eight you may start when the task plainly matches (§10.2).

Request, between the brackets: [$ARGUMENTS]

**Empty brackets** — the user is asking where things stand. Start the `star-flow-status` skill with no argument. Nothing else.

**Otherwise** — match the request against the roster, then in one message: name the skill you picked, give the one-line reason, and name the argument you would pass it. Then:

- An unmarked skill: start it with the Skill tool, with that argument. Do not read its `SKILL.md` and follow it here instead — the model, effort and forked context its frontmatter asks for apply only when it is started as a skill, and `star-flow-status` and `star-expt-digest` both ask for all three.
- A skill marked †: **do not start it.** Ask one plain-text question, with the pick as the recommended option and the nearest alternative beside it, and give the exact line to run — `/star-plan-coach <argument>` — since that command is the only way in. Being named through this command is the user reaching for a skill by describing it, which is not the same as the user choosing it, and §10.1 reserves that choice for them.
- No confident match: say so in one line, name the two closest candidates with what each would do, and ask which was meant. Never fall back to answering the request from general knowledge — a plan-shaped file written without a skill carries none of the frontmatter the rest of the workflow reads.
