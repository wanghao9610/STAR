# Venue 档位表 —— 影响力分的发表分量

`references/refs_rubric_zh.md`"影响力分"一节里发表分量背后的查询表。查法是确定性的：取抓回记录的 venue 字段——转录下来的 `booktitle` 或 `journal`，没有就用检索记录的 venue 串——去掉花括号，忽略大小写，对下面各行匹配。缩写只按整词命中（`ACL` 不会命中 `NAACL`）；名称片段按子串命中，一行里任一片段命中即可——带缩写点的备选片段是给 DBLP 的 condensed 期刊形式准备的（`IEEE Trans. Pattern Anal. Mach. Intell.`）。先命中的档位生效；哪行都没命中而已正式发表 → 4；仅预印本 → 2。

表按 CS/AI 校准。换领域的项目改的是清单，绝不是规则——某个没列的 venue"明显该进某档"，正确做法是在这里加一行，而不是运行中临场破例。查表不掺判断。

## 档位 10 —— 旗舰

| 缩写 | 名称片段 |
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
| — | Nature *（整串精确相等——这样 `Robotics: Science and Systems` 和 Nature 子刊都不受波及）* |
| — | Science *（整串精确相等）* |

ACL 的片段故意取完整的 "Annual Meeting …" 短语：NAACL 与 EACL 的全称里同样含有 "Association for Computational Linguistics"。

## 档位 7 —— 二档

| 缩写 | 名称片段 |
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

## 档位 4 —— 其他正式发表

workshop、区域会议、清单之外的期刊：venue 哪行都对不上的记录都算这档。4 是正式发表的默认档；不需要匹配模式。

## 档位 2 —— 仅预印本

`@misc` 条目（arXiv-only，index 里标 ‡）。这个档位反映的是有没有经过评审，不是质量——标了 `new` 的预印本可能只是还没走完评审；行文怎么对待它，见 `refs_rubric_zh.md` 的旗标规则。
