# Scope Spec — the four selectors, run dating, and the last covered date

A digest is only as honest as its period. This file defines how the argument becomes a run set, how a run is dated, and how the series resumes without skipping or double-counting work.

## The four selectors

Interpret the argument, **first match wins**:

| Argument | Mode | Scope |
|---|---|---|
| *(none)* | `incremental` | every run dated in `(last covered date, today]`, all plan trees |
| `<N>d` (`7d`, `30d`) or `<YYYY-MM-DD>` | `window` | every run dated in `[start, today]`, all plan trees |
| a slug / numeric prefix / filename | `plan` | the node's **family**, no time bound |
| `all` | `all` | every run in the project, all plan trees |

`<N>d` starts `N` days before today, inclusive. A bare `<YYYY-MM-DD>` means "since that date", inclusive. An argument that parses as neither a window nor a plan name is not a guess to make: list the nearest plan candidates and ask (conventions §5.2).

**Plan mode is a family, not a subtree.** Given a node, the run set is every run of every **descendant leaf** — that is the evidence. Its **ancestors up to the root** are read too, but only for context: the root's §4 claim map and §5 kill-criteria are what make a leaf's number mean something, and the digest's headline is written against them. An ancestor contributes no runs of its own; internal nodes are not executable (conventions §5.4). This is what "including parent and sub-plan results" means: the parent asks, the descendants answer.

**A dropped node's runs stay in scope.** A direction given up (`dropped:`) took its evidence with it — those runs happened, and the result that ended the direction is often the most useful line in the digest. Report them with `(dropped <date>)` beside the plan name, never as work still pending, and list the drop itself among the plan-level changes.

## Dating a run

A run's date decides whether it falls in the window. Take the **first available**:

1. the date in its newest `wkdrs/<run>/EXPT_ANALYSIS_<YYYY-MM-DD>.md` filename;
2. else the last dated entry in its `wkdrs/<run>/EXEC_LOG.md`;
3. else the run is **undatable** — list it in the digest's gaps with the reason, and include it only in `plan` and `all` modes, where no window has to be satisfied.

**Never use file mtime.** It moves for a checkout, a formatter, a `cp -r`, a backup — and a digest keyed on mtime silently reshuffles history. This is the same discipline conventions §4 sets for written dates and `status_spec.md` applies to staleness.

A run is dated **once**, by the rule above, even when its two candidate dates disagree. A run executed in April and analyzed in July is a July run for windowing, because the digest reports when the *evidence* was in place, not when the GPU ran. Say so in the run's row when the two dates differ by more than the window's own length.

## The last covered date

The last covered date is the newest digest's `covers.through` — read from frontmatter, never inferred. It makes `star-expt-digest` with no argument mean "since last time".

**Resolving the incremental window:**

- A digest exists → the window is `(covers.through, today]`, half-open at the start so the previous digest's last day is not reported twice.
- No `wkdrs/digests/` at all, or it holds no digest → this is the first digest. The window is the whole history, and the file records `mode: incremental` with `covers.from: —` and `previous: —`.

**Advancing it.** Only a digest whose period **ends today** advances the series. Concretely:

- `incremental` and `<N>d` / `<YYYY-MM-DD>` windows end today → they advance it.
- `plan` mode has no time bound, and a retrospective read is not progress → it writes `covers.through` as the newest in-scope run date and **does not** become the resume point for the next incremental run.
- `all` ends today and restarts the series → it advances it.

The rule this protects: **a backward-looking digest must never cause the next incremental run to skip work.** A `plan`-mode digest whose `covers.through` is an old date is naturally ignored by the max — but one written *today* over a family whose runs all finished today would otherwise poison it. So the next incremental run takes the newest `covers.through` **among digests whose `mode` is `incremental`, `window`, or `all`**.

## Overlap and re-runs

- Two digests **may** cover overlapping periods: a `7d` digest written for a report on Friday does not invalidate Monday's incremental one. Overlap is visible because every digest states its own window.
- Re-running the same selector on the same day **overwrites that day's file** (conventions §4.3). It does not append and does not create `_v2`.
- A run appearing in two digests is expected and needs no reconciliation. What must never happen is a run appearing in **none** — which the half-open incremental window and the `plan`-mode exception above prevent.

## Frontmatter format

```yaml
---
type: digest
language: <en|zh>
generated: <YYYY-MM-DD>          # a real date from the system clock; never invented
mode: <incremental|window|plan|all>
scope: <all plan trees | family of <prefix>_<slug>>
covers:
  from: <YYYY-MM-DD or "—">      # "—" only when the period is unbounded at the start
  through: <YYYY-MM-DD>
previous: <EXPT_DIGEST_<YYYY-MM-DD>.md or "—">
sources:                          # every run this digest reported, both tiers
  - run: <prefix>_<slug>
    report: <EXPT_ANALYSIS_<YYYY-MM-DD>.md or "none">
    tier: <report-backed|provisional>
    verdict: <met|partially met|not met|inconclusive|invalid|—>
---
```

`sources:` is load-bearing twice over: the baseline the **next** digest diffs against to derive "what moved" (`digest_rubric.md`), and the record of which runs were still provisional when this digest was written. `verdict: —` is correct for a provisional row — a provisional run has no verdict, and writing one in would be inventing the judgment this skill is not allowed to make.
