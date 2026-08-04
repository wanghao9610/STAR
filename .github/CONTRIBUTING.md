# Maintaining STAR

For people changing STAR itself. **Not** for projects built from STAR — `.github/` is outside
`execs/update.sh`'s sync set, and the Quick Start tells users to delete it.

## The shape of the problem

The fifteen skills exist four times, in `.agents/skills/`, `.claude/skills/`, `.cursor/skills/` and
`.kimi-code/skills/` — 151 markdown files per tree, 604 in all, roughly 93% of the repository. They are
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
| `.agents` | 54 / 151 |
| `.cursor` | 59 / 151 |
| `.kimi-code` | 65 / 151 |

The reason is completeness, which is measurable: **`.claude` never has fewer headings than any other
tree, in any of the 151 files.** Where trees diverge structurally, `.claude` is the superset. Porting
from the longest version means adapting text down, which is safer than reconstructing text that was
dropped — the failure mode in "What the checks do not catch" below.

## What must differ, and what must not

Each tree names its own harness's tools. This is deliberate, and it is the single thing most often
mistaken for drift.

| Tree | Tool | Invocation | Gate | Delegation | User questions |
|---|---|---|---|---|---|
| `.agents` | Codex | `$star-*` | `update_plan` | `spawn_agent`, `agent_type: explorer` / `worker` (selective; local by default) | `request_user_input` |
| `.claude` | Claude Code | `/star-*` | `EnterPlanMode` / `ExitPlanMode` | `Agent`, `subagent_type: Explore` / `general-purpose` | `AskUserQuestion` |
| `.cursor` | Cursor | `/star-*` | `SwitchMode` → `plan` | `Task`, `subagent_type: explore` / `generalPurpose` | `AskQuestion` |
| `.kimi-code` | Kimi | `/skill:star-*` | `EnterPlanMode` / `ExitPlanMode` | `Agent`, `subagent_type: explore` / `coder` | `AskUserQuestion` |

Measured distribution, as a sanity check when you are unsure whether something is adaptation or drift:
the question tool splits by name — `AskUserQuestion` in 32 `.claude` and 32 `.kimi-code` files,
`AskQuestion` in 32 `.cursor` files, `request_user_input` in 18 `.agents` files; `SwitchMode` in 2
`.cursor` files and 0 elsewhere, against `update_plan` in 4 `.agents` files; the subagent tool is
`Agent` in 28 files each of `.claude` and `.kimi-code`, `Task` in 28 `.cursor` files, and
`spawn_agent` in 30 `.agents` files: the corresponding 28 delegation-capable files carry `agent_type`,
while the two `star-flow-status` manifests prohibit the call. The former three carry `subagent_type`.
The terminal tool is `Bash` in 30 `.claude` files, `Shell` in 30 files each of `.cursor` and
`.kimi-code`, and lowercase `shell` in `.agents`, which is how Codex writes it; the file reader is
`Read` in 28 files each of `.claude` and `.cursor` and `ReadFile` in 28 `.kimi-code` files, while
`.agents` names none — Codex has no
file-reading tool, so those loads say "file read" and carry a marked fallback that `cat`s the files into
the shell call and accepts the spill. A term concentrated in the trees whose harness actually has it is
almost always correct.

Every one of those names was checked against its harness's own tool list, not against how the other
trees write it: Anthropic's Agent Skills docs, Cursor's tool surface, the Kimi CLI built-in tools
reference, and for Codex the tool handlers in `openai/codex` (`codex-rs/core/src/tools/`), where the
registered names are `shell_command`, `apply_patch`, `update_plan`, `request_user_input` and
`spawn_agent`. Three trees needed correcting: `.cursor` and `.kimi-code` had inherited Claude's `Bash`
(and Kimi also its `Read`), and `.agents` named `Bash`, `Read` and `ask_user_question`, the last of
which Codex has never had.

Codex delegation names the real call without changing the cost stance: **collect locally by default,
delegate selectively**, then call `spawn_agent` only after the bounded / independent / materially
helpful test passes. Read-only collection uses `agent_type: explorer`; file-writing implementation uses
`agent_type: worker`. The built-in `default` type is deliberately unused because every STAR delegation
has one of those two explicit roles. OpenAI's warning that subagent workflows spend more tokens than
the single-agent equivalent is why naming the tool does not make delegation the default.

**A term appearing in the wrong tree is the actual defect.** Two real cases: 25 `.cursor` asset
templates told users "Claude Code injects it at session start" (`e149ae0`), and `.kimi-code` names
`CLAUDE.md` as the project rules document in 36 places where the others said `AGENTS.md` (`6f37f77`).

**The names a port forgets to adapt are the ones no reviewer looks at twice.** `Bash` and `Read` were
carried unchanged into `.cursor`, `.kimi-code` and `.agents` for as long as those trees existed, because
a tool name that reads like an ordinary English word does not look like Claude vocabulary — unlike
`AskUserQuestion`, which does. All three named a tool their harness has never had. `.agents` also named
`ask_user_question`, which is worse than an unadapted name: it is harness-shaped, lowercase and
plausible, so it reads as if someone had checked. Nobody had — Codex calls it `request_user_input`. When
you port a tree, check every tool name against that harness's published tool list, not against how
familiar or how plausible the name feels.

**A capability the harness has since gained is the same defect, aged.** A tree ported while its harness
lacked a mechanism keeps the workaround long after the mechanism arrives, and no check can see it —
the wording is self-consistent, and it is the platform that moved. `.cursor` carried the plain-text
substitute for structured questions at all 132 of `.claude`'s `AskUserQuestion` sites, and said outright
in 4 files that "Cursor has no structured question tool", which had stopped being true. When you port
a workaround, name the capability it stands in for, so the next reader knows what to re-check.

Everything else — rules, thresholds, step semantics, write boundaries, rubrics — must not differ.

## `.agents` is a declared variant

`.agents` is a genuine adaptation, not a copy: its executor has 7 steps where the others have 9, and
`stop_line_rules.md` is written as "what **Codex** runs". Its heading structure differs from `.claude`
in 10 files — six under `star-plan-executor`, four under `star-code-architect` — and those differences
are not simple omissions: it restructures.

It is therefore **exempt from the structural check**, and that exemption is a known hole: see below.

## The description length limit

**`SKILL.md` frontmatter descriptions are capped at 1024 characters, in all four trees.** Not a
per-harness budget: the [agentskills.io `SKILL.md` spec](https://agentskills.io/specification),
Anthropic's Agent Skills docs and the Kimi CLI docs all state `description` is 1–1024. `SKILL.md`
only — it is the registered manifest whose description the platform surfaces, while `SKILL_zh.md` is
loaded as a resource and runs past 1300 characters.

This was long recorded here as a `.kimi-code`-only budget of 1050 **bytes**, because that tree was
the only one anybody had condensed, and the number was reverse-engineered from its data (max 1041)
rather than read from a spec. The guess was close enough to hide two measurement errors, both since
fixed in check 12: awk's `length()` counts bytes, and these descriptions carry `§`, `—` and `→`, so
bytes run up to 8 past characters; and `description: >-` left the folded-block indicator `>-` in the
measured text, inflating every folded file by 3. `1024 + 3 + multibyte slack ≈ 1047` is why 1050
passed for so long.

**A harness may truncate well before the spec limit, and nothing in the repo can catch it.** Cursor
cut three `.agents` descriptions at exactly character 1536, mid-word, back when they ran to 2108, 1665
and 1559 (`star-metd-summarize`, `star-refs-reviewer`, `star-expt-analyst`; all three are inside the
limit now) — so the tail of a long description silently never reaches the listing the agent matches
against. Both numbers matter: 1024 is what the spec allows, ~1500 is where a description starts losing
its ending in practice.

Condensing loses things silently, which is the real cost. Two clauses had gone missing from the
English descriptions and were restored: `star-code-release`'s "prepares a release and never publishes
one" and `star-expt-analyst`'s read-only guarantee and `watch` mode. Both fit inside the limit — those
descriptions were at 890 and 593 characters — so the loss bought nothing. Both Chinese descriptions had
kept the clauses, which is what made the English gap visible. **When you shorten a description to fit:
cut detail, never a guarantee about what the skill will not do.** Check 12 enforces the length;
nothing enforces that judgement.

## What the checks catch

`.github/scripts/check_consistency.sh`, run by `.github/workflows/consistency.yml` on push and PR:

1. The four roots carry the same set of skill directories.
2. Frontmatter `name:` matches the directory name.
3. Per-skill file inventory is identical across trees (Codex `agents/` manifests aside).
4. Slash-only guards match the conventions §10 roster in both directions, and the roster itself lists exactly the skills that exist, with the same rows and † set in the zh edition.
5. Every `.md` has its `_zh.md` twin.
6. Every `SKILL.md` references the conventions document.
7. Invocation tokens are tree-appropriate — no `$star-*` in `.claude`, and so on.
8. Workflow docs ship as en/zh pairs.
9. `.cursor/rules/agent-instructions.mdc` matches the `AGENTS.md` body byte for byte.
10. Both session hooks — model-id provenance and project memory — exist, are executable, and are
    registered in all four harnesses' registration files.
11. **Heading structure matches across `.claude`, `.cursor` and `.kimi-code`** — 1200 headings per tree,
    compared after stripping parentheticals (both `(...)` and `（...）`) and inline code, so
    harness vocabulary inside a heading is allowed to differ. Currently exact, with no exception list.
12. **Every tree's `SKILL.md` descriptions stay within the 1024-character spec limit** — counted in
    characters, with the folded-block indicator excluded. See above; a harness truncating earlier than
    the spec is not checkable here.
13. **Skill helper scripts are byte-identical across the four trees, and executable.** A script names no
    harness, so it has nothing to adapt; a copy that has drifted is a bug, not a variant.
14. **`.agents` manifests carry the same `##` sections as `.claude`** — the set, not the sequence, since
    check 11 exempts `.agents` and content had already been lost through that gap.
15. **Shared scripts parse, and the strings they match byte-exactly still have a producer.** Check 13
    compares the four copies against each other, so a break introduced into all four at once — which is
    how these files are normally edited — passes it. This one runs `bash -n` on each copy, and holds a
    registry of the strings a scanner matches on against the templates that must still write them.
    `【待定】` is why it exists: `star-plan-decomposer` wrote it into every Chinese sub-plan, `scan.sh`
    counted only `[TBD]`, and the "too coarse to run" rule silently never fired on a Chinese project
    from `ab4246c` to `9c25079` with CI green the whole time.
16. **Numbered citations of `AGENTS.md` sections still name the section they claim.** 16a pins the
    heading map, so renumbering or retitling a section fails here before anything else notices. 16b
    re-checks the citations that carry a label — `§8 layout`, `布局符合度（§8）` — against the live map.
    The drift it exists for shipped twice: layout and runtime moved to §8 and §9, and both
    `star-code-reviewer` and `star-expt-analyst` kept citing §5 and §6 with CI green, because no check
    had ever looked at a citation.
17. **The conventions document's numbered structure is pinned, and the workflow docs stay line-aligned
    across languages.** Skills cite that file at sub-section granularity — §7.7 sixty-four times, §6.3
    forty — so inserting an item into the middle of a section repoints every citation after it. The
    headings are pinned; item counts are pinned for the sections whose items are cited (§1, §3, §4, §5,
    §6, §7), and both languages are counted, since a §n that means different things per language is the
    same bug. The line-count parity is the "keep them line-aligned" rule below, enforced.
18. **The skills guide and the two READMEs stay tied to the skills they describe.** Roughly 69% of that
    guide paraphrases the fifteen `SKILL.md` files, which are authoritative and change far more often.
    This holds the joins a script can see, across all four documents: every relative link target on
    disk (the guide's per-section "complete definition" links included); every `conventions §n.m`
    citation landing on a section and an item that exists; every in-page anchor still matching a
    heading. On skill coverage the two shapes differ — the guide owes one numbered section per skill
    and no more, the READMEs only have to name each skill, since there it is a table row. What a
    section *says* about a skill is checked by nobody.
19. **The opening-load shape holds in every tree.** One `.env` probe line per file, no `cat` of the
    whole conventions file inside a Bash block (only `.agents`' fallback sentence may, and it is marked
    "accept the spill" / "接受落盘"), `SKILL_zh.md` never a runtime load, and the two passages that are
    uniform across all sixty file pairs by design — the language paragraph and the `SKILL_zh.md` header
    blockquote — still identical, so a partial re-edit shows up. The strings it pins are the probe line
    and those two openings; rewording any of them centrally means updating the check in the same commit.
20. **A skill that loads only part of the conventions says so accurately, and stays under the spill
    line.** Two skills take an `awk` excerpt of the sections they act on rather than the whole file
    (`star-expt-digest`, `star-refs-reviewer`). Per such file: the excerpt prints exactly the sections
    its regex names, so a renumber upstream fails here; it reads its own language's conventions file;
    it stays under `LOAD_EXCERPT_MAX` (28000 bytes), which is the only place that can be caught, since
    `execs/update.sh` copies the conventions wholesale into downstream projects and the file can only
    grow here; the prose's loaded list equals the regex's set and its stay-out list equals the
    complement; and the size the prose quotes matches the size the selector produces. Citations of a
    section a skill no longer loads must be pinned in `RESTATED_REGISTRY`, checked per tree and per
    language in both directions, so both an unregistered citation and an orphaned row fail. Pinned
    strings: the selector shape, and the phrases splitting the two lists in prose ("stay out",
    "不装载"). Deliberate gap: `star-flow-status` also loads part of the conventions, but through `sed`
    ranges plus an item-level pass over §7, which a section-level parser cannot verify.
21. **Every manifest carries the reuse-an-earlier-load paragraph, uniform per language, inside the
    opening-load block.** That paragraph is what lets a second skill in the same conversation skip the
    parts of the load it can still see verbatim, so a multi-skill session pays for one load rather than
    N. Three ways of losing it are invisible to everything above: dropping it from one tree, since
    checks 1–3 compare file sets and not contents; rewording it in one tree, so the four trees disagree
    about what may be skipped; and moving it below the first `##` heading, where it stops being part of
    the load the reader is deciding about. It must also carry no bare `§n` — check 20d reads every `§n`
    in that same block as a claim about which sections the skill loads.

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
- **Whether a shortened description still says the important thing.** Check 12 enforces the length
  limit, but nothing checks that what was cut to fit was expendable — see the description-length
  section. Nor does anything catch a harness truncating a description that is inside the limit.
- **Whether the skills guide still describes the skill correctly.** Check 18 proves a section exists
  for each skill and that its links resolve. Rewrite a skill's workflow and leave the guide's "What it
  does" list describing the old one, and every check stays green.
- **A bare `§n` citation.** Most citations of `AGENTS.md` are bare — `(AGENTS.md §3)` says nothing
  about what §3 contains, so check 16b cannot verify it. Only 16a stands behind those: it makes the
  renumber loud, not the citation correct.
- **A newly grepped string that nobody registered.** Check 15 holds a hand-written registry: add a
  byte-exact match to a scanner without adding its row, and the next person to reword the producer
  breaks it silently, exactly as before. When you teach a script to match on a new string, register it
  in the same commit.

## Before you commit

- Run `bash .github/scripts/check_consistency.sh`. It exits non-zero on failure and is fast.
- Editing `AGENTS.md` means editing `.cursor/rules/agent-instructions.mdc` in the same commit — check 9
  compares their bodies directly.
- Editing a numbered section of the conventions document: do not renumber. Section 7.7 alone has 62
  references across the repository. Check 17 holds the section headings and the item counts; adding an
  item to §1, §3, §4, §5, §6 or §7 fails it until every `§n.m` citation has been re-audited.
- Same for `AGENTS.md`: renumbering a section means re-auditing every `§n` citation in the skill trees
  and updating `AGENTS_SECTIONS` in the check script. Check 16 fails until both are done.
- Keep the English and Chinese workflow guides line-aligned. They currently match line for line, which
  makes cross-language diffs readable — and check 17 now fails if a pair stops matching.
