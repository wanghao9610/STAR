#!/usr/bin/env bash
# Answer Claude's plan-approval prompt (PermissionRequest on ExitPlanMode) while
# the project runs at INVOLVE=low (.env, workflow conventions §7.7): the plan
# the executor presents is approved as it stands and the session lands in auto
# mode (acceptEdits) — the dialog's first option, taken for the user. The
# confirmation point is still presented in full; the skill's decisions record
# logs that it was taken unasked.
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

printf '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow","updatedPermissions":[{"type":"setMode","mode":"acceptEdits","destination":"session"}]}}}\n'
