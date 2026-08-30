# Drive the workflow toward a goal

The user has typed `star-auto` — this file is what that invocation runs. Typing it is the auto grant of conventions §10.7: while this run pursues its goal, the skill each next action names may be started without further naming, the seven explicit-only ones included, and a prepared STOP-line command may be launched instead of handed back. At `involve=low`, that same explicit grant also covers the executor chain's routine local implementation, mechanical review fixes, and Git lifecycle described below; a started run otherwise behaves exactly as if the user had typed its name.

Invocation shape: `star-auto <GOAL> [stop=<STOP-LINE>] [involve=<level>]`.

## Parse the invocation

- Strip `involve=<level>` first, taken from outside the stop text — before `stop=`, or as the invocation's final token; the same words inside the stop line are stop-line text, not the token (conventions §7.7). When nothing sets a level — no token, no `INVOLVE` in `.env` — this run resolves to `low`, not `medium`: an autonomous run takes the marked recommendation on its own judgment calls and logs each (§7.8). At `low`, the invocation itself pre-approves the executor's recommended plan, explicit-path staging and commits, execution-branch or worktree creation, behavior-preserving review fixes that delete nothing, a clean reviewed squash merge, and removal of a worktree only after its durable artifacts have moved out and `git status --porcelain` is empty. Those operations run without an authorization question and are logged. Review fixes that require deletion are skipped and routed rather than guessed. The merged execution branch is retained without asking, so unattended cleanup never needs a forced delete. This exception is carried to the executor and code reviewer as the internal `auto=unattended` token; it is not part of the user-facing invocation shape.
- Then strip `stop=`: everything from that token to the end of what remains is the stop line, natural language in the user's own words — `stop=any single training over 4 hours, or any paid API call`, `stop=用卡超过 2 张就停` (either language, or both at once). **Given**, it is the line this run must not cross: before launching a prepared command, state its expected cost and judge it against each condition — a command that crosses the line, or that cannot be judged against it, is printed and handed back exactly as §2 says. **Absent**, the run is uncapped: prepared STOP-line commands launch autonomously, the goal owning the run (§2's one exception). Either way every launch is logged in the decisions record with its stated cost. Apart from the clean worktree removal above, neither the grant nor any stop line covers deletion, overwrite, `sudo`, system or driver installation, history rewriting, forced Git, `push`, discarding unmerged work, or resolving a merge conflict — those stop and report instead of being guessed through.
- What remains is the goal. No goal — ask for one; never infer a goal from the repository.

## Before the loop

Read `STAR_LANG` and `INVOLVE` from `.env` in one grep (§7.6, §7.7). Turn the goal into a check the run can verify — the `exec_status` a leaf must reach, the file that must exist, the metric a report must show — and open with one line stating that check, the stop line (or that none was set), and the resolved involve level. A goal that cannot be turned into a check is asked about, not pursued.

## The loop

1. When a launch marker on disk names a command whose exit file has not appeared — left by this invocation or an earlier one — resume the wait in "Waiting on a launched command" below instead; the status pass runs after the exit event. Otherwise run `star-flow-status` through the harness's native skill mechanism and take its single next action. An action that does not advance the goal's check is not taken: say so in one line, leave it for a later invocation, and take the next action that does.
2. Start what it names:
   - One of the eight the agent may pick up — the harness's native mechanism, exactly as §10.2–10.6 say, with this run's resolved level appended as an `involve=` token: each started run resolves its own level (§7.7), so a start that carries no token would fall back to `.env`, not to this run's default. When the named skill is `star-plan-executor` or `star-code-reviewer` and the resolved level is `low`, append `auto=unattended` too; that token transmits this invocation's grant and is stripped before the skill reads its target or description.
   - One of the seven explicit-only — the grant covers it: announce one line first (what matched, which target), then dispatch one subagent that reads that skill's harness-owned `SKILL.md` in full and follows it, this run's resolved level passed in the brief as the same `involve=` token; when it ends, one line in the decisions record, `what matched → what ran → what it wrote` (§10.5).
   - A prepared STOP-line command — the stop-line rule above: launch and log as "Waiting on a launched command" below says — detached, marker written, the wait held on the exit event rather than on refreshes — then collect the output its handoff named so the criterion can be checked, and continue at step 1; a command that cannot be waited on this way — no local process to hold, no file its progress would touch — ends the run, the report naming what it is waiting on. When the user's stop line stops the launch — print the command, stop, and report.
3. An unsettled target names the candidates and waits (§5.2, §10.3), and one unit of work runs per start (§10.4). At `low`, operations carried by `auto=unattended` take the guarded behavior above without asking. Every other mandatory confirmation point still asks and waits (§7.2); where nobody can answer — a headless run — it stops there and reports rather than assumes. A question a started run hands back is triaged the same way: a judgment call the level takes unasked is answered with its marked recommendation and logged, while ambiguity or an operation outside the unattended grant goes to the user.
4. After each run ends, take the next action it names — under this grant the seven are taken as the eight are (§10.6) — and where none is named, run `star-flow-status` again.
5. An action that failed is not retried on the same target. The routing a failure earns — a reviser pass, a fix run — is itself a next action, taken once; when it too fails, stop and report.

## Waiting on a launched command

The wait is event-driven: the run comes back when the command exits, not on a clock. Monitoring by refresh — re-reading the log, re-running the status skill, a watch pass to see how it is going — is what this section exists to prevent: every refresh spends a full model turn, and one training run outlives thousands of them.

- **Launch detached, leave a marker.** Start the command in the background, immune to the session ending, wrapped so its exit code lands in a file — `nohup bash -c '<command>; echo $? > wkdrs/<run>/.await.exit' > <log> 2>&1 &` — with the log under that run's `wkdrs/<run>/` (keeping any redirection the handoff already wrote), and in the same shell call write the marker `wkdrs/<run>/.await`: line 1 the process id, line 2 the log path, line 3 the output the handoff named. The exit file, not the process id, is what the wait watches: a sandboxed harness is often denied `kill -0` and `ps` on a process it did not start — a denial that mimics an exit — while a file is readable from any sandbox. The marker pair is launch state this command owns — neither plan nor report — and both files are removed when the wait ends.
- **Hold the turn shell-side.** On a harness whose shell itself announces a detached command's completion, launch through that mechanism and let the announcement return the turn. Everywhere else, wait inside one blocking shell call — sleep and re-check in the shell, where iterations cost nothing:

  ```bash
  run=wkdrs/<run>; log=$(sed -n 2p "$run/.await")
  deadline=$((SECONDS + 550))    # stay inside the harness's per-call time limit
  while [ ! -f "$run/.await.exit" ] && (( SECONDS < deadline )); do sleep 20; done
  if [ -f "$run/.await.exit" ]; then echo "exited $(cat "$run/.await.exit")"
  else echo "running — log last written $(date -r "$log" '+%H:%M:%S' 2>/dev/null || echo '(no log yet)')"; fi
  ```

  `running` re-issues the same call with nothing in between — no log read, no status pass, no watch, at most one line of text. `exited` ends the wait: read the log's tail once, collect what the handoff named, remove the marker pair. A missing exit file with a long-stalled log is the one case the process id settles — and where the harness denies even that probe, the log's silence is the verdict, reported as a stall, never as a clean exit.
- **A stall is an event too.** The `running` line carries the log's last write time; a diagnostic read — `star-expt-analyst watch` is its shape — happens only when that time stops moving for longer than the command's own logging rhythm makes plausible, or on `exited`. Never on a timer, never to check in.
- **Across invocations.** Nothing carries between invocations except what is on disk — and the marker is on disk. A fresh invocation that finds `.await` with no `.await.exit` beside it resumes this wait directly (step 1), so an outer driver that re-invokes this command spends one turn per redrive, not a monitoring pass.

## Where it ends

Report and stop at the first of: the goal's check passes; a mandatory question outside the unattended grant has no one to answer it; a command crosses the user's stop line, or a launched one cannot be waited on; a guarded Git operation finds a dirty tree, a conflict, or another precondition failure; a full pass leaves the goal check no closer than the pass before it; step 5 runs out of moves. The final reply names what ran, what each run wrote, the goal check's result, and — when the run stopped short — the exact command, question, or failed guard it is waiting on. Nothing carries between invocations: re-typing the command resumes from the tree as the runs left it — a live launch marker included — and the stop line is read fresh from the new invocation.

## What this command never does

It starts skills, launches the commands they prepare, and at `low` transmits only the executor-chain grant enumerated above. It writes no plan, report, or code of its own — everything produced comes from the runs it starts. It never weakens `star_commit_guard.sh`. One goal per invocation; the next goal is the next invocation.
