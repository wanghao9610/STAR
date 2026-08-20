# Runnable Check Spec — three layers, evidence required

Run after installation, through the absolute `$ENV_PY`. Budget: minutes, CPU-light, no data, no weights, no network downloads. Every check records its exact command and output tail as evidence in ENV_REPORT's runnable-check results table.

## L1 — imports

Scope: every distribution in `framework.txt` + `runtime.txt`, plus `optional.txt` if it was installed.

Map distribution → import name (reverse of the resolution table), then emit the whole layer in **one** run — one tab-separated row per distribution: dist, import name, `ok` or `FAIL`, the version or the error tail, and the exact command used.

```bash
$ENV_PY - <<'EOF'
import importlib, importlib.metadata as md, traceback
for dist, mod in PAIRS:                    # the mapped list, in framework.txt + runtime.txt order
    try:
        m = importlib.import_module(mod)
        v = getattr(m, "__version__", None) or md.version(dist)
        print(f"{dist}\t{mod}\tok\t{v}\timport {mod}")
    except Exception as e:
        print(f"{dist}\t{mod}\tFAIL\t{type(e).__name__}: {e}\timport {mod}")
EOF
```

Pass = the import succeeds; record the version. The matrix is transcribed from this one output rather than reassembled from thirty-odd separate calls — the likeliest way an evidence cell ends up empty while the check is recorded as run. The main agent runs the loop itself: Principle 6 is unchanged, and batching commands is not delegating them. Every row carries its exact command, a failing row the error tail, or the loop becomes what hides one.

## L2 — framework deep check

For torch (adapt the same shape for jax / tensorflow):

- Report `torch.__version__` and `torch.version.cuda`.
- GPU expected (the preliminary check's `nvidia-smi` succeeded): `torch.cuda.is_available()` must be `True`; record `device_count()`; run a small op — `(torch.randn(64,64,device='cuda') @ torch.randn(64,64,device='cuda')).sum()`.
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

≤2 fix rounds per layer; still failing → mark the layer `blocked` in the results table with the error tail, continue to later layers only where independent, and point it out in the final report.

## Evidence format (runnable-check results rows)

| Layer | Check | Command | Result | Evidence |
|---|---|---|---|---|
| L1 | torch imports | `$ENV_PY -c "import torch; …"` | pass | `2.4.1` |
| L2 | CUDA available | `$ENV_PY -c "…is_available()…"` | pass | `True / 2 devices / sum=-11.98` |
| L3 | entrypoint | `$ENV_PY code/train.py --help` | blocked | `ModuleNotFoundError: pycocotools` (tail) |

Result values: `pass` / `blocked` / `skipped (reason)`. An empty Evidence cell is not acceptable for `pass`.
