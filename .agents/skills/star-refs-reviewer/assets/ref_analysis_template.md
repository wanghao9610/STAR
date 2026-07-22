---
citekey: <Year_Method_FirstAuthor — must match the entry in reference.bib>
title: <exact title from the fetched record>
venue: <venue + year, or "arXiv preprint">
year: <year>
category: <the reference.bib category this entry belongs to>
depth: full | method-and-results | abstract-and-intro
links:
  paper: <URL>
  code: <URL, or "none found">
  project: <URL, or "none found">
read_on: <YYYY-MM-DD>
model_id: <model id, self-reported at write time; "unrecorded" if the runtime states none>
---

# <Method> — <one line: what it is>

<!-- Written by $star-refs-reviewer. Every claim below comes from the paper; mark anything uncertain
     [unverified]. Sections with nothing to say collapse to one line — never pad. -->

## 1. TL;DR

<!-- 2–3 sentences: what problem, what idea, what it achieved. Enough for a reader to decide whether
     to open the paper. -->

## 2. Problem & Motivation

<!-- The task as the paper frames it, and the gap in prior work it claims to fill: what did the
     authors say was impossible, expensive, or brittle before? -->

## 3. Method

<!-- The core insight in one sentence, then the components or pipeline. Load-bearing formulas only,
     symbols defined. Name the training data and the objective. Separate what is new here from what
     is inherited from prior work. -->

## 4. Experiments & Results

<!-- Benchmarks and splits, the comparison set, headline numbers as the paper reports them
     (metric + dataset + number), and the ablation that carries the argument. Do not compare across
     incomparable settings. -->

## 5. Relation to This Project ★

<!-- The reason this note exists. Concrete, specific to our method — not reusable boilerplate. -->

- **Shared ground**: <what our method and this one agree on, reuse, or assume alike>
- **Where it differs**: <the mechanism, setting, or assumption that separates us>
- **Borrowable**: <a component, trick, dataset, metric, or baseline protocol we could take — and what it costs>
- **Our differentiator**: <the "they cannot do X, we can" sentence this paper enables — or "none yet", honestly>

## 6. Limitations & Openings

<!-- What the paper admits, plus what its results imply but do not address. List an opening only if
     our method could plausibly enter it. -->

## 7. Follow-ups Worth Reading

<!-- 2–3 citekeys already in reference.bib, each with one clause on why. -->

- `<citekey>` — <why>
