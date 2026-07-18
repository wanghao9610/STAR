---
name: star-refs-reviewer
disable-model-invocation: true
description: >-
  为项目方法构建可审计的相关工作基础：深读 5–10 篇最接近论文并形成逐篇分析笔记，
  再生成一份分类的 reference.bib，其中包含 ≥50 条已验证记录，全部位于 metds/refs/。
  不带参数时从 metds/*.md 读取方法（依次回退到 metds/plans/ 下的根计划、
  metds/ideas/ 下 finalized 的 idea 文件、用户提供的主题）并执行完整流程；
  metds/refs/ 已存在时增量恢复；PLAN_NAME 或自由文本主题限定搜索；`verify` 重新获取
  每条记录并与文件比较；`organize` 离线重新分类现有 bib；`synthesize` 把现有笔记
  汇编成 metds/refs/ 下的 related-work 叙述；arXiv id、DOI 或论文 URL 追加一篇。
  每个 bib 字段都从本次运行获取的记录转录（DBLP → Crossref → Semantic Scholar →
  arXiv，优先已发表版本），缓存到 wkdrs/，并在 metds/refs/refs_index.md 记录来源
  URL——绝不凭记忆写入；无法获取记录的论文列入人工检查，不作猜测。当用户调用
  $star-refs-reviewer，或要求 Codex 做 literature review / related-work survey、
  逐篇论文分析、reference.bib 或 bibtex 集合，或查找并组织与其方法相关的工作时
  使用。支持中英文双语工作。
---

# 研究文献审查器

匹配用户使用的语言。中文对话加载 `*_zh.md` 资源；否则加载无后缀资源。

调用方式：`$star-refs-reviewer [PLAN_NAME | TOPIC | verify | organize | synthesize | ARXIV_ID | URL]` —— 不带参数时从 `metds/` 读取方法并执行完整流程；计划名（slug / 数字前缀 / 文件名）或自由文本主题限定搜索；`verify` 重新获取并比较所有现有记录；`organize` 在不访问网络的情况下重新分类现有 bib；`synthesize` 把现有笔记和 bib 分类汇编为 `metds/refs/related_work.md`；arXiv id、DOI 或论文 URL 追加该论文。

**共享约定。** 行动前阅读 `docs/mds/star-workflow/research-workflow-conventions.md`（中文：`research-workflow-conventions.zh-CN.md`）：§1 git、§2 STOP line、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话。这是所有 STAR skill 的共同基线；本文件规定此 skill 的专属规则，凡要求更严格之处以本文件为准。

## 角色

担任本系列 skill 的文献分析员。`$star-plan-coach` 不能依靠记忆完成 Related Work 阶段——“3–5 个最接近工作及其局限”；`$star-plan-decomposer` 在估算工作前需要知道有哪些 baseline。本 skill 阅读领域，并留下其他 skill 可以引用的两类工件：说明每篇接近论文与**本项目**方法关系的分析笔记，以及每个字段均来自本次运行所获取并记录之来源的 `reference.bib`。按需（`synthesize`）还会生成第三类工件：论文 Related Work 章节的写作基础。

只做调研和记录；不要制定策略、撰写或修订计划、实现方法或运行实验。调研中发现会改变研究方向的内容应交还用户并转到 `$star-plan-coach` §2——绝不在这里编辑计划。

## 核心原则

1. **零编造；每个字段都有获取来源。** bib 字段只有在本次运行机器获取的记录中出现才合法——DBLP → Crossref → Semantic Scholar → arXiv，首个匹配生效，已发表版本优先于 preprint。绝不凭记忆写字段，绝不“纠正”记录内容，绝不推断缺失页码范围。无法获取记录的论文**不能进入 `reference.bib`**；应进入 Needs-manual-check 列表。来源梯级、端点、匹配规则和允许编辑的封闭列表见 `references/source_policy.md`。Google Scholar 不可获取（无 API、受 CAPTCHA 限制，且其 bibtex 本身也是基于上述数据库机器生成）——绝不抓取。
2. **每条记录都可复查。** 每个获取的 payload 必须在使用**之前**缓存到 `wkdrs/refs_<date>/raw/`，并在 `metds/refs/refs_index.md` 记录 citekey → source、记录 URL、获取日期。完成前随机重新获取 5 条记录，逐字段 diff；出现不一致意味着重新检查该批次，不能用解释搪塞。
3. **先确认集合，再深读。** 阅读成本高：用一个直接问题向用户展示约 15 个排序候选（title / venue / year / citations / 一小句理由）——用户可以保留多个；标出推荐的 5–10 篇——只深读用户保留的内容。搜索和分类无需审批；阅读和写笔记需要审批。
4. **接近胜过著名。** core paper 按与本方法的直接重叠程度和定位价值选择——不按 citation count，也不按 recency；每个候选带一小句理由。门槛和 3–8 个类别的规则见 `references/refs_rubric.md`。
5. **边做边写；重复运行只填缺口。** 每篇笔记写完立即落盘；bib 记录逐批追加——绝不只留在聊天中。重复运行读取 `metds/refs/` 现有内容并补齐缺失项：绝不重写已验证记录，绝不重新阅读已有笔记的论文，绝不从头生成 `reference.bib`。
6. **refs 基础之外只读。** 写入仅限 `metds/refs/**` 与 `wkdrs/refs_<date>/**`。计划、方法笔记、代码和 `.env` 均只读——调研中发现的问题只转交，不应用。网络仅用于元数据和论文文本，按 `references/source_policy.md` 串行并退避；不下载模型或数据集、不调用付费 API、不做认证抓取、不绕过 CAPTCHA。

## 工作流

### 步骤 0：解析方法来源与模式

1. 解释参数，按以下顺序首个匹配项生效：
   - `verify` → **verify 模式**：只执行步骤 7，覆盖每条现有记录。
   - `organize` → **organize 模式**：只离线执行步骤 6。
   - `synthesize` → **synthesize 模式**：只离线执行步骤 9——要求 `metds/refs/` 下已有笔记。
   - arXiv id（`2103.00020`）、DOI 或论文 URL → **append 模式**：让这一篇论文经过步骤 3、5、6。
   - 计划名（以 slug / 数字前缀 / 文件名匹配 `metds/plans/*_plan.md`）→ 该计划是方法来源。
   - 其他任何文本 → 文本本身是主题。
   - 无参数 → 查找方法：首先是 `metds/*.md` 方法笔记（排除 `metds/codearc.md` 和 `metds/results.md`——它们描述代码和分数，不是方法）；否则是 `metds/plans/` 下的根计划（§1 Problem、§2 Related Work、§3 Method）；否则是 `metds/ideas/` 下 `finalized` 的 idea 文件（其 §5 Topic Statement）；否则询问用户主题。说明最终采用的来源。
2. 阅读来源并提取**搜索画像**：任务、方法机制、setting 与约束、点名的数据集和 baseline，以及工作希望提出的 claim。搜索前用 3–4 行说明画像及来源——错误画像会浪费整次运行。
3. 若 `metds/refs/` 已存在，先读 `refs_index.md` 和 `reference.bib`：现有 citekey、类别和笔记是基线。说明已有内容以及本次为增量运行。
4. 确定语言：来源含 frontmatter `language` 时，笔记和 index 遵循该语言；否则遵循对话语言。

### 步骤 1：搜索

从画像构建 5–8 个 query——任务术语、机制术语、领域实际使用的同义词、benchmark 名称，以及论文标题常用的“X for Y”表述。通过 web search 和 Semantic Scholar / DBLP / arXiv 搜索端点运行（`references/source_policy.md`）。收集 title、venue、year、citation count 和一小句理由。按 title 去重；preprint 与 proceedings 版本冲突时保留已发表记录。

### 步骤 2：确认 core set

按 `references/refs_rubric.md` 的 core-paper 标准排序候选，以一个表格展示约 15 篇，最相关在前。只问一个直接问题：深读哪些论文（用户可保留多个）；标出推荐的 5–10 篇。用户可添加自己的论文——像其他论文一样获取记录。

### 步骤 3：阅读并写笔记

对每篇确认论文：获取论文页面（arXiv abs/HTML、ACL Anthology、CVF open access 或 project page），至少阅读 abstract、intro、method 和主 results table，填写 `assets/ref_analysis_template.md`（中文：`assets/ref_analysis_template_zh.md`），并**立即写入** `metds/refs/<ABBREV>.md`。`ABBREV` 使用论文自己的缩写（`CLIP.md`、`DETR.md`）；没有时创建 CamelCase handle（在 index 标为 coined）；冲突时追加 `_<year>`。诚实设置实际阅读深度 `depth:`。

默认在本地阅读；仅当多篇确认论文可相互独立且只读地处理时选择性委派——每篇交给一个受委派者，返回填好的模板。文件由主 agent 写入；主 agent 还负责 §5 Relation to This Project——该节需要方法上下文，也是笔记存在的原因。

### 步骤 4：扩展到 ≥50

从 core set 向外扩展：core paper 的参考文献列表（Semantic Scholar `/references`）、引用它们的工作（`/citations`，按引用数从高到低）、core paper 自身 related-work 章节，以及填补薄弱子主题的 query。与现有 citekey 去重。已发表工作优先于 preprint；仅在无已发表版本时保留 preprint。约 60 个候选时停止。若不填充凑数就无法达到 50，**报告真实数量**——评分规则宁可要 43 条诚实记录，也不要 50 条填充记录。

### 步骤 5：获取与转录

对每篇论文：沿 `references/source_policy.md` 的梯级获取，把 payload 缓存到 `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>`，确认记录匹配（title **以及** first-author surname **以及** year ±1——只匹配一个字段不算），然后转录，只修改 citekey 和封闭列表中允许的 normalization。每约 10 条为一批追加到 `reference.bib`，并同步在 index 写 provenance 行。未找到、有歧义或退避重试后仍受 rate limit → Needs-manual-check，绝不猜测。

### 步骤 6：分类并写 reference.bib

依据实际收集内容的语义派生 3–8 个类别——不能预先选 taxonomy——名称要具体，每条记录只归入一个类别；真正不合群的内容放入最后一个 cross-cutting 块，最多约 10%。把 `metds/refs/reference.bib` 按类别分组；每组以 `%%` block comment 开头，包含类别名、条目数和单行范围；组内按 year 升序，再按 citekey 排序。然后用 `assets/refs_index_template.md`（中文：`assets/refs_index_template_zh.md`）填写 `metds/refs/refs_index.md`。

### 步骤 7：自审计

随机重新获取 5 条记录，逐字段与文件 diff；任何不一致 → 修改文件以匹配来源，再重新检查该记录所在整批。检查 key 唯一性、brace 平衡和 required field 是否为空；若 `.env` conda 环境已经安装 `bibtexparser`，通过它解析——绝不安装（这是 `$star-env-builder` 的职责）。在 index §6 记录审计。`verify` 模式下，此步骤覆盖**每条**记录，且只有展示并确认 diff 后才修改文件。

### 步骤 8：在聊天中给出摘要

约 400 词以内：方法来源与画像、已写笔记（citekey → 文件）、条目数与类别表、自审计结果、Needs-manual-check 列表，以及转交方向——closest-works 发现交给 `$star-plan-coach` §2（Related Work & Positioning）以收紧定位；以后追加一篇使用 `$star-refs-reviewer <arxiv-id>`；`$star-refs-reviewer verify` 复查整个 bib；`$star-refs-reviewer synthesize` 把笔记汇编成 `metds/refs/related_work.md`。

### 步骤 9：汇编 related_work.md（仅 synthesize 模式）

把现有笔记汇编为 `metds/refs/related_work.md`——论文 Related Work 章节的写作材料。离线：不获取、不新读。`metds/refs/` 下没有笔记 → 说明并停止；完整流程或 append 模式先生成笔记。

1. 阅读整个基础：每篇笔记（`metds/refs/<ABBREV>.md`，尤其是其 §5 Relation to This Project）、`refs_index.md`、`reference.bib` 的类别块，以及步骤 0 的方法来源（根计划 §2/§3）来取得定位框架。
2. 按主题组织，遵循 bib 类别——只有笔记支持时才合并或拆分。每个主题一段：这些工作做了什么、无法为本方法做什么，每条声明都来自相应论文自己的笔记，citekey 以内联 `[@citekey]` 引用。最后用定位段收束——它们全都没有做什么——依据方法来源 §2。
3. 笔记是来源，其 `depth:` 是上限：只能根据论文自己的笔记描述它，不能超过笔记承认的深度。没有笔记的 bib 记录可以依据记录事实（title、venue、year）在主题中点名，绝不能刻画。过于单薄、无法撰写的主题变成 gap，点名接下来要读的论文（逐篇用 `$star-refs-reviewer <arxiv-id>`）——绝不填充 prose。
4. Frontmatter：`type: related_work`、`language`（步骤 0.4 规则）、`generated:`（真实日期）、`sources:`（读取的笔记和 index，各带日期）。重复运行时，带这些 frontmatter 的文件必须先展示章节级变更列表，只问一个直接问题，获批后才能覆盖；没有这些字段的文件是手写内容——说明其中内容并询问，绝不能只凭 diff 覆盖。
5. 摘要 ≤400 词：已写主题、已引用 citekey 数与总条目数、薄弱笔记 gap 及 read-next 列表，以及边界：材料按本系列 zero-fabrication 规则汇编——voice、ordering 和最终 citation style 属于写作工具。

## 状态规则

- 写入仅限 `metds/refs/**`（笔记、`reference.bib`、`refs_index.md`、`related_work.md`）和 run 缓存 `wkdrs/refs_<date>/raw/**`。绝不触碰 `metds/plans/*`、`metds/*.md` 方法笔记、`metds/codearc.md`、`${CODE_NAME}/`、`.env`、`UPSTREAM.md` 或 `LICENSE` / `CITATION*`。
- `reference.bib` 只可追加和重组，绝不从头重新生成：已验证记录逐字节保留，除非 `verify` 证明它错误。绝不删除用户手工添加的记录——可重新分类；没有获取记录时把 provenance 标为 `user-supplied`。
- 每篇论文一份笔记。重复运行跳过已有笔记的论文，除非用户要求刷新。
- `related_work.md` 只汇编，绝不发明：每项刻画都追溯到对应论文笔记（无笔记记录只能依据获取记录的事实点名）。生成文件（含 `type:` + `generated:` frontmatter）只有在章节级变更列表获批后才能覆盖；手写文件绝不只凭 diff 覆盖。
- 只用真实日期（约定 §4）：fetch date 就是实际获取日期。
- 本 skill 不设置计划 frontmatter，也不创建计划文件；审计轨迹是 `refs_index.md` 加 run 缓存。Git：只读；从不提交（约定 §1）。
- core-set 确认必须用一个带推荐标记的直接问题，并要求任何论文被阅读前都得到明确答复——即使在 headless 或 scripted 运行中也如此。绝不把笔记描述得比其 `depth:` 更深。笔记和 index 遵循方法来源的 `language`（否则遵循对话语言）；`reference.bib` 内部始终使用英文。
