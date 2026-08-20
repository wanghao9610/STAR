# Maintaining STAR

For people changing STAR itself. **Not** for projects built from STAR — `.github/` is outside
`execs/update.sh`'s sync set, and the Quick Start tells users to delete it.

## The shape of the problem

The fifteen skills exist seven times, in `.agents/skills/`, `.claude/skills/`, `.cursor/skills/`,
`.dsh/skills/`, `.kimi-code/skills/`, `.pi/skills/` and `.qwen/skills/` — 157 markdown files per
tree, 1099 in all, roughly 92% of the repository. Sixty-one of those files per tree are not copies:
no tree words them differently, so they are one file under `.agents/skills/` that the rest link to.
The other 96 are written by `.github/scripts/port.sh` from the one authored copy in `.claude/skills/`,
through a per-harness substitution table and an override list holding every span a tree genuinely
words for itself. CI runs the check; a tree edited directly stops being what those produce.

`.agents/skills/` is not one of those tools' private tree. It is where the `AGENTS.md` convention puts
skills, so Codex scans it as its only project root, Cursor scans it as a native root, and Pi and DSH
read it beside their own — any agent following the convention finds the same fifteen skills there.
That is why it is the one tree naming no harness's tools; see "What must differ, and what must not".

So the cost of changing one shared rule is measured in files, not lines. Recent examples:

| Commit | Files | Change |
|---|---|---|
| `78fadc5` | 25 | unify the dial identifier to `involve` |
| `1289ac4` | 26 | advertise the `involve=` token |
| `e9d6d28` | 34 | carry the QA thread across a long question series |

**Before editing seven trees, check whether the rule belongs in
`docs/mds/star-workflow/research-workflow-conventions.md` instead.** Consistency check 6 proves every
`SKILL.md` defers to that document, so a rule stated there reaches all fifteen skills in two files
(English and Chinese). `877aaec` fixed the `involve=` token for twelve skills that way, in 2 files
rather than 24. Prefer this whenever the rule is not harness-specific.

## `.claude/skills/` is the baseline

Edit there first, then port outward.

This is not because the other trees resemble it most — they do not. After normalizing the invocation
token and the `disable-model-invocation` line, each tree is about equally far from it:

Sixty-one of the 157 Markdown files are not copies at all — no tree words them
differently, so they are one file under `.agents/skills/` that the rest link to.
Of the 96 each tree does word for itself:

| Tree | Byte-identical to `.claude` |
|---|---|
| `.agents` | 43 / 96 |
| `.cursor` | 51 / 96 |
| `.dsh` | 52 / 96 |
| `.kimi-code` | 56 / 96 |
| `.pi` | 48 / 96 |
| `.qwen` | 52 / 96 |

The reason is completeness, which is measurable: **`.claude` never has fewer headings than any other
tree, in any of the 157 files.** Where trees diverge structurally, `.claude` is the superset. Porting
from the longest version means adapting text down, which is safer than reconstructing text that was
dropped — the failure mode in "What the checks do not catch" below.

## What must differ, and what must not

Each of the six named trees names its own harness's tools; the shared root names none, because it
belongs to no one harness. This is deliberate, and it is the single thing most often mistaken for
drift.

| Tree | Tool | Invocation | Gate | Delegation | User questions |
|---|---|---|---|---|---|
| `.agents` | any agent reading the `AGENTS.md` root | `star-*`, no prefix | "your plan tool" | "a read-only sub-agent" / "a writing sub-agent" | "your question tool" |
| `.claude` | Claude Code | `/star-*` | `EnterPlanMode` / `ExitPlanMode` | `Agent`, `subagent_type: Explore` / `general-purpose` | `AskUserQuestion` |
| `.cursor` | Cursor | `/star-*` | `SwitchMode` → `plan` | `Task`, `subagent_type: explore`; writing delegates set no type | `AskQuestion` |
| `.dsh` | DSH | `/skill:star-*` | `exit_plan_mode` only — the human turns plan mode on | `subagent`, no type parameter at all | `ask_user_question` |
| `.kimi-code` | Kimi | `/skill:star-*` | `EnterPlanMode` / `ExitPlanMode` | `Agent`, `subagent_type: explore` / `coder` | `AskUserQuestion` |
| `.pi` | Pi | `/star-*` | `/star-plan` is the user's switch, so the skill holds the gate itself | `star_subagent`, `agent:` naming a `.pi/agents/` entry | `star_questionnaire` |
| `.qwen` | Qwen Code | `/star-*` | `enter_plan_mode` / `exit_plan_mode` | `agent`, `subagent_type: Explore` / `general-purpose` | `ask_user_question` |

Measured distribution, as a sanity check when you are unsure whether something is adaptation or drift:
the question tool splits by name — `AskUserQuestion` in 32 `.claude` and 32 `.kimi-code` files,
`AskQuestion` in 32 `.cursor` files, `ask_user_question` in 32 `.qwen` files; `SwitchMode` in 2
`.cursor` files and 0 elsewhere; the subagent tool is `Agent` in 28 files each of `.claude` and
`.kimi-code`, `Task` in 28 `.cursor` files, and `agent` in the same 28 `.qwen` files (its two
`exec_plan` templates use the bare word for the role, not the tool, so a plain grep there returns 30).
All four carry `subagent_type`.
The terminal tool is `Bash` in 30 files each of `.claude` and `.kimi-code`, `Shell` in 30 `.cursor`
files, and `run_shell_command` in 30 `.qwen` files; the file reader is `Read` in 28 files each of
`.claude`, `.cursor` and `.kimi-code` and `read_file` in 28 `.qwen` files. A term concentrated in the
trees whose harness actually has it is almost always correct.

**`.agents` appears in none of those rows, because its count in each of them is zero**, and check 23 is
what holds it there: its banned list is the union of the others' — every harness's file reader,
terminal, question tool and plan tool, Codex's included. A load in that tree says "file read", a
terminal call says
"shell" as the ordinary English word rather than as a name, and it still carries the marked fallback
that `cat`s the files into the shell call and accepts that the result is written out, because a
harness arriving there may have no file-reading tool: Codex, whose only project root this is, has none.

Every one of the six named trees' names was checked against its harness's own tool list, not against
how the other trees write it: Anthropic's Agent Skills docs, Cursor's tool surface, the [Kimi Code CLI
built-in tools reference](https://moonshotai.github.io/kimi-code/en/reference/tools.html), and for
Qwen Code its own source and the skills it bundles. Codex's list is the tool handlers in
`openai/codex` (`codex-rs/core/src/tools/`), where the registered names are `shell_command`,
`apply_patch`, `update_plan`, `request_user_input` and `spawn_agent` — the list a change under
`.codex/` is still checked against, and the one `.agents` was checked against while it spoke Codex.
One tree needed correcting: `.cursor` had inherited Claude's `Bash`. `.kimi-code`
needed neither correction — Kimi Code CLI's file tools are `Read`, `Write`, `Edit`, `Grep`, `Glob` and
`ReadMediaFile`, and its terminal is `Bash`, the same names Claude publishes — and the delegation it
does need holds: the `Agent` tool takes `subagent_type`, whose built-in values are `coder` (default),
`explore` and `plan`, and whose questions take `multi_select` where Claude writes `multiSelect`.

**Qwen Code publishes two names per tool, and only one of them belongs in a manifest.** The identifier
the model calls is snake_case — `run_shell_command`, `read_file`, `grep_search`, `edit`, `write_file`,
`glob` — and beside it sits a display label the interface shows: `Shell`, `ReadFile`, `Grep`, `Edit`,
`WriteFile`. Qwen Code's own bundled skills write only the identifiers; `ReadFile` and `Bash` appear
zero times in them. So this tree writes identifiers, and check 23 bans the labels here rather than
accepting them as a second correct spelling — a label in a manifest is a half-finished port. The
distinction is not only editorial: the commit guard's `PreToolUse` matcher is `run_shell_command`, and
a matcher naming `Shell` would match nothing, silently. The rest follows the same rule — plan mode is
`enter_plan_mode` / `exit_plan_mode`, delegation is the `agent` tool with `subagent_type` (`Explore`,
`general-purpose`, `fork`), and structured questions are `ask_user_question`, whose parameter is
`multiSelect`, the same camelCase Claude Code uses and the opposite of Kimi's `multi_select`.

Qwen Code takes all four STAR hooks: model-id provenance and project memory on `SessionStart`, the
commit guard and the involve gate on `PreToolUse`. That makes it the third harness carrying the involve
gate, after Claude and Codex, because its `PreToolUse` can answer `permissionDecision: "allow"`.
Registration is the project's own `.qwen/settings.json`, loaded automatically, so there is no
global-install step like Kimi's — but a command hook's `timeout` there is in milliseconds, where every
other harness counts seconds.

`.cursor` used to be the tree with nothing to cite, and no longer is. The prose pages still publish
capabilities rather than identifiers — "Read files", "Run shell commands", a page titled
[Terminal](https://cursor.com/docs/agent/tools/terminal) — which is why `Read` and `Shell` began as
descriptive names this repository chose rather than names read off a list. Two config surfaces now
publish them: [hooks](https://cursor.com/docs/hooks) gives the `preToolUse` matcher values as
"`Shell`, `Read`, `Write`, `Grep`, `Delete`, `Task`, and MCP tools using the `MCP:<tool_name>`
format", and [permissions](https://cursor.com/docs/cli/reference/permissions) gives the tokens
`Shell(...)`, `Read(...)`, `Write(...)`, `WebFetch(...)`, `Mcp(...)`. **The guess turned out to match
the published names exactly**, so the two stay as they are — now because they are cited, not because
re-guessing them would only move the guess. The community-reported `read_file` / `run_terminal_cmd`
belong to neither surface; the SDK's own lowercase union (`"read"`, `"shell"`, `"task"`, …) is a third
namespace and not the one these files write in. What is
published there is the `Task` tool, in [Subagents](https://cursor.com/docs/subagents); `subagent_type`
is not, appearing only in community bug reports. Note which word moved where: in Cursor's vocabulary
`Bash` is the name of a subagent, not of its terminal.

Cursor publishes three built-in subagents — `explore`, `bash` and `browser` — so `explore` is the only
type this tree may name, and it is the only one it does. Its ten file-writing dispatch sites carried
`generalPurpose`, which the current docs do not list; none of the three built-ins is the file-writing
migrator it stood for, so those sites now set no type at all and state what they may write, which the dispatch brief
already gave them. Naming a custom subagent instead was the alternative: Cursor loads them from
`.cursor/agents/*.md` (and, for compatibility, `.claude/agents/` and `.codex/agents/`, with `.cursor/`
winning a name clash), where frontmatter `name` is the identifier the `Task` tool hints at and
`readonly: true` withholds file edits and state-changing shell commands. That would make the read-only
rule a mechanism rather than an instruction, at the cost of an artifact to maintain across six
trees and a `.claude/agents/` directory that Cursor would also read. It stays available and unused.

`.agents` delegation is named by what the delegate does, since that tree can name no call: **a
read-only sub-agent** for collection, **a writing sub-agent** for implementation. What decides whether
one is dispatched is the same everywhere — the bounded / independent / materially helpful test of
conventions §6.1 — so the shared root states the test and leaves the call to whoever reads it. Codex's
own call is `spawn_agent` with `agent_type: explorer` or `worker`; its built-in `default` type has no
use here, because every STAR delegation is one of those two roles.

**A term appearing in the wrong tree is the actual defect.** Two real cases: 25 `.cursor` asset
templates told users "Claude Code injects it at session start" (`e149ae0`), and `.kimi-code` names
`CLAUDE.md` as the project rules document in 36 places where the others said `AGENTS.md` (`6f37f77`).

**The names a port forgets to adapt are the ones no reviewer looks at twice.** `Bash` and `Read` were
carried unchanged into `.cursor`, `.kimi-code` and `.agents` for as long as those trees existed, because
a tool name that reads like an ordinary English word does not look like Claude vocabulary — unlike
`AskUserQuestion`, which does. In `.cursor` and `.agents` that was the defect it looks like. `.agents`
also named `ask_user_question`, which is worse than an unadapted name: it is harness-shaped, lowercase and
plausible, so it reads as if someone had checked. Nobody had — Codex calls it `request_user_input`, and
that is the name the tree carried for as long as it was written for Codex. When
you port a tree, check every tool name against that harness's published tool list, not against how
familiar or how plausible the name feels. In `.agents` there is no list to check against, because no
tool name belongs there at all.

**Renaming on that suspicion, unchecked, is the same defect inverted.** `.kimi-code` had `Bash` and
`Read` because Kimi Code CLI calls them `Bash` and `Read`. v0.1.8 read them as unadapted Claude
vocabulary and renamed them to `Shell` and `ReadFile` across 30 files — names that harness has never
had — then wrote the rename into this file and into the change log as a name checked against Kimi's
own list, which is why nothing questioned it for eleven releases. The contradiction was legible from
v0.1.17 on, where `.kimi-code/hooks.example.toml` registers the commit guard against `PreToolUse`
matching `Bash`, the name every manifest beside it had stopped using; nobody read the two together.
A rename carries the same burden an inherited name does:
cite the harness's published list, and where a name is only ever a citation away, pin it. Check 23 now
holds the six trees' file reader, terminal and `subagent_type` values, so neither direction is a
matter of memory.

**A capability the harness has since gained is the same defect, aged.** A tree ported while its harness
lacked a mechanism keeps the workaround long after the mechanism arrives, and no check can see it —
the wording is self-consistent, and it is the platform that moved. `.cursor` carried the plain-text
substitute for structured questions at all 132 of `.claude`'s `AskUserQuestion` sites, and said outright
in 4 files that "Cursor has no structured question tool", which had stopped being true. When you port
a workaround, name the capability it stands in for, so the next reader knows what to re-check.

Everything else — rules, thresholds, step semantics, what each may write, rubrics — must not differ.

## `.pi` is the tree that ships its own mechanisms

Pi's built-in tools are `read`, `bash`, `edit`, `write`, `grep`, `find`, `ls` — lowercase, and that is
how this tree writes them. What matters more is what its own docs say it **intentionally does not
include**: sub-agents, plan mode, permission popups, MCP, to-dos, background bash. Three of those are
mechanisms the other five trees lean on. Rather than substitute for them, `.pi` vendors them from
**pi's own `examples/extensions`** (MIT), under `.pi/extensions/`:

| Mechanism | Other trees | `.pi` |
|---|---|---|
| Structured questions | `AskUserQuestion` / `AskQuestion` / `request_user_input` / `ask_user_question` | `star_questionnaire` — one question per call, 2–4 options with the recommendation marked. Headless it returns `UI not available`, which is a stop, not a cue to ask in plain text instead. |
| Plan approval | `EnterPlanMode` / `ExitPlanMode` / `SwitchMode` / `update_plan` | `/star-plan` exists but is the **user's** switch: the extension registers a command and a flag, no tool. So the executor's Step 3 is still the mode it imposes on itself — it says out loud that nothing is written or run until Step 4's approval, and holds itself to it. |
| Delegation | `Agent` / `Task` / `spawn_agent` / `agent` | `star_subagent`, dispatching to the roster in `.pi/agents/`: `star-collector` (read-only, §6.4), `star-implementer` (one step under a brief, §6.5), `star-auditor` (blind second read, §6.7). Its scope parameter defaults to `project` so it reaches that roster; upstream defaults to the user's own. |

**The two separators are not a slip.** `star_subagent` and `star_questionnaire` are tool names, and
every tool name in all seven trees is snake or camel — `ask_user_question`, `spawn_agent`,
`update_plan`, `AskUserQuestion` — as is every multi-word tool in pi's own examples
(`structured_output`, `reload_runtime`, `tool_search`). `star-collector`, `/star-plan` and
`star-code-architect` are things a person types or a file is named, and those are kebab throughout.
Unifying them would make one side the only exception in the repository.

Four consequences worth knowing before you edit it:

- **All of it is gated on project trust.** Untrusted, `.pi/extensions/` does not load and none of those
  tools exists. A skill that names one then falls back to what STAR does on a host without it —
  conventions §6.1's local fill, and plain text for a question. That fallback is stated once, in
  `.pi/APPEND_SYSTEM.md`, rather than in every skill that names a tool.
- **Every vendored name is prefixed, and that is not cosmetic.** pi **refuses to start** — `exit 1`,
  no session at all — when two extensions claim one tool name, flag, or command. These same examples
  are commonly installed user-level, so an unprefixed copy in the repo would brick pi for anyone who
  has them. The prefix covers the status and widget slots, session entries and the injected context
  marker too: an unprefixed marker lets a user-level copy filter out this copy's messages, silently.
  Nothing in `.pi/settings.json` can undo a collision — its `extensions` array only adds paths.
- **The involve gate is still absent.** That hook exists to answer the permission prompt before a file
  edit. The vendored confirm covers `rm -rf`, `sudo` and `chmod 777` — dangerous bash, not edits — so
  there is still nothing for it to answer. `.pi/extensions/star-hooks/` carries three scripts, not four,
  and `execs/update.sh`'s `missing_hooks()` has no Pi row.
- **Registration is code, and the scripts sit beside it.** `.pi/extensions/star-hooks/index.ts` plays the part `.claude/settings.json` plays
  elsewhere, and Pi discovers it by itself once the project is trusted. It is in `HOOK_FILES`, not
  `HOOK_CONFIGS`: it holds no project settings, so an update replaces it rather than keeping it.
  The commit guard is the one hook whose shape genuinely differs — it prints the reason on stdout and
  refuses with a non-zero exit, and the extension turns that pair into Pi's `{ block: true, reason }`.
- **Pi discovers `.agents/skills/` too**, and on a name collision keeps whichever copy it finds first.
  `.pi/APPEND_SYSTEM.md` is what corrects that — Pi's always-on channel, the same job
  `.cursor/rules/skill-roots.mdc` does for Cursor. A project running only Pi can delete `.agents/`.

Pi ships a sub-agent *example* extension (`examples/extensions/subagent/`) and a plan-mode one. Neither
is built in, and STAR does not install them; if a project adds them, the `.pi` tree still reads
correctly, because §6.1's local fill is a floor rather than a prohibition.

## `.agents` is a declared variant

`.agents` is a genuine adaptation, not a copy: its executor has 7 steps where the others have 9. Its
heading structure differs from `.claude` in 8 files — four under `star-plan-executor` (the manifest and
`agent_dispatch_spec.md`, each in both languages), four under `star-code-architect`
(`orchestration_spec.md` and `survey_spec.md`, likewise) — and those differences are not simple
omissions: it restructures. `stop_line_rules.md` was the ninth and tenth until the tree stopped naming
a harness: it was titled "what **Codex** runs", and now says "what the agent runs", which is what
`.claude` says, so those two files agree heading for heading.

It is therefore **exempt from the structural check**, and that exemption is a known hole: see below.

## Skill frontmatter does not port

`.claude/skills/*/SKILL.md` carries `argument-hint` and `allowed-tools`. **Of the other five trees only
`.qwen` carries `argument-hint`; none carries `allowed-tools`, and none should.** Each key was checked
against its harness's own surface rather than against how plausible it looks there — the discipline the
tool names get above, applied to frontmatter.

| Tree | `argument-hint` | `allowed-tools` | Where tool pre-approval actually lives |
|---|---|---|---|
| `.claude` | supported | supported | the skill, scoped to the turn that invokes it |
| `.cursor` | not a field | not a field | `.cursor/cli.json` `permissions.allow`, session-wide |
| `.kimi-code` | not a field | not a field | `~/.kimi-code/config.toml` `[[permission.rules]]`, user-level |
| `.qwen` | supported, and carried | read as `allowedTools`, deliberately not ported | `.qwen/settings.json` `permissions.allow`, project-level |
| `.agents` | authoring prose only | authoring prose only | nowhere per-skill — removed on purpose |
| `.pi` | not a skill field (it is a prompt-template one) | read, experimental, deliberately not ported | nowhere — Pi has no permission system; the vendored confirm covers three bash patterns, not edits |

**Cursor's frontmatter table is closed at five keys** — `name`, `description`, `paths`,
`disable-model-invocation`, `metadata` (plus legacy `globs`, and `user-invocable`, documented only in
the [CLI changelog](https://cursor.com/docs/cli/changelog)). Neither key appears anywhere in
[its skills reference](https://cursor.com/docs/skills). Its permission tokens are a different
vocabulary again — `Shell(...)`, `Read(...)`, `Write(...)`, `WebFetch(...)`, `Mcp(...)` in
[`permissions`](https://cursor.com/docs/cli/reference/permissions) — so even the upstream spec's
`allowed-tools: Bash(git:*)` example would name a tool Cursor does not have.

**Kimi keeps unknown keys and ignores them**, so a ported `allowed-tools:` block is inert rather than
an error — the worst failure mode, because nothing reports it. Its parser strips the frontmatter
before the body is sent (`parser.ts`), so a key the runtime does not read never reaches the model
either. Its own `arguments` field is not a hint: it declares positional substitutions for `$NAME`
placeholders in the body, is absent from the `/` menu entry (`tui/commands/skills.ts` sends `name`,
`aliases`, `description` and nothing else), and buys nothing for bodies like ours that carry no
placeholders. The prose `Invocation:` line already in the body is what actually reaches the model.

**Codex removed per-skill permissions on purpose.** Its per-skill manifest — the file carrying the
display name, the default prompt, and the `allow_implicit_invocation` flag that makes a skill
slash-only there — accepted a `permissions:`
block for about six weeks in early 2026 (`5b6911cb`) and lost it again (`0bb152b0`, `b3e069e8`); the
regression test `shell_zsh_fork_skill_scripts_ignore_declared_permissions` now asserts that declared
skill permissions "should not widen script execution beyond the turn sandbox". Both keys survive in
the shipped binary only inside the bundled skill-creator's authoring guide — one occurrence of
`argument-hint`, two of `allowed-tools`, none in a runtime path. Worse, Codex's marketplace validator
pins `allowed_properties = {"name", "description", "license", "allowed-tools", "metadata"}` and
rejects anything else with "Unexpected key(s) in SKILL.md frontmatter", so adding `argument-hint`
there would be inert at runtime *and* a validation failure on publish.

**That manifest is Codex's alone, so it is stored under `.codex/`.** The fifteen files live at
`.codex/skills/<skill>/agents/openai.yaml`, and `.agents/skills/<skill>/agents/openai.yaml` is a
relative symlink to each. The link is not optional: Codex reads a manifest only from inside the skill
directory it belongs to, and `.agents/skills` is the only project root it scans, so there is no
`.codex/skills` discovery to move them to. The checks are written around that split: check 4 reads the
fifteen from `.codex/skills/`, while checks 3 and 7 leave `agents/` out — out of the inventory
baseline, and out of the token scan, since a `default_prompt` is written in Codex's own `$star-*`
syntax on purpose.
`--tools codex` selects `.agents` and `.codex` together, and `execs/update.sh` copies what a link
points at, so an installed project gets a real file rather than a link into a directory it did not take.

**Qwen Code reads both keys, and only one of them ports.** Its skill frontmatter takes `name`,
`description`, `argument-hint`, `when_to_use`, `priority`, `paths`, `user-invocable`,
`disable-model-invocation`, `allowedTools`, `model`, `hooks` and `key`; this tree carries four of them
— `name`, `description`, `argument-hint`, `disable-model-invocation` — and stops there. `allowedTools`
(camelCase, unlike Claude's `allowed-tools`) was left out on purpose, because it means the opposite: it
is an additive, session-scoped auto-approval grant and never narrows the tools the model sees. Carrying
Claude's blocks across would have granted auto-approval where they were written to withhold capability.
Pre-approval for this tree lives in `.qwen/settings.json` `permissions.allow` instead — project-level,
shipped with the six `scan.sh` commands.

**Anything a skill needs pre-approved in the other five trees is a project- or user-level config
change, not a skill change** — and it is always broader in scope than the Claude equivalent, which
lasts one turn. Do not port a turn-scoped grant into an always-on config without saying so.

To re-check any of this without guessing: `codex debug prompt-input` renders Codex's model-visible
input as JSON, which is also how the truncation below was measured.

## The description length limit

**`SKILL.md` frontmatter descriptions are capped at 1024 characters, in all six trees.** Not a
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

**Codex truncates far harder than either number, and it is measurable.** `codex debug prompt-input`
renders the model-visible input; in it every skill — Codex's own bundled ones included — is one line
of `name: <first ~100 characters of description> (file: <path>)`, cut mid-word with no ellipsis. The
fifteen `.agents` descriptions run 504–947 characters, so **about 10% of what is written reaches the
model, and the "Use when the user invokes `star-*`, or wants …" trigger clause reaches it for none of
the fifteen.** That clause is the entire mechanism by which a description earns an unprompted
invocation, and on Codex it is dead weight. The full `SKILL.md` still loads once a skill is invoked,
so this costs discovery, not execution — but discovery is what a description is for.

**The fifteen `.agents` descriptions are now written against that window**: each opens with a
trigger-bearing clause in user language that completes inside the first ~90 characters, and the
mechanism, the routing and the guarantees follow behind it. Re-check it the way it was found —
`codex debug prompt-input` and read the `- <name>: …` lines — because **no check here can see it**.
Two rules when editing one: the window is measured from the *start* of the description, so prepending
anything pushes a trigger out of view; and a guarantee about what the skill will not do still may not
be cut to make room (see above), it moves later in the string instead. This is the one tree where
description order carries function rather than style. The Chinese twins are deliberately untouched:
`SKILL_zh.md` is not a registered manifest, Codex never loads it, so it has no truncation window to
be written against.

Condensing loses things silently, which is the real cost. Two clauses had gone missing from the
English descriptions and were restored: `star-code-release`'s "prepares a release and never publishes
one" and `star-expt-analyst`'s read-only guarantee and `watch` mode. Both fit inside the limit — those
descriptions were at 890 and 593 characters — so the loss bought nothing. Both Chinese descriptions had
kept the clauses, which is what made the English gap visible. **When you shorten a description to fit:
cut detail, never a guarantee about what the skill will not do.** Check 12 enforces the length;
nothing enforces that judgement.

## What the checks catch

`.github/scripts/check_consistency.sh`, run by `.github/workflows/consistency.yml` on push and PR:

1. The six roots carry the same set of skill directories.
2. Frontmatter `name:` matches the directory name.
3. Per-skill file inventory is identical across trees (`.agents`' `agents/` links to Codex's
   manifests aside).
4. Slash-only guards match the conventions §10 roster in both directions, in all six trees, and the roster itself lists exactly the skills that exist, with the same rows and † set in the zh edition.
5. Every `.md` has its `_zh.md` twin.
6. Every `SKILL.md` references the conventions document.
7. Invocation tokens are tree-appropriate — no prefix at all in `.agents`, `/star-*` in `.claude`,
   `.cursor`, `.pi` and `.qwen`, `/skill:star-*` in `.dsh` and `.kimi-code`.
8. Workflow docs ship as en/zh pairs.
9. `.cursor/rules/agent-instructions.mdc` matches the `AGENTS.md` body byte for byte.
10. Both session hooks — model-id provenance and project memory — exist, are executable, and are
    registered in all six harnesses' registration files.
11. **Heading structure matches across `.claude`, `.cursor`, `.kimi-code`, `.pi` and `.qwen`** — 1236
    headings per tree, compared after stripping parentheticals (both `(...)` and `（...）`) and
    inline code, so harness vocabulary inside a heading is allowed to differ. Currently exact, with
    no exception list.
12. **Every tree's `SKILL.md` descriptions stay within the 1024-character spec limit** — counted in
    characters, with the folded-block indicator excluded. See above; a harness truncating earlier than
    the spec is not checkable here.
13. **Skill helper scripts are byte-identical across the six trees, and executable.** A script names no
    harness, so it has nothing to adapt; a copy that has drifted is a bug, not a variant.
14. **`.agents` manifests carry the same `##` sections as `.claude`** — the set, not the sequence, since
    check 11 exempts `.agents` and content had already been lost through that gap.
15. **Shared scripts parse, and the strings they match byte-exactly still have a producer.** Check 13
    compares the six copies against each other, so a break introduced into all six at once — which is
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
    across languages.** Skills cite that file at sub-section granularity — §7.7 280 times, §6.3 50
    times — so inserting an item into the middle of a section repoints every citation after it. The
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
19. **The opening-load shape holds in every tree.** One `.env` lookup line per file, no `cat` of the
    whole conventions file inside a Bash block (only `.agents`' fallback sentence may, and it is marked
    "accept that the result is written out" / "接受结果被存成文件"), `SKILL_zh.md` never a runtime load, and the two passages that are
    uniform across all ninety file pairs by design — the language paragraph and the
    `SKILL_zh.md` header blockquote — still identical, so a partial re-edit shows up. The strings it
    pins are the lookup line and those two openings; rewording any of them centrally means updating
    the check in the same commit.
20. **A skill that loads only part of the conventions says so accurately, and stays under the size
    limit.** Two skills take an `awk` excerpt of the sections they act on rather than the whole file
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
    checks 1–3 compare file sets and not contents; rewording it in one tree, so the six trees disagree
    about what may be skipped; and moving it below the first `##` heading, where it stops being part of
    the load the reader is deciding about. It must also carry no bare `§n` — check 20d reads every `§n`
    in that same block as a claim about which sections the skill loads.
22. **Delegation calls stay native to each harness, and the shared root names none.** `.agents` may
    not carry a delegation tool or type key at all — `spawn_agent`, `star_subagent`, `Agent`, `Task`,
    `agent_type:`, `subagent_type:` — because a delegate there is named by what it does. In the other
    direction, `spawn_agent` and `agent_type:`, which are Codex's, appear in none of `.claude`,
    `.cursor`, `.kimi-code` or `.qwen`.
23. **Each tree names only its own harness's file reader, terminal, question tool and subagent types —
    and `.agents` names none of them.** Pi's are lowercase (`read`, `bash`) and it may name no
    `subagent_type` at all. Claude Code
    and Kimi Code publish `Read` and `Bash`; Cursor's terminal is `Shell`; Qwen Code's are the
    snake_case identifiers `read_file` and `run_shell_command`, with its display labels `ReadFile` and
    `Shell` banned there alongside Claude's names. The shared root's banned list is the union of all of
    them: every harness's file reader, terminal, question tool and plan tool, Codex's own included.
    The `subagent_type` values are pinned per tree — `Explore` /
    `general-purpose` for Claude, `explore` alone for Cursor, `explore` / `coder` for
    Kimi, `Explore` / `general-purpose` / `fork` for Qwen Code — while `.agents` may name no type key,
    which is check 22's half of the job. It exists because the inverse of an unadapted
    name shipped: `.kimi-code` was renamed off `Read` and `Bash` onto names Kimi has never had, and
    every check passed it. `.cursor`'s two began as this repository's descriptive choice and are now
    citable — Cursor's hooks and CLI-permissions pages publish `Shell` and `Read` — so all six trees
    are pinned against a vendor list rather than against a guess.

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
- **Whether a pinned tool name is still the harness's.** Check 23 pins six trees' tool vocabulary
  against a table written here, and a table is only as good as the list behind it. All six now
  trace to a vendor's published list, but what the check can prove is that a name has not drifted
  since someone last looked, never that it was right when they looked — `generalPurpose` sat in that
  tree after Cursor's built-in subagents had moved on, and a check written a day earlier would have
  pinned it there. Cursor's case cuts both ways: its identifiers went from unpublished to published
  without anything here noticing, so a re-check can also *gain* a citation, not only lose one.

## Before you commit

- Run `bash .github/scripts/check_consistency.sh`. It exits non-zero on failure and is fast.
- Editing `AGENTS.md` means editing `.cursor/rules/agent-instructions.mdc` in the same commit — check 9
  compares their bodies directly.
- Editing a numbered section of the conventions document: do not renumber. Section 7.7 alone has 305
  references across the repository. Check 17 holds the section headings and the item counts; adding an
  item to §1, §3, §4, §5, §6 or §7 fails it until every `§n.m` citation has been re-audited.
- Same for `AGENTS.md`: renumbering a section means re-auditing every `§n` citation in the skill trees
  and updating `AGENTS_SECTIONS` in the check script. Check 16 fails until both are done.
- Keep the English and Chinese workflow guides line-aligned. They currently match line for line, which
  makes cross-language diffs readable — and check 17 now fails if a pair stops matching.
