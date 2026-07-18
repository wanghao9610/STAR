---
name: star-plan-reviser
disable-model-invocation: true
description: >-
  依据执行证据审查 metds/plans/ 中的一份研究计划，再经用户逐项批准后原地修订。读取
  wkdrs/<run>/ 的执行日志和工件（internal node 使用 children 汇总），逐项声明地对照
  磁盘文件评分完成情况，把七部分审查报告写入 wkdrs/，每次只问一个问题来处理修订
  候选，直接编辑计划文件并追加 Revision History——结构重塑转交
  star-plan-decomposer，策略转向转交 star-plan-coach。当用户调用
  $star-plan-reviser，或要求 Codex 在（部分）执行后审查、审计或修订计划，或把执行
  结果折回计划时使用。支持中英文双语工作。
---

# 研究计划修订器

匹配用户使用的语言。中文对话加载 `*_zh.md` 资源；否则加载无后缀资源。

调用方式：`$star-plan-reviser PLAN_NAME`，其中 `PLAN_NAME` 是 slug（`open-vocab-det-seg`）、数字前缀（`00`）或文件名（`00_mvp-3way-ablation_plan.md`）。不带参数时列出候选并询问——优先有执行证据或已标记漂移的节点。

**共享约定。** 行动前阅读 `docs/mds/star-workflow/research-workflow-conventions.md`（中文：`research-workflow-conventions.zh-CN.md`）：§1 git、§2 STOP line、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话。这是所有 STAR skill 的共同基线；本文件规定此 skill 的专属规则，凡要求更严格之处以本文件为准。

## 角色

闭合其他 skill 留下的循环：`$star-plan-coach` 编写策略，`$star-plan-decomposer` 拆分策略，`$star-plan-executor` 执行 leaf 并留下证据（`wkdrs/<run>/EXEC_LOG.md`、工件）——还会明确把“结果与计划矛盾”交还用户。选取**一个计划节点**，依据这些证据审计其意图，并在用户决定每项变更的前提下，**原地修订计划文件**。`$star-plan-status` 是覆盖整棵树的浅层只读 dashboard；本 skill 是允许写入的单计划深度审计。

只修订文本；不要重跑实验、重新分解子树或从头重新推导策略。

## 核心原则

1. **证据先于意见。** 每条审查声明都带 evidence pointer（文件路径、日志行、命令输出）。日志自报 `done` 不等于完成——对照磁盘工件佐证，关键处重新运行廉价检查；绝不启动重型实验（executor 的 STOP line 同样适用）。这把项目验证规则（AGENTS.md §7）应用到计划本身。规则见 `references/review_spec.md`。
2. **默认在本地收集；选择性委派。** 自行读取日志、工件和代码状态。仅当对多个 run 或工件集合进行有边界、相互独立、只读的检查确有帮助时，才委派收集；受委派者必须遵守 `references/review_spec.md` 的 collector 契约，绝不写入或提出修订。综合和判断留在主 agent。
3. **用户拥有每项变更的决定权。** 发现变成带编号的修订候选。每项通过一次一个直接问题被 adopted / adjusted / skipped，并标出推荐项——绝不批量批准，绝不未经询问编辑。
4. **原地修订，留下轨迹。** 获批编辑写入原始 `<prefix>_<slug>_plan.md`；绝不分叉 `_v2` 副本（重复前缀会破坏 status/decomposer/executor 解析的树）。每次会话追加一条 `## Revision History`（日期、每项变更的单行说明及证据、报告路径），并更新 `updated`；旧版本留在 git 中。
5. **遵守本系列的写入纪律。** 绝不重编号 prefix；绝不触碰 `EXEC_PLAN.md` / `EXEC_LOG.md`（属于 executor）；结构重塑（添加/删除子计划、重画依赖图）转交 `$star-plan-decomposer`；研究问题或方法转向交给 `$star-plan-coach`。边界见 `references/revision_rules.md`。
6. **注意涟漪效应。** 修订可能使基于旧文本的工作失效。询问变更前，在报告 §6 展示反向 `depends_on` 边和派生 children；objective 行变化时同步父计划 `## Sub-plans` 的单行摘要；更新后的 `updated` 让 `$star-plan-status` 能揭示下游陈旧项。

## 工作流

### 步骤 0：解析目标计划

1. 把 `PLAN_NAME`（slug / 数字前缀 / 完整文件名）与 `metds/plans/*_plan.md` 匹配；完整读取解析出的计划。
2. 目标不存在或有歧义时，列出简洁候选（prefix + slug + 单行状态），只问一个直接问题——优先有执行证据（`exec_runs` 非空）或已知漂移的节点。
3. 对节点分类：**leaf**（审计自己的 run）或 **root/internal**（审计策略章节 + children 汇总）。这决定步骤 1 的证据集合。

### 步骤 1：界定证据范围

- **Leaf**：当前 run 目录（`exec_runs` 最后一项——`EXEC_PLAN.md`、`EXEC_LOG.md`）、每个 §4 交付物路径，以及 §2 点名的输入（`datas/`、`inits/`）和代码模块（`${CODE_NAME}/`，从 `.env` 解析）。
- **Root/internal**：children frontmatter（`status`、`exec_status`、`updated`、`depends_on`）、已执行后代的日志（尤其是 **Strategy signal** 记录和 kill-criteria 命中），以及本节点自身 §1–§6 假设。
- 明确说明存在什么证据。若任何地方都没有执行，说明审查将是 **document-only**：无法评分完成度；报告中的 intent / divergence / candidate 章节仍适用，依据用户知道但计划未写的内容。

### 步骤 2：收集证据（只读）

依据 `references/review_spec.md` 中的 collector 契约收集：**日志证据**（步骤状态、声称的检查、“Awaiting user”命令、strategy signal）、**工件证据**（每个 §4 交付物：存在性 / size / mtime / 廉价 sanity check），以及在 §2–§3 点名代码时的**代码证据**（承诺模块是否存在，是否与日志声称的修改一致）。默认在本地收集；按核心原则 2 选择性委派。

交叉核对分歧——日志说 `done` 但工件缺失 → 该声明是 **unverifiable**，不是 met。重新运行关键的廉价检查；绝不运行重型任务。

### 步骤 3：综合并持久化审查报告

填写 `assets/review_report_template.md`（中文计划：`assets/review_report_template_zh.md`；报告遵循计划的 `language`），包含七节：① intent recap ② what actually happened ③ completion scorecard（逐项 §3 任务及 §5 完成标准：`met` / `partial` / `unmet` / `unverifiable`，每项带证据）④ divergences ⑤ blockers & leftovers ⑥ ripple map ⑦ revision candidates；每项候选分级为 **local / structural / strategic**。

写入 `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md`（真实日期，绝不编造）。计划没有 run 时使用 `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`。在聊天中给出约 400 词以内的摘要：结论、关键偏差，以及候选列表的单行摘要。

### 步骤 4：修订问答（一次一个候选）

1. 按报告顺序处理候选，每个候选只问一个直接问题：*按建议采用* / *修改后采用* / *跳过*——标出推荐项；用户始终可以自由回答。对于 **structural** 或 **strategic** 候选，选项为*转交 `$star-plan-decomposer` 或 `$star-plan-coach`*（推荐）与*仍在这里做有界文本编辑*。绝不把整个列表一次性笼统询问。
2. 列表结束后，只问一次是否还有其他变更。用户新增项同样成为候选（证据：“user directive”）。
3. 若没有任何 adopted 项，跳到步骤 7——纯审查是有效结果；持久化报告就是交付物。

### 步骤 5：应用获批编辑

按文件顺序处理每个 adopted 候选：

1. 依据证据和用户答复起草新章节文字；展示简洁的 before → after 摘要；写入文件。匹配计划的 `language`；中文计划中的技术术语保留英文。
2. 保持 section `status` map 诚实：引入 `[TBD]` / `【待定】` 的编辑会把该节改为 `in_progress`；确认过的重写保持 `done`。

最后一项编辑后：更新 `updated`；若 leaf 的 §5 完成标准或 §3 任务发生实质变化，且其 `exec_status` 为 `done` 或 `blocked`，提议把它重置为 `pending`（无论如何 `exec_runs` 都保留历史）；若 adopted 候选改变 `finalized` 计划的 §1、§2、§3 或 §6——问题、定位、方法或里程碑——只问一次是否清除 `finalized:`（§4/§5 的战术编辑，如收紧 kill-criterion，不清除），因为 `star-code-architect` 读取该字段判断计划能否驱动搜索，重新 finalize 使用 `star-plan-coach <slug> <section>`；随后按 `references/revision_rules.md` 追加 `## Revision History`。

### 步骤 6：一致性检查

- 若计划 title 或单行 objective 改变，更新父计划匹配的 `## Sub-plans` 行——这是目标文件以外唯一允许的编辑。
- 重新检查 `children:` 条目和 `depends_on` prefix 均可解析；对悬空引用只做**标记**并转交 `$star-plan-decomposer`——不要静默修复。（将目标自身 `depends_on` 列表作为获批候选编辑是允许的；跨 sibling 重画边不允许。）
- 若目标是 parent，且修订触碰 children 派生自的内容，点名受影响 children 并推荐重新分解。

### 步骤 7：报告与转交

以结果开头，控制在约 400 词以内：证据基础（读取并验证了什么）、完成结论、逐节应用的变更、跳过的候选、涟漪警告。最后给出下一条命令：`$star-plan-decomposer <slug>`（结构变化 / children 陈旧）、`$star-plan-coach <slug>`（策略转向）、`$star-plan-executor <leaf>`（重跑修订后的 leaf）、`$star-code-reviewer <leaf>`（审计实现代码）、`$star-plan-status`（查看整棵树）。若未编辑，明确说明——报告文件仍然存在。若已应用编辑，只提议一次提交（状态与文件规则）。

## 状态规则

- 审查报告存放在 `wkdrs/` 下（计划 run 目录，否则 `wkdrs/reviews/`）；绝不放在 `metds/plans/` 下。
- 只编辑：目标计划正文和 frontmatter（`updated`、章节 `status` map、`depends_on`、`exec_status`——后两者仅作为用户获批候选），以及 objective 变化时父计划的 `## Sub-plans` 单行摘要。其他内容全部只读：`EXEC_PLAN.md` / `EXEC_LOG.md`、sibling 和 child 计划正文、prefix（绝不重编号）、计划文件（绝不删除或分叉）。
- 每次写入都必须追溯到一项单独批准的候选；`## Revision History` 只可追加。
- Git：应用编辑后，在步骤 7 只提议一次提交目标计划（父计划 `## Sub-plans` 行变化时还包括父计划）——`star-plan-reviser: <slug> — <n> changes`（约定 §1）。核心原则 4 的“旧版本留在 git”依赖这些 commit。
- 合法章节 `status`：`pending` / `in_progress` / `done` / `skipped`；合法 `exec_status`：`pending` / `in_progress` / `done` / `blocked` / `skipped`——与本系列一致。
- 一次只问一个问题，任何写入前都要求明确答复。计划正文与审查报告保持计划 frontmatter 的 `language`。
