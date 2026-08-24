# Writing inside the STAR research record

**Language:** English | [简体中文](human-writing-guide.zh-CN.md)

STAR does not produce one isolated essay. It builds a research record that moves from an idea, through plans and runs, into analyses, method documents, and a release README.
Natural writing in this project must make that chain easier to read without making it harder to audit.
This guide governs prose and replies; [research-workflow-conventions.md](research-workflow-conventions.md) still governs evidence, state, ownership, execution, and provenance.

## 1. The test for a style edit

Every durable statement in the project is either recorded evidence, an inference from recorded evidence, or an open item owned by a later workflow step.
A style edit may improve the expression of any of the three, but it may not move a statement from one class to another.

Use one controlling test:

> After the rewrite, can the next workflow skill recover the same fact, status, uncertainty, and decision from the file?

If not, the edit changed the research record rather than its language.
This is stricter than merely “preserve the meaning”: a dropped citekey, softened negative result, hidden `[TBD]`, changed command, or missing run name may leave the broad meaning intact while breaking the workflow.

## 2. Where the full guide applies

All replies inherit the compact rule in `AGENTS.md`: answer first; skip praise, staged introductions, service offers, and generic positive endings.
Six prose-producing skills load this full guide at the point where they draft narrative text:

| Workflow moment | Skill and writing surface | What the prose must do | Content the style pass must not move |
|---|---|---|---|
| Converge on a topic | `star-idea-storm` → `metds/ideas/<slug>_idea.md` | State one question, the scanned gap, why now, first validation, and risks | Seed, source-backed gap, named works, constraints, verdicts, kill-condition |
| Turn the topic into a plan | `star-plan-coach` → `metds/plans/<digit>_<slug>_plan.md` | Make six confirmed sections usable by later planning and execution | Section status, decisions, citations, thresholds, `[TBD]`, technical distinctions |
| Build the literature base | `star-refs-reviewer` → notes, `related_work.md`, and surveys under `metds/refs/` | Separate what a paper claims from how it relates to this project | Quotes, citekeys, source depth, attribution, uncertainty, negative results |
| Report experiment movement | `star-expt-digest` → `wkdrs/digests/EXPT_DIGEST_<date>.md` | Say what changed in the covered window and what remains unresolved | Window, source tier, run names, numbers, provisional labels, adverse results |
| Compile the method | `star-metd-summarize` → five `metds/*.md` method documents | Reorganize plan-backed method content without designing the method | Plan provenance, values, paths, `TODO`, verification labels, conflicts |
| Compile the release surface | `star-code-release` → `README.md` and optional Chinese twin | Explain what the repository verifiably contains and how to run it | Commands, paths, runs, result conditions, provenance, absent-source `TODO`s |

Other skills use the compact contract in the shared conventions.
They need not load this full file when their output is primarily code, structured state, a rubric verdict, or a bounded execution record.

## 3. Separate the record layer from the prose layer

Before rewriting, divide the target into three layers.

### Record layer: copy exactly or leave alone

- YAML frontmatter, status values, dates, plan names, run names, model identifiers, and `traces_to` links;
- facts, measurements, thresholds, seeds, variance statements, table values, and done-criteria;
- quotations, citekeys, paper titles, source URLs, fetch dates, and source-depth labels;
- paths, commands, flags, environment keys, function names, field names, field values, and code;
- uncertainty boundaries, negative results, unresolved conflicts, `[TBD]`, `TODO`, and “not yet verified” labels.

### Prose layer: rewrite when it improves the handoff

- the order in which supported facts are introduced;
- sentences that connect evidence to a local inference;
- explanations of why a result changes a plan decision;
- transitions between constraints, method choices, experiments, and risks;
- summaries that preserve the source tier and the strength of every claim.

### Ownership boundary: route instead of polishing over it

A missing value is not a style problem.
Neither is a stale plan, an analysis absent from a run, a citation that has not been verified, or a method detail found only in chat.
Keep the explicit gap and route it to the skill that owns the missing record.
Do not add a plausible detail, personality, anecdote, or “reasonable” conclusion to make the paragraph feel complete.

## 4. Failure modes specific to workflow artifacts

### Ideas and plans

Do not turn novelty into ceremonial language such as “groundbreaking direction” or “important milestone”.
Name the scanned works, the unaddressed capability, and the constraint that makes the question worth testing.
Keep `not scanned`, `[TBD]`, parked directions, fallback conditions, and kill-conditions visible; they are control state, not embarrassing prose to smooth away.

### Literature notes and synthesis

Avoid “existing studies show” when a citekey and a verified record are already available.
Do not use venue prestige or citation count as a substitute for direct overlap with the project.
Keep paper claims, collector returns, and the main agent's project-specific judgment distinguishable.
A paragraph may synthesize several papers, but every mapped limitation must remain recoverable from its notes.

### Experiment digests

A failed, partial, stale, or unanalysed run must not acquire a success narrative during summarization.
Report what the analysis file establishes, what the log only reports, and what remains provisional.
Do not infer causality from chronology or turn “metric increased after change X” into “X caused the increase” without the experiment supporting that claim.
End on the unresolved decision, required analysis, or routing command rather than optimism about future progress.

### Method documents

`star-metd-summarize` compiles plans; it does not repair them from code, logs, `wkdrs/`, or chat memory.
If a leaf is unfinished, mark its contribution unverified.
If a leaf and parent disagree, retain the resolved source or the explicit conflict according to the workflow rules.
If no plan covers a template section, keep its `TODO`; a fluent placeholder is still invented method content.

### Release README files

The README is compiled documentation, not sales copy.
Describe the repository's verified capability, not its hoped-for impact.
A result travels with its run and conditions; a command travels byte-for-byte from the resolved script; a figure path appears only when the file exists.
When a mandatory section lacks a source, name the producer in a `TODO`; when the mapping says omit an empty section, omit it without apology.

### Replies and handoffs

Lead with the answer, change, finding, or blocker.
Write the action and its consequence instead of announcing a phase name the reader must decode.
Name a workflow label such as `finalized:` or `§4` only with the meaning needed at that point.
End with the last useful fact, decision, command, file, or blocker; do not append praise or an offer to continue.

## 5. Draft and revise in workflow order

For a long reply or durable prose artifact:

1. **Resolve the owner.** Identify the producing skill, exact target path, language rule, and files it is allowed to read.
2. **Read the record.** Use the sources that workflow step names; do not replace a missing source with chat memory. If the user supplied a writing sample, read it here.
3. **Freeze protected content.** List the facts, literals, statuses, citations, numbers, uncertainty, and negative results that must survive byte-for-byte or claim-for-claim.
4. **Choose the handoff.** State what the next reader or skill must understand or decide from this passage.
5. **Draft around the substantive point.** Distinguish recorded fact, supported inference, and open item. Use stable technical terms from the plan and code architecture.
6. **Review patterns by paragraph.** Look for accumulated formulaic behavior rather than replacing watched words one by one.
7. **Compare against sources.** Restore any dropped qualifier, provenance pointer, status, command, path, or adverse result; remove any new claim.
8. **Write only what this step owns.** Preserve frontmatter, tables, code blocks, link targets, and literal fields, then route gaps to their producer.

For several outputs in one run, compare their openings, method recaps, limitations, and endings.
Repeated structure is acceptable when the templates require it; repeated unsupported rhetoric is not.

## 6. Formulaic patterns worth reviewing

These are review signals, not banned forms and not evidence of AI authorship.
Review a paragraph when several accumulate, or when a clear chatbot residue appears.

- **Inflated significance:** importance, transformation, or broad impact appears without a mapped claim and evidence.
- **Vague attribution:** “experts”, “industry reports”, or “已有研究” replaces a citation or record the project already holds.
- **Unsupported analytical tail:** “thereby demonstrating”, “highlighting”, “从而彰显”, or “进而说明” adds a consequence the evidence did not establish.
- **Staged contrast:** repeated “not only X but Y”, forced threes, or rejected alternatives create drama without carrying a technical distinction.
- **Terminology cycling:** synonyms replace a canonical method, dataset, metric, status, or component name and quietly change its scope.
- **Hidden agency:** passive or abstract-noun chains obscure who designed, measured, confirmed, inferred, or decided.
- **Uniform cadence:** equal-length sentences, repeated openings, and slogan-like fragments make the paragraph follow a template rather than the reasoning.
- **Decorative scaffolding:** greetings, praise, section previews, excessive labels, “I hope this helps”, or offers to continue survive around the useful content.
- **Stacked filler or hedging:** setup phrases delay the claim, while several qualifiers obscure rather than calibrate uncertainty.

Do not ban em dashes, passive voice, transition words, first person, three-item lists, headings, bold text, or long sentences.
Keep them when they serve a real comparison, preserve a user-confirmed voice, expose necessary structure, or state an evidential boundary accurately.
Vary cadence because the reasoning changes, never by injecting random irregularity.

## 7. Acceptance checks before writing the file

Do not assign a numerical “human score”.
Use checks that correspond to downstream workflow risks:

| Check | Question to answer |
|---|---|
| Traceability | Can every research claim still be located in the source file, citation, run, or recorded decision that supports it? |
| State fidelity | Are status values, `[TBD]`, `TODO`, provisional labels, negative results, and unresolved conflicts still explicit? |
| Causal discipline | Does the prose distinguish observation, comparison, and causal conclusion at the same strength as the evidence? |
| Ownership | Did the edit stay inside the producing skill's read/write boundary and route missing records instead of inventing them? |
| Terminology | Do plan, code, experiment, and prose use the same canonical names for the same things? |
| Voice | Does the result match the user's sample or the project's restrained technical default without decorative personality? |
| Handoff | Can the next skill identify the decision, remaining uncertainty, and exact file or command it needs? |

Claim and state fidelity are release conditions.
The other checks locate revision work; none classifies who wrote the text.
