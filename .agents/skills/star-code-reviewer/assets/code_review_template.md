# Code Review — <scope> (<YYYY-MM-DD>)

<!-- Written by star-code-reviewer (model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none — docs/mds/star-workflow/research-workflow-conventions.md §8>). Mode: full | plan | path | diff; target: <argument as given>;
     review_gate: blocked
     Set passed only after verifying no unresolved blocker/major and adequate behavior/constraint coverage;
     the reviewer owns this decision. Record the completed report and explicit source/config/plan scope
     with scripts/review_state.sh; refresh the receipt after any report edit or verified fix.
     files reviewed: <n>. Findings are numbered F1, F2, … and cite file:line, the violated rule,
     and a concrete fix. Sections with nothing to say collapse to one line — never pad. -->

## 1. Scope & Evidence Base

<!-- How the scope resolved (plan mode: which of §2 / §4 deliverables / EXEC_LOG contributed which
     files). Review rules loaded (project guidelines, metds/codearc.md, plan §2–§5) and which
     were absent. Behavior evidence per language: concrete inputs/outputs, boundary/failure cases and checked cross-file contracts.
     Static/runtime evidence: exact narrow installed Python, shell, JS/TS and config check commands/results;
     unavailable tools and unverified behavior explicitly named. No Python prerequisite for other languages. Scoped screen: what the checks for machine-local path
     literals, oversized modules and (when the change could affect one) codearc.md protected names
     returned over the requested files; any paths added to verify a contract, and why.
     Code version: the head commit at review time (`git rev-parse --short HEAD`), with the execution
     branch beside it when the run records one. Explicit source/config files or directory scope and relevant
     leaf/ancestor plans; the REVIEW_STATE.md receipt binds their content and this exact report, not dates. -->

## 2. Verdict

<!-- Briefly: overall state, finding counts per severity, conformance summary (plan mode).
     Explicitly explain the passed/blocked gate and unresolved blocker/major count.
     Specific and honest — no grade inflation, no alarmism. -->

## 3. Findings

<!-- Grouped by severity, F-numbered in report order. Confirmed findings only; doubtful ones go
     under Unconfirmed and are never counted in the verdict. Empty severity groups are omitted. -->

### Blocker

- **F1** `<file>:<line>` — <issue>
  - Rule: <review rule> · Evidence: <snippet> · Fix: <concrete change>

### Major

### Minor

### Nit

### Unconfirmed

<!-- Worth a human look, not verified. One line each, with what would confirm it. -->

## 4. Plan Conformance Scorecard

<!-- Plan mode only; otherwise one line: "not a plan-scoped review". Score against disk, never
     against EXEC_LOG claims. -->

| Item | Verdict | Evidence |
| --- | --- | --- |
| §3.1 <task> | implemented / partial / missing | <module/function, or where you looked> |
| §4 <deliverable> | present / absent / pending | <path, or the awaiting STOP-line command> |
| §5 done-criterion | supported / unsupported | <the machinery that checks it> |

## 5. Good Practices

<!-- The few practices worth keeping or propagating; omit the section rather than invent. -->

## 6. Next Actions

<!-- Routing for findings outside what this skill may write: feature gaps → star-plan-executor <leaf>; plan-text
     divergence → star-plan-reviser <slug>; structural reorganization → star-code-architect;
     unusable env → star-env-builder. Then the fix-pass candidates (mechanical findings, by number). -->

## 7. Fix Record

<!-- Appended by the fix pass: one line per eligible finding — F<n>: applied / skipped / reverted
     (<reason>), with its authorization source — plus the commit hash when the fixes were committed. "No fix pass run" otherwise. -->
