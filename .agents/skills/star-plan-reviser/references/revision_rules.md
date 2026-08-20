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
| parent `## Sub-plans` line for the target | yes — only when the target's title / one-line objective changed, or to add or remove its drop marker |
| `EXEC_PLAN.md` / `EXEC_LOG.md` | never — runs belong to the executor; reviews are written *next to* logs, not into them |
| numeric prefixes / filenames | never — no renumbering, no renaming, no `_v2` forks, no deletion |
| sibling or child plan bodies | never in this session — run the reviser on that file separately, or route to star-plan-decomposer |
| `## Revision History` (target) | append-only — a new entry goes below the last one; never rewrite past entries |

## Routing, not editing

- **structural** — adding/removing sub-plans, changing granularity, redrawing dependency edges across siblings → recommend star-plan-decomposer. (Editing the *target's own* `depends_on` list is a local, approvable candidate.)
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

A direction given up on — a node the flow should stop counting, recommending, and building on. The field goes on the node where the decision was made and nowhere else: every skill reads it as inherited, so one line takes the whole subtree out, and a child added under that node later is dropped with it.

| What | Rule |
|---|---|
| Value | `dropped: <YYYY-MM-DD> — <one-line reason>`, the date from the system clock (conventions §4). The full account — what was tried, what ended it, what replaces it — goes in the same session's `## Revision History` entry. |
| Approval | a candidate of this skill's own, asked on its own: the question names what goes dark with it — the node, every descendant, and the follow-ups their runs were owed. It is **not** one of the strategic candidates that route to star-plan-coach: dropping a direction records a decision already made, while choosing what replaces it is the coaching conversation. |
| Scope of the edit | this field, plus a `— dropped <date>` marker on the parent's `## Sub-plans` line. Nothing else — the parent keeps its `children:` entry (deleting the link would strand the child's `parent:` and erase the record that this was tried), and every descendant keeps its own frontmatter, an `exec_status: done` and its `exec_runs` included. |
| Rolled up | append one line to the root plan's §5 dead ends: this node, one sentence on which result ruled it out, and what not to attempt again. The node's own revision history keeps the full account, but the subtree has gone dark — nobody opens that file again. The root's line is what gets read months later, writing the limitations section or answering a reviewer. |
| Prefixes | a dropped sibling keeps its number; the next child takes the next free one (conventions §5.6). |
| Undropping | clearing the field, a candidate like any other. Check first that no ancestor is dropped — inheritance would keep the node dark, and the cleared field would then read as a bug. |
| What it does not settle | an unmerged execution branch, a live worktree, or an un-ticked STOP command under the dropped subtree. Name them in the final report: the records are rescued and the branch discarded through star-plan-executor (conventions §11.6), never here. |

Two ways in, one rule. A description that gives the direction up routes the run to the drop path (`SKILL.md`), which skips the audit because the decision is already made; a drop that surfaces during a full review is a Step 4 candidate. Both write exactly the three places above.

`exec_status: abandoned` is still one leaf's execution outcome. `dropped:` is about the node: it takes that node and everything under it out of the counts, the follow-up checks and the next action. A leaf can carry both, and the plan-level field is what the tree renders.

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
