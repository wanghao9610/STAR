#!/usr/bin/env python3
"""Find every hard token a rewrite dropped out of a file entirely.

    python3 tasks/prose-compression/literal_census.py [--ref REF] PATH [PATH ...]

Word counts cannot see the failure this catches. A compression that removes a
restatement is safe only where the statement it defers to still exists in the
same file — and the seven trees do not all carry the same lines, so "the claim
survives in the rules section" can be true in the source and false in a tree
whose override collapses that section. The same applies within one file when two
passes each remove a copy of a rule, believing the other one stayed.

So this ignores prose and counts only tokens that cannot be paraphrased: code
spans, paths, section citations, and SCREAMING_CASE identifiers. A token whose
count falls to zero means the file no longer says that thing anywhere. Falling
from three to two is fine — that is what deduplication does; falling to nothing
is a claim leaving the document.
"""
import re
import subprocess
import sys

# A token is worth counting when paraphrase cannot express it.
PATTERNS = [
    re.compile(r"`[^`\n]+`"),                       # code spans: paths, flags, fields
    re.compile(r"§\d+(?:\.\d+)?"),                  # conventions / AGENTS citations
    re.compile(r"\b[A-Z][A-Z0-9_]{3,}\b"),          # CONDA_HOME, PYTHON_HOME, TBD
    re.compile(r"\b(?:star-[a-z-]+|[a-z]+/)+\b"),   # skill names and directory paths
]


def tokens(text):
    out = {}
    for pat in PATTERNS:
        for m in pat.finditer(text):
            t = m.group(0)
            out[t] = out.get(t, 0) + 1
    return out


def at_ref(ref, path):
    r = subprocess.run(["git", "show", f"{ref}:{path}"], capture_output=True, text=True)
    return None if r.returncode else r.stdout


def main():
    args = sys.argv[1:]
    ref = "HEAD"
    if args and args[0] == "--ref":
        ref, args = args[1], args[2:]
    dropped_total, checked = 0, 0
    for path in args:
        old = at_ref(ref, path)
        if old is None:
            continue
        checked += 1
        try:
            new = open(path, encoding="utf-8").read()
        except (OSError, UnicodeDecodeError):
            continue
        o, n = tokens(old), tokens(new)
        gone = sorted(t for t, c in o.items() if c and t not in n)
        if gone:
            dropped_total += len(gone)
            print(f"{path}")
            for t in gone:
                print(f"    gone entirely ({o[t]}x before): {t}")
    print(f"\n{checked} files compared against {ref}; "
          f"{dropped_total} tokens no longer appear anywhere in their file")
    return 1 if dropped_total else 0


if __name__ == "__main__":
    sys.exit(main())
