# Revision Rules — authority, trail, and knock-on effects

What star-plan-reviser may change, how changes are recorded, and what must be routed elsewhere. One session revises **one target file** (plus, at most, the single matching index line in its parent).

## Authority table

| Target | Allowed? |
|---|---|
| target plan body §1–§6 (root or sub-plan) | yes — per-item user approval: the whole candidate list on the page, settled in one question over it (conventions §7.13) |
| target frontmatter `updated` | yes — always bumped after any edit |
| target section `status` map | yes — to reflect the post-edit content honestly |
| target frontmatter `depends_on` | yes — only as an approved candidate; must remain an acyclic list of sibling prefixes |
| target frontmatter `exec_status` | yes — only via the reset rule below, with explicit approval |
| target frontmatter `dropped:` | yes — only as an approved candidate, under the drop rule below |
| the dropped subtree's files on disk (plan files, `tasks/<plan-name>/`, `wkdrs/<run>/` dirs, `execs/scpts/<run>.sh`) | yes — only the move to or from their `dropped/` locations that an approved drop or revival carries (`drop_rules.md`); their contents are never edited |
| parent `## Sub-plans` line for the target | yes — only when the target's title / one-line objective changed, or to add or remove its drop marker |
| target `## Sub-plans` outline lines (units not yet expanded — conventions §0) | yes — as approved candidates: reword, reorder, add or remove outline lines; entries for expanded child files stay with star-plan-decomposer |
| `EXEC_PLAN.md` / `EXEC_LOG.md` | never — runs belong to the executor; reviews are written *next to* logs, not into them |
| numeric prefixes / filenames | never — no renumbering, no renaming, no `_v2` forks, no deletion (a drop's move keeps every filename; only the directory changes) |
| sibling or child plan bodies | never in this session — run the reviser on that file separately, or route to star-plan-decomposer |
| `## Revision History` (target) | append-only — a new entry goes below the last one; never rewrite past entries |

## Routing, not editing

- **structural** — adding/removing sub-plans, changing granularity, redrawing dependency edges across siblings → recommend star-plan-decomposer. (Editing the *target's own* `depends_on` list is a local, approvable candidate — and so is amending the target's outline lines, units not yet expanded into files: they are text, not structure. Expanding one into a file is the decomposer's.)
- **strategic** — the research question, the core method bet, or the direction itself is overturned → recommend star-plan-coach.

A bounded text edit of a strategy section is still local and allowed: tightening a kill-criterion, re-dating a milestone, recording that an assumption was validated or failed. "The method is dead, replace it" is not an edit — it is a coaching conversation.

## Revision History format

Appended at the end of the plan file (after `## Sub-plans` if present); created on the first revision, each new entry below the previous one:

```markdown
## Revision History

### 2026-07-16 — star-plan-reviser · claude-opus-4-8 (report: wkdrs/01_mvp-verify/REVIEW_2026-07-16.md)
- §3 step 4: batch eval → streaming eval — the run OOMs at step 4 (evidence: EXEC_LOG.md step 4, blocked)
- §5: mIoU threshold 85 → 80 — the MVP run reached 82.3 and the root's §4 margin analysis accepts 80 (evidence: wkdrs/01_mvp-verify/eval.json)
- exec_status: done → pending (done-criterion changed)
```

One `###` block per session, real date (never invented), and after the skill name the editing session's `model_id` — the runtime's reported id copied verbatim, or `unrecorded` (conventions §8). That per-entry id gives a plan its model attribution: the frontmatter `model_id` names only the latest writer; this section preserves who wrote each earlier revision. One bullet per change: section, what changed, why, evidence. Record `exec_status` resets and a cleared `finalized:` here too, and optionally a declined candidate worth remembering ("user kept the 85 threshold despite the miss"). A drop is one more bullet — `dropped: 2026-08-11 — superseded by 02` — carrying the account of what ended the direction, since the frontmatter field holds only one line.

## exec_status reset rule

| Situation after edits | Action |
|---|---|
| §5 done-criterion materially changed and the leaf was `done` / `blocked` | offer a reset to `pending` (`exec_runs` keeps the history either way) |
| §3 gained or materially changed steps and the leaf was `done` | offer a reset to `pending` |
| leaf was `in_progress` | leave it — the executor re-orients from `EXEC_LOG.md` on its next run |
| edits touch only §1/§2/§4 prose or §6 risks | no reset — bump `updated` only |

Never reset silently; the offer names the consequence (the leaf rejoins the runnable queue in star-flow-status / star-plan-executor).

## Dropping a plan (`dropped:`)

What a drop writes, what it never touches, and the walk back are in `drop_rules.md`, read where the run is a drop or a revival and not before.

## Section status flips

- An edit that introduces `[TBD]` / `【待定】` → that section becomes `in_progress`.
- A confirmed rewrite with no open gaps → the section stays (or becomes) `done`.
- Never mark a section `done` while it still carries `[TBD]`.

## Knock-on effect duties

- Bump `updated` on every edited file. Downstream, star-flow-status flags children older than a revised parent — that staleness is the intended signal, not a bug to suppress.
- If the revised content is something children were derived from, name the affected children in the final report and recommend re-decomposition for them.
- After edits, verify `children:` entries and `depends_on` prefixes still resolve; report dangling references — do not silently repair them.

## Language

Edits and the review report follow the plan's frontmatter `language`; technical terms stay in English inside Chinese plans. The dialogue language never rewrites a file's language — that takes an explicit user request.
