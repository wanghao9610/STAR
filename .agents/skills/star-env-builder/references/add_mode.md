# Step 8: Add packages (add mode only)

Read where the invocation carried `add <package>…`. Every other run of this skill — creating an environment, or verifying and repairing one in place — never reads this file.

The environment already exists; this mode installs into it and records what it installed — a broken environment is a full run's job (Step 2's *verify & repair in place*).

1. Resolve `ENV_PY` from `.env` (Principle 1). No usable interpreter → say so and recommend a full `star-env-builder` run; install nothing.
2. Categorise each package per `references/installer_policy.md` — framework / runtime / optional / conda-only — and say which requirements file each lands in.
3. **Confirmation point** (Principle 2 — nothing installs before it): present the packages, their categories, the versions and index to be used, the download size when large, and any CUDA coupling; ask *approve and install* / *adjust* / *abort*.
4. Install in the uv > pip > conda order (conda only under a conda backend and only for the whitelist). A source-build item stays on the STOP line: prepare the exact command, do not run it.
5. Run the runnable check on the new packages only (`references/runnable_check_spec.md`): L1 — each imports and reports a version through `$ENV_PY`; a new framework package also gets L2. A failure → diagnose, one bounded retry, then mark it `blocked` and report; never leave a package installed but unverified.
6. Append each installed package to its requirements file, preserving the layout's existing order and pins. Append an `## Added <date>` block to the newest `wkdrs/env_<ENV_NAME>_<date>/ENV_REPORT.md` (none exists → write a fresh report). Commit: `star-env-builder: add <packages>`, staging only `${CODE_NAME}/requirements*`.
7. Report ≤500 words: what installed, what each requirements file gained, the runnable-check evidence, anything blocked or awaiting the user.

