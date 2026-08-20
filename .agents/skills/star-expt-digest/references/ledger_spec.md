# Step 8: Ledger (ledger mode only)

Read where the invocation carried `ledger`. Every digest run — a period, a plan, `all` — never reads this file.

Roll every artifact's `model_trail` into one table — the cross-artifact view of **who wrote what**, which no single artifact can show. Mechanical, not interpretive: read, group, count, write.

1. Walk the conventions §8 artifacts that exist on disk, as the `--trails` scan lists them. Use **frontmatter only** — `model_id`, `model_trail`, and the file's own date field — plus the header-line `model_id` the scan prints for artifacts carrying no frontmatter. Never read a body to infer authorship.
2. Every row is copied from a trail entry. An artifact with no `model_trail` is a **gap**, listed in §5 with why it has none (written before the field existed, or a skill that skipped it) — never assumed single-model, and never back-filled by guessing.
3. Where an artifact carries finer per-event attribution than its trail — a plan's `## Revision History`, an `EXEC_LOG` step table's `model` column, `refs_index`'s `Model` column — prefer it: it says which *step* or *entry* a model wrote, not just which session.
4. Fill `assets/model_ledger_template.md` (Chinese: `assets/model_ledger_template_zh.md`) into `wkdrs/digests/MODEL_LEDGER.md`. Same date rule as the digest: same day overwrites, a later day writes its own.

**Counts are not a verdict.** Report write events per model and stop there. A model with more events did more writes, not "did better" — the model record file carries no quality signal, and saying otherwise from these numbers is the same error as attributing a metric delta to a cause. Trails are self-reported (conventions §8), so the model record file inherits that limit and says so on its face.
