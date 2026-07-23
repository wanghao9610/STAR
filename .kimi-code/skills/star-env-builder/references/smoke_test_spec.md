# Smoke Test Spec — three layers, evidence required

Run after installation, through the absolute `$ENV_PY`. Budget: minutes, CPU-light, no data, no weights, no network downloads. Every check records its exact command and output tail as evidence in ENV_REPORT's smoke matrix.

## L1 — imports

Scope: every distribution in `framework.txt` + `runtime.txt`, plus `optional.txt` if it was installed.

For each, map distribution → import name (reverse of the resolution table) and run:

```bash
$ENV_PY -c "import <mod>; print(getattr(<mod>, '__version__', 'n/a'))"
```

Version `n/a` → fall back to `importlib.metadata.version("<dist>")`. Pass = the import succeeds; record the version.

## L2 — framework deep check

For torch (adapt the same shape for jax / tensorflow):

- Report `torch.__version__` and `torch.version.cuda`.
- GPU expected (the preflight `nvidia-smi` succeeded): `torch.cuda.is_available()` must be `True`; record `device_count()`; run a small op — `(torch.randn(64,64,device='cuda') @ torch.randn(64,64,device='cuda')).sum()`.
- macOS: check `torch.backends.mps.is_available()`; run the op on `mps`.
- CPU-only machine: run the op on CPU and report *CPU-only (expected)* — a finding, not a failure.
- `is_available()` `False` on a GPU machine **is** a failure. Usual causes, in order: the CPU wheel got installed (`torch.version.cuda` is `None` — wrong index used), or the driver is older than the wheel's CUDA runtime (re-match the index against the ceiling).

## L3 — project

1. `$ENV_PY -m compileall -q ${CODE_NAME}` — syntax-level, needs no dependencies.
2. Editable-installed → `$ENV_PY -c "import <package>"` — catches import-time dependency gaps compileall cannot see.
3. Cheapest entrypoint, first that exists: a console entrypoint with `--help`; `$ENV_PY ${CODE_NAME}/<train|main|demo>.py --help` (prefer whatever the README names); tests present → `$ENV_PY -m pytest --collect-only -q` (collection imports test modules without running them).

No entrypoint exists → say so honestly; L3 is then compileall + package import.

## Failure protocol

A failed layer → diagnose from the traceback:

- Missing transitive dependency → install it, **and** append it to the correct generated requirements file (a diagnosis that fixes the env but not the layout will break the next rebuild). Pre-existing (priority-1) layouts are not edited — record the gap in the report instead.
- Wrong wheel (CPU torch on a GPU box, ABI mismatch) → back to the installer policy's wheel selection.

≤2 fix rounds per layer; still failing → mark the layer `blocked` in the matrix with the error tail, continue to later layers only where independent, and surface it in the final report.

## Evidence format (smoke matrix rows)

| Layer | Check | Command | Result | Evidence |
|---|---|---|---|---|
| L1 | torch imports | `$ENV_PY -c "import torch; …"` | pass | `2.4.1` |
| L2 | CUDA available | `$ENV_PY -c "…is_available()…"` | pass | `True / 2 devices / sum=-11.98` |
| L3 | entrypoint | `$ENV_PY code/train.py --help` | blocked | `ModuleNotFoundError: pycocotools` (tail) |

Result values: `pass` / `blocked` / `skipped (reason)`. An empty Evidence cell is not acceptable for `pass`.
