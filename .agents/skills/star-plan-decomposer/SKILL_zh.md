---
name: star-plan-decomposer
disable-model-invocation: true
description: >-
  把现有研究计划（由 star-plan-coach 编写，位于 metds/plans/）分解为具体、可执行的
  子计划。读取父计划，选择分解轴（里程碑 / 组件 / 声明→实验），然后为每个单元自动
  起草一份执行子计划——目标、依赖、任务拆解、交付物和完成标准——以分层数字前缀写入
  metds/plans/，并链接回父计划。支持任意分解深度。当用户调用
  $star-plan-decomposer，或想拆解/充实计划的具体执行细节，把计划的方法或里程碑变成
  可行动任务，或把一个计划分成多个子计划时使用。支持中英文双语。
---

# 研究计划分析——计划分解器

匹配用户使用的语言；中文对话加载 `*_zh.md` 资源。

调用方式：`$star-plan-decomposer PLAN_NAME`，其中 `PLAN_NAME` 是 slug（`open-vocab-det-seg`）、数字前缀（`0`）或文件名（`0_open-vocab-det-seg_plan.md`）。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你把一份**战略性**研究计划转化为**可执行**子计划。同级 skill `star-plan-coach` 产出策略（一份根计划：问题 → 相关工作 → 方法 → 实验 → 风险 → 里程碑）。本 skill 产出执行方案：把计划的具体实现拆成更小的子计划，每份都包含研究者能够实际运行和验证的步骤。

你负责**分解，不重新制定策略**。父计划已经承载思考——从中抽取执行细节；不要从头重新推导研究问题、novelty 或方法。

## 核心原则

1. **只分解，不重新制定策略。** 父计划是 *why* 和 *what* 的事实来源。你的职责是 *how*：子目标、有序步骤、依赖、交付物，以及证明各项完成的检查。若发现自己在质疑研究问题或方法，停下——那属于 `star-plan-coach`，不属于这里。
2. **先确认形状，再自动起草内容。** 依次确认两个决定，每次只确认一个并标出推荐项：**分解轴**，然后是**子计划列表**。有结构化用户输入时使用；否则问简洁纯文本问题。确认后，依据父计划自主起草每份子计划。真正的缺口标为 `[TBD]`；只有步骤缺少用户信息就无法决定时，才问一个针对性问题。不要重新询问父计划已经记录的细节。
3. **增量写入。** 每份子计划起草完立即写文件。宁可多写几次文件，也不要把结果只留在聊天中——聊天会结束，文件不会。
4. **每份子计划都可验证。** 子计划必须有具体、以动词表述的步骤、一个**完成标准**（能证明完成的测试 / metric / output），并按项目布局放置交付物（`datas/`、`inits/`、`code/`、`wkdrs/<run>`），否则不能算完成。这与项目的目标驱动执行和验证规则一致。
5. **双向可追溯。** 每份子计划点名其追溯的根计划章节或声明（`traces_to`）。父计划获得一个 `## Sub-plans` 索引和 `children:` frontmatter 列表。数字前缀供人类排序；frontmatter 的 `parent:` 字段是权威链接。
6. **依赖是一等信息，不能只写在正文。** 每份子计划都有 `depends_on:` frontmatter 列表——开始前必须完成的同级前缀。这是 executor 与 `star-plan-status` 用来回答“下一项可运行工作是什么”的机器可读顺序。保持为 **DAG**（无环），并与 `## Sub-plans` 索引顺序一致。

## 命名约定（摘要）

文件名为 `<prefix>_<slug>_plan.md`。**prefix 是十进制数字字符串；长度等于计划在树中的深度。**

- 分解前缀为 `P` 的计划时，子计划前缀是在 `P` 后**再追加一个数字**，即子节点的 0-based index：`0_` → `00_ 01_ 02_ …`；`00_` → `000_ 001_ …`；`3_` → `30_ 31_ …`。
- **Parent** = 去掉最后一位数字。**Level** = prefix 长度。每个节点最多 **10 个同级子节点**（index 0–9）。

完整规则、示例树和边界情况见 `references/naming_convention.md`。

## 工作流

### 步骤 0：解析目标计划

1. 解释 `PLAN_NAME`：按 slug、数字前缀或完整文件名与 `metds/plans/*_plan.md` 匹配。
2. 未提供参数或匹配有歧义时，列出可用计划（prefix + slug + 单行标题）并询问选择哪一份。
3. 完整读取解析出的计划。

### 步骤 1：评估就绪程度

检查根计划的 `finalized:`——这是策略计划可供消费的唯一信号（`star-plan-coach` 仅在六节均为 `done`/`skipped` 且通过评分规则后设置它，并在任何章节重新打开时清除）。未 finalized → 阅读其 `status` map 和正文，点名 `pending`/`in_progress` 或充满 `[TBD]` 的章节（尤其是 **method** 和 **milestones**），告诉用户分解会比较浅，并提供选择：*仍然分解（缺口在子计划中成为 `[TBD]`）* / *返回 `$star-plan-coach` 先完成父计划*。尊重选择。

若目标本身已有执行证据（`exec_runs` 非空或 `exec_status` 超出 `pending`），拆分前暂停：分解会把已执行 leaf 变成 internal node——其 `exec_status` / `exec_runs` 冻结为历史，`star-plan-status` 不再把它计作可执行 leaf，其 `wkdrs/` run 仍附着在 executor 不会再次访问的节点上。提供选择：*先用 `$star-plan-reviser <slug>` 把执行证据折叠进计划文本（推荐）* / *仍然分解*——若仍分解，起草 children 时应把已执行工作反映在其 §2 输入和 §3 步骤中，而不是重新规划。

### 步骤 2：选择分解轴

在一个问题中提出 2–3 个轴，并推荐第一个。详情和选择方法见 `references/decomposition_axes.md`。

| 轴 | 如何拆分计划 | 最适合 |
|----|--------------|--------|
| **Milestone / phase**（默认） | 根计划 §6 的时间线阶段 | 里程碑已清晰成形（通常如此） |
| **Component / module** | 方法的系统组成（根计划 §3） | 方法具有可清晰分离的模块 |
| **Claim → experiment** | 根计划 §4 中的每个声明/实验 | 贡献以实证为主、消融较多 |

允许混合分解，但必须明确确认。

### 步骤 3：提出子计划列表

依据所选轴起草 N 个单元。每个单元包含：简短标题、英文 `slug`、单行目标、追溯的根计划章节/声明，以及**依赖哪些同级计划**。以普通文本展示列表——包括依赖边和最终执行顺序——询问用户确认、编辑列表或调整粒度。

- **给数据单独一个 leaf。** 若根计划 §4 点名的数据集尚不存在于 `datas/`，则其中一个单元必须是 data-readiness leaf：§3 获取数据，§4 放到 `datas/<name>/`，§5 完成标准是完整性检查——manifest、文件数、checksum——绝不能只是“下载完成”。获取命令本身跨越 STOP line，因此 `star-plan-executor` 会交还用户而不自行运行。每个消费该数据集的 leaf 都 `depends_on` 此项。没有它，执行会停在无人负责的缺失输入上。
- **强制 N ≤ 10。** 若认为需要超过 10 个单元，不要追加第二位 index——应分组，或推荐两层拆分（现在拆成 ≤10 个，再递归处理较重项）。明确说明这一点。
- 按命名规则分配前缀：父前缀 + `0..N-1`。
- **从分解轴推导依赖**（`references/decomposition_axes.md`）：milestone/phase → 线性链（每项依赖前一项）；component/module → 小型 DAG（共享接口）；claim→experiment → 大多独立（通常都是 `[]`）。把每个单元的上游记为同级 prefix 的 `depends_on` 列表。保持无环。

### 步骤 4：起草每份子计划

按顺序处理每个单元：

1. 从 `assets/subplan_template.md`（中文对话：`assets/subplan_template_zh.md`）创建 `metds/plans/<prefix>_<slug>_plan.md`。`language` 必须匹配父计划，而不一定匹配聊天语言。
2. 填写 frontmatter：`prefix`、`parent`、`level`、`traces_to`、`depends_on`（步骤 3 的同级 prefix；独立时为 `[]`）、日期和各节 `status`。保持 `depends_on` 与 §2 正文同步。
3. 从父计划抽取具体细节，起草六个执行章节。父计划未规定某项执行决定时写 `[TBD]`（中文计划写 `【待定】`）；只有步骤确实缺少用户输入就无法写时，才问一个针对性问题。
4. 确保 §4 Deliverables 把输出放到正确项目目录（生成输出放 `wkdrs/<run>`，数据放 `datas/`，权重放 `inits/`），run 名能区分本任务；§5 写出具体完成标准。
5. 写完文件再进入下一个单元。

### 步骤 5：更新父计划索引

向父计划添加以下内容（缺失时创建章节）。按**拓扑（依赖）顺序**列出子计划，标注每项追溯内容和依赖，并明确写出最终执行顺序：

```markdown
## Sub-plans

Decomposed by <axis> on <date> via $star-plan-decomposer.
Execution order: 00 → 01 → 02 → 03  (or a DAG: 00 → {01, 02} → 03)

- `00_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: —)
- `01_<slug>_plan.md` — <one-line objective> (→ §<n>; depends on: 00)
```

同时在父计划 frontmatter 添加/合并 `children:` 列表。不要重写父计划已有正文章节——只允许编辑 `## Sub-plans` 索引与 `children:`。

### 步骤 6：提议递归分解

告诉用户，任何仍较粗的子计划都可用 `$star-plan-decomposer <that sub-plan's slug or prefix>` 继续分解，从而产生下一位深度前缀。询问是否现在处理其中某项。

**转交下游。** leaf 足够具体后，下一步用 `$star-plan-executor <leaf slug or prefix>` 执行一项——从执行顺序中的首项开始（`depends_on` 为空或均已 `done` 的 leaf）。若 `${CODE_NAME}/` 仍缺失或为空，先用 `$star-code-architect` 给计划一个代码落点。`$star-plan-status` 展示整棵树并推荐下一项。

### 步骤 7：评分规则检查

阅读 `references/subplan_rubric.md`（中文：`references/subplan_rubric_zh.md`），检查刚写的子计划。报告失败项（最多 5 个，按重要性排序），每项包含文件和具体修复方法，并询问是否修订。然后只提议一次提交本次运行写入的计划文件（状态与文件规则）。

## 状态与文件规则

- 子计划与父计划平铺在 `metds/plans/` 下。不要创建子目录；树结构编码在数字前缀中。
- 合法 `status` 值：`pending` / `in_progress` / `done` / `skipped`——与 coach 相同。
- 绝不修改父计划已有策略章节；只追加 `## Sub-plans` 索引和 `children:` frontmatter。
- 计划正文末尾可能有 append-only 的 `## Revision History`，由 `star-plan-executor`（用户确认的执行回同步）和 `star-plan-reviser` 写入。§1–§6 已反映其中条目——依据当前正文分解，并原样保留该章节。
- 不在 `metds/plans/` 外写计划文件。
- Git：运行结束时，只提议一次提交本次写入的子计划和更新后的父索引——`star-plan-decomposer: <parent slug> — <N> sub-plans`（约定 §1）。

## 对话纪律

- 仅当当前 Codex 界面提供结构化输入时使用；否则问简洁纯文本问题，一次一个决定。
- 子计划正文语言遵循**父计划**的 `language`；中文计划中的技术术语保留英文。
