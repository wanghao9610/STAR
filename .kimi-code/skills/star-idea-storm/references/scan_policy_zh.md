# 扫描策略——领域证据从哪里来、读到多深

这是文献库来源策略的轻量同胞：那份策略为已定的方法构建可核验的 `reference.bib`；本策略只为 2–4 个候选方向回答"多拥挤、谁最近、gap 在哪"，深度到摘要为止，每方向几分钟。它不产出 bibtex、不写逐篇笔记、不向 `metds/refs/**` 写任何东西——选题定下后，由深度调研（`star-refs-reviewer`）在胜出方向上把那些建起来，起点就是这些扫描表。

## 硬规则（继承自家族）

对话或 idea 文件中出现的每篇论文都转录自本次运行抓取的记录——标题、venue、年份、引用数取自记录，记录 URL 登记在行旁。记忆可以提议查询词和同义词；只有抓到的记录才能进文件。绝不"修正"记录写的内容，绝不补记录里没有的字段。搜索找不到的论文只证明一件事：没找到——要紧就照实说，绝不把凭记忆想起的论文当作扫描到的来转述。不做需登录的抓取，不绕过 CAPTCHA。Google Scholar 不是来源（无 API、CAPTCHA 拦截）；下面这些端点本来就是它索引的对象。

## 来源——要广度，不走阶梯

与文献库"首个命中即止"的阶梯不同，扫描需要分歧：每个方向至少跑两个来源——只用一个索引估出的拥挤度，是那个索引的伪影。

1. **Semantic Scholar 搜索**——拥挤度与引用信号的主来源：
   - `https://api.semanticscholar.org/graph/v1/paper/search?query=<q>&fields=title,year,venue,abstract,citationCount,externalIds&limit=20`
   - 加 `&year=<from>-` 做时效探针（例如近 18 个月）。
2. **arXiv API**——走势与最新工作的主来源：
   - `http://export.arxiv.org/api/query?search_query=all:<terms>&sortBy=submittedDate&sortOrder=descending&max_results=20`（Atom）
3. **DBLP 搜索**——为前两者浮出的结果确认 venue：
   - `https://dblp.org/search/publ/api?q=<query>&format=json&h=20`
4. **网页搜索**——综述、workshop 页面、点出领域行话的博客。网页结果提到的论文仍须经来源 1–3 的记录才能进文件；有用的非论文页面（综述博客、榜单）可在拥挤度注记中带 URL 引用，标注 `web context`。

## 查询词

每方向 2–3 个：任务说法、机制说法、论文标题惯用的"X for Y"说法——外加一个时效探针（近 18 个月的投稿）读走势。从第一轮结果里偷词来磨第二轮——领域自己的词比你的词好搜。

## 每方向记录什么

- **扫描表**——8–15 篇，按标题去重（preprint 与正式版同时浮出时留正式版记录）：标题 / venue / 年份 / 引用数 / 一小句相关性 / 记录 URL。
- **拥挤度注记**——逐年数量走势、涉及的 venue、看得出的团队、有无约 18 个月内的综述、可见的 benchmark 饱和迹象。此处允许 web context 链接，照此标注。
- **3 篇 closest works**——每篇一行：它做了什么，以及它自己的摘要**没有**声称什么。
- **表面 gap**——写成"扫描到的工作都没做什么"。摘要深度下，诚实的动词是"摘要显示……"。
- **深度行**——`abstracts`、`abstracts+intros` 或 `skipped`。

## 深度——默认浅，触发才加深

默认只读标题 + 摘要。仅在 (a) 用户点名某方向，或 (b) 某条 gap 判断直接决定决赛方向去留时加深。加深的含义：该方向 top-3 closest works 的 intro 与 related work 首段，从论文自己的页面读（arXiv abs/HTML、ACL Anthology、CVF open access 或项目页）——然后在该方向的深度行记 `abstracts+intros`。绝不悄悄加深，绝不声称比深度行更深的阅读。

## 缓存、限速与失败

- 每个抓取载荷**先**缓存到 `wkdrs/ideas_<date>/raw/<direction-slug>.<source>.<ext>` 再使用——缓存即审计线索与续跑起点。
- 按主机串行：Semantic Scholar 与 DBLP 约 1 请求/秒；arXiv 约 3 秒 1 请求。HTTP 429 / 503 → 指数退避（2s、4s、8s），至多重试 3 次，然后记录失败并继续。限速绝不是改用记忆填坑的理由。
- 某方向的搜索全部失败时，报告为"扫描失败：<主机与错误>"——绝不填充，绝不悄悄降级为回忆。
