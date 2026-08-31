#!/usr/bin/env bash
# Answer Claude's plan-approval prompt while the project runs at INVOLVE=low
# (.env, workflow conventions §7.7): the plan the executor presents is approved
# as it stands, taken for the user. The confirmation point is still presented in
# full; the skill's decisions record logs that it was taken unasked.
#
# Two mount points, one script. Interactive sessions since Claude Code ~2.1.25x
# run plan approval through a dialog that no longer consults PermissionRequest
# hooks, so settings.json also mounts this script on PreToolUse(ExitPlanMode):
# an allow there bypasses the dialog, and the exit flow itself restores the mode
# the session held before plan mode (auto stays auto). The PermissionRequest
# mount stays for harness paths that still route plan approval through it; that
# older flow moves the mode only via the answer, so there the reply still sets
# acceptEdits — the dialog's then-first option. The payload's hook_event_name
# says which mount invoked us.
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
