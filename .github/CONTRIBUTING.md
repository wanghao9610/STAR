# Maintaining STAR

For people changing STAR itself. **Not** for projects built from STAR — `.github/` is outside
`execs/update.sh`'s sync set, and the Quick Start tells users to delete it.

## The shape of the problem

The fifteen skills exist four times, in `.agents/skills/`, `.claude/skills/`, `.cursor/skills/` and
`.kimi-code/skills/` — 149 markdown files per tree, 596 in all, roughly 93% of the repository. They are
maintained by hand. There is no generator.

So the cost of changing one shared rule is measured in files, not lines. Recent examples:

| Commit | Files | Change |
|---|---|---|
| `78fadc5` | 25 | unify the dial identifier to `involve` |
| `1289ac4` | 26 | advertise the `involve=` token |
| `e9d6d28` | 34 | carry the QA thread across a long question series |

**Before editing four trees, check whether the rule belongs in
`docs/mds/star-workflow/research-workflow-conventions.md` instead.** Consistency check 6 proves every
`SKILL.md` defers to that document, so a rule stated there reaches all fifteen skills in two files
(English and Chinese). `877aaec` fixed the `involve=` token for twelve skills that way, in 2 files
rather than 24. Prefer this whenever the rule is not harness-specific.

## `.claude/skills/` is the baseline

Edit there first, then port outward.

This is not because the other trees resemble it most — they do not. After normalizing the invocation
token and the `disable-model-invocation` line, each tree is about equally far from it:

| Tree | Byte-identical to `.claude` |
|---|---|
| `.agents` | 58 / 149 |
| `.cursor` | 60 / 149 |
| `.kimi-code` | 61 / 149 |

The reason is completeness, which is measurable: **`.claude` never has fewer headings than any other
tree, in any of the 149 files.** Where trees diverge structurally, `.claude` is the superset. Porting
from the longest version means adapting text down, which is safer than reconstructing text that was
dropped — the failure mode in "What the checks do not catch" below.

## What must differ, and what must not

Each tree names its own harness's tools. This is deliberate, and it is the single thing most often
mistaken for drift.

| Tree | Tool | Invocation | Gate | Delegation | User questions |
|---|---|---|---|---|---|
| `.agents` | Codex | `$star-*` | Codex progress-plan | selective delegation | structured user-input tool |
| `.claude` | Claude Code | `/star-*` | `EnterPlanMode` / `ExitPlanMode` | `Agent`, `subagent_type: Explore` / `general-purpose` | `AskUserQuestion` |
| `.cursor` | Cursor | `/star-*` | `SwitchMode` → `plan` | `Task`, `subagent_type: explore` / `generalPurpose` | plain text |
| `.kimi-code` | Kimi | `/skill:star-*` | Plan mode | — | plain text |

Measured distribution, as a sanity check when you are unsure whether something is adaptation or drift:
`AskUserQuestion` appears in 32 `.claude` files and 0 elsewhere; `SwitchMode` in 2 `.cursor` files and 0
elsewhere; `subagent_type` in 24 `.cursor` and 24 `.claude` files, with different values, and 0 in the
other two. A term concentrated in exactly one tree is almost always correct.

**A term appearing in the wrong tree is the actual defect.** Two real cases: 25 `.cursor` asset
templates told users "Claude Code injects it at session start" (`e149ae0`), and `.kimi-code` names
`CLAUDE.md` as the project rules document in 36 places where the others said `AGENTS.md` (`6f37f77`).

Everything else — rules, thresholds, step semantics, write boundaries, rubrics — must not differ.

## `.agents` is a declared variant

`.agents` is a genuine adaptation, not a copy: its executor has 7 steps where the others have 9, and
`stop_line_rules.md` is written as "what **Codex** runs". Its heading structure differs from `.claude`
in 23 files, and those differences are not simple omissions — it restructures.

It is therefore **exempt from the structural check**, and that exemption is a known hole: see below.

## The Kimi description budget

`.kimi-code` **`SKILL.md`** frontmatter descriptions are held to **1050 bytes** (the current maximum is 1041). The other three trees are not, and neither are the `SKILL_zh.md` files — `SKILL.md` is the registered manifest whose description the platform surfaces, while `SKILL_zh.md` is loaded as a resource and runs past 1300 characters.

This is a real convention, not drift, and the evidence is in the shape of the data: every Kimi
description is at or under 1041 bytes, every skill whose `.claude` description already fits is
100–101% of it (untouched), and every skill whose `.claude` description is longer was **rewritten** to
fit — each one still ends in a complete sentence and the `Bilingual (en/zh).` marker, which a hard
truncation would have cut mid-word. Someone condensed these deliberately.

The cost is that condensing loses things silently. Two clauses had gone missing from the English
descriptions and were restored: `star-code-release`'s "prepares a release and never publishes one"
and `star-expt-analyst`'s read-only guarantee and `watch` mode. Both fit inside the budget — those
descriptions were at 890 and 593 bytes, well under the ceiling — so the loss bought nothing.
Both Chinese descriptions had kept the clauses, which is what made the English gap visible.

So when you shorten a description to fit: cut detail, never a guarantee about what the skill will not
do. Check 12 enforces the length; nothing enforces that judgement.

## What the checks catch

`.github/scripts/check_consistency.sh`, run by `.github/workflows/consistency.yml` on push and PR:

1. The four roots carry the same set of skill directories.
2. Frontmatter `name:` matches the directory name.
3. Per-skill file inventory is identical across trees (Codex `agents/` manifests aside).
4. Every skill is guarded against implicit model invocation.
5. Every `.md` has its `_zh.md` twin.
6. Every `SKILL.md` references the conventions document.
7. Invocation tokens are tree-appropriate — no `$star-*` in `.claude`, and so on.
8. Workflow docs ship as en/zh pairs.
9. `.cursor/rules/agent-instructions.mdc` matches the `AGENTS.md` body byte for byte.
10. Provenance hooks exist, are executable, and are registered.
11. **Heading structure matches across `.claude`, `.cursor` and `.kimi-code`** — 1152 headings per tree,
    compared after stripping parentheticals (both `(...)` and `（...）`) and inline code, so
    harness vocabulary inside a heading is allowed to differ. Currently exact, with no exception list.
12. **Kimi `SKILL.md` descriptions stay within their length budget** — see above.

## What the checks do not catch

Be honest with yourself about this list; it is where the real drift lives.

- **Prose content.** Nothing compares the body text of a section. Reversing a rule — "you never publish
  one" to "you may publish one" — passes every check.
- **`.agents` structure**, by the exemption above. Content has been lost there before: `##
  Dialogue Discipline` was missing from 7 of 15 `SKILL.md`, taking an honesty rule in
  `star-refs-reviewer` and the executor's non-interactive fallback with it (restored in `042ece5`).
  Nothing would have caught it, and nothing would catch the next one.
- **Chinese/English divergence in meaning.** Check 5 proves the `_zh.md` file exists; nothing proves it
  says the same thing. Check 11 now proves the two have the same section structure, which is a floor,
  not a guarantee.
- **`docs/htmls/`.** The landing page is not compared against the READMEs or the workflow guide, and
  has drifted from both.
- **Whether a shortened description still says the important thing.** Check 12 enforces the Kimi
  length budget below, but nothing checks that what was cut to fit was expendable — see the budget
  section.

## Before you commit

- Run `bash .github/scripts/check_consistency.sh`. It exits non-zero on failure and is fast.
- Editing `AGENTS.md` means editing `.cursor/rules/agent-instructions.mdc` in the same commit — check 9
  compares their bodies directly.
- Editing a numbered section of the conventions document: do not renumber. Section 7.7 alone has 62
  references across the repository.
- Keep the English and Chinese workflow guides line-aligned. They currently match line for line, which
  makes cross-language diffs readable.
