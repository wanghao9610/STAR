# Code Review — <scope> (<YYYY-MM-DD>)

<!-- Written by $star-code-reviewer. Mode: full | plan | path | diff; target: <argument as given>;
     files reviewed: <n>. Findings are numbered F1, F2, … and cite file:line, the violated rule,
     and a concrete fix. Sections with nothing to say collapse to one line — never pad. -->

## 1. Scope & Evidence Base

<!-- How the scope resolved (plan mode: which of §2 / §4 deliverables / EXEC_LOG contributed which
     files). Yardsticks loaded (project guidelines, metds/codearc.md, plan §2–§5) and which
     were absent. Static evidence: compileall result; ruff/flake8 result or "not installed";
     "reading-only review" when the env was unusable. -->

## 2. Verdict

<!-- 2–4 lines: overall state, finding counts per severity, conformance summary (plan mode).
     Specific and honest — no grade inflation, no alarmism. -->

## 3. Findings

<!-- Grouped by severity, F-numbered in report order. Confirmed findings only; doubtful ones go
     under Unconfirmed and are never counted in the verdict. Empty severity groups are omitted. -->

### Blocker

- **F1** `<file>:<line>` — <issue>
  - Rule: <yardstick> · Evidence: <snippet> · Fix: <concrete change>

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
| §4 <deliverable> | present / absent | <path> |
| §5 done-criterion | supported / unsupported | <the machinery that checks it> |

## 5. Good Practices

<!-- ≤3 bullets worth keeping or propagating; omit the section rather than invent. -->

## 6. Next Actions

<!-- Routing for out-of-boundary findings: feature gaps → $star-plan-executor <leaf>; plan-text
     divergence → $star-plan-reviser <slug>; structural reorganization → $star-code-architect;
     unusable env → $star-env-builder. Then the fix-pass candidates (mechanical findings, by number). -->

## 7. Fix Record

<!-- Appended by the fix pass: one line per eligible finding — F<n>: applied / skipped / reverted
     (<reason>) — plus the commit hash when the fixes were committed. "No fix pass run" otherwise. -->
