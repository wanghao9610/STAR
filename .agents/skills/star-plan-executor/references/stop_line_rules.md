# STOP-line Rules — what Codex runs vs what the user runs

Codex and any delegated workers may write code and run **light validation**. Anything **heavy or irreversible** crosses the STOP line: prepare the exact command, write it to EXEC_LOG's "Awaiting user" area, and stop for the user to run it. Never launch across the STOP line autonomously.

## Codex runs (light validation)

- Unit / smoke tests, import checks, a forward pass on a tiny batch.
- Small-scale, **no-finetune** inference on a small subset — e.g. an MVP done-criterion: "no training, small subset, swap the text input and compare."
- Dry-runs, config validation, shape / dtype checks, a few-step overfit sanity run.
- Anything that finishes in minutes on modest resources, writes generated outputs and durable execution checkpoints only under `wkdrs/<run>/`, and keeps intermediate working files under `tasks/<plan-name>/`.

## Crosses the STOP line → hand to user

- **Long or multi-GPU training / fine-tuning** — any full training run.
- **Costly API calls** — large-volume LLM/VLM inference billed per call (e.g. generating descriptions over a full dataset).
- **Full-dataset evaluation** that takes hours or significant compute.
- Anything that **overwrites existing artifacts** the user may want to keep, or writes generated run artifacts outside `wkdrs/<run>/`. Routine intermediate-file writes under `tasks/<plan-name>/` do not cross the STOP line.
- Anything whose cost or runtime you **cannot bound** — when unsure, treat it as STOP.

## How to hand off

For each STOP action, write into EXEC_LOG "Awaiting user":

- the **exact command**, invoked through the `.env` conda env (never system python) via the project's run surface (`execs/run.sh`) where one exists;
- **what it produces and where** (`wkdrs/<run>/…`);
- **what output to bring back** so the done-criterion can be verified.

For reproducibility, Codex may also **write** the heavy command as a runnable script under `execs/scpts/<run>.sh` (writing the file is light; running it is not) so the user launches it with one command. Never execute it — that stays across the STOP line.

Then stop and tell the user in the report which commands are waiting on them. On re-invoke, if those outputs now exist, resume at done-criterion verification (Step 6).
