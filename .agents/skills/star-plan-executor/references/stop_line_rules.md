# STOP-line Rules — what the agent runs vs what the user runs

The agent and any delegate may write code and run **light validation**. Anything **heavy, costly, or irreversible** crosses the STOP line. Prepare the exact command and record it in EXEC_LOG's "Awaiting user" area unless a launch is already specifically authorized. An ordinary request to implement the plan, an EXEC_PLAN approval, or confidence in the command is not launch authorization. A valid `star-auto` run is the one standing exception for heavy or costly commands: its launcher may run a prepared command after review when the command's stated, bounded cost is within its `stop=` line, or when that invocation set no stop line. A separate explicit user instruction may authorize the same exact or clearly bounded launch in an ordinary run; cite and reuse that instruction rather than asking again. Neither form covers a command whose cost cannot be judged against a user-set limit, nor deletion, overwrite, `sudo`, system/driver installation, or another irreversible action unless the user separately and specifically authorizes that exact action.

## Agent runs (light validation)

- Unit tests / runnable checks, import checks, a forward pass on a tiny batch.
- Small-scale, **no-finetune** inference on a small subset — e.g. an MVP done-criterion: "no training, small subset, swap the text input and compare."
- Dry-runs, config validation, shape / dtype checks, a few-step overfit sanity run.
- Anything that finishes in minutes on modest resources, writes generated outputs and durable execution records only under `wkdrs/<run>/`, and keeps intermediate working files under `tasks/<plan-name>/`.

## Crosses the STOP line → hand to user

- **Long or multi-GPU training / fine-tuning** — any full training run.
- **Costly API calls** — large-volume LLM/VLM inference billed per call (e.g. generating descriptions over a full dataset).
- **Full-dataset evaluation** that takes hours or significant compute.
- Anything that **overwrites existing artifacts** the user may want to keep, or writes generated run artifacts outside `wkdrs/<run>/`. Routine intermediate-file writes under `tasks/<plan-name>/` do not cross the STOP line. Resolve exact targets first and preserve existing artifacts until their overwrite is specifically authorized.
- Anything whose cost or runtime you **cannot bound** — when unsure, treat it as STOP.

## How to hand off

For each STOP action, write into EXEC_LOG "Awaiting user":

- the **exact command**, invoked through the `.env` conda env (never system python) via the project's launch entry point (`execs/run.sh`) where one exists;
- **what it produces and where** (`wkdrs/<run>/…`);
- **what output to bring back** so the done-criterion can be verified.

**Write** the heavy command as a runnable script under `execs/scpts/<run>.sh` (writing the file is light; running it is not) and make `bash execs/scpts/<run>.sh` the command the handoff names, so it has one reviewed launch path — and so the launch guard (conventions §2) can tell this launch from light validation: it declines that script, and the `wkdrs/<run>/.await` marker a `star-auto` launch writes, while `wkdrs/<run>/` holds no `CODE_REVIEW_<date>.md` or its newest one is dated before the newest date in `EXEC_LOG.md`. Do not bypass that guard. Without the specific ordinary-run authorization above, hand the command to the user. Under a valid `star-auto` grant, return control to its launcher, which logs the command and stated cost and may execute it only after the review is current and either no `stop=` was set or the command stays within it; `auto=unattended` alone adds no permission to overwrite, delete, install, or exceed a cost line.

When no launch authorization applies, stop and tell the user in the report which commands are waiting on them — and name `star-code-reviewer <leaf>` above them as the next command: a defect caught before the compute costs a review, the same defect caught after costs the compute and the re-run too. On re-invoke, apply first any blocker or major findings that review left unsettled (the skill's resume rule), then, if those outputs now exist, resume at done-criterion verification (Step 5). Whether the user, an authorized ordinary run, or `star-auto` launched it, keep the exact command, stated cost, raw output/log path, and code version together in EXEC_LOG so later verification does not depend on a summary or require an automatic repeat.
