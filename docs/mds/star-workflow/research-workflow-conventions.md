# Research Workflow Skill Conventions

**Language:** English | [简体中文](research-workflow-conventions.zh-CN.md)

The rules every STAR research workflow skill follows. The fifteen skills — `star-proj-adopt`, `star-idea-storm`, `star-plan-coach`, `star-refs-reviewer`, `star-code-architect`, `star-env-builder`, `star-plan-decomposer`, `star-plan-executor`, `star-code-reviewer`, `star-expt-analyst`, `star-expt-digest`, `star-plan-reviser`, `star-flow-status`, `star-metd-summarize`, `star-code-release` — each carry their own workflow, their own limit on what they may write, and their own rubric. What they share lives here, once.

**Precedence.** This file is the **baseline**. A skill's `SKILL.md` may be **stricter** — a narrower limit on what it may write, a lower threshold, an extra confirmation point, a rule that it never commits at all — and the stricter rule wins. A skill never loosens what this file sets. Where a `SKILL.md` carries a one-line summary of a rule below, that line is the binding reminder and this file is the full rule.

This file is a contract for the skills and a description for the reader: it is what the workflow will and will not do to your repository.

## 0. Vocabulary

Terms this file and every `SKILL.md` use without re-explaining. Each is defined in full where the "Defined in" column points.

| Term | In one clause | Defined in |
|---|---|---|
| top-level plan | the plan `star-plan-coach` writes, covering problem through milestones | §5, §8 |
| done-criterion | a leaf's §5: the binary test that decides whether its run succeeded | the guide, §3 of each plan |
| kill-criterion | a root plan's §5: the result that says stop pursuing this direction | `star-plan-coach` |
| `finalized:` | set by the coach when all six sections are `done`; three skills wait on it — `star-plan-decomposer`, `star-code-architect`, `star-metd-summarize` | §8 |
| `exec_status:` | a leaf's execution state; `done` / `skipped` / `abandoned` are final: nothing more is needed on that leaf | `status_spec.md` |
| `traces_to` | which claim in the root plan this sub-plan supports | `star-plan-decomposer` |
| too big to run | a plan that cannot be executed as it stands — §3/§5 largely `[TBD]` / `【待定】`, or finalized but never decomposed | `status_spec.md` |
| backfill | `star-proj-adopt`'s second phase, recording work finished before any plan existed | §8 |
| follow-up checks | `star-flow-status`'s checks on finished work whose review, analysis, or write-up is missing or out of date | `status_spec.md` |
| summary counts | a parent's progress counted up from its children | `status_spec.md` |
| plan-level finding | a result that changes the plan itself, not just the leaf that produced it | `star-plan-reviser` |
| last covered date | the newest digest's `covers.through`, where the next digest starts | `star-expt-digest` |
| the step's own check | the check an `EXEC_PLAN` step binds to itself, run before that step counts as done | `star-plan-executor` |
| execution branch | the branch — named `<run>`, like the run itself — a leaf's changes live on until the merge confirmation point clears them into the base branch | §11 |
| worktree | a second checkout of the same repository, housing a new run while the invoking checkout is busy; created and removed only by `star-plan-executor` | §11 |

## 1. Git

**Skills that never commit** — git usage is read-only (`status` / `diff` / `log`, plus `branch --list` and `show` for reading an execution branch, §11): `star-flow-status`, `star-refs-reviewer`, `star-expt-analyst`, `star-expt-digest`, `star-metd-summarize`.

**Skills that may commit**, and what each may stage:

| Skill | Commits | Stages |
| --- | --- | --- |
| `star-proj-adopt` | offered once at the end of each phase | only the paths that phase wrote; in an adopted repository, pre-existing uncommitted work is named, never bundled |
| `star-idea-storm` | offered once when the session ends | the idea file this session created or edited |
| `star-plan-coach` | offered once when the session ends | the plan files this session created or edited |
| `star-plan-decomposer` | offered once at the end of the run | the sub-plans written plus the parent's updated index |
| `star-plan-reviser` | offered once at Step 7, when edits were applied | the target plan, plus the parent when its `## Sub-plans` line changed |
| `star-code-architect` | one per finished phase or verified migration group | `${CODE_NAME}/` and the spec files it owns |
| `star-env-builder` | at most one per run | `${CODE_NAME}/requirements*` only |
| `star-plan-executor` | one per verified action, only when the confirmation point approved checkpointing; plus the execution-branch operations §11 defines — create, merge, discard — each at its own confirmation point | the files that action touched; on an execution branch, also the run records those actions updated (§11.2) |
| `star-code-reviewer` | one optional commit after the fix pass | only the files the fix pass touched |
| `star-code-release` | one per finished phase (gather / polish / readme) | only that phase's paths: the promoted files plus the call sites their move broke, the polish-pass files, `README.md` |

**Universal rules:**

1. **Stage only what this run created or edited.** Never `git add -A`, never `git add .`. In a research repository a blanket add sweeps in checkpoints, datasets, and scratch.
2. **The message prefix is the skill's own name**: `star-plan-executor: <run> step 2 — <summary>`, `star-plan-coach: <slug> — <milestone>`. One skill, one namespace in the log.
3. **No pushes, no history rewrites** (`rebase`, `amend`, `reset --hard`), **no tag creation — and no branch switches** outside the execution branches §11 defines, which `star-plan-executor` creates, merges, or discards only at their named confirmation points. The user owns the branch and the remote.
4. **A path that already carried uncommitted changes when the run started is never staged.** Name those paths in the commit offer — or, at `low`, in the final reply — so the user can commit or stash them first; a skill's commit must never bundle work it did not do.
5. **Never commit unannounced.** A commit offer is a judgment call (§7.7), and the answer it recommends is to commit: a local commit publishes nothing, and one made at the wrong moment costs a `git reset --soft`. `medium` and `high` ask it, and declining is always valid; `low` takes it unasked. Either way the final reply names every commit made, with its message and file count — the levels that ask keep their veto, the level that does not keeps its review. With nobody reading the file list at `low`, rule 4 carries the weight alone: snapshot `git status` at the start of the run, and never stage a path already dirty in it.
6. **Never force-add an ignored path.** `.env`, `datas/`, and `inits/` are git-ignored by default and stay out of history. `wkdrs/` is **not** wholly ignored: everything under it is ignored *except* `*.md`, so the workflow's own reports — exec logs, analyses, digests, reviews, the results table — are versionable on purpose, and a run's record can outlive the machine that made it. `tasks/` is tracked in full: a plan's tool scripts are durable by design, and the scratch beside them is small enough not to warrant an exception.

**The guard.** Every tool tree ships a `star_commit_guard.sh` hook that declines the commands breaking these rules where the break is expensive to undo: blanket or forced staging (`add -A`, `add .`, `add -u`, `add -f`, `commit -a`), the history rewrites rule 3 names (`commit --amend`, `rebase`, `reset --hard`, `filter-branch`), the forced branch operations that break §11 in one keystroke (`branch -D`/`-f`, `switch -C`/`-f`, `checkout -B`/`-f`), and any commit whose staged files exceed 10 MB — a research repository's one costly mistake, since clearing a checkpoint back out of history needs exactly those rewrites. `push` is deliberately absent: nothing here makes a skill likelier to push, and a user who asks for one directly should get it. The guard is a floor under the prose, never a replacement for it — it reads one shell line at a time and cannot resolve quoting, and silence is its answer to anything it cannot read confidently. What it declines is the user's to run.

**Why it matters.** `star-plan-reviser` tells users that "older versions live in git"; that is only true if the plan writers actually make the commits.

## 2. The STOP line

Skills may write code and run **light validation**. Anything **heavy, costly, or irreversible** crosses the STOP line: prepare the exact command, hand it to the user, and stop. Never launch it autonomously — no matter how confident the skill is, and no matter that a confirmation point approved the surrounding work.

**Light — a skill may run it:**

- Unit and smoke tests, import checks, `python -m compileall`, a forward pass on a tiny batch.
- Small-scale, **no-finetune** inference on a small subset — e.g. an MVP done-criterion: "no training, small subset, swap the text input and compare".
- Dry runs, config validation, shape/dtype checks, a few-step overfit sanity run.
- Anything that finishes in **minutes on modest resources** and writes only where the skill is allowed to write.

**Crosses the STOP line — hand it to the user:**

- **Long or multi-GPU training or fine-tuning** — any full training run.
- **Full-dataset evaluation** that takes hours or significant compute.
- **Costly API calls** — large-volume LLM/VLM inference billed per call.
- **`sudo` or a system package manager** (apt, brew), driver or CUDA-toolkit system installs, and **CUDA source compilation** (flash-attn-style builds).
- **Deleting any environment**, and overwriting artifacts the user may want to keep.
- Anything whose cost or runtime **cannot be bounded**. When unsure, it is STOP.

Download-size thresholds are **skill-specific** — `star-env-builder` runs framework-scale downloads once its install plan is approved; `star-code-architect` hands anything over ~1 GB back. Each skill states its own; this list is what crosses regardless.

**How to hand off.** Give the user the exact command, invoked through the `.env` environment (§3) and the project's launch entry point (`execs/run.sh`) where one exists; say what it produces and where; say what output to bring back so the criterion can be verified. Writing the command into a runnable script is light; running it is not.

## 3. `.env` and the project runtime

The operational form of `AGENTS.md` §9.

1. **`.env` at the project root is the only source** of `CODE_NAME`, `ENV_NAME`, `CONDA_HOME`, and `PYTHON_HOME`. Never guess a local path, never hardcode one, never read them from memory of another project.
2. **`PYTHON_HOME` is authoritative.** Set → use it as given; `CONDA_HOME` and `ENV_NAME` may be empty, and the interpreter then runs directly rather than through conda. Empty → derive it as `$CONDA_HOME/envs/$ENV_NAME`, which requires both to be set. Neither → a blocker to report, not a value to invent.
3. **Missing `.env`** → for a skill that needs the interpreter, create it from `.env.example`, ask the user to fill the machine-specific values, and stop until they do. Never invent a value to keep going. **This binds only skills that are about to run something.** A skill that needs no runtime — a status report, a plan edit, a survey — notes the absence, treats `INVOLVE` as `medium` (§7.7) and `STAR_LANG` as unset (§7.6), and continues; a read-only skill never creates the file, since its own rule against writing outranks this one. A fresh clone has no `.env`, and reading a plan tree does not require one.
4. **The shell is stateless.** `source activate` does not survive to the next command. Resolve the interpreter once to an absolute path — `$PYTHON_HOME/bin/python`, from §3.2 — and run every command through it. Never system python.
5. **Only `star-env-builder` creates, repairs, or modifies an environment.** No other skill installs or upgrades anything, ever. A tool that is absent (ruff, matplotlib, bibtexparser, pandas) is a **degraded check**: run without it, say so in the report, and route to `star-env-builder`. Installing it to finish your own check is out of bounds.
6. An environment that cannot run python is a **blocker to report**, not a problem to work around.

## 4. Real dates

1. **Every date written into a file comes from the system clock at run time** (`date +%Y-%m-%d`). Never recall a date, never infer one from context, never copy the one in a template or an example.
2. A **fetch date** is the day the fetch happened. A **report date** is the day the report was written. A **backup stamp** is the day the backup was made.
3. A dated file re-generated **the same day** overwrites that day's file; **on a later day** it writes its own. This is what makes a run directory readable as a timeline.

## 5. Plan-name resolution

1. **`PLAN_NAME` matches `metds/plans/*_plan.md`** by slug (`open-vocab-det-seg`), by numeric prefix (`00`), or by full filename; a `metds/plans/…` path counts.
2. **Absent or ambiguous → list the nearest candidates** (prefix + slug + one-line state) and ask one direct question. Never guess which plan was meant.
3. **`parent:` is authoritative; the prefix only hints.** Rebuild the tree from each file's `parent:` frontmatter. The numeric prefix orders and hints the tree for humans — and in projects created before roots took the smallest free digit, two unrelated roots can share a digit.
4. **A leaf is a plan with empty or absent `children:`.** Only leaves are executable.
5. **`depends_on` holds sibling prefixes** and is the machine-readable execution order the executor and `star-flow-status` consume. It stays acyclic and consistent with the parent's `## Sub-plans` index.
6. **Never renumber a prefix.** Every deeper prefix and every `parent:` / `traces_to` reference is built on it.

## 6. Delegation

1. **The main agent decides how the work is split, and delegating is usually the better call.** Work that is bounded, independent, and materially helped by delegation belongs with a delegate rather than in the main context — keeping a large read out of the main agent is the ordinary way to run such a step, not an exception that owes an argument. What earns no delegate is a trivial sequential step: never create one per step of a chain. **Materially helped** has a test: the input is large, the return is small, and what the main agent re-reads afterwards is a spot check rather than the same read again. Where this file or a `SKILL.md` already obliges it to re-open the same evidence — every number re-checked at its cited line, every blocker re-read before it is reported — a delegate moves that read, it does not remove it, and the work belongs at home. **Where the host offers no delegation at all, this item is the whole of §6**: a step that says *dispatch* still owes its contract, and the main agent fills it locally, in the same order and against the same return format. **A step that may fan out names its own size guidance, as a number, in that step** — the size below which reading it in the main agent is the simpler course. Each skill picks its own number, since it depends on what is being read, and the main agent may go either side of it once it can say why; what the number rules out is the unfalsifiable "a large tree".
2. **A delegate is given** its exact file list, the rubric or contract it must return, and its scope stated verbatim ("ONLY these items"). Concurrent delegates hold **disjoint file ownership**, however many there are. **How many run at once is the main agent's call** — size the fan-out to the work, not to a fixed number; the one hard bound is external rather than cautionary: delegates reaching a remote host share one budget per host, so fan-out there is split or serialized (§6.9). **The contract is named in a reference file and enumerates its fields**, ending with "and nothing else". "Returns a filled *<artifact>*" is not a contract: an artifact template carries fields a delegate must not fill — the `model_id` and `model_trail` of a write session it is not (§8), a section the skill reserves to the main agent, a value no step has decided yet.
3. **The main agent owns integration and judgment.** It re-runs every check itself and never trusts a self-reported pass. A delegate never grades the overall verdict. A return that reports its own coverage — files read, plans read, reports read — is read as a claim like any other: **a count below what that delegate was given is the remainder to re-dispatch, not a smaller result.**
4. **A read-only subagent** — the commonest kind of delegate, reading logs, papers, packages, or plans — reads and returns the form it was given, filled in. It writes no files and reads nothing outside its list. One carve-out, and only this one: **a subagent that fetches remote payloads writes them to the run's own cache** — one file per item it was given, under the prefix the skill names — because a fetched record is only re-checkable if the payload is on disk, and only the agent that fetched it holds the bytes. It writes nothing else, and the cache prefixes of concurrent subagents do not overlap.
5. **An implementing delegate may change files, and never runs without a named dispatch contract.** Two skills ship a written one: `star-plan-executor` (`references/agent_dispatch_spec.md`) and `star-code-architect` (`references/orchestration_spec.md`); any other skill that sends a delegate to change files states the same terms in the step that dispatches it, and follows whichever of those two is nearer to the work. Every such contract states the delegate's write surface and ends it with "and nothing outside it"; hand it the absolute interpreter path the main agent already resolved, rather than sending it to re-read `.env`; forbid it to install or repair anything (§3.5 — a missing package is a blocker it returns); require this delegate's files to be clean in git before dispatch, with anything already dirty when the run started named as pre-existing; and restore its files when it fails, so a retry starts from a known tree and no abandoned edit is left for a later commit to stage.
6. **A claim is confirmed before it crosses a confirmation point or causes a write.** Re-running a check (item 3) does not cover this: a delegate reporting a smell at a path, a number at a line, or a stale reference has run no check at all. Before such a claim reaches a question the user answers, or a file the run changes, the main agent opens the cited location and confirms it holds. What does not hold up is dropped, or demoted to something that changes nothing.
7. **An independent-perspective delegate** — one sent to re-read finished work the main agent produced itself — earns its place only when both hold: the main agent's blindness is structural rather than incidental (it cannot see a sentence it never wrote), and the artifact being audited holds up work downstream. Otherwise the main agent checks its own work, and a second opinion is only a hop. This is the one delegate whose reading the main agent still does itself afterwards: a second opinion is the point, not a reading saved.
8. **The involve level reaches delegation too** (§7.7). At `high`, a fan-out is announced with its partition before dispatch; at `low` it runs unannounced. At every level the decisions record (§7.8) names that the run fanned out and how it partitioned — a partition is a judgment call like any other.
9. **A request budget belongs to the host, not to the agent.** The polite rate a skill promises a remote host — `source_policy.md` and `scan_policy.md` each set one — is spent by the whole session against that host, so running N fetchers at once makes the real rate N times higher. A step that fans out fetching either splits the budget by the number of delegates and writes each share as a number in the brief, or fetches one request at a time and says so. Two skills in one session reach the same hosts: a run following `star-idea-storm` has already spent part of the budget it is about to use. The numbers live in the policy files, and steps cite them instead of repeating them — a number copied into a second place is one that drifts.

## 7. Dialogue

The tool-neutral half. **How** to ask — AskUserQuestion, Codex's structured user-input tool, or plain text — is platform-specific and stays in each `SKILL.md`.

1. **Keep each chat reply under about 500 words.** Files written to disk do not count. Detail belongs in the artifact; the reply is the digest.
2. **Ask one question at a time and wait for an explicit answer** before acting on it. Never bundle-approve, never assume a yes. **This holds in headless and scripted runs**: a skill that reaches a confirmation point stops and waits rather than proceeding — see the guide's "Which parts can run unattended?".
3. **Every question carries 2–4 concrete options with the recommendation marked**, and the user may always answer freely outside them. **Each option states its consequence, not its label again**: what choosing it produces or changes, what it rules out, and — where the answer is not plainly undoable — whether it can be reverted and at what cost. "Phase axis" is a label; "splits by the root's §6 stages into a linear chain; re-running the split later overwrites the sub-plan files" is a consequence. Genuinely open questions (an initial research topic) may be asked without options.
4. **Report honestly.** Never round a shortfall up. Never present a check as run when it was skipped or degraded. Never state or imply that a file, a status, or a plan was changed when it was not.
5. **Lead with the outcome**, then the evidence, then the routing to the next skill — which, for the eight skills the agent may start, is the run itself rather than a command printed for someone to type (§10.6).
6. **Reply in the user's dialogue language, unless `STAR_LANG` overrides it.** `STAR_LANG` in `.env` (`en` or `zh`; absent, unset, or any other value → the dialogue language) replaces the dialogue language everywhere a skill picks one: chat replies, localized `*_zh.md`-style resources, templates, and the frontmatter `language` of documents it creates — a Chinese chat with `STAR_LANG=en` gets English replies and English new plans. It never rewrites an existing document: a document's body language follows its own frontmatter `language` (or its source's), **not** the chat's and not `STAR_LANG`'s — a Chinese conversation about an English plan still writes English into that plan. An explicit in-conversation request ("reply in English", "this plan in Chinese") overrides `STAR_LANG` for what it names. Like `INVOLVE` (item 7), it is a one-line `.env` lookup resolved once at the start of the run, even by a skill that needs no runtime and no other `.env` value. That lookup rides in the skill's opening load call — `grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'` first in that call, both values in one grep — and never costs a call of its own. Inside Chinese documents keep technical terms, metric names, venue names, file paths, and everything inside `reference.bib` in English. Code and the comments inside it are English at all times — code is not a document this rule localizes, and no `STAR_LANG` value or dialogue language changes that.
7. **The `involve` level: the user chooses how much is asked.** Every question a workflow poses is one of three kinds. **Mandatory confirmation points** are asked at every level: anything on the STOP line (§2), every question that stops for confirmation before a deletion or an overwrite, every write to user-confirmed content that a named protocol already requires confirmation for (writing an execution change back into the plan, per-item revision approval), the confirmation point a skill places before its side effects, and every ambiguity about what the user meant (§5.2 is the plan-name case). **Judgment calls** — questions item 3 equips with a marked recommendation, where every offered option is safe — are what the level moves. **Derivable details** — anything with a conventional default — are decided silently at every level; they were never questions.

   The user sets the level; the skill **resolves it once at the start of the run**, before the first question, from three sources in precedence order: `INVOLVE` in `.env` (`low` / `medium` / `high`; absent, unset, or invalid → `medium`), then an `involve=<level>` token in the invocation, then plain language mid-run ("ask me less", "ask me everything") — the last instruction wins for the rest of the run. Reading `INVOLVE` is a one-line `.env` lookup, done even by a skill that otherwise needs no runtime and no other `.env` value. A skill that keeps a durable run log records the effective level and its source there once.

   **The token is not an argument.** `involve=<level>` is stripped from the invocation before anything else is resolved — the plan name (§5), the mode, the scope, the date window. This holds in **every** skill, including the ones whose `SKILL.md` never mentions the level: a skill matching its first argument against `metds/plans/*_plan.md` must not see `involve=low` and treat it as a plan name, or match it as a mode word. A skill that accepts no arguments at all still strips it.

   - `medium` — the default: this file and every `SKILL.md` exactly as written. The level adds nothing.
   - `low` — a judgment call is not asked: take the option you would have marked recommended, and log it (item 8). The commit offer is one of them (§1.5), and what it recommends is to commit; the reply still names what was committed. A genuinely open question (item 3) has no recommendation to take, so it is asked at every level — and when unsure which kind a question is, treat it as the more interactive kind.
   - `high` — judgment calls the skill's text batches into one confirmation point, or takes autonomously between confirmation points, are asked one at a time (item 2).

   For every question that is asked, item 2 holds unchanged: the level decides which judgment calls are asked at all, never whether an asked question may be assumed answered.
8. **Decide-then-disclose.** Every run keeps a decisions record — `EXEC_LOG.md`'s "Notes / decisions" where the skill keeps one, otherwise a "Decisions taken" list in the final reply — one line per settled question, as `question → choice → what it set`. At `low` it captures every judgment call taken unasked, and the final reply states that count whenever it is nonzero: `low` moves review after the fact, it never removes it. At `medium` and `high` it captures what the user answered, so a long run's decisions outlive the scrollback and a resumed run can restore them. Lines are appended as questions settle — this is a running record, never a growing recap replayed before each question.
9. **The level tightens per skill; it never loosens.** A `SKILL.md` may declare a judgment call it always asks, or flatten levels that make no sense for it (a coaching skill has no meaningful `low`). No skill treats a mandatory confirmation point as adjustable, and a skill that declares nothing follows exactly the rule above.
10. **Carry the thread.** A user answering a long series of questions loses the thread — what they already settled, and what the current question turns on. Three cheap habits, and deliberately not a recap replayed before every question: that grows with the question count until the user skims it.

    - **Anchor the question.** A question that depends on an earlier answer names it in one clause — "phase axis → 4 units; now: which one owns the data leaf?". One line, carrying only the decisions this question actually rests on, never the whole history.
    - **Recap at boundaries, not between questions.** At each stage, step, or section end — where the user is already pausing — restate in 2–3 sentences what was decided, what it produced (the file written, the field set), and what it opens next. Fixed cost per boundary, however many questions the boundary took.
    - **Name the way back.** When a boundary closes something the user can still change, say how: the skill and argument that reopens it, and what reopening costs. A user who knows a decision is cheap to revisit stops trying to hold every decision in their head.
11. **Write the action, not its name.** The reader should never have to decode a term to know what happened, so a name that must appear brings its meaning with it, in the same sentence. It governs the prose a run writes into files as much as chat, and stops at structure: headings, table columns, field names, and every literal a skill matches byte-exactly stay verbatim, with any explanation beside them rather than in place of them. Orthogonal to item 6 — that one picks the language, this one the wording inside it, so a Chinese reply does not translate technical terms, metric names, or paths to satisfy it.

    **A literal that is nothing but a pointer makes that explanation mandatory in chat.** `§4`, `C4`, `Step B1`, a run name, a plan prefix — to a reader who has lost the thread none of them mean anything, so in a chat reply each one stays verbatim and takes 3–8 words of what it points at, in parentheses, the first time that reply uses it: `§4 (the experiments section)`, `C4 (the pre-training diagnostic predicts the gain)`. First use in **each** reply, not once per conversation — someone reading the message in front of them does not scroll back to recover what `C4` was. Later uses inside the same reply stand alone, and a label with no room for it — a question option's title, a table cell — carries the gloss in the line under it. In the prose written into files the sentence above governs unchanged: the explanation goes beside the pointer where it first matters, not at every mention.

## 8. The output table

Every skill's durable output, in one table. `star-flow-status` reads this as the contract for its coverage checks: a stage is "covered" when the artifact below exists and its state field is current. Keep the table honest — a skill that changes what it writes updates this row in the same commit, or the status skill silently stops checking that stage.

| Stage | Producer | Path | State field |
|---|---|---|---|
| Adoption | `star-proj-adopt` | `metds/adopt.md` | `adopted:`, `backfilled:` |
| Idea | `star-idea-storm` | `metds/ideas/<slug>_idea.md` | `finalized:` |
| Refs | `star-refs-reviewer` | `metds/refs/refs_index.md`, `<ABBREV>.md`, `reference.bib`, `related_work.md`, `<slug>_survey.md` | index presence |
| Codebase | `star-code-architect` | `metds/codearc.md` | presence |
| Env | `star-env-builder` | `wkdrs/env_<name>_<date>/ENV_REPORT.md`, `freeze.txt` | date in dir name |
| Plan | `star-plan-coach`, `star-plan-decomposer`, `star-plan-reviser` | `metds/plans/<prefix>_<slug>_plan.md` | `status:`, `finalized:`, `updated:` |
| Run | `star-plan-executor` | `wkdrs/<run>/EXEC_PLAN.md`, `EXEC_LOG.md` | plan `exec_status:`, `exec_runs:`; the log's `branch:` / `merged:` (§11) |
| Code review | `star-code-reviewer` | `wkdrs/<run>/CODE_REVIEW_<date>.md`, else `wkdrs/reviews/code_<scope>_<date>.md` | date in filename |
| Plan review | `star-plan-reviser` | `wkdrs/<run>/REVIEW_<date>.md`, else `wkdrs/reviews/<prefix>_<slug>_<date>.md` | date in filename |
| Analysis | `star-expt-analyst` | `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`, `wkdrs/<run>/analysis/` | date in filename |
| Results table | `star-expt-analyst aggregate` | `wkdrs/results/results.md`, else `wkdrs/results/results_<slug>.md` when scoped | `generated:` |
| Digest | `star-expt-digest` | `wkdrs/digests/EXPT_DIGEST_<date>.md` | `covers:`, `sources:` |
| Model record file | `star-expt-digest ledger` | `wkdrs/digests/MODEL_LEDGER.md` | `generated:` |
| Method docs | `star-metd-summarize` | `metds/{overview,framework,dataset,training,evaluation}.md` | `generated:`, `sources:` |
| Release | `star-code-release` | `README.md`, `wkdrs/release/RELEASE_<date>.md` | the README's provenance marker (date + `sources:`) |

**Every artifact records the model that wrote it.** Each producer writes `model_id` into what it creates — a frontmatter key where the artifact has frontmatter, and the header line where it does not (`CODE_REVIEW`, `REVIEW`, `refs_index.md`, `UPSTREAM.md`, and `README.md`, whose header line is an HTML comment because GitHub would render frontmatter as a table at the top of the page). The value is the model id the runtime reports for the writing session, copied verbatim — and the runtime does report it: it is stated in your session context, by a STAR `SessionStart` hook and, in Claude Code, by the system prompt. Where that line is missing, or carries a recovery command in place of an id, `model_id_spec.md` holds the per-runtime fallback — run it before writing `unrecorded`, which is for a session that names no model anywhere. Never infer it from behavior, never reason about which model this is "probably", and never copy one artifact's value into another.

Two limits matter, because this field will be used to compare work across models:

1. **It is self-reported, not verified.** It records what the runtime claimed at write time. A model switched mid-session may still be described by the pre-switch string, so a value can lag reality. Treat it as evidence about provenance, not proof of it.
2. **It describes one write, not a file's whole history.** For a write-once artifact — every dated report, and every compiled document, since those are regenerated wholesale — those are the same thing. For a plan, which several skills and several models edit over months, the frontmatter names only the most recent writer; the per-edit record is the `## Revision History` entry, which carries its own model id.

**And `model_trail` records the flow across writers.** `model_id` names one write; several artifacts are written across many sessions — a leaf executed over four days, a `refs_index` grown paper by paper, a plan revised for months — and there a single field describes only the last one. So every artifact also carries an append-only `model_trail`: one entry per write session, `{ date, model, skill, scope }`, where `scope` names what that session wrote in the file's own vocabulary (steps, sections, entries). Append, never rewrite a past entry, and keep `model_id` mirroring the last entry so a plain grep still works. A wholesale regeneration — a compiled document — starts a fresh trail with one entry recording that it replaced the previous generation, since its content is entirely new.

Where an artifact already has per-event rows, those carry the model too and are finer than the trail: a plan's `## Revision History` entry, the `model` column of an `EXEC_LOG` step table, the `Model` column of `refs_index.md`. Prefer them when reading — they say which *step* or *entry* a model wrote, not merely which session.

`star-expt-digest ledger` rolls every trail into `wkdrs/digests/MODEL_LEDGER.md`, the one place the whole flow is visible at once. It is generated, never hand-maintained: to correct a row, fix the trail it came from and regenerate. Because it is compiled from self-reported trails, it inherits their limit — and, being counts of write events, it carries no quality signal at all. More writes is not better work.

**One exception.** In its `backfill` phase, `star-proj-adopt` may write `exec_status:` and `exec_runs:` — and nothing else — onto leaves in `metds/plans/`, each leaf individually confirmed by the user. Those two fields are the Run row's state, and adoption is the one case where the work they describe happened before any plan existed to record it. Every other part of a plan file, in both of adoption's phases, stays with the producers named in the Plan row.

Two properties of this table matter more than its contents:

1. **`sources:` on a compiled document records each source plan's `updated` as it was when read.** That is what makes staleness detectable by exact comparison rather than by file mtime, which moves for unrelated reasons.
2. **Nothing enforces this table.** `star-flow-status` ends its report with a count of report-shaped files matching no row here, which turns a drifted convention into a visible line rather than a silent under-report.

## 9. Project layout

Where a skill puts what it writes. Each destination is exclusive — a file belongs to exactly one, chosen by what the file *is*, not by which step produced it.

| What | Where |
|---|---|
| Project code | `${CODE_NAME}/` (from `.env`) |
| Data | `datas/` |
| Model weights | `inits/` |
| A run's artifacts, execution records, reports | `wkdrs/<run>/` |
| Cross-run compilations | reserved `wkdrs/` subtrees: `reviews/`, `results/`, `digests/`, `release/`, `env_*`, `ideas_*`, `refs_*` — never reuse these as a run name |
| Plans, notes, method docs | `metds/` |
| What earlier sessions learned, owned by no other file | `.star/memory/`; machine-specific facts in `.star/memory/local/`, which git ignores (`memory_spec.md`) |
| Project documentation | `docs/mds/<topic>/`, `docs/htmls/`, `docs/srcs/` (`docs/mds/star-workflow/` is upstream-managed) |
| Plan-owned tool scripts, plan-execution scratch | `tasks/<plan-name>/` |
| Run entrypoint | `execs/run.sh` |
| Reusable launch scripts | `execs/scpts/<run>.sh` |

Two rules the table alone does not carry:

- **`execs/` root is closed.** It holds `run.sh` and `update.sh` and nothing else. A new `.sh` goes to `execs/scpts/`; anything that is not a launch script does not go to `execs/` at all.
- **`tasks/<plan-name>/` holds two kinds of file, and only one is disposable.** A **plan-owned tool script** — the leaf's own verification, indexing, or data-prep tooling, the kind a §5 done-criterion actually runs — is durable: it is neither project code nor a launcher, it lives here for the life of the plan, and finalize never deletes it. Everything else is **scratch**, and belongs here only if losing it at finalize costs nothing. Generated artifacts are neither: an output worth citing, or a config that reproduces a run, goes to `wkdrs/<run>/`.

## 10. The skill roster

Fifteen skills, invoked as `/star-<name>` in Claude Code, Cursor and Qwen Code, `$star-<name>` in Codex, `/skill:star-<name>` in Kimi Code. What each one does in full is [research-workflow-skills.md](research-workflow-skills.md); what each one writes is §8.

| Skill | Role |
| --- | --- |
| `star-proj-adopt` † | adopt an already-started project into the workflow |
| `star-idea-storm` † | turn a vague interest into a defensible topic |
| `star-plan-coach` † | write the top-level research plan |
| `star-refs-reviewer` | build the related-work base and the bib |
| `star-code-architect` † | bootstrap or reorganize the codebase |
| `star-env-builder` | build and verify the Python runtime |
| `star-plan-decomposer` † | split a plan into executable sub-plans |
| `star-plan-executor` | execute one leaf sub-plan |
| `star-code-reviewer` | review code against the conventions and the plan |
| `star-expt-analyst` | score a run against its done-criteria |
| `star-expt-digest` | summarize the programme's recent progress |
| `star-plan-reviser` † | revise one plan against its execution evidence |
| `star-flow-status` | read-only status and the one next action |
| `star-metd-summarize` | compile the plans into method documents |
| `star-code-release` † | prepare the repository for release |

1. **The seven marked † are slash-only.** Run them only when the user names them: each sits on a decision that belongs to the researcher — which repository to adopt, what to study, what the plan says, how it splits, how it is revised, what the code is built on, what gets published — and a decision reached on an agent's own initiative is a decision nobody made. `star-code-architect` earns the mark twice over: which reference implementation the project starts from shapes everything built on top of it, and its trigger — no `metds/codearc.md` — fires about once in a project's life, so taking it unasked saves nobody anything. This table is the source of truth; the guards enforcing it are `disable-model-invocation: true` in the Claude, Cursor, Kimi and Qwen Code manifests and `allow_implicit_invocation: false` in `.agents/skills/<name>/agents/openai.yaml` for Codex, and CI checks all five against these markers in both directions — a † whose guard is missing, or a guard on a skill carrying no †, fails the build.
2. **The other eight may be picked up by the agent** when the task plainly matches. Being picked up changes nothing about how that run then behaves: the STOP line (§2), the commit offer as the level resolves it (§1.5), every deletion or overwrite, and every mandatory confirmation point (§7.7) hold exactly as they do when the user typed the name. The involve level is unaffected in both directions — it moves judgment calls, never confirmation points, and it never moves whether a skill may start itself.
3. **An unresolved target is not picked up.** §5.2 already forbids guessing which plan was meant; a run nobody asked for extends that rule — where the leaf, the run directory, or the scope is not settled by the files themselves, name the candidates and ask instead of starting.
4. **One skill per invocation, and one unit of work inside it.** One leaf, one run, one report — a run that quietly widens its scope is the failure this rule exists for, and it is worse in a run the user did not start, where there was no stated scope to widen from. The next unit is the next invocation.
5. **A run the user did not start says so** — one line before it begins, naming what matched and which target it took, and one line in the decisions record (§7.8) when it ends, in that record's shape: `what matched → what ran → what it wrote`. "Don't start things yourself" is an instruction like any other, and holds for the rest of the session.
6. **A named next action is taken, not printed, when it names one of the eight.** Skills end by naming what comes next — the status skill's single next action, a reviewer routing a feature gap, an analysis that leaves the results table stale — and today each of those is a command handed to the reader. Where the named command is one of the eight and its target is already settled, run it instead of printing it: the reader is the agent, and a command printed to itself is a handoff to nobody. The seven keep the printed command, because typing it *is* the decision they exist to leave with the user. **A reply that names both kinds is not one list.** A run often ends naming a STOP-line command (§2) *and* one of the eight — a review named above an awaiting heavy command is the standing pair. Ownership is per command, not per block: the STOP-line one is printed and waits for the user, the pickable one runs, and standing beside a command only the user may clear does not make it one of those. Where the two carry an order, running the first is what makes the order real — a review merely printed above the awaiting command leaves the sequence to whoever reads faster, and a defect found after the compute costs the compute and the re-run both. A skip the skill itself offers stays an offer, asked before either one runs. Two limits, and they are what make this safe. **The pickup happens after the run ends, never inside it**: a skill that may not write, dispatch, or leave its own scope gains none of that by naming a successor, so a read-only reporter stays read-only and the successor starts once its own run is over. And **the run that follows is bound by items 3 to 5 exactly as any other pickup is** — an unsettled target is asked about rather than guessed, one unit of work, and it says what it is doing before it begins.

## 11. Execution branches and worktrees

The one exception to §1.3's no-branch-switches rule. A leaf whose execution would modify files the codebase already has runs on its own branch, so the base branch keeps a tree those changes have not touched until they earn their merge. Only `star-plan-executor` creates one — at its Step 4 confirmation point, never silently — and only for its own run; the mechanics live in its `references/branch_rules.md`, and this section is the contract every skill can rely on. Items 1–6 are the branch; items 7–9 are the worktree that houses a run when the invoking checkout is busy.

1. **The gap list decides the recommendation.** An EXEC_PLAN action that **modifies** a pre-existing tracked file under `${CODE_NAME}/` → recommend the branch; a plan that only adds new files, or writes only `tasks/<plan-name>/` and `wkdrs/<run>/`, stays on the base branch. Diff size is argument, never trigger. The user settles it either way at the confirmation point, and choosing the branch also chooses per-step checkpoint commits — a branch with nothing committed has nothing to merge.
2. **Name, base, records.** The branch is named for the run, `<run>`, so branch and `wkdrs/<run>/` pair by name; it forks from whatever branch the checkout was on at approval — never assumed to be `main` — and `EXEC_PLAN.md` / `EXEC_LOG.md` frontmatter record `branch:`, `base:`, and later `merged:`. On the branch, each step's commit also stages the run records it updated (the log row, the sub-plan's status), because only commits merge. A listing sweep can only match that name's shape, so a branch no leaf and no run record claims is not an execution branch — leave it alone.
3. **The base branch stays canonical.** Until the merge, everything the run wrote exists only on the branch, so read from the base branch the leaf is simply not done yet — which is the correct reading, not a gap: a dependent whose `depends_on` sibling sits unmerged stays blocked, and merging the sibling is what unblocks it. `star-flow-status` lists execution branches, so an unmerged run reads as a pending contribution rather than lost work.
4. **The merge is a mandatory confirmation point** (§7.7), asked at every involve level. It is reached when the leaf's `exec_status` is `done` and no unsettled blocker/major finding stands in the run's newest code review — for a leaf with heavy experiments, `done` already contains their outputs, run from the branch checkout. Default is a squash merge — the base branch stays linear, one commit per leaf, the per-step story stays in `EXEC_LOG.md`; keeping the step commits is the stated alternative. After merging, re-run the leaf's light checks (§2) on the base branch; the branch's deletion is then its own question, a deletion like any other.
5. **Sync by merging the base branch in, never by rebase.** When the base branch has moved, merge it into the execution branch and re-verify before merging back; §1.3's ban on history rewrites holds on execution branches too. A conflict stops the run: name the conflicted files and hand resolution to the user — never resolve one silently.
6. **A discard rescues the records first.** Before an unmerged branch is deleted, its `wkdrs/<run>/*.md` records — and the sub-plan's run entry, with the verdict that ended it — are committed to the base branch: a negative result is evidence `star-plan-reviser` and `star-expt-digest` still need, and deleting a branch must never delete it. The deletion itself is asked at every level.
7. **A worktree answers a different question: the checkout is busy.** The branch isolates history — which commits belong to this run; a worktree isolates disk — how many file trees exist at one moment. Modifying pre-existing files calls for the branch (item 1); a checkout that is not free right now calls for a worktree. The busy signals: HEAD sits on another run's execution branch; uncommitted changes on paths that belong to another run; a run's log records commands handed back whose results are not yet collected — a job may be running, which cannot be probed, so ask the user; or the user names parallel work outright. No signal → the run stays in the invoking checkout and nothing else in this section changes. Creating the worktree is a discretionary question (§7.7) asked at the same confirmation point as the branch, with the signals giving the recommendation; removing one deletes every untracked file inside it, so removal is a deletion, asked at every level.
8. **A run in a worktree always carries a branch; tree, branch, and run directory share the run's name.** Commits made in the tree need a home of their own while the base branch stays checked out elsewhere, so a plan whose gap list said `branch: none` switches to `branch: <run>` the moment it moves into a tree. Creation is one command, run from the invoking checkout: `git worktree add ../<root-dirname>--wt/<run> -b <run> <base>` — tree, branch, and fork point in one step; the tree's absolute path is recorded as `worktree:` in EXEC_PLAN / EXEC_LOG frontmatter, and that field is how any later session finds the run's home. Git materializes only tracked files, so after creation link `.env`, `datas/`, `inits/` (and `.star/memory/local/` where present) from the main checkout — and never link `wkdrs/` or `tasks/`: they contain tracked files, and linking the directory would replace them with a single symlink in git's eyes. The merge happens in whichever tree has the base branch checked out — normally the invoking checkout; if the user has switched it away, say so and ask.
9. **Before removal, move the artifacts out.** Non-md untracked artifacts under the tree's `wkdrs/<run>/` and `tasks/<plan-name>/` exist nowhere else, and `git worktree remove` deletes them with the tree. The order is fixed: merge (or the record rescue of item 6) → move those artifacts to the same paths in the main checkout → `git worktree remove` without `--force` — git refuses while stray files remain, and that refusal is the safety net, not an obstacle to override → the branch's deletion is then its own question. A tree directory deleted by hand is a blocker to report; `git worktree prune` clears the stale metadata, and the tree is never silently rebuilt.

What this asks of everyone else is small. A skill about to commit while the checkout sits on an execution branch that is not its own target says so and offers to switch back first — an unrelated commit made there rides into that leaf's merge. Nobody switches a checkout something is still running from: a live job re-reads its files mid-run — which is exactly the situation item 7 sends the new run into a worktree for. Worktrees are created and removed only by `star-plan-executor`, each at its named confirmation point; a user who prepares one themselves and invokes the executor inside it stays supported — skills act on the checkout they are invoked in. A run's home is its frontmatter's `worktree:` field, and a skill working on that run (review, analysis) works in that tree.
