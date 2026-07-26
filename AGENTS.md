# Agent Instructions

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" -> "Write tests for invalid inputs, then make them pass"
- "Fix the bug" -> "Write a test that reproduces it, then make it pass"
- "Refactor X" -> "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] -> verify: [check]
2. [Step] -> verify: [check]
3. [Step] -> verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Research Workflow

**This project uses the STAR research workflow. Its records are files, not chat history.**

- Plans live in `metds/plans/`; each leaf's execution record is under `wkdrs/<run>/` (`EXEC_PLAN.md`, `EXEC_LOG.md`).
- Run the status skill first when you do not know where things stand — it reads the plan tree and the reports on disk and names the single next action.
- The rules every workflow skill follows are in `docs/mds/star-workflow/research-workflow-conventions.md`; what each skill does is in `research-workflow-skills.md`.
- Do not hand-edit generated reports under `wkdrs/`, and do not edit `docs/mds/star-workflow/` — `execs/update.sh` overwrites it.

## 6. Reply Language

**`.env` `STAR_LANG` sets the language of chat replies and newly generated workflow documents (plans, reports).**

- Set (`en` or `zh`) → reply and write new documents in it, whatever the chat's language. Unset or empty → follow the user's dialogue language.
- An explicit in-conversation request overrides it; an existing document keeps the language declared in its frontmatter.
- Full rule: `docs/mds/star-workflow/research-workflow-conventions.md` §7.6.

## 7. Reply Wording

**Say what happens. The reader should never have to decode a term to know what you did.**

- Name the action, not the metaphor: "I stop here and hand you the command" over "the STOP line"; "confirmation point" over "gate"; "the file is written" over "on disk".
- A term from the workflow docs is fine when its meaning sits in the same sentence. Never coin a new compound noun.
- Exception: literal values (`exec_status: done`, `**Plan-level finding**`) stay verbatim — skills grep them byte-exactly.
- Technical prose, no filler and no emoji. Plain does not mean chatty.

## 8. Project Layout

**Keep project files in their designated directories.**

- Core code belongs in `${CODE_NAME}/`, as defined in `.env`.
- Data and data-related files belong in `datas/`.
- Model weights and weight-related files belong in `inits/`.
- Generated output files belong in `wkdrs/`.
- Put methodology notes in `metds/` and research plans in `metds/plans/`.
- A plan's own tool scripts and its execution intermediate files belong in `tasks/<plan-name>/`; the scripts are durable, the rest is disposable scratch.
- Launcher scripts belong in `execs/`: keep only `run.sh` and `update.sh` at its root, and put per-run scripts in `execs/scpts/<run>.sh`. Anything that is not a launcher does not go in `execs/` at all.
- Project documentation belongs in `docs/`: Markdown in `docs/mds/<topic>/`, HTML pages in `docs/htmls/`, images and static assets in `docs/srcs/`. `docs/mds/star-workflow/` is upstream-managed and overwritten by `execs/update.sh` — do not edit it.
- Output names must distinguish tasks, experiments, or runs.

## 9. Project Runtime

**Use the project environment. Do not guess local paths.**

Before running Python, tests, or dependency checks:
- Read the project root `.env` and use its `PYTHON_HOME`, or derive it from `CONDA_HOME` and `ENV_NAME` when `PYTHON_HOME` is empty.
- If `.env` is missing, create it from `.env.example` and fill in machine-specific values first.
- Run through that interpreter, not system Python. Conda is optional: when `CONDA_HOME` is empty, `PYTHON_HOME` is used directly, which is also how a plain venv is used.
- Do not hardcode local paths.

## 10. Verification

**Prove the change works before calling it done.**

Before finishing:
- Run the narrowest relevant checks first.
- Broaden checks when changes touch shared behavior, public interfaces, or risky paths.
- If a check cannot be run, say why and name the remaining risk.
- Report what was verified, not just that it "works."

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to over complication, and clarifying questions come before implementation rather than after mistakes.
