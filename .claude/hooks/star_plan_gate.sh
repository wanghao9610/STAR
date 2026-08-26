#!/usr/bin/env bash
# Answer Claude's plan-approval prompt (PermissionRequest on ExitPlanMode) while
# the project runs at INVOLVE=low (.env, workflow conventions §7.7): the plan
# the executor presents is approved as it stands and the session lands in auto
# mode (acceptEdits) — the dialog's first option, taken for the user. The
# confirmation point is still presented in full; the skill's decisions record
# logs that it was taken unasked.
#
# Silence means "no decision", so every other level and a project with no .env
# fall through to the normal approval dialog. INVOLVE is read on each call, so
# editing .env takes effect without a restart.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: the runtime writes it to this
# hook's stdin, and a hook that exits without reading leaves that write to fail.
cat > /dev/null

line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
value="${line#INVOLVE=}"
value="${value%%#*}"
involve="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
[[ "${involve}" == "low" ]] || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow","updatedPermissions":[{"type":"setMode","mode":"acceptEdits","destination":"session"}]}}}\n'
