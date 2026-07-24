<!-- Compiled by /skill:star-code-release on <YYYY-MM-DD> · model_id: <model id, copied verbatim from what your runtime states this session — your Kimi session reports it where available; "unrecorded" only if the session names none> · sources: <artifact>@<date>, … · report: wkdrs/release/RELEASE_<date>.md · Regenerate with /skill:star-code-release readme; hand edits to a section are detected and kept. -->

<!-- Section kinds from references/readme_map.md: (M) always present, carrying a TODO when its
     source is absent; (O) dropped entirely when its source is absent — never padded.
     Delete every guidance comment from the compiled file; keep only the provenance line above. -->

<div align="center">

<!-- (M §1) Logo only if an image file actually exists. Title = the project name, not CODE_NAME
     when the two differ. Tagline = one line from metds/overview.md's core idea: what this does
     and for whom, not a restatement of the title. -->

<h1><PROJECT NAME></h1>
<p><strong><one-line tagline — the claim, in a reader's words></strong></p>

<!-- Authors and affiliations only when the plan or the bib self-entry names them. Never invent
     an author list, and never guess an affiliation. -->

<p><a href="<arXiv/paper URL>">Paper</a> ·
   <a href="<project page>">Project Page</a> ·
   <a href="<weights URL>">Weights</a> ·
   <a href="#citation">Citation</a></p>

<!-- Badge row: only badges whose target exists — license (from the root LICENSE), arXiv (from the
     bib self-entry), stars. A badge pointing at a 404 is worse than no badge. -->

</div>

<!-- The Language line appears only when both READMEs exist. -->
**Language:** English | [简体中文](README.zh-CN.md)

<!-- (M §1) Teaser image — only when the file exists under docs/srcs/. Alt text says what the
     figure shows, for a reader whose images do not load. -->

<p align="center"><img src="docs/srcs/<teaser>.png" alt="<what the figure shows>" width="90%"></p>

## 📰 News

<!-- (O §2) Reverse chronological, real dates only, one line each, from the root plan's §6
     milestones and the digest series. Omit the whole section rather than invent a first entry. -->

- **<YYYY-MM-DD>** — <what happened>

## Abstract

<!-- (M §3) From metds/overview.md: the problem, the gap, the core idea, in that order. Three to
     six sentences. This and the section below are what most readers actually read — everything
     after them is for the reader who has already decided to try it. -->

<TODO: compile from metds/overview.md — run /skill:star-metd-summarize overview>

## ✨ Highlights

<!-- (O §4) From metds/overview.md's contributions, which are written as falsifiable claims. Three
     to five bullets, each one thing the project does that its baselines do not. A number here is
     copied from wkdrs/results/results.md with the run behind it, or it is not a number here. -->

- **<claim>** — <one line of substance, not adjectives>

## 🏗️ Method

<!-- (O §5) From metds/framework.md: the architecture as one data path a reader can follow, then
     each component with its code location from metds/codearc.md §4. An architecture figure only
     when the file exists. Content from an unexecuted leaf keeps its *not yet verified* line. -->

<p align="center"><img src="docs/srcs/<architecture>.png" alt="<what the figure shows>" width="90%"></p>

| Component | What it does | Code |
|---|---|---|
| <component> | <one line> | [`<path>`](<path>) |

## 🛠️ Installation

<!-- (M §6) From ${CODE_NAME}/requirements* and the newest wkdrs/env_*/ENV_REPORT.md: the python
     version, the backend, and the install ladder that was actually used. Every command here is
     resolved before it is printed (readme_map.md rule 2) — this is the first command a stranger
     runs, and the one they judge the repository by. -->

```bash
git clone <repo URL>
cd <repo>

conda create -n <env> python=<version> -y
conda activate <env>

pip install -r <CODE_NAME>/requirements.txt
```

<!-- Anything the environment report flagged as needing the user's own step — a CUDA-compiled
     extension, a source build — is stated here as its own step with the reason. -->

## 📦 Model Zoo

<!-- (O §8) One row per released checkpoint, from wkdrs/results/results.md, linked only when the file is
     on disk under inits/ or already published. Columns follow what the ledger actually carries;
     the shape below is the community default. -->

| Model | Backbone | Data | <metric> | Weights |
|---|---|---|---|---|
| <name> | <backbone> | <training data> | <number, from the ledger> | [download](<URL>) |

## 📂 Data preparation

<!-- (O §7) From metds/dataset.md plus the datas/ layout the data-readiness leaves name: which
     datasets, where to get them, and the tree the code expects. Print the expected tree — it is
     what makes a data section usable rather than descriptive. -->

```text
datas/
└── <dataset>/
    ├── <split>/
    └── <annotations>
```

## 🚀 Quick start

<!-- (O §9) The shortest path from a fresh install to one working output: an inference call, a
     demo script, a few lines of Python. Resolved before printed. -->

```bash
<command>
```

## 🔥 Training

<!-- (O §10) From metds/training.md and execs/scpts/: the stage pipeline, then the command per
     stage, then the hyperparameter table. Say the hardware the run actually used — a command
     without its GPU count and memory is not reproducible. -->

```bash
bash execs/scpts/<run>.sh
```

| Stage | Data | Epochs | LR | Batch | Hardware |
|---|---|---|---|---|---|
| <stage> | <data> | <n> | <lr> | <bs> | <n×GPU> |

## 📊 Evaluation

<!-- (O §11) From metds/evaluation.md: the protocol, the benchmarks, the metrics, then the
     command that reproduces each reported number. -->

```bash
bash execs/scpts/<eval>.sh
```

## 📈 Results

<!-- (O §12) From wkdrs/results/results.md and nowhere else. Reproduce its tables with the run behind each
     number. Numbers the ledger excluded as invalid or inconclusive do not appear here at all.
     A comparison against a baseline needs that baseline's number in the same table. -->

| Method | <benchmark> | <metric> | Run |
|---|---|---|---|
| <baseline> | <benchmark> | <number> | <source> |
| **<ours>** | <benchmark> | **<number>** | `<run>` |

## 🗂️ Repository structure

<!-- (O §13) From metds/codearc.md §1, trimmed to what a reader needs to navigate — not the full
     annotated tree the spec carries. -->

```text
<code_name>/
├── <dir>/        # <responsibility>
└── <dir>/        # <responsibility>
```

## ✅ TODO

<!-- (O §14) Root plan §6 milestones not yet done, as an honest roadmap. Omit rather than promise. -->

- [ ] <milestone>

## 📝 Citation

<!-- (M §15) From metds/refs/reference.bib's self-entry. When there is none, a placeholder with a
     TODO — never a fabricated venue, year, or author list. -->

```bibtex
@article{<key>,
  title   = {<title>},
  author  = {<authors>},
  journal = {<venue>},
  year    = {<year>}
}
```

## 📄 License

<!-- (M §16) The root LICENSE, plus any constraint the upstream license imposes (codearc.md §5).
     State the upstream constraint explicitly when there is one — a reader needs it before they
     build on this. -->

This project is released under the <LICENSE> license. <Upstream constraint, when one applies.>

## 🙏 Acknowledgement

<!-- (M when UPSTREAM.md exists, §17) The upstream codebase with its link and license, then the
     core works from metds/refs/refs_index.md this project builds on. Specific, not a list of
     everything ever read. -->

This project builds on [<upstream>](<URL>) (<license>). We also thank the authors of <core works>.

---

<sub>Built with [STAR](https://github.com/wanghao9610/STAR).</sub>
