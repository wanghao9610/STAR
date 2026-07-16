# Repo Search & Scoring Rubric

How Branch A turns a research plan into a shortlist of reference implementations and a defensible pick.

## 1. Build the search profile

Pull from the plan (do not invent):

- **Task domain** — from §1 (e.g. open-vocabulary detection, time-series forecasting).
- **Method keywords** — from §3 (architecture family, key techniques, loss/matching names).
- **Named baselines** — from §2/§4. These are gold: their official repos are usually the best starting candidates.
- **Framework & versions** — from §3/§4 (PyTorch/JAX, CUDA needs) and anything `.env` implies about the machine.
- **Scale constraints** — single-GPU vs multi-node, dataset size the plan targets.

Show the profile to the user as a short block before searching.

## 2. Search

Prefer structured search, fall back gracefully:

1. `gh search repos "<keywords>" --language=python --sort=stars --json fullName,stargazersCount,license,updatedAt,description` (and `gh api search/repositories` for finer queries). Requires an authenticated `gh`.
2. Web search: `"<baseline name>" official implementation github`, `"<paper title>" code`, `<task> <framework> training github`.
3. If neither works, ask the user for a URL — do not guess repo names from memory.

Shortlist 5–10. Drop immediately: archived repos, inference-/demo-only repos, awesome-lists, tutorials, and forks when the origin is available. Shallow-read each survivor's README (`gh api repos/<owner>/<repo>/readme` or web) plus `setup.py`/`pyproject.toml`/`requirements*` when close to a decision. **Never clone to evaluate.**

## 3. Score

| Dimension | Weight | High score looks like | Low score looks like |
|---|---|---|---|
| Plan fit | 30 | Implements a named baseline or the plan's method family; task matches §1 | Same field, different task; would need re-architecting |
| Completeness | 20 | Training + evaluation + configs + data pipeline all present | Inference demo only; "training code coming soon" |
| License | 15 | MIT / Apache-2.0 / BSD | Copyleft, non-commercial, research-only, or **no license** |
| Activity & maturity | 15 | Recent commits, responsive issues, releases/tags | Last commit years ago; issue tracker full of unanswered "training fails" |
| Code quality | 10 | Clear layout, tests, docs, pinned deps | God-files, no tests, vendored chaos |
| Environment match | 10 | Runs on the plan's compute and the machine's CUDA/Python | Requires hardware or toolchain the user lacks |

## 4. License guidance

Surface this at Gate 1 — the user decides with eyes open:

| License | Verdict |
|---|---|
| MIT / Apache-2.0 / BSD | Fine. Keep the LICENSE file and attribution. |
| GPL / AGPL | Usable for research; flag that derived code released later must stay under the same license. |
| CC-NC, "research only", custom (e.g. some corporate research licenses) | Strong flag: check the intended release path before choosing. |
| No license file | All rights reserved by default. Do not pick without the user's explicit acceptance. |

## 5. Present the shortlist (Gate 1)

One option per candidate, top 3–5, each carrying: one-line why-it-fits, license, stars, last update, main risk (one phrase). Recommend the highest-scoring candidate first. Always include the escape option: "none of these — refine the search / start from scratch". Record the final scores; the chosen repo's row goes into `codearc.md` §5.
