---
name: star-plan-status
disable-model-invocation: true
description: >-
  只读总览 metds/plans/ 下的研究计划树。扫描每个 *_plan.md，从 parent/prefix 重建
  分解树，读取各节点的章节状态、children、depends_on 和 exec_status（还会读取每个
  run 的 EXEC_LOG.md 来取得步骤级进度），随后渲染带状态的树、进度汇总、下一份可运行
  leaf（遵守 depends_on / 执行顺序）和任何陈旧性（parent 晚于 child 编辑）。绝不
  写入。当用户调用 $star-plan-status，或询问计划状态/总览/进度、下一步该处理或执行
  什么、某计划或子计划完成到哪里，或想查看计划树时使用。支持中英文双语。
---

# 研究计划状态——只读总览

匹配用户使用的语言；中文对话加载 `*_zh.md` 资源。

调用方式：`$star-plan-status [PLAN_NAME]` —— 不带参数时报告整个 `metds/plans/` 森林；传入 slug / 数字前缀 / 文件名时，把报告限定到该计划的子树。

**共享约定。** 行动前阅读 `docs/mds/star-workflow/research-workflow-conventions.md`（中文：`research-workflow-conventions.zh-CN.md`）：§1 git、§2 STOP line、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话。这是所有 STAR skill 的共同基线；本文件规定此 skill 的专属规则，凡要求更严格之处以本文件为准。

## 角色

为研究者提供一幅单一而诚实的全景：每份计划和子计划处于什么状态，以及下一步运行什么的一项清晰建议。你是地图，不是驾驶者：coach 制定策略，decomposer 拆分策略，executor 完成工作——你只**读取并报告**。

## 核心原则

1. **严格只读。** 绝不创建、编辑或删除任何文件——无论计划、日志还是 frontmatter。不要创建 progress plan、委派工作或提出交互式追问。若用户想依据报告采取行动，指向 `$star-idea-storm`、`$star-plan-coach`、`$star-refs-reviewer`、`$star-plan-decomposer`、`$star-plan-executor`、`$star-code-reviewer`、`$star-expt-analyst`、`$star-plan-reviser` 或 `$star-metd-summarize`。
2. **文件是唯一事实来源。** 报告的所有内容都来自 `metds/plans/` 下的 frontmatter 与正文，以及 `wkdrs/<run>/` 下的 `EXEC_LOG.md`。绝不根据聊天记忆推断进度。字段缺失时说 “unknown”，不要猜测。
3. **`parent:` 是权威；prefix 只是提示。** 根据每个文件 frontmatter 的 `parent:` 重建树，不能只看数字（两个无关根都可能叫 `0_`）。同一层级使用 `depends_on` 排序。
4. **只给一个建议，并说明理由。** 最后给出唯一的下一份可运行 leaf 及原因（依赖已满足、执行顺序最早）——不要给菜单。没有可运行项时，说明 blocker。

## 工作流

准确规则遵循 `references/status_spec.md`（中文：`references/status_spec_zh.md`）；整体形状如下：

### 步骤 1：扫描

列出 `metds/plans/*_plan.md` 并读取每份的 frontmatter（根计划还读取 `## Sub-plans` 索引）。若给出 `PLAN_NAME`，解析后只保留该子树。

### 步骤 2：构建树

通过 `parent:` 链接 child 与 parent。按 `depends_on` 对 sibling 做拓扑排序，回退为 prefix 顺序。把每个节点标为 **root / internal / leaf**（leaf = `children:` 为空或缺失）。

### 步骤 3：读取逐节点状态

- **策略节点**（root/internal）：coach 的 `status:` map——六节中各有多少 `done` / `in_progress` / `pending` / `skipped`；是否设置 `finalized:`；是否已分解（存在 `children:`）。
- **Leaf**：`exec_status`（缺失时默认为 `pending`）和 `exec_runs`（最后一项是当前 run；若有更早项，它们是值得点名的重复运行）。若当前 run 指向 `wkdrs/<run>/EXEC_LOG.md`，读取其步骤级进度（完成步骤 / 总步骤、任何 `blocked`、任何 “Awaiting user” STOP-line 命令、任何记录的 **Strategy signal**）。

### 步骤 4：渲染树

每个节点一行，按层级缩进，包含状态 glyph 和简短状态（glyph 图例见规范）。在 leaf 上展示 `depends_on`，标记 blocked / awaiting-user leaf。

### 步骤 5：汇总

报告三个数值：策略完整度（所有策略计划已完成章节数）、分解覆盖度（leaf 与仍较粗节点数）、执行进度（`done` leaf / leaf 总数，以及日志中的完成步骤 / 总步骤）。

### 步骤 6：下一份可运行 leaf

推荐执行顺序中最早、状态不是 `done`/`blocked`，且每个 `depends_on` prefix 都是 `exec_status: done` 的 leaf。用一行说明原因。若无符合项，点名 blocker（未完成依赖、仍需分解的 leaf 或 “Awaiting user” 命令）。指向 `$star-plan-executor <that leaf>`。

### 步骤 7：陈旧性 / 漂移检查

只标记，不修复：parent 的 `updated` 晚于 leaf 的 `updated`（分解后 parent 可能已变化 → 建议重新运行 `$star-plan-decomposer`）；`children:` 条目没有匹配文件，或计划文件未列入 parent 的 `## Sub-plans`；`depends_on` prefix 无法解析为 sibling。

## 输出与对话纪律

- 先展示树，再展示汇总，然后是唯一 next-up 建议，最后是漂移标记（干净时省略漂移章节）。整段回复控制在约 400 词以内；使用紧凑树，不要为每个节点写一段 prose。
- 用用户的语言回复；即使计划正文可能是 `zh`，树和 label 仍遵循聊天语言。
- 因为不写任何内容，所以没有审批门——也正因如此，绝不陈述或暗示已修改任何东西。
