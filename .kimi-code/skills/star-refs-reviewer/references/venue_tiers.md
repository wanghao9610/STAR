# Venue Tiers — the venue component of the impact score

The lookup behind the venue component in `references/refs_rubric.md` (Impact score). Deterministic: take the fetched record's venue field — the transcribed `booktitle` or `journal`, else the search record's venue string — strip braces, and match it case-insensitively against the rows below. An abbreviation matches only as a whole word (`ACL` does not hit `NAACL`); a name fragment matches as a substring, and any one of a row's fragments is enough — the dotted alternatives are there because DBLP's condensed journal forms abbreviate (`IEEE Trans. Pattern Anal. Mach. Intell.`). First tier with a hit wins; no hit and published → 4; preprint-only → 2.

The lists are calibrated for CS/AI. A project in another field edits the lists, never the rule — and an unlisted venue that "obviously" deserves a tier gets a row added here, not an exception made mid-run. Judgment never enters a lookup.

## Tier 10 — flagship

| Abbrev | Name fragment(s) |
| --- | --- |
| CVPR | Computer Vision and Pattern Recognition |
| ICCV | International Conference on Computer Vision |
| ECCV | European Conference on Computer Vision |
| NeurIPS, NIPS | Neural Information Processing Systems |
| ICML | International Conference on Machine Learning |
| ICLR | International Conference on Learning Representations |
| ACL | Annual Meeting of the Association for Computational Linguistics |
| EMNLP | Empirical Methods in Natural Language Processing |
| TPAMI | Pattern Analysis and Machine Intelligence / Pattern Anal. Mach. Intell. |
| IJCV | International Journal of Computer Vision / Int. J. Comput. Vis. |
| JMLR | Journal of Machine Learning Research / J. Mach. Learn. Res. |
| TACL | Transactions of the Association for Computational Linguistics / Trans. Assoc. Comput. Linguistics |
| — | Nature *(exact — the whole venue string, so `Robotics: Science and Systems` and the Nature sub-journals stay untouched)* |
| — | Science *(exact)* |

ACL's fragment is the full "Annual Meeting …" phrase deliberately: NAACL's and EACL's full names also contain "Association for Computational Linguistics".

## Tier 7 — second tier

| Abbrev | Name fragment(s) |
| --- | --- |
| AAAI | AAAI Conference on Artificial Intelligence |
| IJCAI | International Joint Conference on Artificial Intelligence |
| NAACL | North American Chapter of the Association |
| EACL | European Chapter of the Association |
| COLING | International Conference on Computational Linguistics |
| WACV | Winter Conference on Applications of Computer Vision |
| BMVC | British Machine Vision Conference |
| — | ACM International Conference on Multimedia |
| KDD | Knowledge Discovery and Data Mining |
| AISTATS | Artificial Intelligence and Statistics |
| ICASSP | Acoustics, Speech and Signal Processing |
| ICRA | International Conference on Robotics and Automation |
| IROS | Intelligent Robots and Systems |
| CoRL | Conference on Robot Learning |
| RSS | Robotics: Science and Systems |
| TMLR | Transactions on Machine Learning Research |
| TIP | Transactions on Image Processing / Trans. Image Process. |
| TNNLS | Neural Networks and Learning Systems / Neural Networks Learn. Syst. |

## Tier 4 — every other published venue

Workshops, regional conferences, journals off the lists: any record whose venue no row matches. 4 is the published default; no patterns needed.

## Tier 2 — preprint-only

`@misc` entries (arXiv-only, ‡ in the index). The tier reflects vetting, not quality — a `new`-flagged preprint may simply not be through review yet; `refs_rubric.md`'s flag rule says how prose treats it.
