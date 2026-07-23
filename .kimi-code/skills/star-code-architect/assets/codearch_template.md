---
code_name: <CODE_NAME>
upstream: <repo URL, or none (in-house)>
upstream_commit: <sha, or —>
language: en
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
model_id: <model id, copied verbatim from what your runtime states this session — your Kimi session reports it where available; "unrecorded" only if the session names none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
---

# Code Architecture — <CODE_NAME>

> Authoritative spec for how code is organized in this project. Agents and humans read this **before writing code**. Summaries elsewhere (AGENTS.md, editor rules) point here; this file wins on conflict.

## 1. Directory layout

<!-- Annotated tree of ${CODE_NAME}/ — one line of responsibility per directory. Current layout is the baseline; mark planned dirs (planned). -->

```text
<code_name>/
├── <dir>/        # <responsibility>
└── <dir>/        # <responsibility>
```

## 2. Placement rules

<!-- Where each kind of new code goes. Cover at least: model components, dataset/data pipeline code, configs, training/eval logic, shared utilities, scripts, tests. One rule per line: "A new <thing> goes in <path>, registered via <mechanism>." -->

- A new model component goes in `<path>` …
- A new dataset goes in `<path>` …
- A new config goes in `<path>` …
- Experiment outputs never live here — they go to `wkdrs/<run>/`; data to `datas/`; weights to `inits/`.

## 3. Naming & style conventions

<!-- Module/file naming, config naming, class-prefix conventions, and the style baseline (usually: match upstream style). Include style notes surfaced by the survey that did NOT become migrations. -->

## 4. Plan component map

<!-- Each method component from the research plan (§3) → where it lives or will live. -->

| Plan component | Target path | Status |
|---|---|---|
| <component> | `<path>` | exists / planned |

## 5. Upstream & provenance

<!-- One-paragraph summary: chosen repo, why (scoring one-liner), license and its implications. Full metadata lives in ${CODE_NAME}/UPSTREAM.md. -->

## 6. Migration record

<!-- Append-only log of structural migrations executed (or blocked) by star-code-architect. -->

| Date | Item | From → To | Status | Verified by |
|---|---|---|---|---|
| <YYYY-MM-DD> | M1 | `<old>` → `<new>` | done / blocked | <check> |

## 7. Rename residuals

<!-- Upstream names intentionally left in place (registry strings, config type keys, checkpoint-coupled names, service names). Each row: where, what kind, risk if renamed, suggested later action. -->

| Location pattern | Category | Risk | Later action |
|---|---|---|---|
| `<pattern>` | <registry string / config key / checkpoint / service name> | <one line> | <keep / rename via executor step> |
