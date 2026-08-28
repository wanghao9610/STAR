# Drive the workflow toward a goal

The user has typed `star-auto` — this file is what that invocation runs. Typing it is the auto grant of conventions §10.7: while this run pursues its goal, the skill each next action names may be started without further naming, the seven explicit-only ones included, and a prepared STOP-line command may be launched instead of handed back. The grant covers starting skills and launching prepared commands, nothing else; a started run behaves exactly as if the user had typed its name.

Invocation shape: `star-auto <GOAL> [stop=<STOP-LINE>] [involve=<level>]`.

## Parse the invocation

- Strip `involve=<level>` first, taken from outside the stop text — before `stop=`, or as the invocation's final token; the same words inside the stop line are stop-line text, not the token (conventions §7.7). When nothing sets a level — no token, no `INVOLVE` in `.env` — this run resolves to `low`, not `medium`: an autonomous run takes the marked recommendation on its own judgment calls and logs each (§7.8). Mandatory confirmation points are untouched — they ask at every level, here as everywhere.
- Then strip `stop=`: everything from that token to the end of what remains is the stop line, natural language in the user's own words — `stop=any single training over 4 hours, or any paid API call`, `stop=用卡超过 2 张就停` (either language, or both at once). **Given**, it is the line this run must not cross: before launching a prepared command, state its expected cost and judge it against each condition — a command that crosses the line, or that cannot be judged against it, is printed and handed back exactly as §2 says. **Absent**, the run is uncapped: prepared STOP-line commands launch autonomously, the goal owning the run (§2's one exception). Either way every launch is logged in the decisions record with its stated cost, and neither the grant nor any stop line ever covers a deletion, an overwrite, `sudo` or a system or driver install, or anything else irreversible — those ask, at every level (§7.7).
- What remains is the goal. No goal — ask for one; never infer a goal from the repository.

## Before the loop

Read `STAR_LANG` and `INVOLVE` from `.env` in one grep (§7.6, §7.7). Turn the goal into a check the run can verify — the `exec_status` a leaf must reach, the file that must exist, the metric a report must show — and open with one line stating that check, the stop line (or that none was set), and the resolved involve level. A goal that cannot be turned into a check is asked about, not pursued.

## The loop

1. Run `star-flow-status` through the harness's native skill mechanism and take its single next action. An action that does not advance the goal's check is not taken: say so in one line, leave it for a later invocation, and take the next action that does.
2. Start what it names:
   - One of the eight the agent may pick up — the harness's native mechanism, exactly as §10.2–10.6 say, with this run's resolved level appended as an `involve=` token: each started run resolves its own level (§7.7), so a start that carries no token would fall back to `.env`, not to this run's default.
   - One of the seven explicit-only — the grant covers it: announce one line first (what matched, which target), then dispatch one subagent that reads that skill's harness-owned `SKILL.md` in full and follows it, this run's resolved level passed in the brief as the same `involve=` token; when it ends, one line in the decisions record, `what matched → what ran → what it wrote` (§10.5).
   - A prepared STOP-line command — the stop-line rule above: launch and log, then wait for it to finish, collect the output its handoff named so the criterion can be checked, and continue at step 1; a command that cannot be waited on ends the run, the report naming what it is waiting on. When the user's stop line stops the launch — print the command, stop, and report.
3. Everything a user-named run asks, this one asks. An unsettled target names the candidates and waits (§5.2, §10.3); a mandatory confirmation point asks and waits (§7.2), and where nobody can answer — a headless run — it stops there and reports rather than assumes; one unit of work per start (§10.4). A question a started run hands back is triaged the same way, at this run's resolved level (§7.7): a judgment call the level takes unasked is answered with its marked recommendation and logged; anything that must be asked goes to the user, never answered by this loop.
4. After each run ends, take the next action it names — under this grant the seven are taken as the eight are (§10.6) — and where none is named, run `star-flow-status` again.
5. An action that failed is not retried on the same target. The routing a failure earns — a reviser pass, a fix run — is itself a next action, taken once; when it too fails, stop and report.

## Where it ends

Report and stop at the first of: the goal's check passes; a mandatory question has no one to answer it; a command crosses the user's stop line, or a launched one cannot be waited on; a full pass leaves the goal check no closer than the pass before it; step 5 runs out of moves. The final reply names what ran, what each run wrote, the goal check's result, and — when the run stopped short — the exact command or question it is waiting on. Nothing carries between invocations: re-typing the command resumes from the tree as the runs left it, and the stop line is read fresh from the new invocation.

## What this command never does

It starts skills and launches the commands they prepare; it grants nothing else. It writes no plan, no report, no code of its own — everything produced comes from the runs it starts. One goal per invocation; the next goal is the next invocation.
