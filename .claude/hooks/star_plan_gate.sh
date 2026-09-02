#!/usr/bin/env bash
# Answer Claude's plan-approval prompt while the project runs at INVOLVE=low
# (.env, workflow conventions §7.7): the plan the executor presents is approved
# as it stands, taken for the user. The confirmation point is still presented in
# full; the skill's decisions record logs that it was taken unasked.
#
# Two mount points, one script — and on an interactive Claude Code 2.1.25x
# session neither one clears the plan dialog. PermissionRequest is not consulted
# for it at all; PreToolUse(ExitPlanMode) fires and its allow is accepted as a
# permission decision, yet the dialog is not a permission prompt and still
# renders and waits for a keypress (every ExitPlanMode call in this machine's
# 2.1.245–2.1.257 transcripts waited on one). What moves the approval at `low`
# on those versions is the executor's own text: it stays out of plan mode there,
# so ExitPlanMode is never called. Both mounts stay for the paths that do consult
# a hook — an older or headless harness raising the approval as a
# PermissionRequest, or a later dialog that honors PreToolUse. That older flow
# moves the mode only via the answer, so the PermissionRequest reply still sets
# acceptEdits — the dialog's then-first option; the PreToolUse reply leaves the
# mode alone, since the exit flow itself restores the mode the session held
# before plan mode. The payload's hook_event_name says which mount invoked us.
#
# The level comes from star_involve_level.sh: the `involve=` token of the
# session's most recent STAR command, or `.env`'s INVOLVE when it carried none.
# Silence means "no decision", so every other level and a project that sets none
# fall through to the normal approval dialog. The level is resolved on each
# call, so a new invocation — or an edit to .env — takes effect without a
# restart.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: it carries the transcript path
# the level is resolved from, and a hook that exits without reading stdin leaves
# the runtime's write to fail.
input=$(cat)

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/star_involve_level.sh"
involve="$(star_involve_level "${input}" "${root}")"
[[ "${involve}" == "low" ]] || exit 0

event="$(star__payload_field "${input}" hook_event_name)"
if [[ "${event}" == "PreToolUse" ]]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"involve=low (star_plan_gate.sh): plan approved unasked; the session resumes its pre-plan mode"}}\n'
else
    printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow","updatedPermissions":[{"type":"setMode","mode":"acceptEdits","destination":"session"}]}}}\n'
fi
