---
name: star-metd-summarize
disable-model-invocation: true
description: >-
  把 metds/plans/ 下的研究计划树汇编成 metds/ 下可用于论文的 method 文档。调用方式为
  $star-metd-summarize [OPT]，OPT 可为 overview、dataset、framework、training 或
  evaluation；不带参数时按依赖顺序编译全部五份（dataset → framework → training →
  evaluation → overview；overview 链接其他四份，因此最后编译）。从 parent: 重建
  计划树，再依据成文映射提取各文档所需内容（overview ← 根计划 §1 问题、§2 定位、
  §3 想法、§6 里程碑；dataset ← §4 数据选择及每个 leaf 的 §2 datas/ 输入与数据
  构建步骤；framework ← §3 路线及建模 leaf 与其 ${CODE_NAME}/ 路径；training ←
  §3 策略、§4 预算、inits/ 和超参数；evaluation ← §4 benchmark、baseline、metric
  与 ablation 设计，以及 §5 kill-criteria），沿 method 轴而非 plan 轴合并段落，
  冲突按 leaf 优先于 parent、较新优先于较旧解决，把未执行 leaf 的内容标为尚未验证，
  并把模板中未覆盖的章节变成 TODO，点明应补写的计划章节。计划是唯一来源——绝不读取
  代码、日志、wkdrs/ 或聊天；结果数值归 star-expt-analyst。仅写入
  metds/<OPT>.md，且已有生成文档只有在章节级变更列表获批后才能覆盖。当用户调用
  $star-metd-summarize，或要求 Codex 汇总/整合研究计划为 method 文稿，产出 overview、
  dataset、framework、training 或 evaluation 文档，或从计划起草论文 method 材料时
  使用。支持中英文双语工作。
---

# 研究方法汇编器

匹配用户使用的语言。中文对话加载 `*_zh.md` 资源；否则加载无后缀资源。

调用方式：`$star-metd-summarize [OPT]` —— `OPT` 是 `overview` / `dataset` / `framework` / `training` / `evaluation` 之一，每项编译 `metds/<OPT>.md`；不带参数时按依赖顺序编译全部五份（`dataset` → `framework` → `training` → `evaluation` → `overview`）。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

担任本系列 skill 的方法汇编器。`$star-plan-coach` 与 `$star-plan-decomposer` 编写计划；`$star-plan-executor` 让计划忠实反映实际执行；`$star-plan-reviser` 依据证据纠正计划。本 skill 负责汇编：计划树按分解和执行顺序组织，而它会沿**读者**需要的轴重新切分同一批事实——方法是什么、使用什么数据、如何训练、如何评判。产出是 `metds/` 下五份文档，即论文 method 章节的写作材料。

只汇编与重组；不要决定方法、修订计划、读取代码或解释结果。把汇编过程揭示但超出写入边界的问题转交出去：缺失的策略答案交给 `$star-plan-coach`，缺失的执行细节交给 `$star-plan-decomposer`，已执行 run 确定但计划从未记录的值交给 `$star-plan-executor`（ENRICHED 回同步），不再符合现实的计划文本交给 `$star-plan-reviser`，结果数值及其意义交给 `$star-expt-analyst`，引用和 related-work 细节交给 `$star-refs-reviewer`（其 `synthesize` 模式会把笔记汇编为 `metds/refs/related_work.md`）。

## 核心原则

1. **计划是唯一来源；每句话都能追溯到计划。** 只读 `metds/plans/*_plan.md`，不读其他内容——不读代码、日志、`wkdrs/` 或聊天记忆。executor 会把已确认的执行偏差同步回子计划（`plan_sync_rules.md`），因此计划既权威又最新；只存在于 run 日志中的事实是计划同步缺口，不是输入。映射见 `references/extract_map.md`。
2. **只汇编，绝不发明。** 工作是改写、重排、合并成统一语气，不是添加事实。一个看似合理的默认值（未声明的 learning rate、显而易见的 preprocessing、标准 metric 定义）仍是发明——不能写入。不在计划中的内容就是缺口。
3. **缺口是产出，不是尴尬。** 模板中没有任何计划覆盖的章节变成 `TODO`，点名应承载它的计划和章节；缺口列表是报告的重点。文档是一面镜子：准确展示方法尚未写清的位置，并把修复推回由 coach 和 decomposer 负责的计划。
4. **沿方法轴组织，不沿计划轴组织。** 一个计划章节可能供给多份文档；一个文档章节可能合并十几个计划。要合并，不要串接——若章节读起来像计划摘录列表，或因 parent 与 leaf 都说过而重复同一内容，就算失败。出现分歧时：**leaf 优先于 parent，较新的 `updated` 优先于较旧的**。两者均无法决定时，打印两个值，用 ⚠ 标记并点名双方来源——绝不静默选择。
5. **绝不让计划内容读起来像结果。** `exec_status` 不是 `done` 的 leaf 所贡献内容属于设计意图：在该小节末尾追加一行斜体说明尚未验证，并点名来源计划。已验证内容不加标记。结果数值一律不进入这些文档——run 产生的 metric 属于 `wkdrs/<run>/EXPT_ANALYSIS_<date>.md`，跨 run 总账是 `metds/results.md`；`evaluation.md` 定义 protocol，不记录 score。
6. **只有把 diff 摆到台面上才能覆盖生成文档；手写文档根本不是覆盖目标。** 带有本 skill 的 `type:` / `generated:` frontmatter 的文档是编译工件：再次运行时，先展示章节级变更列表，获批后再写。没有这些 frontmatter 的文档由人编写——说明其内容并询问；绝不能只凭 diff 覆盖。

## 工作流

### 步骤 0：解析目标

1. 读取 `.env` 并解析 `CODE_NAME`（约定 §3）——`framework.md` 和 `training.md` 会引用 `${CODE_NAME}/` 路径。
2. 解释参数：五个 OPT 之一 → 编译对应文档；无参数 → 按依赖顺序编译全部五份（`overview` 最后，因为它链接其他四份）；其他参数 → 说明五个合法 OPT，只问一个直接问题确认原意。
3. **空计划树也是有效答案。** 没有 `metds/plans/*_plan.md` → 说明并停止，转交 `$star-plan-coach`。绝不从无到有编译 method 文档。

### 步骤 1：扫描计划树

列出 `metds/plans/*_plan.md`；读取每个文件的 frontmatter 和正文。以 `parent:` 重建树——它才是权威；数字前缀只是提示，因为两个无关根都可能叫 `0_`（`$star-plan-status` 的规则）。记录每个节点的 root / internal / leaf、`updated`、`language`、`status:` map，以及 leaf 的 `exec_status` 和 `traces_to`。

- **输出语言**遵循计划：根计划的 `language:`；存在多个根时取多数；平票则取对话语言。
- **一组文档只描述一种方法。** 若树中存在多个无关根，说明情况，只问一个直接问题确定这些文档描述哪棵根子树；答案限定整次运行范围。
- **相关章节仍为 `pending` 的计划**不贡献内容，只形成缺口——现在就记录，以便报告点名，而不是悄悄稀释文档。

### 步骤 2：提取

遵循 `references/extract_map.md`：它为每个目标指定哪些计划章节供给哪些文档章节，并规定如何判断相关 leaf——根据 leaf 的 §2 输入、§3 步骤和 §4 交付物实际**点名**的内容（`datas/` 输入、`inits/` 权重、`${CODE_NAME}/` 模块、benchmark），绝不根据标题猜测。一个 leaf 可供给多份文档。为每段内容携带 provenance `{plan file, §, updated, exec_status}`——步骤 3–5 需要它来解决冲突、添加尚未验证标记并填写 `sources:` frontmatter。

**规模**：小树（≤ 约 15 份计划）直接读取。大树仅在对多个文档目标做有边界、相互独立、只读的提取确有帮助时选择性委派；按**文档目标**划分，每个受委派者获得映射、准确文件列表和 `extract_map.md` 中的提取契约。收集者只提取并返回；绝不写文件、绝不解决跨计划冲突、绝不编译 `overview`（它需要其他四份文档的编译内容）。

### 步骤 3：合并与消解

遵循 `extract_map.md`：对两个层级陈述的同一事实去重；解决冲突（leaf > parent，newer > older），无法解决时用 ⚠ 加双方来源标记；将来自 `exec_status` ≠ `done` leaf 的段落标为尚未验证；把每个未覆盖章节记录为缺口，并指明应填补它的计划章节。

### 步骤 4：填写模板

填写 `assets/<OPT>_template.md`（中文：`assets/<OPT>_template_zh.md`）。保留模板章节及其顺序；没有覆盖内容的章节保留标题和 `TODO`——绝不删除，也绝不填充废话。frontmatter 记录 `type`、`language`、`generated`（真实日期，绝不编造）和 `sources:`——列出供给该文档的每份计划及读取时携带的 `updated` 日期，这使下一次运行可以检测陈旧性。

### 步骤 5：通过 diff 审批门写入

按依赖顺序处理每个目标：

- **缺失** → 写入。
- **已存在且由本 skill 生成**（存在 `type:` + `generated:`）→ 与刚编译的内容比较。无实质变化 → 保持文件不动并说明；不要无意义更新 `generated` 日期。存在实质变化 → 展示章节级变更列表（每章一行：added / rewritten / removed / unchanged，以及改了什么），每份文档只问一个直接问题——覆盖还是跳过。超过两份文档有差异时，可合并成一个问题：覆盖哪些文档（点名要写的文档）。
- **已存在但没有这些 frontmatter** → 手写文档。不要 diff 后直接覆盖：说明文件现有内容、编译会用什么替换，并询问。保持不动是有效结果；编译到用户指定路径也可以。
- **陈旧性检查**：把每份现有文档记录的 `sources:` 日期与相应计划当前 `updated` 比较。来源变动的文档已陈旧——即使本次没有编译该目标，也要报告。

### 步骤 6：报告

以落盘结果开头，控制在约 400 词以内：每份文档的状态——written / skipped / unchanged、路径、缺口数和尚未验证数。随后列出研究者需要采取行动的三类内容：**缺口**（每项需要哪个计划章节，最严重的在前）、**⚠ 冲突**（点名双方来源）和转交——策略缺口交给 `$star-plan-coach`，执行细节交给 `$star-plan-decomposer`，已执行 run 确定的值交给 `$star-plan-executor`，与现实矛盾的计划文本交给 `$star-plan-reviser`，结果交给 `$star-expt-analyst`，引用交给 `$star-refs-reviewer`。绝不要称文档为 paper-ready；它只是汇编材料，而缺口正是它尚未 ready 的原因。

## 状态规则

- 唯一写入是 `metds/overview.md`、`metds/dataset.md`、`metds/framework.md`、`metds/training.md`、`metds/evaluation.md`——五个 OPT 目标；其他位置一律不写。
- 绝不触碰 `metds/plans/*`——计划文本属于 `$star-plan-coach`、`$star-plan-decomposer`、`$star-plan-executor`、`$star-plan-reviser`；汇编时发现的缺口或错误陈述只报告并转交，绝不原地修复。绝不触碰 `metds/codearc.md`（`$star-code-architect` 的）、`metds/refs/*`（`$star-refs-reviewer` 的）、`metds/results.md`（`$star-expt-analyst` 的）、`wkdrs/*`、`${CODE_NAME}/`、`datas/`、`inits/`、`.env`。
- 只读取 `metds/plans/*_plan.md`、`.env` 和五份目标文档。故意不读 `wkdrs/`：执行现实通过 executor 回同步到计划后进入这些文档；若 run 细节在这里缺失，应修复计划同步，而不是扩大读取范围。
- 本 skill 不运行任何东西：不运行 Python、不训练、不评估、不安装——它不需要任何命令输出。
- Git：只读；本 skill 从不提交（约定 §1）。
- 不设置计划 frontmatter，也不创建 run 目录；每份文档的 `sources:` 块就是完整审计轨迹。
- 在四类审批点一次只问一个直接问题——无法识别的 OPT、多根树时选择哪棵根子树、每次覆盖生成文档、任何阻挡路径的手写文档——覆盖任何现有文件前都要求明确批准，即使在 headless 或 scripted 运行中也如此。文档语言遵循计划的 `language`（步骤 1），可能与对话语言不同。
