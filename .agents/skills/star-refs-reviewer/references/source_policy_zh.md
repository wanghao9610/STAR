# Source Policy — bib 记录从哪来，以及允许改什么

`reference.bib` 里的每个字段都能追溯到本次运行抓回的一条记录。本文件规定记录可以来自哪里、按什么顺序取、怎样判定记录与论文匹配，以及之后允许做哪些改动（封闭清单）。第一次抓取前先读它。

## 唯一的硬规则

一个 bib 字段合法的唯一条件是：它出现在下列来源之一机器抓回的记录里。绝不凭模型记忆写字段。绝不"修正"记录里写错的字段。绝不靠推断补齐缺失字段——年份不行，页码不行，出版社也不行。抓不到记录的论文**不进 `reference.bib`**，进 index 的待人工核对清单。90% 转录 + 10% 记忆的条目，就是一条编造的条目。

Google Scholar 不作为来源：它没有 API，自动查询会被 CAPTCHA 拦，而且它导出的 bibtex 本身就是机器生成的——经常缺页码、用缩写会议名、优先给预印本而不是正式发表版。人可以去读它；本 skill 绝不爬它。下面这些数据库正是 Scholar 的 bibtex 被生成出来的**源头**，既抓得到，又更接近原始记录。

## 抓取阶梯

逐篇论文，命中第一条匹配记录即停：

1. **DBLP** —— CS 会议的权威源。
   - 检索：`https://dblp.org/search/publ/api?q=<query>&format=json&h=10`
   - bibtex：`https://dblp.org/rec/<key>.bib?param=1`（condensed 形式；`param=0` 会给 crossref 风格条目——不要用）
   - 同一标题同时有 CoRR（arXiv）记录和会议/期刊记录时，取已发表的那条。
2. **Crossref** —— 有 DOI 背书；覆盖期刊与大量会议录。
   - `https://api.crossref.org/works/<doi>`，或 `https://api.crossref.org/works?query.bibliographic=<title>&rows=5`
   - 经内容协商取 bibtex：`curl -LH "Accept: application/x-bibtex" https://doi.org/<doi>`
3. **Semantic Scholar** —— 覆盖面、参考文献表和引用数最好用。用它的 `externalIds`（DOI、DBLP）**回跳**到来源 1–2，而不是把它当 bib 来源。
   - 检索：`https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&fields=title,year,venue,authors,externalIds,citationCount`
   - 参考文献：`https://api.semanticscholar.org/graph/v1/paper/<id>/references?fields=title,year,venue,externalIds,citationCount&limit=100`
   - 被引：同样形式换成 `/citations`
4. **arXiv** —— 只用于没有正式发表版的工作。
   - `http://export.arxiv.org/api/query?id_list=<id>`（Atom）
   - 转成 `@misc`，带 `eprint`、`archivePrefix = {arXiv}`、`primaryClass`、`year`

每份抓回的载荷在**使用之前**缓存到 `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>`。这份缓存既是审计痕迹，也是重跑的续跑点。

## 记录与论文的匹配判定

三项全对才算匹配：

- **标题** —— 忽略大小写与标点，含副标题；
- **第一作者姓氏**；
- **年份** —— ±1，用来吸收 arXiv 到正会的时间差。

对上一两项不算匹配——workshop 版、扩展版和综述之间标题高度相似是常态。有歧义 → 绝不猜：把候选连同 URL 列进待人工核对清单。

## 已发表优先于预印本

只要存在正式发表版就用它；arXiv id 只有在抓回的记录本身就带着时才保留。arXiv-only 的工作是正当的，收录——在 index 里标 `preprint`（‡），类型用 `@misc`。

## Citekey

`<年份>_<方法>_<第一作者姓氏>` —— 例如 `2021_CLIP_Radford`、`2023_SAM_Kirillov`。

- **年份** —— 被引用的那条记录的年份（已发表记录胜出时，就是发表年）。
- **方法** —— 论文自己写的缩写（`CLIP`、`DETR`、`SAM`）。没有 → 从标题自拟一个紧凑的 CamelCase 名（`MaskDistill`），并在 index 里标为自拟（†）。
- **第一作者姓氏** —— ASCII，无变音符，无空格：`Müller` → `Mueller`，`van den Berg` → `vandenBerg`。
- 冲突 → 追加一个小写字母（`2021_CLIP_Radforda`）。key 在全文件唯一。

citekey 是你唯一"创作"的字段。其余全部是转录。

## 规范化——封闭清单

允许，且仅限于此：

- 把来源的 key 换成 citekey。
- 删噪音字段：`bibsource`、`biburl`、`timestamp`、`abstract`、`keywords`、只是重复 DOI 的 `url`、会议已经确定时的 `month`。
- 给 BibTeX 会自动转小写的大写加花括号保护：`{CLIP}`、`{ImageNet}`、`{T}ransformer`。这改的是渲染，不是内容。
- 展开会议缩写，但**只能用抓回记录里已有的名称**：DBLP 的 `booktitle` 通常本来就写全 `IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR)`，照抄就是转录；凭空造一个记录里没有的全称不是。

不允许：补记录没有的页码、editors、publisher、volume、DOI 或年份；"修正"作者缩写或姓名顺序；把同一篇论文的两条记录的字段拼起来（只能选一条；index 里写明选的哪条）。

## 条目类型与字段

- `@inproceedings` —— 会议录：`author`、`title`、`booktitle`、`year`，记录里有就加 `pages` / `publisher`。
- `@article` —— 期刊：`author`、`title`、`journal`、`year`，记录里有就加 `volume` / `number` / `pages`。
- `@misc` —— arXiv-only：`author`、`title`、`year`、`eprint`、`archivePrefix`、`primaryClass`。
- `@book`、`@incollection` —— 按记录写。

AI 会议模板（NeurIPS / CVPR / ICML / ICLR / ACL）实际渲染的是 author、title、booktitle/journal、year、pages、volume、publisher。记录里有就留，其余不要凑。

## 限速与失败

- 按 host 串行：DBLP 与 Semantic Scholar 约 1 请求/秒，Crossref 约 3 请求/秒（带上 `mailto` 进它的 polite pool）。
- HTTP 429 / 503 → 指数退避（2s、4s、8s），最多重试 3 次，然后跳过并记录失败。被限流绝不构成"凭记忆补上"的理由。
- 某个来源返回空 → 记为"`<来源>` 未找到"——那是一次抓取结果，不是这篇论文不存在的证据。

## 收尾前的自审计

1. `reference.bib` 里的每个 citekey 都在运行缓存里有载荷，**且**在 `refs_index.md` 里有 provenance 行。
2. 随机重抓 5 条；与文件逐字段 diff。有出入 → 把文件改成与来源一致，然后重查该条所在的整批。
3. `.env` 的 conda 环境里**已装** `bibtexparser` 时用它解析（绝不安装——那是 `$star-env-builder` 的活）；否则机械检查花括号配平与 key 唯一性。
4. 没有条目的必填字段为空；没有 key 出现两次。
