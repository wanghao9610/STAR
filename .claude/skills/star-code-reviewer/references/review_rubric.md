# Code Review Rubric

How findings are formed, graded, and returned. Read the code, not just its names: apply every dimension to every file in scope (F only in plan mode). A finding must name the dimension, severity, violated rule, exact location, and a concrete fix — a complaint no written yardstick backs is a style preference, not a finding. When two dimensions overlap (an unused import is both C and E), file it once, under the more specific one.

The project guidelines cited as §n below are AGENTS.md's numbered sections; architecture rules live in metds/codearc.md.

## Finding contract (structured return)

One entry per finding, in file order:

```yaml
- file: <path from project root>
  line: <first affected line>
  dimension: A | B | C | D | E | F
  severity: blocker | major | minor | nit
  rule: <violated rule, e.g. "§6: no hardcoded local paths">
  issue: <one sentence — what is wrong>
  evidence: <offending snippet or 1-line quote>
  fix: <concrete change in one sentence, or the exact replacement>
```

Collectors return exactly this list (plus `files_reviewed: <n>`) and nothing else: no prose verdicts, no fixes applied, no files written.

## Severity ladder

- **blocker** — breaks something or violates a hard project constraint: syntax/import errors, hardcoded machine-local absolute paths, writes landing outside the layout rules, an edited name from the rename-residual list.
- **major** — violates a written convention in a way that misleads or degrades the codebase: a §3 task claimed done but missing/partial in code, a §4 deliverable absent, a public class without a docstring, a module placed against codearc.md's placement rules, a speculative feature or single-use abstraction, duplicated logic an existing helper already provides.
- **minor** — convention gaps that do not mislead: a missing one-line docstring on a public function, a non-PEP 8 name, a dead branch, an overlong function doing several jobs.
- **nit** — polish: a comment narrating the obvious, inconsistent naming style within one file. Report nits only for files that already carry higher findings; nits never dominate a report.

When severity is in doubt, grade down and say why in `issue`.

## A. Docstrings & comments

- Every public class has a docstring stating its responsibility, plus key constructor args/attributes when they are not self-evident.
- Every public function/method has at least a one-line docstring saying what it does or returns; non-trivial signatures document Args/Returns in the style the surrounding code already uses (Google / NumPy / reST — never convert between styles).
- Modules exposing public API carry a module docstring.
- Comments explain **why** (constraints, non-obvious decisions), not **what** the next line does; no stale comments contradicting the code; no commented-out code blocks.

Not a finding: `_private` helpers a few lines long whose name is the documentation; test functions named for what they test.

## B. Naming

- PEP 8: `snake_case` functions/variables, `PascalCase` classes, `UPPER_CASE` module constants, lowercase module/package names.
- Names say what things are: no `data2`, `tmp_fn`, `do_stuff`; booleans read as predicates (`is_`, `has_`); ambiguous quantities carry units (`timeout_s`).
- Follow the naming conventions recorded in metds/codearc.md and the upstream style of the surrounding code (§3: match existing style, even one you would not choose).

Not a finding: conventional short names in tight scopes (`i`, `x`, `df`, `cfg`); upstream-inherited names outside the reviewed scope; residual-list names (those become a blocker only if someone changed them).

## C. Simplicity (§2)

- No features beyond what the task or plan asked; no configurability with a single call site.
- No single-use abstraction: a base class with one subclass, a factory building one product, an interface with one implementation.
- No dead code: unreferenced functions/classes/branches, unreachable code, stale flags. Distinguish project-introduced dead code (a finding, fixable) from upstream-inherited dead code (report only — §3, never delete).
- No duplicated logic an existing helper already provides — the fix cites that helper.
- A function does one job; needing a paragraph to summarize it makes it a split candidate (minor).

## D. STAR project conventions

- **No hardcoded machine-local paths** (`/Users/...`, `/home/...`, `C:\...`) in code; machine-specific roots come from `.env` / environment variables / config (§6). Always a blocker.
- Data is read from `datas/`, weights from `inits/`, generated outputs go to `wkdrs/`; nothing writes into `metds/` or into the package itself at runtime (§5).
- New modules sit where codearc.md's placement rules and plan-component map assign them.
- Runtime assumptions match the project: entrypoints documented to run via the `.env` conda env / `execs/run.sh`; no system-python shebang assumptions; reusable launch scripts live under `execs/scpts/`.
- Rename residuals (codearc.md §7) — registry strings, config `type:` keys, checkpoint `state_dict` prefixes, logger/project names — are untouched.

## E. Correctness smells (high-confidence only)

Report only what the code in front of you demonstrates:

- Unused imports/variables (corroborate with ruff/flake8 output when available; verify an "unused" import is not a side-effect import before flagging).
- Mutable default arguments; bare `except:` / `except Exception: pass` swallowing errors; files or processes opened without context managers; `== None` comparisons; f-strings without placeholders; obviously inverted or off-by-one conditions.
- Signature/call mismatches within the scope (compileall and ruff catch part; read the call sites for the rest).

Not a finding here: hypothetical races, performance guesses, "might fail if …" scenarios with no concrete input you can name. What needs a debugger to confirm goes to the report's Unconfirmed list at most.

## F. Plan conformance (plan mode only)

Score against disk, never against EXEC_LOG claims:

- One row per §3 task: `implemented` (code exists and does what the task says — cite module/function) / `partial` (started; name the gaps) / `missing` (no code found; say where you looked).
- Each §4 deliverable that is code, or is produced by code in scope: present at the stated path?
- §5 done-criterion: the machinery to check it exists (a test, an eval script, an assertion) — verify the machinery statically; running heavy checks is the executor's business, not the reviewer's.
- Cross-check EXEC_LOG: files it claims changed exist and contain the claimed change; a claim without matching code is a major finding.

Conformance rows land in the report's scorecard section, separate from the A–E findings.
