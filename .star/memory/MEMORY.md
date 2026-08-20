# Project Memory — index

What earlier sessions in this repository learned, one line per memory, newest
first. The session hooks under `.claude/hooks/`, `.codex/hooks/`, `.cursor/hooks/`,
`.kimi-code/hooks/` and `.qwen/hooks/` parse these lines byte-exactly, so the
shape is fixed:

    - <type> · <scope> · <verified> · [<slug>](<slug>.md) — <one line>
    - env · machine:cluster-a · 2026-08-03 · [flash-attn-gcc11](flash-attn-gcc11.md) — builds only after `module load gcc/11`

`<type>` is `env`, `pref`, `insight`, or `deadend`. `<scope>` is `global`,
`machine:<name>`, `plan:<prefix>`, or `code:<path>`. `<verified>` is the date the
fact was last confirmed true, as `YYYY-MM-DD`. The separator between the first
four fields is a space, a middle dot, and a space; everything after the em dash
is free text. Only lines starting with `- ` are read.

Machine-specific memories live in `local/`, which git ignores. Full rules —
what belongs here, the file format, how a memory is retired:
`docs/mds/star-workflow/memory_spec.md`.

<!-- entries below -->
