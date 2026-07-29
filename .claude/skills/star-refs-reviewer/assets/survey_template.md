---
type: survey
topic: <the topic as surveyed, in plain words>
language: <en | zh — Step 0.4's rule>
generated: <YYYY-MM-DD, from the system clock>
sources:
  - <the method source read, with its `updated:` as it was — omit the key entirely for a free topic>
papers:
  deep: <count>
  abstract: <count>
  record: <count>
model_id: <model id, copied verbatim from what your runtime states this session — "unrecorded" only if the session names none>
model_trail:                    # append-only: one entry per write session, never rewritten
  - { date: <YYYY-MM-DD>, model: <model id or "unrecorded">, skill: star-refs-reviewer, scope: <what this session wrote> }
---

# <Topic> — a field survey

<!-- Written by /star-refs-reviewer survey. Every claim below traces to a source fetched during the
     run and listed in §12; mark anything else as this survey's own inference. Sections with nothing
     to say collapse to one line — never pad. -->

## 1. TL;DR

<!-- 5–8 bullets: the takeaways a reader needs before deciding whether to read the map. -->

## 2. Scope & Method

<!-- The search profile and its source. Every query as run, with its date. The count ledger:
     found → deduplicated → screened → tiered. What was excluded, and why. -->

## 3. Problem & Background

<!-- The task as the field frames it, the terms the rest of the file uses, defined once. -->

## 4. Taxonomy

<!-- The division axis in one sentence, and the axis rejected, beside it. Then the 3–8 branches,
     one line each. Two levels at most; every paper on exactly one branch. -->

## 5. Branches

<!-- One subsection per branch: what these works share, where they diverge, representative papers
     cited inline [@key]. Synthesis, never a paper-by-paper sequence. -->

### 5.x <Branch name>

## 6. Comparison

<!-- Deep-tier papers only, as rows. Columns that discriminate and are fillable for every row —
     typically: core mechanism, supervision / data requirement, benchmark with the headline number
     (dataset + metric named together), code availability, year. `—` where no fetched source fills a cell. -->

## 7. Evolution & Trends

<!-- 2–3 paragraphs on how the field moved, with years. Record-tier papers may be named here. -->

## 8. Benchmarks & Evaluation Practice

<!-- The datasets, splits, and metrics the field actually reports on, and where comparability breaks. -->

## 9. Open Problems & Gaps

<!-- What the surveyed work cannot yet do, stated critically — from the sources, not from hope. -->

## 10. Relation to This Project

<!-- Only when the source is a plan or method note; a free topic collapses this to one line.
     Where the project sits on the taxonomy, which branches compete with it, what none of them do. -->

## 11. Read Next

<!-- Papers that deserve a full analysis note, each with one clause of why and its command:
     `/star-refs-reviewer <arxiv-id>`. -->

## 12. Annotated References

<!-- Every paper the survey names. One row each:
     [@key] | title | venue | year | tier (deep / abstract / record) | record URL | fetched <YYYY-MM-DD> -->
