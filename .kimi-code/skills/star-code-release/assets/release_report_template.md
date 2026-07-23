# Release Preparation — <project> (<YYYY-MM-DD>)

<!-- Written by /skill:star-code-release (model_id: <model id, copied verbatim from what your runtime states this session — your Kimi session reports it where available; "unrecorded" only if the session names none>).
     Phases run: gather | polish | readme | check (or "full pass"). Sections with nothing to say
     collapse to one line — never pad. -->

## 1. Verdict

<!-- One line first: "release-ready" only when no blocker is open, else "blocked (<n>)" with the
     blockers named. Then 2–3 lines: what this run changed, and what the user must decide next.
     No grade inflation — an open blocker is not a caveat. -->

## 2. Source Readiness

<!-- The table printed at Step 0, with what each row meant for the compile. -->

| Source | State | Producer | Effect on this run |
|---|---|---|---|
| `metds/overview.md` | present / absent / stale | `/skill:star-metd-summarize overview` | <which README section it fed, or which TODO it left> |
| `metds/results.md` | | `/skill:star-expt-analyst aggregate` | |
| `metds/codearc.md` | | `/skill:star-code-architect` | |
| `${CODE_NAME}/requirements*` | | `/skill:star-env-builder` | |

## 3. Promotion Record

<!-- One row per candidate the sweep found, in sweep order — including the ones left in place,
     which is the majority and is the expected outcome. -->

| # | Candidate | Passes | Evidence | Destination | Action | Outcome |
|---|---|---|---|---|---|---|
| 1 | `<path>` | A / B / C / none | <README section, plan file:line, or ledger row> | `<path>` | move / merge / keep in place / route | done / blocked / not approved |

**Verified by:** <the compileall and stale-reference greps that were re-run per row>

**Plan text made stale:** <plan file:line pairs whose paths moved — routed to `/skill:star-plan-reviser`, or "none">

## 4. Polish Record

<!-- Release surface only: file count, then one line per finding — applied / skipped / reverted.
     Findings outside the surface are listed separately for routing, never fixed here. -->

| # | File:line | Finding | Outcome |
|---|---|---|---|
| P1 | `<file>:<line>` | <one line> | applied / skipped / reverted (<reason>) |

**Out of surface, routed to `/skill:star-code-reviewer`:** <count and one-line summary, or "none">

## 5. README Section Map

<!-- What was written, and what it came from. A TODO row names the producer skill that fills it. -->

| Section | Source | State |
|---|---|---|
| Abstract | `metds/overview.md`@<date> | written / TODO (`/skill:star-metd-summarize overview`) / omitted (no source) |
| Installation | `requirements.txt`, `ENV_REPORT.md`@<date> | |
| Results | `metds/results.md`@<date> | |

**Unverified content marked:** <sections carrying a "not yet verified" line, with the leaf behind each, or "none">

**Hand-edited sections kept:** <sections whose text differed from the last generation, or "none — first generation">

## 6. Checklist Results

<!-- From references/release_checklist.md, blockers first, each with file:line and the fix.
     A family with nothing to report gets one line: "no findings". -->

### Secrets & machine-local paths

- **BLOCKER** `<file>:<line>` — <what> · fix: <how>

### License & attribution

### Runnable commands

### Assets & links

## 7. Awaiting User

<!-- The publishing commands, prepared and never run (SKILL.md Core Principle 6). For each: the
     exact command, what it produces, and what it makes irreversible. Plus any blocker whose fix
     is the user's decision — a license choice, a history rewrite after a committed secret. -->

| What | Command | Irreversible? |
|---|---|---|
| <add the remote> | `git remote add origin <URL>` | no |
| <publish> | `git push -u origin <branch>` | yes — public from this point |

## 8. Next Actions

<!-- Routing, worst first: which producer fills each README TODO, where the out-of-surface code
     findings go, which plans need `/skill:star-plan-reviser` after a promotion, and what the user must
     decide before publishing. -->
