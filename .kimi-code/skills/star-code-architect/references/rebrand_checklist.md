# Conservative Rebrand Checklist

Rename the imported codebase to `${CODE_NAME}` without silently breaking it. The rule of thumb: **rename identifiers Python resolves; never rename strings frameworks resolve.**

## Preconditions

- `${CODE_NAME}/UPSTREAM.md` written and the import commit landed (rollback anchor).
- Know the upstream Python package name: the top-level importable directory (may differ from the repo name; may live under `src/`).

## Steps, in order — verify after each

Each step ends with: `grep -rn '<old-name>' ${CODE_NAME} | wc -l` (count must drop as predicted), then `python -m compileall -q ${CODE_NAME}` (syntax-level check, needs no installed deps).

1. **Package directory**: `<upstream_pkg>/` → `<code_name>/` (inside `${CODE_NAME}/`, or under `src/`). Skip if they already match.
2. **Imports**: rewrite `import <upstream_pkg>` / `from <upstream_pkg> …` across all `.py` files, plus `__init__.py` re-exports.
3. **Packaging metadata**: `pyproject.toml` `[project].name` (+ `[tool.setuptools]` packages), or `setup.py`/`setup.cfg` `name=`, `packages=`, `package_dir`.
4. **Console entry points**: `[project.scripts]` / `entry_points={'console_scripts': …}` targets.
5. **README**: title, install command (`pip install <name>`), import snippets in usage examples.
6. **Docs config** (only if trivial): `docs/conf.py` project name.

Then commit: `star-code-architect: rebrand to <CODE_NAME>` (stage only `${CODE_NAME}/`).

## Do-NOT-touch list → residual table

These look like the package name but are resolved by frameworks, checkpoints, or services at **runtime as strings**. Renaming them breaks things with no traceback at rename time:

| Category | Examples | Why untouchable now |
|---|---|---|
| Registry strings | `@MODELS.register_module('XDet')`, detectron2 `META_ARCH` keys | Configs reference them by literal string |
| Config `type:` keys | `type: XDetHead` in YAML/py configs | Resolved via registry lookup |
| Checkpoint coupling | `state_dict` prefixes, class names used in pickled ckpts | Pretrained weights stop loading |
| Service names | wandb project, logger names, HF hub ids | External records reference them |
| Class-name prefixes | `XDetBackbone` and friends | Coupled to all of the above |

For each occurrence class, add a row to the residual table (`codearc.md` §7): location pattern, category, risk, suggested later action. Suggest — never auto-apply — casing for future renames (e.g. `code` → `Code` prefix). Later renames go through `star-plan-executor` steps, each with its own check.

## Import smoke (post-env)

Once the `.env` conda env has the dependencies: `python -c "import <code_name>"` through that env. Record it in the final report; if the env does not exist yet, say the check is pending and hand over the prepared install commands instead.
