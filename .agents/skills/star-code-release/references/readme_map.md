# README Extraction Map

Which artifact feeds which README section, what to do when it is absent, and how the content is transcribed. The README is compiled from this map — a section with no source in the table below does not belong in the README, and a source not in the table is not read for it.

The reference shape comes from what research repositories converge on (GroundingDINO, YOLO-World, LLaVA, SAM all order it roughly this way): identity → what it is → how to install it → what you can download → how to run it → what it scored → how to cite it. STAR's addition is that every one of those sections has a file behind it.

## Section table

`M` = mandatory: the section always appears, carrying a `TODO` line when its source is absent. `O` = omit-when-empty: no source, no section — never padded.

| # | Section | Kind | Primary source | Supporting source | When the source is absent |
|---|---|---|---|---|---|
| 1 | Header — title, tagline, badges, teaser | M | `metds/overview.md` §problem + §core idea | repo directory name, `.env` `CODE_NAME`, `metds/refs/reference.bib` self-entry | Title from the repo/`CODE_NAME`; tagline `TODO` → `$star-metd-summarize overview` |
| 2 | News / Updates | O | root plan §6 milestones with dates, `wkdrs/digests/EXPT_DIGEST_*.md` | — | Omit — a news line nobody wrote is not news |
| 3 | Abstract / Introduction | M | `metds/overview.md` — problem, gap, core idea | root plan §1–§2 | `TODO` → `$star-metd-summarize overview` |
| 4 | Highlights / Contributions | O | `metds/overview.md` contributions (its falsifiable claims) | — | Omit |
| 5 | Method / Architecture | O | `metds/framework.md` — the data path, per-component detail | `metds/codearc.md` §4 plan-component map, for the code pointer per component | Omit; note it in the report as the largest missing section |
| 6 | Installation | M | `${CODE_NAME}/requirements*`, newest `wkdrs/env_*/ENV_REPORT.md` (python version, backend, install ladder, `ENV_PY`) | `.env.example` | `TODO` → `$star-env-builder` |
| 7 | Data preparation | O | `metds/dataset.md` — inventory, preprocessing, constructed data | the `datas/` layout the data-readiness leaves name in §3 | Omit |
| 8 | Model Zoo / Checkpoints | O | `metds/results.md` rows naming a weight | `inits/` for the path that exists | Omit. **Never** link a checkpoint that is neither on disk nor already published |
| 9 | Quick start / Demo | O | the entry point `codearc.md` §2 names | `execs/run.sh` | Omit when no entry point resolves |
| 10 | Training | O | `metds/training.md` — stage pipeline, hyperparameter table, reproduction commands | `execs/scpts/*.sh` | Omit |
| 11 | Evaluation | O | `metds/evaluation.md` — protocol, benchmarks, metrics, ablation design | the eval scripts under `execs/scpts/` | Omit |
| 12 | Results | O | `metds/results.md` — **the only source of a number** | — | Omit. Never reconstruct a table from `EXPT_ANALYSIS` reports or digests |
| 13 | Repository structure | O | `metds/codearc.md` §1 directory layout | — | Omit |
| 14 | TODO / Roadmap | O | root plan §6 milestones not yet `done` | — | Omit |
| 15 | Citation | M | `metds/refs/reference.bib` self-entry | root plan §1 for the title | Placeholder BibTeX with a `TODO` — never a fabricated venue, year, or author list |
| 16 | License | M | root `LICENSE` | `metds/codearc.md` §5 upstream license implications | One line naming the missing file; the checklist raises it as a blocker |
| 17 | Acknowledgement | M when `UPSTREAM.md` exists | `${CODE_NAME}/UPSTREAM.md` | `metds/refs/refs_index.md` core papers | Omit only when there is no upstream and no core-paper base |
| 18 | Footer — Built with STAR | M | — | — | Always present |

## Transcription rules

These are what separate a compiled README from a written one.

1. **A number is copied, never recomputed.** Every figure in §8 and §12 is transcribed from `metds/results.md` exactly as the ledger carries it, together with the run name the ledger cites. A number the ledger excluded (its `invalid` / `inconclusive` section) does not enter the README at all — not even with a caveat. If the ledger is absent, §12 is omitted and the report routes to `$star-expt-analyst aggregate`.
2. **A command is resolved before it is printed.** For every command: the script file exists, each config path it names exists, and the module it invokes imports under the `.env` interpreter. Resolved → print it verbatim, exactly as the script or `metds/training.md` records it. Unresolvable → drop it, or keep it under an explicit *not yet verified* line naming what is missing. A README whose install or train command fails on a fresh clone is the most common way a research repo loses its reader.
3. **A path is checked before it is linked.** Figures, weights, configs, and relative links point at files that exist. A teaser image referenced by `metds/framework.md` but absent from `docs/srcs/` means no image — not a broken `<img>`.
4. **A claim carries its evidence.** "State of the art", "outperforms", "best", "significantly" appear only where `metds/results.md` carries a verdict that says so. Comparative language against a named baseline needs that baseline's number in the same ledger table. Everything else is described, not ranked.
5. **Unverified content is marked, not hidden.** Content compiled from a leaf whose `exec_status` is not `done` — a training recipe never run end to end, an evaluation protocol never executed — keeps one italic line saying it is not yet verified, the same discipline `$star-metd-summarize` uses. A README that silently presents intent as fact is the failure this rule exists to prevent.
6. **Merge along the reader's axis.** One method document may feed three sections; one section may merge four. Rewrite into one voice — a section that reads as pasted excerpts, or that repeats what the section above already said, has failed. Where two sources disagree, the newer `generated:` wins and the report names the conflict.
7. **Length is a feature.** The header through §4 is what most readers read. Keep §1–§4 under about 400 words total; push detail down into the sections that exist to hold it, and link out to `metds/` for the rest.

## The provenance marker

The first line of the compiled README, before the title:

```html
<!-- Compiled by $star-code-release on <YYYY-MM-DD> · model_id: <id or unrecorded> · sources: metds/overview.md@<generated>, metds/framework.md@<generated>, metds/results.md@<generated>, metds/codearc.md@<updated>, … · report: wkdrs/release/RELEASE_<date>.md · Regenerate with $star-code-release readme; hand edits to a section are detected and kept. -->
```

It is an HTML comment, not YAML frontmatter: GitHub renders frontmatter in a README as a table at the top of the page. This marker is the artifact's header line for conventions §8 — it carries `model_id`, and each source with the date that source carried when it was read, which is what makes a stale README detectable by comparison rather than by file mtime.

On a re-run, the marker's `sources:` dates identify what moved, and a section whose text differs from what the recorded sources would produce is treated as hand-edited and defaults to being kept.
