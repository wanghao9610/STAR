# Sub-plan Naming Convention

Every plan file is named `<prefix>_<slug>_plan.md`. The **prefix** is a string of decimal digits that encodes the plan's position in the decomposition tree.

## The rule

- **Depth = prefix length.** A root plan (from `star-plan-coach`) has a 1-digit prefix — the smallest digit no existing root already uses (`0_` in a fresh project, `1_` for a second root, …). Its children have 2-digit prefixes, grandchildren 3-digit, and so on.
- **To decompose a plan with prefix `P`**, each sub-plan gets prefix `P` **with one more digit appended**, and that digit is the sub-plan's 0-based index among its siblings.
  - `0_` → `00_`, `01_`, `02_`, …
  - `00_` → `000_`, `001_`, …
  - `3_` → `30_`, `31_`, …
  - `01_` → `010_`, `011_`, …
- **Parent of any sub-plan** = drop the last digit of its prefix (`011` → parent `01` → parent `0`).

## Worked tree

```
metds/plans/
  0_open-vocab-det-seg_plan.md        root            prefix "0"    level 1
   ├ 00_mvp-3way-ablation_plan.md     child 0 of "0"  prefix "00"   level 2
   ├ 01_core-method-pipeline_plan.md  child 1 of "0"  prefix "01"   level 2
   │  ├ 010_desc-generation_plan.md   child 0 of "01" prefix "010"  level 3
   │  ├ 011_set-matching_plan.md      child 1 of "01" prefix "011"  level 3
   │  └ 012_det-seg-heads_plan.md     child 2 of "01" prefix "012"  level 3
   ├ 02_full-experiments_plan.md      child 2 of "0"  prefix "02"   level 2
   └ 03_writing-submission_plan.md    child 3 of "0"  prefix "03"   level 2
```

Files sort naturally in a directory listing (`0`, `00`, `01`, `010`, `011`, `012`, `02`, `03`), so lexical order already reflects the tree.

## Constraints and edge cases

1. **Max 10 siblings per node.** One digit per level means indices only run 0–9. If a node seems to need more than 10 children, do **not** append a second digit (`10_` is ambiguous — see below). Instead: group units, or split in two levels (decompose into ≤10 coarse units now, then recurse into the heavy ones). This cap is a re-scoping signal, not a bug to engineer around.

2. **Why not two digits per level.** Prefix `10_` could mean "child 0 of plan 1" or "top-level plan 10". With a fixed one-digit-per-level scheme and ≤10 nodes at every level, prefixes stay unambiguous and the parent is always recoverable by dropping one digit. Keep the invariant.

3. **The prefix is a hint; `parent:` is authoritative.** `star-plan-coach` gives each new root the smallest free digit, but projects created before that rule may hold two unrelated roots both numbered `0_` (distinguished only by slug), whose children then both start `00_`, etc. The numeric prefix therefore orders and hints the tree for humans, but the **frontmatter `parent:` field on each sub-plan is the real link**. Always set `parent:` to the exact parent filename, and rely on it (not the prefix) when reconstructing which sub-plan belongs to which parent.

4. **Slugs are independent of the tree.** The `<slug>` is a short, human-readable English name for the unit's content and has nothing to do with the parent's slug. `0_open-vocab-det-seg` can have child `00_mvp-3way-ablation`.

5. **Filling gaps / re-indexing.** Assign indices densely from 0 in the confirmed order. If the user later deletes a middle sub-plan, leave the hole rather than renumbering (renumbering would break every deeper prefix and every `parent:`/`traces_to` reference). If they insert one, give it the next free index even if that puts it out of numeric order; ordering intent lives in the parent's `## Sub-plans` index, not the digits.
