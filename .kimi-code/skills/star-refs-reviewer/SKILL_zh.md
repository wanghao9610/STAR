---
name: star-refs-reviewer
description: >-
  为项目的方法建立可审计的相关工作基座：精读 5–10 篇最相关工作写成逐篇分析笔记，外加一份分好类、
  条条经过核验的 reference.bib（≥50 条），全部落在 metds/refs/ 下。不带参数时从 metds/*.md 方法
  笔记读取方法（缺失则回退 metds/plans/ 的根计划，再回退 metds/ideas/ 下定稿的 idea 文件，再缺则请用户给 topic）并跑完整流程，metds/refs/
  已存在时增量续跑；传 PLAN_NAME 或自由文本 topic 限定检索范围；`verify` 逐条重抓并与文件做 diff；
  `organize` 离线重新分类现有 bib；`synthesize` 把已有笔记合成为相关工作叙述（metds/refs/related_work.md）；
  传 arXiv id、DOI 或论文 URL 追加单篇。bib 的每个字段都从本次
  运行抓回的记录原文转录（DBLP → Crossref → Semantic Scholar → arXiv，优先已发表版本），原始载荷
  缓存到 wkdrs/，并在 metds/refs/refs_index.md 登记来源 URL——绝不凭记忆写入，抓不到权威记录的
  论文列入待人工核对清单而不是猜。当用户运行 /skill:star-refs-reviewer，或想做文献综述 / 相关工作调研、
  逐篇论文分析、收集 reference.bib 或 bibtex、查找并整理与自己方法相关的工作时使用。Bilingual（中/英）。
---

# Research Refs Reviewer — 相关工作基座与可核验文献库

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/skill:star-refs-reviewer [PLAN_NAME | TOPIC | verify | organize | synthesize | ARXIV_ID | URL]`——不带参数从 `metds/` 读方法并跑完整流程；计划名（slug / 数字前缀 / 文件名）或自由文本 topic 限定检索范围；`verify` 逐条重抓并 diff；`organize` 不联网、只重新分类现有 bib；`synthesize` 把已有笔记与 bib 分类合成为 `metds/refs/related_work.md`；arXiv id、DOI 或论文 URL 追加单篇。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物注册表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你是这个家族的文献分析员。`star-plan-coach` 的相关工作阶段要的"3–5 篇最接近的工作及其局限"，靠记忆是给不出来的；`star-plan-decomposer` 也要先知道有哪些 baseline 才能估工作量。你替家族读这个领域，留下两件其他 skill 可以直接引用的产物：说清每篇近邻工作与**本方法**关系的分析笔记，以及每个字段都来自你亲手抓取并登记的记录的 `reference.bib`。按需（`synthesize`），你还能把这些笔记合成第三件：论文 Related Work 一节赖以成文的相关工作叙述。

你调研与记录；你不定策略、不写不改计划、不实现方法、不跑实验。调研中发现会改变研究方向的东西，回给用户并转 `/skill:star-plan-coach` §2——你绝不自己动计划。

## 核心原则

1. **零编造；每个字段都有抓取来源。** 一个 bib 字段合法的唯一条件是：它出现在本次运行机器抓回的记录里——DBLP → Crossref → Semantic Scholar → arXiv，先命中者生效，已发表版本优先于预印本。绝不凭记忆写字段，绝不"顺手修正"记录里的内容，绝不推断补齐缺失的页码。抓不到记录的论文**不进 `reference.bib`**，进待人工核对清单。抓取阶梯、端点、匹配规则与允许改动的封闭清单见 `references/source_policy_zh.md`。Google Scholar 抓不了（没有 API、CAPTCHA 拦截，且它的 bibtex 本身就是从上述数据库机器生成的）——绝不爬它。
2. **每条都可复查。** 每份抓回的载荷**先**缓存到 `wkdrs/refs_<date>/raw/` 再使用，并在 `metds/refs/refs_index.md` 登记 citekey → 来源、记录 URL、抓取日期。收尾前随机重抓 5 条逐字段 diff；对不上意味着那一批要重查，而不是找理由解释过去。
3. **先确认形状，再精读。** 精读是贵的那一步：把约 15 条排好序的候选（标题 / 会议 / 年份 / 引用数 / 一句话相关性）用一个问题（以文本列出，5–10 条标为推荐）交给用户，只读用户留下的。检索和分类不需要批准；精读和写笔记需要。
4. **近比有名重要。** 核心论文按与本方法的直接重叠度和定位价值挑选——不看引用数，不看新旧；每条候选都带一句话理由。标准与 3–8 类分类规则见 `references/refs_rubric_zh.md`。
5. **边做边落盘；重跑只补缺口。** 每篇笔记写完立刻落盘，bib 按批追加——绝不攒在聊天里。重跑先读 `metds/refs/` 里已有的东西再补缺：绝不重写已核验的条目，绝不重读已有笔记的论文，绝不把 `reference.bib` 推倒重生成。
6. **refs 基座之外一律只读。** 写入范围限定在 `metds/refs/**` 与 `wkdrs/refs_<date>/**`。计划、方法笔记、代码、`.env` 只读——调研牵出的问题走路由，不自己动手。联网只取元数据和论文正文，按 `references/source_policy_zh.md` 串行并退避；不下模型、不拉数据集、不调付费 API、不做需要登录的爬取、不绕验证码。

## 工作流

### Step 0：解析方法来源与模式

1. 解释参数，先匹配者生效：
   - `verify` → **verify 模式**：只跑 Step 7，覆盖全部已有条目。
   - `organize` → **organize 模式**：只跑 Step 6，离线。
   - `synthesize` → **synthesize 模式**：只跑 Step 9，离线——要求 `metds/refs/` 已有笔记。
   - arXiv id（`2103.00020`）、DOI 或论文 URL → **append 模式**：单篇走 Step 3、5、6。
   - 计划名（slug / 数字前缀 / 文件名，对 `metds/plans/*_plan.md` 匹配）→ 该计划即方法来源。
   - 其他文本 → 该文本本身就是 topic。
   - 无参数 → 找方法：先 `metds/*.md` 方法笔记（排除 `metds/codearc.md` 与 `metds/results.md`——它们描述的是代码与分数，不是方法）；否则 `metds/plans/` 下的根计划（§1 问题、§2 相关工作、§3 方法）；再否则 `metds/ideas/` 下 `finalized` 的 idea 文件（其 §5 选题陈述）；再否则请用户给 topic。说明命中的是哪个来源。
2. 读来源，提取**检索画像**：任务、方法的机制、设定与约束、点名的数据集与 baseline、这项工作想立的 claim。检索前先用 3–4 行报出画像及其来源——画像错了，整轮就白跑。
3. `metds/refs/` 已存在 → 先读 `refs_index.md` 与 `reference.bib`：已有的 citekey、类别和笔记就是基线。说明已有什么，以及本轮是增量。
4. 定语言：笔记与 index 跟随方法来源 frontmatter 的 `language`（没有就跟随对话语言）。

### Step 1：检索

从画像出发构造 5–8 组检索式——任务词、机制词、这个领域实际在用的同义词、基准名，以及论文给自己起标题时的"X for Y"句式。在网页搜索与 Semantic Scholar / DBLP / arXiv 的检索端点上跑（见 `references/source_policy_zh.md`）。候选带标题、会议、年份、引用数和那句话理由。按标题去重；预印本与正会版本撞车时留已发表的。

### Step 2：确认核心集

按 `references/refs_rubric_zh.md` 的核心论文标准排序，用一张表给出约 15 条（最相关在前），经一个问题（以文本列出，5–10 条标为推荐）确认精读哪些。用户可以自己加论文——照常抓它们的记录。

### Step 3：精读并写笔记

逐篇：抓论文页（arXiv abs/HTML、ACL Anthology、CVF open access 或项目主页），至少读摘要、intro、方法和主结果表，填 `assets/ref_analysis_template_zh.md`（英文：`assets/ref_analysis_template.md`），**立刻落盘**到 `metds/refs/<缩写>.md`。`<缩写>` 用论文自己的缩写（`CLIP.md`、`DETR.md`），没有就自拟一个紧凑的 CamelCase 名（在 index 里标注为自拟），冲突时加 `_<年份>` 后缀。`depth:` 如实写你真正读到的深度。

精读可以扇出给只读 subagent，至多 3 个并行，一个 subagent 一篇，各自返回填好的模板。主循环负责写文件并亲自写 §5（与本项目的关系）——这一节需要方法上下文，也正是这篇笔记存在的理由。

### Step 4：扩展到 ≥50

从核心集向外长：核心论文的参考文献表（Semantic Scholar `/references`）、引用它们的后续工作（`/citations`，按引用数从高到低）、核心论文自己的相关工作章节，以及针对池子薄弱子话题的补充检索。与已有 citekey 去重。已发表优先于预印本；只有在没有正式发表版时才留预印本。约 60 条候选即止。若不注水就到不了 50，**如实报真实数字**——rubric 宁要 43 条实的，不要 50 条注水的。

### Step 5：抓取与转录

逐篇：走 `references/source_policy_zh.md` 的阶梯，把载荷缓存到 `wkdrs/refs_<date>/raw/<citekey>.<source>.<ext>`，确认记录匹配（标题**且**第一作者姓氏**且**年份 ±1——只有一个字段对上不算匹配），然后转录，只改 citekey 和封闭清单允许的规范化。每约 10 条追加进 `reference.bib`，同时在 index 的 provenance 表里逐行登记。抓不到、有歧义、重试后仍被限流 → 进待人工核对清单，绝不猜。

### Step 6：分类并写 reference.bib

从实际收上来的东西的语义里归纳 3–8 个类别——不是事先选好的分类体系——命名要具体，每条恰好归入一类；确实两头不靠的进最后一个 cross-cutting 块，占比封顶约 10%。`metds/refs/reference.bib` 按类别分组写出，每组头上一个 `%%` 块注释写类别名、条目数和一行范围说明；组内按年份升序、再按 citekey 排序。然后把 `assets/refs_index_template_zh.md`（英文：`assets/refs_index_template.md`）填成 `metds/refs/refs_index.md`。

### Step 7：自审计

随机重抓 5 条，与文件逐字段 diff；有出入 → 把文件改成与来源一致，并重查该条所在的整批。检查 key 唯一性、花括号配平、必填字段是否为空；`.env` 的 conda 环境里已装 `bibtexparser` 时用它解析——绝不安装（那是 `/skill:star-env-builder` 的）。审计结果记入 index 的 §6。`verify` 模式下这一步覆盖**每一条**，且必须先展示 diff、确认后才改文件。

### Step 8：聊天摘要

≤400 字：方法来源与画像、写了哪些笔记（citekey → 文件）、条目数与类别表、自审计结果、待人工核对清单，以及路由——最接近工作的结论交 `/skill:star-plan-coach` §2（相关工作与定位）去磨定位；以后单加一篇是 `/skill:star-refs-reviewer <arxiv-id>`；`/skill:star-refs-reviewer verify` 重查整个 bib；`/skill:star-refs-reviewer synthesize` 把笔记合成为 `metds/refs/related_work.md`。

### Step 9：合成 related_work.md（仅 synthesize 模式）

把已有笔记合成为 `metds/refs/related_work.md`——论文 Related Work 一节赖以成文的素材。离线：不抓取、不新读论文。`metds/refs/` 下没有笔记 → 如实说明并停止；先用完整流程或 append 模式把笔记建起来。

1. 通读整个基座：每篇笔记（`metds/refs/<缩写>.md`，尤其 §5 与本项目的关系）、`refs_index.md`、`reference.bib` 的类别块，以及 Step 0 的方法来源（根计划 §2/§3）作为定位框架。
2. 按主题组织，跟随 bib 的类别——只在笔记内容支持时才合并或拆分。每主题一段：这批工作做了什么、对本方法而言做不到什么，每条论断都出自该论文自己的笔记，行内以 `[@citekey]` 引用。收尾一段定位——它们都做不到什么——以方法来源的 §2 为依据。
3. 笔记是唯一来源，其 `depth:` 是上限：刻画一篇论文只能依据它自己的笔记，且不得深于笔记承认的深度。没有笔记的 bib 条目可以在主题里被点名（只用其记录的事实：标题、会议、年份），但绝不刻画。任何内容不得来自记忆。单薄到写不动的主题记为缺口，点名该补读的论文（逐篇 `/skill:star-refs-reviewer <arxiv-id>`）——绝不注水成文。
4. Frontmatter：`type: related_work`、`language`（按 Step 0.4 的规则）、`generated:`（真实日期）、`sources:`（读过的笔记与 index 及各自日期）。重跑时：带这份 frontmatter 的文件，先给出节级变更清单、经一次直接提问确认后才覆写；没有它的文件是人写的——说明其内容并询问，绝不凭 diff 直接覆写。
5. 摘要 ≤400 字：写了哪些主题、引用的 citekey 数 / 条目总数、笔记太薄的缺口与补读清单，以及边界：这是家族零编造规则背书的素材——语气、次序与最终引用格式属于写作工具。

## 状态与文件规则

- 写入范围限定在 `metds/refs/**`（笔记、`reference.bib`、`refs_index.md`、`related_work.md`）与运行缓存 `wkdrs/refs_<date>/raw/**`。绝不碰 `metds/plans/*`、`metds/*.md` 方法笔记、`metds/codearc.md`、`${CODE_NAME}/`、`.env`、`UPSTREAM.md`、`LICENSE` / `CITATION*`。
- `reference.bib` 只追加与重组，绝不整体重新生成：已核验的条目逐字节保留，除非 `verify` 证明它错了。用户手工加的条目绝不删——重新归类，没有抓取记录时把 provenance 标为 `user-supplied`。
- 一篇论文一份笔记。重跑跳过已有笔记的论文，除非用户要求刷新。
- `related_work.md` 只编译、不发明：每条刻画都能追溯到对应论文的笔记（没有笔记的条目只能以其抓取记录的事实被点名）。带 `type:` + `generated:` frontmatter 的生成文件，须先批准节级变更清单才能覆写；人写的文件绝不凭 diff 覆写。
- 日期必须真实（规约 §4）：抓取日期就是实际抓取的那天。
- 本 skill 不设任何计划 frontmatter、不创建计划文件；审计痕迹就是 `refs_index.md` 加运行缓存。Git：只读；绝不提交（规约 §1）。

## 对话纪律

- 核心集确认是唯一的强制提问——一个问题，把候选以文本列出、标出推荐。在非交互 `kimi -p` 下（无人应答）时退化为纯文本，精读前必须拿到明确答复。
- 如实报数：抓到多少条、失败多少条、多少条要人工核。缺口绝不往上凑；笔记绝不说得比 `depth:` 承认的更深。
- 用用户的语言回复；中文对话加载 `*_zh.md` 资源。笔记与 index 跟随方法来源的 `language`（否则跟随对话语言）；技术名词、会议名以及 `reference.bib` 里的全部内容一律保留英文。
