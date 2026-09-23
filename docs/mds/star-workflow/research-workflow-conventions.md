# Research Workflow Skill Conventions

The rules every STAR research workflow skill follows. The fifteen skills (§10 lists them) each carry their own workflow, limit on what they may write, and rubric. What they share lives here, once.

**Precedence.** Follow the active instruction hierarchy. Within user-controlled workflow files, an explicit user instruction or existing authorization for this task overrides a skill default. This file owns shared scope, authority, evidence and provenance rules; a skill states only its task-specific constraints and explicit exceptions. Stricter wording alone does not revoke authorization or override a documented exception. A confirmation point needs a new answer only when the relevant decision or authority is still missing.

This file is both conventions for the skills and a description for the reader: what the workflow will and will not do to your repository.

**Adapter boundary.** §0–§12 define behavior shared across harnesses and name none. Concrete invocation spelling, tool parameters, hook events and configuration mechanics live in §13 (harness adapters) and the corresponding harness manifests; they implement these rules without changing scope, authority or artifact ownership.

## 0. Vocabulary

Terms this file and every `SKILL.md` use without re-explaining. Each is defined in full where the "Defined in" column points.

| Term | In one clause | Defined in |
|---|---|---|
| top-level plan | the plan `star-plan-coach` writes, covering problem through milestones | §5, §8 |
| done-criterion | a leaf's §5: the binary test that decides whether its run succeeded | the guide, §5 of each leaf |
| kill-criterion | a root plan's §5: the result that says stop pursuing this direction | `star-plan-coach` |
| `finalized:` | set by the coach when all six sections are `done` or `skipped` and the rubric has been run and answered; three skills wait on it — `star-plan-decomposer`, `star-code-architect`, `star-metd-summarize` | §8 |
| `exec_status:` | a leaf's execution state; `done` and `abandoned` are final: nothing more is needed on that leaf | `status_spec.md` |
| `dropped:` | a plan node given up on, written once where the decision was made and inherited by its whole subtree: outside every count and every recommendation, its record kept — its files moved aside under `dropped/` directories (§9) | `status_spec.md` |
| `traces_to` | which claim in the root plan this sub-plan supports | `star-plan-decomposer` |
| too big to run | a plan that cannot be executed as it stands — §3/§5 largely `[TBD]` / `【待定】`, or finalized but never decomposed | `status_spec.md` |
| outline unit | a unit the parent's `## Sub-plans` keeps as one marked line — `- (outline)` / `- （概要）` — with no file and no prefix until execution reaches it and it is expanded | `star-plan-decomposer` |
| backfill | `star-proj-adopt`'s second phase, recording work finished before any plan existed | §8 |
| follow-up checks | `star-flow-status`'s checks on finished work whose review, analysis, or write-up is missing or out of date | `status_spec.md` |
| summary counts | a parent's progress counted up from its children | `status_spec.md` |
| plan-level finding | a result that changes the plan itself, not just the leaf that produced it | `star-plan-reviser` |
| last covered date | the newest digest's `covers.through`, where the next digest starts | `star-expt-digest` |
| the step's own check | the check an `EXEC_PLAN` step binds to itself, run before that step counts as done | `star-plan-executor` |
| execution branch | the branch — named `<run>`, like the run itself — a leaf's changes live on until the merge confirmation point clears them into the base branch | §11 |
| worktree | a second checkout of the same repository, housing a new run while the invoking checkout is busy; created and removed only by `star-plan-executor` | §11 |
| claim | what a plan asserts and a sub-plan supports; also an unchecked statement in a log or a return | §6.6 |
| fallback | the route a plan takes when its first approach fails | `star-plan-coach` |
| gap list | what the code holds now against what the leaf requires, before step one | `star-plan-executor` |
| runnable check | evidence the environment runs: imports, framework and GPU, entrypoint | `star-env-builder` |
| what it may write / dispatch brief | the paths a skill or a delegate may create or edit; for a delegate, the terms stating them before it starts | §6.5 |
| fan-out | delegates dispatched at once, on disjoint files, one request budget per host | §6.2, §6.9 |
| record | the log line a step earns once its check passes; also a fetched source entry | `star-plan-executor`, §6.4 |
| downgrade (a finding) | evidence too thin for the severity claimed, so the finding drops one severity level | `star-code-reviewer` |
| per-step / per-phase commits | one commit per verified action or finished phase, never one at the end | §1, §11.1 |
| the output table | every skill's durable output, its path and its state field | §8 |

## 1. Git

**Skills that never commit** — git usage is read-only (`status` / `diff` / `log`, plus `branch --list`, `worktree list` and `show` for reading an execution branch, §11): `star-flow-status`, `star-refs-reviewer`, `star-expt-analyst`, `star-expt-digest`, `star-metd-summarize`.

**Skills that may commit**, and what each may stage:

| Skill | Commits | Stages |
| --- | --- | --- |
| `star-proj-adopt` | offered once at the end of each phase | only the paths that phase wrote; in an adopted repository, pre-existing uncommitted work is named, never bundled |
| `star-idea-storm` | offered once when the session ends | the idea file this session created or edited |
| `star-plan-coach` | offered once when the session ends | the plan files this session created or edited |
| `star-plan-decomposer` | offered once at the end of the run | the sub-plans written plus the parent's updated index |
| `star-plan-reviser` | offered once at Step 7, when edits were applied | the target plan, plus the parent when its `## Sub-plans` line changed; on a drop or revival, also the moved subtree paths, and on a drop the root plan's dead-end line |
| `star-code-architect` | one per finished phase or verified migration group | `${CODE_NAME}/` and the spec files it owns |
| `star-env-builder` | at most one per run | `${CODE_NAME}/requirements*` only |
| `star-plan-executor` | one per verified action when per-action commits were chosen (recommended; `low` takes it, §7.7, §11.1); plus §11's execution-branch operations — creation as a routine choice (§7.7), merge and discard each at its own confirmation point (§11.4, §11.6) | the files that action touched; on an execution branch, also the run records those actions updated (§11.2) |
| `star-code-reviewer` | one optional commit after the fix pass | only the files the fix pass touched |
| `star-code-release` | one per finished phase (gather / polish / readme) | only that phase's paths: the promoted files plus the call sites their move broke, the polish-pass files, `README.md` |

**Universal rules:**

1. **Stage only what this run created or edited.** Never `git add -A`, never `git add .` — a blanket add sweeps in checkpoints and scratch.
2. **The message prefix is the skill's own name**: `star-plan-executor: <run> step 2 — <summary>`, `star-plan-coach: <slug> — <milestone>`. One skill, one prefix, so the log separates by skill.
3. **No pushes, no history rewrites** (`rebase`, `amend`, `reset --hard`), **no tag creation — and no branch switches** outside the execution branches §11 defines, which `star-plan-executor` creates as a routine choice (§7.7) and merges or discards only at their named confirmation points. The user owns the branch and the remote.
4. **A path that already carried uncommitted changes when the run started is never staged.** Name those paths in the commit offer — or, at `low`, in the final reply — so the user can commit or stash them first.
5. **Record each authorized commit.** At `medium` or `high`, ask when commit authority is missing; at `low`, the in-scope commit recommendation is taken and logged. Never ask again for the same approved commit scope. Snapshot `git status` at the start and exclude paths already dirty. The final reply identifies commits made.
6. **Never force-add an ignored path.** `.env`, `datas/`, and `inits/` are git-ignored by default and stay out of history. `wkdrs/` is **not** wholly ignored: everything under it is ignored *except* `*.md`, so the workflow's own reports — exec logs, analyses, digests, reviews, the results table — are versionable on purpose, and a run's record outlives the machine that made it. `tasks/` is tracked in full: a plan's tool scripts are durable by design, and the scratch beside them too small to warrant an exception.

**The guard.** Every harness tree ships a `star_commit_guard.sh` hook declining the rule-breaking commands whose break is expensive to undo: blanket or forced staging (`add -A`, `add .`, `add -u`, `add -f`, `commit -a`), the history rewrites rule 3 names (`commit --amend`, `rebase`, `reset --hard`, `filter-branch`, `filter-repo`), the forced branch and worktree operations that break §11 in one keystroke (`branch -D`/`-f`, `switch -C`/`-f`, `checkout -B`/`-f`, `worktree remove --force`), and any commit whose staged files exceed 10 MB. `push` is deliberately absent. It also declines the launch of a prepared STOP-line command — `execs/scpts/<run>.sh` in command position, or a write to the `wkdrs/<run>/.await` marker — while `wkdrs/<run>/` holds no `CODE_REVIEW_<date>.md` or its newest one is dated before the newest date in `EXEC_LOG.md` (§2). The guard is a last check behind the prose, never a replacement — it reads one shell line at a time and answers with silence anything it cannot read confidently. What it declines is the user's to run.

## 2. The STOP line

Skills may write code and run **light validation** within the requested scope. Heavy, costly or irreversible work requires specific authority: prepare the command, its outputs and known cost before asking for what remains unapproved. A prior explicit instruction to run that command, with its resource scope understood, satisfies that confirmation; permission for surrounding implementation alone does not. A `star-auto` invocation (§10.7) also authorizes prepared heavy commands within its goal and `stop=` boundary; an absent `stop=` retains that invocation's uncapped grant. Log each launch and stated cost (§7.8). A command whose cost or compliance with a stated limit cannot be judged is handed back. The auto grant excludes destructive operations except the guarded clean worktree removal explicitly defined in §11.4.

**Light — a skill may run it:**

- Unit tests and runnable checks, import checks, `python -m compileall`, a forward pass on a tiny batch.
- Small-scale, **no-finetune** inference on a small subset.
- Dry runs, config validation, shape/dtype checks, a few-step overfit sanity run.
- Anything that finishes in **minutes on modest resources** and writes only where the skill is allowed to write.

**Crosses the STOP line — hand it to the user:**

- **Long or multi-GPU training or fine-tuning** — any full training run.
- **Full-dataset evaluation** that takes hours or significant compute.
- **Costly API calls** — large-volume LLM/VLM inference billed per call.
- **`sudo` or a system package manager** (apt, brew), driver or CUDA-toolkit system installs, and **CUDA source compilation** (flash-attn-style builds).
- **Deleting any environment**, and overwriting artifacts the user may want to keep.
- Anything whose cost or runtime **cannot be bounded or assessed against the user's authorization**. Obtain the missing information or hand back the prepared command.

Download-size thresholds are **skill-specific** — `star-env-builder` runs framework-scale downloads once its install plan is approved; `star-code-architect` hands anything over ~1 GB back. Each skill states its own; this list is what crosses regardless.

**How to hand off.** Give the user the exact command, invoked through the `.env` environment (§3) and the project's launch entry point (`execs/run.sh`) where one exists; say what it produces and where, and what output to bring back so the criterion can be verified. Writing the command into a runnable script is light; running it is not. The launch guard (§1) holds the order the executor's report states: the prepared command, `execs/scpts/<run>.sh`, is declined — under `star-auto` too — until the run's review exists and is no older than its log; a declined launch names `star-code-reviewer` as what comes first, not a failure to retry.

## 3. `.env` and the project runtime

The operational form of `AGENTS.md` §9.

1. **`.env` at the project root is the only source** of `CODE_NAME`, `ENV_NAME`, `CONDA_HOME`, and `PYTHON_HOME`. Never guess a local path, never hardcode one, never read them from memory of another project.
2. **`PYTHON_HOME` is authoritative.** Set → use it as given; `CONDA_HOME` and `ENV_NAME` may be empty, the interpreter then running directly rather than through conda. Empty → derive it as `$CONDA_HOME/envs/$ENV_NAME`, which requires both. Neither → a blocker to report, not a value to invent.
3. **Missing `.env`** → a skill that needs the interpreter creates it from `.env.example`, asks the user to fill the machine-specific values, and stops until they do. Never invent a value to keep going. **This binds only skills about to run something.** A skill that needs no runtime — a status report, a plan edit, a survey — notes the absence, treats `INVOLVE` as `medium` (§7.7) and `STAR_LANG` as unset (§7.6), and continues; a read-only skill never creates the file, since its own rule against writing outranks this one.
4. **The shell is stateless.** `source activate` does not survive to the next command. Resolve the interpreter once to an absolute path — `$PYTHON_HOME/bin/python`, from §3.2 — and run every command through it. Never system python.
5. **Only `star-env-builder` creates, repairs, or modifies an environment.** No other skill installs or upgrades anything, ever. A tool that is absent (ruff, matplotlib, bibtexparser, pandas) means **a partial check**: run without it, say so in the report, and route to `star-env-builder`. Installing it to finish your own check is out of bounds.
6. An environment that cannot run python is a **blocker to report**, not a problem to work around.

## 4. Real dates

1. **Every date written into a file comes from the system clock at run time** (`date +%Y-%m-%d`). Never recall a date, never infer one from context, never copy the one in a template or an example.
2. A **fetch date** is the day the fetch happened. A **report date** is the day the report was written. A **backup stamp** is the day the backup was made.
3. A dated file re-generated **the same day** overwrites that day's file; **on a later day** it writes its own.

## 5. Plan-name resolution

1. **`PLAN_NAME` matches `metds/plans/*_plan.md`** by slug (`open-vocab-det-seg`), by numeric prefix (`00`), or by full filename; a `metds/plans/…` path counts. A dropped plan matches the same way from `metds/plans/dropped/`, where its drop moved it (§9).
2. **Resolve the target from the explicit argument and current task context.** If it remains absent or ambiguous, list the nearest candidates (prefix + slug + one-line state) and ask one direct question. A target already identified by the user or the active authorized run needs no repeated selection. Never guess between materially different plans.
3. **`parent:` is authoritative; the prefix only hints.** Rebuild the tree from each file's `parent:` frontmatter. The numeric prefix orders and hints the tree for humans — and in projects created before roots took the smallest free digit, two unrelated roots can share a digit.
4. **A leaf is a plan with empty or absent `children:`.** Only leaves are executable.
5. **`depends_on` holds sibling prefixes** and is the machine-readable execution order the executor and `star-flow-status` consume. It stays acyclic and consistent with the parent's `## Sub-plans` index. An outline unit (§0) has no prefix and never appears in `depends_on`: it enters the graph only once expanded into a file. A prefix is satisfied by a sibling leaf with `exec_status: done`, or by a sibling internal node whose live (not dropped) leaves are all terminal, at least one of them `done`, with no outline line left in any `## Sub-plans` index of its subtree.
6. **Never renumber a prefix.** Every deeper prefix and every `parent:` / `traces_to` reference is built on it.

## 6. Delegation

1. **Delegate bounded, independent work when it materially helps.** The main agent chooses the partition and concurrency; small sequential or tightly coupled work stays local. Delegation earns its cost when the input is large, the return small and integration does not repeat the whole task. Item 7 separately covers a useful independent review. Respect the host's delegation policy: an authorized skill step may satisfy a policy requiring a request, but never an outright ban. With no permitted delegation, perform the work locally and disclose the missing independent perspective where relevant; do not ask for a tool the host cannot provide. Size guidance in a skill is a default, not a quota.
2. **A delegate is given** its exact file list, the rubric or format it must return, and its scope stated verbatim ("ONLY these items"). Concurrent delegates **never share a file**, however many there are. **How many run at once is the main agent's call** — size the fan-out to the work, not to a fixed number; the one hard bound: delegates reaching a remote host share one budget per host, so fan-out there is split or serialized (§6.9). **The return format is named in a reference file and enumerates its fields**, ending with "and nothing else". "Returns a filled *<artifact>*" is not a return format: an artifact template carries fields a delegate must not fill — the `model_id` and `model_trail` of a write session it is not (§8), a section the skill reserves to the main agent, a value no step has decided yet.
3. **The main agent integrates the returns and owns acceptance.** Inspect the changed artifacts and independently verify check evidence: the actual command, exit status or raw result, scope and code version must support the claim. Re-run when evidence is unavailable or uncertain, integration changed the checked behavior, or a required acceptance check remains. Do not repeat an unchanged check solely because a delegate ran it. A delegate never grades the overall verdict. Account for every assigned file through reviewed coverage, explicit unknowns or a follow-up read.
4. **A read-only subagent** — the commonest kind, reading logs, papers, packages, or plans — returns the form it was given, filled in. It writes no files and reads nothing outside its list. One exception only: **a subagent that fetches records from the web writes them to the run's own cache** — one file per item it was given, under the prefix the skill names — because only the agent that fetched a record holds the bytes. It writes nothing else, and the cache prefixes of concurrent subagents do not overlap.
5. **An implementing delegate may change files, and never runs without a named dispatch brief.** Two skills ship a written one: `star-plan-executor` (`references/agent_dispatch_spec.md`) and `star-code-architect` (`references/orchestration_spec.md`); any other skill sending a delegate to change files states the same terms in the dispatching step, following whichever of the two is nearer to the work. Every such brief states what the delegate may write and ends it with "and nothing outside it"; hand it the absolute interpreter path the main agent already resolved, rather than sending it to re-read `.env`; forbid it to install or repair anything (§3.5 — a missing package is a blocker it returns); require its files to be clean in git before dispatch, with anything already dirty when the run started named as pre-existing; and restore them when it fails, so a retry starts from a known tree.
6. **A claim is confirmed before it crosses a confirmation point or causes a write.** Re-running a check (item 3) does not cover this: a delegate reporting a suspicious pattern at a path, a number at a line, or a stale reference has run no check at all. Before such a claim reaches a question the user answers, or a file the run changes, the main agent opens the cited location and confirms it holds. What does not hold up is dropped, or demoted to something that changes nothing.
7. **An independent-perspective delegate** — one sent to re-read finished work the main agent produced itself — earns its place only when both hold: the main agent's blindness is structural, not incidental (it cannot see a sentence it never wrote), and the audited artifact holds up work downstream. Otherwise the main agent checks its own work. This is the one delegate whose reading the main agent still does itself afterwards: a second opinion is the point, not a reading saved.
8. **The involve level reaches delegation too** (§7.7). At `high`, a fan-out is announced with its partition before dispatch; at `low` it runs unannounced. At every level the decisions record (§7.8) names that the run fanned out and how it partitioned — a partition is a judgment call like any other.
9. **A request budget belongs to the host, not to the agent.** The polite rate a skill promises a remote host — `source_policy.md` and `scan_policy.md` each set one — is spent by the whole session against that host, so running N fetchers at once makes the real rate N times higher. A step that fans out fetching either splits the budget by delegate count and writes each share as a number in the brief, or fetches one request at a time and says so. The numbers live in the policy files, and steps cite them rather than repeat them.
10. **Which model and, where supported, thinking depth a delegate runs on is §10.8's rule, not this section's.** The three `.env` tier keys decide it — a read-only delegate on READ, an implementing one (item 5) on EXEC, item 7's independent-perspective delegate on PLAN. An empty key leaves delegation working exactly as items 1–9 describe; a host applies only the model and depth controls its delegation interface actually exposes.

## 7. Dialogue

The tool-neutral half. **How** to ask — a structured question tool where the agent has one, plain text where it does not — is per-tool and stays in each `SKILL.md`.

### Human-writing contract

Chat replies and workflow prose state the substantive point without praise, staged introductions, service offers, inflated significance, vague attribution, or generic positive endings. The aim is clear research prose, not authorship detection or detector evasion: a formulaic-prose finding is an advisory review signal that neither establishes that AI produced the text nor authorizes changing the research record to make the wording appear human.

**Preserve the record.** A style edit may reorder, merge, split or shorten, and never changes a fact, number, threshold, date, quotation, citation, source URL, path, command, flag, environment key, literal field, identifier, code, link, status, decision, open item, done-criterion, technical distinction, uncertainty boundary, negative result, attribution, or source quality. Recorded facts, supported inferences and open questions stay distinct, as do a source's claim and this project's judgment, a log report and an analysis finding, sequence and causation. A missing or conflicting record stays a visible gap routed to the owning workflow, never a plausible detail; nothing gains personality or concrete detail without authorial and evidential support. The test: can the next reader recover the same claim, status, uncertainty, decision and source?

**Match the writer.** Follow an author-confirmed sample where one exists — its vocabulary, sentence movement, punctuation, transitions, qualification and deliberate repetition — without borrowing sentences or adding facts, opinions or humor; without one, restrained direct technical prose: lead with the answer, finding, change or blocker, end on the last useful fact, decision, command or open item, prefer canonical project terms and simple verbs, name who measured, inferred or decided where agency affects interpretation, and replace claims of importance with what changed, under which condition, and why it changes a decision.

**Review pattern clusters, not words.** Rewrite at paragraph scale when several signals accumulate, one template recurs, or a pattern introduces an unsupported claim — inflated significance; vague attribution, disclaimers and plausible guesses; shallow analytical tails, hidden actors and stacked qualifiers; "not X but Y", forced triads, fake objections and slogans; stock signposting, filler, previews and generic endings; synonym cycling, uniform cadence, dramatic fragments, excessive dashes, decorative emphasis, label-heavy lists and emojis — toward the exact result and its supported consequence, a named source or an explicit gap, a direct fact–inference link with a clear actor, and only the structure the reader needs. No word, transition, passive, first person, long sentence, list or dash is banned in isolation: a form that carries a real relation, preserves technical meaning, matches the author or exposes required structure stays, and quotations, titles, code, data and literal fields are never rewritten for matching a pattern.

**Rewrite and verify.** Identify the owner, reader, language and allowed sources; mark what must survive unchanged; map the fact–support–inference sequence and diagnose by paragraph; rewrite each unit around its substantive point rather than patching watched words; compare the revision with its sources, restoring every dropped qualifier, status, citation, path, command and adverse result and removing every new claim; then run the owning workflow's checks and confirm the next reader can find the decision, open item, source, file or command they need.

1. **Keep each chat reply under about 500 words.** Files the run writes do not count. Detail belongs in the artifact; the reply is the digest. **One exception**: a reply whose length is set by what it must enumerate — `star-flow-status`'s tree, or a §7.13 drafted list — is bounded by shape instead, stated by that skill (one line per node or row), never unbounded.
2. **Ask only for a decision or authority that is still missing.** Existing explicit approval remains valid within its scope. Prepare the concrete proposal and complete independent authorized work first; then wait for an explicit answer before the dependent action. An unanswered question is not approval, including in headless runs. Item 13 covers a visible list reviewed as one decision.
3. **Make questions concrete and easy to answer.** Use the active host's supported question interface when appropriate, otherwise concise plain text. Give a recommendation and the material consequence of each useful alternative; omit choices for genuinely open questions. Do not force a fixed option count or a tool unavailable in the current mode.
4. **Report honestly.** Never round a shortfall up. Never present a check as run when it was skipped or could not be run in full. Never state or imply that a file, a status, or a plan was changed when it was not.
5. **Lead with the outcome**, then the evidence, then the routing to the next skill — run in the same turn only under §10.6's conditions (an already authorized execution goal), otherwise given as the recommendation. A printed command recommended to run at an `involve` level other than the one `INVOLVE` in `.env` resolves to (item 7) carries the token spelled out — `star-plan-executor 03 involve=low` — so the line works pasted as printed; at the level `.env` already gives, the bare command is the whole recommendation.
6. **Resolve language once.** An explicit user language request wins for what it names; otherwise valid `.env` `STAR_LANG` (`en` or `zh`) sets replies and newly created workflow documents. When unset or invalid, follow the dialogue, or the invocation language when there is no user turn. Relayed delegate replies follow the same choice. Existing documents keep their frontmatter language. Use the corresponding localized references and templates when needed; `SKILL.md` remains the executable instruction. Preserve technical terms, metrics, paths and BibTeX fields in English inside Chinese documents; code comments are always English. Read the needed `.env` controls together and reuse them within the run until changed.
7. **The `involve` level controls unresolved judgment calls, not the user's existing authority.** Mandatory decisions are material changes to research objectives, acceptance criteria, key inputs, cost or authority; ambiguous targets; and deletions or overwrites not already specifically authorized. A protocol confirmation is satisfied by explicit prior approval of the same operation and scope, or its documented grant. Routine reversible implementation details with project defaults are derivable, not mandatory questions. Preserve evidence, valuable artifacts and pre-existing user work at every level.

   The user sets the level; the skill **resolves it once at the start of the run**, before the first question, from three sources, each later one overriding the earlier: `INVOLVE` in `.env` (`low` / `medium` / `high`; anything else → `medium`), then an `involve=<level>` token in the invocation, then plain language mid-run ("ask me less", "ask me everything") — the last instruction wins for the rest of the run. Reading `INVOLVE` is the same one-line `.env` lookup item 6 describes. A skill that keeps a durable run log records the effective level and its source there once.

   **The token is not an argument.** `involve=<level>` is stripped from the invocation before anything else is resolved — the plan name (§5), the mode, the scope, the date window. This holds in **every** skill, `SKILL.md` mention or not: a skill matching its first argument against `metds/plans/*_plan.md` must not take `involve=low` for a plan name or a mode word, and a skill that accepts no arguments still strips it.

   - `medium` — the default: this file and every `SKILL.md` exactly as written. The level adds nothing.
   - `low` — take the recommended safe judgment call and log it (item 8), including authorized in-scope commits (§1.5). The executor presents its implementation plan and proceeds without entering an approval mode; its routine commit, branch and worktree choices use the recommendation. Do not equate this with permission to change research scope or spend unapproved resources. Ask only if a consequential decision or authority remains unresolved.
   - `high` — judgment calls the skill's text batches into one confirmation point, or takes autonomously between confirmation points, are asked one at a time, each waiting for its explicit answer (item 2).

   For every question that is asked, item 2 holds unchanged: the level decides which judgment calls are asked at all, never whether an asked question may be assumed answered.
8. **Decide-then-disclose.** Every run keeps a decisions record — `EXEC_LOG.md`'s "Notes / decisions" where the skill keeps one, otherwise a "Decisions taken" list in the final reply — one line per settled question, as `question → choice → what it set`. At `low` it captures every judgment call taken unasked, and the final reply states that count whenever it is nonzero. At `medium` and `high` it captures what the user answered. Lines are appended as questions settle — a running record, never a growing recap replayed before each question.
9. **A skill may define a task-specific decision boundary, with its reason and scope.** It must honor existing explicit authorization and documented exceptions. Do not classify every file update or conventional choice as a fresh approval merely because a skill uses stricter wording.
10. **Carry the thread.** A user answering a long series of questions loses the thread. Three cheap habits, and deliberately not a recap before every question — that grows until the user skims it.

    - **Anchor the question.** A question that depends on an earlier answer names it in one clause — "phase axis → 4 units; now: which one owns the data leaf?". One line, only the decisions this question rests on, never the whole history.
    - **Recap at boundaries, not between questions.** At each stage, step, or section end — where the user is already pausing — restate in 2–3 sentences what was decided, what it produced (the file written, the field set), and what it opens next.
    - **Name the way back.** When a boundary closes something the user can still change, say how: the skill and argument that reopens it, and what reopening costs.
11. **Write the action, not its name.** The reader should never have to decode a term to know what happened, so a name that must appear brings its meaning with it, in the same sentence. It governs prose written into files as much as chat, and stops at structure: headings, table columns, field names, and every literal a skill matches byte-exactly stay verbatim, explanation beside them, never in place of them. Item 6 picks the language; this one the wording inside it: a Chinese reply does not translate technical terms, metric names, or paths.

    **A literal that is nothing but a pointer makes that explanation mandatory in chat.** `§4`, `C4`, `Step B1`, a run name, a plan prefix — none of them mean anything to a reader who has lost the thread, so in a chat reply each stays verbatim and takes 3–8 words of what it points at, in parentheses, at first use in that reply: `§4 (the experiments section)`, `C4 (the pre-training diagnostic predicts the gain)`. Not once per conversation — the reader does not scroll back. Later uses inside the same reply stand alone, and a label with no room for it — a question option's title, a table cell — carries the gloss in the line under it. In the prose written into files, the explanation goes beside the pointer where it first matters, not at every mention.

12. **Free text carries user intent, constraints and explicit authorization.** `<skill> [TARGET] [DESCRIPTION] [involve=<level>]` is the shared shape: strip control tokens, resolve the target (§5), then interpret the remaining words semantically. Background alone authorizes nothing; a clear request to perform a specified operation can satisfy its confirmation (§7.2). Preserve explicit read-only requests and limits. Do not widen a selected mode or target silently. In `star-auto`, parse `stop=` separately so its conditions remain binding (§10.7). If a first argument is itself a topic or idea, the same interpretation applies.
13. **A drafted list is one question, not one question per item.** Where a run produces a numbered list the user must accept or reject — revision candidates, fix findings, pending amendments — the whole list goes in the text of the message that carries the question, above the call: one row per item, with what it changes, from what to what, on what evidence, and the recommended action. Then **one** question over that list, four options:

    - *adopt all as listed* — recommended when every row is a local change carrying its own evidence;
    - *adopt all but the ones I name* — the named numbers open a second round, the rest are settled here;
    - *answer my questions on the ones I name first* — nothing is settled this round, and the answers come back with the same list asked again — a question about one row is not agreement to the others;
    - *adopt none* — nothing is written, and whatever the run already persisted stays the deliverable.

    The rows pulled out open a second round in the same shape; a round reduced to one row is asked as that row. With **four rows or fewer** the list fits inside the options, so ask over the rows themselves — several answers at once where the tree's question tool takes them — not over their numbers; question tools commonly cap a question at four options, which the four above already fill.

    **This is not bundle approval** — approving a list the user cannot see, which item 2's explicit answer rules out; here the material is on the page above the call, row by row, and every row the user names comes back on its own. The options carry the answers, never the material: a message arriving as bare options has lost the list, not shortened it.

    **Separate materially different decisions.** A new cost commitment, destructive change or unresolved research choice must be visible with its own consequences. Do not hide a new authority request inside a routine list.

    **The level still moves it** (item 7): `high` walks the list one row at a time, `low` takes the recommended option and logs it (item 8).

    **Elicitation is not a list.** A coaching series, where each answer decides what to ask next, has nothing drafted to lay out and stays one question at a time, each answered before the next is asked (item 2).

## 8. The output table

Every skill's durable output, in one table. `star-flow-status` reads this as the basis for its coverage checks: a stage is "covered" when the artifact below exists and its state field is current. Keep the table honest — a skill that changes what it writes updates this row in the same commit.

| Stage | Producer | Path | State field |
|---|---|---|---|
| Adoption | `star-proj-adopt` | `metds/adopt.md` | `adopted:`, `backfilled:` |
| Idea | `star-idea-storm` | `metds/ideas/<slug>_idea.md` | `finalized:` |
| Refs | `star-refs-reviewer` | `metds/refs/refs_index.md`, `<ABBREV>.md`, `reference.bib`, `related_work.md`, `<slug>_survey.md` | index presence |
| Codebase | `star-code-architect` | `metds/codearc.md`, `${CODE_NAME}/UPSTREAM.md` when built from a reference implementation | presence |
| Env | `star-env-builder` | `wkdrs/env_<name>_<YYYYMMDD>/ENV_REPORT.md`, `freeze.txt` | date in dir name |
| Plan | `star-plan-coach`, `star-plan-decomposer`, `star-plan-reviser`, `star-plan-executor` (exec fields; the plan's §2–§5 write-back) | `metds/plans/<prefix>_<slug>_plan.md` | `status:`, `finalized:`, `updated:`, `dropped:` |
| Run | `star-plan-executor` (`star-proj-adopt` writes a reconstructed `EXEC_LOG.md`) | `wkdrs/<run>/EXEC_PLAN.md`, `EXEC_LOG.md`, `matrix.md` for a grid | plan `exec_status:`, `exec_runs:`; the log's `branch:` / `merged:` (§11) |
| Code review | `star-code-reviewer` | `wkdrs/<run>/CODE_REVIEW_<date>.md`, else `wkdrs/reviews/code_<scope>_<date>.md` | date in filename |
| Plan review | `star-plan-reviser` | `wkdrs/<run>/REVIEW_<date>.md`, else `wkdrs/reviews/<prefix>_<slug>_<date>.md` | date in filename |
| Analysis | `star-expt-analyst` | `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`, `wkdrs/<run>/analysis/` | date in filename |
| Results table | `star-expt-analyst aggregate` | `wkdrs/results/results.md`, else `wkdrs/results/results_<slug>.md` when scoped | `generated:` |
| Digest | `star-expt-digest` | `wkdrs/digests/EXPT_DIGEST_<date>.md` | `mode:`, `covers:`, `sources:` |
| Model record file | `star-expt-digest ledger` | `wkdrs/digests/MODEL_LEDGER.md` | `generated:` |
| Method docs | `star-metd-summarize` | `metds/{overview,framework,dataset,training,evaluation}.md` | `generated:`, `sources:` |
| Release | `star-code-release` | `README.md` (and `README.zh-CN.md` when requested), `wkdrs/release/RELEASE_<date>.md` | the README's provenance marker (date + `sources:`) |

**Every artifact records the model that wrote it.** Each producer writes `model_id` into what it creates — a frontmatter key where the artifact has frontmatter, and the header line where it does not (`CODE_REVIEW`, `REVIEW`, `RELEASE`, `refs_index.md`, `UPSTREAM.md`, and `README.md`, whose header line is an HTML comment). The value is the model id the runtime reports for the writing session, copied verbatim from the provenance line the harness's session hook injects (§13), which takes one of three forms in a fixed recovery order: a resolver command — run it at the moment of the write, not earlier, with the arguments the line fills in, and copy what it prints; a delegate runs the command its own start line injected, against its own record, never the session's — or an id stated outright, copied verbatim although a mid-session switch may have left it stale — or nothing, in which case a model the runtime's own session context states outright is copied verbatim, then the harness's fallback read in §13 is tried once before writing `unrecorded`, which is right only when the session names no model anywhere. Never infer it from behavior, never reason about which model this is "probably", never copy one artifact's value into another, and never derive an id from a model-family description — descriptions are not ids.

Resolution before the write is paired with a check after it. Where the session context supplies a post-write provenance check (§13 says which harness does), every producer skill, including every report writer, runs it once for each artifact it wrote, after the last write and before it reports completion or offers or makes a commit. The expected value is the resolver's output, otherwise the exact model id reported at session start, otherwise `unrecorded`; the actual value is the artifact's `model_id`. A nonzero exit is a blocker: correct the provenance and run the check again, and neither report completion nor commit while it fails.

Two limits matter, because this field will be used to compare work across models:

1. **It is self-reported, not verified.** A model switched mid-session may still carry the pre-switch string. Treat it as evidence of provenance, not proof of it.
2. **It describes one write, not a file's whole history.** For a write-once artifact — every dated report, and every compiled document, regenerated wholesale — those are the same thing. For a plan, which several skills and several models edit over months, the frontmatter names only the most recent writer; the per-edit record is the `## Revision History` entry, which carries its own model id.

**And `model_trail` records the flow across writers.** `model_id` names one write, but several artifacts are written across many sessions — a leaf executed over days, a plan revised for months — where one field describes only the last. So every artifact with frontmatter also carries an append-only `model_trail`: one entry per write session, `{ date, model, skill, scope }`, where `scope` names what that session wrote in the file's own vocabulary (steps, sections, entries). A new entry goes at the end, below every older one, so the trail reads oldest first whatever the runtime; never rewrite a past entry, and keep `model_id` mirroring the last one so a plain grep still works. A wholesale regeneration — a compiled document — starts a fresh trail with one entry recording that it replaced the previous generation. The header-line artifacts above carry `model_id` only: each is written whole in one session, except `refs_index.md`, whose per-row `Model` column stands in for its trail. A write that changes only state fields (`exec_status:`, `exec_runs:`, `updated:`) is not a trail session: it appends no entry, leaves `model_id` as it was, and puts the file outside the post-write check.

Where an artifact already has per-event rows, those carry the model too and are finer than the trail: a plan's `## Revision History` entry, the `model` column of an `EXEC_LOG` step table, the `Model` column of `refs_index.md`. Prefer them when reading — they say which *step* or *entry* a model wrote, not merely which session.

`star-expt-digest ledger` rolls every trail into `wkdrs/digests/MODEL_LEDGER.md`, the one place the flow across `metds/` and `wkdrs/` is visible at once. It is generated, never hand-maintained: to correct a row, fix the trail it came from and regenerate. Compiled from self-reported trails, it inherits their limit, and it carries no quality signal: more writes is not better work.

**One exception.** In its `backfill` phase, `star-proj-adopt` may write `exec_status:` and `exec_runs:` — and nothing else — onto leaves in `metds/plans/`, each leaf individually confirmed by the user. Every other part of a plan file, in both of adoption's phases, stays with the producers named in the Plan row.

Two properties of this table matter more than its contents:

1. **`sources:` on a compiled document records each source plan's `updated` as it was when read.** It makes staleness detectable by exact comparison rather than by file mtime.
2. **Nothing enforces this table.** `star-flow-status` ends its report with a count of report-shaped files matching no row here.

A dropped subtree's artifacts keep every name in this table; only the directory changes, to the `dropped/` locations §9 lists.

## 9. Project layout

Where a skill puts what it writes. Each destination is exclusive — a file belongs to exactly one, chosen by what the file *is*, not by which step produced it.

| What | Where |
|---|---|
| Project code | `${CODE_NAME}/` (from `.env`) |
| Data | `datas/` |
| Model weights | `inits/` |
| A run's artifacts, execution records, reports | `wkdrs/<run>/` |
| Cross-run compilations, environment reports, fetch caches | reserved `wkdrs/` subtrees: `reviews/`, `results/`, `digests/`, `release/`, `env_*`, `ideas_*`, `refs_*` — never reuse these, or `dropped/`, as a run name |
| Plans, notes, method docs | `metds/` |
| What earlier sessions learned, owned by no other file | `.star/memory/`; the git-ignored `.star/memory/local/` for `machine:` scoped facts and anything kept off the repository (§12) |
| Project documentation | `docs/mds/<topic>/`, `docs/htmls/`, `docs/srcs/` (`docs/mds/star-workflow/` is upstream-managed) |
| Plan-owned tool scripts, plan-execution scratch | `tasks/<plan-name>/` |
| Run entrypoint | `execs/run.sh` |
| Reusable launch scripts | `execs/scpts/<run>.sh` |
| A dropped subtree's files | the same names moved aside by `star-plan-reviser`'s drop, back by a revival: `metds/plans/dropped/`, `wkdrs/dropped/<run>/`, `tasks/dropped/<plan-name>/`, `execs/scpts/dropped/` |

Two rules the table alone does not carry:

- **`execs/` root is closed.** It holds `run.sh`, `update.sh` and `configure.sh` and nothing else. A new `.sh` goes to `execs/scpts/`; anything that is not a launch script does not go to `execs/` at all.
- **`tasks/<plan-name>/` holds two kinds of file, and only one is disposable.** A **plan-owned tool script** — the leaf's own verification, indexing, or data-prep tooling, the kind a §5 done-criterion runs — is durable: it lives here for the life of the plan, and finalize never deletes it. Everything else is **scratch**, and belongs here only if losing it at finalize costs nothing. Generated artifacts are neither: an output worth citing, or a config that reproduces a run, goes to `wkdrs/<run>/`.

## 10. The skill roster

Fifteen skills, identified as `star-<name>`; use the explicit invocation supported by the current harness, as §13 spells it. What each one does in full is [research-workflow-skills.md](research-workflow-skills.md); what each one writes is §8 (artifacts and ownership).

| Skill | Tier | Role |
| --- | --- | --- |
| `star-proj-adopt` † | exec | adopt an already-started project into the workflow |
| `star-idea-storm` † | plan | turn a vague interest into a defensible topic |
| `star-plan-coach` † | plan | write the top-level research plan |
| `star-refs-reviewer` | exec | build the related-work base and the bib |
| `star-code-architect` † | plan | set up or reorganize the codebase |
| `star-env-builder` | exec | build and verify the Python runtime |
| `star-plan-decomposer` † | plan | split a plan into executable sub-plans |
| `star-plan-executor` | plan | execute one leaf sub-plan |
| `star-code-reviewer` | exec | review code against the conventions and the plan |
| `star-expt-analyst` | plan | score a run against its done-criteria |
| `star-expt-digest` | read | summarize the programme's recent progress |
| `star-plan-reviser` † | plan | revise one plan against its execution evidence |
| `star-flow-status` | read | read-only status and the one next action |
| `star-metd-summarize` | plan | compile the plans into method documents |
| `star-code-release` † | exec | prepare the repository for release |

1. **The seven marked † are slash-only.** Run them only when the user names them (item 7's standing grant is the one exception): each sits on a decision belonging to the researcher, and a decision reached on an agent's own initiative is a decision nobody made. This table is the source of truth; each harness manifest carries its own guard against implicit invocation, named in that harness's vocabulary, and CI checks all seven against these markers in both directions — a † whose guard is missing, or a guard on a skill carrying no †, fails the build.
2. **The other eight may be selected when the task plainly matches.** Selection authorizes only what the user requested and preserves the mode's write limits. A request for status, explanation or review without changes never authorizes implementation, fixes, installations or another writing successor. Broader execution requires the user's existing execution goal or a new explicit request.
3. **An unresolved target is not picked up.** §5.2 already forbids guessing which plan was meant; a run nobody asked for extends that rule — where the leaf, the run directory, or the scope is not settled by the files themselves, name the candidates and ask instead of starting.
4. **One skill per invocation, and one unit of work inside it.** One leaf, one run, one report — a run that quietly widens its scope is the failure this rule exists for. The next unit is the next invocation. A review of the same leaf before its launch or merge, which returns control to the executor (item 6), is part of that unit, not a second one.
5. **A run the user did not start says so** — one line before it begins, naming what matched and which target it took, and one line in the decisions record (§7.8) when it ends, in that record's shape: `what matched → what ran → what it wrote`. "Don't start things yourself" is an instruction like any other, and holds for the rest of the session.
6. **Take a named next action only when it advances an already authorized execution goal.** A report-only or read-only request ends with its deliverable and a recommendation, even when the recommended skill is one of the eight. Under an execution goal, start a matching unmarked successor with a settled target in the same turn after the current run ends; announce its scope and preserve all cost, write and authority limits. The seven marked skills still require explicit invocation or the `star-auto` grant. Judge each command separately: a permitted review may precede a heavy command that still needs launch authority. A successor gains no permission merely by appearing in a report.
7. **`star-auto` is an explicit standing grant.** `star-auto <goal> [stop=<stop line>] [involve=<level>]` pursues the stated goal through the roster. It may invoke the seven marked skills, with each run preserving its scope and artifact ownership. At `low` its documented `auto=unattended` executor-chain grant covers routine implementation, non-deleting mechanical fixes, scoped commits, branch/worktree creation, clean reviewed squash merge and guarded empty worktree removal (§11.4). It also permits prepared heavy commands within the goal and stop line (§2). Missing authority or a material unanswered decision still stops the dependent action; broader deletion, overwrite, force, push or discard is not implied. With no configured level, auto defaults to `low`. Full procedure: [`star-auto`](../../../.agents/commands/star-auto.md).
8. **Where a run executes, and on which model.** Three `.env` keys name one model each: `STAR_PLAN_MODEL` for research judgment — plans, plan reviews, analyses and independent blind reviews — `STAR_EXEC_MODEL` for implementation and production, and `STAR_READ_MODEL` for read-only scans, collectors and summaries. The tier column above says which of the three a skill's run belongs to, and all three are read in the same one-line `.env` lookup that already gets `STAR_LANG` and `INVOLVE` (§7.6), never a call of their own. **An empty key changes nothing about how a run behaves**: it stays on whatever model the session or the harness already gave it, and every other rule in this file reads exactly as it does with the keys unset.

   **One key can name one model per harness.** A value is either a single model name — used by whichever harness reads the key — or comma-separated `<harness>:<model>` entries, tagged with the tokens `STAR_HARNESSES` uses. A run takes its current harness's tagged entry, falls back to an untagged entry, and reads the key as empty when it has neither; other and unknown tags are ignored. The first colon ends the tag, so a model name carrying a colon is written tagged; model names retain their harness spelling. "The tier value", here and in every manifest, means the result resolved for the current harness, never the raw string returned by the lookup.

   **An entry may end in `@<depth>`** — `low`, `medium`, `high`, `xhigh`, `max`, or a positive integer — the thinking depth that tier uses wherever the harness can set it. Only those suffixes are parsed as depth; other `@` suffixes remain part of the model name. Two tiers may name the same model at different depths; a configured depth the harness can apply per dispatch is itself a routing difference. With no depth control, use the model alone; if the interface or model rejects the depth, keep the available execution route, state the limitation once, and never claim the depth was applied.

   **Before choosing dispatch parameters, read the current harness's entry in §13.** Concrete tags, model aliases, manifest fields, named delegates, selectable model lists, configuration pools and parameter mappings belong there and in the harness manifests. Use only parameters supported by the current interface and existing configuration; never invent model names, depth parameters or configuration entries, or override a valid manifest setting with an invalid per-call value. Offline synchronization remains `bash execs/configure.sh`; a running skill never rewrites harness configuration itself.

   **The mode overrides the roster tier for that run**, because what a skill does in one mode is not what it does in another: `star-expt-analyst aggregate` and `star-expt-analyst watch` are READ, `star-refs-reviewer synthesize` is PLAN, `star-proj-adopt backfill` is PLAN, and `star-code-release check` is READ. **Two runs change tier partway through.** `star-plan-executor` runs its execute-and-verify phase on EXEC while the rest of the run stays PLAN, and `star-code-architect` runs its migration execution on EXEC while the design work stays PLAN. That is the rule; how each one hands the phase over, and what the delegate may write, belongs to that skill's own harness-owned manifest — and neither dispatches when the run is already on an alias of that model unless the harness can apply that phase's configured depth per dispatch. An alias is the family name inside the id, or the id itself, a context-window suffix aside; the session's model is what the resolver command in the session context's provenance line prints when run once (§8), or failing that the id that line states.

   **A run stays in the session that started it.** A directly invoked skill runs on the session's model and never hands the whole run to a delegate. When the key for its tier (or its mode's tier, above) is non-empty and names a model that is not an alias of the session's, or a depth the harness applies only per dispatch, the run says so in one line at the start — the tier, that model and depth, and the two ways to get them: switch the session's model, or start the run through `star-auto` (item 7) — and then runs where it is; an empty key changes nothing and is not mentioned, and a run carrying `tier=` was started on its tier by item 7 or a phase hand-off and gives no such line. That line is the paragraph a manifest carries at the head of its Workflow, before its first step, under the lead **Where this run executes.** — every manifest but `star-plan-coach` and `star-idea-storm`: they question the user at every stage, so the line's `star-auto` route would only relay those questions back, and a direct invocation keeps the session settings unannounced; `star-auto` can still start them on the PLAN tier. Where the harness already applies a tier through the manifest itself (§13) — forking `star-flow-status` and `star-expt-digest` on the READ model, or stamping a tier's depth into its manifests — the line names only what is still missing, and nothing when nothing is. Where the harness gives a delegate no delegation of its own, a run item 7 starts as a delegate runs its inner delegates locally, and `star-plan-executor` and `star-code-architect` their phase hand-off too. Like `involve=` (§7.7), **`tier=<name>` is stripped from the invocation before anything else is resolved** — the plan name (§5), the mode, the scope, the date window — in every skill, whether its own manifest mentions the token or not.

   **Inside a run, delegate routing follows the work rather than the skill**: a read-only collector runs on READ, an implementing delegate (§6.5) on EXEC, and §6.7's independent blind read on PLAN, a second reading of finished work being research judgment. Pass both that tier's model and its supported per-dispatch depth when the harness exposes both; pass only the control it exposes, and never turn an unsupported depth into a model-name suffix.

   **Item 7 is how a whole run gets its tier's model.** A `star-auto` loop reads the session's model once before its loop, through the resolver the mode paragraph above names (§8), and starts each run on its tier's model and supported per-dispatch depth directly. What it hands the started run is fixed: read that skill's harness-owned manifest in full and follow it; the invocation as the loop composed it, its target settled (§10.3); `involve=<level> tier=<name>`; the dialogue language in one line where `STAR_LANG` is empty (§7.6); where the loop holds one, its `auto=unattended` grant; and, on a restart after a returned question, that question and its answer. It waits for the run and relays its reply unchanged; the files the run wrote are that run's artifacts, and the provenance recorded in them (§8) is the started run's model, not the session's. A delegate cannot put a question to the user, so a started run that meets a question it cannot answer returns it, and the loop triages it as item 7 says; `star-plan-coach` and `star-idea-storm` are started this way and relay their questions back. Every start and every fan-out records its tier, the model it got, and the requested depth or `default` in the decisions record (§7.8), beside what item 5 already has it announce.

## 11. Execution branches and worktrees

Only `star-plan-executor` manages the execution branches and worktrees described here, within its authorized run. Record the isolation choice in EXEC_PLAN before changing the checkout. Routine creation follows §7.7; merge, discard and cleanup follow their specific authority and artifact-preservation conditions below. Mechanics live in `references/branch_rules.md`. Items 1–6 cover branches; items 7–9 cover worktrees.

1. **The gap list decides the recommendation.** Modifying pre-existing tracked code recommends an execution branch; only adding files or writing the run's own tasks and records normally stays on the base. Record the reason and honor an existing isolation choice. Apply §7.7 to unresolved commit, branch and worktree choices: `low` takes the safe recommendation, while `medium` and `high` ask the still-unsettled choices at their respective granularity. Choosing a branch also requires its scoped commits, because uncommitted work cannot merge.
2. **Name, base, records.** The branch is named `<run>`, pairing by name with `wkdrs/<run>/`; it forks from whatever branch the checkout was on at approval — never assumed to be `main` — and `EXEC_PLAN.md` / `EXEC_LOG.md` frontmatter record `branch:`, `base:`, and later `merged:`. On the branch, each step's commit also stages the run records it updated (the log row, the sub-plan's status), because only commits merge. A listing sweep can only match that name's shape, so a branch no leaf and no run record claims is not an execution branch — leave it alone.
3. **The base branch stays canonical.** Until the merge, everything the run wrote exists only on the branch, so read from the base branch the leaf is simply not done yet — the correct reading, not a gap: a dependent whose `depends_on` sibling sits unmerged stays blocked, and merging the sibling unblocks it. `star-flow-status` lists execution branches, so an unmerged run stays visible.
4. **Merge only with applicable authorization**, after the leaf is `done` and its newest review has no unsettled blocker/major finding. Ordinary runs ask if merge authority is missing; a valid `auto=unattended` grant at `low` authorizes a clean reviewed squash merge and the guarded cleanup in `branch_rules.md`. Default is squash; retaining step commits is an explicit alternative. Before the merge commit, verify affected light checks on the integrated base, then stage the successful `merged:` record with the integration. Confirm the commit contains that record before cleanup; a failed check or commit leaves it unset. Under unattended auto, move durable artifacts out, remove the worktree without force only when its status is empty, and retain the merged branch. Other deletion or discard needs specific authority.
5. **Sync by merging the base branch in, never by rebase.** Within an explicitly authorized integration, resolve mechanical conflicts when both intended changes are clear, then verify the affected behavior. Ask when resolution would choose between research decisions or overwrite user work. The unattended auto grant alone does not authorize conflict resolution: retain the state and report unless the user separately authorized it.
6. **A discard rescues the records first.** Before an unmerged branch is deleted, carry its `wkdrs/<run>/*.md` records and the plan's run entry and verdict to the base branch. Preserve non-md artifacts too. A negative result is evidence. Discard and deletion require specific authorization, which may already have been given; neither is implied by the unattended grant.
7. **A worktree isolates a busy checkout.** Busy signals include another run's branch, uncommitted paths owned by another run, an unresolved launched command, or explicit parallel work. Use run markers and available read-only evidence; no results yet does not prove a job is running, and a failed process probe does not prove it stopped. When state is uncertain, prefer an isolated worktree without switching the uncertain checkout; ask only if that cannot resolve the collision safely. Routine creation follows §7.7. Removal preserves every artifact and requires the authority in item 4.
8. **A run in a worktree always carries a branch; tree, branch, and run directory share the run's name.** Commits made in the tree need a home while the base branch stays checked out elsewhere, so a plan whose gap list said `branch: none` switches to `branch: <run>` on moving into a tree. Creation is one command, run from the invoking checkout: `git worktree add ../<root-dirname>--wt/<run> -b <run> <base>` — tree, branch, and fork point in one step; the tree's absolute path is recorded as `worktree:` in EXEC_PLAN / EXEC_LOG frontmatter, the field by which any later session finds the run's home. Git creates only tracked files in it, so afterwards link `.env`, `datas/`, `inits/` (and `.star/memory/local/` where present) from the main checkout — and never link `wkdrs/` or `tasks/`: they contain tracked files, and linking the directory replaces them with a single symlink in git's eyes. The merge happens in whichever tree has the base branch checked out — normally the invoking checkout; if the user has switched it away, say so and ask.
9. **Before removal, move the artifacts out.** Non-md untracked artifacts under the tree's `wkdrs/<run>/` and `tasks/<plan-name>/` exist nowhere else, and `git worktree remove` deletes them with the tree. The order is fixed: merge (or the record rescue of item 6) → move those artifacts to the same paths in the main checkout — a run whose plan was dropped meanwhile owns the `dropped/` paths (§9), and its deferred drop move follows this rescue → `git worktree remove` without `--force` — git refuses while stray files remain, and that refusal is the safety net, not an obstacle to override → the branch's deletion is then its own question. A tree directory deleted by hand is a blocker to report; `git worktree prune` clears the stale metadata, and the tree is never silently rebuilt.

Other skills work in the run's recorded `worktree:` when one exists. A skill about to commit while the checkout sits on another run's execution branch says so and does not commit there — an unrelated commit made there rides into that leaf's merge; preserve unrelated changes, and the user switches back (§1.3) or names where the commit goes. Never switch a checkout that a live job may re-read. The executor owns creation and cleanup under the conditions above; a user-prepared worktree is supported without asking to create it again.

## 12. Project memory

What a session learned and no file in the project owns goes to `.star/memory/`, one fact per file, reaching the next session as an index line the session hook (§13) builds from its frontmatter. The test is exclusive: a result belongs to its run's `EXEC_LOG.md`, a research decision to its plan, a paper to `metds/refs/`, a placement rule to `metds/codearc.md`; memory is the residue, and where it disagrees with a file in the repository, the file wins. Recording is offered, never assumed — at most two offers a session, written only after the user agrees; `INVOLVE=low` (§7.7) records unasked and says so. Four types: `env`, a fact about a machine, cluster or toolchain, usually learned by failing, and the one type the hooks age; `pref`, a standing user preference about how the work is done; `insight`, a judgment that outlived the run that produced it; `deadend`, something tried, failed and not worth retrying, with what it cost.

**Where it lives.** `.star/memory/<slug>.md` is versioned and travels with a clone; `.star/memory/local/<slug>.md` is git-ignored like `.env` and holds a `machine:` scoped fact — true here, false on the next machine — and any memory the user keeps off the repository, whatever its scope: the split is by where a fact travels, not where it holds.

**The file.** Frontmatter with English keys — `type`; `scope` (`global`, `machine:<name>`, `plan:<prefix>` or `code:<path>`: where the fact is true, not where it was learned); `summary` (the index line: what the fact *is*, "builds only after `module load gcc/11`", not what it is about); `language` (§7.6); `verified` (when the fact was last confirmed true, from the clock, §4); `model_id` (the model that wrote or last re-verified it, verbatim, §8); `source` (the artifact it came out of, or `conversation`); optional `supersedes` (the slug it replaces) — then a body opening with one sentence stating the fact and holding only what a reader needs to act on it. No `model_trail`: a re-verification rewrites `verified` and `model_id` rather than appending.

**The index line.** Nothing is hand-written: the hook reads every `<slug>.md` in the two directories and prints, newest `verified` first, the versioned store's lines then `local/`'s, nothing for an empty store.

    - <type> · <scope> · <verified> · [<slug>](<slug>.md) — <summary>

It reads the frontmatter literally: a block not closed by a second `---` is not listed; a file without `summary` is listed by its first body line; an `env` line — the type token as written — whose `verified` is more than 180 days old is marked stale, the other types never. Keep the store under roughly 60 memories; past that, retire rather than group, since every line reaches every session.

**Retiring.** Re-verified: set `verified` to today and `model_id` to the checking model. Superseded: write the new memory with `supersedes: <old-slug>` and delete the old file; git holds the history. Wrong: delete it. A deletion is confirmed with the user at every involve level (§7.7).

## 13. Harness adapters

This is the one section of this file that names a harness: everything above holds for all of them, and a manifest implements it without changing scope, authority or artifact ownership. Read the current harness's entry before choosing an invocation or dispatch parameter, and use only what the active interface supports.

### Invocation and tags

The skills are invoked as `/star-<name>` in Claude Code, Cursor, Pi and Qwen Code, `$star-<name>` in Codex, `/skill:star-<name>` in Kimi Code and DSH. The tag below is what `STAR_HARNESSES` and a tagged model entry (§10.8) use; model names keep their harness spelling (`pi:anthropic/claude-fable-5`, `claude:claude-opus-5[1m]`), and an alias comparison ignores the context-window suffix — `opus` for `claude-opus-5[1m]` — while artifacts record the id verbatim.

### Hooks and model provenance

Each tree's `hooks/` directory (Pi: `.pi/extensions/star-hooks/`) holds `star_model_id.sh`, `star_memory.sh` (§12) and `star_commit_guard.sh` (§1); the memory hook fires on the provenance hook's event.

| Harness | Tag | Registered in | Provenance line: event → injects → read |
|---|---|---|---|
| Claude Code | `claude` | `.claude/settings.json` | `SessionStart`, `SubagentStart` for a delegate → a `--resolve` command over the session transcript or the delegate's own; the id itself when none was named → as you write |
| Codex | `codex` | `.codex/hooks.json` | `SessionStart` → the exact `session_model_id`, a `--resolve` command over the rollout, the `--check` command → as you write, then after |
| Cursor | `cursor` | `.cursor/hooks.json` | `sessionStart` → the id → at session start |
| DSH | `dsh` | `.dsh/hooks.json`, enabled by `bash .dsh/hooks/install.sh` and the per-profile hooks bridge | `SessionStart` via the bridge → a `--resolve` command over the session log, needing `zstd` on PATH → as you write |
| Kimi Code | `kimi` | no project-level config: `bash .kimi-code/hooks/install.sh`, once per machine | `UserPromptSubmit` → `default_model` from `~/.kimi-code/config.toml` → from config, never the session |
| Pi | `pi` | `.pi/extensions/star-hooks/index.ts` | `before_agent_start` → the live id, again after every model change → at the prompt that uses it |
| Qwen Code | `qwen` | `.qwen/settings.json` | `SessionStart` → a `--resolve` command over the transcript; the id itself when none was named → as you write |

A hook that exists is not necessarily registered; a project adopted before a hook existed keeps its own registration file — `execs/update.sh` reports the gap, and the entry is added by hand. Claude Code also states the model in its system prompt, so a Claude session with no hook line is not one that names no model.

A value read as you write cannot be stale; Cursor's and Kimi's can, and Pi's last injected line is the writing model. A `--resolve` command reads the runtime's own per-turn record, and a delegate's start line points at the delegate's own record (Claude Code: its transcript under `subagents/`, with no session model). Kimi's line does not reach a skill opened by slash command before any plain user message, so before writing `unrecorded` read the value once: `grep -E '^[[:space:]]*default_model[[:space:]]*=' "${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"`. Codex supplies the post-write check §8 requires: `bash .codex/hooks/star_model_id.sh --check <artifact> <rollout> <session_model>`.

### Model and thinking depth

`bash execs/configure.sh` writes the tier keys (§10.8) into the static fields each harness supports, `--kimi-pool` registers Kimi's aliases, and a running skill never rewrites harness configuration. Qwen Code's named agents take the model without the suffix; DSH and Pi apply only the model and depth controls their delegation interface exposes.

#### Claude Code

The depth is the `effort:` frontmatter `configure.sh` writes into each tier's manifests and into the named `star-plan`, `star-exec` and `star-read` agents: naming the agent names the depth per dispatch, and a plain subagent type inherits the dispatching run's depth. A directly invoked run therefore has its roster tier's depth and lacks only that of a tier its mode switches to, which is applied per dispatch alone (§10.8's opening line names it). `star-flow-status` and `star-expt-digest` also fork on the READ model `configure.sh` stamps into their manifests, so for those two the opening line names nothing. For a phase hand-off or a `star-auto` start, a configured depth is a routing difference even when the tier model aliases the active model. A read-only dispatch — a collector or a blind read — keeps the generic `Explore` type, whose tool set is what keeps it read-only, since the named agents carry no tool restriction; it takes the tier's model but not its depth, and the run says so once. A subagent cannot dispatch subagents, so a run started as one works locally (§10.8).

#### Codex

No file stamp: whenever the current `spawn_agent` interface accepts the suffix for the selected model, every tier dispatch passes it explicitly as `reasoning_effort`, so a configured depth is a routing difference even when the tier model aliases the active model, and a phase that changes tier can change both. A direct invocation stays in the main thread on the session's model and effort, so a configured depth is one the opening line names; `star-auto` starts each run at its tier's model and effort, `star-plan-coach` and `star-idea-storm` included, and relays their questions back.

#### Cursor

Cursor resolves only the flat ids its catalog lists, one per depth (`claude-opus-5-high`), and rejects a parameterised `id[effort=<depth>]`, so `configure.sh` appends a configured `@<depth>` to the model as `-<depth>` and writes that flat id, unquoted, onto that tier's named agent's `model:`. Name the delegate `star-plan`, `star-exec` or `star-read` so the stamp applies. `Task` exposes a per-call `model`, no depth parameter, and a passed `model` overrides the file: pass the stamped id when this session's selectable `Task` `model` list contains it; otherwise scan that list for a slug of the same model family that already carries the wanted depth — a speed-tier variant counts — and pass it when listed; if nothing listed matches, omit `model` so the file stamp is not overridden, and say once that the per-call slug was unavailable. Never invent a slug, pass an `@<depth>` suffix or bracketed parameter, or a family match at the wrong depth; a listed stamped id is a routing difference even when the tier model aliases the active model, and an unlisted depth is not claimed applied.

#### Kimi Code

No per-dispatch depth parameter: `Agent` / `AgentSwarm` `model` accepts only aliases from the configured secondary-model pool, so a configured `@<depth>` is dispatched as the pool alias binding that model at that depth — conventionally `<model>-<depth>`, a `[models]` variant carrying that `default_effort` in `~/.kimi-code/config.toml`, registered by hand or by `--kimi-pool`, never by a skill run. A configured depth is thus a routing difference even when the tier model aliases the active model; with no pool entry binding it, the dispatch passes the model alone and says once that the depth went unapplied.
