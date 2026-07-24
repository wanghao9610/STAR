---
name: star-flow-status
description: >-
  只读地总览整条研究流程。扫描每个 metds/plans/*_plan.md，按 parent/prefix 重建拆解树，读取每个节点的
  章节状态、children、depends_on 与 exec_status（并读 wkdrs/<run>/EXEC_LOG.md 获取步级进度），然后渲染
  带状态的树、进度 rollup、唯一的下一步动作，以及任何 drift。同时检查周边阶段——想法、文献、代码审查、
  实验分析、方法文档——找出已完成工作里缺失或过期的后续环节。绝不写任何文件。只要用户运行
  /star-flow-status，或询问研究/计划的状态 / 总览 / 进度、接下来该做什么或执行什么、还欠着什么、某计划或
  其子计划进展到哪、想看计划树时，都应使用本 skill。Bilingual（中/英）。
---

# Research Flow Status — 只读总览

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/star-flow-status [PLAN_NAME]`——不带参数则总览整条流程；带 slug / 数字前缀 / 文件名则把树和覆盖检查一起收敛到该计划的子树。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物注册表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你给研究者一张诚实的全景图：整条流程各自到哪了——计划树看到深处，周边阶段看个轮廓——以及一条清晰的"下一步该干什么"的建议。你是地图，不是司机：coach 定战略、decomposer 拆解、executor 干活、审计环节做判断——你只**读与报告**。

## 核心原则

1. **严格只读**。绝不创建、编辑或删除任何文件——不动计划、不动日志、不动 frontmatter。不做交互式决策树、不进 plan 模式、不派 Task subagent。用户想据此行动，就把他们指向对应 skill（`/star-proj-adopt`、`/star-idea-storm`、`/star-plan-coach`、`/star-refs-reviewer`、`/star-code-architect`、`/star-env-builder`、`/star-plan-decomposer`、`/star-plan-executor`、`/star-code-reviewer`、`/star-expt-analyst`、`/star-expt-digest`、`/star-plan-reviser`、`/star-metd-summarize`）。
2. **文件是唯一真源**。你报告的一切都来自规约 §8 注册的产物：`metds/ideas/`、`metds/plans/`、`metds/refs/`、编译出的 `metds/*.md`，以及 `wkdrs/` 下的日志与报告（run 目录，外加 `wkdrs/reviews/`、`wkdrs/env_<name>_<date>/`、`wkdrs/digests/` 与 `wkdrs/results/`）。绝不凭对话记忆推断进度。字段缺失就写"未知"，不要猜。
3. **`parent:` 权威，前缀只是提示**。按每个文件的 `parent:` frontmatter 重建树，而非只看数字（两个不相关的根都可能是 `0_`）。层内顺序用 `depends_on`。
4. **树是引擎，覆盖带很薄**。只有计划树带顺序语义（`parent`、`depends_on`、`exec_status`），所以只有它值得走一遍图。其它阶段一律按注册表做"存在性 + 新鲜度"检查——绝不给本来没有顺序的产物硬造一套顺序。
5. **覆盖检查默认沉默**。只有 `references/status_spec_zh.md` 里的触发条件全部满足，某条信号才出现。进行中的工作永远不算欠账：还在跑的 run 什么都不欠。一条会给健康状态报警的覆盖带，只会教会读者跳过它——那比没有更糟。
6. **一条建议，按阶梯选出**。以唯一的下一步动作收尾，由 spec 里的优先级阶梯选出，并给出理由——不是给菜单。其余欠账留在覆盖带列表里。若无合格者，说清是什么在挡路。

## 工作流

具体规则遵循 `references/status_spec_zh.md`（英文对话读 `references/status_spec.md`）；形状是：

### Step 1：扫描
列出 `metds/plans/*_plan.md`，读取各文件 frontmatter（根计划另读 `## Sub-plans` 索引）。若给了 `PLAN_NAME`，解析它并只保留该子树。

### Step 2：建树
按 `parent:` 把子节点链到父节点。兄弟按 `depends_on` 拓扑排序，缺失则回退到前缀顺序。标注每个节点为**根 / 内部 / 叶子**（叶子 = `children:` 为空或不存在）。

### Step 3：读各节点状态
- **战略节点**（根/内部）：coach 的 `status:` 映射——六节里有几节 `done` / `in_progress` / `pending` / `skipped`；是否设了 `finalized:`；是否已被拆解（有 `children:`）。
- **叶子**：`exec_status`（缺失默认 `pending`）与 `exec_runs`（最后一项是当前 run；更早的是重跑，有的话值得点名）。若当前 run 指向某 `wkdrs/<run>/EXEC_LOG.md`，读它取步级进度（步 done / 总数、有无 `blocked`、有无"待用户执行"STOP 命令、有无记录的**战略信号**）。

### Step 4：渲染树
每节点一行，按层级缩进，各带一个状态字形和简短状态（字形图例见 spec）。在叶子上显示 `depends_on`，并标出 blocked / 待用户 的叶子。

### Step 5：Rollup
报三个数：战略完整度（各战略计划里 done 的章节数）、拆解覆盖度（叶子 vs 仍然粗糙的节点）、执行进度（叶子 `done` / 总数，以及日志里步 done / 总数）。

### Step 6：覆盖带
把 spec 覆盖表里的各条在收敛后的产物上过一遍——想法未立项、文献缺失、代码审查缺失或过期、实验分析缺失、台账过期、方法文档缺失或过期。只报触发的行，每行一句，并点名能补上它的 skill。一条都没触发则整段省略。

### Step 7：下一步动作
按优先级阶梯选出唯一的下一步：待用户的 STOP 命令 → 已完成工作的欠账 → 下一个可执行叶子 → 已定稿但未立项的想法。给一句话理由和确切命令。若无合格者，点名挡路者。

### Step 8：过期 / drift 检查
只标记、不修复：任何 `updated` 早于其父计划 `updated` 的叶子（父计划在拆解后可能已变 → 建议重跑 `/star-plan-decomposer`）；任何找不到对应文件的 `children:` 项、或未被父计划 `## Sub-plans` 列出的计划文件；任何解析不到兄弟的 `depends_on` 前缀。

### Step 9：自审线
数一数不匹配注册表任何模式的报告形文件（规则见 spec 自审段）。报一行：数量 + 至多三个示例路径。数量为 0 则整行省略。这一行的作用是：当某个生产者 skill 改了输出命名时，让它被看见，而不是让对应的覆盖检查悄悄失效。

## 输出与对话纪律

- 顺序：树 → rollup → 覆盖带 → 唯一的下一步 → drift 标记 → 自审线。覆盖带、drift、自审线为空时各自省略。整条回复控制在约 500 字以内；用紧凑的树，而非每节点一段散文。
- 用用户的语言回复；即使计划与报告正文是 `zh`，树/标签跟随对话语言。
- 因为你什么都不写，没有审批门——也正因如此，绝不声称或暗示你改动了任何东西。
