# Dropping a plan, and taking one back

Read where the run is a drop or a revival — the argument or the description asks for one, or Step 0 finds the target already carrying `dropped:`. A review, and every revision that comes out of one, never reads this file. A drop that comes up *during* a full review is not this path: it is a Step 4 candidate, approved like any other, writing the same three places named below.

A drop records a decision you have already made, so this path does not audit the plan: Step 0 resolves the target as always, the four steps below replace Steps 1–6, Step 7 reports as always, and nothing here writes a review report. The description routes a run here (conventions §7.12), so say in one line which path this run took before reading anything — a misread description then costs that line rather than an edit.

1. **Read what goes dark**, from the opening digest alone — no collectors, no run bodies: every descendant of the target with its `exec_status`, the follow-ups their runs were owed (a review, an analysis), any unmerged `branch:`, live `worktree:` or un-ticked STOP command underneath, and any live leaf whose `depends_on` names the target or one of its descendants.
2. **Show that list and ask once** — one line per descendant, one line per loose end — confirming the drop and its one-line reason in the same question; the reason is the description's own words where it carried them, and asked for where it did not. This is a mandatory confirmation point (conventions §7.7): asked at every involve level, `low` included, never bundled with anything else. No reason, no drop.
3. **Write the three places** `references/revision_rules.md` names — `dropped: <date> — <reason>` on the target, the `— dropped <date>` marker on the parent's `## Sub-plans` line, one `## Revision History` entry — and bump `updated`. No descendant is edited: they go dark by inheritance.
4. **Report** what went dark and what the drop did not settle — dependency edges now pointing at a dropped node, and any branch, worktree or STOP command still on disk — then the commit offer, as Step 7.

Taking a node back is the same walk with the field cleared instead of written — a description asking for it routes there — plus one check before the question: no ancestor may be dropped, or inheritance keeps the node dark and the cleared field reads as a bug. Its Revision History entry says why the direction is live again.

A drop that comes up *during* a full review is not this mode — it is a Step 4 candidate, approved like any other, writing the same three places.

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
