# Source Policy — bib 记录从哪来，以及允许改什么

`reference.bib` 里的每个字段都能追溯到本次运行抓回的一条记录。本文件规定记录可以来自哪里、按什么顺序取、怎样判定记录与论文匹配，以及之后允许做哪些改动（封闭清单）。第一次抓取前先读它。

## 唯一的硬规则

一个 bib 字段合法的唯一条件是：它出现在从下列来源之一机器抓回的记录里。绝不凭模型记忆写字段。绝不"修正"记录里写错的字段。绝不靠推断补齐缺失字段——年份不行，页码不行，出版社也不行。抓不到记录的论文**绝不成为一条条目**：它以一行注释写进文件末尾的 `%% Needs manual check` 块，细节记进 index 的待人工核对一节。90% 转录 + 10% 记忆的条目，就是一条编造的条目。

Google Scholar 不作为来源：它没有 API，自动查询会被 CAPTCHA 拦，而且它导出的 bibtex 本身就是机器生成的——经常缺页码、用缩写会议名、优先给预印本而不是正式发表版。人可以去读它；本 skill 绝不爬它。下面这些数据库正是生成 Scholar bibtex 的**源头**：抓得到，也更接近原始记录。

## 抓取优先顺序

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

每份抓回的原始内容在**使用之前**缓存到 `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>`。这份缓存既是审计线索，也是重跑的续跑点。

## 记录与论文的匹配判定

三项全对才算匹配：

- **标题** —— 忽略大小写与标点，含副标题；
- **第一作者姓氏**；
- **年份** —— ±1，用来吸收 arXiv 到正会的时间差。

对上一两项不算匹配——workshop 版、扩展版和综述之间标题高度相似是常态。有歧义 → 绝不猜：把候选连同 URL 列进 index 的待人工核对一节，并在 bib 的 `%% Needs manual check` 块里写下这篇。

## 标题的解析

`add` 允许只用标题指一篇论文，此时能拿来匹配的就只有标题本身。解析用上面的检索端点（DBLP 检索、Crossref `query.bibliographic`、Semantic Scholar 检索），并沿用匹配判定的归一化规则：忽略大小写与标点。恰好一篇论文的记录标题与输入相等——全标题相等，或与副标题冒号之前的主标题相等——才算解析成功。多篇各不相同的论文都对得上，或最佳命中只是近似 → 提问，一个直接问题列出每条候选的标题、会议、年份和 URL；哪儿都查不到 → 进 `%% Needs manual check` 块与 index 的待人工核对一节。解析成功的标题从此就是一篇普通论文：它的记录照走上面的抓取优先顺序、三项匹配判定和已发表优先规则。

## 已发表优先于预印本

只要存在正式发表版就用它；arXiv id 只有在抓回的记录本身就带着时才保留。arXiv-only 的工作是正当的，收录——在 index 里标 `preprint`（‡），类型用 `@misc`。

## Citekey

`<年份>_<方法>_<第一作者姓氏>` —— 例如 `2021_CLIP_Radford`、`2023_SAM_Kirillov`。

- **年份** —— 被引用的那条记录的年份（已发表记录胜出时，就是发表年）。
- **方法** —— 论文自己写的缩写（`CLIP`、`DETR`、`SAM`）。没有 → 从标题自拟一个紧凑的 CamelCase 名（`MaskDistill`），并在 index 里标为自拟（†）。
- **第一作者姓氏** —— ASCII，无变音符，无空格：`Müller` → `Mueller`，`van den Berg` → `vandenBerg`。
- 冲突 → 追加一个小写字母（`2021_CLIP_Radforda`）。key 在全文件唯一。

citekey 是你唯一"创作"的字段。

## 出处注释——`% src:`

每条条目正上方一行，写的是 index 出处表登记的同一份出处：

- 抓取来的记录：`% src: <记录 URL> (fetched YYYY-MM-DD)`——URL 与日期同该条目在 index 里那一行，逐字一致。
- 用户手工加的、没有抓取记录：`% src: user-supplied`。

URL 里的 `mailto` 参数写之前删掉：这个文件里的注释一个 `@` 都不能有。BibTeX 在条目之外照样扫描这个字符，会把 `%` 行里的 `@article` 读成一条新记录的开头，静默吞掉它下面那条条目——bib 解析得动、key 却不见了，故障最后以"未定义引用"的形式冒出来，离病因很远。要指条目类型就写"一条 article 型条目"，绝不写那个字面量。

注释属于条目，不属于它在文件里的位置：重新分类时两者一起移动；条目被复制出这个文件时——写作侧的 STAGE 就是逐字节合并它们——出处跟着一起到。

## 待人工核对块——`%% Needs manual check`

抓不到权威记录的论文写成这个块里的一行注释，不写成条目。块固定在文件最后，排在所有类别块之后：

```text
%% Needs manual check — 2 papers, no authoritative record as of 2026-08-05
% "Learning to Segment Everything with Less" — DBLP / Crossref / Semantic Scholar / arXiv 均无匹配记录；见 refs_index.md 第 6 节
% "Prompt Tuning for Dense Prediction" — 三条候选标题高度相似，无法判定；候选与 URL 见 refs_index.md 第 6 节
```

一行一篇：标题，加上试过什么、卡在哪。绝不写一条注释掉的条目——`%` 行里的 `@misc{` 正是上一节警告的那个字符。URL 同理不写进来；细节留在 index 的 §6，块里那行指过去。

论文后来抓到了记录，它就成为一条正式条目，那一行同时从块里删掉。

## 规范化——封闭清单

允许，且仅限于此：

- 把来源的 key 换成 citekey。
- 删噪音字段：`bibsource`、`biburl`、`timestamp`、`abstract`、`keywords`、只是重复 DOI 的 `url`、会议已能确定月份的 `month`。
- 给 BibTeX 会自动转小写的大写加花括号保护：`{CLIP}`、`{ImageNet}`、`{T}ransformer`。这改的是渲染，不是内容。
- 展开会议缩写，但**只能用抓回记录里已有的名称**：DBLP 的 `booktitle` 通常本来就写全 `IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR)`，照抄就是转录；凭空造一个记录里没有的全称不是。

不允许：补记录没有的页码、editors、publisher、volume、DOI 或年份；"修正"作者缩写或姓名顺序；把同一篇论文的两条记录的字段拼起来（只能选一条；index 里写明选的哪条）。

## 条目类型与字段

- `@inproceedings` —— 会议录：`author`、`title`、`booktitle`、`year`，记录里有就加 `pages` / `publisher`。
- `@article` —— 期刊：`author`、`title`、`journal`、`year`，记录里有就加 `volume` / `number` / `pages`。
- `@misc` —— arXiv-only：`author`、`title`、`year`、`eprint`、`archivePrefix`、`primaryClass`。
- `@book`、`@incollection` —— 按记录写。

AI 会议模板（NeurIPS / CVPR / ICML / ICLR / ACL）实际渲染的是 author、title、booktitle/journal、year、pages、volume、publisher。记录里有就留，其余不要凑。

## 影响力指标——评分的输入，绝不是 bib 字段

影响力分（`references/refs_rubric_zh.md`"影响力分"一节）由三类指标算出。它们一律不进 `reference.bib`；落在 index 里，带抓取日期。

- **引用数**搭上面已列的 Semantic Scholar 调用顺路取得——检索、`/references`、`/citations` 的字段清单里都有 `citationCount`，完整流程不多花一次请求。`score` 模式一次调用刷新全库：`POST https://api.semanticscholar.org/graph/v1/paper/batch?fields=citationCount,year,externalIds`，body 里最多 500 个 id（`{"ids": ["DOI:…", "ARXIV:…", …]}`），取自 index 已登记的出处。批量端点解析不了的条目保留旧值旧日期。
- **发表档位**离线：抓回记录的 venue 字段对 `references/venue_tiers_zh.md` 查表。
- **星标与最近提交** —— `https://api.github.com/repos/<owner>/<repo>` → `stargazers_count`、`pushed_at`。响应先缓存成 `<citekey>.github.json` 再用。无认证的 GitHub 限 **60 请求/小时**——这才是真正的约束，但仍比一次运行该用到的 ≤15 个仓库（核心论文、综述精读层）宽出数倍；照旧按 host 约 1 请求/秒串行。这里的 403/429 多半就**是**小时上限：退避一次，然后记录失败、把该分量标为未抓到——按评分表记残缺分，绝不循环重试，绝不凭记忆填数。

**只认官方仓库。** 仓库合格的唯一条件是论文自己的页面挂出它：arXiv abs 页、项目主页，或论文 PDF/HTML 本身。发现顺序：Step 3 本来就要读的论文页 → arXiv abs 页 → 该论文的 Hugging Face papers 页（`https://huggingface.co/papers/<arxiv-id>`）。Papers with Code 已于 2025 年 7 月关停——不要再抓它。从其他途径冒出来的仓库（代码搜索、引用它的仓库的 README）在 index 里记 `unofficial`，绝不计分。

## 配图——笔记带的那几张图

一篇笔记最多带三张图：论文自己用来展示笔记正文带不动的那些东西的图。是哪几张由 Step 3 看图注、看这篇论文的性质来定；这一节定的是它们只能从哪里来、拿到之后怎么处置。

- **只一个来源。** 论文的 arXiv HTML 渲染版 `https://arxiv.org/html/<arxiv-id>`——存在时 Step 3 本就会读的那个页面。arXiv 大致从 2024 年起才渲染，而且只渲染投稿 LaTeX 能转成功的，所以很多论文根本没有：这是笔记要写明的事实，不是去别处找的理由。这里不渲染 PDF，也绝不从项目主页、仓库 README、博客或搜索结果里取图。
- **抓下来是什么字节，存的就是什么字节。** 把选中的每张图的 `<img>`（相对页面自身 URL 解析）下载到 `metds/refs/figs/<缩写>_fig<N>.<扩展名>`——`<缩写>` 用笔记的，`<N>` 用论文的图编号，扩展名用文件自己的。绝不重编码、不裁剪、不缩放、不把两张拼成一张。这个文件本身就是那份缓存：不在 `raw/` 下再存一份。
- **出处跟着图走。** 每张图下那一行写图编号、原图注的第一句（原文照录）、图片 URL 和抓取日期——与 `% src:` 行同一条"出处紧贴着产物"的规矩。没有这一行的图就是一张来历不明的图：删掉，不解释。
- **图的说明同样要有出处。** 图下那几句只出自两处：图注全文，以及同一个抓下来的页面里按编号引用这张图的那些句子——把图变成文字在这里没有第三条路，两处都没说的标 `[unverified]`。说明写不出来的图就不放进笔记，而不是放一张读者读不懂的图。
- **留几张图就多几次 arXiv 请求。** 每张都紧接着选它的那个页面抓，遵守 arXiv 要求的约 3 秒 1 次；最多三次。下载失败就记一笔、笔记不带那张图照常发出——绝不滞在重试循环里，也绝不拿另一篇论文的图顶替。

## 限速与失败

- 按 host 串行：DBLP 与 Semantic Scholar 约 1 请求/秒，Crossref 约 3 请求/秒（带上 `mailto` 进它的 polite pool）。这份预算属于整个会话、按 host 算，不是每个 agent 各有一份（规约 §6.9）；分派出去的步骤要把它按份数分开，并把各自那份写成具体数字。
- Step 3 抓的论文页面——arXiv abs/HTML、ACL Anthology、CVF open access、项目主页——和抓普通网页用同一套礼貌默认值：约 1 请求/秒，其中 arXiv 约 3 秒 1 次（它自己这么要求）。Step 3 每篇论文只抓一页，所以只有这一步并行分派时，这份预算才真正构成限制。
- HTTP 429 / 503 → 指数退避（2s、4s、8s），最多重试 3 次，然后跳过并记录失败。被限流绝不构成"凭记忆补上"的理由。
- 某个来源返回空 → 记为"`<来源>` 未找到"——那是一次抓取结果，不是这篇论文不存在的证据。

## 收尾前的自查

1. `reference.bib` 里的每个 citekey 都在运行缓存里有原始内容，**且**在 `refs_index.md` 里有出处行，**且**条目正上方那行 `% src:` 与该行是同一个 URL、同一个日期。
2. 随机重抓 5 条；与文件逐字段 diff。有出入 → 把文件改成与来源一致，然后重查该条所在的整批。
3. `.env` 的 conda 环境里**已装** `bibtexparser` 时用它解析（绝不安装——那是 `/star-env-builder` 的活）；否则例行检查花括号配平与 key 唯一性。
4. 没有条目的必填字段为空；没有 key 出现两次。
5. `%% Needs manual check` 块里的论文没有一篇在文件里另有条目；块里没有任何一行含 `@`。
