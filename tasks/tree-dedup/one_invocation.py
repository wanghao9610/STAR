#!/usr/bin/env python3
"""Collapse the three spellings of a skill invocation into the bare name.

    star-env-builder          the neutral tree
    /star-env-builder         Claude, Cursor, Pi, Qwen
    /skill:star-env-builder   DSH, Kimi Code

become `star-env-builder` everywhere under the skill trees. Run from the project
root, then `bash .github/scripts/port.sh --write`.

What it touches, and why each is a separate pass:

  the source        .claude/skills/**.md, through its symlinks — a file this tree
                    shares reaches its text through a link into the store, and
                    the store is where the authored copy physically lives.
  the manifests     SKILL.md / SKILL_zh.md in every tree. Frontmatter is not
                    generated: each harness tunes its own `description`, and
                    every description names the invocation, so port.sh would
                    never reach these.
  the rules         the `/star-` -> `star-` and `/star-` -> `/skill:star-` rows
                    go. Left in place they would re-prefix the next occurrence
                    someone writes, silently undoing this.
  the overrides     both sides of every record: an anchor is the source after
                    the rules ran, and the other side is that tree's own wording.

`/star-workflow` is a documentation path, not an invocation, and is left alone.
"""
import os
import re

SLASH = re.compile(r'/star-(?!workflow)')
TREES = "agents claude cursor dsh kimi-code pi qwen".split()


def retokenize(text):
    return SLASH.sub("star-", text.replace("/skill:star-", "star-"))


def main():
    files = hits = 0
    for root, _dirs, names in os.walk(".claude/skills"):
        for name in names:
            if not name.endswith(".md"):
                continue
            path = os.path.join(root, name)
            if os.path.islink(path):
                path = os.path.realpath(path)
            before = open(path, encoding="utf-8").read()
            after, n = SLASH.subn("star-", before)
            if n:
                open(path, "w", encoding="utf-8").write(after)
                files += 1
                hits += n
    print(f"source: {hits} occurrences rewritten in {files} files")

    manifests = 0
    for tree in TREES:
        for root, _dirs, names in os.walk(f".{tree}/skills"):
            for name in names:
                if name not in ("SKILL.md", "SKILL_zh.md"):
                    continue
                path = os.path.join(root, name)
                before = open(path, encoding="utf-8").read()
                after = retokenize(before)
                if after != before:
                    open(path, "w", encoding="utf-8").write(after)
                    manifests += 1
    print(f"manifests: {manifests} retokenized")

    for tree, rule in (("agents", "/star-(?!workflow)\tstar-"),
                       ("dsh", "/star-(?!workflow)\t/skill:star-"),
                       ("kimi-code", "/star-(?!workflow)\t/skill:star-")):
        path = f".github/scripts/port/{tree}.rules"
        lines = open(path, encoding="utf-8").read().split("\n")
        keep = [l for l in lines if l != rule]
        if len(keep) == len(lines):
            print(f"{tree}.rules: prefix rule already gone")
            continue
        open(path, "w", encoding="utf-8").write("\n".join(keep))
        print(f"{tree}.rules: dropped the prefix rule")

    for tree in TREES:
        path = f".github/scripts/port/{tree}.overrides"
        if not os.path.exists(path):
            continue
        before = open(path, encoding="utf-8").read()
        after = retokenize(before)
        if after != before:
            open(path, "w", encoding="utf-8").write(after)
        print(f"{tree}.overrides: retokenized")


if __name__ == "__main__":
    main()
