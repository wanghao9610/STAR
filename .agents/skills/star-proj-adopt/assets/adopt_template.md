---
code_name: <CODE_NAME>
language: en
adopted: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
backfilled: <YYYY-MM-DD, or — >
---

# Project Adoption Record

> What this repository looked like when STAR was added to it, and what was wired up. This file is
> descriptive: it records what exists, not what it is for. Research strategy lives in
> `metds/plans/`, code architecture in `metds/codearc.md`, and result judgments in the analyses
> under `wkdrs/`.

## 1. Repository at adoption

<!-- First commit date, commit count, primary language and framework, and one honest paragraph on
     what the project was already doing. Quote the README where it says so rather than paraphrasing. -->

## 2. Mapping

<!-- The confirmed probe result, one row per lane. `confidence` is what it was at Gate 1, kept so a
     later reader knows which lines were guessed at and confirmed rather than detected. -->

| Lane | Mapped to | Target | Confidence | Note |
|---|---|---|---|---|
| Source | `CODE_NAME=<dir>` | — | | |
| Runtime | `PYTHON_HOME=<path>` | — | | |
| Data | `datas/` | `<abs path>` | | link / already in place |
| Weights | `inits/` | `<abs path>` | | |
| Outputs | `wkdrs/` | `<abs path>` | | |

## 3. What was wired

<!-- Every write this skill made, and every one it skipped because the path already existed. The
     skipped lines matter as much as the made ones: they are the record of what was left alone. -->

| Action | Path | Result |
|---|---|---|
| | | created / already existed, left alone / conflict, asked |

## 4. Work inventory

<!-- One row per identifiable unit of finished or in-flight work, per references/adopt_spec.md §5.
     Descriptive only. `state`: built / run / concluded / abandoned. Every row carries evidence. -->

| id | what | state | evidence | run_dir | metric (verbatim) |
|---|---|---|---|---|---|
| W1 | | | | | |

## 5. Ledgered runs

<!-- The prior runs the user chose to bring into wkdrs/, and how many were left as evidence only.
     Each ledgered run has a reconstructed EXEC_LOG.md marked as such. -->

| Run | Linked from | Date | Reconstructed log | Note |
|---|---|---|---|---|

Left as evidence only: <N> prior run(s) — see §4.

## 6. Open questions

<!-- What the probe could not settle and the user could not answer yet. Each with who or what would
     settle it. An empty section is a fine outcome; a padded one is not. -->

## 7. Backfill record

<!-- Appended by `$star-proj-adopt backfill`, one dated block per run. Each line: leaf, the field
     written, the value, and the inventory id that justified it. Leaves the user declined are
     recorded as declined — that is a decision worth keeping, not an absence. -->

### <YYYY-MM-DD>

| Leaf | Field | Value | From | Note |
|---|---|---|---|---|
