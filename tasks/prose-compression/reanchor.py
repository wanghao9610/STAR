#!/usr/bin/env python3
"""Carry a source rewrite into the six trees' override records.

    python3 tasks/prose-compression/reanchor.py [--ref REF] [--write]

An override record says "where .claude reads THIS, my tree reads THAT", anchored
on the source lines themselves, so compressing a source line strands the record
and the tree stops reproducing. Re-porting each stranded record by hand means
re-reading six trees per file; almost always it is unnecessary, because the tree's
wording differs from the source only in spans the rewrite never touched — a tool
name, a dispatch mechanism.

So: token-level three-way merge per record. base = the anchor as it read at REF,
ours = the same line after the rewrite, theirs = what the tree says instead. Where
the two edits fall in different parts of the line the merge is unambiguous and the
record is rewritten. Where they overlap, the tree genuinely rewords the words the
rewrite touched, and only a reader can say what the tree should now say — those
are listed for hand porting and their records left untouched.

Without --write nothing is modified; the report is the same either way.
"""
import difflib
import os
import re
import subprocess
import sys

TREES = ["agents", "cursor", "dsh", "kimi-code", "pi", "qwen"]
ROOT = os.getcwd()


def load_rules(tree):
    rules = []
    with open(f"{ROOT}/.github/scripts/port/{tree}.rules", encoding="utf-8") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line.startswith("#") or "\t" not in line:
                continue
            pat, _, rep = line.partition("\t")
            rules.append((pat, rep))
    return rules


def apply_rules(body, rules):
    for pat, rep in rules:
        body = re.sub(pat, rep.replace("\\", "\\\\"), body)
    return body


def load_overrides(tree):
    """[(rel, [anchor lines], [tree lines])] in file order, plus the header text."""
    path = f"{ROOT}/.github/scripts/port/{tree}.overrides"
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    header, recs, rel, i = [], [], None, 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("### "):
            rel = line[4:]
        elif line.startswith("--- "):
            n = int(line.split()[1])
            old = lines[i + 1 : i + 1 + n]
            i += 1 + n
            m = int(lines[i].split()[1])
            new = lines[i + 1 : i + 1 + m]
            i += m
            recs.append([rel, old, new])
        elif rel is None and line.startswith("#"):
            header.append(line)
        i += 1
    return header, recs


def at_ref(ref, path):
    r = subprocess.run(["git", "show", f"{ref}:{path}"], capture_output=True, text=True)
    return None if r.returncode else r.stdout


def physical(rel):
    """Where the source for a skill-relative path actually lives."""
    return os.path.relpath(os.path.realpath(f"{ROOT}/.claude/skills/{rel}"), ROOT)


TOKEN = re.compile(r"\s+")

# A tree may answer one source line with several lines — a paragraph plus a
# heading it renumbers. Tokenizing splits on whitespace, newlines included, so
# the break has to travel as a token of its own or the lines merge into one.
NL = "\x00NL\x00"


def tokens(s):
    return [t for t in TOKEN.split(s) if t]


def edits(base, side):
    """Non-equal opcodes as (start, end, replacement tokens) over base indices."""
    sm = difflib.SequenceMatcher(None, base, side, autojunk=False)
    return [(i1, i2, side[j1:j2]) for tag, i1, i2, j1, j2 in sm.get_opcodes() if tag != "equal"]


def merge3(base, ours, theirs):
    """Token-level three-way merge. Returns merged tokens, or None on conflict."""
    eo, et = edits(base, ours), edits(base, theirs)
    for o1, o2, _ in eo:
        for t1, t2, _ in et:
            # true overlap only: two edits that merely abut are both applied, in
            # order. An insertion (an empty range) conflicts only when it falls
            # strictly inside a span the other side replaced, where it has no
            # defined place to land.
            if o1 < t2 and t1 < o2:
                return None
    out, i = [], 0
    for start, end, repl in sorted(eo + et):
        if start < i:
            return None
        out.extend(base[i:start])
        out.extend(repl)
        i = end
    out.extend(base[i:])
    return out


def phrase_replay(base, ours, theirs):
    """Fallback when the token merge conflicts.

    A tree's difference is usually "where the source says X, say Y". If X still
    reads verbatim in the rewritten line — the rewrite worked around the span
    rather than through it — replaying it as a string substitution is exact even
    though the token ranges overlap. Anything ambiguous returns None.
    """
    b, v = tokens(base), tokens(theirs)
    out = ours
    for i1, i2, repl in edits(b, v):
        after = " ".join(repl)
        before = " ".join(b[i1:i2])
        if not before:
            # an insertion: place it after the run of tokens preceding it
            ctx = " ".join(b[max(0, i1 - 4) : i1])
            if not ctx or out.count(ctx) != 1:
                return None
            out = out.replace(ctx, f"{ctx} {after}", 1)
            continue
        if out.count(before) != 1:
            return None
        out = out.replace(before, after, 1).replace("  ", " ") if after else \
            out.replace(before, "", 1).replace("  ", " ").strip()
    return out


def harvest(ref, tree, rel, variant, cache):
    """Read the ported line straight off the tree, where a pass already wrote it.

    Some of this corpus was compressed by editing each tree by hand before the
    replay existed. Where that happened the tree file on disk already says what
    the record should now say: find the old variant in the tree's file at REF,
    and take whatever stands in its place today.
    """
    key = (tree, rel)
    if key not in cache:
        path = f"{ROOT}/.{tree}/skills/{rel}"
        old = at_ref(ref, f".{tree}/skills/{rel}")
        if old is None or os.path.islink(path) or not os.path.exists(path):
            cache[key] = None
        else:
            o = old.split("\n")
            n = open(path, encoding="utf-8").read().split("\n")
            cache[key] = (o, n, align(o, n))
    ctx = cache[key]
    if ctx is None:
        return None
    old_t, new_t, amap = ctx
    for i in range(len(old_t) - len(variant) + 1):
        if old_t[i : i + len(variant)] == variant:
            idx = [amap.get(i + k) for k in range(len(variant))]
            if any(x is None for x in idx):
                return None
            return [new_t[x] for x in idx]
    return None


def recover(anchor, variant, new_body, floor=0.80):
    """Re-anchor a record whose anchor text is nowhere in the old body.

    Matches each anchor line against the rewritten body by similarity and takes
    the best line above `floor`, requiring the matches to run in order and to be
    distinct. The variant then follows by the same replay as everywhere else.
    """
    if len(variant) == 1 and len(anchor) > 1:
        # A hard-wrapped paragraph the tree states as one line. The rewrite
        # re-wrapped it, so no line maps to a line — match the paragraph whole.
        want = " ".join(anchor)
        best, span = 0.0, None
        i = 0
        while i < len(new_body):
            if not new_body[i].strip():
                i += 1
                continue
            j = i
            while j < len(new_body) and new_body[j].strip():
                j += 1
            r = difflib.SequenceMatcher(None, want, " ".join(new_body[i:j]),
                                        autojunk=False).ratio()
            if r > best:
                best, span = r, (i, j)
            i = j
        if best < floor or span is None:
            return None
        picked = new_body[span[0] : span[1]]
        line = merge3(tokens(want), tokens(" ".join(picked)), tokens(variant[0]))
        line = " ".join(line) if line is not None else \
            phrase_replay(want, " ".join(picked), variant[0])
        return (picked, [line]) if line is not None else None

    picked, last = [], -1
    for a in anchor:
        best, best_i = 0.0, -1
        for i in range(last + 1, len(new_body)):
            r = difflib.SequenceMatcher(None, a, new_body[i], autojunk=False).ratio()
            if r > best:
                best, best_i = r, i
        if best < floor:
            return None
        picked.append(new_body[best_i])
        last = best_i
    if picked == anchor:
        return None
    if len(anchor) == len(variant):
        pairs = list(zip(anchor, variant, picked))
    elif len(anchor) == 1:
        pairs = [(anchor[0], f" {NL} ".join(variant), picked[0])]
    else:
        return None
    merged = []
    for base_l, var_l, new_l in pairs:
        m = merge3(tokens(base_l), tokens(new_l), tokens(var_l))
        line = " ".join(m) if m is not None else phrase_replay(base_l, new_l, var_l)
        if line is None:
            return None
        merged.append(line)
    return picked, "\n".join(merged).replace(f" {NL} ", "\n").split("\n")


def align(old_lines, new_lines):
    """old index -> new index, for lines a rewrite changed in place."""
    sm = difflib.SequenceMatcher(None, old_lines, new_lines, autojunk=False)
    m = {}
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            for k in range(i2 - i1):
                m[i1 + k] = j1 + k
        elif tag == "replace" and (i2 - i1) == (j2 - j1):
            for k in range(i2 - i1):
                m[i1 + k] = j1 + k
    return m


def main():
    args = sys.argv[1:]
    ref, write, emit = "HEAD", False, None
    while args:
        if args[0] == "--ref":
            ref = args[1]
            args = args[2:]
        elif args[0] == "--write":
            write = True
            args = args[1:]
        elif args[0] == "--emit-conflicts":
            emit = args[1]
            args = args[2:]
        else:
            sys.exit(f"unknown argument {args[0]}")

    totals = {"kept": 0, "merged": 0, "harvested": 0, "recovered": 0, "conflict": 0, "lost": 0}
    conflicts, worklist = [], []
    for tree in TREES:
        rules = load_rules(tree)
        header, recs = load_overrides(tree)
        bodies = {}
        for rel, _, _ in recs:
            if rel in bodies:
                continue
            phys = physical(rel)
            old_src, new_src = at_ref(ref, phys), open(phys, encoding="utf-8").read()
            if old_src is None:
                bodies[rel] = None
                continue
            old_b = apply_rules(old_src, rules).split("\n")
            new_b = apply_rules(new_src, rules).split("\n")
            bodies[rel] = (old_b, new_b, align(old_b, new_b))

        cursor_rel, cursor = None, 0
        trees_seen = {}
        out = []
        for rel, anchor, variant in recs:
            if rel != cursor_rel:
                cursor_rel, cursor = rel, 0
            ctx = bodies.get(rel)
            if ctx is None:
                out.append((rel, anchor, variant))
                totals["kept"] += 1
                continue
            old_b, new_b, amap = ctx
            # find this record's anchor in the old body, after the previous record
            at = -1
            for i in range(cursor, len(old_b) - len(anchor) + 1):
                if old_b[i : i + len(anchor)] == anchor:
                    at = i
                    break
            if at < 0:
                # The generator splices each record in as it applies them, so an
                # anchor can be text an earlier record produced and be invisible
                # in the unmodified body. Recover it by similarity instead.
                rec = recover(anchor, variant, new_b)
                if rec is not None:
                    out.append((rel, rec[0], rec[1]))
                    totals["recovered"] += 1
                    continue
                out.append((rel, anchor, variant))
                totals["lost"] += 1
                conflicts.append(f"  .{tree:<10} {rel}  (anchor not locatable)\n      {anchor[0][:110]}")
                continue
            cursor = at + len(anchor)
            new_idx = [amap.get(at + k) for k in range(len(anchor))]
            if any(x is None for x in new_idx):
                # the rewrite re-wrapped these lines, so no line maps one to one
                rec = recover(anchor, variant, new_b)
                if rec is not None:
                    out.append((rel, rec[0], rec[1]))
                    totals["recovered"] += 1
                    continue
                out.append((rel, anchor, variant))
                totals["lost"] += 1
                conflicts.append(f"  .{tree:<10} {rel}  (anchor not locatable)\n      {anchor[0][:110]}")
                continue
            new_anchor = [new_b[x] for x in new_idx]
            if new_anchor == anchor:
                out.append((rel, anchor, variant))
                totals["kept"] += 1
                continue
            # the rewrite changed the anchor; carry it into the tree's wording
            merged, ok = [], True
            if len(anchor) == len(variant):
                pairs = list(zip(anchor, variant, new_anchor))
            elif len(anchor) == 1:
                pairs = [(anchor[0], f" {NL} ".join(variant), new_anchor[0])]
            else:
                pairs, ok = [], False
            for base_l, var_l, new_l in pairs:
                m = merge3(tokens(base_l), tokens(new_l), tokens(var_l))
                line = " ".join(m) if m is not None else phrase_replay(base_l, new_l, var_l)
                if line is None:
                    ok = False
                    break
                merged.append(line)
            if not ok:
                # Third try: the tree file may already carry the ported line,
                # from a pass that edited the trees directly. Harvest it.
                harvested = harvest(ref, tree, rel, variant, trees_seen)
                if harvested is not None:
                    merged, ok = harvested, True
                    totals["harvested"] += 1
                    totals["merged"] -= 1
            if ok:
                new_variant = "\n".join(merged).replace(f" {NL} ", "\n").split("\n")
                out.append((rel, new_anchor, new_variant))
                totals["merged"] += 1
            else:
                out.append((rel, anchor, variant))
                totals["conflict"] += 1
                conflicts.append(f"  .{tree:<10} {rel}\n      {anchor[0][:120]}")
                worklist.append({"tree": tree, "file": rel, "was": anchor,
                                 "now": new_anchor, "tree_said": variant})

        if write:
            path = f"{ROOT}/.github/scripts/port/{tree}.overrides"
            with open(path, "w", encoding="utf-8") as fh:
                fh.write("\n".join(header) + "\n")
                for rel, anchor, variant in out:
                    fh.write(f"### {rel}\n--- {len(anchor)}\n")
                    fh.write("\n".join(anchor) + "\n")
                    fh.write(f"+++ {len(variant)}\n")
                    fh.write("\n".join(variant) + "\n")

    print(f"records  kept {totals['kept']}  re-anchored {totals['merged']}  "
          f"harvested {totals['harvested']}  recovered {totals['recovered']}  "
          f"conflict {totals['conflict']}  unfindable {totals['lost']}")
    if emit:
        import json
        with open(emit, "w", encoding="utf-8") as fh:
            json.dump(worklist, fh, ensure_ascii=False, indent=1)
        print(f"\nworklist for hand porting: {emit}  ({len(worklist)} records)")
    if conflicts:
        print("\nthe tree rewords the same words the rewrite touched — port these by hand:")
        print("\n".join(conflicts))
    return 0


if __name__ == "__main__":
    sys.exit(main())
