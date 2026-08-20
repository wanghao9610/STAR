# Step 9: Watch (watch mode only)

Read where the invocation carried `watch`. A full analysis and an `aggregate` run never read this file.

A quick check of a run that may still be executing — dimension C plus liveness, nothing else. Chat-only: no verdict, no report file, no figures; re-run it as often as needed.

1. Resolve the run as in Step 0. No run directory, or no logs in it yet → say so and stop; nothing to watch.
2. Scan the logs for dimension C's fatal, numeric, and dynamics signals (crash, traceback, NaN/Inf, OOM, divergence, a plateau) — grep for patterns and read head and tail, never a big log whole.
3. Liveness and progress: the newest log/artifact mtime ("last write N minutes ago"), and the latest progress line — step / epoch / eval with its values, quoted as the log states them.
4. Report ≤200 words, liveness first: alive or stalled since when, the latest progress line, any fatal or anomalous signal with its `file:line`, and one next action — keep waiting; a fatal signal → stop the job, fix and relaunch via `star-plan-executor <slug>`; import or environment errors → `star-env-builder`. Say plainly the run has not been scored: when it finishes, the full pass (`star-expt-analyst <slug>`) does that.

