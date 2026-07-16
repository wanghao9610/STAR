# Installer Policy — the uv > pip > conda ladder

Which tool installs what, in what order, and what happens on failure. Every command runs through the absolute `$ENV_PY` or `$CONDA_HOME/bin/conda` — never `source activate`, never system python.

## The ladder

| Tier | When | Command shape |
|---|---|---|
| uv (default) | uv on PATH, or the user approved installing it | `uv pip install --python $ENV_PY -r <file>` |
| pip (fallback) | uv absent and declined, or a package fails under uv | `$ENV_PY -m pip install <pkg>` |
| conda (whitelist only) | conda backend **and** the package is on the whitelist | `$CONDA_HOME/bin/conda install -n <ENV_NAME> -c conda-forge <pkg> -y` |

- uv missing → ask once, with a recommendation: install uv (e.g. `$PYTHON_HOME/bin/python -m pip install --user uv`, or the official standalone installer if the user prefers) / use pip for this run. Declining costs speed, not correctness.
- Do not mix managers beyond the ladder: what uv/pip installed, uv/pip upgrades. Never conda-install over pip-managed packages — the whitelist is the only conda territory, and pip never owns it.

## Install order

1. `conda.txt` — conda backend only; the system/toolchain layer goes first so later builds can see it.
2. `framework.txt` — with its `--extra-index-url`; the biggest wheels install early to fail fast.
3. `runtime.txt`
4. `optional.txt` — only if the approved install plan included it.
5. Editable project install last, when packaging metadata exists: `uv pip install --python $ENV_PY --no-deps -e ${CODE_NAME}` (`--no-deps` because the categories already covered dependencies).

## Conda whitelist (the only things conda installs)

`cudatoolkit` / `cuda-toolkit`, `cudnn`, `nccl`, `gcc_linux-64` / `gxx_linux-64` (compilers for source builds), `ffmpeg`, `openmpi` / `mpich` (with `mpi4py`), `faiss-gpu`.

Rationale: these ship native libraries that must be isolated from — or coordinated with — the system; pip wheels for them either do not exist or fight the system copies.

Venv backend needing a whitelist item → do not improvise (no `sudo`, no apt/brew): stop and ask with options — the user installs it system-wide themselves / skip it / a pip alternative where one exists (`faiss-cpu`, `imageio-ffmpeg`).

## Framework wheel selection (CUDA matching)

1. **Ceiling**: the `CUDA Version` in the `nvidia-smi` header = the highest runtime the driver supports.
2. **Pin**: any torch pin from the dependency source, plus any CUDA version the upstream README names.
3. **Choose**: the highest official `cuXXX` wheel index ≤ ceiling that satisfies the pin — verify current index availability on pytorch.org/get-started (indexes rotate; do not trust memory). Example: `--extra-index-url https://download.pytorch.org/whl/cu121`.
4. macOS → default PyPI wheels (CPU + MPS). Linux without an NVIDIA GPU → `/whl/cpu`.
5. **Mismatch** (pin newer than the ceiling; upstream demands an nvcc the machine lacks) → a gate question with concrete options: older wheel that matches the pin / newer torch (name the API risk) / CPU build.

`nvcc` matters only for source builds (STOP line anyway); wheel installs need only the driver.

## Failure handling

- Per package: uv → pip retry, ≤2 attempts total; capture the error tail.
- A failed package does not abort the run: record it, keep installing the rest, then resolve or hand over the failures in one batch at the end.
- Source-build signatures — `--no-build-isolation` required, `setup.py` probing `CUDA_HOME`, "Building wheel …" that runs minutes (`flash-attn`, full `mmcv`, `detectron2` from git) → STOP line: write the exact prepared command into ENV_REPORT's "Awaiting user"; never run it autonomously.
- Resolver conflicts (uv/pip backtracking errors) → never force with `--no-deps` (the editable project install is the sole exception); surface the conflicting pair at the gate or in the report.

## Mirrors & indexes

- Respect `PIP_INDEX_URL` / `UV_DEFAULT_INDEX` / `UV_INDEX_URL` already present in the environment or `.env` — pass them through, never override.
- The torch index composes with mirrors: keep the user's primary index, add the torch index via `--extra-index-url`.
- Never write global configuration: no `pip config set`, no `.condarc` edits, no `uv.toml` writes.
