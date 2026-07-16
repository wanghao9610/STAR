# Review Spec — evidence collection & report definition

How star-plan-reviser gathers evidence and what each report section must contain. Collectors are **read-only**: they never create, edit, or delete files, and they report facts, not revision opinions. Everything in the report comes from files on disk — never from chat memory.

## Evidence sources

| Source | What it yields |
|---|---|
| the plan file itself | intent: §1 objective, §3 tasks, §4 deliverable paths, §5 done-criterion, §6 risks; frontmatter `status` / `exec_status` / `exec_run` / `depends_on` / `children` / `updated` |
| `wkdrs/<exec_run>/EXEC_PLAN.md` | the actions the executor committed to, and where the STOP line fell |
| `wkdrs/<exec_run>/EXEC_LOG.md` | step statuses, bound-check results, artifact paths, "Awaiting user" commands, Notes/decisions incl. **Strategy signal** entries |
| `wkdrs/<exec_run>/EXPT_ANALYSIS_<date>.md` (when present) | star-expt-analyst's results audit: the run verdict, the done-criteria scorecard with each metric's source, log health, and the interpretation incl. kill-criteria hits — a pre-verified evidence base, still cross-checked against disk like any other claim |
| §4 deliverable paths | artifacts on disk: existence, size, mtime, cheap sanity |
| `${CODE_NAME}/` modules named in §2/§3 | whether promised code exists and plausibly matches the log's claims |
| children frontmatter (root/internal targets) | per-child section status, `exec_status`, `updated`, `depends_on` |
| executed descendants' logs (root/internal targets) | kill-criteria hits and strategy signals that bear on this node's assumptions |

Missing evidence is reported as "unknown" or "absent" — never guessed.

## Collector contracts (structured returns)

**Log collector** — for one run dir:

- `steps` — id / title / status / claimed check result / claimed artifact path, one line each
- `awaiting_user` — commands recorded as waiting for the user, or `none`
- `strategy_signals` — Strategy-signal or kill-criterion notes, quoted, or `none`
- `log_gaps` — missing or malformed fields in the log, or `none`

**Artifact collector** — for each §4 deliverable path:

- `path` / `exists` / `size` / `mtime`
- `sanity` — one cheap content check (non-empty, parses, expected row/key count), or `not cheaply checkable`
- `verdict` — `found` / `missing` / `suspect` (exists but fails sanity, or predates the step that claims it)

**Code collector** — for each named module/entrypoint:

- `path` / `exists` / `consistent` (does the file's state plausibly agree with what the log claims was created/modified?) / `notes`

All collectors: read-only; return "unknown" over guessing; no revision proposals; touch nothing under `datas/`, `inits/`, or `wkdrs/` beyond reading.

## Verification ladder

Score each completion claim by the highest rung that actually holds:

1. the log says `done` →
2. …and the bound artifact exists on disk →
3. …and a cheap re-check passes.

| Verdict | Meaning |
|---|---|
| `met` | every rung applicable to the item holds (a step with no artifact can be met at rungs 1+3) |
| `partial` | some sub-items hold, others do not |
| `unmet` | evidence positively shows it did not happen or failed |
| `unverifiable` | claims without artifacts, artifacts not cheaply checkable, or contradictions (log `done`, artifact missing) |

Never promote `unverifiable` to `met` on the log's word alone.

**Cheap-check boundary**: file existence / size / head, a tiny parse, a checksum, a unit-test-scale command — roughly under a minute, no GPU, no paid API, no side effects. Everything beyond is heavy: do not run it; note in the report what a full re-verification would take.

## Scoping by node type

- **Leaf**: the full ladder over its own run.
- **Root/internal**: do not fan out per descendant — read children frontmatter directly; run log collectors only on runs that exist; audit this node's own §1–§6 assumptions against the aggregated signals (a child's strategy signal is evidence against a parent assumption).
- **No execution evidence anywhere**: document-only review — the scorecard reads `unverifiable`/absent; divergences and candidates draw on the plan text and on what the user supplies.

## Report sections

1. **Intent recap** — the objective in 1–2 lines; a leaf quotes its §5 done-criterion verbatim, a root/internal states its finalized status and the key claims/assumptions it rests on.
2. **What actually happened** — steps done / blocked / skipped; artifacts verified on disk; commands still under "Awaiting user"; children rollup for root/internal targets.
3. **Completion scorecard** — one row per §3 task plus one row for the §5 done-criterion: verdict + evidence pointer.
4. **Divergences** — planned X but did Y; extra work not in the plan; assumptions the evidence contradicts; kill-criteria hits and quoted strategy signals.
5. **Blockers & leftovers** — blocked steps with cause; remaining `[TBD]` / `【待定】`; questions the run raised but did not answer.
6. **Ripple map** — reverse `depends_on` edges (siblings that list this node), children derived from it, and which revision candidates would invalidate what.
7. **Revision candidates** — numbered; each names the target section, what to change, the evidence, a proposed-edit sketch, and a blast radius grade.

**Evidence pointers** are concrete: `path[:line]`, a command plus its output snippet, or a frontmatter field — at least one per claim.

**Blast radius**: `local` (this file's prose/frontmatter) / `structural` (tree shape or cross-sibling dependency edges → star-plan-decomposer) / `strategic` (research question, method bet, or kill-criteria overturned → star-plan-coach).

Sections with nothing to say collapse to a single line ("None observed.") — never pad.
