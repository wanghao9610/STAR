#!/usr/bin/env bash
# Prose-economy meter. Run before and after every compression commit; the two
# outputs are the evidence that the pass cut words without inventing sentences.
#   usage: bash tasks/prose-compression/measure.sh FILELIST [--per-file]
#          FILELIST = one repo-relative path per line
# Sentence unit: each line is split on [.!?] followed by whitespace; fragments
# under 2 words are dropped. YAML frontmatter and fenced code blocks are skipped,
# so a template's code does not dilute the prose numbers.
# bash 3.2 safe: no associative arrays, no mapfile, no process substitution needed.
set -uo pipefail
LIST="${1:?usage: measure.sh FILELIST [--per-file]}"
PER_FILE="${2:-}"
LENS="$(mktemp)"; PERF="$(mktemp)"

while IFS= read -r f; do
    [[ -n "${f}" ]] || continue
    awk -v OUT="${LENS}" -v PERF="${PERF}" '
      BEGIN { fm=0; fence=0 }
      NR==1 && $0=="---" { fm=1; next }
      fm==1 { if ($0=="---") fm=0; next }
      /^```/ { fence=!fence; next }
      fence { next }
      { em += gsub(/—/,"—")
        n=split($0, parts, /[.!?][ \t]+/)
        for (i=1;i<=n;i++) {
            c=split(parts[i], w, /[ \t]+/); k=0
            for (j=1;j<=c;j++) if (w[j]!="") k++
            if (k>=2) { s++; tot+=k; print k >> OUT }
        }
      }
      END { printf "%s\t%d\t%d\t%.1f\t%d\n", FILENAME, tot, em, (tot?em*1000/tot:0), s >> PERF }' "${f}"
done < "${LIST}"

if [[ "${PER_FILE}" == "--per-file" ]]; then
    printf 'file\twords\tem-dash\tem/1kw\tsentences\n'
    sort -t"$(printf '\t')" -k3,3rn "${PERF}"
    printf '\n'
fi

sort -n "${LENS}" > "${LENS}.s"
awk -v perf="${PERF}" '
  { l[NR]=$1; tot+=$1; if ($1>40) over++ }
  END {
    n=NR
    while ((getline line < perf) > 0) { split(line, a, "\t"); words+=a[2]; em+=a[3]; nfiles++ }
    printf "files      %d\n", nfiles
    printf "words      %d (prose only; frontmatter and fenced code excluded)\n", words
    printf "em-dashes  %d  = %.1f per 1000 words\n", em, (words?em*1000/words:0)
    printf "sentences  %d\n", n
    printf "mean       %.1f words\n", (n?tot/n:0)
    printf "p90        %d words\n", l[int(0.9*n)+1]
    printf "max        %d words\n", l[n]
    printf ">40 words  %d  (%.0f%%)\n", over, (n?100*over/n:0)
  }' "${LENS}.s"
rm -f "${LENS}" "${LENS}.s" "${PERF}"
