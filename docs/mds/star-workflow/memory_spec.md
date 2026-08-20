# Project Memory

**Language:** English | [简体中文](memory_spec.zh-CN.md)

Where a session records what it learned, and how that reaches the next one. The rule for *whether* to record — offer, never assume; the project's own files come first — is `AGENTS.md` §10, not repeated here. This file is the format both halves stand on: what the store holds, what one memory looks like, what the hooks parse.

## What belongs here

One exclusive test: **a fact belongs in memory only when no file in the project already owns it.** A result belongs to its run's `EXEC_LOG.md`, a research decision to its plan, a paper to `metds/refs/`, a placement rule to `metds/codearc.md`. Memory is the residue — true across runs, owned by nothing. Without that test the store becomes a second answer to what the plans already answer, and the two drift apart.

| Type | What it holds | Example |
|---|---|---|
| `env` | a fact about a machine, cluster, or toolchain, usually learned by failing | this cluster builds flash-attn only after `module load gcc/11` |
| `pref` | a standing user preference about how the work is done | commit straight to `main`; no feature branches |
| `insight` | a judgment that outlived the run that produced it | the baseline's published number does not reproduce above 0.3; do not use it as a reference point |
| `deadend` | something tried, failed, and not worth retrying, with what it cost | swapping in the other sampler changed nothing; two A100-days |

`deadend` is the type a research repository needs most and a general-purpose memory has no room for: the expensive knowledge is what *not* to run again.

## Where it lives

```text
.star/memory/
├── MEMORY.md          # the index: one line per memory
├── <slug>.md          # one memory per file
└── local/             # machine-specific memories, git-ignored
    ├── MEMORY.md
    └── <slug>.md
```

`.star/memory/` is versioned, so a memory outlives the machine that recorded it and travels with a clone. `local/` is ignored the way `.env` is: a path, module name, or driver quirk true here and false on the next machine belongs there. Where such a fact is worth carrying anyway, use a shared memory whose `scope` names the machine it holds on.

## The memory file

One fact per file, named for its slug:

```markdown
---
type: env
scope: machine:cluster-a
language: en
verified: 2026-08-03
model_id: claude-opus-5[1m]
source: wkdrs/03_pretrain_run/EXEC_LOG.md
---

flash-attn compiles on this cluster only after `module load gcc/11`.

**Why:** the default toolchain is gcc 9.4, and the build fails on a C++17 feature.
**How to apply:** put the module load in the launcher, not in the shell profile.
```

| Field | What it is |
|---|---|
| `type` | one of the four above; `env` is the only one the hooks age |
| `scope` | `global`, `machine:<name>`, `plan:<prefix>`, or `code:<path>` — where the fact is true, not where it was learned |
| `language` | the body's language (conventions §7.6, the reply-language rule); frontmatter keys stay English |
| `verified` | the date the fact was last confirmed true, from the system clock (conventions §4, real dates) |
| `model_id` | the model that wrote or last re-verified it, verbatim (conventions §8, the output table; fallbacks in `model_id_spec.md`) |
| `source` | the artifact the fact came out of, or `conversation` |
| `supersedes` | optional: the slug this memory replaces |

The body opens with one sentence stating the fact, then only what a reader needs to act on it. A memory has no `model_trail`: it records a single fact, and a re-verification rewrites `verified` and `model_id` rather than appending to a history. Conventions §8 asks for a trail where several sessions each write a different part of one artifact — not what happens to a file this small.

## The index line

`MEMORY.md` lists every memory beside it, one line each, newest first:

    - <type> · <scope> · <verified> · [<slug>](<slug>.md) — <one line>
    - env · machine:cluster-a · 2026-08-03 · [flash-attn-gcc11](flash-attn-gcc11.md) — builds only after `module load gcc/11`

The first four fields are separated by a space, a middle dot, and a space; everything after the em dash is free text, that separator included. **The session hooks split on it byte-exactly** — reword the separator and they silently stop marking anything, no error anywhere. The aging check is as literal about the type token: `env` stays English, whatever language the one-liner speaks. Only lines starting with `- ` are read, so the index file's own header is invisible to them.

That one line is what a session judges relevance on, so it says what the fact *is*, not what it is about: "builds only after `module load gcc/11`", not "notes on the flash-attn build". Keep the index under roughly 60 lines; past that, group entries under one heading per type — in this same file, never a second one: the hooks read no other file as an index, so a split-off one silently stops reaching sessions, while a heading is just another line they skip.

## Retiring a memory

Three ways out, and the first is the common one:

- **Re-verified** — the fact still holds: set `verified` to today and `model_id` to the model that checked it, and carry the new date into the index line — the stale flag reads that line, not the frontmatter.
- **Superseded** — the fact changed: write the new memory with `supersedes: <old-slug>`, then delete the old file and its index line. Git holds the history; nothing is archived inside the store — that is what keeps the index short enough to inject into every session.
- **Wrong** — delete it. A memory that was never true is not history worth keeping.

Deleting a memory is a deletion like any other: confirmed with the user at every involve level (conventions §7.7, how much the skills ask).

## How it reaches a session

| Runtime | Hook | Event | What it injects |
|---|---|---|---|
| Claude Code | `.claude/hooks/star_memory.sh` | `SessionStart` | the index, as `additionalContext` |
| Codex | `.codex/hooks/star_memory.sh` | `SessionStart` | the index, as `additionalContext` |
| Cursor | `.cursor/hooks/star_memory.sh` | `sessionStart` | the index, as `additional_context` |
| DSH | `.dsh/hooks/star_memory.sh` | `SessionStart`, through the Claude Code hook bridge | the index, as `additionalContext` |
| Kimi | `.kimi-code/hooks/star_memory.sh` | `UserPromptSubmit` | the index, once per session |
| Pi | `.pi/extensions/star-hooks/star_memory.sh` | `before_agent_start`, wired by `.pi/extensions/star-hooks/index.ts` | the index, as a hidden message before the first agent run, and again after a model change |
| Qwen Code | `.qwen/hooks/star_memory.sh` | `SessionStart` | the index, as `additionalContext` |

Each hook prints the two indexes and nothing else — the shared one, and `local/`'s where it exists. An `env` line whose `verified` is more than 180 days old is marked stale in what the session sees, because a machine changes under a fact recorded about it; the other three types are not aged: a dead end stays dead, and a flag firing on healthy entries teaches the reader to skip it. An empty store prints nothing, so a project that has recorded nothing pays nothing.

A hook that exists is not necessarily registered. Claude, Codex, Cursor and Qwen Code ship theirs registered in `.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json` and `.qwen/settings.json`; Kimi has no project-level config, so `bash .kimi-code/hooks/install.sh` registers it once per machine. DSH is the same shape: `.dsh/hooks.json` is the table, but the row pointing DSH at it belongs in the machine's `$DSH_HOME/cordis.patch.yml`, written once by `bash .dsh/hooks/install.sh` — and the bridge it loads is not a dsh dependency, so each profile needs `dsh plugin --profile <name> add @deepseek-ai/dsh-hooks-claude-code`. Pi's registration is code, not config — the extension is discovered automatically, but only in a trusted project (`/trust`, or `defaultProjectTrust`); untrusted, it loads no project extension and injects nothing. Qwen Code's registration adds one condition: a project-level hook runs only in a trusted folder, which applies only where folder trust is on (`security.folderTrust.enabled`, off by default). A project adopted before this hook existed keeps its own registration file; `execs/update.sh` never overwrites it, reports the gap instead, and the entry is added by hand.
