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
model_id: <model id, copied verbatim from what your runtime states this session — Claude Code injects it at session start; "unrecorded" only if the session names none>
model_trail:                    # append-only: one entry per write session, newest last, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: <star-…>, scope: <what this session wrote> }
---

# <Method> — <one line: what it is>

<!-- Written by /star-refs-reviewer. Every claim below comes from the paper; mark anything uncertain
     [unverified]. Sections with nothing to say collapse to one line — never pad. -->

## 1. TL;DR

<!-- 2–3 sentences: what problem, what idea, what it achieved. Enough for a reader to decide whether
     to open the paper. -->

## 2. Problem & Motivation

<!-- The task as the paper frames it, and the gap in prior work it claims to fill: what did the
     authors say was impossible, expensive, or brittle before? -->

## 3. Method

<!-- The core insight in one sentence, then the components or pipeline. Only the formulas the method depends on,
     symbols defined. Name the training data and the objective. Separate what is new here from what
     is inherited from prior work. A claim about what the method requires or cannot do — the
     kind a later paper positions itself against — names where the paper states it: a section,
     a table, or a short quote. -->

<!-- Figures, where the paper's arXiv HTML has them: up to three across the whole note, each in the
     section whose content it shows — the method figure here, a problem or setting figure in §2, a
     results figure in §4. The three lines below are one figure; repeat them where a second earns its
     place. No qualifying figure, or no arXiv HTML rendering — delete them and say which of the two
     it was, in one line. -->

![<Method> — <what this figure shows, 2–4 words>](figs/<ABBREV>_fig<N>.png)
*Figure <N>: <the caption's first sentence, verbatim>* — src: <image URL> (fetched YYYY-MM-DD)

<!-- 2–4 sentences: what the figure shows and how to read it — the parts and how they connect, the
     axes and what moves along them, what to take from it. Written from the caption in full and the
     passages citing this figure by number; anything neither states is [unverified]. Restating the
     caption is not a description, and a figure that cannot be described is not kept. -->

**What this figure shows**: <…>

## 4. Experiments & Results

<!-- Benchmarks and splits, the comparison set, headline numbers as the paper reports them
     (metric + dataset + number), and the ablation that carries the argument. Do not compare across
     incomparable settings. Write each headline number as one self-contained line, the number
     travelling with its dataset, metric, and setting, so it survives being quoted without
     this section around it — that is the form a writing repository's citation audit checks a
     manuscript sentence against, and a number stranded from its setting backs nothing.
     A results figure belongs here under §3's rule and in §3's three-line form — kept only where it
     carries what these numbers cannot. -->

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
