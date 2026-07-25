#!/usr/bin/env bash
set -euo pipefail

# Placeholder experiment. It runs no science — it confirms that the launcher
# resolved the runtime and exported the project paths, so a fresh checkout has
# something that visibly succeeds. Replace it with your first real experiment.

echo "Interpreter : $(command -v python || command -v python3 || echo 'not on PATH')"
for var in ROOT_DIR CODE_DIR DATA_DIR INIT_DIR WORK_DIR SCPT_DIR; do
    printf '%-12s: %s\n' "${var}" "${!var:-unset — run this through execs/run.sh}"
done
