#!/usr/bin/env python3
"""Gate a compression pass file by file, against the same text at a git ref.

    python3 tasks/prose-compression/verify_pass.py [--ref REF] [--anchors FILE] PATH [PATH ...]

Refuses a rewrite that changed anything a check pins rather than anything a
reader reads: frontmatter, heading text, fenced code, an override anchor line,
the opening-load block, or a literal check_consistency.sh greps byte-exactly.
Prints one line per file plus a corpus total, and exits 1 if any file failed.
"""
import re, subprocess, sys, os

FROZEN_LITERALS = [
    "stay out", "stays out", "不装载", "excerpt", "摘录",
    "accept that the result is written out", "接受结果被存成文件",
    "not loaded at runtime", "Match the user's language.",
    "Reusing an earlier load.", "复用上一次装载。",
    "Shared conventions.", "通用规约。",
    "grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'",
    "Sub-plans", "Revision History", "Plan-level finding", "方向性信号",
    "[TBD]", "【待定】", "model_trail:", "model_id",
    "in full before acting", "与读取本文件", "issue its read together",
]
# The opening-load block: pinned end to end by checks 19-21. Two spans, because
# the Invocation line sits between them and is free to compress.
LANG_LINE  = re.compile(r"^(Match the user's language\.|> 本文件是)")
LOAD_START = re.compile(r"^\*\*(Shared conventions\.|通用规约。)")
LOAD_END   = re.compile(r"^\*\*(Reusing an earlier load\.|复用上一次装载。)\*\*")


def at_ref(ref, path):
    r = subprocess.run(["git", "show", f"{ref}:{path}"], capture_output=True, text=True)
    return None if r.returncode else r.stdout


def frontmatter(lines):
    if not lines or lines[0] != "---":
        return []
    for i in range(1, len(lines)):
        if lines[i] == "---":
            return lines[: i + 1]
    return []


def headings(lines):
    out, fence = [], False
    for l in lines:
        if l.startswith("```"):
            fence = not fence
        elif not fence and re.match(r"^#{1,6} ", l):
            out.append(l)
    return out


def fenced(lines):
    out, fence = [], False
    for l in lines:
        if l.startswith("```"):
            fence = not fence
            out.append(l)
        elif fence:
            out.append(l)
    return out


def load_block(lines):
    """The language line, plus the shared-conventions load through the reuse paragraph."""
    out = [l for l in lines if LANG_LINE.match(l)]
    start = next((i for i, l in enumerate(lines) if LOAD_START.match(l)), None)
    if start is None:
        return out
    end = next((i for i, l in enumerate(lines) if i > start and LOAD_END.match(l)), None)
    return out + lines[start : (end + 1 if end is not None else start + 1)]


def prose_words(lines):
    """Words outside frontmatter and fenced code; CJK counted per character."""
    fence, fm, n = False, False, 0
    for i, l in enumerate(lines):
        if i == 0 and l == "---":
            fm = True
            continue
        if fm:
            if l == "---":
                fm = False
            continue
        if l.startswith("```"):
            fence = not fence
            continue
        if fence:
            continue
        cjk = len(re.findall(r"[一-鿿]", l))
        n += cjk + len([w for w in re.sub(r"[一-鿿]", " ", l).split() if w])
    return n


# Characters an editor substitutes for their ASCII originals without saying so.
# A file may already use any of them; what is refused is a rewrite introducing
# more than the old text had, which is how a literal string stops matching.
SMART = "“”‘’′″‐‑‒–−ﬁﬂ 　"


def smart_punct(old, new):
    out = []
    for ch in SMART:
        o, n = old.count(ch), new.count(ch)
        if n > o:
            out.append(f"introduced {n - o} more {ch!r} than the old text had "
                       f"(an editor substituted it for the ASCII original)")
    return out


def load_anchors(path):
    """rel-path -> set of source lines an override record anchors on."""
    anchors = {}
    if not path or not os.path.exists(path):
        return anchors
    for line in open(path, encoding="utf-8"):
        rel, _, rest = line.rstrip("\n").partition("\t")
        _, _, joined = rest.partition("\t")
        anchors.setdefault(rel, set()).update(t for t in joined.split("\t") if t)
    return anchors


def check(path, ref, anchors):
    old = at_ref(ref, path)
    if old is None:
        return None, [f"not at {ref}"]
    o, n = old.split("\n"), open(path, encoding="utf-8").read().split("\n")
    errs = []
    if frontmatter(o) != frontmatter(n):
        errs.append("frontmatter changed")
    if headings(o) != headings(n):
        errs.append("heading text or order changed")
    if fenced(o) != fenced(n):
        errs.append("fenced code changed")
    if load_block(o) != load_block(n):
        errs.append("opening-load block changed (checks 19-21)")
    errs += smart_punct(old, "\n".join(n))
    for lit in FROZEN_LITERALS:
        if lit in old and lit not in "\n".join(n):
            errs.append(f"dropped frozen literal: {lit!r}")
    rel = re.sub(r"^\.(claude|agents)/skills/", "", path)
    for a in anchors.get(rel, ()):
        if a not in n:
            errs.append(f"override anchor no longer present: {a[:70]!r}")
    if path.startswith("docs/mds/star-workflow/") and len(o) != len(n):
        errs.append(f"line count {len(o)} -> {len(n)}; the en/zh twins are line-aligned (check 17)")
    return (prose_words(o), prose_words(n)), errs


def main():
    args = sys.argv[1:]
    ref, anchors_file = "HEAD", None
    while args and args[0].startswith("--"):
        if args[0] == "--ref":
            ref = args[1]
        elif args[0] == "--anchors":
            anchors_file = args[1]
        args = args[2:]
    anchors = load_anchors(anchors_file)
    tot_o = tot_n = 0
    bad = 0
    for path in args:
        counts, errs = check(path, ref, anchors)
        if counts:
            tot_o += counts[0]
            tot_n += counts[1]
            pct = 100 * (counts[0] - counts[1]) / counts[0] if counts[0] else 0
            head = f"{counts[0]:6d} -> {counts[1]:6d}  {pct:5.1f}%  {path}"
        else:
            head = f"{'':>21}{path}"
        print(head + ("" if not errs else "  FAIL"))
        for e in errs:
            print(f"        {e}")
        bad += bool(errs)
    if tot_o:
        print(f"\ntotal  {tot_o} -> {tot_n} prose words  ({100*(tot_o-tot_n)/tot_o:.1f}% cut)  "
              f"{len(args)-bad}/{len(args)} files clean")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
