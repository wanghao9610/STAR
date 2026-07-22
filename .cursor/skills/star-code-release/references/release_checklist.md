# Release Checklist

Four families of check, run over the **tracked** repository plus anything this run promoted. Every finding carries `file:line`, the check that caught it, and a concrete fix. Severity is fixed by the family, not by how the rest of the run went: a single open blocker means the run's verdict is `blocked`, never "ready with one caveat".

Scope note: check what a stranger who clones the repository would receive. `git ls-files` is the authority on that, plus the paths promoted this run. A secret sitting in a git-ignored `wkdrs/` file is not a release blocker — but a secret in a file this run is about to promote is, which is why the sweep runs after gather.

## 1. Secrets & machine-local paths — **blocker**

Nothing here is a judgement call, and nothing here is waived.

| Check | How | Fix |
|---|---|---|
| `.env` committed | `git ls-files .env` returns anything | `git rm --cached .env`; confirm `.gitignore` covers it. Say plainly that history still holds it, and that rewriting history is the user's call |
| API keys and tokens | Grep the tracked tree for `sk-`, `hf_`, `ghp_`, `AKIA`, `api[_-]?key`, `secret`, `token`, `password`, `WANDB_API_KEY`, `Bearer ` | Move it to `.env` / an environment variable and read it there |
| Machine-local absolute paths | Grep for `/home/`, `/Users/`, `/mnt/`, `/data1/`, `C:\\`, and the user's own username | Read the root from `.env` (AGENTS.md §6). Always a blocker — it is the single most common reason a research repo does not run for anyone else |
| Internal hosts & endpoints | Grep for internal-looking hostnames, private IP ranges (`10.`, `192.168.`, `172.16–31.`), cluster node names, and non-public URLs | Remove, or replace with the public equivalent |
| Personal data | Author emails beyond the citation, an SSH config, a `.netrc`, private dataset URLs | Remove |

Grep through the tracked file list, and read every hit before reporting it: a docstring saying "do not hardcode `/home/...`" is not a finding, and `token` inside `tokenizer` is not a secret. A false blocker costs the checklist its authority.

## 2. License & attribution

| Check | Severity | Fix |
|---|---|---|
| A root `LICENSE` exists | blocker | The user chooses the license; name the constraint from §5 below and ask. Never pick one for them |
| It is compatible with the upstream license `metds/codearc.md` §5 recorded | blocker on conflict | Report the conflict precisely — "upstream is GPL-3.0, root LICENSE is MIT" — and stop there. Resolving a license conflict is a legal decision, not a skill's |
| Upstream `LICENSE` / `CITATION*` files still in place under `${CODE_NAME}/` | blocker if removed | Restore them from git history |
| `${CODE_NAME}/UPSTREAM.md` exists when the codebase was bootstrapped from a repo | major | `/star-code-architect` records provenance |
| The README's Acknowledgement names the upstream repo and the core papers | major | Compile it from `UPSTREAM.md` and `metds/refs/refs_index.md` |
| Third-party code copied in without attribution | major | Name the file and where it came from, if that is recoverable; otherwise flag it for the user |

## 3. Runnable commands

Every command the README prints, checked in the order a reader would meet them. This is the check that decides whether the repository works for anyone but its author.

1. **Install** — the requirements files the README names exist; the python version it states matches the newest `ENV_REPORT.md`; the install ladder it prints is the one that was actually used.
2. **Entry points** — each module the README invokes imports under the `.env` interpreter (`python -c "import <module>"`). An import failure is a major finding naming the missing dependency or path.
3. **Scripts** — every `execs/scpts/*.sh` and tool script the README prints exists, is executable, and its `--help` or first 20 lines confirm the flags the README shows.
4. **Configs** — every config path a printed command names exists at that path.
5. **Weights** — every checkpoint the Model Zoo links is either on disk under `inits/` or already published at the URL given. A link to neither is a blocker: a Model Zoo row for a file nobody can download is worse than no row.

Nothing is *executed* beyond imports and `--help`. Verifying that a training command trains is what the STOP line exists to prevent.

## 4. Assets & links

| Check | Severity |
|---|---|
| Every image the README references exists (`docs/srcs/…`, relative paths) | major |
| Every relative link resolves to a file in the repository | major |
| Every anchor link matches a heading in the file | minor |
| No link points into `wkdrs/`, `datas/`, `inits/`, or another git-ignored path | major — it resolves for the author and 404s for everyone else |
| `.gitignore` still covers `.env`, `datas/`, `inits/`, `wkdrs/` | blocker if not |
| No file over ~10 MB is tracked | major — name it and suggest a release asset or a download script |

## Reporting

Group findings by family, blockers first, each `<file>:<line> — <what> · fix: <how>`. Then the verdict line:

- **release-ready** — no blocker open. Say what remains as majors, and that they are the user's judgement.
- **blocked (n)** — n blockers open, each named. This is the verdict even when everything else passed.

The prepared publish commands go in the report under *Awaiting user*, never run here (`SKILL.md` Core Principle 6): the remote, the push, the tag, the release, the weight upload. Give the exact commands and say what each one makes irreversible.
