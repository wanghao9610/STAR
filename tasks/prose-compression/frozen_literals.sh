#!/usr/bin/env bash
# Every string .github/scripts/check_consistency.sh matches BYTE-EXACTLY inside
# markdown — i.e. every string a prose edit can break with no error message that
# names the sentence. Run before and after any wording pass.
#   usage: bash tasks/prose-compression/frozen_literals.sh [path-to-check_consistency.sh]
# bash 3.2 safe (no associative arrays, no mapfile).
set -uo pipefail
CC="${1:-.github/scripts/check_consistency.sh}"

echo "### A. literal grep arguments (every grep whose pattern is fixed text, not a variable)"
perl -ne '
  next if /^\s*#/;
  my $ln = $.;
  while (/grep\s+(?:-[A-Za-z-]+\s+)*(?:--\s+)?(?:\x27([^\x27]*)\x27|"([^"]*)")/g) {
    my $lit = defined $1 ? $1 : $2;
    next if $lit =~ /^\$\{[A-Za-z_@#]/;      # variable, resolved elsewhere in this report
    next if $lit eq "" ;
    printf "  %s:%d  %s\n", $ARGV, $ln, $lit;
  }
' "$CC"

echo
echo "### B. named literals held in variables"
grep -nE '^[[:space:]]*(LOOKUP_LINE|lead|head|conv)=' "$CC" \
  | sed -E "s|^([0-9]+):[[:space:]]*|  ${CC}:\1  |"
grep -nE '^(CONV_EN|CONV_ZH|CONV_MAX_SECTION|LOAD_EXCERPT_MAX)=' "$CC" \
  | sed -E "s|^([0-9]+):|  ${CC}:\1  |" 

echo
echo "### C. alternation lists pinned inside awk split() — every branch is a literal"
grep -nE 'split\("[^"]+", *marks' "$CC" \
  | sed -E "s|^([0-9]+):.*split\(\"([^\"]*)\".*|  ${CC}:\1  \2|" 

echo
echo "### D. registry arrays (literal -> file that must still contain it)"
awk '/^(LITERAL_REGISTRY|RESTATED_REGISTRY|AGENTS_SECTIONS|CITATION_LABELS)=\(/{inr=1;next}
     inr && /^\)/{inr=0;next}
     inr && NF {gsub(/^[ \t]*"/,""); gsub(/"[ \t]*$/,""); printf "  %s:%d  %s\n", FILENAME, NR, $0}' "$CC"

echo
echo "### E. harness tool vocabulary — required present / banned outright, per tree (check 23)"
grep -nE '^check_vocab |^check_subagent_types ' "$CC" | sed -E "s|^([0-9]+):|  ${CC}:\1  |" 

echo
echo "### F. whole-line byte-identity pins (the text is free, the UNIFORMITY is not)"
cat <<'TXT'
  check_consistency.sh:1024-1028  the `^Match the user's language.` line must sort -u to ONE
                                  line over all 105 SKILL.md; the zh `> 本文件是 ...` blockquote
                                  likewise over all 105 SKILL_zh.md
  check_consistency.sh:1373-1377  the `^**Reusing an earlier load.**` line must sort -u to ONE
                                  line over all 105 SKILL.md; `^**复用上一次装载。**` over 105 SKILL_zh.md
  check_consistency.sh:1353       that same paragraph may carry NO bare §n (20d reads §n as a load claim)
  check_consistency.sh:1361-1367  it must sit between the `**Shared conventions.` line and the next `## `
  check_consistency.sh:834        docs/mds/star-workflow/X.md and X.zh-CN.md: identical LINE COUNT
TXT
